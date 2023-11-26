********************************************************************************
* 5 Making student level course summaries
********************************************************************************
use "${proj}/data/rf_courselevel_temp.dta", clear


keep institution newid snapshot_term credit_hours credit_hours_char hours_attempted credit_hours_enrolled quality_points termyear termtype sortterm gpa_course term_hrs_attempt_all term_points_earn_all

gen obs = 1

drop if credit_hours == 0 | credit_hours == .

// num of courses taken per semester
egen sem_course_count = sum(obs) , by(newid institution termyear sortterm)
// sum of gpa's in semester
egen sem_sum_gpa = sum(gpa_course), by(newid institution termyear sortterm)

// avg gpa based on number of courses taken
gen sem_mean_gpa = sem_sum_gpa / sem_course_count

// de-meaned course GPA then squared
gen demeaned_gpa = (gpa_course - sem_mean_gpa) ^ 2

// sum of squared deviations
egen sum_squared_dev = sum(demeaned_gpa) , by(newid institution termyear sortterm) 




egen sem_gpa_mean = mean(gpa_course), by(newid institution termyear sortterm)
egen sem_gpa_sd = sd(gpa_course), by(newid institution termyear sortterm)




bysort newid institution termyear sortterm: gen terms = _n

sort newid institution termyear sortterm

egen term_completion_order = group(newid institution termyear sortterm)

bysort newid institution termyear sortterm)












// dropping duplicates

duplicates report newid institution termyear sortterm
duplicates drop newid institution termyear sortterm, force

drop credit_hours credit_hours_char hours_attempted credit_hours_enrolled quality_points gpa_course term_hrs_attempt_all term_points_earn_all
sort newid institution termyear sortterm

bysort newid institution (termyear sortterm): gen cum_courses_num = sum(sem_course_count)
bysort newid institution (termyear sortterm): gen cum_sum_gpa = sum(sem_sum_gpa)
gen cum_mean_gpa = cum_sum_gpa / cum_courses_num

gen cum_gpa_sd = sqrt(((cum_sum_gpa - cum_mean_gpa) ^ 2) / cum_courses_num)

* incorrect, need to subtract mean gpa from all individual courses then square and sum

// bysort loops over the sorted obs
* Lagged (-1) deviation from cumulative GPA (-2)
* Lagged cumulative standard deviation
