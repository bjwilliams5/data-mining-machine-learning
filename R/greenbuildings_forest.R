library(tidyverse)
library(rpart)
library(rpart.plot)
library(rsample)
library(randomForest)
library(gbm)
library(pdp)

green <- read_csv("data/greenbuildings.csv")

green <- green %>% 
  mutate(revenue = Rent * leasing_rate / 100) %>% 
  as.data.frame()

# some exploratory plots

ggplot(green) +
  geom_point(aes(x=age, y=revenue, color=green_rating))

ggplot(green) +
  geom_point(aes(x=City_Market_Rent, y=revenue, color=green_rating))

# let's split our data into training and testing
green_split = initial_split(green, prop=0.8)
green_train = training(green_split)
green_test  = testing(green_split)

# consider a simple linear model

green.lm = lm(revenue ~ . - Rent - leasing_rate - LEED - Energystar - cluster - CS_PropertyID, data=green_train)
summary(green.lm)$coefficients[11,1]

# let's build a baseline tree model 

green.tree = rpart(revenue ~ . - Rent - leasing_rate - LEED - Energystar - cluster - CS_PropertyID, 
                     data=green_train,
                     control = rpart.control(cp = 0.0001, minsplit=30))


# a handy function for picking the smallest tree 
# whose CV error is within 1 std err of the minimum
cp_1se = function(my_tree) {
  out = as.data.frame(my_tree$cptable)
  thresh = min(out$xerror + out$xstd)
  cp_opt = max(out$CP[out$xerror <= thresh])
  cp_opt
}

cp_1se(green.tree)

# this function actually prunes the tree at that level
prune_1se = function(my_tree) {
  out = as.data.frame(my_tree$cptable)
  thresh = min(out$xerror + out$xstd)
  cp_opt = max(out$CP[out$xerror <= thresh])
  prune(my_tree, cp=cp_opt)
}

# let's prune our tree at the 1se complexity level
green.tree_prune = prune_1se(green.tree)

rpart.plot(green.tree, digits=-5, type=4, extra=1)

rpart.plot(green.tree_prune, digits=-5, type=4, extra=1)

green.forest = randomForest(revenue ~ . - Rent - leasing_rate - LEED - Energystar - cluster - CS_PropertyID,
                             data=green_train, importance = TRUE, na.action=na.omit)

# shows out-of-bag MSE as a function of the number of trees used
plot(green.forest)

# let's compare RMSE on the test set
modelr::rmse(green.lm, green_test)
modelr::rmse(green.tree_prune, green_test)
modelr::rmse(green.forest, green_test)

vi = varImpPlot(green.forest, type=1)

partialPlot(green.forest, green_test, 'green_rating', las=1)

# what if we try boosted?

green.boost = gbm(revenue ~ . - Rent - leasing_rate - LEED - Energystar - cluster - CS_PropertyID,
             data=green_train,
             interaction.depth=4, n.trees=1000, shrinkage=.05)

gbm.perf(green.boost)


yhat_test_gbm = predict(green.boost, green_test, n.trees=100)
modelr::rmse(green.boost, green_test)

# no improvement