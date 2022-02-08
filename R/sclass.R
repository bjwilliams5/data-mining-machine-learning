library(tidyverse)
library(ggplot2)
library(rsample)  # for creating train/test splits
library(caret)
library(modelr)
library(parallel)
library(foreach)
library(here)


sclass <- read_csv(here("Data/sclass.csv"))
