#################SETUP####################
#for cv repeat times
repeats = 1
#for tune length parameter
tuneLength = 2
train_out_rdata = "../train.dat.rdata"
bootstrap.num = 500
bootstrap.perc = 0.7
CPUnum = 1
memory = "6000M"
outd = "bagging_imp_out"
ml.method = c("rf")
outf = paste0(ml.method, "_", bootstrap.num, "_imp.txt")
pdffile = paste0(ml.method, "_", bootstrap.num, "_imp.pdf")

metric = "Accuracy" # "ROC", "logLoss" "Accuracy"

fork_script = "~/PD_dream/scripts/feature_selection/feature_selection_rf_svm_screen_02_fork_v2.R"
casecontrol = F
mysummaryFunction = multiClassSummary #twoClassSummary or multiClassSummary
#################SETUP####################


