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

snp.rank.f = "top_1501_m2m9_imp.txt"
snp.rank.f.header = T

from = 2
to = NA
length.out = 11

ml.algorithm = c("svmRadial", "rf", "knn", "xgbTree", "caretEnsemble")
#ml.algorithm = c("caretEnsemble")
ml.algorithm = c("rf")
ml.algorithm = c("svmRadial","knn", "rf", "caretEnsemble")
#ml.algorithm = c("svmRadial","knn", "rf")
ensemble.ml.algorithm = c("svmRadial","knn", "rf", "glmnet")
nnetweight.factor = 13

fork_script = "/ycga-gpfs/project/fas/wang_zhengrong/xz345/work/other/PD_dream/rawdata/PDBiomarkerChallenge-master/scripts/feature_selection/feature_selection_rf_svm_screen_02_fork_v2.R"
####################################
