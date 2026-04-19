#source("~/mybiotools/r/", echo=T)
rm(list=ls());
options("scipen"=1, "digits"=4, stringsAsFactors=FALSE);
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
#for testing data
SYNID = 'syn10733842'
testing_syntable <- synTableQuery("SELECT * FROM syn10733842")
testing <- testing_syntable@values
testing$idx <- rownames(testing)
save(testing, file = "testing.rdata")

DL_headers = colnames(testing)[6:13]
testing_json_files <-
	synDownloadTableColumns(testing_syntable, DL_headers)
testing_json_files <-
	data.frame(
			   testing_json_fileId = names(testing_json_files),
			   testing_json_file = as.character(testing_json_files)
			   )
testing_json_files <- testing_json_files %>%
distinct(testing_json_file, .keep_all = TRUE)
save(testing_json_files, file = "testing_json_files.rdata")   

