********************************************************************************
* 4 Making term/semester summaries
********************************************************************************	
* Creating semester level cumulatives
/*
current semester hours attempted
current semester quality points
current semester GPA
by CIP: same as above

On 8/2/2023:
- creating a more granular breakdown of the above by using 6 digit CIP

bysort snapshot_term: mdesc *cip* shows a few terms are missing 100% of larger cip code course_department_cip_code



- To create a matrix of all courses and performance
	- begin by deduplicating on course_abbreviation
	- reshape to wide?
	- initialize to value of -9 for did not take course
	- replace value in course column with true GPA

*/

	// use "/proj/ncefi/uncso/projects/nsf_stem/data/rf_courselevel_temp.dta", clear
		
	
	
	// browse newid institution snapshot_term credit_hours quality_points term_* course_abbreviation section_title
	
	
/* 
PENDING TO DO: Create a crosswalk of all courses across institutions such that there is 1 column per unique subject (e.g., the calc1 column contains all calc1 courses regardless of course name or department)
	
// imputing long CIP code. Links using institution course_abbreviation course_cip_code
	frame copy default fix_course_department_cip_code // copying data into new frame
	frame change fix_course_department_cip_code // switching to that frame 
	keep institution snapshot_term course_abbreviation course_cip_code course_department course_department_cip_code // keeping only variables of interest
	drop if course_department_cip_code == "" // dropping blanks
	duplicates drop institution course_abbreviation course_cip_code course_department course_department_cip_code, force // keeping only unique values
	
	duplicates tag institution course_abbreviation course_cip_code course_department, gen(cipdupes)
	tab cipdupes, m
	sort course_abbreviation course_department 
	// browse if cipdupes > 0
	frame change default
	
	frlink m:1 institution course_abbreviation course_cip_code course_department, frame(fix_course_department_cip_code)
	
	frget updating_depcip = course_department_cip_code, from(fix_course_department_cip_code)
	
	replace course_department_cip_code = updating_depcip if course_department_cip_code == ""
	
	*/
	
/* 
IGB: 10/27/23: This code is not useful at the moment, will comment out. I may return to this later
	
* Creating granularity in CIP 40 and 27 since these emerged in top 10 feature importance
{
/*
Approach: 
Create new columns for each unique course within institution-CIP40/27 groups
	- Set to -9 if course not offered in student's institution
	- Set to -1 if course offered in student's insitutiont but not yet taken by student
	- Replace with GPA if course taken
	

*/ 


// Instead of creating new frames and linking, I decided to save a merge file
/*capture frame drop granular
	frame copy default granular // copying data into new frame
	frame change granular // switching to that frame */

use "${proj}/data/rf_courselevel_temp.dta", clear
	
	
	keep newid institution institution_id snapshot_term termyear sortterm course_cip_code course_subject_code course_number course_abbreviation *credit* gpa_course
	
	//keep if course_cip_code == "27" | course_cip_code == "40" // commented out since otherwise this leaves holes in data in semesters where students didnt' take a stem course.
	distinct course_abbreviation
	mdesc *credit*
	tab credit_hours, m
	
	drop if credit_hours == 0 | credit_hours == .
	distinct course_abbreviation
	
	//sorting
	sort institution_id newid termyear sortterm
	
	// creating string with no spaces that contains course abbreviation
	mdesc course_subject_code course_number course_abbreviation
	gen course_string = subinstr(course_abbreviation, " ", "", .)
	//browse if course_string == ""
	distinct course_string
	
	gen keep_string = 0
		replace keep_string = 1 if course_cip_code == "27" | course_cip_code == "40"
	
	replace course_string = "" if keep_string == 0
	
	distinct course_string
	
	// creating the new variables
	levelsof institution_id, clean local(levels_of_inst)
	
	foreach inst of local levels_of_inst {
		
		// getting unique courses within each school
		levelsof course_string if institution_id == `inst', clean local(courses_in_school)
		foreach course of local courses_in_school {
			gen `course'_`inst' = -9
			replace `course'_`inst' = -1 if institution_id == `inst'
			replace `course'_`inst' = gpa_course if institution_id == `inst' & course_string == "`course'" & gpa_course != .
			
			/*
			Need to carry forward GPA's from previous terms into future terms.
			To do this I group observations into newid then sort on the year,
			term, and course_string name. Then I replace the current-observation 
			GPA for	the newly generated variable with the previous-observation 
			GPA if previous is not missing and if current-observation is smaller 
			than previous-observation. This allows retakes to be represented such that
			only the highest GPA is carried forward. This procedure may introduce 
			a little noise for transfer students. Currently courses offered 
			in other schools will be listed as -9 for non-transfers but due 
			to this carry-forward procedure, transfer students will have values of -1
			in courses offered at their previous institutions. Similarly, these
			students will appear to the RF as having never taken key courses in the
			current institution while also having values other than -9 in their
			previous institutions.
			*/
			bysort newid (termyear sortterm course_string): replace `course'_`inst' = `course'_`inst'[_n-1] if `course'_`inst'[_n-1] != . & `course'_`inst' < `course'_`inst'[_n-1]
			
				// replacing each semester 
			//bysort newid institution snapshot_term: replace `course'_`inst' = max(`course'_`inst')
		}
	}
	
/* 
CHECKING MY WORK
	
* A non-transfer student
browse institution snapshot_term newid gpa_course course_string *_8 if newid == "957589858"
	
* A transfer student
browse institution snapshot_term newid gpa_course course_string *_1 *_15 if newid == "099628827"
	
//MATH233_8 in fall 2016 and MATH 383_8 IN Spring 2017
*/
	
	* In order to keep term-level summaries I must sort in the same way as the above replacement procedure, then keep the last observation per term. However this time I want observations grouped at the student-year-term level.
	
	bysort newid termyear sortterm (course_string): keep if _n == _N // keeps last observation within each group
	
	
	// dropping unnecessary variables
	drop institution_id credit_hours credit_hours_char credit_hours_enrolled course_subject_code course_number course_cip_code gpa_course course_string termyear sortterm course_abbreviation institution keep_string
	
	// newid and snapshot_term uniquely identify all rows
	duplicates report newid snapshot_term
	
	// mdesc // reports there are no missing
	
	
	
	// Reverting back to original frame and merging in this summary frame
	frame change default
	
	frlink m:1 newid snapshot_term, frame(granular) // linking current frame to granular frame
	
	frlink describe granular
	
	frget *, from(granular) // getting all variables from granular and bringing them into current frame.
	
	replace course_department_cip_code = updating_depcip if course_department_cip_code == ""


// end of granularity code	
}


// need to save here

*/
	
	
	
	
	
	
use "${proj}/data/rf_courselevel_temp.dta", clear	
	
	
	bysort newid institution snapshot_term course_cip_code: egen term_hrs_attempt_cip = total(credit_hours)
	
	bysort newid institution snapshot_term course_cip_code: egen term_points_earn_cip = total(quality_points)
	
	gen term_gpa_cip = term_points_earn_cip / term_hrs_attempt_cip
	
	
	
	
	
	duplicates drop newid institution snapshot_term course_cip_code, force
	
	// browse newid institution snapshot_term credit_hours quality_points course_abbreviation section_title course_cip_code term_*
	
	keep institution snapshot_term newid course_cip_code termyear termtype sortterm term_hrs_attempt_all term_points_earn_all term_hrs_attempt_cip term_points_earn_cip term_gpa_cip
	
	egen groupings = group(newid institution snapshot_term)
	
	drop if course_cip_code == ""
	
	
	reshape wide term_hrs_attempt_cip term_points_earn_cip term_gpa_cip, i(groupings) j(course_cip_code) string
	
	order institution snapshot_term newid termyear termtype sortterm term_hrs_attempt_all term_points_earn_all
	
	sort newid institution termyear sortterm
	// browse
	
	// egen group2 = group(newid)
	
	foreach var in term_hrs_attempt_all term_points_earn_all term_hrs_attempt_cip01 term_points_earn_cip01 term_hrs_attempt_cip03 term_points_earn_cip03 term_hrs_attempt_cip04 term_points_earn_cip04 term_hrs_attempt_cip05 term_points_earn_cip05 term_hrs_attempt_cip09 term_points_earn_cip09 term_hrs_attempt_cip10 term_points_earn_cip10 term_hrs_attempt_cip11 term_points_earn_cip11 term_hrs_attempt_cip13 term_points_earn_cip13 term_hrs_attempt_cip14 term_points_earn_cip14 term_hrs_attempt_cip15 term_points_earn_cip15 term_hrs_attempt_cip16 term_points_earn_cip16 term_hrs_attempt_cip19 term_points_earn_cip19 term_hrs_attempt_cip22 term_points_earn_cip22 term_hrs_attempt_cip23 term_points_earn_cip23 term_hrs_attempt_cip24 term_points_earn_cip24 term_hrs_attempt_cip25 term_points_earn_cip25 term_hrs_attempt_cip26 term_points_earn_cip26 term_hrs_attempt_cip27 term_points_earn_cip27 term_hrs_attempt_cip28 term_points_earn_cip28 term_hrs_attempt_cip29 term_points_earn_cip29 term_hrs_attempt_cip30 term_points_earn_cip30 term_hrs_attempt_cip31 term_points_earn_cip31 term_hrs_attempt_cip36 term_points_earn_cip36 term_hrs_attempt_cip37 term_points_earn_cip37 term_hrs_attempt_cip38 term_points_earn_cip38 term_hrs_attempt_cip40 term_points_earn_cip40 term_hrs_attempt_cip41 term_points_earn_cip41 term_hrs_attempt_cip42 term_points_earn_cip42 term_hrs_attempt_cip43 term_points_earn_cip43 term_hrs_attempt_cip44 term_points_earn_cip44 term_hrs_attempt_cip45 term_points_earn_cip45 term_hrs_attempt_cip49 term_points_earn_cip49 term_hrs_attempt_cip50 term_points_earn_cip50 term_hrs_attempt_cip51 term_points_earn_cip51 term_hrs_attempt_cip52 term_points_earn_cip52 term_hrs_attempt_cip54 term_points_earn_cip54 term_hrs_attempt_cip90 term_points_earn_cip90 {

		// Creates an iterative sum 
		bysort newid institution (termyear sortterm): gen cum_`var' = sum(`var')
		replace cum_`var' = 0 if cum_`var' == .
		
	}
	
	// creating cumulative GPA
	
	gen cum_gpa_all = cum_term_points_earn_all / cum_term_hrs_attempt_all 
	
	// browse cum*all
	
	foreach i in 01 03 04 05 09 10 11 13 14 15 16 19 22 23 24 25 26 27 28 29 30 31 36 37 38 40 41 42 43 44 45 49 50 51 52 54 90 {
		
		gen cum_gpa_cip`i' = cum_term_points_earn_cip`i' / cum_term_hrs_attempt_cip`i'
		
	}
	
	// browse newid snapshot_term cum*27
	// looks good
	
	drop groupings
	
	// Creating lag terms
	
	foreach var in term_hrs_attempt_all term_points_earn_all term_hrs_attempt_cip01 term_points_earn_cip01 term_gpa_cip01 term_hrs_attempt_cip03 term_points_earn_cip03 term_gpa_cip03 term_hrs_attempt_cip04 term_points_earn_cip04 term_gpa_cip04 term_hrs_attempt_cip05 term_points_earn_cip05 term_gpa_cip05 term_hrs_attempt_cip09 term_points_earn_cip09 term_gpa_cip09 term_hrs_attempt_cip10 term_points_earn_cip10 term_gpa_cip10 term_hrs_attempt_cip11 term_points_earn_cip11 term_gpa_cip11 term_hrs_attempt_cip13 term_points_earn_cip13 term_gpa_cip13 term_hrs_attempt_cip14 term_points_earn_cip14 term_gpa_cip14 term_hrs_attempt_cip15 term_points_earn_cip15 term_gpa_cip15 term_hrs_attempt_cip16 term_points_earn_cip16 term_gpa_cip16 term_hrs_attempt_cip19 term_points_earn_cip19 term_gpa_cip19 term_hrs_attempt_cip22 term_points_earn_cip22 term_gpa_cip22 term_hrs_attempt_cip23 term_points_earn_cip23 term_gpa_cip23 term_hrs_attempt_cip24 term_points_earn_cip24 term_gpa_cip24 term_hrs_attempt_cip25 term_points_earn_cip25 term_gpa_cip25 term_hrs_attempt_cip26 term_points_earn_cip26 term_gpa_cip26 term_hrs_attempt_cip27 term_points_earn_cip27 term_gpa_cip27 term_hrs_attempt_cip28 term_points_earn_cip28 term_gpa_cip28 term_hrs_attempt_cip29 term_points_earn_cip29 term_gpa_cip29 term_hrs_attempt_cip30 term_points_earn_cip30 term_gpa_cip30 term_hrs_attempt_cip31 term_points_earn_cip31 term_gpa_cip31 term_hrs_attempt_cip36 term_points_earn_cip36 term_gpa_cip36 term_hrs_attempt_cip37 term_points_earn_cip37 term_gpa_cip37 term_hrs_attempt_cip38 term_points_earn_cip38 term_gpa_cip38 term_hrs_attempt_cip40 term_points_earn_cip40 term_gpa_cip40 term_hrs_attempt_cip41 term_points_earn_cip41 term_gpa_cip41 term_hrs_attempt_cip42 term_points_earn_cip42 term_gpa_cip42 term_hrs_attempt_cip43 term_points_earn_cip43 term_gpa_cip43 term_hrs_attempt_cip44 term_points_earn_cip44 term_gpa_cip44 term_hrs_attempt_cip45 term_points_earn_cip45 term_gpa_cip45 term_hrs_attempt_cip49 term_points_earn_cip49 term_gpa_cip49 term_hrs_attempt_cip50 term_points_earn_cip50 term_gpa_cip50 term_hrs_attempt_cip51 term_points_earn_cip51 term_gpa_cip51 term_hrs_attempt_cip52 term_points_earn_cip52 term_gpa_cip52 term_hrs_attempt_cip54 term_points_earn_cip54 term_gpa_cip54 term_hrs_attempt_cip90 term_points_earn_cip90 term_gpa_cip90 cum_term_hrs_attempt_all cum_term_points_earn_all cum_term_hrs_attempt_cip01 cum_term_points_earn_cip01 cum_term_hrs_attempt_cip03 cum_term_points_earn_cip03 cum_term_hrs_attempt_cip04 cum_term_points_earn_cip04 cum_term_hrs_attempt_cip05 cum_term_points_earn_cip05 cum_term_hrs_attempt_cip09 cum_term_points_earn_cip09 cum_term_hrs_attempt_cip10 cum_term_points_earn_cip10 cum_term_hrs_attempt_cip11 cum_term_points_earn_cip11 cum_term_hrs_attempt_cip13 cum_term_points_earn_cip13 cum_term_hrs_attempt_cip14 cum_term_points_earn_cip14 cum_term_hrs_attempt_cip15 cum_term_points_earn_cip15 cum_term_hrs_attempt_cip16 cum_term_points_earn_cip16 cum_term_hrs_attempt_cip19 cum_term_points_earn_cip19 cum_term_hrs_attempt_cip22 cum_term_points_earn_cip22 cum_term_hrs_attempt_cip23 cum_term_points_earn_cip23 cum_term_hrs_attempt_cip24 cum_term_points_earn_cip24 cum_term_hrs_attempt_cip25 cum_term_points_earn_cip25 cum_term_hrs_attempt_cip26 cum_term_points_earn_cip26 cum_term_hrs_attempt_cip27 cum_term_points_earn_cip27 cum_term_hrs_attempt_cip28 cum_term_points_earn_cip28 cum_term_hrs_attempt_cip29 cum_term_points_earn_cip29 cum_term_hrs_attempt_cip30 cum_term_points_earn_cip30 cum_term_hrs_attempt_cip31 cum_term_points_earn_cip31 cum_term_hrs_attempt_cip36 cum_term_points_earn_cip36 cum_term_hrs_attempt_cip37 cum_term_points_earn_cip37 cum_term_hrs_attempt_cip38 cum_term_points_earn_cip38 cum_term_hrs_attempt_cip40 cum_term_points_earn_cip40 cum_term_hrs_attempt_cip41 cum_term_points_earn_cip41 cum_term_hrs_attempt_cip42 cum_term_points_earn_cip42 cum_term_hrs_attempt_cip43 cum_term_points_earn_cip43 cum_term_hrs_attempt_cip44 cum_term_points_earn_cip44 cum_term_hrs_attempt_cip45 cum_term_points_earn_cip45 cum_term_hrs_attempt_cip49 cum_term_points_earn_cip49 cum_term_hrs_attempt_cip50 cum_term_points_earn_cip50 cum_term_hrs_attempt_cip51 cum_term_points_earn_cip51 cum_term_hrs_attempt_cip52 cum_term_points_earn_cip52 cum_term_hrs_attempt_cip54 cum_term_points_earn_cip54 cum_term_hrs_attempt_cip90 cum_term_points_earn_cip90 cum_gpa_all cum_gpa_cip01 cum_gpa_cip03 cum_gpa_cip04 cum_gpa_cip05 cum_gpa_cip09 cum_gpa_cip10 cum_gpa_cip11 cum_gpa_cip13 cum_gpa_cip14 cum_gpa_cip15 cum_gpa_cip16 cum_gpa_cip19 cum_gpa_cip22 cum_gpa_cip23 cum_gpa_cip24 cum_gpa_cip25 cum_gpa_cip26 cum_gpa_cip27 cum_gpa_cip28 cum_gpa_cip29 cum_gpa_cip30 cum_gpa_cip31 cum_gpa_cip36 cum_gpa_cip37 cum_gpa_cip38 cum_gpa_cip40 cum_gpa_cip41 cum_gpa_cip42 cum_gpa_cip43 cum_gpa_cip44 cum_gpa_cip45 cum_gpa_cip49 cum_gpa_cip50 cum_gpa_cip51 cum_gpa_cip52 cum_gpa_cip54 cum_gpa_cip90 {
		
		replace `var' = 0 if `var' == .
		
		bysort newid institution (termyear sortterm): gen lag_`var' = `var'[_n-1]
		replace lag_`var' = 0 if lag_`var' == .
		
	}
	
	// browse newid institution snapshot_term *_all *27
	
	
	
// TO DO IF NEEDED: calculate STEM and Non-stem specific GPA with same rules
	

	
	* Saving
	save "${proj}/data/rf_term_summaries_formerge.dta", replace
