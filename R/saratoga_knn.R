library(tidyverse)
library(ggplot2)
library(modelr)
library(rsample)
library(mosaic)
library(foreach)
library(caret)

data(SaratogaHouses)

## Generate our folds for cross validation

K_folds = 10                        # folds, 10 standard
k_grid = c(2:100)                   # what values of K in KNN to check

saratoga_folds = crossv_kfold(SaratogaHouses, k=K_folds)


## Create a for loop to generate scaled data based on randomized training set

training <- foreach (i = 1:K_folds) %do% {
  
  # call each training set "train" with an index and then convert it to a matrix
  
  train_name <- paste("train_", i, sep = "") 
  train = as.data.frame(saratoga_folds$train[i])         
  train_mtx = model.matrix(~ . - 1, data=train)          
  
  # create our scale using only the training data
  
  scale_train = apply(train_mtx[,2:20], 2, sd)  # calculate std dev for each column
  
  # scale the training data using std dev of the training data
  
  scaled_train = scale(train_mtx[,2:20], scale = scale_train) %>% 
    as.data.frame()

  # this automatically removes price (because we don't want to scale it)
  # so we add it back in
  
  scaled_train = scaled_train %>%
    mutate(price = train_mtx[,1])
  
  # assign the name we created at the beginning  
  # drop prefixes and spaces in column names

  colnames(scaled_train) <- sub(".*\\.", "", colnames(scaled_train))
  names(scaled_train) <- str_replace_all(names(scaled_train), c(" " = "." , "/" = "." ))
  
  assign(train_name, scaled_test)

}

testing <- foreach (i = 1:K_folds) %do% {
  
  # repeat the same process for testing
  
  test_name <- paste("test_", i, sep = "")
  test = as.data.frame(saratoga_folds$test[i])
  test_mtx = model.matrix(~ . - 1, data=test) 
  
  # scale the testing data using std dev of the training data
  
  scaled_test = scale(test_mtx[,2:20], scale = scale_train) %>% 
    as.data.frame()
  
  # add price column back
  
  scaled_test = scaled_test %>%
    mutate(price = test_mtx[,1])
  
  # assign the name we created at the beginning  
  # drop prefixes and spaces in column names
  
  colnames(scaled_test) <- sub(".*\\.", "", colnames(scaled_test))
  names(scaled_test) <- str_replace_all(names(scaled_test), c(" " = "." , "/" = "." ))
  
  assign(test_name, scaled_train)
  
}

# We now have k-fold testing and training splits

# We can apply these to both KNN and the linear models

#####
# KNN
#####

# Calculate RMSE over folds for each value of k

cv_grid = foreach(k = k_grid, .combine='rbind') %dopar% {
  
  models = map(training, ~ knnreg(price ~ lotSize + age +landValue + livingArea +pctCollege + bedrooms + fireplaces + bathrooms + rooms + heatinghot.water.steam + heatinghot.water.steam + heatingelectric + fuelelectric + centralAirNo + fueloil + sewerpublic.commercial + sewernone + waterfrontNo + newConstructionNo, k=k, data = ., use.all=FALSE))
  
  errs = map2_dbl(models, testing, modelr::rmse)
  c(k=k, err = mean(errs), sd = sd(errs), std_err = sd(errs)/sqrt(K_folds))
  
} %>% as.data.frame

# Plot the results

ggplot(cv_grid) + 
  geom_point(aes(x=k, y=err)) + 
  geom_errorbar(aes(x=k, ymin = err-std_err, ymax = err+std_err)) + 
  scale_x_log10()

# can we make it better?

cv_grid2 = foreach(k = k_grid, .combine='rbind') %dopar% {
  
  models = map(training, ~ knnreg(price ~ lotSize + age +landValue + livingArea + bedrooms + fireplaces + bathrooms + rooms + centralAirNo + waterfrontNo, k=k, data = ., use.all=FALSE))
  
  errs = map2_dbl(models, testing, modelr::rmse)
  c(k=k, err = mean(errs), sd = sd(errs), std_err = sd(errs)/sqrt(K_folds))
  
} %>% as.data.frame

ggplot(cv_grid2) + 
  geom_point(aes(x=k, y=err)) + 
  geom_errorbar(aes(x=k, ymin = err-std_err, ymax = err+std_err)) + 
  scale_x_log10()

# can we make it worse?

cv_grid3 = foreach(k = k_grid, .combine='rbind') %dopar% {
  
  models = map(training, ~ knnreg(price ~ lotSize + bedrooms + bathrooms, k=k, data = ., use.all=FALSE))
  
  errs = map2_dbl(models, testing, modelr::rmse)
  c(k=k, err = mean(errs), sd = sd(errs), std_err = sd(errs)/sqrt(K_folds))
  
} %>% as.data.frame

ggplot(cv_grid3) + 
  geom_point(aes(x=k, y=err)) + 
  geom_errorbar(aes(x=k, ymin = err-std_err, ymax = err+std_err)) + 
  scale_x_log10()

# Choose optimal k at the lowest RMSE

opt_k = cv_grid%>%
  arrange(err)
min_k = opt_k[1,1]
min_rmse = opt_k[1,2]

opt_k2 = cv_grid2%>%
  arrange(err)
min_k2 = opt_k2[1,1]
min_rmse2 = opt_k2[1,2]

#####
# Better linear model
#####

better_rmse = foreach(i = 1:K_folds, .combine='rbind') %dopar% {
  
  # pull each fold and clean up
  
  test = as.data.frame(saratoga_folds$test[i])
  train = as.data.frame(saratoga_folds$train[i])
  
  colnames(test) <- sub(".*\\.", "", colnames(test)) 
  colnames(train) <- sub(".*\\.", "", colnames(train)) 
  
  # calculate rmse across all folds
    
  lm_better = lm(price ~ . - pctCollege - sewer - newConstruction, data=train)
  rmse(lm_better, test)
}

avg_rmse_better <- mean(better_rmse)

# baseline medium model with 11 main effects

baseline_rmse = foreach(i = 1:K_folds, .combine='rbind') %dopar% {
  
  # pull each fold and clean up
  
  test = as.data.frame(saratoga_folds$test[i])
  train = as.data.frame(saratoga_folds$train[i])
  colnames(test) <- sub(".*\\.", "", colnames(test)) 
  colnames(train) <- sub(".*\\.", "", colnames(train)) 

  # calculate rmse across all folds
  
  lm_baseline = lm(price ~ . - pctCollege - sewer - waterfront - landValue - newConstruction, data=train)
  rmse(lm_baseline, test)
}

avg_rmse_baseline <- mean(baseline_rmse)

# compare average RMSEs across each model

avg_rmse_better
min_rmse
min_rmse2
avg_rmse_baseline