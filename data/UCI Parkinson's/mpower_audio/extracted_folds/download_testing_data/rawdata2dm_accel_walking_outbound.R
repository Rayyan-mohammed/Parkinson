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
testing <- merge(testing,testing_json_files, by.x="accel_walking_outbound.json.items", by.y="testing_json_fileId", all.x=TRUE, all.y=F)

# add walking json files columns
testing <- testing %>% mutate(testing_json_file = as.character(testing_json_file))

# remove duplicates
testing <- testing %>%
distinct(testing_json_file, .keep_all = TRUE)
dim(testing)
#[1] 34588    16

#############
# Feature Extraction
##############
registerDoMC(30)

dat.ncol = 4

my.getWalkFeatures = function (walking_json_file) {
	if (is.na(walking_json_file) == T) {
		return (rep(NA, times=dat.ncol))
	}
	dat <- jsonlite::fromJSON(walking_json_file)
	if (nrow(dat)  == 0) {
		return (rep(NA, times=dat.ncol))
	}
	dat.m <- matrix(unlist(dat), ncol = dat.ncol, byrow = F)
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
	check.e.l = check.e < dat.ncol
	sum(check.e.l)
}

countna = function (x) {
	sum(is.na(x))
}
checkna = unlist(sapply(walkFeatures, countna))
checkna.l = (checkna == dat.ncol)
if (length(which(checkna.l)) > 0 ) {
	walkFeatures = walkFeatures[-which(checkna.l)]
}

#transforming to data frame
#walkFeatures.df = matrix(unlist(walkFeatures), ncol = dat.ncol, byrow = F)
output <- do.call(rbind, lapply(walkFeatures, matrix, ncol=dat.ncol, byrow=F))
colnames(output) = colnames(walkFeatures[[1]])
nn = unlist(sapply(walkFeatures, nrow))
idx = rep(names(nn), nn)
walkFeatures.df = cbind(idx=idx, as.data.frame(output))
str(walkFeatures.df)
#'data.frame':	66413570 obs. of  5 variables:

# Only keep the non-redundant data
accel_walking_outbound.json.items_testing.features <- walkFeatures.df %>% filter(idx %in% selected_records)

save(accel_walking_outbound.json.items_testing.features, file="accel_walking_outbound.json.items_testing.features.rdata")


