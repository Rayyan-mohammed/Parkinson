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
testing <- merge(testing,testing_json_files, by.x="deviceMotion_walking_return.json.items", by.y="testing_json_fileId", all.x=TRUE, all.y=F)

# add walking json files columns
testing <- testing %>% mutate(testing_json_file = as.character(testing_json_file))

# remove duplicates
testing <- testing %>%
distinct(testing_json_file, .keep_all = TRUE)
dim(testing)
#[1] 23115    16

#############
# Feature Extraction
##############
registerDoMC(20)

#dat.ncol = 4

#for test
#testing = head(testing, n = 1000)
walking_json_file = testing[1,dim(testing)[2]]
dat <- jsonlite::fromJSON(walking_json_file)
str(dat)
dat.ncol <- length(names(unlist(dat[1,,drop=F])))

my.getWalkFeatures = function (walking_json_file) {
	if (is.na(walking_json_file) == T | is.null(walking_json_file)) {
		return (rep(NA, times=dat.ncol))
	}
	dat <- try (jsonlite::fromJSON(walking_json_file))
	if (is.null(dat) ) {
		return (rep(NA, times=dat.ncol))
	} 
	if ( class(dat) == "try-error" | length(unlist(dat)) < dat.ncol) {
		return (rep(NA, times=dat.ncol))
	}
	dat.m <- try (matrix(unlist(dat), ncol = dat.ncol, byrow = F))
	if (class(dat.m) == "try-error") {
		return (rep(NA, times=dat.ncol))
	}
	dat.name = try(names(unlist(dat[1,,drop=F])))
	if (class(dat.name) == "try-error" | dim(dat.m)[2] != length(dat.name)) {
		return (rep(NA, times=dat.ncol))
	}
	colnames(dat.m) = dat.name
	return (dat.m)
}

#for debug
if (F) {
w = list()
for (i in 1:nrow(testing))
{
	cat (testing[i, "testing_json_file"], "......\n")
	out = my.getWalkFeatures(testing[i, "testing_json_file"])
	w[[length(w)+1]] = out
}
}

walkFeatures <-
	dlply(
		  .data = testing, 
		  .variables = ("idx"),
		  .fun = function(row) {
			  my.getWalkFeatures(row$testing_json_file)
		  },
		  .parallel = T
		  )

length(walkFeatures)
countna = function (x) {
	sum(is.na(x))
}
checkna = unlist(sapply(walkFeatures, countna))
checkna.l = (checkna == dat.ncol)
if (length(which(checkna.l)) > 0 ) {
	walkFeatures = walkFeatures[-which(checkna.l)]
}
length(walkFeatures)
length(which(checkna.l))

#transforming to data frame
#walkFeatures.df = matrix(unlist(walkFeatures), ncol = dat.ncol, byrow = F)
output <- do.call(rbind, lapply(walkFeatures, matrix, ncol=dat.ncol, byrow=F))
colnames(output) = colnames(walkFeatures[[1]])
nn = unlist(sapply(walkFeatures, nrow))
idx = rep(names(nn), nn)
walkFeatures.df = cbind(idx=idx, as.data.frame(output))
str(walkFeatures.df)
#33833156 obs. of  19 variables:

# Only keep the non-redundant data
deviceMotion_walking_return.json.items_testing.features <- walkFeatures.df %>% filter(idx %in% selected_records)

save(deviceMotion_walking_return.json.items_testing.features, file="deviceMotion_walking_return.json.items_testing.features.rdata")


