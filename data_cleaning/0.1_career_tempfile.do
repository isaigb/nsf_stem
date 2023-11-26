********************************************************************************
* 2 Cleaning career and creating a temp file to merge
********************************************************************************
use "${rawdata}/career/career_10_05_22.dta", clear

rename *, lower

gen isincareer = 1

drop if career == "Graduate"
drop if class_level == "Graduate"
drop if institution == "UNCSA"

* fixing snapshot_term
	gen termyear = substr(snapshot_term, -4, .)
	destring termyear, replace
	
	gen termtype = ""
		replace termtype = "Spring" 	if strpos(snapshot_term, "Spring")
		replace termtype = "Summer I" 	if strpos(snapshot_term, "Summer I")
		replace termtype = "Summer II" 	if strpos(snapshot_term, "Summer II")
		replace termtype = "Fall"	if strpos(snapshot_term, "Fall")
		
	tab termyear termtype, m
	tab snapshot_term termtype, m
	
	
	gen sortterm = .
		replace sortterm = 1 	if strpos(snapshot_term, "Spring")
		replace sortterm = 2 	if strpos(snapshot_term, "Summer I")
		replace sortterm = 3 	if strpos(snapshot_term, "Summer II")
		replace sortterm = 4	if strpos(snapshot_term, "Fall")

		
* Keeping only observations within our time period of Spring 2017 through Spring 2020
	tab termyear sortterm, m
	
	// observations after 2017 are ok
	gen keepcond1 = 0
		replace keepcond1 = 1 if termyear >= 2017 & termyear <= 2019
		
	// observations on and before spring 2020 are ok
	gen keepcond2 = 0
		replace keepcond2 = 1 if termyear == 2020 & termtype == "Spring"
	
	gen keep = 0
		replace keep = 1 if keepcond1 == 1 | keepcond2 == 1
	
	tab snapshot_term keep, m
	
	
	keep if keep == 1
	
	drop keep keepcond*
		
		
* Checking for duplicates
	duplicates tag newid institution termyear termtype, gen(duplicates)
	// browse if duplicates > 0
	bysort newid institution termyear termtype (cum_over_attempt_hours): keep if _n == _N 
	//keeps the last observation after grouping by newid, institution, termyear, termtype and sorting by cumulative attempted hours.
	duplicates report newid institution termyear termtype // no more duplicates
	drop duplicates
		
		
		
* Saving a file that flags our sample
	gen issample = 1
	preserve
	keep newid institution snapshot_term issample
	save "${proj}/data/rf_issample.dta", replace	
	restore	

* Keeping limited set of vars 

	keep institution snapshot_term newid stdnt_race_ipeds student_gender_ipeds student_age student_citizenship enrollment_status_code enrollment_status_code_ipeds orig_enroll_status_code class_level_code student_fte county_of_residence_code student_perm_county_code housing_indicator_code cum_xfer_attempt_hours military_affiliated_flag major_1_cip_code major_1_cip_stem_flag state_of_residence student_perm_state
	
	
* Fixing various vars
	
	//race
	tab stdnt_race_ipeds, m gen(race_)
		rename race_1 race_AIAN
		rename race_2 race_asian
		rename race_3 race_black
		rename race_4 race_latino
		rename race_5 race_nhawaii_paci_island
		rename race_6 race_nonresalien
		rename race_7 race_twoplus
		rename race_8 race_unknown
		rename race_9 race_white
		drop stdnt_race_ipeds
	//gender
	gen ismale = 0
		replace ismale = 1 if student_gender_ipeds == "M"
		tab ismale student_gender_ipeds, m
		drop student_gender_ipeds
		
	//student_citizenship
	tab student_citizenship, m
	replace student_citizenship = "Nonresident Alien" if student_citizenship == "Non-Resident Alien"
	encode student_citizenship, gen(citizenship_status)
	drop student_citizenship
	
	
	//state of residence
	tab state_of_residence, m 
		replace state_of_residence = "Foreign Country" if state_of_residence == "Foreign Countries"
		encode state_of_residence, gen(residence_state)
		gen residence_state_instate = 0
		replace residence_state_instate = 1 if state_of_residence == "North Carolina"
		drop state_of_residence
	tab student_perm_state, m
		encode student_perm_state, gen(perm_state)
		gen perm_state_instate = 0 
		replace perm_state_instate = 1 if student_perm_state == "North Carolina"
		drop student_perm_state
	
	// military_affiliated_flag
	tab military_affiliated_flag, m
		gen ismilitary = 0
		replace ismilitary = 1 if military_affiliated_flag == "Y"
		drop military_affiliated_flag
	
	
	// major 1
	tab1 major_1_cip_code major_1_cip_stem_flag, m
	
	gen is_stem_major = 0
		replace is_stem_major = 1 if major_1_cip_stem_flag == "Y"
	
	gen major_1_cip_gencode = substr(major_1_cip_code, 1, 2)
	
	drop major_1_cip_code major_1_cip_stem_flag
	
	// destringing
	foreach var in enrollment_status_code enrollment_status_code_ipeds orig_enroll_status_code class_level_code county_of_residence_code student_perm_county_code housing_indicator_code major_1_cip_gencode {
		destring `var', replace
	}
		
	* Saving
	save "${proj}/data/rf_career_formerge.dta", replace
