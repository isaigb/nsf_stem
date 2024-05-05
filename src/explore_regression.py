"""
Created on Wed Jul  5 14:38:08 2023

@author: isaigb
"""


from sklearn.ensemble import RandomForestRegressor
from sklearn.linear_model import LassoCV, Lasso
from sklearn.model_selection import GridSearchCV, cross_val_score, cross_val_predict

import pandas as pd

import numpy as np

import math

import time

import matplotlib.pyplot as plt
import matplotlib.gridspec as grid_spec

import utils


# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# TODO's
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# TODO: run a HistGradientBoostingRegressor -> an estimator also found in xgboost
# this has native support for missing values and chooses which branch based on
# score. Rework data cleaning

# Importing data
df, df_summary, sorting_ids, x_train, x_test, y_train, y_test = utils.import_training_data(grading= 'quality_points')

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Defining basic random forest regression model and cross validating
# TODO: fix this code


# RF regressor
base_RF_reg = RandomForestRegressor(bootstrap = True, 
                                 random_state = utils.SEED,
                                 n_jobs = -1, 
                                 max_features= 'sqrt', 
                                 criterion = 'squared_error')

#storing max samples values for total training size/5 splits
count_obs = round(x_train.shape[0] * (4/5))


def gridcv_rf_reg():
    # Defining the search grid
    # searchgrid = {'n_estimators':[125, 350], 
    #               'max_samples':[count_obs, round(count_obs/2)]}
    
    searchgrid = {'n_estimators':[125, 350], 
                   'min_samples_leaf':[2,5]}

    cvsearch = GridSearchCV(base_RF_reg, searchgrid,
                             cv=5, 
                             verbose= 3,
                             scoring = 'r2')

    # Executing the fitting of the gridsearch
    cvsearch.fit(x_train, y_train)


    # saving results of search as a dataframe
    search_results = pd.DataFrame(cvsearch.cv_results_)

    # changing result to error
    search_results['error'] = 1 - search_results.mean_test_score

    # Saving results to CSV
    search_results.to_excel("/proj/ncefi/uncso/projects/nsf_stem/randomforest/rf_regressionCV.xlsx",)
    













# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# LASSO with manual CV
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

base_lasso = Lasso(fit_intercept= True,
                        copy_X= True, 
                        max_iter= 10000,
                        tol= 1e-4,
                        random_state= utils.SEED,
                        selection= 'random')

def gridcv_lasso():
    # Defining the search grid
    alpha_list = np.linspace(0.001, 5,  num=5)
    searchgrid = {'alpha': alpha_list}

    base_lasso_cvsearch = GridSearchCV(base_lasso, searchgrid,
                             cv=5, 
                             verbose= 3,
                             scoring = 'r2')

    # Executing the fitting of the gridsearch
    base_lasso_cvsearch.fit(x_train, y_train)


    # saving results of search as a dataframe
    lasso_results = pd.DataFrame(base_lasso_cvsearch.cv_results_)

    # changing result to error
    lasso_results['error'] = 1 - lasso_results.mean_test_score

    # Saving results to CSV
    lasso_results.to_excel("/proj/ncefi/uncso/projects/nsf_stem/randomforest/lasso_regressionCV.xlsx",)




# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# AdaBoostRegressor with manual CV
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# given non-normally distributed errors in RF regression, will try AdaBoostRegressor
# which uses gradient of trees to make better subsequent trees
# model requires tuning, never predicted zero's
# tune loss, learning_rate, number of trees
from sklearn.ensemble import AdaBoostRegressor

adaboost = AdaBoostRegressor(estimator = None, n_estimators= 50, 
                             learning_rate= 1.0, loss = 'square', 
                             random_state= utils.SEED)

adaboost_reg_yhat = cross_val_predict(adaboost, X= x_train, y= y_train, cv = 5, method= 'predict')
# check errors overall and for subgroups, plot errors, convert to grades and make confusion matrix
    
# convert to categoricals

# Create confusion matrix and report
utils.report_and_plot_rf(model= adaboost, 
                   true_y= grade_ytrue, 
                   predicted_y= grade_yhat, 
                   label_dict= labels.classes_, 
                   save_path= utils.my_save_path, 
                   fig_name="adaboost_reg2class")


# work with the errors
























# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# ExtraTreesRegressor with manual CV
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

from sklearn.ensemble import ExtraTreesRegressor






# Defining the rerun function that re-estimates all models
def rerun():
    gridcv_rf_reg()
    gridcv_lasso()


if __name__ == '__main__':
    rerun()