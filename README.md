# NSF STEM
The goal of this project was to model undergraduate student performance as measured by grades in STEM courses. I approached this as both a classification and regression problem.

The project primarily on Stata for data cleaning and the Python libraries `scikit-learn` for the learning algorithms and `imbalanced-learn` to address class imbalance.

This repo is not updated live.

## TODO
 - Add test-set prediction and model selection

## Organization
The `/data_cleaning/` folder contains all of the `.do` files used to clean the training data. The entire procedure can be completed by running the `0.0_data_cleaning_control.do` file.

The `/src/` folder contains the Python code used to compare/contrast various learning algorithms for our problem. This procedure can be completed by running the `master.py` file.


## Setting up Python environment using Anaconda
To set up conda environment from the command line or VS Code terminal:
```
conda create -n nsfstem python=3.10.9 ipython statsmodels numpy matplotlib pandas jupyter scikit-learn imbalanced-learn
```
To activate the newly created environment:
```
conda activate nsfstem
```
You're now ready to begin using the code or run the script from the command line:
```
python master.py
```