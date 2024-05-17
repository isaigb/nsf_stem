********************************************************************************
* 5 Making student level course summaries (this title likley inaccurate now)
* start with student-course level data, end with student-term data
/*
Makes student-semester cumulative means and standard deviations
*/
********************************************************************************
use "${proj}/data/rf_courselevel_temp.dta", clear


keep institution newid snapshot_term credit_hours credit_hours_char hours_attempted credit_hours_enrolled quality_points termyear termtype sortterm gpa_course term_hrs_attempt_all term_points_earn_all

gen obs = 1

drop if credit_hours == 0 | credit_hours == .



/*
Creating a GPA standard deviation variable that is cumulative up to the current 
term
*/

* Variable that counts terms
	sort newid termyear sortterm institution

	bysort newid termyear sortterm institution : gen terms = _n == 1 
	by newid: replace terms = sum(terms)

* Max terms
	egen max_terms = max(terms) , by(newid)

* GPA mean and SD per term 
	egen sem_gpa_mean = mean(gpa_course), by(newid institution termyear sortterm)
	egen sem_gpa_sd = sd(gpa_course), by(newid institution termyear sortterm)


	
	
* Doing this over a loop
	gen cum_gpa_mean = .
	gen cum_gpa_sd = .
	
	quietly sum terms
	local max = r(max)
	
	forvalues i = 1/ `max' { 
		tempvar store_mean store_sd
		

		di "Starting `i'"
		egen `store_mean' = mean(gpa_course) if terms <= `i' & `i' <= max_terms, by(newid institution)
		
		replace cum_gpa_mean = `store_mean' if terms == `i'
		
		
		
		egen `store_sd' = sd(gpa_course) if terms <= `i' & `i' <= max_terms, by(newid institution)
		
		replace cum_gpa_sd = `store_sd' if terms == `i'
	}
* dropping vars that must be dropped, not available in typical dataset
	drop max_terms
* Deduplicating data to keep single row per student-term-inst
	//duplicates report newid institution termyear sortterm
	duplicates drop newid institution termyear sortterm, force

* Generating lag vars
	sort newid institution termyear sortterm
	foreach var in cum_gpa_mean cum_gpa_sd {
		bysort newid institution (termyear sortterm): gen lag_`var' = `var'[_n-1]
	}

* Keeping vars (might not need this if I move this code over to the larger student-course to student-term summaries file)
	keep newid termyear sortterm institution terms lag_cum_gpa_mean lag_cum_gpa_sd
* Saving
	save "${proj}/data/rf_student-term_gpa_mean_sd_formerge.dta", replace
