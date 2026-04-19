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

load("supp_training.rdata")
selected_records <- supp_training$idx

load("supp_training_json_files.rdata")

####
supp_training <- merge(supp_training,supp_training_json_files, by.x="deviceMotion_walking_outbound.json.items", by.y="supp_training_json_fileId", all.x=TRUE, all.y=F)

# add walking json files columns
supp_training <- supp_training %>% mutate(supp_training_json_file = as.character(supp_training_json_file))

# remove duplicates
supp_training <- supp_training %>%
distinct(supp_training_json_file, .keep_all = TRUE)

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
#supp_training = head(supp_training, n = 1000)

walkFeatures <-
	dlply(
		  .data = supp_training, 
		  #.variables = colnames(supp_training)[c(2,3,10)],
		  #.variables = c("idx", "deviceMotion_walking_return.json.items", "supp_training_json_file"),
		  .variables = ("idx"),
		  .fun = function(row) {
			  my.getWalkFeatures(row$supp_training_json_file)
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
deviceMotion_walking_outbound.json.items_supp.features <- walkFeatures.df %>% filter(idx %in% selected_records)

save(deviceMotion_walking_outbound.json.items_supp.features, file="deviceMotion_walking_outbound.json.items_supp.features.rdata")


