library(tidyverse)
library(rpart)
library(rpart.plot)
library(rsample)
library(randomForest)
library(gbm)
library(pdp)
library(usmap)
library(caret)
library(modelr)
library(parallel)
library(foreach)

housing <- read_csv("data/CAhousing.csv")

hou_split =  initial_split(housing, prop=0.9)
hou_train = training(hou_split)
hou_test  = testing(hou_split)

## benchmarks

lm1 = lm(medianHouseValue ~ ., data=hou_train)
lm2 = lm(medianHouseValue ~ (.)^2, data=hou_train)


K_folds = 5

# Pipeline 1:
# create specific fold IDs for each row
# the default behavior of sample actually gives a permutation
housing = housing %>%
  mutate(fold_id = rep(1:K_folds, length=nrow(housing)) %>% sample)

head(loadhou)

# now loop over folds
rmse_cv = foreach(fold = 1:K_folds, .combine='c') %do% {
  knn100 = knnreg(medianHouseValue ~ .,
                  data=filter(housing, fold_id != fold), k=100)
  modelr::rmse(knn100, data=filter(housing, fold_id == fold))
}

rmse_cv
rmse(lm1, hou_test)
rmse(lm2, hou_test)

# evidence of some overfitting?

# let's try trees

hou.forest = randomForest(medianHouseValue ~ .,
                             data=hou_train, importance = TRUE, na.action=na.omit)

modelr::rmse(hou.forest, hou_test)

vi = varImpPlot(hou.forest, type=1)

yhat = predict(hou.forest, housing)

yhat_map <- housing %>% 
  mutate(yhat = predict(hou.forest, housing)) %>% 
  mutate(res = medianHouseValue - predict(hou.forest, housing)) %>% 
  usmap_transform()
  
plot_usmap(include = "CA") +
  geom_point(data = hou_map, aes(x = longitude.1, y = latitude.1, colour = medianHouseValue),
             alpha = 0.3)

plot_usmap(include = "CA") +
  geom_point(data = yhat_map, aes(x = longitude.1, y = latitude.1, colour = yhat),
             alpha = 0.3)

plot_usmap(include = "CA") +
  geom_point(data = yhat_map, aes(x = longitude.1, y = latitude.1, colour = res),
             alpha = 0.3)
