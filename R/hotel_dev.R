

hotels_dev <- read.csv(here("Data/hotels_dev.csv"))


hotels_split = initial_split(hotels_dev, prop = 0.8)
hotels_train = training(hotels_split)
hotels_test = testing(hotels_split)


lm_small = lm(children ~ market_segment + adults + customer_type + is_repeated_guest,
              data = hotels_train)
coef(lm_small)

lm_manual = lm(children ~ hotel + lead_time + stays_in_weekend_nights + stays_in_week_nights + adults + meal + distribution_channel + market_segment + distribution_channel + is_repeated_guest + previous_cancellations + previous_bookings_not_canceled + reserved_room_type + assigned_room_type + booking_changes + deposit_type + days_in_waiting_list + customer_type + average_daily_rate + required_car_parking_spaces + total_of_special_requests,
              data = hotels_train)

lm_big = lm(children ~ . - arrival_date,
              data = hotels_train)
coef(lm_big)

lm0 = lm(children ~ 1, data=hotels_train)
lm_forward = step(lm0, direction='forward', 
                  scope=~(hotel + lead_time + stays_in_weekend_nights + stays_in_week_nights + adults + meal + distribution_channel + market_segment + distribution_channel + is_repeated_guest + previous_cancellations + previous_bookings_not_canceled + reserved_room_type + assigned_room_type + booking_changes + deposit_type + days_in_waiting_list + customer_type + average_daily_rate + required_car_parking_spaces + total_of_special_requests)^2)

lm_step = step(lm_big, 
               scope=~(.)^2)

AICc(lm_small, hotels_test)
rmse(lm_small, hotels_test)
rmse(lm_big, hotels_test)
rmse(lm_manual, hotels_test)
rmse(lm_forward, hotels_test)

colnames(hotels_train)
