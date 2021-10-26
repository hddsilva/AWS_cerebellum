#Generates a list of the subjects who failed the minc and maget qcs
#Will use the generated list to move the failed subject data to a 
#"bad" folder on AWS so it won't be used

library(dplyr)

#Load in data
data <- read.table("W1_Eur_Ingenia_Grp1/W1_Eur_Ingenia_Grp1.csv", 
                   header = TRUE, sep = ",")

#Count of QC pass/fails
table(data$minc_bpipe_QC)

#Create a list of subjects that failed
failed_minc <- data %>%
  filter(minc_bpipe_QC == "No" | minc_bpipe_QC == "Maybe") %>% 
  select(Subj) %>% 
  mutate(Subj = tolower(Subj))

maybe_minc <- data %>%
  filter(minc_bpipe_QC == "Maybe") %>% 
  select(Subj) %>% 
  mutate(Subj = tolower(Subj))

failed_maget <- data %>%
  filter(MAGeT_QC == "No" | HD_decision == "No") %>% 
  select(Subj) %>% 
  mutate(Subj = tolower(Subj))

#Write out list
write.table(failed_minc, file=paste("W1_Eur_Ingenia_Grp1/failed_minc.txt",
                                    sep=""), 
            sep="\t", row.names = FALSE,
            col.names = FALSE, quote = FALSE)
write.table(failed_maget, file=paste("W1_Eur_Ingenia_Grp1/failed_maget.txt",
                                    sep=""), 
            sep="\t", row.names = FALSE,
            col.names = FALSE, quote = FALSE)
write.table(maybe_minc, file=paste("W1_Eur_Ingenia_Grp1/maybe_minc.txt",
                                     sep=""), 
            sep="\t", row.names = FALSE,
            col.names = FALSE, quote = FALSE)
