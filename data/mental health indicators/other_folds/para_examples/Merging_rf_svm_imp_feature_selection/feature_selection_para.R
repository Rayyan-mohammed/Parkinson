####################################
CPUnum = 10
comm.mem = "60000M"
ensemble.mem = "120000M"
queue = "general"

casecontrol = T
train_out_rdata = "../train.dat.rdata"
test_out_rdata = "../testing.XY.rdata"
validation_rdata = "../validation.XY.rdata"
response.level = c("Cont", "Case")

repeats = 2

outdir = "FS_validation"

snp.rank.f = "merge_svm_rf_imp_top3000.txt"
snp.rank.f.header = T

from = 2
to = NA
length.out = 41

ml.algorithm = c("svmRadial", "rf", "knn", "xgbTree", "caretEnsemble")
#ml.algorithm = c("caretEnsemble")
ml.algorithm = c("svmRadial","knn", "rf", "caretEnsemble")
ensemble.ml.algorithm = c("glmnet", "svmRadial","knn", "rf", "nnet")
#ensemble.ml.algorithm = c("svmRadial","knn")

fork_script = "~/PD_dream/scripts/feature_selection/feature_selection_rf_svm_screen_02_fork_v2.R"
####################################
