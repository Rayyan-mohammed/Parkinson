#source("~/mybiotools/r/", echo=T)
rm(list=ls());
options("scipen"=1, "digits"=4, stringsAsFactors=FALSE);
source("~/mybiotools/r/myfunc.R");
library(PDdream)

user = NA
password = NA

require(synapseClient)
if (!is.na(user)) {
	synapseLogin(
				 rememberMe = T,
				 username = user,
				 password = password
				 )
} else {
	synapseLogin(rememberMe = T)
}
demo_syntable <- synTableQuery("SELECT * FROM syn10146552")
demo <- demo_syntable@values
healthCodeCol <- c(as.character(demo$healthCode))
healthCodeList <-
	paste0(sprintf("'%s'", healthCodeCol), collapse = ", ")

###############################################################
#for supplementary training data
SYNID = 'syn10495809'
LdopaTraining_syntable <-
	synTableQuery(
				  paste0(
						 "SELECT * FROM  ",
						 SYNID
						 )
				  )   
#tsv_files = syn.downloadTableColumns(query_table, "dataFileHandleId")

LdopaTraining <- LdopaTraining_syntable@values
LdopaTraining$idx <- rownames(LdopaTraining)
save(LdopaTraining, file = "LdopaTraining.rdata")

DL_headers = colnames(LdopaTraining)[1]

LdopaTraining_tsv_files <-
	synDownloadTableColumns(LdopaTraining_syntable, DL_headers)
LdopaTraining_tsv_files <-
	data.frame(
			   LdopaTraining_tsv_fileId = names(LdopaTraining_tsv_files),
			   LdopaTraining_tsv_file = as.character(LdopaTraining_tsv_files)
			   )
LdopaTraining_tsv_files <- LdopaTraining_tsv_files %>%
distinct(LdopaTraining_tsv_file, .keep_all = TRUE)
save(LdopaTraining_tsv_files, file = "LdopaTraining_tsv_files.rdata")

