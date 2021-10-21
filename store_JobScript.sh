#!/bin/bash
#Job script to store the data once you have your final tabular data
set -e

GroupDir=data-abcdgruen/${Group}/

# echo "Starting batch_ids"
# echo "Copying data in"
# mkdir ~/batch_ids 
# mkdir ~/batch_ids/minc ~/batch_ids/maget
# aws s3 cp s3://${GroupDir}/batch_ids/minc/ ~/batch_ids/minc/ --recursive
# aws s3 cp s3://${GroupDir}/batch_ids/maget/ ~/batch_ids/maget/ --recursive
# echo "Tarring"
# tar -zcvf ~/minc_batch_ids.tar.gz ~/batch_ids/minc
# tar -zcvf ~/maget_batch_ids.tar.gz ~/batch_ids/maget
# echo "Copying data to S3"
# aws s3 cp ~/minc_batch_ids.tar.gz s3://${GroupDir}/batch_ids/minc/
# aws s3 cp ~/maget_batch_ids.tar.gz s3://${GroupDir}/batch_ids/maget/
# echo "Removing untarred data"
# aws s3 rm s3://${GroupDir}/batch_ids/minc/ --recursive --exclude "*" --include "*.txt"
# aws s3 rm s3://${GroupDir}/batch_ids/maget/ --recursive --exclude "*" --include "*.txt"

echo "Starting minc bpipe input"
echo "Copying data in"
mkdir ~/minc_bpipe_input
cd ~/minc_bpipe_input
aws s3 cp s3://${GroupDir}/minc_bpipe_input/ ~/minc_bpipe_input/ --recursive
echo "ls ~/minc_bpipe_input"
ls ~/minc_bpipe_input
echo "Putting into groups of 20"
aws s3 ls s3://${GroupDir}/minc_bpipe_input/ | grep -o "\<ndar_..........." > subjlist.txt
echo "Cat subjlist"
cat subjlist.txt
split -a 2 -d -l 20 subjlist.txt minc_input_tar_
echo "Cat minc_input_tar_00"
cat minc_input_tar_00
echo "Moving data into directories for tarring"
for aGroup in minc_input_tar_*
do
	mkdir ${aGroup}_dir
	for aSub in $(cat ${aGroup})
	do
		mv ${aSub}* ${aGroup}_dir/
	done
done
echo "Tarring"
for aGroup in minc_input_tar_*; tar -zcvf ${aGroup}.tar.gz ${aGroup}_dir/; done
echo "Copying data to S3"
for aGroup in minc_input_tar_*
do
	aws s3 cp ${aGroup} s3://${GroupDir}/minc_bpipe_input/
	aws s3 cp ${aGroup}.tar.gz s3://${GroupDir}/minc_bpipe_input/
done

echo "bye bye!!"