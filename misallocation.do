**************************************************************************
* "Do Multinationals Transfer Culture? Evidence from Female Employment   *
*  in China"                                                             *
*  Journal of International Economics                                    *
*  Replication Do Files                                                  *
*  Heiwai Tang and Yifan Zhang (2021)                                    *
**************************************************************************


*************************************************************************
*															            *
* Part 3: replicate the misallocation results (Figure 3, Table 6 and 7) *
*															            *
*************************************************************************

set more off
set matsize 10000

* set global path to the data folder
cd "Y:\Dropbox\FDI and gender\JIE submission\Data"
 
 
* 1. Obtain sector-level measures of female employment share *

use "firm level data\main_panel.dta", clear
gen cic_3d = substr(cic, 1, 3)
rename female_ca beta3


* 2. Obtain sector-level measures of capital share *
sort cic_3d
merge cic_3d using "nber_capital_int_cic_3d"
drop if _m==2
drop _m
gen alpha_new = alpha_cic_3d


* 3. Set key parameters *
replace sigma = 2
replace alpha  = 1-(3/2)*(1-alpha_new)	// according to HK, boost up labor int by a factor of 1.5, before taking captal int
replace beta = beta3


* 4. Set key macroeconomic variables, and remove observations that have reported negative value added or employment*
replace rental_rate = 0.1
replace real_cap=. if real_cap<0
replace va = . if va<0
replace emp = . if emp<0
replace wage_e = . if wage_e<0
replace ln_k = ln(real_cap)
drop if wage_e==0
drop if va ==. | wage_e==.
gen factor = .
egen gdp = sum(va) if va>0, by(year)
egen labor_cost = sum(wage_e*employment) if wage>0, by(year)
replace factor=1
replace wage_e= 1


* 5. Adjust the quality of male and female employment share *
replace female = female*wage_e*factor
replace male = male*wage_e*factor


* 6. Set distortion variables *
gen double eta = 1-1/sigma
gen double one_t_k = ((1-alpha)/(alpha*(1-beta)))*(male/(rental_rate*real_cap))
gen double one_t_y = (male/(eta*alpha*(1-beta)))/exp(ln_v)
gen double  one_gamma = (beta/(1-beta))*(male/(wage_female*female))

foreach v in t_k t_y gamma {
	replace one_`v' = . if one_`v'==0
}


* 7. remove outliers following Hsieh and Klenow (2009) *
egen temp99 = pctile(one_gamma), p(99) by(year)
egen temp1 = pctile(one_gamma), p(1) by(year)
replace one_gamma = . if one_gamma>temp99 | one_gamma<temp1
drop temp*

drop if one_gamma==.
save temp, replace

egen temp99 = pctile(one_t_k), p(99) by(year)
egen temp1 = pctile(one_t_k), p(1) by(year)
replace one_t_k = . if one_t_k>temp99 | one_t_k<temp1
drop temp*

egen temp99 = pctile(one_t_y), p(99) by(year)
egen temp1 = pctile(one_t_y), p(1) by(year)
replace one_t_y = . if one_t_y>temp99 | one_t_y<temp1
drop temp*


* 8. Compute firm TPPQ * 
drop ln_TFPQ 
gen double  ln_TFPQ = .

replace ln_TFPQ = (sigma/(sigma-1))*ln_v - (1-alpha)*ln_k - alpha*beta*ln(female)-alpha*(1-beta)*ln(male)
label var ln_TFPQ "(sigma/(sigma-1))*ln_v - (1-alpha)*ln_k - alpha*beta*ln(female)-alpha*(1-beta)*ln(male)"

gen TFPQ = exp(ln_TFPQ)


* 9. Compute firm TPPR * 
drop ln_TFPR
gen double  ln_TFPR = .

replace ln_TFPR = ln_v - (1-alpha)*ln(real_cap) - (alpha)*beta*ln(female) - (alpha)*(1 - beta)*ln(male)
label var ln_TFPR "ln_v - (1-alpha)*ln(real_cap) - (alpha)*beta*ln(female) - (alpha)*(1 - beta)*ln(male)"

gen double TFPR = exp(ln_TFPR)


* 10. Compute sector-level average TFPR (using wages, distortions, etc.) *												
gen double tfpr = .
gen double ln_tfpr = .

// a. Set TFPQ means by sector //
egen sector_va = sum(exp(ln_v)), by(cic_3d year)
gen wgt = exp(ln_v)/sector_va

gen double ele = TFPQ^(sigma-1)
egen double  elex = sum(ele), by(cic_3d year)
egen double n = count(year) if TFPQ!=., by(cic_3d year)
gen double mTFPQ = (elex/n)^(1/(sigma-1))
replace mTFPQ =. if elex==.

gen mrpk = .
gen mrpm = .
gen mrpf = .
gen mtfpr = .

gen elek = wgt*(one_t_y/one_t_k)
gen elem = wgt*(one_t_y)
gen elef = wgt*(one_t_y/one_gamma)

egen elek1 = sum(elek), by(cic_3d year)
egen elem1 = sum(elem), by(cic_3d year)
egen elef1 = sum(elef), by(cic_3d year)

replace mrpk = rental_rate/elek1
replace mrpm = 1/elem1
replace mrpf = wage_female/elef1

replace tfpr = (1/eta)*[(rental_rate/(one_t_y/one_t_k))/(1-alpha)]^(1-alpha)*[(1/(one_t_y))/(alpha*(1-beta))]^(alpha*(1-beta))*[(wage_f/(one_t_y/one_gamma))/(alpha*beta)]^(alpha*beta)
replace mtfpr = (1/eta)*[(mrpk/(1-alpha))^(1-alpha)]*[(mrpm/(alpha*(1-beta)))^(alpha*(1-beta))]*[(mrpf/(alpha*beta))^(alpha*beta)]

drop ele* 


* 11. Drop outliers bsaed on TFPQ (following Hsieh and Klenow (09)) *
gen double TFPQ_dm = .
replace TFPQ_dm = TFPQ/mTFPQ

egen double temp99 = pctile(TFPQ_dm), p(99) by(year)
egen double temp1 = pctile(TFPQ_dm), p(1) by(year)
replace TFPQ = . if TFPQ_dm>temp99 | TFPQ_dm<temp1
drop temp*

gen double tfpr_dm = .
replace tfpr_dm = tfpr/mtfpr

egen double temp99 = pctile(tfpr_dm), p(99) by(year)
egen double temp1 = pctile(tfpr_dm), p(1) by(year)
replace tfpr = . if tfpr_dm>temp99 | tfpr_dm<temp1
drop temp*

drop if one_gamma==. | one_t_y==. | one_t_k==. | tfpr==. | TFPQ ==. | tfpr ==.  

drop sector_va wgt mtfpr mTFPQ n gdp

save working, replace


********************************
*							   *
*    Table 6 and Table 7 	   *
*							   *
********************************

* Compute column (1) of table 6 - the aggregate TFP gain by removing all three types distortions (i.e., gender, capital, and output)) *
use working, clear
egen double sector_va = sum(exp(ln_v)) if tfpr!=. & TFPQ!=., by(cic_3d year)
egen double gdp = sum(va) if tfpr!=. & TFPQ!=. & va>0, by(year)
gen double wgt = exp(ln_v)/sector_va if tfpr!=. & TFPQ!=. & va>0
egen double n = count(year) if  tfpr!=. & TFPQ!=., by(cic_3d year)

// recompute tfpq and tfpr dm after removing outliers //
gen mtfpr = .

gen elek = wgt*(one_t_y/one_t_k) if  tfpr!=. & TFPQ!=.
gen elem = wgt*(one_t_y) if  tfpr!=. & TFPQ!=.
gen elef = wgt*(one_t_y/one_gamma) if  tfpr!=. & TFPQ!=.

egen elek1 = sum(elek) if  tfpr!=. & TFPQ!=., by(cic_3d year)
egen elem1 = sum(elem) if  tfpr!=. & TFPQ!=., by(cic_3d year)
egen elef1 = sum(elef) if  tfpr!=. & TFPQ!=., by(cic_3d year)

replace  mrpk = rental_rate/elek1 if  tfpr!=. & TFPQ!=.
replace  mrpm = 1/elem1 if  tfpr!=. & TFPQ!=.
replace  mrpf = wage_female/elef1 if  tfpr!=. & TFPQ!=.

replace mtfpr = (1/eta)*[(mrpk/(1-alpha))^(1-alpha)]*[(mrpm/(alpha*(1-beta)))^(alpha*(1-beta))]*[(mrpf/(alpha*beta))^(alpha*beta)]
replace tfpr_dm = tfpr/mtfpr

drop ele* 

gen double ele = TFPQ^(sigma-1) 
egen double elex = sum(ele) , by(cic_3d year)
gen double mTFPQ = (elex/n)^(1/(sigma-1)) 
replace mTFPQ =. if elex==.
replace TFPQ_dm = TFPQ/mTFPQ

gen double ele1= (TFPQ/tfpr_dm)^(sigma-1)
egen double ele2 = sum(ele1), by(cic_3d year)
replace ele2 = . if ele1==.
gen double tfp = ele2^(1/(sigma-1))
drop ele*

// Efficient TFP //
gen double  ele = TFPQ^(sigma-1) if tfpr_dm!=. & TFPQ!=.
egen double  elex = sum(ele) if tfpr_dm!=. & TFPQ!=., by(cic_3d year)
gen double  tfp_e = (elex)^(1/(sigma-1)) if tfpr_dm!=. & TFPQ!=.
replace  tfp_e =. if tfp_e==0

gen loss = tfp_e/tfp-1  // this is the "Aggregate TFP Gain by Removing All Three Distortions", as reported in column (1) of Table 6 
drop ele*


* Compute column (2) of table 6 - the aggregate TFP gain by removing capital and output distortions *
gen double tfpr1 = .
gen double ln_tfpr1 = .
gen double ln_tfpr1_dm = .

gen one_gamma1 = 1  // when there is no gender discrimination, i.e. gamma = 0 // 
replace tfpr1 = (1/eta)*[(rental_rate/(one_t_y/one_t_k))/(1-alpha)]^(1-alpha)*[(1/(one_t_y))/(alpha*(1-beta))]^(alpha*(1-beta))*[(wage_f/(one_t_y/one_gamma1))/(alpha*beta)]^(alpha*beta)
replace ln_tfpr1 = ln(tfpr1)

// set new mtfpr //
gen tfpr1_dm = .
gen mtfpr1 = .
 
gen elek = wgt*(one_t_y/one_t_k)
gen elem = wgt*(one_t_y)
gen elef = wgt*(one_t_y/one_gamma1)

egen elek1 = sum(elek) if  tfpr!=. & TFPQ!=., by(cic_3d year)
egen elem1 = sum(elem) if  tfpr!=. & TFPQ!=., by(cic_3d year)
egen elef1 = sum(elef) if  tfpr!=. & TFPQ!=., by(cic_3d year)

replace  mrpk = rental_rate/elek1
replace  mrpm = 1/elem1
replace  mrpf = wage_female/elef1

replace mtfpr1 = (1/eta)*[(mrpk/(1-alpha))^(1-alpha)]*[(mrpm/(alpha*(1-beta)))^(alpha*(1-beta))]*[(mrpf/(alpha*beta))^(alpha*beta)]
replace tfpr1_dm = tfpr1/mtfpr1

drop ele* 

gen double ele1= (TFPQ/tfpr1_dm)^(sigma-1)
egen double ele2 = sum(ele1), by(cic_3d year)
replace ele2 = . if ele1==.
gen double tfp1 = ele2^(1/(sigma-1))
drop ele*

// Efficient TFP //
gen double  ele = TFPQ^(sigma-1) if tfpr_dm!=. & TFPQ!=.
egen double  elex = sum(ele) if tfpr_dm!=. & TFPQ!=., by(cic_3d year)
gen double tfp1_e = (elex)^(1/(sigma-1)) if tfpr_dm!=. & TFPQ!=.
replace  tfp1_e =. if tfp1_e==0
drop ele*

gen double  loss1 = tfp1_e/tfp1-1  // this is the "Aggregate TFP Gain by Removing Capital and Output Distortions", as reported in column (2) of Table 6 //


* Compute column (3) of table 6 - the aggregate TFP gain by removing capital distortions *
gen double tfpr2 = .
gen double ln_tfpr2 = .
gen double ln_tfpr2_dm = .

replace one_t_k = 1  // when there is no capital discrimination // 

replace tfpr2 = (1/eta)*[(rental_rate/(one_t_y/one_t_k))/(1-alpha)]^(1-alpha)*[(1/(one_t_y))/(alpha*(1-beta))]^(alpha*(1-beta))*[(wage_f/(one_t_y/one_gamma))/(alpha*beta)]^(alpha*beta)

replace ln_tfpr2 = ln(tfpr2)

gen tfpr2_dm = .
gen mtfpr2 = .
 
gen elek = wgt*(one_t_y/one_t_k)
gen elem = wgt*(one_t_y)
gen elef = wgt*(one_t_y/one_gamma)

egen elek2 = sum(elek) if  tfpr!=. & TFPQ!=., by(cic_3d year)
egen elem2 = sum(elem) if  tfpr!=. & TFPQ!=., by(cic_3d year)
egen elef2 = sum(elef) if  tfpr!=. & TFPQ!=., by(cic_3d year)

replace  mrpk = rental_rate/elek2
replace  mrpm = 1/elem2
replace  mrpf = wage_female/elef2

replace mtfpr2 = (1/eta)*(mrpk/(1-alpha))^(1-alpha)*(mrpm/(alpha*(1-beta)))^(alpha*(1-beta))*(mrpf/(alpha*beta))^(alpha*beta)
replace tfpr2_dm = tfpr2/mtfpr2

drop ele*

su tfpr2_dm

gen double ele1= (TFPQ/tfpr2_dm)
gen double ele1b = ele1^(sigma-1)
egen double ele2 = sum(ele1b) if ele1!=., by(cic_3d year)
gen double  tfp2 = ele2^(1/(sigma-1))
drop ele*

// Efficient TFP //
gen double  ele = TFPQ^(sigma-1) if tfpr_dm!=. & TFPQ!=.
egen double  elex = sum(ele) if tfpr_dm!=. & TFPQ!=., by(cic_3d year)
gen double tfp2_e = (elex)^(1/(sigma-1)) if tfpr_dm!=. & TFPQ!=.
replace  tfp2_e =. if tfp2_e==0
drop ele*

gen double loss2 = tfp2_e/tfp2-1 // this is the "Aggregate TFP Gain by Removing Gender and Output Distortions", as reported in column (3) of Table 6 //

gen ln_TFPQ_dm = .
gen ln_tfpr_dm=.
foreach v in TFPQ_dm tfpr_dm tfpr1_dm tfpr2_dm tfpr tfpr1 tfpr2{
	replace ln_`v'= ln(`v')
}

save working2, replace

*** the remaining parts of table 6 and table 7 are constructed based on simple computation ***

exit
