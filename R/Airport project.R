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
library(colorspace)

ABIA <- read.csv(here("Data/ABIA.csv"))

## Let's take a look at what average delays look like for flights out of Austin 

ABIA_stats = ABIA %>% 
  filter(Origin == 'AUS') %>% 
  group_by(Dest) %>% 
  summarize(count = n(),
            mean_arr_delay = mean(ArrDelay, na.rm=TRUE)) %>% 
  filter(count > 499)
ABIA_stats

ggplot(ABIA_stats) +
  geom_col(aes(x = mean_arr_delay, fct_reorder(Dest, mean_arr_delay), fill = mean_arr_delay)) +
  scale_fill_continuous_sequential(palette = "Heat"
                                    )

mean(ABIA_stats$mean_arr_delay)

ABIA_airlines = ABIA %>% 
  filter(Origin == 'AUS') %>% 
  group_by(UniqueCarrier) %>% 
  summarize(count = n())
ABIA_airlines

## We need to clear the entire airports database from airport into airports in the US only
## Side note: we probably don't have to do this with inner_join, which matches only ids that appear in both

airports <- airports %>% 
  rename(Dest = IATA)

## Let's also have only Austin outgoing flights

ABIA_outbound <- ABIA %>% 
  filter(Origin == 'AUS')

## Let's join our tables

ABIA_locations <- inner_join(x = ABIA_outbound, y = airports, by = 'Dest')

## Great! We didn't lose any data, so each Destination had a corresponding airport code and now we have geographical information for each.

## We need to reorganize the data and map it to the usmap package:

ABIA_locations2 <- ABIA_locations %>%           # Reorder LAT
  dplyr::select("Latitude", everything())
ABIA_locations3 <- ABIA_locations2 %>%           # Reorder LONG
  dplyr::select("Longitude", everything())



ABIA_locations <- ABIA_locations %>%           
  dplyr::select("Latitude", everything()) %>%       # Reorder LAT
  dplyr::select("Longitude", everything()) %>%      # Reorder LONG
  group_by(Longitude, Latitude, Dest) %>%           #Only 100+ flight destinations
  summarize(count = n(),
            mean_arr_delay = mean(ArrDelay, na.rm=TRUE)) %>% 
  filter(count > 499)


ABIA_transformed <- usmap_transform(ABIA_locations)

ABIA_hubs <- ABIA_transformed %>% 
  filter(Dest == "DEN" |
           Dest == "DAL" |
           Dest == "ORD" |
           Dest == "ATL" |
           Dest == "CLT")

ABIA_hubdata <- ABIA_hubs %>% 
  select(Dest, count, mean_arr_delay) %>% 
  arrange(desc(mean_arr_delay)) %>% 
  rename(Flights = count) %>% 
  rename(Destination = Dest) %>% 
  rename("Average Delay (Mins)" = mean_arr_delay)

ABIA_worstdata <- ABIA_transformed %>% 
  select(Dest, count, mean_arr_delay) %>% 
  arrange(desc(mean_arr_delay)) %>% 
  rename(Flights = count) %>% 
  rename(Destination = Dest) %>% 
  rename("Average Delay (Mins)" = mean_arr_delay) %>% 
  head(5)
  
  

plot_usmap() +
  geom_point(data = ABIA_transformed, aes(x = Longitude.1, y = Latitude.1, colour = mean_arr_delay, size = mean_arr_delay),
             alpha = 0.8) +
  scale_color_continuous_sequential(palette = "Heat", guide = "legend") +
  scale_size_continuous(range = c(1, 16)) +
  ggrepel::geom_label_repel(data = ABIA_hubs,
                            aes(x = Longitude.1, y = Latitude.1, label = Dest),
                            size = 3, alpha = 0.8,
                            label.r = unit(0.5, "lines"), label.size = 0.5,
                            segment.color = "red", segment.size = 1,
                            seed = 1002) +
  labs(title = "Worst Arrival Delays by Airport",
       subtitle = "Arriving from Austin (At Least 500 Flights)") + 
  theme(legend.position = "right")

plot_usmap() +
  geom_point(data = ABIA_transformed, aes(x = Longitude.1, y = Latitude.1, color = mean_arr_delay),
             alpha = 0.5, size = 10) +
  scale_color_continuous_sequential(palette = "Heat") +
  labs(title = "Flights",
       subtitle = "Source: ") + 
  theme(legend.position = "right")

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