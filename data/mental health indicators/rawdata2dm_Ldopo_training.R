#source("~/mybiotools/r/", echo=T)
rm(list=ls());
options("scipen"=1, "digits"=4, stringsAsFactors=FALSE);

library(PDdream)
# synapseLogin()
synapseLogin(rememberMe=T)

load("LdopaTraining.rdata")
load("LdopaTraining_tsv_files.rdata")

selected_records = LdopaTraining$idx

registerDoMC(10)

determine.ncol = function (Ldopo.task) {
	for (j in 1:10) {
		if (file.exists(Ldopo.task$LdopaTraining_tsv_file[j])) {
			n.col = as.numeric(system(paste0("head -n1 ", Ldopo.task$LdopaTraining_tsv_file[j], " | awk '{print NF}'"), intern=T))
			if (n.col > 0) return (n.col)
		}
	}
}

my.getWalkFeatures = function (tsv_file, dat.ncol) {
	if (is.na(tsv_file) == T) {
		return (rep(NA, times=dat.ncol))
	}
	dat <- read.delim(tsv_file, T)
	if (nrow(dat)  == 0) {
		return (rep(NA, times=dat.ncol))
	}
	return (dat)
}

countna = function (x) {
	sum(is.na(x))
}

task.t = table(LdopaTraining$task)
for (i in 1:length(task.t)) {
	n = names(task.t)[i]
	n.i = which(LdopaTraining$task %in% n)
	Ldopo.task <- merge(LdopaTraining[n.i, ], LdopaTraining_tsv_files, by.x="dataFileHandleId", by.y="LdopaTraining_tsv_fileId", all.x=TRUE, all.y=F)
	Ldopo.task <- Ldopo.task %>% mutate(LdopaTraining_tsv_file = as.character(LdopaTraining_tsv_file))
	# remove duplicates
	Ldopo.task <- Ldopo.task %>% distinct(LdopaTraining_tsv_file, .keep_all = TRUE)
	dim(Ldopo.task)
	dat.ncol = determine.ncol (Ldopo.task)
	LdopoFeatures <-
		dlply(
			  .data = Ldopo.task, 
			  .variables = ("idx"),
			  .fun = function(row) {
				  my.getWalkFeatures(row$LdopaTraining_tsv_file, dat.ncol)
			  },
			  .parallel = TRUE
			  )
	checkna = unlist(sapply(LdopoFeatures, countna))
	checkna.l = (checkna == dat.ncol)
	if (length(which(checkna.l)) > 0 ) {
		LdopoFeatures = LdopoFeatures[-which(checkna.l)]
	}

	norecord.idx.i = which(!(names(LdopoFeatures) %in% selected_records))
	if (length(norecord.idx.i) > 0) LdopoFeatures = LdopoFeatures[[-norecord.idx.i]]
	outf = paste0(n, ".rdata")
	save(LdopoFeatures, file=outf)
}

####

#for test
#Ldopo.task = head(Ldopo.task, n = 1000)

#transforming to data frame
#LdopoFeatures.df = matrix(unlist(LdopoFeatures), ncol = dat.ncol, byrow = F)
#output <- do.call(rbind, lapply(LdopoFeatures, matrix, ncol=dat.ncol, byrow=F))
#colnames(output) = colnames(LdopoFeatures[[1]])
#nn = unlist(sapply(LdopoFeatures, nrow))
#idx = rep(names(nn), nn)
#LdopoFeatures.df = cbind(idx=idx, as.data.frame(output))
#str(LdopoFeatures.df)
#'data.frame':	66413570 obs. of  5 variables:

# Only keep the non-redundant data


