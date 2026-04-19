#!/usr/bin/env Rscript --slave

argv    <- commandArgs(TRUE);
f       <- as.numeric(argv[1]);
from    <- as.numeric(argv[2]);
to      <- as.numeric(argv[3]);
outf    <- argv[4];
data_type    <- argv[5]; #either "training", "supp", or "testing"

library(PDdream);

if (data_type == "testing") {
	mdir  <- "~/PD_dream/download_testing_data/";
	fname <- c("accel_walking_outbound.json.items_testing.features.rdata", "accel_walking_rest.json.items_testing.features.rdata",
			   "accel_walking_return.json.items_testing.features.rdata", "deviceMotion_walking_outbound.json.items_testing.features.rdata",
			   "deviceMotion_walking_rest.json.items_testing.features.rdata", "deviceMotion_walking_return.json.items_testing.features.rdata");
} else if (data_type == "supp") {            
	mdir  <- "~/PD_dream/download_supp_data/";
	fname <- c("accel_walking_outbound.json.items_supp.features.rdata", "accel_walking_rest.json.items_supp.features.rdata",
			   "accel_walking_return.json.items_supp.features.rdata", "deviceMotion_walking_outbound.json.items_supp.features.rdata",
			   "deviceMotion_walking_rest.json.items_supp.features.rdata", "deviceMotion_walking_return.json.items_supp.features.rdata");
} else if (data_type == "training") {
	mdir  <- "~/PD_dream/download_training_data/";
	fname <- c("accel_walking_outbound.json.items.features.rdata", "accel_walking_rest.json.items.features.rdata",
			   "accel_walking_return.json.items.features.rdata", "deviceMotion_walking_outbound.json.items_testing.features.rdata",
			   "deviceMotion_walking_rest.json.items.features.rdata", "deviceMotion_walking_return.json.items_testing.features.rdata");
} else {
	stop ("wrong data_type")
}

out.m <- NULL;

infile <- paste0(mdir, fname[f]);
dat    <- load_obj(infile);
idxes  <- unique(dat$idx);
idxes  <- idxes[from:to];
for (idx in idxes){
	i   <- which(dat$idx==idx);
	if (length(i) < 1){
		t.l <- NA;
	} else {
		t.l <- max(dat$timestamp[i]) - min(dat$timestamp[i]);
	}
	if (f < 4){
		## for acc
		if (length(i) < 1){
			out.m <- rbind(out.m, c(idx, "x", "W", t.l, rep(NA, 35)));
			out.m <- rbind(out.m, c(idx, "x", "V", t.l, rep(NA, 35)));
			out.m <- rbind(out.m, c(idx, "y", "W", t.l, rep(NA, 35)));
			out.m <- rbind(out.m, c(idx, "y", "V", t.l, rep(NA, 35)));
			out.m <- rbind(out.m, c(idx, "z", "W", t.l, rep(NA, 35)));
			out.m <- rbind(out.m, c(idx, "z", "V", t.l, rep(NA, 35)));
		} else {
			v   <- dat$x[i];
			if (mean(v) > 10){
				out.m <- rbind(out.m, c(idx, "x", "W", t.l, rep(NA, 35)));
				out.m <- rbind(out.m, c(idx, "x", "V", t.l, rep(NA, 35)));
			} else {
				out1 <- wavelets_f_max(v);
				out.m <- rbind(out.m, c(idx, "x", "W", t.l, out1$W));
				out.m <- rbind(out.m, c(idx, "x", "V", t.l, out1$V));
			}
			v   <- dat$y[i];
			out1 <- wavelets_f_max(v);
			out.m <- rbind(out.m, c(idx, "y", "W", t.l, out1$W));
			out.m <- rbind(out.m, c(idx, "y", "V", t.l, out1$V));
			v   <- dat$z[i];
			out1 <- wavelets_f_max(v);
			out.m <- rbind(out.m, c(idx, "z", "W", t.l, out1$W));
			out.m <- rbind(out.m, c(idx, "z", "V", t.l, out1$V));
		}
	} else {
		## for dev
		if (length(i) < 1){
			out.m <- rbind(out.m, c(idx, "att.y", "W", t.l, rep(NA, 35)));
			out.m <- rbind(out.m, c(idx, "att.y", "V", t.l, rep(NA, 35)));
			out.m <- rbind(out.m, c(idx, "att.x", "W", t.l, rep(NA, 35)));
			out.m <- rbind(out.m, c(idx, "att.x", "V", t.l, rep(NA, 35)));
			out.m <- rbind(out.m, c(idx, "att.w", "W", t.l, rep(NA, 35)));
			out.m <- rbind(out.m, c(idx, "att.w", "V", t.l, rep(NA, 35)));
			out.m <- rbind(out.m, c(idx, "att.z", "W", t.l, rep(NA, 35)));
			out.m <- rbind(out.m, c(idx, "att.z", "V", t.l, rep(NA, 35)));
			out.m <- rbind(out.m, c(idx, "rot.y", "W", t.l, rep(NA, 35)));
			out.m <- rbind(out.m, c(idx, "rot.y", "V", t.l, rep(NA, 35)));
			out.m <- rbind(out.m, c(idx, "rot.x", "W", t.l, rep(NA, 35)));
			out.m <- rbind(out.m, c(idx, "rot.x", "V", t.l, rep(NA, 35)));
			out.m <- rbind(out.m, c(idx, "rot.z", "W", t.l, rep(NA, 35)));
			out.m <- rbind(out.m, c(idx, "rot.z", "V", t.l, rep(NA, 35)));
			out.m <- rbind(out.m, c(idx, "use.y", "W", t.l, rep(NA, 35)));
			out.m <- rbind(out.m, c(idx, "use.y", "V", t.l, rep(NA, 35)));
			out.m <- rbind(out.m, c(idx, "use.x", "W", t.l, rep(NA, 35)));
			out.m <- rbind(out.m, c(idx, "use.x", "V", t.l, rep(NA, 35)));
			out.m <- rbind(out.m, c(idx, "use.z", "W", t.l, rep(NA, 35)));
			out.m <- rbind(out.m, c(idx, "use.z", "V", t.l, rep(NA, 35)));
			out.m <- rbind(out.m, c(idx, "gra.y", "W", t.l, rep(NA, 35)));
			out.m <- rbind(out.m, c(idx, "gra.y", "V", t.l, rep(NA, 35)));
			out.m <- rbind(out.m, c(idx, "gra.x", "W", t.l, rep(NA, 35)));
			out.m <- rbind(out.m, c(idx, "gra.x", "V", t.l, rep(NA, 35)));
			out.m <- rbind(out.m, c(idx, "gra.z", "W", t.l, rep(NA, 35)));
			out.m <- rbind(out.m, c(idx, "gra.z", "V", t.l, rep(NA, 35)));
		} else {
			v   <- dat$attitude.y[i];
			out1 <- wavelets_f_max(v);
			if (length(out1$W) < 35){
				out.m <- rbind(out.m, c(idx, "att.y", "W", t.l, out35(out1$W)));
				out.m <- rbind(out.m, c(idx, "att.y", "V", t.l, out35(out1$V)));
			} else {
				out.m <- rbind(out.m, c(idx, "att.y", "W", t.l, out1$W));
				out.m <- rbind(out.m, c(idx, "att.y", "V", t.l, out1$V));
			}
			v   <- dat$attitude.x[i];
			out1 <- wavelets_f_max(v);
			if (length(out1$W) < 35){
				out.m <- rbind(out.m, c(idx, "att.x", "W", t.l, out35(out1$W)));
				out.m <- rbind(out.m, c(idx, "att.x", "V", t.l, out35(out1$V)));
			} else {
				out.m <- rbind(out.m, c(idx, "att.x", "W", t.l, out1$W));
				out.m <- rbind(out.m, c(idx, "att.x", "V", t.l, out1$V));
			}
			v   <- dat$attitude.w[i];
			out1 <- wavelets_f_max(v);
			if (length(out1$W) < 35){
				out.m <- rbind(out.m, c(idx, "att.w", "W", t.l, out35(out1$W)));
				out.m <- rbind(out.m, c(idx, "att.w", "V", t.l, out35(out1$V)));
			} else {
				out.m <- rbind(out.m, c(idx, "att.w", "W", t.l, out1$W));
				out.m <- rbind(out.m, c(idx, "att.w", "V", t.l, out1$V));
			}
			v   <- dat$attitude.z[i];
			out1 <- wavelets_f_max(v);
			if (length(out1$W) < 35){
				out.m <- rbind(out.m, c(idx, "att.z", "W", t.l, out35(out1$W)));
				out.m <- rbind(out.m, c(idx, "att.z", "V", t.l, out35(out1$V)));
			} else {
				out.m <- rbind(out.m, c(idx, "att.z", "W", t.l, out1$W));
				out.m <- rbind(out.m, c(idx, "att.z", "V", t.l, out1$V));
			}

			v   <- dat$rotationRate.y[i];
			out1 <- wavelets_f_max(v);
			if (length(out1$W) < 35){
				out.m <- rbind(out.m, c(idx, "rot.y", "W", t.l, out35(out1$W)));
				out.m <- rbind(out.m, c(idx, "rot.y", "V", t.l, out35(out1$V)));
			} else {
				out.m <- rbind(out.m, c(idx, "rot.y", "W", t.l, out1$W));
				out.m <- rbind(out.m, c(idx, "rot.y", "V", t.l, out1$V));
			}
			v   <- dat$rotationRate.x[i];
			out1 <- wavelets_f_max(v);
			if (length(out1$W) < 35){
				out.m <- rbind(out.m, c(idx, "rot.x", "W", t.l, out35(out1$W)));
				out.m <- rbind(out.m, c(idx, "rot.x", "V", t.l, out35(out1$V)));
			} else {
				out.m <- rbind(out.m, c(idx, "rot.x", "W", t.l, out1$W));
				out.m <- rbind(out.m, c(idx, "rot.x", "V", t.l, out1$V));
			}
			v   <- dat$rotationRate.z[i];
			out1 <- wavelets_f_max(v);
			if (length(out1$W) < 35){
				out.m <- rbind(out.m, c(idx, "rot.z", "W", t.l, out35(out1$W)));
				out.m <- rbind(out.m, c(idx, "rot.z", "V", t.l, out35(out1$V)));
			} else {
				out.m <- rbind(out.m, c(idx, "rot.z", "W", t.l, out1$W));
				out.m <- rbind(out.m, c(idx, "rot.z", "V", t.l, out1$V));
			}

			v   <- dat$userAcceleration.y[i];
			out1 <- wavelets_f_max(v);
			if (length(out1$W) < 35){
				out.m <- rbind(out.m, c(idx, "use.y", "W", t.l, out35(out1$W)));
				out.m <- rbind(out.m, c(idx, "use.y", "V", t.l, out35(out1$V)));
			} else {
				out.m <- rbind(out.m, c(idx, "use.y", "W", t.l, out1$W));
				out.m <- rbind(out.m, c(idx, "use.y", "V", t.l, out1$V));
			}
			v   <- dat$userAcceleration.x[i];
			out1 <- wavelets_f_max(v);
			if (length(out1$W) < 35){
				out.m <- rbind(out.m, c(idx, "use.x", "W", t.l, out35(out1$W)));
				out.m <- rbind(out.m, c(idx, "use.x", "V", t.l, out35(out1$V)));
			} else {
				out.m <- rbind(out.m, c(idx, "use.x", "W", t.l, out1$W));
				out.m <- rbind(out.m, c(idx, "use.x", "V", t.l, out1$V));
			}
			v   <- dat$userAcceleration.z[i];
			out1 <- wavelets_f_max(v);
			if (length(out1$W) < 35){
				out.m <- rbind(out.m, c(idx, "use.z", "W", t.l, out35(out1$W)));
				out.m <- rbind(out.m, c(idx, "use.z", "V", t.l, out35(out1$V)));
			} else {
				out.m <- rbind(out.m, c(idx, "use.z", "W", t.l, out1$W));
				out.m <- rbind(out.m, c(idx, "use.z", "V", t.l, out1$V));
			}

			v   <- dat$gravity.y[i];
			out1 <- wavelets_f_max(v);
			if (length(out1$W) < 35){
				out.m <- rbind(out.m, c(idx, "gra.y", "W", t.l, out35(out1$W)));
				out.m <- rbind(out.m, c(idx, "gra.y", "V", t.l, out35(out1$V)));
			} else {
				out.m <- rbind(out.m, c(idx, "gra.y", "W", t.l, out1$W));
				out.m <- rbind(out.m, c(idx, "gra.y", "V", t.l, out1$V));
			}
			v   <- dat$gravity.x[i];
			out1 <- wavelets_f_max(v);
			if (length(out1$W) < 35){
				out.m <- rbind(out.m, c(idx, "gra.x", "W", t.l, out35(out1$W)));
				out.m <- rbind(out.m, c(idx, "gra.x", "V", t.l, out35(out1$V)));
			} else {
				out.m <- rbind(out.m, c(idx, "gra.x", "W", t.l, out1$W));
				out.m <- rbind(out.m, c(idx, "gra.x", "V", t.l, out1$V));
			}
			v   <- dat$gravity.z[i];
			out1 <- wavelets_f_max(v);
			if (length(out1$W) < 35){
				out.m <- rbind(out.m, c(idx, "gra.z", "W", t.l, out35(out1$W)));
				out.m <- rbind(out.m, c(idx, "gra.z", "V", t.l, out35(out1$V)));
			} else {
				out.m <- rbind(out.m, c(idx, "gra.z", "W", t.l, out1$W));
				out.m <- rbind(out.m, c(idx, "gra.z", "V", t.l, out1$V));
			}
		}
	}
}
out.m = cbind(rep(f, nrow(out.m)), out.m)
if (data_type == "supp") {
	    out.m[,2] = paste0("s.", out.m[,2])
}
write.table(out.m, outf, row.names=F, col.names=F, quote=F, sep="\t");



