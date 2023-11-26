********************************************************************************
* Exporting the required files for modeling in Python
********************************************************************************

* STEM only courses FULL letter grades (train and prediction files)
	use "${proj}/data/rf_analytic_temp.dta", clear
	drop quality_points
	tab new_grade, m
	
	rename new_grade rf_grade
	
	drop if STEM_course == 0
	preserve
	drop if termyear == 2020 & sortterm == 1 // dropping Spring 2020
	save "${proj}/data/rf_stemonly_fullgrades_training.dta", replace
	restore
	keep if termyear == 2020 & sortterm == 1 // keeping Spring 2020
	save "${proj}/data/rf_stemonly_fullgrades_covidpredict.dta", replace


	
	
	
* STEM only courses WHOLE letter grades (train and prediction files)
	use "${proj}/data/rf_analytic_temp.dta", clear
	drop quality_points
	tab new_grade, m
	gen rf_grade = ""
		replace rf_grade = "A" if new_grade == "A+" | new_grade == "A" | new_grade == "A-"
		replace rf_grade = "B" if new_grade == "B+" | new_grade == "B" | new_grade == "B-"
		replace rf_grade = "C" if new_grade == "C+" | new_grade == "C" | new_grade == "C-"
		replace rf_grade = "D" if new_grade == "D+" | new_grade == "D" | new_grade == "D-"
		replace rf_grade = "F" if new_grade == "F"
		tab new_grade rf_grade , m
	drop new_grade
	drop if STEM_course == 0
	preserve
	drop if termyear == 2020 & sortterm == 1 // dropping Spring 2020
	save "${proj}/data/rf_stemonly_wholegrades_training.dta", replace // exporting all semester types
	keep if sortterm == 1
	save "${proj}/data/rf_stemonly_wholegrades_training_springonly.dta", replace //saving spring semesters only
	restore
	keep if termyear == 2020 & sortterm == 1 // keeping Spring 2020
	save "${proj}/data/rf_stemonly_wholegrades_covidpredict.dta", replace
	
	
	
* STEM only courses QUALITY POINTS (train and prediction files)
	use "${proj}/data/rf_analytic_temp.dta", clear
	drop new_grade
	drop if STEM_course == 0
	preserve
	drop if termyear == 2020 & sortterm == 1 // dropping Spring 2020
	save "${proj}/data/rf_stemonly_qualitypoints_training.dta", replace
	restore
	keep if termyear == 2020 & sortterm == 1 // keeping Spring 2020
	save "${proj}/data/rf_stemonly_qualitypoints_covidpredict.dta", replace	
