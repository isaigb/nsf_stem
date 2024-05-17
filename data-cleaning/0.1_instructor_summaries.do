********************************************************************************
* 6 Making instructor-course-term level course summaries
* Input: Instructor
* start with student-course level data, end with student-term data
/*
Makes lagged instructor-term-course summaries
*/
********************************************************************************


/*
duplicates report crn_id institution snapshot_term

crn_id is unique code for course

primary_instr_flag grading_auth_flag are flags for instructor who is primary vs who does grading
*/

use "${rawdata}/instructorsection/instructorsection_05_23_22.dta", clear

rename *, lower

* Pulling code from Wesley's online-ed to deduplicate

duplicates tag instructor_pidm, gen(courses_taught)

gsort snapshot_term_code institution_id crn_id -primary_instr_flag -pct_responsible -grading_auth_flag -courses_taught

destring snapshot_term_code, replace

collapse (firstnm) instructor_pidm snapshot_term institution, by(snapshot_term_code institution_id crn_id course_abbreviation section_number)

/*
Now have a deduplicated instructor-term-course file to link to individual students' files. Saving as a frame in memory.
*/

frame copy default instructor


* Working with student-term-course level data
use "${proj}/data/rf_courselevel_temp.dta", clear

destring snapshot_term_code, replace

frlink m:1 snapshot_term_code institution_id crn_id course_abbreviation section_number, frame(instructor)

frget instructor_pidm, from(instructor)
frame drop instructor

* Generating means and SD of GPA instructor-course level

egen course_gpa_avg = mean(gpa_course), by(snapshot_term_code institution_id instructor_pidm course_abbreviation)
egen course_gpa_sd = sd(gpa_course), by(snapshot_term_code institution_id instructor_pidm course_abbreviation)

* Generating a lagged course average for all sections and instructors
egen course_gpa_avg_all = mean(gpa_course), by(snapshot_term_code institution_id course_abbreviation)
egen course_gpa_sd_all  = sd(gpa_course), by(snapshot_term_code institution_id course_abbreviation)

/*
TODO
finish checking this section, where do we drop/summarize at? do I need section? likely not
*/
* Collapsing so there is 1 row per instructor-course-term
keep termyear sortterm snapshot_term_code institution_id crn_id course_abbreviation section_number instructor_pidm course_gpa_avg course_gpa_sd course_size course_gpa_avg_all course_gpa_sd_all

//temp  delete later
//frame copy default temp

// think I need crn_id and section_number here in order to merge to the larger file?
duplicates drop instructor_pidm institution_id course_abbreviation termyear sortterm crn_id section_number, force

sort institution_id instructor_pidm course_abbreviation  termyear sortterm crn_id section_number

* Generating lag vars using same ID's as above but adding instructor

rename course_size inst_course_size
// replaces a lagged instructor-course gpa average with a lagged gpa average of all students in that course last term
foreach var in course_gpa_avg course_gpa_sd inst_course_size {
	bysort institution_id instructor_pidm course_abbreviation (termyear sortterm): gen lag_`var' = `var'[_n-1]
	
	if "`var'" != "inst_course_size" {
		bysort institution_id instructor_pidm course_abbreviation (termyear sortterm): replace lag_`var' = `var'_all[_n-1] if lag_`var' == .
	}
	
}

* Dropping unnecessary vars 
	drop instructor_pidm

* Saving
	save "${proj}/data/instructor_only_temp.dta", replace
