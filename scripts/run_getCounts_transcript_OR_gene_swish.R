
# alternative version of 'run_DEG_swish.R' to be used only for counts generation
# it extract counts directly from quants.sf / files, either on transcript- and gene-level
# 2 methods implemented: tximeta (SummarizedExperiment object as output) and tximport (list as output)

# NOTE: doesn't work for gene-level for now
# stop("Stopped intentionally")

if (!requireNamespace("BiocManager", quietly = TRUE)) install.packages("BiocManager")
if (!requireNamespace("SummarizedExperiment", quietly = TRUE)) BiocManager::install("SummarizedExperiment")
if (!requireNamespace("fishpond", quietly = TRUE)) BiocManager::install("fishpond")
if (!requireNamespace("tximeta", quietly = TRUE)) BiocManager::install("tximeta")
if (!requireNamespace("org.Hs.eg.db", quietly = TRUE)) BiocManager::install("org.Hs.eg.db")
if (!requireNamespace("tximport", quietly = TRUE)) BiocManager::install("tximport")

suppressMessages(library(SummarizedExperiment))
suppressMessages(library(fishpond))
suppressMessages(library(tximeta))
suppressMessages(library(tximport))
suppressMessages(library(org.Hs.eg.db))

# get working directory to recognise the machine
w_dir <- getwd()

# create a shortcut for the OneDrive directory where all files are stored
if(startsWith(w_dir, "/Users/michal")){           
  main_dir <- "/Users/michal/Documents/OneDrive - University of Leeds"    # on my mac
} else if (startsWith(w_dir, "/Users/ummz")) {    
  main_dir <- "/Users/ummz/Documents/OneDrive - University of Leeds"      # on uni mac    
} else if (startsWith(w_dir, "/nobackup/ummz")) {
  main_dir <- "/nobackup/ummz"						  # on ARC4 (nobackup)
} else if (startsWith(w_dir, "/home/home02/ummz/")) {
  main_dir <- "/home/home02/ummz/"					  # on ARC4 (home directory)
} else {
  print("Unrecognised machine.")
}

args <- commandArgs(trailingOnly = TRUE)

# for testing ONLY
#args <- c("transcript-level",
#         "/nobackup/ummz/analyses/run_17_Jun21/quants_all/transcript-level",
#         "/nobackup/ummz/analyses/run_17_Jun21/swish/transcript-level",
#         "/nobackup/ummz/analyses/run_17_Jun21/swish/samples_all.txt") 

# DOESN'T WORK FOR GENE-LEVEL
#args <- c("gene-level",
#         "/nobackup/ummz/analyses/run_17_Jun21/quants_all/gene-level",
#         "/nobackup/ummz/analyses/run_17_Jun21/swish/gene-level",
#         "/nobackup/ummz/analyses/run_17_Jun21/swish/samples_all.txt") 

if (length(args)!=4) {
         stop("ERROR: 4 arguments must be supplied:
                 \n(1) running mode [either transcript-level or gene-level]
                 \n(2) INPUT directory,
                 \n(3) OUTPUT directory,
                 \n(4) annotation file", call.=FALSE)
}

# define wheather output files should be saved or not [TRUE / FALSE]
output_save <- TRUE

# define directory with data (INPUT)
dir_in <- args[2]

# define directory for results (OUTPUT)
dir_out <- args[3]

# load table data
coldata <- read.table(args[4], header = TRUE)

# define the nema to be used and create a new folder for results of the current run
# colnames(coldata)
run_feat <- "counts"
  
# check if directory for this feature already exists
if(dir.exists(file.path(dir_out, run_feat)) == FALSE){
  # if not, create it
  dir.create(file.path(dir_out, run_feat))
  paste0("Created new directory: ", file.path(dir_out, run_feat))
} else {
  cat("Output directory already exists")
}

if ( args[1] == "transcript-level" ){
  
  # get list of all files and add it to coldata table
  coldata$files <- file.path(dir_in, coldata$names, "quant.sf")
  all(file.exists(coldata$files))
  
} else if ( args[1] == "gene-level" ) {
  
  # get list of all files and add it to coldata table
  coldata$files <- file.path(dir_in, coldata$names, "quant.genes.sf")
  all(file.exists(coldata$files))
  
} else {
  print("Running mode needs to be specify as either 'transcript-level' or 'gene-level'")
}

# -------------- tximeta --------------

# load quantification data 
se <- tximeta(coldata)

# get counts matrix
cts_tximeta <- assays(se)[["counts"]]

# save counts matrix as .csv
write.csv(cts_tximeta, file = file.path(dir_out, run_feat, paste0(args[1], "_tximeta_", run_feat, ".csv")))
cat("Created: ", file.path(dir_out, run_feat, paste0(args[1], "_tximeta_", run_feat, ".csv")), "\n")
  
# save SummarizedExperiment object from tximeta
saveRDS(cts_tximeta, file = file.path(dir_out, run_feat, paste0(args[1], "_tximeta_", run_feat, ".rds")))
cat("Created: ", file.path(dir_out, run_feat, paste0(args[1], "_tximeta_", run_feat, ".rds")), "\n")

# -------------- tximport --------------

# import quantification data
obj_tximport <- tximport(coldata$files, type = "salmon", txOut = TRUE)

# get counts matrix
cts_tximport <- obj_tximport$counts

# add column names
colnames(cts_tximport) <- coldata$names

# save counts matrix as .csv
write.csv(cts_tximport, file = file.path(dir_out, run_feat, paste0(args[1], "_tximport_", run_feat, ".csv")))
cat("Created: ", file.path(dir_out, run_feat, paste0(args[1], "_tximport_", run_feat, ".csv")), "\n")

# save list object from tximport
saveRDS(obj_tximport, file = file.path(dir_out, run_feat, paste0(args[1], "_tximport_", run_feat, ".rds")))
cat("Created: ", file.path(dir_out, run_feat, paste0(args[1], "_tximport_", run_feat, ".rds")), "\n")

# -------------------- GET SUMMARY TABLE -------------------- #
# use the addIds function from tximeta to add gene symbols, By specifying gene=TRUE, 
# this will use the gene ID to match to gene symbols for all of the transcripts.
se <- addIds(se, "SYMBOL", gene=TRUE)

# save the summary table
cts_transcript_summary <- rowRanges(se)
write.table(as.data.frame(cts_transcript_summary), file = file.path(dir_out, run_feat, paste0(args[1], "_summary.csv")), sep=";")

cat("Created: ", file.path(dir_out, run_feat, paste0(args[1], "_summary.csv")), "\n")

cat("Finished ! ! !")

