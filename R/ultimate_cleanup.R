library(tidyverse)
library(stringr)

final_df <- read_csv("GitHub/Data-Mining-Proj-1/data/final_df.csv")
final_df$mvp[is.na(final_df$mvp)] = '0'


final_df$G <- str_replace_all(final_df$G, " ", "")
final_df$G <- str_replace_all(final_df$G, "-", "")

final_df <- final_df %>% 
  mutate(champ = 
    ifelse(
      Year == 2012 & G == "PHS" |
        Year == 2013 & G == "TOR" |
        Year == 2014 & G == "SJ" |
        Year == 2015 & G == "SJ" |
        Year == 2016 & G == "DAL" |
        Year == 2017 & G == "SF" |
        Year == 2018 & G == "MAD" |
        Year == 2019 & G == "NY" |
        Year == 2021 & G == "RAL" 
        ,
      "1", "0")
  ) %>% 
  rename(plusminus = "+/-") 

final_df$Cmppct <- as.numeric(final_df$Cmppct)

## Let's try a simple linear model

lm1 <- lm(mvp ~ plusminus, data=final_df)
summary(lm1)

final_df$lm1_pred = predict(lm1)

ggplot(data = final_df) + 
  geom_jitter(aes(x=plusminus, y = mvp), 
              height=0.1, alpha=0.5)

## A more complicated linear model

lm2 <- lm(mvp ~ SCR + AST + GLS + BLK + Cmp + Cmppct + HA + Throwaway + S + D + C, data=final_df)
summary(lm2)
