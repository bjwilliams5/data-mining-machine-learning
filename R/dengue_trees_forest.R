library(tidyverse)
library(rpart)
library(rpart.plot)
library(rsample)
library(randomForest)
library(gbm)
library(pdp)

dengue <- read_csv("data/dengue.csv")


# To avoid errors in partial plot, I need to clean the data a bit
dengue <- dengue %>% 
  as.data.frame() %>% 
  na.omit() 


# let's split our data into training and testing
dengue_split =  initial_split(dengue, prop=0.8)
dengue_train = training(dengue_split)
dengue_test  = testing(dengue_split)


## A tree with default control

dengue.tree1 = rpart(total_cases ~ season + precipitation_amt + avg_temp_k + air_temp_k + 
                       dew_point_temp_k + max_air_temp_k + min_air_temp_k +
                       precip_amt_kg_per_m2 + relative_humidity_percent + specific_humidity + tdtr_k, 
                     data=dengue_train)

## Tree with modified control

dengue.tree2 = rpart(total_cases ~ season + precipitation_amt + avg_temp_k + air_temp_k + 
                      dew_point_temp_k + max_air_temp_k + min_air_temp_k +
                      precip_amt_kg_per_m2 + relative_humidity_percent + specific_humidity + tdtr_k, 
                    data=dengue_train,
                    control = rpart.control(cp = 0.0000001, minsplit=30))


rpart.plot(dengue.tree2, digits=-5, type=4, extra=1)

plotcp(dengue.tree2)

# a handy function for picking the smallest tree 
# whose CV error is within 1 std err of the minimum
cp_1se = function(my_tree) {
  out = as.data.frame(my_tree$cptable)
  thresh = min(out$xerror + out$xstd)
  cp_opt = max(out$CP[out$xerror <= thresh])
  cp_opt
}

cp_1se(dengue.tree2)

# this function actually prunes the tree at that level
prune_1se = function(my_tree) {
  out = as.data.frame(my_tree$cptable)
  thresh = min(out$xerror + out$xstd)
  cp_opt = max(out$CP[out$xerror <= thresh])
  prune(my_tree, cp=cp_opt)
}

# let's prune our tree at the 1se complexity level
dengue.tree2_prune = prune_1se(dengue.tree2)

dengue.tree2_prune

rpart.plot(dengue.tree2_prune, digits=-5, type=4, extra=1)

# Random Forest


dengue.forest = randomForest(total_cases ~ season + precipitation_amt + avg_temp_k + air_temp_k + 
                             dew_point_temp_k + max_air_temp_k + min_air_temp_k +
                             precip_amt_kg_per_m2 + relative_humidity_percent + specific_humidity + tdtr_k,
                           data=dengue_train, importance = TRUE, na.action=na.omit)

# shows out-of-bag MSE as a function of the number of trees used
plot(dengue.forest)

# let's compare RMSE on the test set
modelr::rmse(dengue.tree2_prune, dengue_test)
modelr::rmse(dengue.forest, dengue_test)

vi = varImpPlot(dengue.forest, type=1)
 

partialPlot(dengue.forest, dengue_test, 'specific_humidity', las=1)
partialPlot(dengue.forest, dengue_test, 'precipitation_amt', las=1)
partialPlot(dengue.forest, dengue_test, 'max_air_temp_k', las=1)


## Boosted 

boost1 = gbm(total_cases ~ season + precipitation_amt + avg_temp_k + air_temp_k + 
               dew_point_temp_k + max_air_temp_k + min_air_temp_k +
               precip_amt_kg_per_m2 + relative_humidity_percent + specific_humidity + tdtr_k,
             data=dengue_train,
             interaction.depth=4, n.trees=500, shrinkage=.05)

# It doesn't like the season variable

# Look at error curve -- stops decreasing much after ~300
gbm.perf(boost1)


yhat_test_gbm = predict(boost1, dengue_test, n.trees=350)

# RMSE
modelr::rmse(dengue.tree2_prune, dengue_test)
modelr::rmse(dengue.forest, dengue_test)
modelr::rmse(boost1, dengue_test)
