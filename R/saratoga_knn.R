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

foreach (i = 1:K_folds, .combine='rbind') %do% {
  
  # call each training set "train" with an index and then convert it to a matrix
  
  train_name <- paste("train_", i, sep = "") 
  train = as.data.frame(saratoga_folds$train[i])         
  train_mtx = model.matrix(~ . - 1, data=train)          
  
  # repeat the same process for testing
  
  test_name <- paste("test_", i, sep = "")               
  test = as.data.frame(saratoga_folds$test[i])           
  test_mtx = model.matrix(~ . - 1, data=test) 
  
  # create our scale using only the training data
  
  scale_train = apply(train_mtx[,2:20], 2, sd)  # calculate std dev for each column
  
  # scale the training and testing data using std dev of the training data
  
  scaled_train = scale(train_mtx[,2:20], scale = scale_train) %>% 
    as.data.frame()
  scaled_test = scale(test_mtx[,2:20], scale = scale_train) %>% 
    as.data.frame()
  
  # this automatically removes price (because we don't want to scale it)
  # so we add it back in
  
  scaled_test = scaled_test %>%
    mutate(price = test_mtx[,1])
  scaled_train = scaled_train %>%
    mutate(price = train_mtx[,1])
  
  # assign the name we created at the beginning  
  # drop prefixes and spaces in column names

  colnames(scaled_test) <- sub(".*\\.", "", colnames(scaled_test))
  names(scaled_test) <- str_replace_all(names(scaled_test), c(" " = "." , "/" = "." ))
  colnames(scaled_train) <- sub(".*\\.", "", colnames(scaled_train))
  names(scaled_train) <- str_replace_all(names(scaled_train), c(" " = "." , "/" = "." ))
  
  assign(train_name, scaled_test)
  assign(test_name, scaled_train)
  
}

# We now have k-fold testing and training splits

first <- list(train_1, train_2)
second <- list(test_1, test_2)
combined <- mapply(c, first, second, SIMPLIFY=FALSE)

knnreg(price ~ lotSize + age +landValue + livingArea + bedrooms + 
         fireplaces + bathrooms + rooms + heatinghot.water.steam
       + heatingelectric + fuelelectric + centralAirNo + fueloil, k=20, data = train_1, use.all=FALSE)
              
models = map(loadhou_folds$train, ~ knnreg(COAST ~ KHOU, k=100, data = ., use.all=FALSE))

