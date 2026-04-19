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

load("testing.rdata")
selected_records <- testing$idx

load("testing_json_files.rdata")

####
testing <- merge(testing,testing_json_files, by.x="deviceMotion_walking_outbound.json.items", by.y="testing_json_fileId", all.x=TRUE, all.y=F)

# add walking json files columns
testing <- testing %>% mutate(testing_json_file = as.character(testing_json_file))

# remove duplicates
testing <- testing %>%
distinct(testing_json_file, .keep_all = TRUE)

#############
# Feature Extraction
##############
registerDoMC(20)

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
#testing = head(testing, n = 1000)

walkFeatures <-
	dlply(
		  .data = testing, 
		  #.variables = colnames(testing)[c(2,3,10)],
		  #.variables = c("idx", "deviceMotion_walking_return.json.items", "testing_json_file"),
		  .variables = ("idx"),
		  .fun = function(row) {
			  my.getWalkFeatures(row$testing_json_file)
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
deviceMotion_walking_outbound.json.items_testing.features <- walkFeatures.df %>% filter(idx %in% selected_records)

save(deviceMotion_walking_outbound.json.items_testing.features, file="deviceMotion_walking_outbound.json.items_testing.features.rdata")


