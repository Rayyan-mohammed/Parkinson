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
actv_walking <- merge(actv_walking,outbound_Walking_json_files, by.x="accel_walking_rest.json.items", by.y="outbound_Walking_json_fileId", all.x=TRUE, all.y=F)

# add walking json files columns
actv_walking <- actv_walking %>% mutate(outbound_Walking_json_file = as.character(outbound_Walking_json_file))

# remove duplicates
actv_walking <- actv_walking %>%
distinct(outbound_Walking_json_file, .keep_all = TRUE)
dim(actv_walking)
#[1] 23115    16

#############
# Feature Extraction
##############
registerDoMC(30)

#dat.ncol = 4

#for test
#actv_walking = head(actv_walking, n = 1000)
walking_json_file = actv_walking[1,16]
dat <- jsonlite::fromJSON(walking_json_file)
str(dat)
(dat.ncol <- length(names(unlist(dat[1,,drop=F]))))

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

walkFeatures <-
	dlply(
		  .data = actv_walking, 
		  .variables = ("idx"),
		  .fun = function(row) {
			  my.getWalkFeatures(row$outbound_Walking_json_file)
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
#	104364595 obs. of  5 variables:

# Only keep the non-redundant data
accel_walking_rest.json.items.features <- walkFeatures.df %>% filter(idx %in% selected_records)

save(accel_walking_rest.json.items.features, file="accel_walking_rest.json.items.features.rdata")


