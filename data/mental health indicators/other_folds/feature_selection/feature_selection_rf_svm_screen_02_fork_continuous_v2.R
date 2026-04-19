#!/usr/bin/env Rscript
#source("~/mybiotools/r/", echo=T)
#rm(list=ls());
options("scipen"=3, "digits"=4, stringsAsFactors=FALSE);
source("~/mybiotools/r/myfunc.R");

library(caret)
library(plyr); 
library(dplyr)
library(kernlab) # support vector machine 
library(doMC)

args<-commandArgs(T)

CPUnum = as.numeric(args[1])
in_rdata = args[2]
method = args[3]
tuneLength = as.numeric(args[4])
out_rdata = args[5]
repeats = as.numeric(args[6])
val.index.list.f = args[7]


registerDoMC(CPUnum)
load(in_rdata)

savePredictions = "final"
nnetweight.factor = 10
pp = c("center", "scale") #preProc / preProcess parameter, NULL, center, scale ...
ensemble.ml.algorithm = c("svmLinear", "glmnet", "xgbTree")
continue_on_fail = T #for caretList

if (file.exists("./bagging_importance_para.R")) #in imp ranking process
	source("./bagging_importance_para.R", echo=T)
if (file.exists("./feature_selection_para.R"))  #in feature selection process
	source("./feature_selection_para.R", echo=T)

MaxNWts = as.numeric(nnetweight.factor * (ncol(X) + 1) + nnetweight.factor + 1)

set.seed(1492)

if (is.na(val.index.list.f)) {
	ctrl <- trainControl(method = "repeatedcv", number = 10, repeats = repeats, 
						 #						 summaryFunction=twoClassSummary,
						 classProbs = F, 
						 savePredictions = savePredictions)
} else {
	load(val.index.list.f)
	ctrl <- trainControl(method = "boot", number = length(val.index.list), 
						 #						 summaryFunction=twoClassSummary,
						 index = val.index.list,
						 classProbs = F, 
						 savePredictions = savePredictions)
}

if (method == "nnet") {
	svm.tune <- train(x = X, y = Y, method = method, 
					  #metric = "ROC", 
					  trControl = ctrl, tuneLength = tuneLength, MaxNWts=MaxNWts, preProcess=pp)
} else if (method == "caretEnsemble")  {
	library(caretEnsemble)
	#methodList = c("svmRadial", "rf", "xgbTree")
	set.seed(123)
	dat = data.frame(cbind(X, response=Y), check.names=F)
	tuneList = list()
	for (ml in ensemble.ml.algorithm) {
		if (ml == "nnet") {
			tuneList[[length(tuneList)+1]] = caretModelSpec(method = ml, trace=F, MaxNWts=MaxNWts)
		} else if (ml == "nnet") {
		} else if (ml == "glmnet") {
			enetGrid = expand.grid(.alpha = seq(.05, 1, length = 5),
								   .lambda = c((1:5)/10))
			tuneList[[length(tuneList)+1]] = caretModelSpec(method = ml, "tuneGrid" = enetGrid)
		} else {
			tuneList[[length(tuneList)+1]] = caretModelSpec(method = ml)
		}
	}

	model_list <- caretList(
							response~.,
							data=dat,
							trControl=ctrl,
							#metric = "ROC",
							tuneList = tuneList,
							tuneLength = tuneLength,
							continue_on_fail = continue_on_fail,
							preProc = pp
							#methodList=ensemble.ml.algorithm
							)
	svm.tune <-
		caretEnsemble(
					  model_list,
					  #metric="ROC",
					  trControl=trainControl(
											 number=length(model_list),
											 summaryFunction=twoClassSummary,
											 classProbs=TRUE
											 )
					  #trControl=my_control
					  )
	#summary(greedy_ensemble)
	#svm.tune = greedy_ensemble

} else if (method == "xgbTree") {
	xgb.grid <- expand.grid(nrounds = 1000,
							eta = c(0.01,0.1,0.3,0.4),
							colsample_bytree = 1,
							gamma = c(0, 10),
							min_child_weight = c(1L, 10L),
							subsample = c(0.5, 1),
							max_depth = c(4,6,8)
							)
	svm.tune <-train(
					 x = X,
					 y = Y,
					 method = method,
					 trControl=ctrl,
					 tuneGrid=xgb.grid,
					 verbose=T,
					 nthread = CPUnum
					 )
} else {
	svm.tune <- train(x = X, y = Y, method = method, 
					  # metric = "ROC", 
					  trControl = ctrl, tuneLength = tuneLength, preProcess=pp)
}

#original code
if (F) {
	if (method == "nnet") {
		svm.tune <- train(x = X, y = Y, method = method, preProcess = NULL, 
						  #metric = "ROC", 
						  trControl = ctrl, tuneLength = tuneLength, MaxNWts=nnetweight.factor*ncol(X))
	} else if (method == "xgbTree") {
		system(paste(c("Rscript ~/mybiotools/r/feature_selection_xgboost_screen_02_fork_continuous.R", args), collapse=" "))
	} else {
		svm.tune <- train(x = X, y = Y, method = method, preProcess = NULL, 
						  #metric = "ROC", 
						  trControl = ctrl, tuneLength = tuneLength)
	}
}

save(svm.tune, file=out_rdata)

####debug###
CPUnum = 20 
in_rdata = "FS_02out/_tempin_1344.rdata"
in_rdata = "train.XY.rdata"
method = "rf" 
method = "svmRadial" 
tuneLength = 4 
out_rdata = "testout.rdata"
repeats = 2
nnetweight.factor = 2


