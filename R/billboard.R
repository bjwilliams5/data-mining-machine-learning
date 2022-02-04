library(here)
library(tidyverse)

billboard <- read_csv(here("Data/billboard_clean.csv"))
  
billboard_top10 <- billboard %>% 

  group_by(performer, song) %>% 
  summarize(count = n()) %>% 
  arrange(desc(count)) %>% 
  head(n = 10)

billboard_unique <- billboard %>% 
  filter(year > 1958, year <2021) %>% 
  select(performer, song, year) %>% 
  unique() %>% 
  group_by(year) %>% 
  summarize(count = n())

ggplot(billboard_unique) + 
  geom_line(aes(x=year, y=count))
  
