
capmetro_UT <- read.csv(here("Data/capmetro_UT.csv"))

capmetro_UT <- mutate(capmetro_UT,
                     day_of_week = factor(day_of_week,
                                          levels=c("Mon", "Tue", "Wed","Thu", "Fri", "Sat", "Sun")),
                     month = factor(month,
                                    levels=c("Sep", "Oct","Nov")),
                     date = ymd_hms(timestamp))

capmetro_rev <- capmetro_UT %>% 
  group_by(hour_of_day, day_of_week, month) %>% 
  summarize(avg_boarding = mean(boarding))

ggplot(capmetro_rev) +
  geom_line(aes(x=hour_of_day, y=avg_boarding, color=month)) +
  facet_wrap(~day_of_week)

ggplot(capmetro_UT) +
  geom_point(aes(x=temperature, y=boarding, color=weekend)) +
  facet_wrap(~hour_of_day)
