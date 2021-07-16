**************************************************************************
* "Do Multinationals Transfer Culture? Evidence from Female Employment   *
*  in China"                                                             *
*  Journal of International Economics                                    *
*  Replication Do Files                                                  *
*  Heiwai Tang and Yifan Zhang (2021)                                    *
**************************************************************************


****************************************************************
*												 		       *
* Part 2: replicate the regression results (Table 2 - Table 5) *
*												               *
****************************************************************

set more off
set matsize 10000

* set global path to the data folder
cd "Y:\Dropbox\FDI and gender\JIE submission\Data"
 
 

********************
*     Figure 1     *
********************

use "firm level data\main_panel.dta", clear
drop if HMT == 1 //exclude Hong Kong, Macao, Taiwan invested firms
keep if year==2004
drop if female_share < 0.05 |female_share > 0.95 //drop outliers
label variable female_share "Female Employment Share"
kdensity female_share, bwidth(0.07) nograph generate(x fx)
kdensity female_share if foreign==0, bwidth(0.07) nograph generate(fx0) at(x)
kdensity female_share if foreign==1, bwidth(0.07) nograph generate(fx1) at(x)
label var fx0 "Chinese Domestic Firms"
label var fx1 "Foreign Firms"
line fx0 fx1 x, sort ytitle(Density) lpattern(solid) lpattern(dash)



********************
*     Figure 2     *
********************

use "firm level data\main_panel.dta", clear
drop if HMT == 1 
keep if year==2004
drop if female_share < 0.05 |female_share > 0.95
label variable female_share "Female Employment Share"
set matsize 5000
qui reg female_share i.industry 
predict female_share1
label variable female_share1 "Predicted Female Employment Share"
kdensity female_share1, bwidth(0.07) nograph generate(x fx)
kdensity female_share1 if foreign==0, bwidth(0.07) nograph generate(fx0) at(x)
kdensity female_share1 if foreign==1, bwidth(0.07) nograph generate(fx1) at(x)
label var fx0 "Chinese Domestic Firms"
label var fx1 "Foreign Firms"
line fx0 fx1 x, sort ytitle(Density) lpattern(solid) lpattern(dash)


********************
*     Table 2      *
********************

use "firm level data\main_panel.dta", clear
keep if year==2004
egen cnt = group(ISO3)
gen int_gii_ca = gii*female_ca
local controls_1 ln_GDPpc rcomp rd_1 tfp1 skillint lncapint lnrevenue lnwage_e lnage

* column (1)
areg female_share gii i.province, absorb(cic) cluster(cnt)

* column (2)
areg female_share gii `controls_1' i.province, absorb(cic) cluster(cnt)

* column (3)
areg fprob gii `controls_1' i.province, absorb(cic) cluster(cnt)

* column (4)
areg female_share gii int_gii_ca `controls_1' i.province, absorb(cic) cluster(cnt)


********************
*     Table 3      *
********************

use "firm level data\main_panel.dta", clear
qui sum prof_rate, det
gen pl = r(p1)
gen pu = r(p99)
replace prof_rate = . if prof_rate > pu | prof_rate < pl //drop outliers
local controls_2 ln_patent rd_1 lncapint lnemp lnwage_e lnage 

* column (1)
areg prof_rate female_share `controls_2' i.year, absorb(regid) cluster(cic)

* column (2)
drop if HMT == 1 | foreign == 1
areg prof_rate female_share `controls_2' i.year, absorb(regid) cluster(cic)


********************
*     Table 4      *
********************

use "firm level data\main_panel.dta", clear
keep if year==2004
drop if HMT == 1|foreign == 1
local controls_3 ln_patent rd_1 tfp1 lnoutput lncapint lnwage_e lnage import_ratio_cic herf

* column (1)
reg female_share foreign_cic_share skillint `controls_3' i.province, cluster(cic)

* column (2)
reg fprob foreign_cic_share skillint `controls_3' i.province, cluster(cic)

* column (3)
use "firm level data\main_panel.dta", clear
drop if HMT == 1|foreign == 1
areg female_share foreign_cic_share `controls_3' i.year, absorb(regid) cluster(cic)

* column (4)
areg female_share foreign_cic_share int_fdi_gii_cic `controls_3' i.year, absorb(regid) cluster(cic)

* column (5)
areg female_share foreign_province_cic_share foreign_non_province_cic_share `controls_3' i.year, absorb(regid) cluster(cic)

* column (6)
areg female_share foreign_cic_share int_fdi_profitability_cic `controls_3' i.year, absorb(regid) cluster(cic)

* column (7)
areg female_share foreign_cic_share `controls_3' i.sector#year i.year, absorb(regid) cluster(cic)


********************
*     Table 5      *
********************


use "firm level data\main_panel.dta", clear
keep if year==2004
drop if HMT == 1|foreign == 1
local controls_4 ln_patent rd_1 tfp1 lnoutput lncapint lnwage_e lnage import_ratio_city herf_city

* column (1)
reg female_share foreign_city_share skillint `controls_4', cluster(cic)

* column (2)
reg fprob foreign_city_share skillint `controls_4', cluster(cic)

* column (3)
use "firm level data\main_panel.dta", clear
drop if HMT == 1|foreign == 1
areg female_share foreign_city_share `controls_4' i.year, absorb(regid) cluster(cic)

* column (4)
areg female_share foreign_city_share int_fdi_gii_city `controls_4' i.year, absorb(regid) cluster(cic)

* column (5)
areg female_share foreign_sector_city_share foreign_non_sector_city_share `controls_4' i.year, absorb(regid) cluster(cic)

* column (6)
areg female_share foreign_city_share int_fdi_profitability_city `controls_4' i.year, absorb(regid) cluster(cic)

* column (7)
areg female_share foreign_city_share `controls_4' i.province#year, absorb(regid) cluster(cic)
