********************************************************************************
*----------------------------------- HEADER -----------------------------------*
*Author: Isai Garcia-Baza
*Email: isaigb@live.unc.edu
/*
Purpose: This file will preprocess data for training a Random Forest model to 
predict course letter grades.
*/
********************************************************************************

* 0 Set Stata version *

	clear all
	version 17.0
	capture log close
	set more off
	
	set seed 1234

********************************************************************************
* Setting file path
global proj "/proj/ncefi/uncso/projects/nsf_stem"

global rawdata "/proj/ncefi/uncso/rawdata-stata/new_uncso_data"
********************************************************************************


* 1 Cleaning applications and creating a temp file to merge

	do "${proj}/randomforest/0.1_application_tempfile.do"

	
* 2 Cleaning career and creating a temp file to merge

	do "${proj}/randomforest/0.1_career_tempfile.do"


* 3 Cleaning Course level

	do "${proj}/randomforest/0.1_course_level_enrollment_tempfile.do"

* 4 Term/Semester summaries
	
	do "${proj}/randomforest/0.1_term_summaries.do"

* 5 Student Level Course Summaries
	
	do "${proj}/randomforest/0.1_student_level_course_summaries.do"

* 6 Instructor summaries
	
	do "${proj}/randomforest/0.1_instructor_summaries.do"

* Creating an analytic file

	do "${proj}/randomforest/0.2_analytic_tempfile.do"

* Making files for modeling

	do "${proj}/randomforest/0.3_make_modeling_data.do"
