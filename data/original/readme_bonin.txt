**************
*** README ***
**************

This file describes how the results presented in the following article can be replicated:

The German Statutory Minimum Wage and Its Effects on Regional Employment and Unemployment
(Holger Bonin, Ingo E. Isphording, Annabelle Krause-Pilatus, Andreas Lichter, Nico Pestel and Ulf Rinne)
Journal of Economics and Statistics 2019
https://doi.org/10.1515/jbnst-2018-0067


*** Data file and Code ***

The datafile used is "mlk_amr_panel.csv". The dataset contains panel data on 257 labor market regions in Germany for 16 quarters from Q1/2013 to Q4/2016 (N=4112). The results are produced by a Stata do-file: "replication_bonin_etal2019.do".


*** Data sources ***

The data were collected from the following sources:

1. Structure of Earnings Survey 2014 (SES 2014) of the Federal Statistical Office (Verdienststrukturerhebung 2014).
2. Federal Employment Agency Statistics (Statistik der Bundesagentur für Arbeit, BA-Statistik).
3. Federal Institute for Research on Building, Urban Affairs and Spatial Development (Bundesinstitut für Bau-, Stadt- und Raumforschung, BBSR) 
4. Federal Statistical Office (Destatis).



*** Variable list ***

Variable name 		Description

amr			AMR: Arbeitsmarktregion
amr_name		AMR: Arbeitsmarktregion (Name)
amr_N_kreise		AMR: Anzahl Kreise
amr_flaeche		AMR: Fläche
amr_pop			AMR: Bevölkerung
amr_typ			AMR: Siedlungsstrukturtyp
east			Ostdeutschland
time			Monat-Jahr
timeQ			Quartal-Jahr
timeH			Halbjahr-Jahr
year			Jahr
month			Kalendermonat
post15			Zeitpunkt nach 1.1.2015
post14			Zeitpunkt nach 30.6.2014
weight_pop13		Gewicht: Bevölkerung 18-64 (31.12.2013, in 1.000)
weight_work14		Gewicht: Beschäftigte VSE (April 2014, in 1.000)
mw_aff			Anteil Beschäftigte unter 8,50 Euro
mw_luecke		Wage Gap
mw_kaitz_mean		Kaitz-Index zum Durchschnittslohn
mw_kaitz_p50		Kaitz-Index zum Median-Lohn
mw_aff_g2		Anteil Beschäftigte unter 8,50 Euro (Dummy Median)
mw_luecke_g2		Wage Gap (Dummy Median)
mw_kaitz_mean_g2 	Kaitz-Index zum Durchschnittslohn (Dummy Median)
mw_kaitz_p50_g2		Kaitz-Index zum Median-Lohn (Dummy Median)
pop_totalle		Bevölkerung gesamt (31.12.)
pop_tot18_64		Bevölkerung 18 bis 64 Jahre (31.12.)
pop_tot18_34		Bevölkerung 18 bis 34 Jahre (31.12.)
pop_tot35_64		Bevölkerung 35 bis 64 Jahre (31.12.)
pop_share_1864_2013	Anteil Bevölkerung 18-64 (31.12.2013, in %)
empl_share_agric_2013	Anteil Erwerbstätige Landwirtschaft (in %)
empl_share_trade_2013	Anteil Erwerbstätige Handel etc. (in %)
empl_share_finan_2013	Anteil Erwerbstätige Finanzen etc. (in %)
empl_share_publ_2013	Anteil Erwerbstätige öffentlicher Dienst etc. (in %)
empl_share_manutot_2013	Anteil Erwerbstätige Produzierendes Gewerbe (in %)
svb_total		SV-Beschäftigte (AO): insgesamt
svb_m			SV-Beschäftigte (AO): Männer
svb_f			SV-Beschäftigte (AO): Frauen
svb_foreign		SV-Beschäftigte (AO): Ausländer
svb_age025		SV-Beschäftigte (AO): unter 25 Jahre
svb_educnon		SV-Beschäftigte (AO): ohne berufliche Ausbildung
svb_age50plus		SV-Beschäftigte (AO): 50 Jahre und älter
geb_total		Geringfügig Beschäftigte (AO): insgesamt
geb_ausschl		Geringfügig Beschäftigte (AO): ausschließlich
svgeb_total		SV- und Geringfügig Beschäftigte: insgesamt
al_abs_insg_tot		Arbeitslose: insgesamt (absolut) (Rechtskreis: alle)
al_abs_m_tot		Arbeitslose: Männer (Rechtskreis: alle)
al_abs_f_tot		Arbeitslose: Frauen (Rechtskreis: alle)
al_abs_15_25_tot	Arbeitslose: Alter 15 bis unter 25 (Rechtskreis: alle)
al_abs_55_65_tot	Arbeitslose: Alter 55 bis unter 65 (Rechtskreis: alle)
al_abs_auslaender_tot	Arbeitslose: Ausländer (Rechtskreis: alle)
log_svb_total		Log. SV-Beschäftigte (AO): insgesamt
log_svb_m		Log. SV-Beschäftigte (AO): Männer
log_svb_f		Log. SV-Beschäftigte (AO): Frauen
log_svb_foreign		Log. SV-Beschäftigte (AO): Ausländer
log_svb_age025		Log. SV-Beschäftigte (AO): unter 25 Jahre
log_svb_educnon		Log. SV-Beschäftigte (AO): ohne berufliche Ausbildung
log_svb_age50plus	Log. SV-Beschäftigte (AO): 50 Jahre und älter
log_geb_total		Log. Geringfügig Beschäftigte (AO): insgesamt
log_geb_ausschl		Log. Geringfügig Beschäftigte (AO): ausschließlich
log_svgeb_total		Log. SV- und Geringfügig Beschäftigte: insgesamt
log_al_abs_insg_tot	Log. Arbeitslose: insgesamt (absolut) (Rechtskreis: alle)
log_al_abs_m_tot	Log. Arbeitslose: Männer (Rechtskreis: alle)
log_al_abs_f_tot	Log. Arbeitslose: Frauen (Rechtskreis: alle)
log_al_abs_15_25_tot	Log. Arbeitslose: Alter 15 bis unter 25 (Rechtskreis: alle)
log_al_abs_55_65_tot	Log. Arbeitslose: Alter 55 bis unter 65 (Rechtskreis: alle)
log_al_abs_auslaender_tot	Log. Arbeitslose: Ausländer (Rechtskreis: alle)
log_pop_totalle		Log. Bevölkerung gesamt (31.12.)
log_pop_tot18_64	Log. Bevölkerung 18 bis 64 Jahre (31.12.)
log_pop_tot18_34	Log. Bevölkerung 18 bis 34 Jahre (31.12.)
log_pop_tot35_64	Log. Bevölkerung 35 bis 64 Jahre (31.12.)
gr_svb_total		Wachstumsrate: SV-Beschäftigte (AO): insgesamt in %
gr_svb_m		Wachstumsrate: SV-Beschäftigte (AO): Männer in %
gr_svb_f		Wachstumsrate: SV-Beschäftigte (AO): Frauen in %
gr_svb_foreign		Wachstumsrate: SV-Beschäftigte (AO): Ausländer in %
gr_svb_age025		Wachstumsrate: SV-Beschäftigte (AO): unter 25 Jahre in %
gr_svb_educnon		Wachstumsrate: SV-Beschäftigte (AO): ohne berufliche Ausbildung in %
gr_svb_age50plus	Wachstumsrate: SV-Beschäftigte (AO): 50 Jahre und älter in %
gr_geb_total		Wachstumsrate: Geringfügig Beschäftigte (AO): insgesamt in %
gr_geb_ausschl		Wachstumsrate: Geringfügig Beschäftigte (AO): ausschließlich in %
gr_svgeb_total		Wachstumsrate: SV- und Geringfügig Beschäftigte: insgesamt in %
gr_al_abs_insg_tot	Wachstumsrate: Arbeitslose: insgesamt (absolut) (Rechtskreis: alle) in %
gr_al_abs_m_tot		Wachstumsrate: Arbeitslose: Männer (Rechtskreis: alle) in %
gr_al_abs_f_tot		Wachstumsrate: Arbeitslose: Frauen (Rechtskreis: alle) in %
gr_al_abs_15_25_tot	Wachstumsrate: Arbeitslose: Alter 15 bis unter 25 (Rechtskreis: alle) in %
gr_al_abs_55_65_tot	Wachstumsrate: Arbeitslose: Alter 55 bis unter 65 (Rechtskreis: alle) in %
gr_al_abs_auslaender_tot	Wachstumsrate: Arbeitslose: Ausländer (Rechtskreis: alle) in %
gr_pop_totalle		Wachstumsrate: Bevölkerung gesamt (31.12.) in %
gr_pop_tot18_64		Wachstumsrate: Bevölkerung 18 bis 64 Jahre (31.12.) in %
gr_pop_tot18_34		Wachstumsrate: Bevölkerung 18 bis 34 Jahre (31.12.) in %
gr_pop_tot35_64		Wachstumsrate: Bevölkerung 35 bis 64 Jahre (31.12.) in %
