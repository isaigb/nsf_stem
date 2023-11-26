********************************************************************************
* 3 Cleaning Course level
********************************************************************************
/*
Conceptually I need:
	- Course level summaries explaining course information
	- semester level summaries explaining composition of course load, historical performance, etc.
*/

use "${rawdata}/enrollment/enrollment_04_11_22.dta", clear


rename *, lower

gen isinenrollment = 1


* Keeping only undergrad level courses
keep if course_level == "Lower division undergraduate" | course_level == "Upper division undergraduate"

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

* For now dropping observations prior to SDM
gen drop = 0
	replace drop = 1 if termyear < 2015 
	replace drop = 1 if termyear == 2015 & sortterm <= 3
	
	tab snapshot_term drop, m
drop if drop == 1

* Dropping 0 credit hour rows, changed my mind, might indicate an audit
//drop if credit_hours == 0

* Dropping incompletes and withdrawals
drop if grade_category == "INCOMPLETE" | grade_category == "WITHDRAW"


* Fixing quality_points and hours_attempted
mdesc quality_points hours_attempted credit_hours
	
* Creating GPA measure, setting GPA to missing if withdrawn or incomplete

	gen gpa_course = quality_points / credit_hours


	
* Creating a summary of total hrs attempt and hours earned per term.
	bysort newid institution snapshot_term: egen term_hrs_attempt_all = total(credit_hours)
	bysort newid institution snapshot_term: egen term_points_earn_all = total(quality_points)
	
* Creating a variable that captures course level/difficulty
	// using the egenmore sieve() command to strip away the string characters from course_number
	egen clean_course_number = sieve(course_number), keep(numeric)
	// generating empty string and replacing with the string from clean_course_number minus last 2 digits
	gen course_lev_num = ""
	replace course_lev_num = substr(clean_course_number, 1, length(clean_course_number) - 2)
	drop clean_course_number
	destring course_lev_num, replace
	label var course_lev_num "First 2 digits of course num, indicates course level/difficulty"


* Section taken from Wesley's Analytic_file_6_14_22
{
*Master grade variable
//gen gpa_course= quality_points / hours_attempted


* Coding STEM Coures

local NHS_STEM_CIP 14 26 27 40


gen STEM_course=0

foreach v in 14 26 27 40 {
	replace STEM_course=1 if course_cip_code=="`v'"
	}

***creates 2 digit cip code from 4 digit department code
gen dept_cip_2 = substr(course_department_cip_code, 1,2)
destring dept_cip_2, replace

***Creates indicator for Dept STEM
gen STEM_dept=0

foreach v in 14 26 27 40 {
	replace STEM_dept=1 if dept_cip_2==`v'
	}

foreach v in 0103	0109	0110	0111	0112	0181	0301	0302	0305	0306	0409	0907	1003	1101	1102	1103	1104	1105	1107	1108	1109	1110	1305	1306	1500	1501	1502	1503	1504	1505	1506	1507	1508	1509	1510	1511	1512	2805	2902	2903	2904	3001	3006	3008	3010	3017	3018	3019	3025	3027	3030	3031	3032	3033	3035	3038	3039	3041	3043	3044	3049	3050	3070	3071	4100	4101	4102	4103	4227	4228	4501	4503	4507	4901	5110	5114	5120	5127	5213 {
	replace STEM_dept=1 if course_department_cip_code=="`v'"
	}

foreach v in 14 26 27 40 {
	replace STEM_dept=1 if course_cip_code=="`v'"
	}

replace STEM_dept=1 if strpos(course_department, "Computer")
replace STEM_dept=1 if strpos(course_department, "Engineer")
replace STEM_dept=1 if strpos(course_department, "Aerospace")
replace STEM_dept=1 if strpos(course_department, "Animal Science")
replace STEM_dept=1 if strpos(course_department, "Applied Ecology")
replace STEM_dept=1 if strpos(course_department, "Clinical Laboratory")
replace STEM_dept=1 if strpos(course_department, "Crop")
replace STEM_dept=1 if strpos(course_department, "Soil")
replace STEM_dept=1 if strpos(course_department, "Environment")
replace STEM_dept=1 if strpos(course_department, "Forestry")
replace STEM_dept=1 if strpos(course_department, "Management Information")
replace STEM_dept=1 if strpos(course_department, "Military Science")
replace STEM_dept=1 if strpos(course_department, "Poultry")
replace STEM_dept=1 if strpos(course_department, "Technology Systems")
replace STEM_dept=1 if strpos(course_department, "Aviation")
replace STEM_dept=1 if strpos(course_department, "Naval")
replace STEM_dept=1 if strpos(course_department, "Natural Resource")
replace STEM_dept=1 if strpos(course_department, "Bioprocessing")
replace STEM_dept=1 if strpos(course_department, "Geolog")


/* Descriptives for analyzing if a department is STEM
br COURSE_DEPARTMENT COURSE_SUBJECT COURSE_DEPARTMENT_CIP_CODE COURSE_CIP_CODE STEM_course STEM_dept if STEM_dept==1 & STEM_course==0

br COURSE* STEM_dept if strpos(COURSE_DEPARTMENT, "Aviation")

tab COURSE_CIP_CODE if COURSE_DEPARTMENT=="Environment"

tab COURSE_CIP_CODE if strpos(COURSE_DEPARTMENT, "Environment")
*/

/// Encoding numeric variables

//encode INSTITUTION_CODE, gen(Institution_code)


/// Cleaning Grades

//rename GRADE grade
//rename GRADE_CATEGORY grade_category
/*
gen c_grade=grade
replace c_grade="F" if grade_category=="FAIL/UNSUCCESSFUL"
replace c_grade="AU" if grade_category=="AUDIT"
replace c_grade="W" if grade_category=="WITHDRAW"
replace c_grade="I" if grade_category=="INCOMPLETE"
replace c_grade="" if grade_category=="IN PROGRESS"
replace c_grade="" if grade_category=="ADMIN USE"
replace c_grade="B-" if grade=="RXB-"

local rx A B C D F S U I

foreach i of local rx {
	replace c_grade="`i'" if grade=="RX`i'"
	replace c_grade="`i'-" if grade=="RX`i'-"
	replace c_grade="`i'+" if grade=="RX`i'+"
	
	replace c_grade="F" if grade=="`i' IE"
	replace c_grade="F" if grade=="`i'-IE"
	replace c_grade="F" if grade=="`i'+IE"
	
	replace c_grade="`i'" if grade=="`i' XE"
	replace c_grade="`i'-" if grade=="`i'-XE"
	replace c_grade="`i'+" if grade=="`i'+XE"
	
	replace c_grade="P" if grade=="P `i'"
	replace c_grade="P" if grade=="P `i'-"
	replace c_grade="P" if grade=="P `i'+"
	
	replace c_grade="`i'" if grade=="I/`i'"
	replace c_grade="`i'-" if grade=="I/`i'-"
	replace c_grade="`i'+" if grade=="I/`i'+"
	}
	*/
* Fixing grades 
merge m:1 grade using "${proj}/data/recode_grades_WM.dta"
}
drop if _merge == 2

drop _merge // c_grade is not used


tab new_grade, m

mdesc gpa_course quality_points hours_attempted




//saving current file

save "${proj}/data/rf_courselevel_temp.dta", replace
