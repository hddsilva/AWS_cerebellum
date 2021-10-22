#This script subsets the pilot data for the AWS cerebellum project

library(dplyr)
library(lubridate)
library(stringr)

Demographics <- read.csv("/Volumes/Gruenlab-726014-YSM/hailey_dsilva/projects/AWS_cerebellum/Pilot/data_pulls/Demographics.csv",header=TRUE)
FreesurferQC <- read.csv("/Volumes/Gruenlab-726014-YSM/hailey_dsilva/projects/AWS_cerebellum/Pilot/data_pulls/FreesurferQC.csv",header=TRUE)
MRFindings <- read.csv("/Volumes/Gruenlab-726014-YSM/hailey_dsilva/projects/AWS_cerebellum/Pilot/data_pulls/MRFindings.csv",header=TRUE)
MRI_info <- read.csv("/Volumes/Gruenlab-726014-YSM/hailey_dsilva/projects/AWS_cerebellum/Pilot/data_pulls/MRI_info.csv",header=TRUE)
NIHtb <- read.csv("/Volumes/Gruenlab-726014-YSM/hailey_dsilva/projects/AWS_cerebellum/Pilot/data_pulls/NIHtb.csv",header=TRUE)
Pearson_scores <- read.csv("/Volumes/Gruenlab-726014-YSM/hailey_dsilva/projects/AWS_cerebellum/Pilot/data_pulls/Pearson_scores.csv",header=TRUE)
PilotPart3 <- read.csv("/Volumes/Gruenlab-726014-YSM/hailey_dsilva/projects/AWS_cerebellum/Pilot/data_pulls/PilotPart3.csv",header=TRUE)
RAnotes <- read.csv("/Volumes/Gruenlab-726014-YSM/hailey_dsilva/projects/AWS_cerebellum/Pilot/data_pulls/RAnotes.csv",header=TRUE)
screener <- read.csv("/Volumes/Gruenlab-726014-YSM/hailey_dsilva/projects/AWS_cerebellum/Pilot/data_pulls/screener.csv",header=TRUE)
TwinInfo <- read.csv("/Volumes/Gruenlab-726014-YSM/hailey_dsilva/projects/AWS_cerebellum/Pilot/data_pulls/TwinInfo.csv",header=TRUE)
Genetic_QC <- read.delim("/Volumes/Gruenlab-726014-YSM/hailey_dsilva/projects/AWS_cerebellum/Pilot/data_pulls/Shiying_genetic_QC.txt",header=FALSE,sep = " ")
Kinship <- read.delim("/Volumes/Gruenlab-726014-YSM/hailey_dsilva/projects/AWS_cerebellum/Pilot/data_pulls/Shiying_kinship.txt",header=TRUE)
Missing_Covars <- read.delim("/Volumes/Gruenlab-726014-YSM/hailey_dsilva/projects/AWS_cerebellum/Pilot/data_pulls/SubjIDs_8068_income_reading.txt",header=TRUE,sep = " ")
PilotIDs1 <- read.delim("/Volumes/Gruenlab-726014-YSM/hailey_dsilva/projects/AWS_cerebellum/Pilot/IDs/Full_PilotIDs.txt",header=FALSE)
PilotIDs2 <- read.delim("/Volumes/Gruenlab-726014-YSM/hailey_dsilva/projects/AWS_cerebellum/Pilot/IDs/Full_PilotIDs2.txt",header=FALSE)
T1_s3links <- read.table("/Volumes/Gruenlab-726014-YSM/hailey_dsilva/projects/AWS_cerebellum/Pilot/data_pulls/T1_s3links.txt",header=TRUE)

#Modify a few dataframes to integrate better into the full dataframe
PilotIDs1 <- PilotIDs1 %>% mutate(PilotIDs1 = "Yes")
PilotIDs2 <- PilotIDs2 %>% mutate(PilotIDs2 = "Yes")
Genetic_QC <- Genetic_QC %>% mutate(Genetic_QC = "Yes")
colnames(Missing_Covars) <- paste0(colnames(Missing_Covars), '_avail')
MRI_info <- MRI_info %>% mutate(MRI_INFO_STUDYDATE = dmy(MRI_INFO_STUDYDATE))

#Modify the s3 links dataframe
T1_s3links2 <- T1_s3links %>% 
  #Starts w/ "NDARINV then 8 alphanumeric characters
  mutate(SUBJECTKEY = paste("NDAR_",str_extract(ENDPOINT, pattern = "INV[A-z0-9]{8}"), sep=""),
         MRI_INFO_STUDYDATE = ymd(str_extract(ENDPOINT, pattern = "20[0-9]{6}"))) %>% 
  distinct(SUBJECTKEY, MRI_INFO_STUDYDATE, .keep_all = TRUE)

#Create the dataframe
#Join tables
Subjs <- Demographics %>% 
  left_join(FreesurferQC, by = "SUBJECTKEY") %>% 
  left_join(MRFindings, by = "SUBJECTKEY") %>% 
  left_join(MRI_info, by = "SUBJECTKEY") %>% 
  left_join(NIHtb, by = "SUBJECTKEY") %>% 
  left_join(Pearson_scores, by = "SUBJECTKEY") %>% 
  left_join(PilotPart3, by = "SUBJECTKEY") %>% 
  left_join(RAnotes, by = "SUBJECTKEY") %>% 
  left_join(screener, by = "SUBJECTKEY") %>% 
  left_join(TwinInfo, by = "SUBJECTKEY") %>%
  left_join(Genetic_QC, by = c("SUBJECTKEY" = "V2")) %>%
  left_join(Missing_Covars, by = c("SUBJECTKEY" = "SUBJECTKEY_avail")) %>%
  left_join(PilotIDs1, by = c("SUBJECTKEY" = "V1")) %>%
  left_join(PilotIDs2, by = c("SUBJECTKEY" = "V1")) %>%
  left_join(T1_s3links2, by = c("SUBJECTKEY","MRI_INFO_STUDYDATE")) %>%
  #Create variables
  mutate(US_ReqTime = case_when(DEMO_ORIGIN_V2 == 189 ~ "Yes",
                                (DEMO_ORIGIN_V2 != 189) & (DEMO_YEARS_US_V2 > 2.9) ~ "Yes",
                                (DEMO_ORIGIN_V2 != 189) & (DEMO_YEARS_US_V2 <= 2.9) ~ "No"),
         Engl_Req = case_when(US_ReqTime == "Yes" & NIHTBX_PICVOCAB_AGECORRECTED >= 70 ~ "Yes",
                              US_ReqTime == "No" | NIHTBX_PICVOCAB_AGECORRECTED < 70 ~ "No"),
         interview_age = round(INTERVIEW_AGE/12),
         interview_date = dmy(INTERVIEW_DATE),
         nihtbx_picvocab_date = ymd(substr(NIHTBX_PICVOCAB_DATE, 1, 10)),
         nihtbx_reading_date = mdy(NIHTBX_READING_DATE),
         pea_altdate = case_when(startsWith(PEA_ASSESSMENTDATE, "20") ~ 1),
         pea_assessmentdate = case_when(pea_altdate == 1 ~ ymd(substr(PEA_ASSESSMENTDATE, 1, 10)),
                                        is.na(pea_altdate) ~ dmy(substr(PEA_ASSESSMENTDATE, 6, 16))),
         mri_reading_gapDays = abs(nihtbx_reading_date - MRI_INFO_STUDYDATE),
         mri_picvocab_gapDays = abs(nihtbx_picvocab_date - MRI_INFO_STUDYDATE),
         mri_interview_gapDays = abs(interview_date - MRI_INFO_STUDYDATE)) %>% 
  #Exclusions
  filter(MRIF_SCORE < 4, #MR findings requiring immediate clinical review
         MRIF_HYDROCEPHALUS == "no", #hydrocephalus MR finding
         MRIF_HERNIATION == "no", #herniation MR finding
         SCRN_CPALSY == 1,
         SCRN_TUMOR == 1,
         SCRN_STROKE == 1,
         SCRN_ANEURYSM == 1,
         SCRN_HEMORRHAGE == 1,
         SCRN_HEMOTOMA == 1,
         SCRN_MEDCOND_OTHER == 0 | is.na(SCRN_MEDCOND_OTHER), #serious medical or neurological condition
         SCRN_EPLS == 0 | is.na(SCRN_EPLS), #epilepsy
         SCRN_SCHIZ == 0 | is.na(SCRN_SCHIZ), #schizophrenia
         SCRN_ASD == 0 | is.na(SCRN_ASD), #autism
         Engl_Req == "Yes", #Born in the US or lived in US for at least 3 years with a Pic Vocab score of at least 70
         FSQC_QC == 1,
         PEA_WISCV_TSS >= 4, #Matrix reasoning at least 2 sd below mean
         MEDHX_2F == 0 | is.na(MEDHX_2F), #Seen a doctor for cerebral palsy
         MEDHX_2H == 0 | is.na(MEDHX_2H), #Seen a doctor for epilepsy/seizures
         MEDHX_2M == 0 | is.na(MEDHX_2M), #Seen a doctor for multiple sclerosis
         MEDHX_6P_NOTES <= 2 | is.na(MEDHX_6P_NOTES), #Has had more than 2 seizures
         Genetic_QC == "Yes",  #Passed Shiying's genetic qc
         family_income_avail == 1 & reading_baseline_avail == 1,
         is.na(PilotIDs1), #Is not included in the two pilot batches
         is.na(PilotIDs2),
         !is.na(ENDPOINT)) %>% #Missing s3 link
  distinct(REL_FAMILY_ID, .keep_all = T)  #Remove siblings 
  
#Data screening and exploration
summary(Subjs)
table(Subjs$DEMO_COMB_INCOME_V2)
hist(Subjs$INTERVIEW_AGE)
summary(Subjs$INTERVIEW_AGE)
hist(Subjs$PEA_WISCV_TSS)
hist(Subjs$NIHTBX_READING_AGECORRECTED)
hist(as.numeric(Subjs$mri_interview_gapDays))
hist(as.numeric(Subjs$mri_picvocab_gapDays))
hist(as.numeric(Subjs$mri_reading_gapDays))
         
#See the count of participants by race
table(Subjs$RACE_ETHNICITY)

#See the count of participants by race and MRI manufacturer
table(Subjs$RACE_ETHNICITY, Subjs$MRI_INFO_MANUFACTURERSMN)

#The $5000 grant will cover processing about 2732 children. For now, will process
#European kids from the Prisma_fit, Prisma, Achieva dStream, and Ingenia to get us to 2648.

#Create the 1st wave
Wave1 <- Subjs %>% 
  filter(RACE_ETHNICITY == 1,
         MRI_INFO_MANUFACTURERSMN == "Prisma" | MRI_INFO_MANUFACTURERSMN == "Prisma_fit" |
           MRI_INFO_MANUFACTURERSMN == "Achieva dStream" | MRI_INFO_MANUFACTURERSMN == "Ingenia")

#See the count of Wave 1 participants by collection site
table(Wave1$MRI_INFO_DEVICESERIALNUMBER, Wave1$MRI_INFO_MANUFACTURERSMN)

#Create Wave 1 Groups
W1_Eur_PriFit_Grp1 <- Wave1 %>% 
  filter(MRI_INFO_DEVICESERIALNUMBER == "HASH1314a204" | MRI_INFO_DEVICESERIALNUMBER == "HASH65b39280"
         | MRI_INFO_DEVICESERIALNUMBER == "HASH96a0c182") %>% 
  select(SUBJECTKEY, ENDPOINT) %>% arrange(SUBJECTKEY)
W1_Eur_PriFit_Grp2 <- Wave1 %>% 
  filter(MRI_INFO_DEVICESERIALNUMBER == "HASH311170b9" | MRI_INFO_DEVICESERIALNUMBER == "HASHb640a1b8") %>% 
  select(SUBJECTKEY, ENDPOINT) %>% arrange(SUBJECTKEY)
W1_Eur_PriFit_Grp3 <- Wave1 %>% 
  filter(MRI_INFO_DEVICESERIALNUMBER == "HASH31ce566d" | MRI_INFO_DEVICESERIALNUMBER == "HASH4d1ed7b1"
         | MRI_INFO_DEVICESERIALNUMBER == "HASH7911780b" | MRI_INFO_DEVICESERIALNUMBER == "HASHc9398971"
         | MRI_INFO_DEVICESERIALNUMBER == "HASH7f91147d" | MRI_INFO_DEVICESERIALNUMBER == "HASHe4f6957a") %>% 
  select(SUBJECTKEY, ENDPOINT) %>% arrange(SUBJECTKEY)

W1_Eur_Prisma_Grp1 <- Wave1 %>% 
  filter(MRI_INFO_DEVICESERIALNUMBER == "HASH3935c89e") %>% 
  select(SUBJECTKEY, ENDPOINT) %>% arrange(SUBJECTKEY)
W1_Eur_Prisma_Grp2 <- Wave1 %>% 
  filter(MRI_INFO_DEVICESERIALNUMBER == "HASH03db707f" | MRI_INFO_DEVICESERIALNUMBER == "HASHd422be27") %>% 
  select(SUBJECTKEY, ENDPOINT) %>% arrange(SUBJECTKEY)
W1_Eur_Prisma_Grp3 <- Wave1 %>% 
  filter(MRI_INFO_DEVICESERIALNUMBER == "HASH11ad4ed5" | MRI_INFO_DEVICESERIALNUMBER == "HASH5b0cf1bb"
         | MRI_INFO_DEVICESERIALNUMBER == "HASHe76e6d72") %>% 
  select(SUBJECTKEY, ENDPOINT) %>% arrange(SUBJECTKEY)

W1_Eur_Ingenia_Grp1 <- Wave1 %>% 
  filter(MRI_INFO_DEVICESERIALNUMBER == "HASH5ac2b20b") %>% 
  select(SUBJECTKEY, ENDPOINT) %>% arrange(SUBJECTKEY)
W1_Eur_Achieva_Grp1 <- Wave1 %>% 
  filter(MRI_INFO_DEVICESERIALNUMBER == "HASHdb2589d4" | MRI_INFO_DEVICESERIALNUMBER == "HASH6b4422a7") %>% 
  select(SUBJECTKEY, ENDPOINT) %>% arrange(SUBJECTKEY)

#Check Wave 1 groupings for errors
W1_check <- bind_rows(W1_Eur_Achieva_Grp1, W1_Eur_Ingenia_Grp1, W1_Eur_PriFit_Grp1, W1_Eur_PriFit_Grp2,
                      W1_Eur_PriFit_Grp3, W1_Eur_Prisma_Grp1, W1_Eur_Prisma_Grp2, W1_Eur_Prisma_Grp3)
W1_check$SUBJECTKEY[duplicated(W1_check$SUBJECTKEY)]
W1_check$ENDPOINT[duplicated(W1_check$ENDPOINT)]

#Write out IDs
#Total Wave 1
Wave1_IDs <- select(Wave1, SUBJECTKEY) %>% arrange(SUBJECTKEY)
write.table(Wave1_IDs, file=paste("/Volumes/Gruenlab-726014-YSM/hailey_dsilva/projects/AWS_cerebellum/FullStudy/ID_lists/Wave1_IDs.txt",sep=""), sep="\t", row.names = FALSE,
            col.names = FALSE, quote = FALSE)
#W1_Eur_PriFit_Grp1
W1_Eur_PriFit_Grp1_IDs <- W1_Eur_PriFit_Grp1 %>% select(SUBJECTKEY)
W1_Eur_PriFit_Grp1_s3 <- W1_Eur_PriFit_Grp1 %>% select(ENDPOINT)
W1_Eur_PriFit_Grp1_sub <- W1_Eur_PriFit_Grp1 %>% 
  mutate(SUBJECTKEY_sub = paste("sub-",str_remove(SUBJECTKEY,"_"), sep="")) %>% select(SUBJECTKEY_sub)
write.table(W1_Eur_PriFit_Grp1_IDs, file=paste("/Volumes/Gruenlab-726014-YSM/hailey_dsilva/projects/AWS_cerebellum/FullStudy/ID_lists/W1_Eur_PriFit_Grp1_IDs.txt",sep=""), sep="\t", row.names = FALSE,
            col.names = FALSE, quote = FALSE)
write.table(W1_Eur_PriFit_Grp1_s3, file=paste("/Volumes/Gruenlab-726014-YSM/hailey_dsilva/projects/AWS_cerebellum/FullStudy/ID_lists/W1_Eur_PriFit_Grp1_s3.txt",sep=""), sep="\t", row.names = FALSE,
            col.names = FALSE, quote = FALSE)
write.table(W1_Eur_PriFit_Grp1_sub, file=paste("/Volumes/Gruenlab-726014-YSM/hailey_dsilva/projects/AWS_cerebellum/FullStudy/ID_lists/W1_Eur_PriFit_Grp1_sub.txt",sep=""), sep="\t", row.names = FALSE,
            col.names = FALSE, quote = FALSE)
#W1_Eur_PriFit_Grp2
W1_Eur_PriFit_Grp2_IDs <- W1_Eur_PriFit_Grp2 %>% select(SUBJECTKEY)
W1_Eur_PriFit_Grp2_s3 <- W1_Eur_PriFit_Grp2 %>% select(ENDPOINT)
W1_Eur_PriFit_Grp2_sub <- W1_Eur_PriFit_Grp2 %>% 
  mutate(SUBJECTKEY_sub = paste("sub-",str_remove(SUBJECTKEY,"_"), sep="")) %>% select(SUBJECTKEY_sub)
write.table(W1_Eur_PriFit_Grp2_IDs, file=paste("/Volumes/Gruenlab-726014-YSM/hailey_dsilva/projects/AWS_cerebellum/FullStudy/ID_lists/W1_Eur_PriFit_Grp2_IDs.txt",sep=""), sep="\t", row.names = FALSE,
            col.names = FALSE, quote = FALSE)
write.table(W1_Eur_PriFit_Grp2_s3, file=paste("/Volumes/Gruenlab-726014-YSM/hailey_dsilva/projects/AWS_cerebellum/FullStudy/ID_lists/W1_Eur_PriFit_Grp2_s3.txt",sep=""), sep="\t", row.names = FALSE,
            col.names = FALSE, quote = FALSE)
write.table(W1_Eur_PriFit_Grp2_sub, file=paste("/Volumes/Gruenlab-726014-YSM/hailey_dsilva/projects/AWS_cerebellum/FullStudy/ID_lists/W1_Eur_PriFit_Grp2_sub.txt",sep=""), sep="\t", row.names = FALSE,
            col.names = FALSE, quote = FALSE)
#W1_Eur_PriFit_Grp3
W1_Eur_PriFit_Grp3_IDs <- W1_Eur_PriFit_Grp3 %>% select(SUBJECTKEY)
W1_Eur_PriFit_Grp3_s3 <- W1_Eur_PriFit_Grp3 %>% select(ENDPOINT)
W1_Eur_PriFit_Grp3_sub <- W1_Eur_PriFit_Grp3 %>% 
  mutate(SUBJECTKEY_sub = paste("sub-",str_remove(SUBJECTKEY,"_"), sep="")) %>% select(SUBJECTKEY_sub)
write.table(W1_Eur_PriFit_Grp3_IDs, file=paste("/Volumes/Gruenlab-726014-YSM/hailey_dsilva/projects/AWS_cerebellum/FullStudy/ID_lists/W1_Eur_PriFit_Grp3_IDs.txt",sep=""), sep="\t", row.names = FALSE,
            col.names = FALSE, quote = FALSE)
write.table(W1_Eur_PriFit_Grp3_s3, file=paste("/Volumes/Gruenlab-726014-YSM/hailey_dsilva/projects/AWS_cerebellum/FullStudy/ID_lists/W1_Eur_PriFit_Grp3_s3.txt",sep=""), sep="\t", row.names = FALSE,
            col.names = FALSE, quote = FALSE)
write.table(W1_Eur_PriFit_Grp3_sub, file=paste("/Volumes/Gruenlab-726014-YSM/hailey_dsilva/projects/AWS_cerebellum/FullStudy/ID_lists/W1_Eur_PriFit_Grp3_sub.txt",sep=""), sep="\t", row.names = FALSE,
            col.names = FALSE, quote = FALSE)
#W1_Eur_Prisma_Grp1
W1_Eur_Prisma_Grp1_IDs <- W1_Eur_Prisma_Grp1 %>% select(SUBJECTKEY)
W1_Eur_Prisma_Grp1_s3 <- W1_Eur_Prisma_Grp1 %>% select(ENDPOINT)
W1_Eur_Prisma_Grp1_sub <- W1_Eur_Prisma_Grp1 %>% 
  mutate(SUBJECTKEY_sub = paste("sub-",str_remove(SUBJECTKEY,"_"), sep="")) %>% select(SUBJECTKEY_sub)
write.table(W1_Eur_Prisma_Grp1_IDs, file=paste("/Volumes/Gruenlab-726014-YSM/hailey_dsilva/projects/AWS_cerebellum/FullStudy/ID_lists/W1_Eur_Prisma_Grp1_IDs.txt",sep=""), sep="\t", row.names = FALSE,
            col.names = FALSE, quote = FALSE)
write.table(W1_Eur_Prisma_Grp1_s3, file=paste("/Volumes/Gruenlab-726014-YSM/hailey_dsilva/projects/AWS_cerebellum/FullStudy/ID_lists/W1_Eur_Prisma_Grp1_s3.txt",sep=""), sep="\t", row.names = FALSE,
            col.names = FALSE, quote = FALSE)
write.table(W1_Eur_Prisma_Grp1_sub, file=paste("/Volumes/Gruenlab-726014-YSM/hailey_dsilva/projects/AWS_cerebellum/FullStudy/ID_lists/W1_Eur_Prisma_Grp1_sub.txt",sep=""), sep="\t", row.names = FALSE,
            col.names = FALSE, quote = FALSE)
#W1_Eur_Prisma_Grp2
W1_Eur_Prisma_Grp2_IDs <- W1_Eur_Prisma_Grp2 %>% select(SUBJECTKEY)
W1_Eur_Prisma_Grp2_s3 <- W1_Eur_Prisma_Grp2 %>% select(ENDPOINT)
W1_Eur_Prisma_Grp2_sub <- W1_Eur_Prisma_Grp2 %>% 
  mutate(SUBJECTKEY_sub = paste("sub-",str_remove(SUBJECTKEY,"_"), sep="")) %>% select(SUBJECTKEY_sub)
write.table(W1_Eur_Prisma_Grp2_IDs, file=paste("/Volumes/Gruenlab-726014-YSM/hailey_dsilva/projects/AWS_cerebellum/FullStudy/ID_lists/W1_Eur_Prisma_Grp2_IDs.txt",sep=""), sep="\t", row.names = FALSE,
            col.names = FALSE, quote = FALSE)
write.table(W1_Eur_Prisma_Grp2_s3, file=paste("/Volumes/Gruenlab-726014-YSM/hailey_dsilva/projects/AWS_cerebellum/FullStudy/ID_lists/W1_Eur_Prisma_Grp2_s3.txt",sep=""), sep="\t", row.names = FALSE,
            col.names = FALSE, quote = FALSE)
write.table(W1_Eur_Prisma_Grp2_sub, file=paste("/Volumes/Gruenlab-726014-YSM/hailey_dsilva/projects/AWS_cerebellum/FullStudy/ID_lists/W1_Eur_Prisma_Grp2_sub.txt",sep=""), sep="\t", row.names = FALSE,
            col.names = FALSE, quote = FALSE)
#W1_Eur_Prisma_Grp3
W1_Eur_Prisma_Grp3_IDs <- W1_Eur_Prisma_Grp3 %>% select(SUBJECTKEY)
W1_Eur_Prisma_Grp3_s3 <- W1_Eur_Prisma_Grp3 %>% select(ENDPOINT)
W1_Eur_Prisma_Grp3_sub <- W1_Eur_Prisma_Grp3 %>% 
  mutate(SUBJECTKEY_sub = paste("sub-",str_remove(SUBJECTKEY,"_"), sep="")) %>% select(SUBJECTKEY_sub)
write.table(W1_Eur_Prisma_Grp3_IDs, file=paste("/Volumes/Gruenlab-726014-YSM/hailey_dsilva/projects/AWS_cerebellum/FullStudy/ID_lists/W1_Eur_Prisma_Grp3_IDs.txt",sep=""), sep="\t", row.names = FALSE,
            col.names = FALSE, quote = FALSE)
write.table(W1_Eur_Prisma_Grp3_s3, file=paste("/Volumes/Gruenlab-726014-YSM/hailey_dsilva/projects/AWS_cerebellum/FullStudy/ID_lists/W1_Eur_Prisma_Grp3_s3.txt",sep=""), sep="\t", row.names = FALSE,
            col.names = FALSE, quote = FALSE)
write.table(W1_Eur_Prisma_Grp3_sub, file=paste("/Volumes/Gruenlab-726014-YSM/hailey_dsilva/projects/AWS_cerebellum/FullStudy/ID_lists/W1_Eur_Prisma_Grp3_sub.txt",sep=""), sep="\t", row.names = FALSE,
            col.names = FALSE, quote = FALSE)
#W1_Eur_Achieva_Grp1
W1_Eur_Achieva_Grp1_IDs <- W1_Eur_Achieva_Grp1 %>% select(SUBJECTKEY)
W1_Eur_Achieva_Grp1_s3 <- W1_Eur_Achieva_Grp1 %>% select(ENDPOINT)
W1_Eur_Achieva_Grp1_sub <- W1_Eur_Achieva_Grp1 %>% 
  mutate(SUBJECTKEY_sub = paste("sub-",str_remove(SUBJECTKEY,"_"), sep="")) %>% select(SUBJECTKEY_sub)
write.table(W1_Eur_Achieva_Grp1_IDs, file=paste("/Volumes/Gruenlab-726014-YSM/hailey_dsilva/projects/AWS_cerebellum/FullStudy/ID_lists/W1_Eur_Achieva_Grp1_IDs.txt",sep=""), sep="\t", row.names = FALSE,
            col.names = FALSE, quote = FALSE)
write.table(W1_Eur_Achieva_Grp1_s3, file=paste("/Volumes/Gruenlab-726014-YSM/hailey_dsilva/projects/AWS_cerebellum/FullStudy/ID_lists/W1_Eur_Achieva_Grp1_s3.txt",sep=""), sep="\t", row.names = FALSE,
            col.names = FALSE, quote = FALSE)
write.table(W1_Eur_Achieva_Grp1_sub, file=paste("/Volumes/Gruenlab-726014-YSM/hailey_dsilva/projects/AWS_cerebellum/FullStudy/ID_lists/W1_Eur_Achieva_Grp1_sub.txt",sep=""), sep="\t", row.names = FALSE,
            col.names = FALSE, quote = FALSE)
#W1_Eur_Ingenia_Grp1
W1_Eur_Ingenia_Grp1_IDs <- W1_Eur_Ingenia_Grp1 %>% select(SUBJECTKEY)
W1_Eur_Ingenia_Grp1_s3 <- W1_Eur_Ingenia_Grp1 %>% select(ENDPOINT)
W1_Eur_Ingenia_Grp1_sub <- W1_Eur_Ingenia_Grp1 %>% 
  mutate(SUBJECTKEY_sub = paste("sub-",str_remove(SUBJECTKEY,"_"), sep="")) %>% select(SUBJECTKEY_sub)
write.table(W1_Eur_Ingenia_Grp1_IDs, file=paste("/Volumes/Gruenlab-726014-YSM/hailey_dsilva/projects/AWS_cerebellum/FullStudy/ID_lists/W1_Eur_Ingenia_Grp1_IDs.txt",sep=""), sep="\t", row.names = FALSE,
            col.names = FALSE, quote = FALSE)
write.table(W1_Eur_Ingenia_Grp1_s3, file=paste("/Volumes/Gruenlab-726014-YSM/hailey_dsilva/projects/AWS_cerebellum/FullStudy/ID_lists/W1_Eur_Ingenia_Grp1_s3.txt",sep=""), sep="\t", row.names = FALSE,
            col.names = FALSE, quote = FALSE)
write.table(W1_Eur_Ingenia_Grp1_sub, file=paste("/Volumes/Gruenlab-726014-YSM/hailey_dsilva/projects/AWS_cerebellum/FullStudy/ID_lists/W1_Eur_Ingenia_Grp1_sub.txt",sep=""), sep="\t", row.names = FALSE,
            col.names = FALSE, quote = FALSE)

#Check groupings for errors
W1_check <- bind_rows(W1_Eur_Achieva_Grp1_IDs, W1_Eur_Ingenia_Grp1_IDs, W1_Eur_PriFit_Grp1_IDs, W1_Eur_PriFit_Grp2_IDs,
                      W1_Eur_PriFit_Grp3_IDs, W1_Eur_Prisma_Grp1_IDs, W1_Eur_Prisma_Grp2_IDs, W1_Eur_Prisma_Grp3_IDs)
W1_check$SUBJECTKEY[duplicated(W1_check$SUBJECTKEY)]

W1_check <- bind_rows(W1_Eur_Achieva_Grp1_s3, W1_Eur_Ingenia_Grp1_s3, W1_Eur_PriFit_Grp1_s3, W1_Eur_PriFit_Grp2_s3,
                      W1_Eur_PriFit_Grp3_s3, W1_Eur_Prisma_Grp1_s3, W1_Eur_Prisma_Grp2_s3, W1_Eur_Prisma_Grp3_s3)
W1_check$ENDPOINT[duplicated(W1_check$ENDPOINT)]

W1_check <- bind_rows(W1_Eur_Achieva_Grp1_sub, W1_Eur_Ingenia_Grp1_sub, W1_Eur_PriFit_Grp1_sub, W1_Eur_PriFit_Grp2_sub,
                      W1_Eur_PriFit_Grp3_sub, W1_Eur_Prisma_Grp1_sub, W1_Eur_Prisma_Grp2_sub, W1_Eur_Prisma_Grp3_sub)
W1_check$SUBJECTKEY_sub[duplicated(W1_check$SUBJECTKEY_sub)]
