**************************************************************************
* "Do Multinationals Transfer Culture? Evidence from Female Employment   *
*  in China"                                                             *
*  Journal of International Economics                                    *
*  Replication Do Files                                                  *
*  Heiwai Tang and Yifan Zhang (2021)                                    *
**************************************************************************


**************************************************
*												 *
* Part 1: Combine datasets and create variables  *
*												 *
**************************************************

set more off
set matsize 10000

* set global path to the data folder
cd "Y:\Dropbox\FDI and gender\JIE submission\Data"
  
  
****************************** 
* calculate Herfindahl index *
******************************

forvalues i = 2004/2007 {
	use "firm level data\NBS_panel.dta", clear
	keep if year == `i'
	keep cic output
	bysort cic: egen total = total(output) 
	gen share2 = (output/total)^2
	collapse (sum) share2, by(cic)
	rename share2 herf
	sort cic
	drop if cic == ""
	gen year = `i'
	local herf`i':  tempfile
	save `herf`i'', replace
}

use `herf2004', clear
forvalues i = 2005/2007 {
append using `herf`i''
}

sort year cic
save "industry level data/herf.dta", replace

 
****************************** 
*     merge patent data      *
******************************

use "firm level data\design.dta", clear
drop if asie ==""
drop patent
bysort asie_id year: gen design = _N
duplicates drop asie_id year design, force
rename asie id
sort id year
local tmp1:  tempfile
save `tmp1', replace

use "firm level data\invention.dta", clear
drop if asie ==""
drop patent
bysort asie_id year: gen invention = _N
duplicates drop asie_id year invention, force
rename asie id
sort id year
local tmp2:  tempfile
save `tmp2', replace

use "firm level data\utility.dta", clear
drop if asie ==""
drop patent
bysort asie_id year: gen utility = _N
duplicates drop asie_id year utility, force
rename asie id
sort id year
merge id year using `tmp1'
drop _merge
sort id year
merge id year using `tmp2'
drop _merge
sort id year
save "firm level data\firm_patents.dta", replace

 
****************************** 
*  merge country level data  *
******************************

forvalue i = 2004/2007 {
	use "firm level data/`i'_MNCs_result.dta", clear
	capture rename 法人代码 id
	capture rename 法人单位代码 id
	capture rename frdm id
	capture rename FDI_ID id
	rename foreign1 country
	keep id country
	gen year = `i'
	sort country
	drop if country<100 | country>999
	local tmp`i':  tempfile
	save `tmp`i'', replace
}

use `tmp2004', clear
append using `tmp2005'
append using `tmp2006'
append using `tmp2007'

sort country
merge country using "country level data\FIE survey country code.dta"
bysort year id: drop if _N>1
drop _merge
sort ISO2
merge ISO2 using "country level data\country level variables"
drop _merge
sort id year
save "firm level data\FDI_country_data.dta", replace

 
****************************** 
*   calcualte import value   *
******************************

forvalue i = 2004/2006 {
	use "customs data\import`i'.dta", clear
	gen hs02_6=real(substr(hs,1,6))
	collapse (sum) value, by(hs02_6)
	sort hs02_6
	merge hs02_6 using "customs data\HS02-CIC03.dta"
	collapse (sum) value, by(cic03)
	gen cic = string(cic03)
	drop cic03
	gen year = `i'
	sort year cic
	drop if cic ==""|cic=="."
	local tmp`i':  tempfile
	save `tmp`i'', replace
}
	//HS07 slightly is different from HS02
	use "customs data\import2007.dta", clear
	gen hs07_6=real(substr(hs,1,6))
	collapse (sum) value, by(hs07_6)
	sort hs07_6
	merge hs07_6 using "customs data\HS07-HS02.dta"
	tab _merge
	drop _merge
	sort hs02_6
	merge hs02_6 using "customs data\HS02-CIC03.dta"
	collapse (sum) value, by(cic03)
	gen cic = string(cic03)
	drop cic03
	gen year = 2007
	sort year cic
	drop if cic ==""|cic=="."
	local tmp2007:  tempfile
	save `tmp2007', replace


use `tmp2004', clear
append using `tmp2005'
append using `tmp2006'
append using `tmp2007'
sort year cic
save "industry level data\import_value.dta", replace


****************************** 
*   merge various data		 *
******************************

use "firm level data\NBS_panel.dta", clear
gen foreign = (type == "310"|type == "320"|type == "330"|type == "340")
gen HMT = (type == "210"|type == "220"| type == "230"|type == "240")
gen city = substr(dq,1,4)

sort year cic
merge year cic using "industry level data\import_value.dta"
drop if _merge==2
drop _merge

sort year cic
merge year cic using "industry level data\herf.dta"
drop if _merge==2
drop _merge

sort id year
merge id year using "firm level data\FDI_country_data.dta"
drop _merge

sort id year
merge id year using "firm level data\firm_patents.dta"
drop _merge

replace design=0 if design==.
replace invention=0 if invention==.
replace utility=0 if utility==.
gen patent = design+utility+invention
gen ln_patent = ln(1+patent)

bysort year cic: egen output_total = sum(output)
gen import_ratio_cic = value*8.3/(1000*output_total) //exchange rate of 8.3
replace import_ratio_cic = . if value==.

 
****************************************************** 
*     calulate FDI presence in industry or city      *
******************************************************

bysort cic year: egen foreign_cic_total = sum(foreign*output) 
bysort cic year: egen cic_total = sum(output) 
gen foreign_cic_share = foreign_cic_total/cic_total

gen gii_dummy = (gii !=. & foreign==1)
bysort year cic: egen num_cic = sum(output*gii)
bysort year cic: egen total_num_cic = sum(output*gii_dummy) 
gen gii_cic = num_cic/total_num_cic
gen int_fdi_gii_cic = foreign_cic_share * gii_cic

bysort province cic year: egen foreign_province_cic_total = sum(foreign*output) 
bysort province cic year: egen province_cic_total = sum(output) 
gen foreign_province_cic_share = foreign_province_cic_total/province_cic_total
gen foreign_non_province_cic_share = (foreign_cic_total-foreign_province_cic_total)/(cic_total - province_cic_total)

bysort cic year: egen foreign_profit_total_cic = sum(foreign*profit)
gen foreign_profit_rate_cic = foreign_profit_total_cic/foreign_cic_total
gen int_fdi_profitability_cic = foreign_cic_share * foreign_profit_rate_cic

bysort year city: egen import_ratio_city = mean(import_ratio_cic)
bysort year city: egen herf_city = mean(herf)

bysort city year: egen foreign_city_total = sum(foreign*output) 
bysort city year: egen city_total = sum(output) 
gen foreign_city_share = foreign_city_total/city_total

bysort year city: egen num_city = sum(output*gii)
bysort year city: egen total_num_city = sum(output*gii_dummy) 
gen gii_city = num_city/total_num_city
gen int_fdi_gii_city = foreign_city_share * gii_city

bysort sector city year: egen foreign_sector_city_total = sum(foreign*output) 
bysort sector city year: egen sector_city_total = sum(output) 
gen foreign_sector_city_share = foreign_sector_city_total/sector_city_total
gen foreign_non_sector_city_share = (foreign_city_total-foreign_sector_city_total)/(city_total-sector_city_total)

bysort city year: egen foreign_profit_total_city = sum(foreign*profit)
gen foreign_profit_rate_city = foreign_profit_total_city/foreign_city_total
gen int_fdi_profitability_city = foreign_city_share * foreign_profit_rate_city

save "firm level data\main_panel.dta", replace
