#!/usr/bin/env Rscript
rm(list=ls());
options("scipen"=1, "digits"=4, stringsAsFactors=FALSE);
library(PDdream)

args<-commandArgs(T)
infile = args[1] 	#run1.txt
outfile = args[2] #"run1_table.txt";
code = args[3] 		# m1.f

CPUnum = 10

inf1 <- "~/PD_dream/download_training_data/actv_walking.rdata"
load(inf1);
inf2 <- "~/PD_dream/download_supp_data/supp_training.rdata"
load(inf2);
tmp     <-  supp_training[,c(2,15)];
tmp[,2] <- paste0("s.", tmp[,2])
walking <- rbind(actv_walking[,c(2,15)], tmp);
hcode   <- unique(walking[,1]);

#dat      <- read.table("run1.txt");
dat      <- r.table(infile, F);
s.name   <- paste0(dat[,1], "_", dat[,3], "_", dat[,4]);
s.name.u <- unique(s.name);
s.col.n  <- paste0(code, rep(s.name.u, each=34), ".", 1:34);

## f1.x.W1 ... f6_gra.z_V34
out.s   <- NULL;
library(doParallel)
registerDoParallel(cores = CPUnum)
out.s <- foreach (hd.i = 1:length(hcode), .combine = rbind) %dopar%
#for (hd.i in 1:length(hcode))
{
  print(c(hd.i, length(hcode)));
  hd    <- hcode[hd.i];
  out   <- hd;
  h.i   <- which(walking[,]==hd);
  idx   <- walking[h.i,2];
  d.i   <- which(dat[,2] %in% idx);
  dat.s <- dat[d.i,];
  s.n.s <- s.name[d.i];
  for (s.n in s.name.u){
    s.i <- which(s.n.s %in% s.n);
    if (length(s.i) < 1){
      out <- c(out, rep("NA", 34));
    } else if (length(s.i)==1){
      tmp <- dat.s[s.i,];
      out <- c(out, tmp[-c(1:6)]);
    } else {
      tmp   <- dat.s[s.i,];
      ## filter if level number < 10;
      tmp.i <- which(tmp[,6] > 9)
      if (length(tmp.i) > 0){
        tmp <- tmp[tmp.i,-c(1:6)];
      } else {
        tmp <- tmp[,-c(1:6)];
      }
      tmp <- as.matrix(tmp);
      tmp <- apply(tmp, 2, function(x) mean(as.numeric(x), na.rm = T));
      tmp <- round(tmp, 3);
      out <- c(out, tmp);
    }
  }
  out.s <- rbind(out.s, out);
}

colnames(out.s) <- c("healthCode", s.col.n);
write.table(out.s, outfile, row.names=F, sep="\t", quote=F);

#debug
infile = "run9.txt"
outfile = "run9_table.txt"
code = "m9.f"

