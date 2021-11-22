#### Download the s3 data from the NDA
#Launch an instance (Python AMI from Anaconda)
#c5.2xlarge, Spot, Hailey_Role, 50G storage, nitrc-keypair
#SSH into instance
ssh -i ~/.aws/nitrc-keypair.pem ec2-user@[my-instance-public-dns-name]
#Create a ~/.aws/credentials file and add credentials to it
#Add subjects lists to download
nano ~/s3list.txt
nano ~/sub-list.txt
nano ~/idlist.txt
#Convert idlist to all lower case
cat ~/idlist.txt | tr [:upper:] [:lower:] > ~/idlist_lower.txt
#Download nda-tools
pip install nda-tools --user
#Download subject files
downloadcmd -dp 1194700 -t ~/s3list.txt -u [nda_username] -p [nda_password]
#Hit "Enter" when asked for access keys
#Unzip the files
cd /home/ec2-user/NDA/nda-tools/downloadcmd/packages/1194700/image03/
for aFile in $(ls /home/ec2-user/NDA/nda-tools/downloadcmd/packages/1194700/image03/)
do
	tar -xvzf /home/ec2-user/NDA/nda-tools/downloadcmd/packages/1194700/image03/${aFile}
done
#Download Docker
sudo yum update -y
sudo yum install -y docker
sudo service docker start
sudo usermod -a -G docker ec2-user
##Convert to MINC
#Pull MAGeTDocker
sudo docker pull gdevenyi/magetdocker:latest
#Launch the MAGeTDocker
sudo docker run -i -v /home/ec2-user:/maget -t gdevenyi/magetdocker bash
mkdir input_files
#Convert to mnc
for aSub in $(cat /maget/sub-list.txt)
do
	dcmDir=/maget/NDA/nda-tools/downloadcmd/packages/1194700/image03/${aSub}/ses-baselineYear1Arm1/anat/ABCD*
	echo ${dcmDir}
	dcm2mnc ${dcmDir}/ /maget/input_files/
done
#Copy to s3
exit
Group=[GroupName]
for aSub in $(cat ~/idlist_lower.txt)
do
	aws s3 cp ~/input_files/${aSub}*/ s3://data-abcdgruen/${Group}/minc_bpipe_input/ --recursive
done


#### MINC processing
##Create a batch listing
#Generate list of IDs on AWS
Group=[GroupName]
aws s3 ls s3://data-abcdgruen/${Group}/minc_bpipe_input/ --profile haileyw | grep -o "\<ndar_..........." > ~/Desktop/batch_ids/${Group}.txt
#Transfer the resulting txt file to Farnam. Need a Linux machine for the next line
#Splits the txt file into groups of 10
split -a 2 -d -l 10 [Group].txt minc_batch_
#Add txt file extension
for f in minc_batch_*; do mv "$f" "$f.txt"; done
#Add batch files to the batch id folder
##Create a launch template that allows for extra EBS storage in your compute environment (only need to do once)
#Follow the instructions here: https://aws.amazon.com/premiumsupport/knowledge-center/batch-ebs-volumes-launch-template/
#Increase xvda to 60 in the launch template
#Register the launch template
aws ec2 --region us-east-1 create-launch-template --cli-input-json file://increase-ebs-60G-launchtemplate.json --profile haileyw
##Set up for Batch
#Add the MINC job script to the scripts folder
#Create an ECR registry and use the push instructions to push the MAGeT_FetchRun docker to the ECR
#Create a compute environment
	#Managed, HaileyRole, Spot, allow only 8x compute instances, spot-capacity optimized, specify launch template created above
#Create a job queue
#Register a job definition (only need to do this once)
aws batch register-job-definition --cli-input-json file://minc_jobdefinition.json --profile haileyw
#Run a job
aws batch submit-job --cli-input-json file://minc-job.json --profile haileyw
#Or run sequential jobs
aws batch submit-job --cli-input-json file://minc-job-seq.json --profile haileyw
##QC the data (does masked area cover the cerebellum?)
#After qc, modify and run the failed_qc.R script to generate a list of subjects that failed minc QC.
#Move failed subjects into the "bad" folder according to the list
Group=[GroupName]
for aSub in $(cat /Volumes/Gruenlab-726014-YSM/hailey_dsilva/projects/AWS_cerebellum/FullStudy/QC/${Group}/failed_minc.txt)
do
	aws s3 mv s3://data-abcdgruen/${Group}/minc_bpipe_output/ s3://data-abcdgruen/${Group}/minc_bpipe_output/bad/ --recursive --exclude "*" --include "${aSub}*" --profile haileyw 
done


#### MAGeT processing
##Create a batch listing
#Generate list of IDs on AWS
Group=[GroupName]
aws s3 ls s3://data-abcdgruen/${Group}/minc_bpipe_output/ --profile haileyw | grep -o "\<ndar_..........." > ~/Desktop/batch_ids/${Group}.txt
#Transfer the resulting txt file to Farnam. Need a Linux machine for the next line
#Splits the txt file into groups of 10
split -a 2 -d -l 10 [Group].txt maget_batch_
#Add txt file extension
for f in maget_batch_*; do mv "$f" "$f.txt"; done
#Add batch files to the batch id folder
#Register a job definition (only need to do this once)
aws batch register-job-definition --cli-input-json file://maget_jobdefinition.json --profile haileyw
#Run a job 
aws batch submit-job --cli-input-json file://maget-job.json --profile haileyw
#Or run sequential jobs
aws batch submit-job --cli-input-json file://maget-job-seq.json --profile haileyw
##If some jobs failed, use this to compare who's missing
Group=
aws s3 ls s3://data-abcdgruen/${Group}/minc_bpipe_output/ --profile haileyw | grep -o "\<ndar_..........." > ~/Desktop/expected.txt
aws s3 ls s3://data-abcdgruen/${Group}/maget_output/ --profile haileyw | grep -o "\<ndar_..........." > ~/Desktop/actual.txt
grep -Fxvf ~/Desktop/actual.txt ~/Desktop/expected.txt > ~/Desktop/missing.txt
##QC the data
#Check "Maybe's" in the final QC'ed spreadsheet
#After qc, modify and run the failed_qc.R script to generate a list of subjects that failed MAGeT QC.
#Move failed subjects into the "bad" folder according to the list
Group=[GroupName]
for aSub in $(cat /Volumes/Gruenlab-726014-YSM/hailey_dsilva/projects/AWS_cerebellum/FullStudy/QC/${Group}/failed_maget.txt)
do
	aws s3 mv s3://data-abcdgruen/${Group}/maget_output/ s3://data-abcdgruen/${Group}/maget_output/bad/ --recursive --exclude "*" --include "${aSub}*" --profile haileyw 
done
##Collect volume data
Group=[GroupName]
aws s3 ls s3://data-abcdgruen/${Group}/maget_output/ --profile haileyw | grep -o "\<ndar_..........." > ~/Desktop/${Group}.txt
#Start a c5.2xlarge instance and install MAGeTDocker on it (like we did when downloading from the NDA)
Group=[GroupName]
mkdir input
nano ~/${Group}.txt
aws s3 cp s3://scripts-abcdgruen/label-names.csv .
for aSub in $(cat ~/${Group}.txt)
do
	aws s3 cp s3://data-abcdgruen/${Group}/maget_output/${aSub}/fusion/majority_vote/ ~/input/ --recursive
done
#Launch the MAGeTDocker and collect volumes
sudo docker run -i -v /home/ec2-user:/maget -t gdevenyi/magetdocker bash
Group=[GroupName]
collect_volumes.sh /maget/label-names.csv /maget/input/*beastextract_labels.mnc > /maget/${Group}.csv
exit
#Save out the volume data
aws s3 cp ~/${Group}.csv s3://results-abcdgruen/

#### Running the Maybe's
#Move into Maybe folder
Group=[GroupName]
for aSub in $(cat /Volumes/Gruenlab-726014-YSM/hailey_dsilva/projects/AWS_cerebellum/FullStudy/QC/${Group}/maybe_minc.txt)
do
	aws s3 mv s3://data-abcdgruen/${Group}/minc_bpipe_output/bad/ s3://data-abcdgruen/${Group}/minc_bpipe_output/maybe/ --recursive --exclude "*" --include "${aSub}*" --profile haileyw 
done
#Create batch ids
Group=[GroupName]
aws s3 ls s3://data-abcdgruen/${Group}/minc_bpipe_output/maybe/ --profile haileyw | grep -o "\<ndar_..........." > ~/Desktop/batch_ids/${Group}.txt
split -a 2 -d -l 10 [Group].txt maybe_batch_
for f in maybe_batch_*; do mv "$f" "$f.txt"; done
#Edit MAGeT_JobScript_seq.sh to take "maybe_batch"
#Submit jobs to MAGeT as normal
#If fewer maget_output files than expected, check to see who's missing
aws s3 ls s3://data-abcdgruen/${Group}/minc_bpipe_output/ --profile haileyw | grep -o "\<ndar_..........." > ~/Desktop/expected.txt
aws s3 ls s3://data-abcdgruen/${Group}/minc_bpipe_output/maybe/ --profile haileyw | grep -o "\<ndar_..........." >> ~/Desktop/expected.txt
aws s3 ls s3://data-abcdgruen/${Group}/maget_output/ --profile haileyw | grep -o "\<ndar_..........." > ~/Desktop/actual.txt
grep -Fxvf ~/Desktop/actual.txt ~/Desktop/expected.txt > ~/Desktop/missing.txt
#Submit missing jobs to MAGeT
for aSub in $(cat ~/Desktop/missing.txt)
do
        sed -i '' -e 's/NEWSUB/'${aSub}'/' maget-job.json
        aws batch submit-job --cli-input-json file://maget-job.json --profile haileyw
        sed -i '' -e 's/'${aSub}'/NEWSUB/' maget-job.json
done
#Submit missing jobs to MAGeT dependently (have job IDs in a file)
for num in {1..15}
do
    aSub=$(sed -n ${num}p ~/Desktop/missing.txt)
    jobID=$(sed -n ${num}p ~/Desktop/jobids.txt)
    sed -i '' -e 's/NEWSUB/'${aSub}'/' maget-job.json
    sed -i '' -e 's/JBID/'${jobID}'/' maget-job.json
    aws batch submit-job --cli-input-json file://maget-job.json --profile haileyw
    sed -i '' -e 's/'${aSub}'/NEWSUB/' maget-job.json
    sed -i '' -e 's/'${jobID}'/JBID/' maget-job.json
done
#Add QC images to shared drive
FullStudyDir=/Volumes/Gruenlab-726014-YSM/hailey_dsilva/projects/AWS_cerebellum/FullStudy
mkdir ${FullStudyDir}/QC/${Group}/maybe
for aSub in $(cat ${FullStudyDir}/QC/${Group}/maybe_minc.txt)
do
	aws s3 cp s3://data-abcdgruen/${Group}/maget_output/QC/${aSub}_MAGeT_QC.jpg ${FullStudyDir}/QC/${Group}/maybe/ --profile haileyw
done
####Store the data
#Register a job definition (only need to do this once)
aws batch register-job-definition --cli-input-json file://store_jobdefinition.json --profile haileyw
#Run a job
aws batch submit-job --cli-input-json file://store-job.json --profile haileyw

for aSub in $(cat ~/Desktop/idlist_lower.txt)
do
	aws s3 mv s3://data-abcdgruen/W1_Eur_Discovery_Grp2/minc_bpipe_input/ s3://data-abcdgruen/W1_Eur_Discovery_Grp3/minc_bpipe_input/ --recursive --exclude "*" --include "${aSub}*" --profile haileyw 
done
