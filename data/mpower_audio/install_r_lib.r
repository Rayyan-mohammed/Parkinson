#necessary R libraries before installing PDdream


rm(list=ls());
options("scipen"=1, "digits"=4, stringsAsFactors=FALSE);

packages = c(
			 "devtools",
			 "plyr",
			 "dplyr",
			 "ggplot2",
			 "doMC",
			 "jsonlite",
			 "parallel",
			 "tidyr",
			 "lubridate",
			 "stringr",
			 "caret",
			 "caretEnsemble",
			 'fpp', 
			 "wavelets", 
			 "psd", 
			 "jmotif",
			 "sqldf"
			 )
check_and_install_package = function (libNames) {
	installBioConPackage <- function (libName) {
		message (paste0("Package ", libName, " need to be installed.\n"))
		source("http://www.bioconductor.org/biocLite.R")
		biocLite(libName)
	}
	for (libName in libNames) {
		if (!(libName %in% installed.packages())) {
			installBioConPackage(libName)
			if ((libName %in% installed.packages())) {
				message (paste0("Package ", libName, " is successfully installed.\n"))
			} else {
				message (paste0("Package ", libName, " is failed to be installed.\n"))
			}
		}
	}
}

check_and_install_package(packages)
if (!("synapseClient" %in% installed.packages())) {
	require(devtools)
	install_github('Sage-Bionetworks/rSynapseClient', ref = 'develop')
}
if (!("mpowertools" %in% installed.packages())) {
	require(devtools)
	devtools::install_github("Sage-Bionetworks/mpowertools")
}
if (!("TSPatternQuery" %in% installed.packages())) {
	require(devtools)
	devtools::install_github("joshmarsh/TSPatternQuery") 
}

