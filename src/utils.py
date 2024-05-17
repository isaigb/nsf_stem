"""
This file defines constants and helper functions for data importing, figure 
generation, and letter grade to point conversion. These are utilized throughout
the project.
"""

from sklearn.model_selection import train_test_split
from sklearn.metrics import confusion_matrix, balanced_accuracy_score
from sklearn.metrics import ConfusionMatrixDisplay, classification_report
from sklearn.preprocessing import LabelEncoder
import pandas as pd
import time


# Defining the project file paths
my_save_path = "/proj/ncefi/uncso/projects/nsf_stem/DEV_nsf_stem/"
fig_path = "/proj/ncefi/uncso/projects/nsf_stem/DEV_nsf_stem/figures/"

# Defining the seed for use in randomizers for this project
SEED = 1234


def report_and_plot_rf(model, true_y, predicted_y, label_dict, save_path, fig_name, file_time_stamp = False, dpi = 600):
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
    # TODO clean this up
    CM_figure = ConfusionMatrixDisplay.from_predictions(y_true = true_y, y_pred = predicted_y, display_labels = label_dict, normalize = 'true')
    CM_figure.plot()
    #adding the full command as title
    CM_figure.ax_.set_title(f'{model}', loc='center')
    # Checking for inclusion of timestamp
    current_time = ""
    if file_time_stamp == True: 
        current_time = time.strftime("%Y%m%d-%H%M%S")
    # saving
    CM_figure.figure_.savefig(f'{save_path + fig_name + "_" + current_time + ".png"}', 
                                  dpi= dpi,  
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



# helper function converting from points to GPA
# currently not working
# TODO
def point2gpa(points, x_data):
    gpa = points/x_data['credit_hours']
    return gpa


# helper function converting from points to grades, modeled after https://registrar.unc.edu/academic-services/grades/explanation-of-grading-system/
def gpa2letter(gpa, grading = 'whole_letter', boundary_type = 'prediction'):
    """
    Helper function converting predicted 'quality points' to grades.
    
    Modeled after the UNC grading system ( https://registrar.unc.edu/academic-services/grades/explanation-of-grading-system/).
    Takes the midpoint between the letter grade GPA boundaries for conversion.
    """
    # setting up bins and labels
    if ((grading == 'full_letter') and (boundary_type  == 'prediction')):
        bins = [-100, 0.5-1e-5, 1.15-1e-5, 1.5-1e-5, 1.85-1e-5, 2.15-1e-5, 2.5-1e-5, 2.85-1e-5, 3.15-1e-5, 3.5-1e-5, 3.85-1e-5, 4.15-1e-5, 100]
        labels = ['F', 'D', 'D+', 'C-', 'C', 'C+', 'B-', 'B', 'B+', 'A-', 'A', 'A+']
        
    elif ((grading == 'full_letter') and (boundary_type  == 'true')):
        bins = [-100, 0.0+1e-5, 1.0+1e-5, 1.3+1e-5, 1.7+1e-5, 2.0+1e-5, 2.3+1e-5, 2.7+1e-5, 3.0+1e-5, 3.3+1e-5, 3.7+1e-5, 4.0+1e-5, 100]
        labels = ['F', 'D', 'D+', 'C-', 'C', 'C+', 'B-', 'B', 'B+', 'A-', 'A', 'A+']
        
    elif ((grading == 'whole_letter') and (boundary_type  == 'prediction')):
        bins = [-100, 0.5-1e-5, 1.5-1e-5, 2.5-1e-5, 3.5-1e-5, 100]
        labels = ['F', 'D', 'C', 'B','A']
    
    elif ((grading == 'whole_letter') and (boundary_type  == 'true')):
        bins = [-100, 0.0+1e-5, 1.3+1e-5, 2.3+1e-5, 3.3+1e-5, 100]
        labels = ['F', 'D', 'C', 'B', 'A']
    
    # Converting
    letters = pd.cut(gpa, bins = bins, labels = labels, include_lowest= True)
    
    # Returning letters
    return letters



# TODO make this more general, able to calculate errors for letters AND GPA's.
# working with regression errors
def append_gpa_letters_errors(x_data, y_true, y_hat, grading = 'whole_letter'):
    outframe = x_data.copy(deep = True)
    # calculates gpa from predictions
    gpa_yhat = point2gpa(points= y_hat, x_data= x_data)
    # calculates gpa from true  points
    gpa_ytrue = point2gpa(points= y_true, x_data = x_data)
    
    errors = gpa_yhat - gpa_ytrue
    
    grade_yhat = gpa2letter(gpa= gpa_yhat, grading= grading, boundary_type= 'prediction')
    grade_ytrue =  gpa2letter(gpa= gpa_ytrue, grading= grading, boundary_type= 'true')
    
    labels = LabelEncoder().fit(grade_ytrue)
    print(f'Classes in Y are: {labels.classes_}')
    grade_ytrue = labels.transform(grade_ytrue)
    grade_yhat = labels.transform(grade_yhat)
    
    outframe['gpa_ytrue'] = gpa_ytrue
    outframe['gpa_yhat'] = gpa_yhat
    outframe['grade_ytrue'] = grade_ytrue
    outframe['grade_yhat'] = grade_yhat
    outframe['gpa_errors'] = errors
    
    return outframe, labels



# helper function for making and placing histograms in a matplotlib sublot. Works with letter grade predictions or errors.
def histhelper(ax, xloc, yloc, data, xtype = 'errors', title= '', histtype = 'bar', density = True):
    """
    Helper function that constructs a single histogram and places it at subplot position xloc, yloc.
    
    It is set to plot errors by default but can plot letter grades.

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


# A helper function for moving to the next subplot position, will require a pre-initialized variable that stores
# the current position. Raises an exception if out of bounds.
def next_subplot_position(current_row_pos, current_column_pos, max_rows, max_columns):
    # checks that current column position can be incremented by 1 without going out of bounds, then increments by 1
    if current_column_pos < max_columns-1:
        current_column_pos += 1
    # Checks that the column position is at max position or out of bounds,
    # also checks that row position can be incremented by 1 without going out of bounds,
    # then sets column position to 0 (left most position) and increments row position by 1.
    elif ((current_column_pos >= max_columns-1) and (current_row_pos < max_rows - 1)):
        current_column_pos = 0
        current_row_pos += 1
    # Raises an exception if next position will exceed both rows and columns.
    else:
        raise Exception("Next position is out of bounds. Consider making a subplots object with more rows or columns.")
    # returns an updated row and column position
    return current_row_pos, current_column_pos