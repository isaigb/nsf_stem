********************************************************************************
* Making a temporary analytic file, keeping only our in-sample observations
********************************************************************************

use "${proj}/data/rf_courselevel_temp.dta", clear

* Adding an indicator for our sample
merge m:1 newid institution snapshot_term using "${proj}/data/rf_issample.dta", keepusing(issample)

* Keeping only the matched data 
keep if _merge == 3
drop _merge

******
** Merging in additional data 
******

* Merging in term summaries
	merge m:1 newid institution snapshot_term using "${proj}/data/rf_term_summaries_formerge.dta", keepusing(lag* term_hrs_attempt* cum_term_hrs_attempt*)
	drop if _merge == 2
	drop _merge
	
	// Adding a variable that lists current course CIP lag items
	gen samecip_hrs_attempt = .
	gen samecip_cum_hrs_attempt = .
	
	gen samecip_lag_hrs_attempt = .
	gen samecip_lag_cum_hrs_attempt = .
	
	gen samecip_lag_points = .
	gen samecip_lag_cum_points = .
	
	
	levelsof course_cip_code, local(cipnum) clean
	
	di "`cipnum'"
	
	foreach i of local cipnum {
		di " cipunum = `i'"

		replace samecip_hrs_attempt = term_hrs_attempt_cip`i' if course_cip_code == "`i'"
		
		replace samecip_cum_hrs_attempt = cum_term_hrs_attempt_cip`i' if course_cip_code == "`i'"
		
		replace samecip_lag_hrs_attempt = lag_term_hrs_attempt_cip`i' if course_cip_code == "`i'"
		
		replace samecip_lag_cum_hrs_attempt = lag_cum_term_hrs_attempt_cip`i' if course_cip_code == "`i'"
		
		replace samecip_lag_points = lag_term_points_earn_cip`i' if course_cip_code == "`i'"
	
		replace samecip_lag_cum_points = lag_cum_term_points_earn_cip`i' if course_cip_code == "`i'"
		}
		
	gen quality_points_attempted = credit_hours * 4
	

* Merging in career data
	merge m:1 newid institution snapshot_term using "${proj}/data/rf_career_formerge.dta"
	drop if _merge == 2
	drop _merge


* Merging in application data 
	merge m:1 newid institution using "${proj}/data/rf_application_formerge.dta"

	drop if _merge == 2 // dropping unmatched applications 
	drop _merge
{ //TODO: move to application processing section
* fixing app_term_ipeds
	gen appyear = substr(app_term_ipeds, -4, .)
	destring appyear, replace
	
	gen appterm = .
		replace appterm = 1	if strpos(app_term_ipeds, "Spring")
		replace appterm = 2 	if strpos(app_term_ipeds, "Summer I")
		replace appterm = 3 	if strpos(app_term_ipeds, "Summer II")
		replace appterm = 4	if strpos(app_term_ipeds, "Fall")
		
	tab appyear appterm, m
	tab app_term_ipeds appterm, m
	



* Fixing some vars
gen intended_stem_major = 0
	replace intended_stem_major = 1 if intended_cip_1_stem_flag == "Y"
	tab intended_cip_1_stem_flag intended_stem_major, m
	drop intended_cip_1_stem_flag
}



* Creating a sorting variable for use in python
sort termyear sortterm institution_id newid course_subject_code course_number
gen sorting = _n 
order sorting newid


* Adding in student-term-gpa mean/sd summaries
	merge m:1 newid termyear sortterm institution using"${proj}/data/rf_student-term_gpa_mean_sd_formerge.dta"
	drop if _merge == 2
	drop _merge

* Adding in instructor-term-course summaries
	merge m:1 institution_id course_abbreviation termyear sortterm crn_id section_number using "${proj}/data/instructor_only_temp.dta" , force
	drop if _merge == 2
	drop _merge


* Dropping unnecessary variables
drop institution institution_code snapshot_term snapshot_term_code student_pidm student_cid nc_uid student_date_of_birth credit_hours_char hours_attempted credit_hours_enrolled hours_earned grade grade_category grade_category_code grading_basis_code grading_basis quality_points_char course_abbreviation section_title course_level course_cip  delivery_method site_of_instruction_code section_gradable_flag placeholder_indicator placeholder_indicator_code crn_id course_college course_department course_department_cip resident_extension_indicator study_abroad_indicator registration_status registration_status_desc general_ed_flag fundable_flag enrollment_funding_model enrollment_funding_model_code fund_type_section_oos_nf isinenrollment gpa_course new_earned_GPA termtype issample app_term_code_ipeds app_term_ipeds primary_application_flag acceptance_status enroll_date last_school_fice last_school_state last_school_fice_category highest_deg_fice_category highest_deg_fice_affiliation highest_degree_date highest_degree_fice intended_career intended_degree_level intended_degree_1 intended_api_program_1 student_perm_city student_perm_zipcode isinapp term_points_earn_all stdnt_race_ipeds student_gender_ipeds student_citizenship student_perm_state course_number section_number course_subject_code county_of_residence_code student_perm_county_code




// distinct course_subject_code course_number course_abbreviation course_cip course_cip_code

* Destringing
destring study_abroad_indicator_code course_level_code course_cip_code delivery_method_code study_abroad_indicator_code intended_api_program_code_1 course_department_cip_code highest_degree_fice_code, replace



* Fixing new_grade
	tab new_grade, m
	replace new_grade = "" if new_grade == "Audit" | new_grade == "No Credit"
	drop if new_grade == "" | new_grade == "H" | new_grade == "I" | new_grade == "P" | new_grade == "S" | new_grade == "U" | new_grade == "W" 
	tab new_grade, m


	
* Encoding variables (for now I'm not dummy coding since that induces sparsity. if model is not performing well then I will try dummy coding to see if it helps.)

// TODO: if necessary will instead turn these into a series of dummy vars which include a dummy for missing. This might be ideal if my end of distribution approach is not working for these.

foreach var in delivery_type site_of_instruction course_college_code course_department_code resident_extension_ind_cd student_type admission_type last_school_fice_code last_school_attend_affiliation last_school_fice_high_deg highest_degree_level highest_deg_fice_high_deg residency_appl student_perm_county mar_status mar_gpa_status mar_test_status test_decision_indicator parent1_highest_ed parent2_highest_ed {
	rename `var' o_`var'
	encode o_`var', gen(`var')
	drop o_`var'
	di "finished `var'"
}

* Setting missing values to -11
	mdesc 
	gen contained_missing = 0
	foreach var in `r(miss_vars)' {
		replace contained_missing = 1 if `var' == .
		replace `var' = -11 if `var' == .
	}


save "${proj}/data/rf_analytic_temp.dta", replace
