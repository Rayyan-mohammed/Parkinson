#!/usr/bin/env Rscript
#source("~/mybiotools/r/", echo=T)
#rm(list=ls());
options("scipen"=3, "digits"=4, stringsAsFactors=FALSE);
#source("~/mybiotools/r/myfunc.R");

library(caret)
library(dplyr) # Used by caret
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
#nnetweight.factor = as.numeric(args[8])


registerDoMC(CPUnum)
load(in_rdata)

#check response error
y.table = table(Y)
if (sum(y.table <= 1) > 0 ) {
	e.i = which(y.table <= 1)
	if (length(e.i) > 1) {
		e.y.i = c()
		for (ee in e.i) {
			e = names(y.table)[ee]
			e.y.i = c(e.y.i, which(Y == e))
		}
	} else {
		e = names(y.table)[e.i]
		e.y.i = which(Y == e)
	}
	Y = Y[-e.y.i]
	Y = factor(Y)
	X = X[-e.y.i,]
}

savePredictions = "final"
nnetweight.factor = 10
metric = "ROC" # metric, "logLoss"
pp = c("center", "scale") #preProc / preProcess parameter, NULL, center, scale ...
ensemble.ml.algorithm = c("svmLinear", "glmnet", "xgbTree")
continue_on_fail = T #for caretList
mysummaryFunction = twoClassSummary #twoClassSummary or multiClassSummary
classProbs = T

if (file.exists("./bagging_importance_para.R")) #in imp ranking process
	source("./bagging_importance_para.R", echo=T)
if (file.exists("./feature_selection_para.R"))  #in feature selection process
	source("./feature_selection_para.R", echo=T)

MaxNWts = as.numeric(nnetweight.factor * (ncol(X) + 1) + nnetweight.factor + 1)

set.seed(1492)

###if (!casecontrol & metric != "ROC" ) {
if (!casecontrol ) {
	metric = "Accuracy"
	#classProbs = F
}

if (is.na(val.index.list.f)) {
	ctrl <- trainControl(method = "repeatedcv", number = 10, repeats = repeats, summaryFunction=mysummaryFunction, classProbs = classProbs, savePredictions = savePredictions)
} else {
	load(val.index.list.f)
	ctrl <- trainControl(method = "boot", number = length(val.index.list), summaryFunction=mysummaryFunction,
						 index = val.index.list,
						 classProbs=classProbs, savePredictions = savePredictions)
}

if (method == "nnet") {
	svm.tune <- train(x = X, y = Y, method = method, metric = metric, trControl = ctrl, tuneLength = tuneLength, MaxNWts=MaxNWts, preProcess=pp)
} else if (method == "caretEnsemble")  {
	library(caretEnsemble)
	#methodList = c("svmRadial", "rf", "xgbTree")
	set.seed(123)
	#Y = as.numeric(Y)
	if (F) {
		if (is.na(val.index.list.f)) {

			my_control <- trainControl(
									   method="repeatedcv",
									   number=10,
									   repeats = repeats,
									   savePredictions="final",
									   classProbs=classProbs,
									   #index=createResample(training$Class, 25),
									   summaryFunction=mysummaryFunction
									   )
		} else {
			load(val.index.list.f)
			my_control <- trainControl(
									   method="boot",
									   number=length(val.index.list),
									   savePredictions="final",
									   classProbs=classProbs,
									   index=val.index.list,
									   summaryFunction=mysummaryFunction
									   )
		}
	}
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
							metric = metric, 
							tuneList = tuneList,
							tuneLength = tuneLength,
							continue_on_fail = continue_on_fail, 
							preProc = pp
							#methodList=ensemble.ml.algorithm
							)
	svm.tune <- 
		caretEnsemble(
					  model_list, 
					  metric=metric,
					  trControl=trainControl(
											 number=length(model_list),
											 summaryFunction=mysummaryFunction,
											 classProbs=classProbs
											 )
					  #trControl=my_control
					  )
	#summary(greedy_ensemble)
	#svm.tune = greedy_ensemble

} else if (method == "glmnet")  {
	enetGrid = expand.grid(.alpha = seq(.05, 1, length = 5),
						   .lambda = c((1:5)/10))
	svm.tune <- train(x = X, y = Y, method = method, metric = metric, trControl = ctrl, tuneGrid = enetGrid, tuneLength = tuneLength, preProcess=pp)
} else {
	svm.tune <- train(x = X, y = Y, method = method, metric = metric, trControl = ctrl, tuneLength = tuneLength, preProcess=pp)
}

save(svm.tune, file=out_rdata)

####debug###
CPUnum = 10 
in_rdata = "bagging_imp_out/_tempin_101.rdata"
in_rdata = "FS_training/_tempin_15.rdata"
in_rdata = "../bagging_importance_rf/out_bagging_imp/_tempin_426.rdata"
in_rdata = "bagging_imp_out/_tempin_426.rdata"
method = "glmnet" 
method = "svmLinear" 
method = "svmRadial" 
method = "rf" 
tuneLength = 2 
out_rdata = "FS_training/_tempout_svmLinear_224.rdata"
out_rdata = "FS_training/_tempout_glmnet_15.rdata"
out_rdata = "FS_training/_tempout_svmRadial_15.rdata"
out_rdata = "bagging_imp_out/_tempout_rf_426.rdata"
repeats = 1

#val.index.list.f="val.index.list.rdata"


