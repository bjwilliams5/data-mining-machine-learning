library(here)
library(tidyverse)

billboard <- read_csv(here("Data/billboard_clean.csv"))
  

## PART A

billboard_top10 <- billboard %>% 

  group_by(performer, song) %>% 
  summarize(count = n()) %>% 
  arrange(desc(count)) %>% 
  head(n = 10)

billboard_byyear <- billboard %>% 
  filter(year > 1958, year <2021) %>% 
  select(performer, song, year) %>% 
  unique() %>% 
  group_by(year) %>% 
  summarize(count = n())

ggplot(billboard_byyear) + 
  geom_line(aes(x=year, y=count))
  

billboard_10week <- billboard %>% 
  select(song, performer, week) %>% 
  group_by(song, performer) %>% 
  summarize(count = n()) %>% 
  filter(count >= 10) %>% 
  group_by(performer) %>% 
  summarize(count = n()) %>% 
  filter(count >= 30)

billboard_10week %>% 
  ggplot(aes(count, fct_reorder(performer, count))) + 
  geom_col() +
  labs(title="Billboard Top Performers", 
       subtitle="Number of Songs on Billboard for at least 10 Weeks",
       x="Number of Songs",
       y="Artist") +
  theme(plot.title.position = 'plot')