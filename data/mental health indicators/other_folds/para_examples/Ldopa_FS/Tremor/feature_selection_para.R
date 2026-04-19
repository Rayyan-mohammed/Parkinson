####################################
CPUnum = 20
comm.mem = "120000M"
ensemble.mem = "120000M"
queue = "general"

casecontrol = F
train_out_rdata = "../train.dat.rdata"
test_out_rdata = "../testing.XY.rdata"
#response.level = c("Cont", "Case")

repeats = 2
outdir = "FS_training"

snp.rank.f = "../bagging_importance_rf/rf_500_imp.txt"
snp.rank.f.header = T

from = 2
to = NA
length.out = 21
#snp.num = c(1575, 1501, 1351, 1051, 751, 451, 151)

#ml.algorithm = c("xgbTree", "knn", "rf", "nnet", "caretEnsemble")
#ml.algorithm = c("svmRadial", "glmnet", "rf")
ml.algorithm = c("svmLinear", "glmnet", "rf")
#ensemble.ml.algorithm = c("glmnet", "svmLinear","knn", "rf")
ensemble.ml.algorithm = c("svmRadial","glmnet", "rf")

metric = "Accuracy" # "ROC", "logLoss" "Accuracy"

fork_script = "~/PD_dream/scripts/feature_selection/feature_selection_rf_svm_screen_02_fork_v2.R"
casecontrol = F
mysummaryFunction = multiClassSummary #twoClassSummary or multiClassSummary
####################################
