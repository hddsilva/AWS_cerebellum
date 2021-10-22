#Cleans the tables for MAGeT-processed cerebellum volumes

library(stringr)
library(dplyr)

#Import
PilotSubjs1 <- read.csv("Subjs1_cerebellum_volumes.csv", header = TRUE)
PilotSubjs2 <- read.csv("Subjs2_cerebellum_volumes.csv", header = TRUE)
W1_Eur_PriFit_Grp1 <- read.csv("W1_Eur_PriFit_Grp1.csv", header = TRUE)
W1_Eur_PriFit_Grp2 <- read.csv("W1_Eur_PriFit_Grp2.csv", header = TRUE)
W1_Eur_PriFit_Grp3 <- read.csv("W1_Eur_PriFit_Grp3.csv", header = TRUE)
W1_Eur_Prisma_Grp1 <- read.csv("W1_Eur_Prisma_Grp1.csv", header = TRUE)
W1_Eur_Prisma_Grp2 <- read.csv("W1_Eur_Prisma_Grp2.csv", header = TRUE)
W1_Eur_Prisma_Grp3 <- read.csv("W1_Eur_Prisma_Grp3.csv", header = TRUE)

#Merge
Final <- rbind(PilotSubjs1, PilotSubjs2) %>% 
  rbind(W1_Eur_PriFit_Grp1) %>% 
  rbind(W1_Eur_PriFit_Grp2) %>% 
  rbind(W1_Eur_PriFit_Grp3) %>%
  rbind(W1_Eur_Prisma_Grp1) %>%
  rbind(W1_Eur_Prisma_Grp2) %>%
  rbind(W1_Eur_Prisma_Grp3)

Test <- rbind(W1_Eur_PriFit_Grp1, W1_Eur_PriFit_Grp2) %>% 
  rbind(W1_Eur_PriFit_Grp3) %>%
  rbind(W1_Eur_Prisma_Grp1) %>%
  rbind(W1_Eur_Prisma_Grp2) %>%
  rbind(W1_Eur_Prisma_Grp3)

#Clean
Final$Subject <- str_match(Final$Subject, "ndar_.{11}")
#Check for duplicated rows
check_rows <- distinct(Final)
count(unique(Final[c("Subject")]))

write.csv(Final, "ABCD_CereVolumes.csv", row.names = FALSE)
