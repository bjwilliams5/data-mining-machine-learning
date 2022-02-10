library(here)
library(tidyverse)

read_csv(here("Data/billboard.csv")) %>% 
  
  select(performer, song, year, week, week_position) %>% 
  
  write_csv(here("Data/billboard_clean.csv"))