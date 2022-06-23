######################################################################################################
# this script runs trimming (on raw fastq files) for all files (pairs) at once
######################################################################################################

if [ $# != 4 ] ; then
    echo -e "ERROR: 4 arguments are required: \n
    (1) running mode (either 'SE' or 'PE'), \n
    (2) Path to data folder, \n
    (3) path to output folder and \n
    (4) SGE_TASK_ID argument for array jobs \n
    ... Exiting"
    exit 1
fi	

# define arguments
run_mode=$1         		# running mode (either 'SE' or 'PE')
data_dir=$2			# path to the folder with fastq files
out_dir=$3			# path the the folder where output will be placed

# export software (Trimmomatic)
export PATH=/nobackup/ummz/tools/bioinfo/Trimmomatic-0.39:$PATH

# get the read1 fastq.gz file and its pair
fastqFile=$(ls $data_dir/*_R1.fastq.gz | sed -n -e "$SGE_TASK_ID p")

read1=$fastqFile
read2=$(echo $read1 | sed 's/R1/R2/g')

coreFile=$(ls $data_dir/*_R1.fastq.gz | rev | cut -d '/' -f 1 | cut -c 13- | rev | sed -n -e "$SGE_TASK_ID p")

# run Trimmomatic (parameters guide listed below)
if [ $run_mode == 'SE' ]     # single-end [SE]
then
    echo "Running in single-end (SE) mode"

    mkdir -p $out_dir/trimmed/single-end
    echo "Created new folder for output '$out_dir/trimmed/single-end'"
    
    java -jar /nobackup/ummz/tools/bioinfo/Trimmomatic-0.39/trimmomatic-0.39.jar \
    SE \
    -threads 4 \
    -phred33 $read1 \
    $out_dir/trimmed/single-end/${coreFile}_R1_trim_single.fastq.gz \
    ILLUMINACLIP:/nobackup/ummz/tools/bioinfo/Trimmomatic-0.39/adapters/TruSeq3-SE.fa:2:30:10 \
    SLIDINGWINDOW:4:15 \
    LEADING:20 \
    TRAILING:20 \
    HEADCROP:10 \
    MINLEN:36

    echo "Trimming completed"

elif [ $run_mode == 'PE' ]  # paired-end [PE]
then
    echo "Running in paired-end (PE) mode"
    
    mkdir -p $out_dir/trimmed/paired-end
    echo "Created new folder for output '$out_dir/trimmed/paired-end'"

    java -jar /nobackup/ummz/tools/bioinfo/Trimmomatic-0.39/trimmomatic-0.39.jar \
    PE \
    -threads 4 \
    -phred33 $read1 $read2 \
    $out_dir/trimmed/paired-end/${coreFile}_R1_trim_paired.fastq.gz $out_dir/trimmed/paired-end/${coreFile}_R1_trim_unpaired.fastq.gz \
    $out_dir/trimmed/paired-end/${coreFile}_R2_trim_paired.fastq.gz $out_dir/trimmed/paired-end/${coreFile}_R2_trim_unpaired.fastq.gz \
    ILLUMINACLIP:/nobackup/ummz/tools/bioinfo/Trimmomatic-0.39/adapters/TruSeq3-PE-2.fa:2:30:10 \
    SLIDINGWINDOW:4:15 \
    LEADING:20 \
    TRAILING:20 \
    HEADCROP:10 \
    MINLEN:36
    
    echo "Trimming completed"

else
    echo "ERROR: running mode argument incorrect! Exiting..."
    exit 1
fi

# NOTICE: "It is recommended in most cases that adapter clipping, if required, is done as early as possible"

# parameters meanings (the order matters): 
# ILLUMINACLIP:         Cut adapter and other illumina-specific sequences from the read. 
# SLIDINGWINDOW:        Performs a sliding window trimming approach. It starts scanning at the 5‟ end and clips the read once the average quality within the window falls below a threshold.
# MAXINFO:  (not used)  An adaptive quality trimmer which balances read length and error rate to maximise the value of each read
# LEADING:              Cut bases off the start of a read, if below a threshold quality
# TRAILING:             Cut bases off the end of a read, if below a threshold quality
# CROP:     (not used)  Cut the read to a specified length by removing bases from the end 
# HEADCROP:             Cut the specified number of bases from the start of the read 
# MINLEN:               Drop the read if it is below a specified length
# AVGQUAL:  (not used)  Drop the read if the average quality is below the specified level 
# TOPHRED33:(not used)  Convert quality scores to Phred-33
# TOPHRED64:(not used)  Convert quality scores to Phred-64