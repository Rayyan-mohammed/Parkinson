#!/usr/bin/env Rscript
rm(list=ls());
options("scipen"=1, "digits"=4, stringsAsFactors=FALSE);
library(PDdream)

args<-commandArgs(T)
infile = args[1] 	#run1.txt
outfile = args[2] #"run1_table.txt";

CPUnum = 10

inf1 <- "~/PD_dream/download_training_data/actv_walking.rdata"
load(inf1);
inf2 <- "~/PD_dream/download_supp_data/supp_training.rdata"
load(inf2);
tmp     <-  supp_training[,c(1,2,15)];
tmp[,3] <- paste0("s.", tmp[,3])
walking <- rbind(actv_walking[,c(1,2,15)], tmp);
recordId  <- unique(walking[,1]);

#filter recordId
remotef = "~/PD_dream/download_training_data/Merged_demos_covs_walktest_training.csv"
remotef = "~/PD_dream/PDChallenge_SC1_SubmissionTemplate.csv"
d.r = read.csv(remotef, T)
r.i = match(d.r[,1], recordId, nomatch= 0)
recordId2 = recordId[r.i]
length(recordId2)
#[1] 6043
length(recordId)
#[1] 42504

dat      <- r.table(infile, F);

out.s   <- NULL;
library(doParallel)
registerDoParallel(cores = CPUnum)
out.s <- foreach (rd.i = 1:length(recordId2), .combine = rbind) %dopar%
#for (rd.i in 1:length(recordId2))
{
  print(c(rd.i, length(recordId2)));
  rd    <- recordId2[rd.i];
  out   <- rd;
  h.i   <- which(walking[,]==rd);
  idx   <- walking[h.i, 3];
  d.i   <- which(dat[,2] %in% idx);
  dat.s <- dat[d.i,];
  out.s <- rbind(out.s, dat.s);
}

write.table(out.s, outfile, col.names=F, row.names=F, sep="\t", quote=F);

#debug
infile = "run9.txt"
outfile = "run9_f.txt"

