#!/bin/bash
#Job script for the MAGeT Fetch and Run
set -e
date

PATH="$PATH:/opt/minc-toolkit-extras:/opt/iterativeN4:/opt/ANTs/bin:/opt/bpipe/bpipe-0.9.9.9/bin:/opt/minc-stuffs/bin:/opt/MAGeTbrain/bin/:/opt/minc/1.9.18/bin:/opt/minc/1.9.18/pipeline"

aws s3 cp s3://data-abcdgruen/${Group}/batch_ids/maget/ /maget/ --recursive --exclude "*" --include "maget_batch_${batchNum}.txt"
LINE=$((AWS_BATCH_JOB_ARRAY_INDEX + 1))
aSub=$(sed -n ${LINE}p /maget/maget_batch_${batchNum}.txt)

echo "Group is ${Group}"
echo "Subject is ${aSub}"
echo "Args: $@"
echo "jobId: $AWS_BATCH_JOB_ID"
echo "jobQueue: $AWS_BATCH_JQ_NAME"
echo "computeEnvironment: $AWS_BATCH_CE_NAME"
echo "arrayIndex: $AWS_BATCH_JOB_ARRAY_INDEX"

cd /maget/

if [ -d "/maget/input" ] 
then
    echo "MAGeT inputs already present"
    echo "Removing old files"
	rm /maget/input/subjects/brains/*
	rm -rf /maget/output/intermediate/*
	rm -rf /maget/output/fusion
	rm /maget/*_MAGeT_QC.jpg
else
	echo "Creating directories"
	mb init
	mkdir output output/intermediate output/registrations output/templatemasks
	echo "Copying atlases"
	aws s3 cp s3://scripts-abcdgruen/atlases/ /maget/input/atlases/brains/ --recursive --exclude "*" --include "brain?.mnc"
	aws s3 cp s3://scripts-abcdgruen/atlases/ /maget/input/atlases/labels/ --recursive --exclude "*" --include "*labels.mnc"
	date
	echo "Copying templates"
	aws s3 cp s3://scripts-abcdgruen/templates/ /maget/input/templates/brains/ --recursive
	date
	echo "Copying template masks"
	aws s3 cp s3://scripts-abcdgruen/templatemasks/ /maget/output/templatemasks/ --recursive
	date
	echo "Copying registrations"
	aws s3 cp s3://scripts-abcdgruen/registrations/ /maget/output/registrations/ --recursive
	date
fi

echo "Copying subject data"
	aws s3 cp s3://data-abcdgruen/${Group}/minc_bpipe_output/ /maget/input/subjects/brains --recursive --exclude "*" --include "${aSub}*.mnc"

echo "Running the MAGeT voting command"
mb run vote -q parallel -j 10
 
echo "Generating the QC image"
MAGeT-QC.sh /maget/input/subjects/brains/${aSub}*.mnc /maget/output/fusion/majority_vote/${aSub}*_labels.mnc /maget/${aSub}_MAGeT_QC.jpg

echo "Tarring the intermediate folder"
tar -zcvf /maget/output/intermediate.tar.gz /maget/output/intermediate

echo "Copying files to S3"
aws s3 cp /maget/output s3://data-abcdgruen/${Group}/maget_output/${aSub} --recursive --exclude "*" --include "fusio*"
aws s3 cp /maget/output s3://data-abcdgruen/${Group}/maget_output/${aSub} --recursive --exclude "*" --include "intermediate.tar.gz"
aws s3 cp /maget/${aSub}_MAGeT_QC.jpg s3://data-abcdgruen/${Group}/maget_output/QC/

date
echo "bye bye!!"