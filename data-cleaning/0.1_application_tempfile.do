********************************************************************************
* 1 Cleaning applications and creating a temp file to merge
********************************************************************************
use "${rawdata}/application/application_04_14_22.dta", clear

rename *, lower

gen isinapp = 1

keep if acceptance_status == "Accepted" | acceptance_status == "Admit"

keep if intended_career == "Undergraduate"
keep if primary_undup_app == "Y"

// Fixing gpa
	
*Cleaning HS admit GPA
	//Convert GPAs to 4.0 scale where on a different scale
	//Those missing a scale category look like 4.0 scale
	gen hs_gpa = admit_hs_gpa // if inlist(gpa_scale_a,"4.0","Migrated 4.0","Converted 4.0","")
	replace hs_gpa=admit_hs_gpa*(4/10) if gpa_scale_a=="10.0"
	replace hs_gpa=admit_hs_gpa*(4/100) if gpa_scale_a=="100"
	replace hs_gpa=admit_hs_gpa*(4/12) if gpa_scale_a=="12.0"
	replace hs_gpa=admit_hs_gpa*(4/5) if gpa_scale_a=="5.0"
	replace hs_gpa=admit_hs_gpa*(4/6) if gpa_scale_a=="6.0"
	replace hs_gpa=admit_hs_gpa*(4/7) if gpa_scale_a=="7.0"
	replace hs_gpa=admit_hs_gpa*(4/8) if gpa_scale_a=="8.0"
	replace hs_gpa=admit_hs_gpa*(4/100) if hs_gpa > 50 // fixing 3 random observations that made it through as scaled from 100.
	
	


* Cleaning HS grad date
gen hs_grad_date_v2 = dofc(hs_grad_date)
format hs_grad_date_v2 %td
gen hs_grad_year = year(hs_grad_date_v2)

replace hs_grad_year = . if hs_grad_year >= 2025
replace hs_grad_year = . if hs_grad_year <= 1950

*Creating sortable intended term, dropping those before fall 2015
	tab app_term_ipeds, m 
	gen apptermyear = substr(app_term_ipeds, -4, .)
	destring apptermyear, replace
	
	gen apptermtype = .
		replace apptermtype = 1 if strpos(app_term_ipeds, "Spring")
		replace apptermtype = 4 if strpos(app_term_ipeds, "Fall")
		label define apptermtype 1 "Spring" 2 "Summer 1" 3 "Summer 2" 4 "Fall"
		label values apptermtype apptermtype
		tab app_term_ipeds apptermtype, m


*keeping apps for inteded BA
keep if intended_degree_level == "Bachelor's"
	
	duplicates report newid institution //did people apply to the same institution multiple times? -- yes
	duplicates report newid institution app_term_ipeds //are there multiple apps to same inst in same year? -- Yes
	
	
*Keeping last application by newid institution and app_term_ipeds
	duplicates tag newid institution, gen(newidinstdupes)
	tab newidinstdupes, m 
	
	gen keep = 0
		replace keep = 1 if newidinstdupes == 0
		bysort newid institution (apptermyear apptermtype): replace keep = 1 if newidinstdupes >= 1 & _n == _N //groups observations by newid and institution. It then sorts within these groups using apptermyear and apptermtype. It will replace keep = 1 if the observations have duplicates and if the observation number (within each group) equals the total number of observations in the group. (i.e., if the observation is last of its group)
	tab newidinstdupes keep, m 
	
	keep if keep == 1
	drop keep newidinstdupes
	duplicates report newid institution

	
*Cleaning ACT and SAT scores

	merge m:1 act_super using "/proj/ncefi/uncso/projects/sesproxy/data_raw/act_sat_mapping.dta"
	gen mapped_sat=sat_super2_ipeds //creates a var that will combine test performance across SAT and ACT.
	replace mapped_sat = SAT if mapped_sat==. & act_super != . //if the student did not atek the SAT but did take the ACT, their ACT score will be mapped to equivalent SAT and stored.
	drop _merge SAT

* First Gen indicator
	gen p1nocoll = 0
		replace p1nocoll = 1 if parent1_highest_ed_code == "1" | parent1_highest_ed_code == "2" | parent1_highest_ed_code == "3"
	gen p2nocoll = 0
		replace p2nocoll = 1 if parent2_highest_ed_code == "1" | parent2_highest_ed_code == "2" | parent2_highest_ed_code == "3"
		
	tab parent1_highest_ed p1nocoll, m
	
	tab parent2_highest_ed p2nocoll, m
	
	
	gen isfirstgen = 0
		replace isfirstgen = 1 if p1nocoll == 1 & p2nocoll == 1


keep isinapp institution snapshot_term_code snapshot_term app_term_code_ipeds app_term_ipeds student_pidm newid stdnt_race_ipeds student_gender_ipeds student_citizenship primary_application_flag student_type admission_type acceptance_status enroll_date last_school_fice_code last_school_fice last_school_state last_school_attend_affiliation last_school_fice_category last_school_fice_high_deg highest_degree_level highest_deg_fice_high_deg highest_deg_fice_category highest_deg_fice_affiliation highest_degree_date highest_degree_fice_code highest_degree_fice highest_degree_gpa expected_xfer_credits post_sec_admit_gpa intended_career intended_degree_level intended_degree_1 intended_api_program_code_1 intended_api_program_1 intended_cip_1_stem_flag residency_appl student_perm_city student_perm_state student_perm_zipcode student_perm_county mar_status mar_gpa_status mar_test_status hs_gpa test_decision_indicator act_super act_composite act_english act_math act_reading act_science act_stem act_writing act_writing_hist sat_super2_ipeds sat_math_ipeds sat_read_ipeds sat_writing sat_writing_essay sat_writing_mc hs_grad_year hs_rank_pct parent1_highest_ed parent2_highest_ed mapped_sat isfirstgen


*Sorting and saving
sort newid institution
save "${proj}/data/rf_application_formerge.dta", replace
