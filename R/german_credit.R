library(rsample)

german_credit <- read.csv(here("Data/german_credit.csv"))

german_default <- german_credit %>% 
  group_by(history) %>% 
  summarize(default_rate = mean(Default))

ggplot(german_default) +
   geom_col(aes(x=history, y=default_rate))

credit_split = initial_split(german_credit, prop = 0.8)
credit_train = training(credit_split)
credit_test = testing(credit_split)

logit_credit = glm(Default ~ ., data=credit_train)
coef(logit_credit) %>%  round(3)

# Threshold at 50%

phat_test_logit_credit = predict(logit_credit, credit_test, type='response')
yhat_test_logit_credit = ifelse(phat_test_logit_credit > .5, 1, 0)
confusion_out_logit = table(y = credit_test$Default,
                            yhat = yhat_test_logit_credit)
confusion_out_logit

# We didn't do great, error rate of 46/200 or 23%, accuracy of 77%. 
# TPR of 29/57 = 50.8%. FDR of 18/47 = 38.3%
