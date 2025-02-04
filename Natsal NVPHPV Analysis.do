* Last updated: 3 Feb 2025; Author: Emily Dema
* Filename: Natsal NVPHPV Analysis.do
* File objective: To share code on deriving variables and analysis Natsal data for NVP-HPV paper submitted to CEBP
* Comments/notes:  Data can be accessed through applying on UK Data Archive. National surveillance data is not publicly available, but derivation of key variables and analysis was conducted in the same way as for Natsal datasets.

*Step 1: Prepare to append Natsal-2 and Natsal-3 datasets

*Derive type-specific HPV groupings for each dataset
*Apply codes for not eligible, invalid results, or missing to each type-specific result code
foreach var of varlist hpv_6 hpv_11 hpv_16 hpv_18 hpv_26 hpv_31 hpv_33 hpv_35 hpv_39 hpv_45 hpv_51 hpv_52 hpv_53 hpv_56 hpv_58 hpv_59 hpv_66 hpv_68 hpv_70 hpv_73 hpv_82 {
	replace `var'=-2 if hpv_status==-2
	replace `var'=-1 if hpv_status==-1
	replace `var'=9 if hpv_status==9
}

*DV: NVPHPV detected in vaginal swab sample
*Checked by CG
gen d_NVPHPV=. 
replace d_NVPHPV=0 if hpv_status == 0  | (hpv_status == 1 & (hpv_26==0 & hpv_53==0 &  hpv_66==0 & hpv_70==0 & hpv_73==0) )
replace d_NVPHPV=1 if hpv_status == 1 & (hpv_26==1 | hpv_53==1 |  hpv_66==1 | hpv_70==1 | hpv_73==1) 
replace d_NVPHPV=-1 if hpv_status == -1 
replace d_NVPHPV=-2 if hpv_status == -2
replace d_NVPHPV=9 if hpv_status == 9

label var d_NVPHPV "DV: NVPHPV detected in vaginal swab sample"
label define d_NVPHPV 0 "NVPHPV not detected" 1 "NVPHPV detected"  -2 "Not applicable" 9 "Missing" -1 "Invalid/not tested" 
label values d_NVPHPV d_NVPHPV

tab d_NVPHPV, m

*Ensure required variables match in both datasets

*Create a variable indicating survey
gen survey=0
label var survey "Natsal Survey"
label define survey 0"Natsal-2" 1"Natsal-3"
label val survey survey
*(repeat this for Natsal-3 data, gen survey=1)

*Specify missing data

foreach var of varlist d_NVPHPV{
mvdecode `var', mv (-1)
mvdecode `var', mv (-2)
mvdecode `var', mv(9)
}

*Save prepped N2_dataset and N3_dataset

*Step 2 
*Adjust weighting variables so datasets can be combined
** ADD 10,000 TO EACH PSU IN NATSAL-2 SO THAT THEY DO NOT OVERLAP WITH THE PSUs IN NATSAL-3 **
replace psu=psu+10000

** ADD 1,000 TO EACH STRATA IN NATSAL-2 SO THAT THEY DO NOT OVERLAP WITH THE STRATA IN NATSAL-3 **
replace strata=strata+1000
replace stratagrp=stratagrp+1000
replace stratagrp2 = stratagrp2+1000

*Step 3
*Append datasets
append using "N3_dataset.dta"

*Step 4
*Set survey weights

svyset [pweight=urine_wt], strata(stratagrp2) psu(psu) 

*Step 5
*Conduct regression analysis to show asssociations between sexual behaviours and NVPHPV infection among all females 18-44 in combined dataset
*Repeated for each sexual behaviour (summarised as sexbehav below)
*Age and survey adjusted
svy, subpop(if sex==2 & age>=18 & age<=44): logistic d_NVPHPV i.sexbehav i.survey dage, or
testparm i.sexbehav

*Step 6
*Compare prevalence ratio between Natsal-2 and Natsal-3 to calculate vaccine impact among 18-20 year olds
*Conducted the same way for other type-specific HPV groupings, including NVP-HPV
*Age adjusted
svy, subpop(if sex==2 & age>=18 & age<=20): glm d_HPV16_18 i.survey dage, fam(poisson) link(log) nolog eform
*Age and NVP-HPV adjusted
svy, subpop(if sex==2 & age>=18 & age<=20): glm d_HPV16_18 i.survey dage i.d_NVPHPV, fam(poisson) link(log) nolog eform

*Step 7
*Compare prevalence ratio between vaccinated and unvaccinated women 
*Age adjusted
svy, subpop(if sex==2 & age>=18 & age<=20 & survey==1): glm d_HPV16_18 ib3.hpvever dage, fam(poisson) link(log) nolog eform
*Age and NVP-HPV adjusted
svy, subpop(if sex==2 & age>=18 & age<=20 & survey==1): glm d_HPV16_18 ib3.hpvever i.d_NVPHPV dage, fam(poisson) link(log) nolog eform








