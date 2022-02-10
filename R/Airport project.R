library(tidyverse)
library(mosaic)
library(airportr)
library(dplyr)
library(usmap)
library(maptools)
library(ggplot2)
library(rgdal)
library(viridis)
library(here)

ABIA <- read.csv(here("Data/ABIA.csv"))

## Let's take a look at what average delays look like for flights out of Austin 

ABIA_stats = ABIA %>% 
  filter(Origin == 'AUS') %>% 
  group_by(Dest) %>% 
  summarize(count = n(),
            mean_arr_delay = mean(ArrDelay, na.rm=TRUE)) %>% 
  filter(count > 99)

ABIA_airlines = ABIA %>% 
  filter(Origin == 'AUS') %>% 
  group_by(UniqueCarrier) %>% 
  summarize(count = n())

## We need to clear the entire airports database from airport into airports in the US only
## Side note: we probably don't have to do this with inner_join, which matches only ids that appear in both

airportsUS <- airports %>% 
  filter(`Country Code` == 840) %>% 
  rename(Dest = IATA)

## Let's also have only Austin outgoing flights

ABIA_outbound <- ABIA %>% 
  filter(Origin == 'AUS')

## Let's join our tables

ABIA_locations <- inner_join(x = ABIA_outbound, y = airportsUS, by = 'Dest')

## Great! We didn't lose any data, so each Destination had a corresponding airport code and now we have geographical information for each.

## We need to reorganize the data and map it to the usmap package:

ABIA_locations2 <- ABIA_locations %>%           # Reorder LAT
  dplyr::select("Latitude", everything())
ABIA_locations3 <- ABIA_locations2 %>%           # Reorder LONG
  dplyr::select("Longitude", everything())

## This step could probably be consolidated. 

ABIA_locations4 <- ABIA_locations3 %>% 
  group_by(Longitude, Latitude, Dest) %>% 
  summarize(count = n(),
            mean_arr_delay = mean(ArrDelay, na.rm=TRUE)) %>% 
  filter(count > 99)

ABIA_transformed <- usmap_transform(ABIA_locations4)
  
## Create separate script to save csv

## Let's try a plot:

plot_usmap() +
  geom_point(data = ABIA_transformed, aes(x = Longitude.1, y = Latitude.1, colour = mean_arr_delay, size = mean_arr_delay),
             alpha = 0.5) +
  scale_color_viridis_b(direction = -1, guide = "legend") +
  scale_size_continuous(range = c(.1, 16)) +
  labs(title = "Flights",
       subtitle = "Source: ") + 
  theme(legend.position = "right")

## Plot needs to be updated for easy readability. Can play around with adding labels here: https://cran.r-project.org/web/packages/usmap/vignettes/advanced-mapping.html

## According to Business Wire, the major transfer hubs in the US are Dallas/Fort Worth (American), Charlotte (American), Atlanta (Delta), Chicago-O'Hare (United), and Denver (Frontier). https://www.businesswire.com/news/home/20170925005333/en/OAG-Unveils-the-Most-Connected-Airports-in-the-U.S.