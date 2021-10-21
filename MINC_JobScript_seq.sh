#!/bin/bash
#Job script for the MINC Fetch and Run
set -e

PATH="$PATH:/opt/minc-toolkit-extras:/opt/iterativeN4:/opt/ANTs/bin:/opt/bpipe/bpipe-0.9.9.9/bin:/opt/minc-stuffs/bin:/opt/MAGeTbrain/bin/:/opt/minc/1.9.18/bin:/opt/minc/1.9.18/pipeline"

echo "Args: $@"
echo "jobId: $AWS_BATCH_JOB_ID"
echo "jobQueue: $AWS_BATCH_JQ_NAME"
echo "computeEnvironment: $AWS_BATCH_CE_NAME"
echo "arrayIndex: $AWS_BATCH_JOB_ARRAY_INDEX"

#ZeroDigit serves to insert a zero at the beginning of batches in the single digits. If the batch is not in the single digits, just leave it
#blank in minc-job.json.
batchNum="${ZeroDigit}$((AWS_BATCH_JOB_ARRAY_INDEX + ${startingNum}))"
echo "batchNum is ${batchNum}"
echo "Group is ${Group}"

if [ -d "/maget/input_files" ] 
then
    echo "MINC inputs already present, removing old files"
	rm -rf /maget/input_files
	rm -rf /maget/output_files
fi

mkdir /maget/input_files
mkdir /maget/output_files
mkdir /maget/output_files/batchNum_${batchNum}

echo "Copying data in"
aws s3 cp s3://data-abcdgruen/${Group}/batch_ids/minc/minc_batch_${batchNum}.txt /maget/
for aSub in $(cat /maget/minc_batch_${batchNum}.txt)
do
	aws s3 cp s3://data-abcdgruen/${Group}/minc_bpipe_input/ /maget/input_files/ --recursive --exclude "*" --include "${aSub}*"
done

echo "Running bpipe"
cd /maget/output_files/batchNum_${batchNum}
bpipe run -n 10 /opt/minc-bpipe-library/pipeline.bpipe /maget/input_files/*mnc #n flag is number of participants

echo "Copying data to S3"
aws s3 cp /maget/output_files/batchNum_${batchNum}/  s3://data-abcdgruen/${Group}/minc_bpipe_output/ --recursive --exclude "*" --include "*.n4correct.cutneckapplyautocrop.beastextract.mnc"
aws s3 cp /maget/output_files/batchNum_${batchNum}/QC/  s3://data-abcdgruen/${Group}/minc_bpipe_output/QC/ --recursive

echo "bye bye!!"

#10 subjs takes about 3.5 to 6 hours on 4x series to run through this MINC script
#Run this with limiting to a 4x family so they can't run on the same instance