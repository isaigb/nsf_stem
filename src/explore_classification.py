#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
This script uses various configurations of the random forest algorithm, other
classification algorithms, and class balancing to learn the relationship 
between data X and classes Y.
"""


from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import GridSearchCV, StratifiedKFold
from sklearn.model_selection import cross_val_score, cross_val_predict

from imblearn.ensemble import BalancedRandomForestClassifier, RUSBoostClassifier
from imblearn.under_sampling import RandomUnderSampler
from imblearn.over_sampling import RandomOverSampler, SMOTE
from imblearn.pipeline import Pipeline

import pandas as pd
import matplotlib.pyplot as plt
from numpy import mean

import utils

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# TODO's
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# TODO: add pipeline for undersampling largest class, then SMOTE for rest
# TODO: define the tuning procedure
# Defining the tuning procedure for hyperparameters
    # e.g., loop over all RF parameters, place rf estimator inside loop and
    # fill in with values. Finally run the cross validator predict, export figure


# =============================================================================
# Importing Data
# =============================================================================

df, df_summary, sorting_ids, x_train, x_test, y_train, y_test, labels = utils.import_training_data(grading= 'whole_letter')



# =============================================================================
# Using imbalanced-learn pipelines
# =============================================================================

# defining a basic random forest basic model
base_RF = RandomForestClassifier(bootstrap = True,
                                 n_estimators= 350,
                                 random_state = utils.SEED, 
                                 n_jobs= -1,
                                 criterion = 'gini',
                                 class_weight=None,
                                 max_features= 'sqrt')


# Defining my K-fold strategy: stratified k-fold
stratKF = StratifiedKFold(n_splits = 5, random_state= utils.SEED, shuffle= True)


# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Random Unders Sampling (RUS) pipeline
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Note: n_jobs option should be in classifier NOT in the search/predict cv to
#       avoid crashing

# Defining the Random Unders Sampling (RUS) pipeline
pipeRUS = Pipeline([
    ('RUS', RandomUnderSampler(sampling_strategy= 'not minority', random_state= utils.SEED)), 
    ('rforest', base_RF)])


# Predict classes for left-out set for all k-folds
def cv_rus_rf():
    pipeRUS_yhat = cross_val_predict(pipeRUS, X= x_train, y= y_train, cv= stratKF, verbose= 2, method= 'predict')

    # Create confusion matrix and report
    utils.report_and_plot_rf(model= pipeRUS, 
                       true_y= y_train, 
                       predicted_y= pipeRUS_yhat, 
                       label_dict= labels.classes_, 
                       save_path= utils.my_save_path, 
                       fig_name="rf_pipeRUS")


# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Random Over Sampling (ROS) pipeline
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

# Defining the ROS pipeline
pipeROS = Pipeline([
    ('ROS', RandomOverSampler(sampling_strategy= 'all', random_state= utils.SEED)), 
    ('rforest', base_RF)])


# predict using CV methods and making report
def cv_ros_rf():
    pipeROS_yhat = cross_val_predict(pipeROS, X= x_train, y= y_train, cv= stratKF, verbose= 3, method= 'predict')

    # Create confusion matrix and report
    utils.report_and_plot_rf(model= pipeROS, 
                       true_y= y_train, 
                       predicted_y= pipeROS_yhat, 
                       label_dict= labels.classes_, 
                       save_path= utils.my_save_path, 
                       fig_name="rf_pipeROS")


# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Synthetic Minority Oversampling TEchnique (SMOTE) pipeline
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

# Defining the SMOTE pipeline
pipeSMOTE = Pipeline([
    ('SMOTE', SMOTE(sampling_strategy= 'not majority', random_state= utils.SEED)), 
    ('rforest', base_RF)])

# Predict using CV methods
def cv_smote_rf():
    pipeSMOTE_yhat = cross_val_predict(pipeSMOTE, X= x_train, y= y_train, cv= stratKF, verbose= 3, method= 'predict')

    # Create confusion matrix and report
    utils.report_and_plot_rf(model= pipeSMOTE, 
                       true_y= y_train, 
                       predicted_y= pipeSMOTE_yhat, 
                       label_dict= labels.classes_, 
                       save_path= utils.my_save_path, 
                       fig_name="rf_pipeSMOTE")





# =============================================================================
# Using imbalanced-learn implementation of balanced RF
# =============================================================================

# Defining a basic balanced RF
balanced_rf = BalancedRandomForestClassifier(n_estimators = 350, 
                                      bootstrap = True,
                                      replacement= True,
                                      random_state = utils.SEED, 
                                      n_jobs = -1,  
                                      class_weight= None,
                                      max_features= 'sqrt',
                                      criterion = 'gini',
                                      sampling_strategy= 'all')

# creating predicted y-hat
def cv_balanced_rf():
    balanced_rf_yhat = cross_val_predict(balanced_rf, X= x_train, y= y_train, cv= stratKF, verbose= 3, method= 'predict')

    # Create confusion matrix and report
    utils.report_and_plot_rf(model= balanced_rf, 
                       true_y= y_train, 
                       predicted_y= balanced_rf_yhat, 
                       label_dict= labels.classes_, 
                       save_path= utils.my_save_path, 
                       fig_name="rf_balancedRF")


# =============================================================================
# Using imbalanced-learn RUSBoostClassifier
# =============================================================================
# Defining a baseline model
rusboost = RUSBoostClassifier(sampling_strategy= 'all', random_state= utils.SEED)

# creating predicted y-hat
def cv_rusboost():
    rusboost_yhat = cross_val_predict(rusboost, X= x_train, y= y_train, cv= stratKF, verbose= 3, method= 'predict')

    # Create confusion matrix and report
    utils.report_and_plot_rf(model= rusboost, 
                       true_y= y_train, 
                       predicted_y= rusboost_yhat, 
                       label_dict= labels.classes_, 
                       save_path= utils.my_save_path, 
                       fig_name="rusboost")



# Defining the rerun function that re-estimates all models
def rerun():
    cv_rus_rf()
    cv_ros_rf()
    cv_smote_rf()
    cv_balanced_rf()
    cv_rusboost()


if __name__ == '__main__':
    rerun()