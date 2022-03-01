library(tidyverse)
library(ggplot2)
library(naivebayes)
library(modelr)
library(rsample)

library(foreach)


## Let's consider first the manual calculation

# read in data
congress109 = read.csv("../data/congress109.csv", header=TRUE, row.names=1)
congress109members = read.csv("../data/congress109members.csv", header=TRUE, row.names=1)

X_small = dplyr::select(congress109, minimum.wage, war.terror, tax.relief, hurricane.katrina)
X_small[c('John McCain', 'Mike Pence', 'John Kerry', 'Edward Kennedy'),]

y = congress109members$party

#Sum prhase counts by party
R_rows = which(y == 'R')
D_rows = which(y == 'D')
colSums(X_small[R_rows,])
colSums(X_small[D_rows,])

probhat_R = colSums(X_small[R_rows,])
probhat_R =probhat_R/sum(probhat_R)
probhat_R %>% round(3)

probhat_D = colSums(X_small[D_rows,])
probhat_D =probhat_D/sum(probhat_D)
probhat_D %>% round(3)

# Sheila Jackson-Lee
X_small['Sheila Jackson-Lee',]

x_try = X_small['Sheila Jackson-Lee',]
sum(x_try * log(probhat_R))
sum(x_try * log(probhat_D))

table(y) %>%  prop.table %>%  round(3)

## Now we do Naive Bayes with test / train split

# First split into a training and set set
# our naive bayes function expects X and Y separated out
X_NB = as.matrix(congress109)  # feature matrix
y_NB = factor(congress109members$party)

# so let's manually create a train/test split
# a bit more annoying than initial_split, but not too bad.
# Plus, good to see this pipeline, since a lot of ML
# packages expect y and X separated out like this, rather than
# invoked via an lm-like formula syntax
N = length(y_NB)
train_frac = 0.8
train_set = sample.int(N, floor(train_frac*N)) %>% sort
test_set = setdiff(1:N, train_set)

# training and testing matrices
X_train = X_NB[train_set,]
X_test = X_NB[test_set,]

# Training and testing response vectors
y_train = y_NB[train_set]
y_test = y_NB[test_set]

# train the model: this function is in the naivebayes package.
# Check out "congress109_bayes_detailed" if you want to see a 
# version where we step through these calculations "by hand", i.e.
# not relying on a package to build the classifier.
nb_model = multinomial_naive_bayes(x = X_train, y = y_train)

# predict on the test set
y_test_pred = predict(nb_model, X_test)

# look at the confusion matrix
table(y_test, y_test_pred)

# overall test-set accuracy
sum(diag(table(y_test, y_test_pred)))/length(y_test)

# some examples of misses
misses = which(y_test != y_test_pred)
congress109members[test_set[misses],]
