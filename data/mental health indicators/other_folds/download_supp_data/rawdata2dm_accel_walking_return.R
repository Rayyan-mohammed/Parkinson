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
supp_training <- merge(supp_training,supp_training_json_files, by.x="accel_walking_return.json.items", by.y="supp_training_json_fileId", all.x=TRUE, all.y=F)

# add walking json files columns
supp_training <- supp_training %>% mutate(supp_training_json_file = as.character(supp_training_json_file))

# remove duplicates
supp_training <- supp_training %>%
distinct(supp_training_json_file, .keep_all = TRUE)
dim(supp_training)
#[1] 23114    16

#############
# Feature Extraction
##############
registerDoMC(30)

dat.ncol = 4

#for test
#supp_training = head(supp_training, n = 1000)
walking_json_file = supp_training[1,16]
dat <- jsonlite::fromJSON(walking_json_file)

my.getWalkFeatures = function (walking_json_file) {
	if (is.na(walking_json_file) == T | is.null(walking_json_file)) {
		return (rep(NA, times=dat.ncol))
	}
	dat <- jsonlite::fromJSON(walking_json_file)
	if (is.null(dat) ) {
		#cat ("NULL: ", walking_json_file, "\n")
		return (rep(NA, times=dat.ncol))
	} else if ( dat == "" | is.na(dat) ) {
		#cat ("NA: ", walking_json_file, "\n")
		return (rep(NA, times=dat.ncol))
	}
	#dat = as.matrix(as.data.frame(dat), drop=F)
	dat.m <- matrix(unlist(dat), ncol = dat.ncol, byrow = F)
	if (ncol(dat.m) == length(names(unlist(dat[1,])))) {
		colnames(dat.m) = names(unlist(dat[1,]))
	} else {
		return (rep(NA, times=dat.ncol))
	}
	return (dat.m)
}

walkFeatures <-
	dlply(
		  .data = supp_training, 
		  #.variables = colnames(supp_training)[c(2,3,10)],
		  #.variables = c("idx", "deviceMotion_walking_return.json.items", "supp_training_json_file"),
		  .variables = ("idx"),
		  .fun = function(row) {
			  my.getWalkFeatures(row$supp_training_json_file)
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
#66413570 obs. of  5 variables:

# Only keep the non-redundant data
accel_walking_return.json.items_supp.features <- walkFeatures.df %>% filter(idx %in% selected_records)

save(accel_walking_return.json.items_supp.features, file="accel_walking_return.json.items_supp.features.rdata")


