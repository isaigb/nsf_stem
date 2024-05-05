"""
Trains models and generates figures for the AEFP 2024 conference.
"""

import utils
import explore_classification
import matplotlib.pyplot as plt
import matplotlib.gridspec as grid_spec
import pandas as pd
import numpy as np

from sklearn.metrics import confusion_matrix, balanced_accuracy_score
from sklearn.metrics import ConfusionMatrixDisplay, classification_report


# Setting up, getting data and defining functions
df, df_summary, sorting_ids, x_train, x_test, y_train, y_test, labels = utils.import_training_data(grading= 'whole_letter')

# helpfer function
# TODO: move to utils, make this file call utils.histhelper
def histhelper(ax, xloc, yloc, data, xtype = 'errors', title= '', histtype = 'bar', density = True):
    """
    Helper function that constructs a single histogram plotting errors or grade distributions.

    Args:
        ax (matplotlib.axes.Axes): The returned axes object from a matplotlib.plots.subplots() call.
        xloc (int): Int representing the row in which to place histogram.
        yloc (int): Int representing the column in which to place histogram.
        data (pandas.DataFrame): A Pandas dataframe.
        xtype (str, optional): Select whether plot is for 'errors' or 'grades'. Defaults to 'errors'.
        title (str, optional): Title for subplot, not entire plot. Defaults to empty string.
        histtype (str, optional): Select bar or step histogram. Step is outline of hist, no fill. Defaults to 'bar'.
        density (bool, optional): When False, Y axis is count, when True Y axis is percentage of total. Defaults to True.
    """
    if xtype == 'errors':
        ticks = [-4, -3, -2, -1, 0, 1, 2, 3, 4]
        labels = ['-4', '-3', '-2', '-1', '0', '1', '2', '3', '4']
    if xtype == 'grades': 
        ticks = [-1, 0, 1, 2, 3, 4]
        labels = ['', 'A', 'B', 'C', 'D', 'F']
    ax[xloc, yloc].hist(data, bins = [-4.5, -3.5, -2.5, -1.5, -0.5, 0.5, 1.5, 2.5, 3.5, 4.5], rwidth = 0.75, align = 'mid', histtype = histtype, density = density)
    ax[xloc, yloc].set_title(title)
    # sets x axis min/max
    if xtype =='errors':
        ax[xloc, yloc].set_xlim(-5, 5)
    if xtype == 'grades':
        ax[xloc, yloc].set_xlim(-1, 5)
    ax[xloc, yloc].set_xticks(ticks, labels)




# # Naive classifier plots
naive_modal_yhat, naive_stratified_yhat, naive_uniform_yhat, naive_predict_b_yhat, naive_predict_c_yhat = explore_classification.get_naive_predictions()

# Names for naive models
naive_model_names = ['modal', 'stratified_random', 'uniform_random']

# titles for plots
naive_titles = ["Predicts Most Common", 
                "Stratified Random Prediction", 
                "Uniform Random Prediction"]
# list of predictions
naive_predictions = [naive_modal_yhat, 
                     naive_stratified_yhat, 
                     naive_uniform_yhat]


ncolumns = 2
nrows = 3
r = 0
c = 0
#sharey option shares Y axis min/max along columns
histfig, histaxes = plt.subplots(nrows, ncolumns,  figsize = (8,9), tight_layout = True, sharey = 'col')
for i, desc in zip(naive_predictions, naive_titles):
    confusion_mat_raw = confusion_matrix(y_train, i, normalize='true')
    confusion_mat_raw = confusion_matrix(y_train, i)
    
    
    # plot the confusion matrix
    histaxes[r, c].set_title(desc)
    ConfusionMatrixDisplay.from_predictions(y_train, i, display_labels = labels.classes_, normalize = 'true').plot(ax = histaxes[r, c])
    
    # next portion ensures subsequent plots move from right to left, top to bottom
    if c < ncolumns-1:
        c += 1
    elif ((c >= ncolumns-1) and (r < nrows - 1)):
        c = 0
        r += 1
    else: break

    errors  = y_train - i
    histhelper(ax = histaxes, xloc = r, yloc= c, data = errors, title = desc)
    
    # next portion ensures subsequent plots move from right to left, top to bottom
    if c < ncolumns-1:
        c += 1
    elif ((c >= ncolumns-1) and (r < nrows - 1)):
        c = 0
        r += 1
    else: break
histaxes[0, 1].set_ylim(0, 0.75)
histfig.suptitle('Distribution of Prediction Errors for Naive Models', fontsize=16)
histfig.savefig(f'{utils.fig_path}aefp_naivemodels_cm_errors.png', dpi=300, bbox_inches='tight', format= 'png')

# ======================
# commenting out this block for now, don't need
# # titles for plots
# naive_titles = ["Predicts Most Common", 
#                 "Randomly Samples Stratified Distribution", 
#                 "Randomly Samples from Uniform Distribution", 
#                 "Predicts B's", 
#                 "Predicts C's"]
# # list of predictions
# naive_predictions = [naive_modal_yhat, 
#                      naive_stratified_yhat, 
#                      naive_uniform_yhat, 
#                      naive_predict_b_yhat, 
#                      naive_predict_c_yhat]

# # list of confusion matrices
# naive_confusion_mats = []
# for i, desc in zip(naive_predictions, naive_titles):
#     confusion_mat_raw = confusion_matrix(y_train, i, normalize='true')
#     naive_confusion_mats.append(confusion_mat_raw)
#     # add reports here?
#     # add balanced accuracy here? append into a single large csv?
#     # Creating a classification report
#     report = classification_report(y_train, i, target_names = labels.classes_)
#     print(f'Classification report: {desc}')
#     print(report)

#     # Balanced accuracy scores
#     balanced_report = balanced_accuracy_score(y_train, i)
#     print(f'Balanced Accuracy Score: {desc}')
#     print(balanced_report)
    
#     # Creating the figure    
#     CM_figure = ConfusionMatrixDisplay(confusion_matrix=confusion_mat_raw, display_labels=labels.classes_)
#     CM_figure.plot()
#     #adding the full command as title
#     CM_figure.ax_.set_title(f'{desc}', loc='center')
    
    
# # making histograms
# # setting up figure
# ncolumns = 2
# nrows = 3
# r = 0
# c = 0
# histfig, histaxes = plt.subplots(nrows, ncolumns,  figsize = (5,4), tight_layout = True)
# for i, desc in zip(naive_predictions, naive_titles):
#     errors  = y_train - i
#     histhelper(ax = histaxes, xloc = r, yloc= c, data = errors, title = desc)
    
#     # next portion ensures subsequent plots move from right to left, top to bottom
#     if c < ncolumns-1:
#         c += 1
#     elif ((c >= ncolumns-1) and (r < nrows - 1)):
#         c = 0
#         r += 1
#     else: break
# histfig.suptitle('Distribution of Prediction Errors for Naive Models', fontsize=16)
# histfig.savefig(f'{utils.fig_path}aefp_hist_errorsbyrace.png', dpi=300, bbox_inches='tight', format= 'png')
# ===============








# Training a balanced Random Foreest using 5-fold CV
# Generating predictions on left-out sets, all training obs get a turn as left out set.
# Returning predictions which are an approximation of test-set performance
balanced_rf_yhat = explore_classification.cv_balanced_rf()

# Generating confusion matrix plot
utils.report_and_plot_rf(model= 'Balanced Random Forest Classifier (350 trees)', 
                   true_y= y_train, 
                   predicted_y= balanced_rf_yhat, 
                   label_dict= labels.classes_, 
                   save_path= utils.fig_path, 
                   fig_name="aefp_rf_balancedRF")

# generating confusion matrix
CM_figure = ConfusionMatrixDisplay.from_predictions(y_train, balanced_rf_yhat, display_labels = labels.classes_, normalize = 'true')
CM_figure.plot()
CM_figure.ax_.set_title('Balanced Random Forest Classifier (350 trees)', loc='center')
CM_figure.figure_.savefig(f'{utils.fig_path + "aefp_rf_balancedRF.png"}', 
                              dpi= 300,  
                              format='png',
                              bbox_inches= 'tight')

# Making DF that contains training data and appends predictions, gold labels,
# and errors for RF and naive models
results = x_train.copy(deep = True)
results['ytrue'] = y_train
results['yhat'] = balanced_rf_yhat
# Plotting true vs predicted distribution, not exporting for now
results['yhat'].hist(bins=50)
results['ytrue'].hist(bins=50)
# generating errors and plotting
results['errors'] = results['ytrue'] - results['yhat']
results['errors'].hist(bins=17)
# adding naive stratified errors to results
results['naive_stratified_errors']  = results['ytrue'] - naive_stratified_yhat

# generating a sorted list of grades
grades = sorted(results['ytrue'].unique().tolist())



# Histogram of the errors for lettergrades less than or equal to specified grade
histfig, histaxes = plt.subplots(2, 3, sharex= False, tight_layout = True, sharey = 'all')
histhelper(ax = histaxes, xloc = 0, yloc= 0, data = results['errors'], title = 'Overall')
histhelper(ax = histaxes, xloc = 0, yloc= 1, data = results[results['ytrue']>= 1]['errors'], title = 'True grade <= B')
histhelper(ax = histaxes, xloc = 0, yloc= 2, data = results[results['ytrue']>= 2]['errors'], title = 'True grade <= C')
histhelper(ax = histaxes, xloc = 1, yloc= 0, data = results[results['ytrue']>= 3]['errors'], title = 'True grade <= D')
histhelper(ax = histaxes, xloc = 1, yloc= 1, data = results[results['ytrue']>= 4]['errors'], title = 'True grade = F')
histhelper(ax = histaxes, xloc = 1, yloc= 2, data = results['yhat'],xtype = 'grades', title = '')
histhelper(ax = histaxes, xloc = 1, yloc= 2, data = results['ytrue'],xtype = 'grades', title = 'Predicted (fill) vs True', histtype = 'step')
histaxes[0, 0].set_ylim(0, 0.60)
histfig.suptitle('Distribution of Prediction Errors for Grades below by True Grade', fontsize=16)
# likely not useful




# Histogram of Errors per letter grade
histfig, histaxes = plt.subplots(2, 3, sharex= False, sharey = True, tight_layout = True, figsize=(7, 4))
histhelper(ax = histaxes, xloc = 0, yloc= 0, data = results['errors'], title = 'Overall')
histhelper(ax = histaxes, xloc = 0, yloc= 1, data = results[results['ytrue']== 0]['errors'], title = 'True grade = A')
histhelper(ax = histaxes, xloc = 0, yloc= 2, data = results[results['ytrue']== 1]['errors'], title = 'True grade = B')
histhelper(ax = histaxes, xloc = 1, yloc= 0, data = results[results['ytrue']== 2]['errors'], title = 'True grade = C')
histhelper(ax = histaxes, xloc = 1, yloc= 1, data = results[results['ytrue']== 3]['errors'], title = 'True grade = D')
histhelper(ax = histaxes, xloc = 1, yloc= 2, data = results[results['ytrue']== 4]['errors'], title = 'True grade = F')
histfig.suptitle('Distribution of Prediction Errors by True Grade', fontsize=16)
histaxes[0, 0].set_ylim(0, 0.75) # setting all y axis range between 0 and 0.75
histfig.savefig(f'{utils.fig_path} aefp_hist_errorsbygrade.png', dpi=300, bbox_inches='tight', format= 'png')




# Histogram of Errors per institution
# loops over all institutions, plotting them in subplots 
# from left to right, top to bottom
nrows = 3
ncolumns = 5
r = 0
c = 0
histfig, histaxes = plt.subplots(nrows, ncolumns, sharex= False, tight_layout = False, figsize=(13, 8.5), sharey = 'all')
for inst in range(len(results['institution_id'])):
    histhelper(ax = histaxes, xloc = r, yloc= c, data = results[results['institution_id'] == inst+1]['errors'], title = f'Inst. {inst + 1}')
    # Advances row/column indexes, first moving to the right along the same row,
    # then starting over in first colum of next row.
    if c < ncolumns-1:
        c += 1
    elif ((c >= ncolumns-1) and (r < nrows - 1)):
        c = 0
        r += 1
    else: break
histaxes[0, 0].set_ylim(0, 0.75)
histfig.suptitle('Distribution of Prediction Errors by Institution', fontsize=40)
histfig.savefig(f'{utils.fig_path}aefp_hist_errorsbyinst.png', dpi=300, bbox_inches='tight', format= 'png')


###
# Histogram of prediction errors by race
race = [(1,'American Indian or Alaska Native'), 
        (2, 'Asian'), 
        (3, 'Black or African American'), 
        (4, 'Hispanic'), 
        (5, 'Native Hawaiian/Pacific Islander'), 
        (6, 'Non-resident Alien'), 
        (7, 'Two or More Races'), 
        (8, 'Unknown'), 
        (9, 'White')]

# begin plotting
nrows = 3
ncolumns = 3
r = 0
c = 0
histfig, histaxes = plt.subplots(nrows, ncolumns, sharex= False, tight_layout = False, figsize=(11, 7), sharey = 'all')
for i in range(len(race)):
    num, label = race[i] # unpacking tuple at position i
    histhelper(ax = histaxes, xloc = r, yloc= c, data = results[results['stdnt_race_encode'] == num]['errors'], title = label)
    # next portion ensures subsequent plots move from right to left, top to bottom
    if c < ncolumns-1:
        c += 1
    elif ((c >= ncolumns-1) and (r < nrows - 1)):
        c = 0
        r += 1
    else: break
histaxes[0, 0].set_ylim(0, 0.75)
histfig.suptitle('Distribution of Prediction Errors by Student Race', fontsize=40)
histfig.savefig(f'{utils.fig_path}aefp_hist_errorsbyrace.png', dpi=300, bbox_inches='tight', format= 'png')


###
# Histogram of prediction errors by sex
histfig, histaxes = plt.subplots(1, 2, sharex= True, tight_layout = False, figsize=(8, 4), sharey = 'all')
histaxes[0].hist(x = results[results['ismale'] == 1]['errors'], bins = [-4.5, -3.5, -2.5, -1.5, -0.5, 0.5, 1.5, 2.5, 3.5, 4.5], rwidth = 0.75, align = 'mid', histtype = 'bar', density = True)
histaxes[0].set_title('Male')
#histaxes[0].set_yticks([])
#histaxes[0].set_xticks([-4, -3, -2, -1, 0, 1, 2, 3, 4], ['-4', '-3', '-2', '-1', '0', '1', '2', '3', '4'])
#histaxes[0].set_xlim(-5, 5)
histaxes[1].hist(x = results[results['ismale'] == 0]['errors'], bins = [-4.5, -3.5, -2.5, -1.5, -0.5, 0.5, 1.5, 2.5, 3.5, 4.5], rwidth = 0.75, align = 'mid', histtype = 'bar', density = True)
histaxes[1].set_title('Female')
histaxes[1].set_xticks([-4, -3, -2, -1, 0, 1, 2, 3, 4], ['-4', '-3', '-2', '-1', '0', '1', '2', '3', '4'])
histaxes[1].set_xlim(-5, 5)
histaxes[0].set_ylim(0, 0.75)
histfig.suptitle('Distribution of Prediction Errors by Student Sex', fontsize=40)
histfig.savefig(f'{utils.fig_path}aefp_hist_errorsbysex.png', dpi=300, bbox_inches='tight', format= 'png')


###
# Head-to-Head, our preferred model vs a naive approach
###
naive_stratified_errors  = y_train - naive_stratified_yhat

fig, axes = plt.subplots(1,1, sharex= True, sharey = 'all', tight_layout = False, figsize= (5,5))
axes.hist(results['errors'], bins = [-4.5, -3.5, -2.5, -1.5, -0.5, 0.5, 1.5, 2.5, 3.5, 4.5], rwidth = 0.75, align = 'mid', histtype = 'bar', density = True)
axes.hist(naive_stratified_errors, bins = [-4.5, -3.5, -2.5, -1.5, -0.5, 0.5, 1.5, 2.5, 3.5, 4.5], align = 'mid', histtype = 'step', density = True)
axes.set_xlim(-5, 5)
axes.set_ylim(0, 0.75)
fig.suptitle('Error Distribution Our Model (fill) vs Naive Stratified Random', fontsize=16)
fig.savefig(f'{utils.fig_path}aefp_hist_errorsnaive_vs_ours_overall.png', dpi=300, bbox_inches='tight', format= 'png')



# Histogram of Errors per letter grade
histfig, histaxes = plt.subplots(2, 3, sharex= False, sharey = True, tight_layout = True, figsize=(6, 4.5)) 
# plotting our model
histhelper(ax = histaxes, xloc = 0, yloc= 0, data = results['errors'], title = 'Overall')
histhelper(ax = histaxes, xloc = 0, yloc= 1, data = results[results['ytrue']== 0]['errors'], title = 'True grade = A')
histhelper(ax = histaxes, xloc = 0, yloc= 2, data = results[results['ytrue']== 1]['errors'], title = 'True grade = B')
histhelper(ax = histaxes, xloc = 1, yloc= 0, data = results[results['ytrue']== 2]['errors'], title = 'True grade = C')
histhelper(ax = histaxes, xloc = 1, yloc= 1, data = results[results['ytrue']== 3]['errors'], title = 'True grade = D')
histhelper(ax = histaxes, xloc = 1, yloc= 2, data = results[results['ytrue']== 4]['errors'], title = 'True grade = F')
# plotting the naive model
histhelper(ax = histaxes, xloc = 0, yloc= 0, data = results['naive_stratified_errors'], title = 'Overall', histtype= 'step')
histhelper(ax = histaxes, xloc = 0, yloc= 1, data = results[results['ytrue']== 0]['naive_stratified_errors'], title = 'True grade = A', histtype= 'step')
histhelper(ax = histaxes, xloc = 0, yloc= 2, data = results[results['ytrue']== 1]['naive_stratified_errors'], title = 'True grade = B', histtype= 'step')
histhelper(ax = histaxes, xloc = 1, yloc= 0, data = results[results['ytrue']== 2]['naive_stratified_errors'], title = 'True grade = C', histtype= 'step')
histhelper(ax = histaxes, xloc = 1, yloc= 1, data = results[results['ytrue']== 3]['naive_stratified_errors'], title = 'True grade = D', histtype= 'step')
histhelper(ax = histaxes, xloc = 1, yloc= 2, data = results[results['ytrue']== 4]['naive_stratified_errors'], title = 'True grade = F', histtype= 'step')

histfig.suptitle('Error Distribution of our Model (fill) vs Naive Model (outline)', fontsize=16)
histaxes[0, 0].set_ylim(0, 0.75)
histfig.savefig(f'{utils.fig_path}aefp_hist_errorsnaive_vs_ours_bygrade.png', dpi=300, bbox_inches='tight', format= 'png')


# Generating Classification Reports
from sklearn.metrics import classification_report
# Naive models
for preds, model in zip(naive_predictions, naive_model_names):
    report = classification_report(y_true = y_train, y_pred = preds, target_names= labels.classes_, output_dict= True)
    print(f'Report for model: {model}')
    print(report)
    df = pd.DataFrame(report).to_csv(f'{utils.my_save_path}aefp_classification_report_{model}.csv')

# Our model
report = classification_report(y_true = y_train, y_pred = balanced_rf_yhat, target_names= labels.classes_, output_dict= True)
print(f'Report for model: {model}')
print(report)
df = pd.DataFrame(report).to_csv(f'{utils.my_save_path}aefp_classification_report_balanced_rf.csv')



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Feature importances and export
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
model = explore_classification.balanced_rf.fit(X= x_train, y = y_train)

importances = model.feature_importances_
features = model.feature_names_in_

# Making a DF of feature importances
featureimportances = []
for score, name in zip(model.feature_importances_, x_train):
    print(round(score,5),name)
    featureimportances.append((name, score))

featureimportances = pd.DataFrame(list(featureimportances))
#exporting
featureimportances.to_csv("/proj/ncefi/uncso/projects/nsf_stem/randomforest/aefp_balanced_rf_featureimportances.csv",)

