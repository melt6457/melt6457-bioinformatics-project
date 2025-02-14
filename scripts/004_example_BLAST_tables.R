######################################################################
# Script to analyze data from BLAST stored in comma separated files:
#     output/curatedSummary.csv - top genus/descriptions
#     output/top5blast.csv - top genus/descriptions
#
#
# Kory Melton
# December 5, 2019
# kmelton@dons.usfca.edu
######################################################################

library("dplyr")
library("tidyr")
library("knitr")
library("ggplot2")
library("lubridate")
library("forcats")
library("ggthemes")

# These are the primary packages well use to clean and analyze the data
# this package needs to be installed from bioconductor -- it's not on CRAN
# see info here: https://benjjneb.github.io/dada2/dada-installation.html
library("dada2")

# read curated summary data in from csv
blast_results <- read.csv("output/curatedSummary.csv")

# flip the order of the data so the genus comes first
top_10_genus <- blast_results[, c(2, 1)] %>%
  arrange(desc(count)) %>%
  mutate(genus = paste0("*", genus, "*")) %>%
  head(10)

top_10_genus$genus <- gsub("[*]Proteobacteria[*]",
                     "Proteobacteria",
                     top_10_genus$genus)

######################################################
# Make a table of the top 10 genus
######################################################
# make table
kable(top_10_genus)

######################################################
# Work with data from top 5 genera/descriptions
######################################################
# read curated data on top 5 in from csv
top_5_genus <- read.csv("output/top5blast.csv")

# mutate the data frame to split scientific name into genus and species
top_5_genus$genus <- gsub(" .*$", "", top_5_genus$Scientific.Name)
top_5_genus$species <- gsub(".* ", "", top_5_genus$Scientific.Name)

# edit data so it will be in italics after knitting
top_5_genus$genus <- paste0("*",
                            top_5_genus$genus,
                            "*")
top_5_genus$species <- paste0("*",
                            top_5_genus$species,
                            "*")

# remove proteobacteria from species list
top_5_genus$species <- gsub("*Proteobacteria",
                              "",
                              top_5_genus$species)
top_5_genus$genus <- gsub("[*]Proteobacteria[*]",
                          "Proteobacteria",
                          top_5_genus$genus)

# get top by species w/o Bradyrhizobium and Pseudomonas
top_3_staph_rals_pro <- top_5_genus %>%
  filter(genus != "*Bradyrhizobium*") %>%
  filter(genus != "*Pseudomonas*") %>%
  group_by(genus, species) %>%
  tally() %>%
  arrange(desc(n)) %>%
  head(3)
  
# get top 3 of Bradyrhizobium and Pseudomonas
# Bradyrhizobium
top_3_br <- top_5_genus %>%
  filter(genus == "*Bradyrhizobium*") %>%
  group_by(genus, species) %>%
  tally() %>%
  arrange(desc(n)) %>%
  head(3)

# Pseudomonas
top_3_pseu <- top_5_genus %>%
  filter(genus == "*Pseudomonas*") %>%
  group_by(genus, species) %>%
  tally() %>%
  arrange(desc(n)) %>%
  head(3)

# bind Bradyrhizobium and Pseudomonas
top_3_bp <- rbind(top_3_br,
                  top_3_pseu)

# graph counts with genus on x and fill species
# Filtered for only the top 10 samples
# Ralstonia was ommitted to make graph more readable
# Proteobacteria didn't have any species
top_3_bp %>%
  filter(genus == 0 | 1) %>%
  filter(n > 10) %>%
  ggplot(aes(x = genus,
             y = n,
             fill = species)) +
  xlab("Genus") +
  ylab("Number of Samples") +
  ggtitle("BLAST Samples by Genus and Species") +
  geom_col(position = position_dodge()) +
  theme(axis.text.x = element_text(angle = 60,
                                   hjust = 1))

# make a table for other relevant counts
kable(top_3_staph_rals_pro)

#################################################
# Boxplots by scientific group
#################################################
# graph boxplot of percent identity by top 5 Genus
top_5_genus %>%
  ggplot(aes(x = genus,
             y = pident)) +
  geom_boxplot() +
  ggtitle("Percent Identity by Genus") +
  xlab("Genus") +
  ylab("Percent Identity") +
  theme_classic() +
  theme(axis.text.x = element_text(angle = 60,
                                   hjust = 1)) +
  geom_hline(yintercept = 90, color = "red")

# graph boxplot of length by top 5 Genus
top_5_genus %>%
  ggplot(aes(x = genus,
             y = length)) +
  geom_boxplot() +
  ggtitle("Length of Sequence Match by Genus") +
  xlab("Genus") +
  ylab("Length of Sequence") +
  theme_classic() +
  theme(axis.text.x = element_text(angle = 60,
                                   hjust = 1)) +
  geom_hline(yintercept = 200, color = "red")

# graph boxplot of evalue by top 5 genus
top_5_genus %>%
  filter(evalue < .0002) %>%
  ggplot(aes(x = genus,
             y = evalue)) +
  geom_boxplot() +
  ggtitle("Expected Value by Description") +
  xlab("Description") +
  ylab("Expected Value") +
  theme_classic() +
  theme(axis.text.x = element_text(angle = 60,
                                   hjust = 1)) +
  geom_hline(yintercept = 0.0001, color = "red")

# graph boxplot of bitscore by top 5 genus
top_5_genus %>%
  ggplot(aes(x = genus,
             y = bitscore)) +
  geom_boxplot() +
  ggtitle("Bitscore by Genus") +
  xlab("Genus") +
  ylab("Bitscore") +
  theme_classic() +
  theme(axis.text.x = element_text(angle = 60,
                                   hjust = 1)) +
  geom_hline(yintercept = 200, color = "red")

# Number of Samples in top 5 genus when controlled for
# - bitscore above 200
# - e value below 0.05
# - length above 200
# - percent identity above 90%
curated_top_5_totals <- top_5_genus %>%
  filter(bitscore > 200) %>%
  filter(evalue < 0.05) %>%
  filter(length > 200) %>%
  filter(pident > 90) %>%
  group_by(Genus) %>%
  tally()

curated_top_5_totals %>%
  ggplot(aes(x = genus,
             y = n)) +
  geom_col() +
  ggtitle("Number of Curated Samples") +
  xlab("Genus") +
  ylab("Total Samples") +
  theme_classic() +
  theme(axis.text.x = element_text(angle = 60,
                                   hjust = 1))

top_5_totals <- top_10_genus %>%
  head(5) %>%
  arrange(genus)

sort(top_5_totals$Genus)

top_5_totals$curated_count <- curated_top_5_totals$n

top_5_totals <- top_5_totals %>%
  arrange(desc(count))

kable(top_5_totals)
