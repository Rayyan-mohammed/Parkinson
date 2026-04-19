#source("~/mybiotools/r/", echo=T)
rm(list=ls());
options("scipen"=1, "digits"=4, stringsAsFactors=FALSE);
#source("~/mybiotools/r/myfunc.R");
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
SYNID = 'syn10733835'
supp_training_syntable <-
	synTableQuery(
				  paste0(
						 "SELECT * FROM  ",
						 SYNID,
						 " WHERE healthCode IN ",
						 "(",
						 healthCodeList,
						 ")"
						 )
				  )   
supp_training <- supp_training_syntable@values
supp_training$idx <- rownames(supp_training)
save(supp_training, file = "supp_training.rdata")

DL_headers = colnames(supp_training)[6:13]

supp_training_json_files <-
	synDownloadTableColumns(supp_training_syntable, DL_headers)
supp_training_json_files <-
	data.frame(
			   supp_training_json_fileId = names(supp_training_json_files),
			   supp_training_json_file = as.character(supp_training_json_files)
			   )
supp_training_json_files <- supp_training_json_files %>%
distinct(supp_training_json_file, .keep_all = TRUE)
save(supp_training_json_files, file = "supp_training_json_files.rdata")

