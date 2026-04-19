#source("~/mybiotools/r/", echo=T)
rm(list=ls());
options("scipen"=1, "digits"=4, stringsAsFactors=FALSE);

library(synapseClient)
# synapseLogin()
synapseLogin(rememberMe=T)


library(plyr)
library(dplyr)
library(ggplot2)
library(doMC)
library(jsonlite)
library(parallel)
library(tidyr)
library(lubridate)
library(stringr)
library(sqldf)
library(mpowertools) 

load("actv_walking.rdata")
selected_records <- actv_walking$idx

load("outbound_Walking_json_files.rdata")

####
actv_walking <- merge(actv_walking,outbound_Walking_json_files, by.x="deviceMotion_walking_outbound.json.items", by.y="outbound_Walking_json_fileId", all.x=TRUE, all.y=F)

# add walking json files columns
actv_walking <- actv_walking %>% mutate(outbound_Walking_json_file = as.character(outbound_Walking_json_file))

# remove duplicates
actv_walking <- actv_walking %>%
distinct(outbound_Walking_json_file, .keep_all = TRUE)

#############
# Feature Extraction
##############
registerDoMC(30)

my.getWalkFeatures = function (walking_json_file) {
	if (is.na(walking_json_file) == T) {
		return (rep(NA, times=18))
	}
	dat <- jsonlite::fromJSON(walking_json_file)
	if (nrow(dat)  == 0) {
		return (rep(NA, times=18))
	}
	dat.m <- matrix(unlist(dat), ncol = 18, byrow = F)
	colnames(dat.m) = names(unlist(dat[1,]))
	return (dat.m)
}

#for test
#actv_walking = head(actv_walking, n = 1000)

walkFeatures <-
	dlply(
		  .data = actv_walking, 
		  #.variables = colnames(actv_walking)[c(2,3,10)],
		  #.variables = c("idx", "deviceMotion_walking_return.json.items", "outbound_Walking_json_file"),
		  .variables = ("idx"),
		  .fun = function(row) {
			  my.getWalkFeatures(row$outbound_Walking_json_file)
		  },
		  .parallel = TRUE
		  )

#to delete some problem results
if (F)
{
	check.e = unlist(sapply(walkFeatures, ncol))
	check.e.l = check.e < 18
	sum(check.e.l)
}

countna = function (x) {
	sum(is.na(x))
}
checkna = unlist(sapply(walkFeatures, countna))
checkna.l = checkna > 0
if (length(which(checkna.l)) > 0 ) {
	walkFeatures = walkFeatures[-which(checkna.l)]
}

#transforming to data frame
#walkFeatures.df = matrix(unlist(walkFeatures), ncol = 18, byrow = F)
output <- do.call(rbind, lapply(walkFeatures, matrix, ncol=18, byrow=F))
colnames(output) = colnames(walkFeatures[[1]])

nn = unlist(sapply(walkFeatures, nrow))
idx = rep(names(nn), nn)
walkFeatures.df = cbind(idx=idx, as.data.frame(output))
str(walkFeatures.df)
#'data.frame':	63189009 obs. of  19 variables:

# Only keep the non-redundant data
deviceMotion_walking_outbound.json.items.features <- walkFeatures.df %>% filter(idx %in% selected_records)

save(deviceMotion_walking_outbound.json.items.features, file="deviceMotion_walking_outbound.json.items.features.rdata")


