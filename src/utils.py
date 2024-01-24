#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
This file defines constants and data importing and figure generating functions 
that will be used in other parts of the project.
"""

from sklearn.model_selection import train_test_split
from sklearn.metrics import confusion_matrix, balanced_accuracy_score
from sklearn.metrics import ConfusionMatrixDisplay, classification_report
from sklearn.preprocessing import LabelEncoder
import pandas as pd
import time


# Defining the project file path as object
my_save_path = "/proj/ncefi/uncso/projects/nsf_stem/randomforest/"

# Defining the seed for use in randomizers for this project
SEED = 1234


def report_and_plot_rf(model, true_y, predicted_y, label_dict, save_path, fig_name):
    """
    Helper function that prints a classification report and generates + exports a confusion matrix plot.

    Parameters
    ----------
    model : sklearn classification model
        Input the model here, will be added as a title in the figure. Helpful if multiple plots and models are constructed.
    true_y : ndarray
        ndarray of true classes.
    predicted_y : ndarray
        ndarray of predicted classes based on the model.
    label_dict : DICT
        Dictionary of class labels to class values.
    save_path : STR
        The file path where figure will be exported.
    fig_name : STR
        The name for this figure, will be the figure's file name with a date stamp.

    Returns
    -------
    Exports a confusion matrix figure and prints a classification report.
    """
    
    # Describing the model
    print(f'Model parameters:{model}')
    
    # Creating numerical confusion matrix, normalized
    confusion_mat_raw = confusion_matrix(true_y, predicted_y, normalize='true')

    # Creating a classification report
    report = classification_report(true_y, predicted_y, target_names = label_dict)
    print("Classification report:")
    print(report)

    # Balanced accuracy scores
    balanced_report = balanced_accuracy_score(true_y, predicted_y)
    print("Balanced Accuracy Score")
    print(balanced_report)
    
    # Creating the figure    
    CM_figure = ConfusionMatrixDisplay(confusion_matrix=confusion_mat_raw, display_labels=label_dict)
    CM_figure.plot()
    #adding the full command as title
    CM_figure.ax_.set_title(f'{model}', loc='center')
    # Saving to path with timestamp in figure name
    current_time = time.strftime("%Y%m%d-%H%M%S")
    CM_figure.figure_.savefig(f'{save_path + fig_name + "_" + current_time + ".png"}', 
                                  dpi=600,  
                                  format='png',
                                  bbox_inches= 'tight')


# helper function to be used during import of data to print data frame
# summaries to the console
def describe_df(df):
    """Helper function defining the data description steps"""
    # Getting info about dataframe
    print(df.info(verbose=True))

    # generating a dataframe that holds summary description of data frame
    df_summary = pd.DataFrame.describe(df)
    print(df_summary)
    return df_summary



# Defining helper functions that read in regression or classification data
def import_training_data(grading= 'whole_letter', test_size= 0.30):
    """
    Helper function that imports data with grades as whole or full letter or continuous points.

    Parameters
    ----------
    grading : {'whole_letter', 'full_letter', 'quality_points'}, default='whole_letter'
        Keyword options stating the desired grade format. Full letter grades 
        refer to the typical 'A+', 'A', 'A-' style of grading. Whole letter 
        grades are stripped of '+' and '-'. Quality points are more akin to GPA
        where a 3-credit hour course can award 12 quality points.
    test_size : float, default = 0.30
        Denotes the share of the data that will serve as the test set. Must be
        between 0 and 1.

    Returns
    -------
    df : Pandas Dataframe
        All available data as a Pandas data frame.
    df_summary : Pandas Dataframe
        A pandas.dataframe.summary object of the full data frame.
    sorting_ids : Pandas dataframe
        A dataframe of the IDs and index of observations.
    x_train : array, shape = (obs/1-test_size, features)
        An array of the X training data.
    x_test : array, shape = (obs/test_size, features)
        An array of the X test data.
    y_train : array, shape = (obs/1-test_size, )
        An array of the Y training data.
    y_test : array, shape = (obs/test_size, )
        An array of the Y test data.
    labels : sklearn.preprocessing.LabelEncoder object, Only returned if any of the two letter grade data were selected
        An instance of the ScikitLearn's LabelEncoder. Only returned if 
        'whole_letter' or 'full_letter' is selected for the grading parameter.
    """
    
    # defining the paths per file type
    if grading == 'whole_letter':
        path = '/proj/ncefi/uncso/projects/nsf_stem/data/rf_stemonly_wholegrades_training.dta'
        yvar = 'rf_grade'
        
    elif grading == 'full_letter':
        path = '/proj/ncefi/uncso/projects/nsf_stem/data/rf_stemonly_fullgrades_training.dta'
        yvar = 'rf_grade'
        
    elif grading == 'quality_points':
        path = '/proj/ncefi/uncso/projects/nsf_stem/data/rf_stemonly_qualitypoints_training.dta'
        yvar = 'quality_points'
        
    # reading data
    df = pd.read_stata(path, convert_categoricals= False)
    
    df_summary = describe_df(df=df)
    
    #Separating out the newid's and index of observations from features
    sorting_ids = df[['sorting', 'newid']]
    print(sorting_ids.columns.tolist())
    df = df.drop(columns = ['sorting', 'newid'])
    
    # Splitting df into X and Y matrix
    x_data = df.drop(yvar, axis=1) # creating an x df by dropping the y var
    y_data = df[yvar]
    
    # Encoding letter grades if needed
    if yvar == 'rf_grade':
        labels = LabelEncoder().fit(y_data)
        print(f'Classes in Y are: {labels.classes_}')
        y_data = labels.transform(y_data)
    
    # Test train split
    x_train, x_test, y_train, y_test = train_test_split(x_data, y_data, 
                                                        test_size= test_size, 
                                                        random_state= SEED)
    
    # defining the list of returns
    return_list = [df, df_summary, sorting_ids, 
                   x_train, x_test, y_train, y_test]
    if yvar == 'rf_grade':
        return_list.append(labels)
    
    return return_list
