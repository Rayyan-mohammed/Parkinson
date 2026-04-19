#source("~/mybiotools/r/", echo=T)
rm(list=ls());
options("scipen"=1, "digits"=4, stringsAsFactors=FALSE);

library(PDdream)

rawdata2dm <- function (actv_data, json_files, dataColumnName, jsonColumnName, jsonFileColumnName, threads=1, savedir = ".", outfile=NULL) {
    
    all_names = c("accel_walking_outbound.json.items",	"deviceMotion_walking_outbound.json.items",	"pedometer_walking_outbound.json.items",	"accel_walking_return.json.items",	"deviceMotion_walking_return.json.items",	"pedometer_walking_return.json.items",	"accel_walking_rest.json.items",	"deviceMotion_walking_rest.json.items")
    if (is.na(match(dataColumnName, all_names))) {
        stop (paste("dataColumnName has to be one of the following: ", paste(all_names, collapse = ", " )))
    }
    
    # data(actv_data)
    # data(json_files)
    selected_records <- actv_data$idx
    actv_data <-
        merge(
            actv_data,
            json_files,
            by.x = dataColumnName,
            #by.y = names(json_files)[1],
            by.y = jsonColumnName,
            all.x = TRUE,
            all.y = F
        )
    
    # add walking json files columns
    actv_data <-
        actv_data %>% mutate(jsonFileColumnName = as.character(jsonFileColumnName))
    
    # remove duplicates
    actv_data <- actv_data %>%
        distinct(json_files, .keep_all = TRUE)
    dim(actv_data)

    #############
    # Feature Extraction
    ##############
    registerDoMC(threads)
    
    #for test
    #actv_data = head(actv_data, n = 1000)
    json_file = actv_data[1, 16]
    dat <- jsonlite::fromJSON(json_file)
    str(dat)
    (dat.ncol <- length(names(unlist(dat[1, , drop = F]))))
    
    my.getWalkFeatures = function (json_file) {
        if (is.na(json_file) == T | is.null(json_file)) {
            return (rep(NA, times = dat.ncol))
        }
        dat <- try (jsonlite::fromJSON(json_file))
        if (is.null(dat)) {
            return (rep(NA, times = dat.ncol))
        }
        if (class(dat) == "try-error" | length(unlist(dat)) < dat.ncol) {
            return (rep(NA, times = dat.ncol))
        }
        dat.m <- try (matrix(unlist(dat), ncol = dat.ncol, byrow = F))
        if (class(dat.m) == "try-error") {
            return (rep(NA, times = dat.ncol))
        }
        dat.name = try(names(unlist(dat[1, , drop = F])))
        if (class(dat.name) == "try-error" |
            dim(dat.m)[2] != length(dat.name)) {
            return (rep(NA, times = dat.ncol))
        }
        colnames(dat.m) = dat.name
        return (dat.m)
    }
    
    walkFeatures <-
        dlply(
            .data = actv_data,
            .variables = ("idx"),
            .fun = function(row) {
                my.getWalkFeatures(row$outbound_json_file)
            },
            .parallel = T
        )
    
    length(walkFeatures)
    countna = function (x) {
        sum(is.na(x))
    }
    checkna = unlist(sapply(walkFeatures, countna))
    checkna.l = (checkna == dat.ncol)
    if (length(which(checkna.l)) > 0) {
        walkFeatures = walkFeatures[-which(checkna.l)]
    }
    length(walkFeatures)
    length(which(checkna.l))
    
    #transforming to data frame
    #walkFeatures.df = matrix(unlist(walkFeatures), ncol = dat.ncol, byrow = F)
    output <-
        do.call(rbind,
                lapply(walkFeatures, matrix, ncol = dat.ncol, byrow = F))
    colnames(output) = colnames(walkFeatures[[1]])
    nn = unlist(sapply(walkFeatures, nrow))
    idx = rep(names(nn), nn)
    walkFeatures.df = cbind(idx = idx, as.data.frame(output))
    str(walkFeatures.df)
    
    # Only keep the non-redundant data
    features.matrix <-
        walkFeatures.df %>% filter(idx %in% selected_records)
    if (!dir.exists(savedir)) {
        system(paste0("mkdir -p ", savedir))
    }
    if (is.null(outfile)) outfile = paste0(savedir, "/", dataColumnName, ".features.rdata")
    save(features.matrix, file = outfile)
}

load("supp_training.rdata")
load("supp_training_json_files.rdata")

all_names = c("accel_walking_outbound.json.items",  "deviceMotion_walking_outbound.json.items", "pedometer_walking_outbound.json.items",    "accel_walking_return.json.items",  "deviceMotion_walking_return.json.items",   "pedometer_walking_return.json.items",  "accel_walking_rest.json.items",    "deviceMotion_walking_rest.json.items")

threads = 20
savedir = "."
actv_data = supp_training
json_files = supp_training_json_files
jsonColumnName = "supp_training_json_fileId"
jsonFileColumnName = "supp_training_json_file"
for (n in all_names) {
	dataColumnName = n
	outfile = paste0(savedir, "/", "supp_training_", dataColumnName, ".features.rdata")
	rawdata2dm(actv_data = actv_data, json_files = json_files, dataColumnName = dataColumnName, jsonColumnName=jsonColumnName, jsonFileColumnName=jsonFileColumnName, threads=threads, savedir = savedir, outfile=outfile)
}

