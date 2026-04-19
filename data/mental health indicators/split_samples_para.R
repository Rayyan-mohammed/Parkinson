################SET UP#################
#input
input_dat = "../proc_raw_features/j2_j11.txt"
input_demo = "demo.txt"
response_col = "professional-diagnosis"  #response name or No.
sample_col = "healthCode"  #sample name or No.
dat_header = T #if the dat file has a header

#output
training_output  = "train.dat.rdata"
testing_output  = "testing.XY.rdata"
validation_output  = "validation.XY.rdata"
demo_output = "demo_allocated.txt" # for output the sets

#percentage
training_perc = 0.7
validation_perc = 0.2
testing_perc = 0.1

#if imputation NA with random forest
if_imputation_na = T
################SET UP#################

