
/*****************************************************************************************************/
/** 	VB, VB + Booster / case rates and age adjustment											**/
/**															  				   						**/
/** 	Evaluates mRNA and JJ Vaccine Additional Doses, mRNA and 									**/
/**		Update: data for slides for Gov slides & vaccine breakthrough dashboard						**/
/**																									**/
/**     Uses cedrs_view to capture cases															**/
/**																									**/															   
/** 																								**/
/**		Written by: M. Pike, January 11, 2022														**/
/**																									**/

/*****************************************************************************************************/


libname newcedrs odbc dsn='CEDRS_3_read' schema=CEDRS 	READ_LOCK_TYPE=NOLOCK;
libname tableau odbc dsn='Tableau' schema=ciis 			READ_LOCK_TYPE=NOLOCK; 
libname severson odbc dsn='Tableau' schema=dbo			READ_LOCK_TYPE=NOLOCK; 
libname archive3 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Vaccine Breakthrough\07_Data\archive3'; 
libname archive4 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Vaccine Breakthrough\07_Data\archive4'; 
run;


PROC SQL;
   CREATE TABLE WORK.FILTER_FOR_CEDRS_VIEW AS 
   SELECT t1.eventid, 
          t1.age_at_reported, 
          t1.collectiondate, 
          t1.earliest_collectiondate, 
          t1.vax_firstdose, 
          t1.vax_utd, 
		  t1.vaccine_received,
          t1.breakthrough, 
          t1.breakthrough_booster, 
          t1.vax_booster, 
          t1.hospitalized_cophs, 
		  t1.cophs_admissiondate,
		  t1.datevsdeceased,
          t1.deathdueto_vs_u071
      FROM SEVERSON.cedrs_view t1;
QUIT;


/*Create a file with both VB and VBB cases*/; 

DATA VB_VBB_analysis_test;
	set WORK.FILTER_FOR_CEDRS_VIEW;

	if age_at_reported >= 12 and age_at_reported  <= 19 then agegrp = '12-19';
		else if age_at_reported  >= 20 and age_at_reported  <= 29 then agegrp = '20-29';
		else if age_at_reported  >= 30 and age_at_reported  <= 39 then agegrp = '30-39';
		else if age_at_reported  >= 40 and age_at_reported  <= 49 then agegrp = '40-49';
		else if age_at_reported  >= 50 and age_at_reported  <= 59 then agegrp = '50-59';
		else if age_at_reported  >= 60 and age_at_reported  <= 69 then agegrp = '60-69';
		else if age_at_reported  >= 70 and age_at_reported  <= 79 then agegrp = '70-79';
		else if age_at_reported  >= 80 then agegrp = '80+';
		else if age_at_reported  <= 11 then delete; 

	Test_date = input(earliest_collectiondate, yymmdd10.); /*create sas date from character format*/
	month_test = month(test_date); /*extract month*/
	vax_date = input(vax_booster, yymmdd10.); /*create sas date from character format*/

	vb_day_duration = test_date - vax_date; /*find the difference between the dates for filtering those who meet VBB case definition*/

	if breakthrough = 1 and vax_booster = '' then boosted_case = 0; /*vaccinated cases that have not recieved a third dose*/
		else if breakthrough = 1 and vax_booster < '2021-08-13' then boosted_case = 0; /*vaccinated cases who recieved a third dose before CDC dates*/;

	if breakthrough = 1 and vax_booster >= '2021-08-13' and vb_day_duration >= 14 then boosted_case = 1; /*definition for breakthrough boosted cases*/;
	if breakthrough = 0 then delete; /*these are the unvaccinated*/

	if boosted_case = . then boosted_case = 0; /*these are cases that are outside the vb_day_duration filter that return a missing value*/
	

RUN; 

/*VB, No Booster Cases */;

DATA work.VB_NoBooster_144_Cases;
	set VB_VBB_analysis_test;

	if breakthrough = 1 and boosted_case = 0 then output;

RUN; 

PROC SORT data=work.vb_nobooster_144_cases nodup; 
	by eventid;
RUN; 

PROC FREQ data=work.vb_nobooster_144_cases; 
	tables breakthrough; 
RUN; 


PROC FREQ data=work.VB_NoBooster_144_Cases;
	tables agegrp*month_test / out=work.freqct_nobo nocol nocum norow nopercent; 
RUN;


/*VB, No Booster Population: Denominator*/;

/*AUGUST*/

PROC SQL;
   CREATE TABLE WORK.FILTER_FOR_VAXUNVAX_VB_AUG AS 
   SELECT t1.age, 
          t1.date, 
          t1.cumulative_fullyvaxed_nobooster, 
          t1.population, 
          t1.type
      FROM TABLEAU.vaxunvax_nobooster t1
      WHERE t1.type = 'Fully vaccinated and did not receive additional dose on or after August 13' AND t1.date = '2021-08-15';
QUIT;

DATA Pop_Fully_Vax_NoDose_AUG;
	Set WORK.FILTER_FOR_VAXUNVAX_VB_AUG;

	if age >= 12 and age <= 19 then agegrp = '12-19';
		else if age >= 20 and age <= 29 then agegrp = '20-29';
		else if age >= 30 and age <= 39 then agegrp = '30-39';
		else if age >= 40 and age <= 49 then agegrp = '40-49';
		else if age >= 50 and age <= 59 then agegrp = '50-59';
		else if age >= 60 and age <= 69 then agegrp = '60-69';
		else if age >= 70 and age <= 79 then agegrp = '70-79';
		else if age >= 80 then agegrp = '80+';
		else if age <= 11 then delete; 

RUN; 

PROC SQL; 

	create table popfully_vax_nodose_815 as
 	select 	type,
			date, 
			agegrp, 
			cumulative_fullyvaxed_nobooster, 
          	population, 

	sum(cumulative_fullyvaxed_nobooster) as Sum_vaxed_nobooster
	,sum(population) as Sum_population

	FROM work.pop_fully_vax_nodose_aug
	GROUP BY agegrp;
QUIT; 

DATA pop_Vax_no_dose_815;
	set popfully_vax_nodose_815;
	by agegrp;
 
	keep date agegrp type Sum_vaxed_nobooster; 

	if first.agegrp then output; 

RUN; 


/*SEPT*/;

PROC SQL;
   CREATE TABLE WORK.FILTER_FOR_VAXUNVAX_VB_SEPT AS 
   SELECT t1.age, 
          t1.date, 
          t1.cumulative_fullyvaxed_nobooster, 
          t1.population, 
          t1.type
      FROM TABLEAU.vaxunvax_nobooster t1
      WHERE t1.type = 'Fully vaccinated and did not receive additional dose on or after August 13' AND t1.date = '2021-09-15';
QUIT;

DATA Pop_Fully_Vax_NoDose_SEPT;
	Set WORK.FILTER_FOR_VAXUNVAX_VB_SEPT;

	if age >= 12 and age <= 19 then agegrp = '12-19';
		else if age >= 20 and age <= 29 then agegrp = '20-29';
		else if age >= 30 and age <= 39 then agegrp = '30-39';
		else if age >= 40 and age <= 49 then agegrp = '40-49';
		else if age >= 50 and age <= 59 then agegrp = '50-59';
		else if age >= 60 and age <= 69 then agegrp = '60-69';
		else if age >= 70 and age <= 79 then agegrp = '70-79';
		else if age >= 80 then agegrp = '80+';
		else if age <= 11 then delete; 

RUN; 

PROC SQL; 

	create table popfully_vax_nodose_915 as

 	select 	type,
			date, 
			agegrp, 
			cumulative_fullyvaxed_nobooster, 
          	population, 

	sum(cumulative_fullyvaxed_nobooster) as Sum_vaxed_nobooster
	,sum(population) as Sum_population

	FROM work.pop_fully_vax_nodose_sept
	GROUP BY agegrp;
QUIT; 

DATA pop_Vax_no_dose_915;
	set popfully_vax_nodose_915;
	by agegrp;
 
	
	keep date agegrp type Sum_vaxed_nobooster; 

	if first.agegrp then output; 

RUN; 

/*OCTOBER */;

PROC SQL;
   CREATE TABLE WORK.FILTER_FOR_VAXUNVAX_VB_OCT AS 
   SELECT t1.age, 
          t1.date, 
          t1.cumulative_fullyvaxed_nobooster, 
          t1.population, 
          t1.type
      FROM TABLEAU.vaxunvax_nobooster t1
      WHERE t1.type = 'Fully vaccinated and did not receive additional dose on or after August 13' AND t1.date = '2021-10-15';
QUIT;

DATA Pop_Fully_Vax_NoDose_OCT;
	Set WORK.FILTER_FOR_VAXUNVAX_VB_OCT;

	if age >= 12 and age <= 19 then agegrp = '12-19';
		else if age >= 20 and age <= 29 then agegrp = '20-29';
		else if age >= 30 and age <= 39 then agegrp = '30-39';
		else if age >= 40 and age <= 49 then agegrp = '40-49';
		else if age >= 50 and age <= 59 then agegrp = '50-59';
		else if age >= 60 and age <= 69 then agegrp = '60-69';
		else if age >= 70 and age <= 79 then agegrp = '70-79';
		else if age >= 80 then agegrp = '80+';
		else if age <= 11 then delete; 

RUN; 

PROC SQL; 

	create table popfully_vax_nodose_1015 as
 
 	select 	type,
			date, 
			agegrp, 
			cumulative_fullyvaxed_nobooster, 
          	population, 

	sum(cumulative_fullyvaxed_nobooster) as Sum_vaxed_nobooster
	,sum(population) as Sum_population

	FROM work.pop_fully_vax_nodose_oct
	GROUP BY agegrp;
QUIT; 

DATA pop_Vax_no_dose_1015;
	set popfully_vax_nodose_1015;
	by agegrp;
 
	keep date agegrp type Sum_vaxed_nobooster; 

	if first.agegrp then output; 

RUN; 


/*NOVEMBER */;

PROC SQL;
   CREATE TABLE WORK.FILTER_FOR_VAXUNVAX_VB_NOV AS 
   SELECT t1.age, 
          t1.date, 
          t1.cumulative_fullyvaxed_nobooster, 
          t1.population, 
          t1.type
      FROM TABLEAU.vaxunvax_nobooster t1
      WHERE t1.type = 'Fully vaccinated and did not receive additional dose on or after August 13' AND t1.date = '2021-11-15';
QUIT;

DATA Pop_Fully_Vax_NoDose_NOV;
	Set WORK.FILTER_FOR_VAXUNVAX_VB_NOV;

	if age >= 12 and age <= 19 then agegrp = '12-19';
		else if age >= 20 and age <= 29 then agegrp = '20-29';
		else if age >= 30 and age <= 39 then agegrp = '30-39';
		else if age >= 40 and age <= 49 then agegrp = '40-49';
		else if age >= 50 and age <= 59 then agegrp = '50-59';
		else if age >= 60 and age <= 69 then agegrp = '60-69';
		else if age >= 70 and age <= 79 then agegrp = '70-79';
		else if age >= 80 then agegrp = '80+';
		else if age <= 11 then delete; 

RUN; 

PROC SQL; 

	create table popfully_vax_nodose_1115 as

 	select 	type,
			date, 
			agegrp, 
			cumulative_fullyvaxed_nobooster, 
          	population, 

	sum(cumulative_fullyvaxed_nobooster) as Sum_vaxed_nobooster
	,sum(population) as Sum_population

	FROM work.pop_fully_vax_nodose_Nov
	GROUP BY agegrp;
QUIT; 

DATA work.pop_Vax_no_dose_1115;
	set popfully_vax_nodose_1115;
	by agegrp;
 
	keep date agegrp type Sum_vaxed_nobooster; 

	if first.agegrp then output; 

RUN; 

/*DECEMBER */;

PROC SQL;
   CREATE TABLE WORK.FILTER_FOR_VAXUNVAX_VB_DEC AS 
   SELECT t1.age, 
          t1.date, 
          t1.cumulative_fullyvaxed_nobooster, 
          t1.population, 
          t1.type
      FROM TABLEAU.vaxunvax_nobooster t1
      WHERE t1.type = 'Fully vaccinated and did not receive additional dose on or after August 13'  AND t1.date = '2021-12-15';
QUIT;

DATA Pop_Fully_Vax_NoDose_DEC;
	Set WORK.FILTER_FOR_VAXUNVAX_VB_DEC;

	if age >= 12 and age <= 19 then agegrp = '12-19';
		else if age >= 20 and age <= 29 then agegrp = '20-29';
		else if age >= 30 and age <= 39 then agegrp = '30-39';
		else if age >= 40 and age <= 49 then agegrp = '40-49';
		else if age >= 50 and age <= 59 then agegrp = '50-59';
		else if age >= 60 and age <= 69 then agegrp = '60-69';
		else if age >= 70 and age <= 79 then agegrp = '70-79';
		else if age >= 80 then agegrp = '80+';
		else if age <= 11 then delete; 

RUN; 

PROC SQL; 

	create table popfully_vax_nodose_1215 as
 
	select 	type,
			date, 
			agegrp, 
			cumulative_fullyvaxed_nobooster, 
          	population, 

	sum(cumulative_fullyvaxed_nobooster) as Sum_vaxed_nobooster
	,sum(population) as Sum_population

	FROM work.pop_fully_vax_nodose_DEC
	GROUP BY agegrp;
QUIT; 

DATA work.pop_Vax_no_dose_1215;
	set popfully_vax_nodose_1215;
	by agegrp;
 
	keep date agegrp type Sum_vaxed_nobooster; 

	if first.agegrp then output; 

RUN; 


/*COMBINE INTO ONE FILE*/;

DATA archive4.Pop_VB_NoDose_ADJ; 
	set work.pop_Vax_no_dose_815
		work.pop_Vax_no_dose_915
		work.pop_Vax_no_dose_1015
		work.pop_Vax_no_dose_1115
		work.pop_Vax_no_dose_1215; 

	Month = input(date, yymmdd10.);
	month_test = month(month);

	drop date month;
RUN; 


/*LEFT JOIN, Cases and population data*/;

PROC SQL;
create table vaccinated_popcase
as select distinct *
	from work.freqct_nobo v
	left join archive4.Pop_VB_NoDose_ADJ e on v.month_test = e.month_test and v.agegrp = e.agegrp

	order by v.month_test

;
quit;



Data vaccinated_popcase_144;
	set vaccinated_popcase;

	cases_per100k = ((count/Sum_vaxed_nobooster)*100000); 
	
	if  agegrp = '12-19' 		 then weight = 0.12150;
		else if agegrp = '20-29' then weight = 0.16959;
		else if agegrp = '30-39' then weight = 0.17013;
		else if agegrp = '40-49' then weight = 0.15005;
		else if agegrp = '50-59' then weight = 0.14357;
		else if agegrp = '60-69' then weight = 0.12932;
		else if agegrp = '70-79' then weight = 0.07780;
		else if agegrp = '80+' 	 then weight = 0.03800;

	cases_wt = cases_per100k*weight;

	if month_test < 8 then delete;

	drop percent ;

RUN;



PROC SQL; 

	create table AA_144_Vax_Nobo_rates as
 
	select 	type,
			month_test,
			cases_wt

	,sum(cases_wt) as AgeAdj_rate_VB
	
	FROM vaccinated_popcase_144
	GROUP BY month_test;
QUIT; 


DATA AA_144_Vax_Nobo_rates;
	set AA_144_Vax_Nobo_rates;
	by month_test;
 
	keep type2 month_test AgeAdj_rate_VB; 

	type2 = 'vaccinated_nobo_cases';

	if first.month_test then output; 

RUN; 



/*HOSPITAL */; 

DATA VB_NoBo_144_ADJ_HOS;
	set work.VB_NoBooster_144_Cases; 

	Hosp_date = input(cophs_admissiondate, yymmdd10.);
	month_hosp = month(hosp_date);
	month_test = month_hosp;

	if hospitalized_cophs = 1 then output;

RUN; 

PROC FREQ data=VB_NoBo_144_ADJ_HOS;
	tables agegrp*month_test / out=work.hosp_freqct_nobo nocol nocum norow nopercent; 
RUN;


/*LEFT JOIN, Cases and population data*/;

PROC SQL;
create table vax_hosp_popcase
as select distinct *
	from work.hosp_freqct_nobo v
	left join archive4.Pop_VB_NoDose_ADJ e on v.month_test = e.month_test and v.agegrp = e.agegrp

	order by v.month_test

;
quit;


Data vax_hosp_popcase_144;
	set vax_hosp_popcase;

	cases_per100k = ((count/Sum_vaxed_nobooster)*100000); 
	
	if  agegrp = '12-19' 		 then weight = 0.12150;
		else if agegrp = '20-29' then weight = 0.16959;
		else if agegrp = '30-39' then weight = 0.17013;
		else if agegrp = '40-49' then weight = 0.15005;
		else if agegrp = '50-59' then weight = 0.14357;
		else if agegrp = '60-69' then weight = 0.12932;
		else if agegrp = '70-79' then weight = 0.07780;
		else if agegrp = '80+' 	 then weight = 0.03800;

	cases_wt = cases_per100k*weight;

	if month_test < 8 then delete;

	drop percent ;

RUN;



PROC SQL; 

	create table AA_144_Vax_Nobo_hos_rte as
 
	select 	type,
			month_test,
			cases_wt

	,sum(cases_wt) as AgeAdj_rate_VB
	
	FROM vax_hosp_popcase_144
	GROUP BY month_test;
QUIT; 


DATA AA_144_Vax_Nobo_hos_rte;
	set AA_144_Vax_Nobo_hos_rte;
	by month_test;
 
	keep type2 month_test AgeAdj_rate_VB; 

	type2 = 'vax_nobo_hosp_rate';

	if first.month_test then output; 

RUN; 



/*DEATHS, Vax no Booster*/;

DATA VB_NoBo_144_ADJ_Death;
	set work.VB_NoBooster_144_Cases; 

	Death_date = input(datevsdeceased, yymmdd10.);
	month_death = month(death_date);
	month_test = month_death;

	if deathdueto_vs_u071 = 1 then output;

RUN; 


PROC FREQ data=VB_NoBo_144_ADJ_Death;
	tables agegrp*month_test / out=work.dead_freqct_nobo nocol nocum norow nopercent; 
RUN;


/*LEFT JOIN, Cases and population data*/;

PROC SQL;
create table vax_dead_popcase
as select distinct *
	from work.dead_freqct_nobo v
	left join archive4.Pop_VB_NoDose_ADJ e on v.month_test = e.month_test and v.agegrp = e.agegrp

	order by v.month_test

;
quit;


Data vax_dead_popcase_144;
	set vax_dead_popcase;

	cases_per1M = ((count/Sum_vaxed_nobooster)*1000000); 
	
	if  agegrp = '12-19' 		 then weight = 0.12150;
		else if agegrp = '20-29' then weight = 0.16959;
		else if agegrp = '30-39' then weight = 0.17013;
		else if agegrp = '40-49' then weight = 0.15005;
		else if agegrp = '50-59' then weight = 0.14357;
		else if agegrp = '60-69' then weight = 0.12932;
		else if agegrp = '70-79' then weight = 0.07780;
		else if agegrp = '80+' 	 then weight = 0.03800;

	cases_wt = cases_per1M*weight;

	if month_test <8 then delete;

	drop percent ;

RUN;



PROC SQL; 

	create table AA_144_Vax_Nobo_dead_rte as
 
	select 	type,
			month_test,
			cases_wt

	,sum(cases_wt) as AgeAdj_rate_VB
	
	FROM vax_dead_popcase_144
	GROUP BY month_test;
QUIT; 


DATA AA_144_Vax_Nobo_dead_rte;
	set AA_144_Vax_Nobo_dead_rte;
	by month_test;
 
	keep type2 month_test AgeAdj_rate_VB; 

	type2 = 'vax_nobo_death_rate';

	if first.month_test then output; 

RUN; 


DATA archive4.AA_144_Vax_NoBo_All;
	set work.AA_144_Vax_Nobo_rates
		work.AA_144_Vax_Nobo_hos_rte
		work.AA_144_Vax_Nobo_dead_rte; 
RUN;



/**********************************************************************************************/;

/*VB, with Booster Cases */;

DATA VB_Booster_144_cases;
	set work.VB_VBB_analysis_test;

	if boosted_case = 1 then output;

RUN; 

PROC SORT data=vb_booster_144_cases nodup; 
	by eventid;
RUN; 


PROC FREQ data=work.VB_Booster_144_Cases;
	tables agegrp*month_test / out=work.freqct_vbb nocol nocum norow nopercent; 
RUN;


/*VB, with Booster Population (denominator)*/; 

/*AUGUST*/;

PROC SQL;
   CREATE TABLE WORK.FILTER_FOR_VAXUNVAX_VB_AUG2 AS 
   SELECT t1.age, 
          t1.date,
		  t1.cumulative_received_booster,
          t1.type
      FROM TABLEAU.vaxunvax_aug13booster t1
      WHERE t1.type = 'Received additional dose on or after August 13' AND t1.date = '2021-08-15';
QUIT;

DATA PopFully_Vax_BSTR_AUG;
	Set WORK.FILTER_FOR_VAXUNVAX_VB_AUG2;

	if age >= 12 and age <= 19 then agegrp = '12-19';
		else if age >= 20 and age <= 29 then agegrp = '20-29';
		else if age >= 30 and age <= 39 then agegrp = '30-39';
		else if age >= 40 and age <= 49 then agegrp = '40-49';
		else if age >= 50 and age <= 59 then agegrp = '50-59';
		else if age >= 60 and age <= 69 then agegrp = '60-69';
		else if age >= 70 and age <= 79 then agegrp = '70-79';
		else if age >= 80 then agegrp = '80+';
		else if age <= 11 then delete; 
RUN;


PROC SQL; 

	create table popfullyvax_bster_aug as
 
	select 	type,
			date, 
			agegrp, 
			cumulative_received_booster

	,sum(cumulative_received_booster) as Sum_received_booster

	FROM work.PopFully_Vax_BSTR_AUG
	GROUP BY agegrp;
QUIT;  

DATA popfullyvax_Booster_Aug;
	set popfullyvax_bster_aug;
	by agegrp;
 
	keep date agegrp type Sum_received_booster; 

	month = 8; 

	if first.agegrp then output; 

RUN; 



/*SEPT*/;

PROC SQL;
   CREATE TABLE WORK.FILTER_FOR_VAXUNVAX_VB_SEPT2 AS 
    SELECT t1.age, 
          t1.date, 
		  t1.cumulative_received_booster,
          t1.type
      FROM TABLEAU.vaxunvax_aug13booster t1
      WHERE t1.type = 'Received additional dose on or after August 13' AND t1.date = '2021-09-15';
QUIT;

DATA PopFully_Vax_BSTR_SEPT;
	Set WORK.FILTER_FOR_VAXUNVAX_VB_SEPT2;

		if age >= 12 and age <= 19 then agegrp = '12-19';
		else if age >= 20 and age <= 29 then agegrp = '20-29';
		else if age >= 30 and age <= 39 then agegrp = '30-39';
		else if age >= 40 and age <= 49 then agegrp = '40-49';
		else if age >= 50 and age <= 59 then agegrp = '50-59';
		else if age >= 60 and age <= 69 then agegrp = '60-69';
		else if age >= 70 and age <= 79 then agegrp = '70-79';
		else if age >= 80 then agegrp = '80+';
		else if age <= 11 then delete; 

RUN;


PROC SQL; 

	create table popfullyvax_bster_sept as
 
	select 	type,
			date, 
			agegrp,
			cumulative_received_booster,
	
	sum(cumulative_received_booster) as Sum_received_booster

	FROM work.PopFully_Vax_BSTR_sept
	GROUP BY agegrp;
QUIT;  

DATA popfullyvax_Booster_sept;
	set popfullyvax_bster_sept;
	by agegrp;
 
	keep date agegrp type Sum_received_booster; 

	month = 9;

	if first.agegrp then output; 

RUN; 

/*OCT*/;

PROC SQL;
 CREATE TABLE WORK.FILTER_FOR_VAXUNVAX_VB_OCT2 AS 
 SELECT t1.age, 
          t1.date, 
		  t1.cumulative_received_booster,
          t1.type
      FROM TABLEAU.vaxunvax_aug13booster t1
      WHERE t1.type = 'Received additional dose on or after August 13' AND t1.date = '2021-10-15';
QUIT;

DATA PopFully_Vax_BSTR_OCT;
	Set WORK.FILTER_FOR_VAXUNVAX_VB_OCT2;

	if age >= 12 and age <= 19 then agegrp = '12-19';
		else if age >= 20 and age <= 29 then agegrp = '20-29';
		else if age >= 30 and age <= 39 then agegrp = '30-39';
		else if age >= 40 and age <= 49 then agegrp = '40-49';
		else if age >= 50 and age <= 59 then agegrp = '50-59';
		else if age >= 60 and age <= 69 then agegrp = '60-69';
		else if age >= 70 and age <= 79 then agegrp = '70-79';
		else if age >= 80 then agegrp = '80+';
		else if age <= 11 then delete;  

RUN;


PROC SQL; 

	create table popfullyvax_bster_oct as

	select 	type,
			date, 
			agegrp, 
			cumulative_received_booster,

	sum(cumulative_received_booster) as Sum_received_booster

	FROM work.PopFully_Vax_BSTR_oct
	GROUP BY agegrp;
QUIT;  

DATA popfullyvax_Booster_oct;
	set popfullyvax_bster_oct;
	by agegrp;
 
	keep date agegrp type Sum_received_booster; 

	month = 10;

	if first.agegrp then output; 

RUN; 


/*NOV*/;

PROC SQL;
  CREATE TABLE WORK.FILTER_FOR_VAXUNVAX_VB_NOV2 AS 
  SELECT t1.age, 
          t1.date, 
		  t1.cumulative_received_booster,
          t1.type
      FROM TABLEAU.vaxunvax_aug13booster t1
      WHERE t1.type = 'Received additional dose on or after August 13' AND t1.date = '2021-11-15';
QUIT;

DATA PopFully_Vax_BSTR_NOV;
	Set WORK.FILTER_FOR_VAXUNVAX_VB_NOV2;

	if age >= 12 and age <= 19 then agegrp = '12-19';
		else if age >= 20 and age <= 29 then agegrp = '20-29';
		else if age >= 30 and age <= 39 then agegrp = '30-39';
		else if age >= 40 and age <= 49 then agegrp = '40-49';
		else if age >= 50 and age <= 59 then agegrp = '50-59';
		else if age >= 60 and age <= 69 then agegrp = '60-69';
		else if age >= 70 and age <= 79 then agegrp = '70-79';
		else if age >= 80 then agegrp = '80+';
		else if age <= 11 then delete; 

RUN;


PROC SQL; 

	create table popfullyvax_bster_nov as

	select 	type,
			date, 
			agegrp, 
			cumulative_received_booster,

	sum(cumulative_received_booster) as Sum_received_booster

	FROM work.PopFully_Vax_BSTR_nov
	GROUP BY agegrp;
QUIT;  

DATA popfullyvax_Booster_nov;
	set popfullyvax_bster_nov;
	by agegrp;

 	keep date agegrp type Sum_received_booster; 

	month = 11; 

	if first.agegrp then output; 

RUN; 


/*DEC*/;

PROC SQL;
   CREATE TABLE WORK.FILTER_FOR_VAXUNVAX_VB_DEC2 AS 
	SELECT t1.age, 
          t1.date, 
		  t1.cumulative_received_booster,
          t1.type
      FROM TABLEAU.vaxunvax_aug13booster t1
      WHERE t1.type = 'Received additional dose on or after August 13' AND t1.date = '2021-12-15';
QUIT;

DATA PopFully_Vax_BSTR_DEC;
	Set WORK.FILTER_FOR_VAXUNVAX_VB_DEC2;

	if age >= 12 and age <= 19 then agegrp = '12-19';
		else if age >= 20 and age <= 29 then agegrp = '20-29';
		else if age >= 30 and age <= 39 then agegrp = '30-39';
		else if age >= 40 and age <= 49 then agegrp = '40-49';
		else if age >= 50 and age <= 59 then agegrp = '50-59';
		else if age >= 60 and age <= 69 then agegrp = '60-69';
		else if age >= 70 and age <= 79 then agegrp = '70-79';
		else if age >= 80 then agegrp = '80+';
		else if age <= 11 then delete; 

RUN;


PROC SQL; 

	create table popfullyvax_bster_dec as
 
	select 	type,
			date, 
			agegrp, 
			cumulative_received_booster,

	sum(cumulative_received_booster) as Sum_received_booster

	FROM work.PopFully_Vax_BSTR_dec
	GROUP BY agegrp;
QUIT;  

DATA popfullyvax_Booster_dec;
	set popfullyvax_bster_dec;
	by agegrp;
 
	keep date agegrp type Sum_received_booster; 

	month = 11; 

	if first.agegrp then output; 

RUN; 


/*COMBINE INTO ONE FILE*/;

DATA work.Pop_VB_Booster_ADJ; 
	set work.popfullyvax_Booster_aug
		work.popfullyvax_Booster_sept
		work.popfullyvax_Booster_oct
		work.popfullyvax_Booster_nov
		work.popfullyvax_Booster_dec;

	Month = input(date, yymmdd10.);
	month_test = month(month);

	drop date month;

RUN; 


/*LEFT JOIN, Cases and population data*/;

PROC SQL;
create table vax_boost_popcase
as select distinct *
	from work.freqct_vbb v
	left join work.pop_vb_booster_adj e on v.month_test = e.month_test and v.agegrp = e.agegrp

	order by v.month_test

;
quit;



Data vax_boost_popcase_144;
	set vax_boost_popcase;

	cases_per100k = ((count/Sum_received_booster)*100000); 
	
	if  agegrp = '12-19' 		 then weight = 0.12150;
		else if agegrp = '20-29' then weight = 0.16959;
		else if agegrp = '30-39' then weight = 0.17013;
		else if agegrp = '40-49' then weight = 0.15005;
		else if agegrp = '50-59' then weight = 0.14357;
		else if agegrp = '60-69' then weight = 0.12932;
		else if agegrp = '70-79' then weight = 0.07780;
		else if agegrp = '80+' 	 then weight = 0.03800;

	cases_wt = cases_per100k*weight;

	if month_test < 8 then delete;

	drop percent ;

RUN;



PROC SQL; 

	create table AA_144_Vax_Booster_rates as
 
	select 	type,
			month_test,
			cases_wt

	,sum(cases_wt) as AgeAdj_rate_VB
	
	FROM vax_boost_popcase_144
	GROUP BY month_test;
QUIT; 


DATA AA_144_Vax_Booster_rates;
	set AA_144_Vax_Booster_rates;
	by month_test;
 
	keep type2 month_test AgeAdj_rate_VB; 

	type2 = 'vax_booster_cases';

	if first.month_test then output; 

RUN;  


/*Hosptializations: Vaccine Breakthrough + Booster */;

DATA work.VB_Booster_144_Hosp;
	set work.VB_Booster_144_Cases; 

	Hosp_date = input(cophs_admissiondate, yymmdd10.);
	month_hosp = month(hosp_date);
	month_test = month_hosp; 

	if hospitalized_cophs = 1 then output;

RUN; 



PROC FREQ data=VB_Booster_144_Hosp;
	tables agegrp*month_test / out=work.hosp_freqct_vbb nocol nocum norow nopercent; 
RUN;


/*LEFT JOIN, Cases and population data*/;

PROC SQL;
create table vax_bstr_hosp_popcase
as select distinct *
	from work.hosp_freqct_vbb v
	left join work.pop_vb_booster_adj e on v.month_test = e.month_test and v.agegrp = e.agegrp

	order by v.month_test

;
quit;


Data vax_bstr_hosp_popcase_144;
	set vax_bstr_hosp_popcase;

	cases_per100k = ((count/Sum_received_booster)*100000); 
	
	if  agegrp = '12-19' 		 then weight = 0.12150;
		else if agegrp = '20-29' then weight = 0.16959;
		else if agegrp = '30-39' then weight = 0.17013;
		else if agegrp = '40-49' then weight = 0.15005;
		else if agegrp = '50-59' then weight = 0.14357;
		else if agegrp = '60-69' then weight = 0.12932;
		else if agegrp = '70-79' then weight = 0.07780;
		else if agegrp = '80+' 	 then weight = 0.03800;

	cases_wt = cases_per100k*weight;

	if month_test < 8 then delete;

	drop percent ;

RUN;



PROC SQL; 

	create table AA_144_Vax_Bster_hos_rte as
 
	select 	type,
			month_test,
			cases_wt

	,sum(cases_wt) as AgeAdj_rate_VB
	
	FROM vax_bstr_hosp_popcase_144
	GROUP BY month_test;
QUIT; 


DATA AA_144_Vax_Bster_hos_rte;
	set AA_144_Vax_Bster_hos_rte;
	by month_test;
 
	keep type2 month_test AgeAdj_rate_VB; 

	type2 = 'vax_booster_hosp_rate';

	if first.month_test then output; 

RUN; 


/*Deaths, vaccinated + Booster*/;

DATA VB_Booster_144_Death;
	set work.VB_Booster_144_Cases;  

	Death_date = input(datevsdeceased, yymmdd10.);
	month_death = month(death_date);
	month_test = month_death;

	if deathdueto_vs_u071 = 1 then output;

RUN; 


PROC FREQ data=VB_Booster_144_death;
	tables agegrp*month_test / out=work.death_freqct_vbb nocol nocum norow nopercent; 
RUN;



/*LEFT JOIN, Cases and population data*/;

PROC SQL;
create table vax_bstr_death_popcase
as select distinct *
	from work.death_freqct_vbb v
	left join work.pop_vb_booster_adj e on v.month_test = e.month_test and v.agegrp = e.agegrp

	order by v.month_test

;
quit;


Data vax_bstr_death_popcase_144;
	set vax_bstr_death_popcase;

	cases_per1M = ((count/Sum_received_booster)*1000000); 
	
	if  agegrp = '12-19' 		 then weight = 0.12150;
		else if agegrp = '20-29' then weight = 0.16959;
		else if agegrp = '30-39' then weight = 0.17013;
		else if agegrp = '40-49' then weight = 0.15005;
		else if agegrp = '50-59' then weight = 0.14357;
		else if agegrp = '60-69' then weight = 0.12932;
		else if agegrp = '70-79' then weight = 0.07780;
		else if agegrp = '80+' 	 then weight = 0.03800;

	cases_wt = cases_per1M*weight;

	if month_test < 8 then delete;

	drop percent ;

RUN;



PROC SQL; 

	create table AA_144_Vax_Bster_death_rte as
 
	select 	type,
			month_test,
			cases_wt

	,sum(cases_wt) as AgeAdj_rate_VB
	
	FROM vax_bstr_death_popcase_144
	GROUP BY month_test;
QUIT; 


DATA AA_144_Vax_Bster_death_rte;
	set AA_144_Vax_Bster_death_rte;
	by month_test;
 
	keep type2 month_test AgeAdj_rate_VB; 

	type2 = 'vax_booster_death_rate';

	if first.month_test then output; 

RUN; 


DATA archive4.AA_144_VB_VBB_All;
	set work.AA_144_Vax_Nobo_rates
		work.AA_144_Vax_Nobo_hos_rte
		work.AA_144_Vax_Nobo_dead_rte
		work.AA_144_Vax_Booster_rates
		work.AA_144_Vax_Bster_hos_rte
		work.AA_144_Vax_Bster_death_rte; 
RUN;


/*********************************************************************/

/*Unvaccinated */;

DATA Unvax_144_cases;
	set WORK.FILTER_FOR_CEDRS_VIEW;
	
	if age_at_reported >= 12 and age_at_reported  <= 19 then agegrp = '12-19';
		else if age_at_reported  >= 20 and age_at_reported  <= 29 then agegrp = '20-29';
		else if age_at_reported  >= 30 and age_at_reported  <= 39 then agegrp = '30-39';
		else if age_at_reported  >= 40 and age_at_reported  <= 49 then agegrp = '40-49';
		else if age_at_reported  >= 50 and age_at_reported  <= 59 then agegrp = '50-59';
		else if age_at_reported  >= 60 and age_at_reported  <= 69 then agegrp = '60-69';
		else if age_at_reported  >= 70 and age_at_reported  <= 79 then agegrp = '70-79';
		else if age_at_reported  >= 80 then agegrp = '80+';
		else if age_at_reported  <= 11 then delete; 

	Test_date = input(earliest_collectiondate, yymmdd10.);
	month_test = month(test_date);
	
	if earliest_collectiondate = '' then delete;

	if breakthrough = 0 and earliest_collectiondate >= '2021-01-01' and earliest_collectiondate <= '2021-12-31' then output;

RUN; 

PROC SORT data=work.unvax_144_cases nodup; 
	by eventid; 
RUN; 
 Proc contents data= work.unvax_144_cases; 
 RUN;

PROC FREQ data=work.unvax_144_Cases;
	tables breakthrough / nocol nocum norow nopercent; 
RUN;


PROC FREQ data=work.unvax_144_Cases;
	tables agegrp*month_test / out=work.freqct_unvax nocol nocum norow nopercent; 
RUN;


/* Unvaccinated Population - August to December */;

/*AUGUST*/;

PROC SQL;
   CREATE TABLE WORK.FILTER_FOR_VAXUNVAX_POP_AUG AS 
   SELECT t1.age, 
          t1.date, 
          t1.total_not_fully_vaccinated
      FROM TABLEAU.vaxunvax_population_byage t1
      WHERE t1.date = '2021-08-15';
QUIT;


DATA unvax_pop_Aug;
	set WORK.FILTER_FOR_VAXUNVAX_POP_AUG; 

	if age >= 12 and age <= 19 then agegrp = '12-19';
		else if age >= 20 and age <= 29 then agegrp = '20-29';
		else if age >= 30 and age <= 39 then agegrp = '30-39';
		else if age >= 40 and age <= 49 then agegrp = '40-49';
		else if age >= 50 and age <= 59 then agegrp = '50-59';
		else if age >= 60 and age <= 69 then agegrp = '60-69';
		else if age >= 70 and age <= 79 then agegrp = '70-79';
		else if age >= 80 then agegrp = '80+';
		else if age <= 11 then delete; 
RUN; 

PROC SQL; 
	create table pop_unvax_81521 as
 
	select 	
			date, 
			agegrp, 
			total_not_fully_vaccinated,

	sum(total_not_fully_vaccinated) as Sum_pop_notfullyvax

	FROM work.unvax_pop_Aug
	GROUP BY agegrp;
QUIT;

DATA pop_unvax_815;
	set pop_unvax_81521;
	by agegrp;
 
	keep date agegrp Sum_pop_notfullyvax; 

	if first.agegrp then output; 

RUN; 

/*SEPT*/;

PROC SQL;
   CREATE TABLE WORK.FILTER_FOR_VAXUNVAX_POP_SEPT AS 
   SELECT t1.age, 
          t1.date, 
          t1.total_not_fully_vaccinated
      FROM TABLEAU.vaxunvax_population_byage t1
      WHERE t1.date = '2021-09-15';
QUIT;;

DATA unvax_pop_SEPT;
	set WORK.FILTER_FOR_VAXUNVAX_POP_SEPT; 

		if age >= 12 and age <= 19 then agegrp = '12-19';
		else if age >= 20 and age <= 29 then agegrp = '20-29';
		else if age >= 30 and age <= 39 then agegrp = '30-39';
		else if age >= 40 and age <= 49 then agegrp = '40-49';
		else if age >= 50 and age <= 59 then agegrp = '50-59';
		else if age >= 60 and age <= 69 then agegrp = '60-69';
		else if age >= 70 and age <= 79 then agegrp = '70-79';
		else if age >= 80 then agegrp = '80+';
		else if age <= 11 then delete; 
RUN; 

PROC SQL; 
	create table pop_unvax_91521 as
 
	select 	
			date, 
			agegrp, 
			total_not_fully_vaccinated,

	sum(total_not_fully_vaccinated) as Sum_pop_notfullyvax

	FROM work.unvax_pop_SEPT
	GROUP BY agegrp;
QUIT;

DATA pop_unvax_915;
	set pop_unvax_91521;
	by agegrp;
 
	keep date agegrp Sum_pop_notfullyvax; 

	if first.agegrp then output; 

RUN; 

/*OCTOBER*/;

PROC SQL;
   CREATE TABLE WORK.FILTER_FOR_VAXUNVAX_POP_OCT AS 
   SELECT t1.age, 
          t1.date, 
          t1.total_not_fully_vaccinated
      FROM TABLEAU.vaxunvax_population_byage t1
      WHERE t1.date = '2021-10-15';
QUIT;;

DATA unvax_pop_OCT;
	set WORK.FILTER_FOR_VAXUNVAX_POP_OCT;

 	if age >= 12 and age <= 19 then agegrp = '12-19';
		else if age >= 20 and age <= 29 then agegrp = '20-29';
		else if age >= 30 and age <= 39 then agegrp = '30-39';
		else if age >= 40 and age <= 49 then agegrp = '40-49';
		else if age >= 50 and age <= 59 then agegrp = '50-59';
		else if age >= 60 and age <= 69 then agegrp = '60-69';
		else if age >= 70 and age <= 79 then agegrp = '70-79';
		else if age >= 80 then agegrp = '80+';
		else if age <= 11 then delete;
 
RUN; 

PROC SQL; 
	create table pop_unvax_101521 as
 
	select 	
			date, 
			agegrp, 
			total_not_fully_vaccinated,

	sum(total_not_fully_vaccinated) as Sum_pop_notfullyvax

	FROM work.unvax_pop_OCT
	GROUP BY agegrp;
QUIT;

DATA pop_unvax_1015;
	set pop_unvax_101521;
	by agegrp;
 
	keep date agegrp Sum_pop_notfullyvax; 

	if first.agegrp then output; 

RUN; 

/*NOVEMBER */;


PROC SQL;
   CREATE TABLE WORK.FILTER_FOR_VAXUNVAX_POP_NOV AS 
   SELECT t1.age, 
          t1.date, 
          t1.total_not_fully_vaccinated
      FROM TABLEAU.vaxunvax_population_byage t1
      WHERE t1.date = '2021-11-15';
QUIT;;

DATA unvax_pop_NOV;
	set WORK.FILTER_FOR_VAXUNVAX_POP_NOV; 

	if age >= 12 and age <= 19 then agegrp = '12-19';
		else if age >= 20 and age <= 29 then agegrp = '20-29';
		else if age >= 30 and age <= 39 then agegrp = '30-39';
		else if age >= 40 and age <= 49 then agegrp = '40-49';
		else if age >= 50 and age <= 59 then agegrp = '50-59';
		else if age >= 60 and age <= 69 then agegrp = '60-69';
		else if age >= 70 and age <= 79 then agegrp = '70-79';
		else if age >= 80 then agegrp = '80+';
		else if age <= 11 then delete; 
RUN; 

PROC SQL; 
	create table pop_unvax_111521 as
 
	select 	
			date, 
			agegrp, 
			total_not_fully_vaccinated,

	sum(total_not_fully_vaccinated) as Sum_pop_notfullyvax

	FROM work.unvax_pop_nov
	GROUP BY agegrp;
QUIT;

DATA pop_unvax_1115;
	set pop_unvax_111521;
	by agegrp;
 
	keep date agegrp Sum_pop_notfullyvax; 

	if first.agegrp then output; 

RUN; 


/*DECEMBER */;


PROC SQL;
   CREATE TABLE WORK.FILTER_FOR_VAXUNVAX_POP_DEC AS 
   SELECT t1.age, 
          t1.date, 
          t1.total_not_fully_vaccinated
      FROM TABLEAU.vaxunvax_population_byage t1
      WHERE t1.date = '2021-12-15';
QUIT;;

DATA unvax_pop_DEC;
	set WORK.FILTER_FOR_VAXUNVAX_POP_DEC; 

	if age >= 12 and age <= 19 then agegrp = '12-19';
		else if age >= 20 and age <= 29 then agegrp = '20-29';
		else if age >= 30 and age <= 39 then agegrp = '30-39';
		else if age >= 40 and age <= 49 then agegrp = '40-49';
		else if age >= 50 and age <= 59 then agegrp = '50-59';
		else if age >= 60 and age <= 69 then agegrp = '60-69';
		else if age >= 70 and age <= 79 then agegrp = '70-79';
		else if age >= 80 then agegrp = '80+';
		else if age <= 11 then delete; 
RUN; 

PROC SQL; 
	create table pop_unvax_121521 as
 
	select 	
			date, 
			agegrp, 
			total_not_fully_vaccinated,

	sum(total_not_fully_vaccinated) as Sum_pop_notfullyvax

	FROM work.unvax_pop_dec
	GROUP BY agegrp;
QUIT;

DATA pop_unvax_1215;
	set pop_unvax_121521;
	by agegrp;
 
	keep date agegrp Sum_pop_notfullyvax; 

	if first.agegrp then output; 

RUN; 

DATA unvax_pop_augdec21_adj;
	set pop_unvax_815
		pop_unvax_915
		pop_unvax_1015
		pop_unvax_1115
		pop_unvax_1215;
		
	Month = input(date, yymmdd10.);
	month_test = month(month);

	drop date month;
	
RUN; 


/*LEFT JOIN, Cases and population data*/;

PROC SQL;
create table unvax_popcase
as select distinct *
	from work.freqct_unvax v
	left join work.unvax_pop_augdec21_adj e on v.month_test = e.month_test and v.agegrp = e.agegrp

	order by v.month_test

;
quit;



Data unvax_popcase_144;
	set unvax_popcase;

	cases_per100k = ((count/Sum_pop_notfullyvax)*100000); 
	
	if  agegrp = '12-19' 		 then weight = 0.12150;
		else if agegrp = '20-29' then weight = 0.16959;
		else if agegrp = '30-39' then weight = 0.17013;
		else if agegrp = '40-49' then weight = 0.15005;
		else if agegrp = '50-59' then weight = 0.14357;
		else if agegrp = '60-69' then weight = 0.12932;
		else if agegrp = '70-79' then weight = 0.07780;
		else if agegrp = '80+' 	 then weight = 0.03800;

	cases_wt = cases_per100k*weight;

	if month_test < 8 then delete;

	type = 'unvax';

	drop percent;

RUN;



PROC SQL; 

	create table AA_144_Unvax_rates as
 
	select 	type,
			month_test,
			cases_wt

	,sum(cases_wt) as AgeAdj_rate_VB
	
	FROM unvax_popcase_144
	GROUP BY month_test;
QUIT; 


DATA AA_144_Unvax_rates;
	set AA_144_Unvax_rates;
	by month_test;
 
	keep type2 month_test AgeAdj_rate_VB; 

	type2 = 'unvax_cases';

	if first.month_test then output; 

RUN;  


/*Hospitalization, Unvaccinated */;


DATA Unvax_144_Hos;
	set Unvax_144_cases;

	Hosp_date = input(cophs_admissiondate, yymmdd10.);
	month_hosp = month(hosp_date);
	month_test = month_hosp;

	if hospitalized_cophs = 1 then output;

RUN; 


PROC FREQ data=Unvax_144_Hos;
	tables agegrp*month_test / out=work.hosp_freqct_unvax nocol nocum norow nopercent; 
RUN;


/*LEFT JOIN, Cases and population data*/;

PROC SQL;
create table unvax_hosp_popcase
as select distinct *
	from work.hosp_freqct_unvax v
	left join work.unvax_pop_augdec21_adj e on v.month_test = e.month_test and v.agegrp = e.agegrp

	order by v.month_test

;
quit;


Data unvax_hosp_popcase_144;
	set unvax_hosp_popcase;

	cases_per100k = ((count/Sum_pop_notfullyvax)*100000); 
	
	if  agegrp = '12-19' 		 then weight = 0.12150;
		else if agegrp = '20-29' then weight = 0.16959;
		else if agegrp = '30-39' then weight = 0.17013;
		else if agegrp = '40-49' then weight = 0.15005;
		else if agegrp = '50-59' then weight = 0.14357;
		else if agegrp = '60-69' then weight = 0.12932;
		else if agegrp = '70-79' then weight = 0.07780;
		else if agegrp = '80+' 	 then weight = 0.03800;

	cases_wt = cases_per100k*weight;

	if month_test < 8 then delete;

	type = 'unvax';

	drop percent ;

RUN;



PROC SQL; 

	create table AA_144_unvax_hos_rte as
 
	select 	type,
			month_test,
			cases_wt

	,sum(cases_wt) as AgeAdj_rate_unvax
	
	FROM unvax_hosp_popcase_144
	GROUP BY month_test;
QUIT; 


DATA AA_144_unvax_hos_rte;
	set AA_144_unvax_hos_rte;
	by month_test;
 
	keep type2 month_test AgeAdj_rate_Unvax; 

	type2 = 'unvax_hosp_rate';

	if first.month_test then output; 

RUN; 





/* deaths, unvaccinated*/;


DATA Unvax_144_Death;
	set Unvax_144_cases;

	Death_date = input(datevsdeceased, yymmdd10.);
	month_death = month(death_date);
	month_test = month_death; 

	if deathdueto_vs_u071 = 1 then output;

	if datevsdeceased = '' then delete;

RUN; 



PROC SORT data=work.Unvax_144_Death nodup; 
	by eventid; 
RUN; 

PROC FREQ data=work.Unvax_144_Death;
	tables breakthrough / nocol nocum norow nopercent; 
RUN;


PROC FREQ data=work.Unvax_144_Death;
	tables agegrp*month_test / out=work.freqct_unvax_dead nocol nocum norow nopercent; 
RUN;


/*LEFT JOIN, Cases and population data*/;

PROC SQL;
create table unvax_dead_popcase
as select distinct *
	from work.freqct_unvax_dead v
	left join work.unvax_pop_augdec21_adj e on v.month_test = e.month_test and v.agegrp = e.agegrp

	order by v.month_test

;
quit;


Data unvax_dead_popcase_144;
	set unvax_dead_popcase;

	cases_per1M = ((count/Sum_pop_notfullyvax)*1000000); 
	
	if  agegrp = '12-19' 		 then weight = 0.12150;
		else if agegrp = '20-29' then weight = 0.16959;
		else if agegrp = '30-39' then weight = 0.17013;
		else if agegrp = '40-49' then weight = 0.15005;
		else if agegrp = '50-59' then weight = 0.14357;
		else if agegrp = '60-69' then weight = 0.12932;
		else if agegrp = '70-79' then weight = 0.07780;
		else if agegrp = '80+' 	 then weight = 0.03800;

	cases_wt = cases_per1M*weight;

	if month_test < 8 then delete;

	type = 'unvax_deaths';

	drop percent ;

RUN;



PROC SQL; 

	create table AA_144_unvax_death_rte as
 
	select 	type,
			month_test,
			cases_wt

	,sum(cases_wt) as AgeAdj_rate_unvax
	
	FROM unvax_dead_popcase_144
	GROUP BY month_test;
QUIT; 


DATA AA_144_unvax_death_rate;
	set AA_144_unvax_death_rte;
	by month_test;
 
	keep type2 month_test AgeAdj_rate_Unvax; 

	type2 = 'unvax_death_rate';

	if first.month_test then output; 

RUN; 


/*Combine all Age Adjustment files into one*/;


DATA archive4.AA_144_Unvax_VB_VBB_All;
	set work.AA_144_Vax_Nobo_rates
		work.AA_144_Vax_Nobo_hos_rte
		work.AA_144_Vax_Nobo_dead_rte
		work.AA_144_Vax_Booster_rates
		work.AA_144_Vax_Bster_hos_rte
		work.AA_144_Vax_Bster_death_rte
		work.AA_144_UNVAX_RATES
		work.AA_144_unvax_hos_rte
		work.AA_144_UNVAX_DEAth_RATE; 
RUN;


/************END OF CODE***********************************/;