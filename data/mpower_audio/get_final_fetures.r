#!/usr/bin/env Rscript --slave

argv    <- commandArgs(TRUE);
datfile  <- argv[1]
feature_ranking_file  <- argv[2]
num     <- as.numeric(argv[3])
outfile  <- argv[4]
outfile.all  <- argv[5]
traindatfile <- argv[6]

options("scipen"=1, "digits"=4, stringsAsFactors=FALSE);
library(PDdream)

#get specific recordIds
synapseLogin()
synid<-"syn10233116"
syndemos<-synGet(synid)
demos<-read.csv(attributes(syndemos)$filePath, header=T, as.is=T)
required_recordID = demos$recordId.walktest
#updated
template = read.csv("~/PD_dream/PDChallenge_SC1_SubmissionTemplate.csv",T)
required_recordID = template$recordId


testingDat = r.table(datfile, T, 1)
trainingDat = r.table(traindatfile, T, 1)
t.i = match(colnames(testingDat), colnames(trainingDat))
if (sum(is.na(t.i))>0) stop (paste0("Colnames are not equal between test and traing dat"))
trainingDat = trainingDat[, t.i]
r.i = match(rownames(testingDat), rownames(trainingDat))
if (sum(!is.na(r.i))>0) stop ("some row names are equal")

#allDat = rbind(testingDat, trainingDat)
allDat_all = rbind(testingDat, trainingDat) #including all samples

#check recordId
rid.i = match(required_recordID, rownames(allDat_all))
if (sum(is.na(rid.i)>0)) stop ("Some required recordId are not available")
#trainingDat.r = trainingDat[required_recordID,]

#selected features
ft = r.table(feature_ranking_file, T, 1)
features = rownames(ft)[1:num]
f.i = match(features, colnames(allDat_all))
#if (sum(is.na(f.i)) > 0) stop (paste0("Not all features in data file"))
#dat.out = allDat[ ,f.i]
dat.out_all = allDat_all[ ,f.i]

#imputation
if (sum(is.na(dat.out_all))>0) {
	message ("NA values need to be imputed for all samples. ")
	for(i in 1:ncol(dat.out_all)){
		dat.out_all[is.na(dat.out_all[,i]), i] <- mean(dat.out_all[,i], na.rm = TRUE);
	}
}
if (F) {
if (sum(is.na(dat.out))>0) {
	message ("NA values need to be imputed for specific samples. ")
	for(i in 1:ncol(dat.out)){
		dat.out[is.na(dat.out[,i]), i] <- mean(dat.out[,i], na.rm = TRUE);
	}
}
}
#output specific samples
#dim(dat.out)
#head(dat.out[,1:5])
#w.table(dat.out, file=outfile, T, T, col1name="recordId", quote=T, append=F, sep=",")
#output all samples
dim(dat.out_all)
head(dat.out_all[,1:5])
w.table(dat.out_all, file=outfile.all, T, T, col1name="recordId", quote=T, append=F, sep=",")

###debug
datfile= "~/PD_dream/proc_raw_features/run_table_v3_testing/tj2_j11.txt"
#feature_ranking_file="~/PD_dream/R2_R11_feature_selection_PDdream/Merging_rf_svm_imp_feature_selection/merge_svm_rf_imp_top3000.txt"
feature_ranking_file="/home/xz345/PD_dream/R2_R11_feature_selection_PDdream/Hcode432/FS_knn_glmnet_rf/merge_rf_knn_glmnet_imp_top1500.txt"
num = 900 
outfile = "mPower_feature5_required.csv"
outfile.all = "mPower_feature5_all.csv"
#traindatfile = "~/PD_dream/proc_raw_features/run_table_v3_training/j2_j11.txt"
#traindatfile = "~/PD_dream/proc_raw_features/run_table_v3_alltraining/temp.txt"
traindatfile = "/home/xz345/PD_dream/proc_raw_features/run_table_v3_alltraining/j2_j11.txt"

