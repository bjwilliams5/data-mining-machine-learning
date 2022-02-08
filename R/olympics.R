library(here)
library(tidyverse)

olympics <- read_csv(here("Data/olympics_top20.csv"))

athletics <- olympics %>% 
  filter(sport == "Athletics", sex == "F") %>% 
  select(id, height) %>% 
  unique()

quantile(athletics$height, probs = c(.95))

sddev <- olympics %>% 
  filter(sex == "F") %>% 
  group_by(event) %>% 
  summarize(stddev = sd(height)) %>% 
  arrange(desc(stddev)) %>% 
  head(1)

avgage <- olympics %>% 
  filter(sport == "Swimming") %>% 
  group_by(year, sex) %>% 
  summarize(avgage = mean(age))

ggplot(avgage) +
  geom_line(aes(x=year, y=avgage, color=sex))