# Analyzing the ABCD dataset using AWS

These scripts were used to perform cerebellar segmentation using MAGeTBrain (https://github.com/CoBrALab/MAGeTbrain) within the Adolescent Brain and Cognitive Development Study (ABCD) dataset (https://abcdstudy.org/). A detailed guideline for each step in the process can be found in "Workflow.sh". The basic steps are outlined below. 

## Downloading S3 data from the NDA
Create a data package on the NDA website. Launch an EC2 instance and install the nda-tools package to the instance. Install Docker and MAGeTDocker to the instance. Convert the raw data to .mnc before saving it to an S3. The EC2 must be launched with an IAM that allows write access to S3.

## Process the data through MINC bpipe
Group your data into groups of 10 (not necessary, but handy for running through Batch). Create a launch template that allows for extra EBS storage. Create a customized Docker container that combines MAGeTDocker with a fetch and run script (https://aws.amazon.com/blogs/compute/creating-a-simple-fetch-and-run-aws-batch-job/). Create a Batch compute environment, job queue, and job definition. Run the batches in your groups of 10. After it's completed, visually QC the data and move unusable images to a separate directory.

## Process the data through MAGeT
