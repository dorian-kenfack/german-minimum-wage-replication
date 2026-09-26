***************************************************************
************ Replication Code for Bonin et al. (2019): ********
*** The German Statutory Minimum Wage and Its Effects *********
*********On Regional Employment and Unemployment***************
***************************************************************

qui {
	
	// Specify stata specifics
	set more off 
	capture log close _all
	pause on
	clear all
	set mem 6g
	set maxvar 32767
	set matsize 10000
	set seed 1234567891
	set scheme lean2 
	set graphics on
	set linesize 200

	// Specify what to run
	local maps 		   = 1
	local descriptives = 1
	local regressions  = 1

	//
	// CREATE MAPS (FIGURES 1, 2 and A1) 
	//
	
	if `maps' == 1 {
		
		noi di "CREATE MAPS (Fig.1, Fig.2, Fig.A1)..."
	
		// Load Shapefile
		shp2dta using "shapefiles/shp_ger_kreis.shp", ///
				database("shapefiles/shp_base_kreis") ///
				coordinates("shapefiles/shp_coord_2013") ///
				replace genid(id) gencentroids(stub)
		 
		use "shapefiles/shp_base_kreis.dta", clear

		// Account for redrawn county border for Göttingen/Osterode 
		gen kreis 			= AGS
		gen kreis_panel 	= AGS
		replace kreis_panel = "03159" if inlist(kreis_panel,"03152","03156") 

		// Merge Shapefile data with AMR crosswalk
		merge m:1 kreis_panel using "shapefiles/crosswalk_amr_ror", ///
			  nogen keepusing(amr amr_name)

		// Load Shapefile for AMR in GER
		mergepoly id using "shapefiles/shp_coord_2013", by(amr) ///
				  coordinates("shapefiles/shp_coord_amr") replace

		// Merge regional bite info to data
		merge m:1 amr using "ml_bite_VSE_2014.dta", nogen

		// Merge population data
		gen year = 2013
		gen month = 12
		merge 1:1 amr year month using "mlk_amr_panel.dta", ///
			  keep(master match) nogen keepusing(weight_*)

		// Generate weights	  
		gen double weight_workpop = 100 * weight_work14 / weight_pop13 
		replace weight_workpop = 90 if weight_workpop>90 & weight_workpop!=.
		
		//
		// Graph regional variation in minimum wage
		//
		
		// ...for different definitions of mw bite	(winsorize it)		
		replace mw_aff = 35 if mw_aff > 35 
		replace mw_luecke = round(mw_luecke,.01) if mw_luecke > 0.65 
		replace mw_kaitz_mean = 40 if mw_kaitz_mean <40 
		
		foreach bite in luecke aff kaitz_mean kaitz_p50 { 
		
			// Share Affected
			if "`bite'" == "aff" {	
				local clb "0 10 20 30 35"
				local title "Measure: Sh. of affected workers"
				local legtitle "in percent"
			}
			
			// Kaitz-Index (Mean)
			if "`bite'" == "kaitz_mean" {	
				local clb "40 50 60 70 80"
				local title "Measure: Kaitz index (mean)"
				local legtitle "in percent"
			}	
			
			// Kaitz-Index (Median)
			if "`bite'" == "kaitz_p50" {	
				local clb "40 50 60 70 80 90"
				local title "Measure: Kaitz index (median)"
				local legtitle "in percent"
			}
			
			// Kaitz-Index (Wage Gap)
			if "`bite'" == "luecke" {	
				local clb "0 0.1 0.16 0.25 0.45 0.65"
				local title "Wage gap"
				local legtitle "in Euro"	
			}
			
			spmap mw_`bite' using "shapefiles/shp_coord_amr", ///
				id(id) fcolor(Greys) clm(custom) clbreaks("`clb'") ///
				name(`bite'_cont, replace) legend(pos(10) size(vsmall) ///
				title("`legtitle'", size(vsmall))) title("`title'") 
			graph export "graphs/map_cont_`bite'.pdf", replace as(pdf)
			
			// Discrete Treatment/Control Group for wag gap
			
			if "`bite'" == "luecke" {
				
				spmap mw_`bite'_g2 using "shapefiles/shp_coord_amr", ///
					  id(id) fcolor(Greys) clmethod(unique) ///
					  name(`bite'_g2, replace) legend(pos(11) ///
					  size(tiny)) title("`title'") 
				graph export "graphs/map_dummy_`bite'.pdf", replace as(pdf)
			}			
		} 
		noi di "...OK"
	}

	// 
	// CREATE FIGURE 3 
	// 
	
	if `descriptives' == 1 {
				
		noi di "Show evaluation of outcome variables over time..."
		
		use mlk_amr_panel.dta,clear
		
		// Define treatment and outcome vars ***
		local treatvars_bin "mw_luecke_g2"  
		local outcomevars 	"log_svb_total log_geb_total log_al_abs_insg_tot"
		
		foreach outvar of varlist `outcomevars' {
			
			// Specify titles
			if "`outvar'" == "log_svb_total" {
				local title "(a) Regular employment (in logs)"
			}
			
			if "`outvar'" == "log_geb_total" {
				local title "(b) Marginal employment (in logs)"	
			}
			
			if "`outvar'" == "log_al_abs_insg_tot" {
				local title "(c) Total Unemployment (in logs)"
			}
			
			// Create graphs
			foreach treatvar of varlist `treatvars_bin' {	
			
				local subtitle: var lab `treatvar'	
				local subtitle = subinstr("`subtitle'","Bite: ","",.)
				local subtitle = subinstr("`subtitle'"," (Dummy Median)","",.)

				preserve
				
				if strpos("`outvar'","geb")>0 	local time "timeH"
				else 							local time "timeQ"
				
				collapse (mean) `outvar' [aw=weight_pop13],by(`treatvar' `time')
				
				qui sum `outvar'
				if r(min) < 0 	local yline "yline(0, lp(solid) lc(black))"
				else 			local yline ""
					
				if "`time'"=="timeQ" {
					local t1 = tq(2014q2) + (1/3)
					local t2 = tq(2014q4) + (1/3)
					
					local tline "tline(`t1', lp(dash) lc(black)) tline(`t2', lp(solid) lc(black)) tlabel(2013q1(1)2016q4, angle(90) labsize(small))"
				}
				if "`time'"=="timeH" {
					local t1 = th(2014h1) + (1/6)
					local t2 = th(2014h2) + (1/6)
					
					local tline "tline(`t1', lp(dash) lc(black)) tline(`t2', lp(solid) lc(black)) tlabel(2013h1 "6/2013" 2014h1 "6/2014" 2015h1 "6/2015" 2016h1 "6/2016", angle(90) labsize(small))"
				}
				
				if strpos("`treatvar'","g2") > 0 {
					local conn "(conn `outvar' time if `treatvar'==1, mc(black) lc(black)) (conn `outvar' time if `treatvar'==2, mc(black) lc(black))"
					local leglab "lab(1 "control (lower 50%)") lab(2 "treatment (upper 50%)")"
				}
						
				tw `conn', legend(pos(6) rows(1) `leglab' `yline' ///
				title("`subtitle'", size(medsmall))) ytitle("") xtitle("") ///
				ylabel(, nogrid) title("`title'", size(medsmall)) `tline'
				
				graph export "graphs/overtime_`outvar'.pdf", replace as(pdf)
				
				restore
				
			} //treatvar
		} //outvar
		noi di "...OK"
	} 
	
	//
	// REGRESSION RESULTS
	//
	
	if `regressions' == 1 {
	
		noi di "CREATE REGRESSION RESULTS"
	
		// Load dataset
		use mlk_amr_panel.dta,clear

		// Set panel dimension (AMR*Time)
		xtset amr time
	
		// Define Treatment (first post treatment: 3rd quarter 2014)
		drop post15
		gen post15 = 0
		replace post15 = 1 if time > 653 // Juni 2014
		
		recode mw_luecke_g2 (1=0) (2=1)
		gen treatment_effect = mw_luecke_g2 * post15
	
		// Define locals
		local mwbite mw_luecke_g2 
		local bite luecke
		
		qui su mw_luecke, d
		local p10_luecke = r(p10)
		local p90_luecke = r(p90)
		
		sencode amr_typ, replace
		
		// Specify outcomes
		local depvars log_svb_total log_geb_tot ///
					  log_geb_aus log_svgeb_tot
		
		noi di ""
		noi di "Table 1: Effects on Employment"
		
		estimates drop _all
		
		foreach depvar of local depvars {
	
			estimates drop _all

			// Run regressions for entire GER
						
			eststo `depvar'_1: xtreg `depvar' i.post15 i.`mwbite' ///
				   treatment_effect i.time [aw=weight_pop13], ///
				   fe cluster(amr) 
		
			if "`depvar'" == "log_svb_total" {
			eststo `depvar'_2: xtreg `depvar' i.post15 i.`mwbite' ///
				   treatment_effect i.time i.month#i.east ///
				   [aw=weight_pop13], fe cluster(amr) 
			}
			
			if "`depvar'" != "log_svb_total" {
				eststo `depvar'_2: xtreg `depvar' i.post15 i.`mwbite' ///
					   treatment_effect i.time c.time#i.east ///
					   [aw=weight_pop13], fe cluster(amr) 
			}

			eststo `depvar'_3: xtreg `depvar' i.post15 i.`mwbite' ///
				   treatment_effect i.time i.amr_typ#i.time#i.east ///
				   [aw=weight_pop13], fe cluster(amr) 
								   
			eststo `depvar'_4: xtreg `depvar' i.post15 i.`mwbite' ///
				  treatment_effect i.time i.amr_typ#i.time#i.east ///
				  c.pop_share_1864_2013#i.time#i.east ///
				  c.time#c.empl_share_manutot_2013#i.east /// 
				  c.time#c.empl_share_publ_2013#i.east ///
				  c.time#c.empl_share_agric_2013#i.east ///
				  c.time#c.empl_share_trade_2013 ///
				  [aw=weight_pop13], fe cluster(amr) 	
			
			eststo `depvar'_5: xtreg `depvar' i.post15 i.`mwbite' ///
				  treatment_effect i.time i.amr_typ#i.time#i.east ///
				  c.pop_share_1864_2013#i.time#i.east ////
				  c.time#c.empl_share_manutot_2013#i.east /// 
				  c.time#c.empl_share_publ_2013#i.east ///
				  c.time#c.empl_share_agric_2013#i.east ///
				  c.time#c.empl_share_trade_2013 [aw=weight_pop13] ///
				  if mw_luecke > `p10_luecke' & ///
				  mw_luecke < `p90_luecke', fe cluster(amr)
		
			noi esttab `depvar'_?, keep(treatment_effect) ///
				star(* 0.1 ** 0.05 *** 0.01) b(%9.4fc) se(%9.4fc) nogaps
		}
		
		noi di "...OK"
		noi di ""
		
		// CREATE TABLE 2: Effects on Unemployment
		noi di "Table 2: Effects on Unemployment"
		
		estimates drop _all
		
		// Load dataset
		use mlk_amr_panel.dta,clear
		
		// Set panel dimension (AMR*Time)
		xtset amr time
	
		// Define Treatment (first post treatment: 3rd quarter 2014)
		drop post15
		gen post15 = 0
		replace post15 = 1 if time > 653
		
		recode mw_luecke_g2 (1=0) (2=1)
		
		gen treatment_effect = mw_luecke_g2 * post15
			
		// Recode variable to zero/one
		recode mw_luecke_g2 (1=0) (2=1)

		// Define locals
		local mwbite mw_luecke_g2 
		local bite luecke
		
		qui su mw_luecke, d
		local p10_luecke = r(p10)
		local p90_luecke = r(p90)
		
		sencode amr_typ, replace
		
		// Run regressions

		eststo lalo_1: xtreg log_al_abs_insg_tot i.post15 ///
					   i.mw_luecke_g2 treatment_effect i.time ///
					   [aw=weight_pop13], fe cluster(amr) 
			
		eststo lalo_2: xtreg log_al_abs_insg_tot i.post15 ///
					   i.mw_luecke_g2 treatment_effect i.time ///
					   i.month#i.east [aw=weight_pop13], fe cluster(amr) 
		
		eststo lalo_3: xtreg log_al_abs_insg_tot i.post15 ///
					   i.mw_luecke_g2 treatment_effect i.time ///
					   i.amr_typ#i.time#i.east ///
					   [aw=weight_pop13], fe cluster(amr) 
								   
		eststo lalo_4: xtreg log_al_abs_insg_tot i.post15 ///
					   i.mw_luecke_g2 treatment_effect i.time ///
					   i.amr_typ#i.time#i.east ///
					   c.pop_share_1864_2013#i.time#i.east ///
					   c.time#c.empl_share_manutot_2013#i.east /// 
					   c.time#c.empl_share_publ_2013#i.east ///
					   c.time#c.empl_share_agric_2013#i.east ///
					   c.time#c.empl_share_trade_2013 ///
					   [aw=weight_pop13], fe cluster(amr) 	
			
		eststo lalo_5: xtreg log_al_abs_insg_tot i.post15 ///
					   i.mw_luecke_g2 treatment_effect i.time ///
					   i.amr_typ#i.time#i.east ///
					   c.pop_share_1864_2013#i.time#i.east ///
					   c.time#c.empl_share_manutot_2013#i.east /// 
					   c.time#c.empl_share_publ_2013#i.east ///
					   c.time#c.empl_share_agric_2013#i.east ///
					   c.time#c.empl_share_trade_2013 [aw=weight_pop13] ///
					   if mw_luecke > `p10_luecke' & ///
					   mw_luecke < `p90_luecke', fe cluster(amr)	
		
		noi esttab lalo_?, keep(treatment_effect) ///
				star(* 0.1 ** 0.05 *** 0.01) b(%9.4fc) se(%9.4fc) nogaps
		
		noi di "...OK"
		noi di ""
		
		// Table A3: Robustness Check: Bite = Share of affected workers
		noi di "Table A3: Share of affected workers as mw bite proxy"
		
		estimates drop _all
		
		use mlk_amr_panel.dta,clear

		// Set panel dimension (AMR*Time)
		xtset amr time
		
		cap drop post15
		gen post15 = 0
		replace post15 = 1 if time > 653
		
		recode mw_aff_g2 (1=0) (2=1)
			
		// Create treatment variable
		cap drop treatment_effect 
		gen treatment_effect = mw_aff_g2 * post15
		
		sencode amr_typ, replace
		
		// Run regressions for quarterly outcomes
		
		eststo sv_aff: xtreg log_svb_total i.post15 i.mw_aff_g2 ///
					   treatment_effect i.time i.amr_typ#i.time#i.east ///
					   c.pop_share_1864_2013#i.time#i.east ///
					   c.time#c.empl_share_manutot_2013#i.east /// 
					   c.time#c.empl_share_publ_2013#i.east ///
					   c.time#c.empl_share_agric_2013#i.east ///
					   c.time#c.empl_share_trade_2013 ///
					   [aw=weight_pop13], fe cluster(amr)

		eststo al_aff: xtreg log_al_abs_insg_tot i.post15 i.mw_aff_g2 ///
						  treatment_effect i.time i.amr_typ#i.time#i.east ///
					      c.pop_share_1864_2013#i.time#i.east ///
						  c.time#c.empl_share_manutot_2013#i.east /// 
						  c.time#c.empl_share_publ_2013#i.east ///
						  c.time#c.empl_share_agric_2013#i.east ///
						  c.time#c.empl_share_trade_2013 ///
						  [aw=weight_pop13], fe cluster(amr)				   

		// Run regressions for years outcomes
		local depvars log_geb_tot log_geb_aus log_svgeb_tot
		foreach depvar of local depvars {
			eststo `depvar'_aff: xtreg `depvar' i.post15 treatment_effect ///
					i.mw_aff_g2 i.time c.time#i.east i.amr_typ#i.time#i.east ///
					c.pop_share_1864_2013#i.time#i.east ///
					c.time#c.empl_share_manutot_2013#i.east ///
					c.time#c.empl_share_publ_2013#i.east ///
					c.time#c.empl_share_agric_2013#i.east ///
					c.time#c.empl_share_trade_2013 ///
					[aw=weight_pop13], fe cluster(amr)
		}	
		
		noi esttab sv_aff log_geb_tot_aff log_geb_aus_aff ///
				   log_svgeb_tot_aff al_aff, keep(treatment_effect) ///
				star(* 0.1 ** 0.05 *** 0.01) b(%9.4fc) se(%9.4fc) nogaps
		
		noi di "...OK"
		noi di ""		
		
		// Table 4: Robustness Check: Non-weighted regressions
		noi di "Table 4: Non-weighted regressions"
		
		estimates drop _all
		
		use mlk_amr_panel.dta,clear
		
		// Set panel dimension (AMR*Time)
		xtset amr time
		
		cap drop post15
		gen post15 = 0
		replace post15 = 1 if time > 653
		
		tab mw_luecke_g2, nol
		recode mw_luecke_g2 (2=1) (1=0)
				
		sencode amr_typ, replace
		
		// Define treatment 
		gen treatment_effect = mw_luecke_g2  * post15
		
		// Run regressions for quarterly outcomes 
				
		eststo sv: xtreg log_svb_total i.post15 i.mw_luecke_g2 ///
				   treatment_effect i.time i.amr_typ#i.time#i.east ///
				   c.pop_share_1864_2013#i.time#i.east ///
				   c.time#c.empl_share_manutot_2013#i.east /// 
				   c.time#c.empl_share_publ_2013#i.east ///
				   c.time#c.empl_share_agric_2013#i.east ///
				   c.time#c.empl_share_trade_2013, fe cluster(amr)
							   
		eststo al: xtreg log_al_abs_insg_tot i.post15 i.mw_luecke_g2 ///
				   treatment_effect i.time i.amr_typ#i.time#i.east ///
				   c.pop_share_1864_2013#i.time#i.east ///
				   c.time#c.empl_share_manutot_2013#i.east /// 
				   c.time#c.empl_share_publ_2013#i.east ///
				   c.time#c.empl_share_agric_2013#i.east ///
				   c.time#c.empl_share_trade_2013, fe cluster(amr)				   
		
		// Run regressions for yearly outcomes
		local depvars log_geb_tot log_geb_aus log_svgeb_tot
		foreach depvar of local depvars {
			eststo `depvar': xtreg `depvar' i.post15 treatment_effect ///
							 i.mw_luecke_g2 i.time c.time#i.east ///
							 i.amr_typ#i.time#i.east ///
							 c.pop_share_1864_2013#i.time#i.east ///
							 c.time#c.empl_share_manutot_2013#i.east ///
							 c.time#c.empl_share_publ_2013#i.east ///
							 c.time#c.empl_share_agric_2013#i.east ///
							c.time#c.empl_share_trade_2013, fe cluster(amr)
		}
   		
		noi esttab sv log_geb_tot log_geb_aus ///
				   log_svgeb_tot al, keep(treatment_effect) ///
				star(* 0.1 ** 0.05 *** 0.01) b(%9.4fc) se(%9.4fc) nogaps
		
		noi di "...OK"
		noi di ""
		
		//
		// Estimate dynamic treatment effects and graph effects
		//
		
		noi di "Create dynamic treatment effect graphs (Fig 4/5)"
		
		//
		// Run regressions for quarterly outcomes
		//
		
		noi di "(a) Run regressions for quarterly outcomes..."
		use mlk_amr_panel.dta,clear
		
		// Set panel dimension (AMR*Time)
		xtset amr time
		
		sencode amr_typ, replace
					
		// Define treatment 
		cap drop treatment_??? foo
		levelsof time, local(times)
		foreach t of local times {
			gen treatment_`t' = mw_luecke * (time == `t')
		}			
		rename treatment_653 foo

		ds treatment_*
		local treat_list = r(varlist)	

		qui su mw_luecke, d
		local p10_luecke = r(p10)
		local p90_luecke = r(p90)
				
		local cond "if mw_luecke > `p10_luecke' & mw_luecke < `p90_luecke'"
		
		// Loop regression results over outcomes
		local depvars log_al_abs_insg_tot log_svb_tot 
		
		foreach depvar of local depvars {
			
			if "`depvar'" == "log_svb_tot" {
				local title "(a) Regular employment (in logs)"
				local yvar lsvb_tot
				local text 
				local ylabel "-0.06 (0.02) 0.06"
			} 		
				
			if "`depvar'" == "log_al_abs_insg_tot" {
				local title "Total unemployed (in logs)"
				local ylabel "-0.4 (0.2) 0.4"
				local text 
				local yvar lalo_tot
			} 
			
			// Specify tempfile to store lincom results
			tempname memhold
			tempfile results
			postfile `memhold' testrun estimate ll ul using "`results'"

			local i = 0	
	   
			reghdfe `depvar' treatment_??? ///
					i.time#c.pop_share_1864_2013#i.east ///
					c.time#c.empl_share_publ_2013#i.east ///
					c.time#c.empl_share_manutot_2013#i.east ///
					c.time#c.empl_share_trade_2013#i.east ///
					c.time#c.empl_share_agric_2013#i.east [aw=weight_pop13] ///
					`cond',	absorb(amr amr_typ#time#east) cluster(amr)
		
			// Foreach level of variable, perform lincom and save b, sd, df_r
			local i = 1
			foreach l of local treat_list {
				noi post `memhold' (`i') (_b[`l']) (_b[`l'] - invttail(e(df_r),0.025)*_se[`l']) (_b[`l'] + invttail(e(df_r),0.025)*_se[`l'])
				local i = `i' + 1
			} // foreach l

			postclose `memhold'

			preserve

			use "`results'", clear
			
			expand 2 if testrun == 5, gen(exp)
			replace estimate = 0 if exp == 1
			replace ul = 0 if exp == 1 
			replace ll = 0 if exp == 1
			sort testrun exp
			gen year = _n
			 
			noi tw (rcap ul ll year, lc(gs10) lwidth(thin) lcolor(black)) ///
			   (scatter estimate year, lcolor(black) mcolor(black) m(o)), ///
				title(`title', color(black) size(medium)) xtitle("Time") ylabel(`ylabel', nogrid) ///
				xline(6.25, lpattern(dash)) xline(8.25, lpattern(solid)) yline(0, lcolor(black)) ///
				xlabel(1 "Q1/2013" 2 "Q2/2013" 3 "Q3/2013" 4 "Q4/2013" 5 "Q1/2014" 6 "Q2/2014" 7 "Q3/2014" 8 "Q2/2014" ///
					   9 "Q1/2015" 10 "Q2/2015" 11 "Q3/2015" 12 "Q4/2015" 13 "Q1/2016" 14 "Q2/2016" 15 "Q3/2016" ///
					   16 "Q4/2016", angle(90) labsize(small)) /// 
				legend(order(2 1) pos(6) rows(1) label(1 "95% Confidence Interval") ///
				label(2 "Point Estimate") size(small)) ytitle("Point Estimate") text(`text') 
				graph export "graphs/`depvar'_dyn.pdf", replace as(pdf)
			restore				
		}
		
		noi di "...OK"
		noi di ""
		
		//
		// Run regressions for yearly outcome variables"
		//
		
		noi di "(b) Run regressions for yearly outcome variables"
		
		use mlk_amr_panel.dta,clear
		
		keep if log_geb_total !=.
	
		// Set panel dimension (AMR*Time)
		xtset amr time
		
		sencode amr_typ, replace
		
		// Define treatment 
		cap drop treatment_??? foo
		levelsof time, local(times)
		foreach t of local times {
			gen treatment_`t' = mw_luecke * (time == `t')
		} 	
		su treatment_???
			
		rename treatment_653 foo

		ds treatment_*
		local treat_list = r(varlist)	
		
		qui su mw_luecke, d
		local p10_luecke = r(p10)
		local p90_luecke = r(p90)
				
		local cond "if mw_luecke > `p10_luecke' & mw_luecke < `p90_luecke'"
		
		// Loop over outcomes
		local depvars log_svgeb_tot log_geb_aus
		foreach depvar of local depvars {
		
			if "`depvar'" == "log_geb_aus" {
				local title "(b) Marginal Employment (in logs)"
				local yvar lgeb_aus
				local text 0.225 11 
				local yvar ggeb_aus
				local ylabel "-0.4 (0.1) 0.1"
			} 		
		
			if "`depvar'" == "log_svgeb_tot" {
				local title "(c) Total employment (regular and marginal, in logs)"
				local text 0.045 11 
				local yvar svgeb_aus
				local ylabel "-0.1 (0.05) 0.05"
			}
			
			// Specify tempfile to store lincom results
			tempname memhold
			tempfile results
			postfile `memhold' testrun estimate ll ul using "`results'"

			local i = 0	
	   
			reghdfe `depvar' treatment_??? c.time#i.east ///
					i.time#c.pop_share_1864_2013#i.east ///
					c.time#c.empl_share_publ_2013#i.east ///
					c.time#c.empl_share_manutot_2013#i.east ///
					c.time#c.empl_share_trade_2013#i.east ///
					c.time#c.empl_share_agric_2013#i.east [aw=weight_pop13] ///
					`cond',	absorb(amr amr_typ#time#east) cluster(amr)

			// Foreach level of variable, perform lincom and save b, sd, df_r
			local i = 1
			foreach l of local treat_list {
				noi post `memhold' (`i') (_b[`l']) (_b[`l'] - invttail(e(df_r),0.025)*_se[`l']) (_b[`l'] + invttail(e(df_r),0.025)*_se[`l'])
				local i = `i' + 1
			} // foreach l
			
			postclose `memhold'

			preserve

			use "`results'", clear
			
			expand 2 if testrun == 1, gen(exp)
			replace estimate = 0 if exp == 1
			replace ul = 0 if exp == 1 
			replace ll = 0 if exp == 1
			sort testrun exp
			gen year = _n
			replace year = year * 3

			noi tw (rcap ul ll year, lc(gs10) lwidth(thin) lcolor(black)) ///
			   (scatter estimate year, lcolor(black) mcolor(black) m(o)), ///
				title(`title', color(black) size(medium)) xtitle("Time") ylabel(`ylabel', nogrid) ///
				xline(6.25, lpattern(dash)) xline(7.5, lpattern(solid)) yline(0, lcolor(black)) ///
				xlabel(3 "6/2013" 6 "6/2014" 9 "6/2015" 12 "6/2016", angle(90) labsize(small)) /// 
				legend(order(2 1) pos(6) rows(1) label(1 "95% Confidence Interval") label(2 "Point Estimate") ///
				size(small)) ytitle("Point Estimate") text(`text')
			graph export "graphs/`depvar'_dyn.pdf", replace as(pdf) 	
			restore		
						
		}
	}
}

****
