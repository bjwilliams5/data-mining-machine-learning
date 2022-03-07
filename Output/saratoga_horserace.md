# Homework 2

Patrick Massey, Harrison Snell, Brandon Williams

## Problem 1

## Problem 2

We consider three models for predicting the sale price of a house for
tax authority purposes. In order to assess the predictive power of each,
we conduct a “horse race” to determine who has the best predictive
ability when compared to a withheld testing set of the data. The three
models are: \* Simple linear model (our medium benchmark model) \*
Linear model with additional features and an interaction term \*
K-Nearest Neighbor (KNN) regression

For all three models, we use a train/test split of the data: the
training data set is used to build the model and the testing set is used
to evaluate the model’s predictive accuracy. In order to account for
random variation in the data depending on how we split it, we use k-fold
cross-validation which takes k number (in this case, k=10) train/test
splits and allows us to examine the average error over each split.

Consider first the baseline model. This model uses 11 main effects from
the data set in a linear regression. It includes the variables lot size,
age, living area, bedrooms, fireplaces, bathrooms, rooms, heating
method, fuel method, and central air. This model performed consistently
the worst. In this iteration, for example, it acheived an average
out-of-sample mean-squared error of `avg_rmse_baseline`.

This is to be expected. Economic intuition indicates that we are likely
ommitting important considerations for house prices, notably land value,
waterfront access and whether or not it is a new construction. We add
these to our linear model to improve it, as well as an interaction term
for lot size and waterfront access. Indeed, we see significant
improvement in the RMSE. In this iteration, we see a mean-squared error
of `avg_rmse_better`.

Finally, we attempt to create a KNN model. To begin, we include all
possible covariates and attempt to identify the value of K neighbors
that gives us the lowest mean-squared error. The following graph shows
the error on the vertical access and the value of k on the horizontal.

![](saratoga_horserace_files/figure-markdown_strict/unnamed-chunk-3-1.png)
The minimum RMSE can be found at k=`min_k` with a RMSE of `min_rmse`.
