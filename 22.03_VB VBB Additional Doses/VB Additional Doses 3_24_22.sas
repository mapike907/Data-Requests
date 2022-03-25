
/*****************************************************************************************************/
/** 	Evaluation of Additional Vaccine Doses and Vaccine Breakthrough Cases						**/
/**															  				   						**/
/** 	Vaccine Breakthrough: Colorado VB data, all VB cases, including hospitalization & Death		**/
/** 																								**/
/**		Input: CDC_04_01_22.sas																		**/
/**		Output: Creates Variables for Tableau with additional doses									**/
/** 																								**/												   
/** 																								**/
/**		Written by: M. Pike, March 24, 2022															**/
/*****************************************************************************************************/

libname covid	 odbc dsn='COVID19' 	    schema=dbo		READ_LOCK_TYPE=NOLOCK; /* 144 - DBO */;
libname covcase	 odbc dsn='COVID19' 	    schema=cases	READ_LOCK_TYPE=NOLOCK; /* 144 - DBO */;
libname archive 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Vaccine Breakthrough\07_Data\archive';

PROC SQL;
   CREATE TABLE WORK.FILTER_FOR_CDC_04_01_22B AS 
   SELECT t1.profileid, 
          t1.breakthrough, 
          t1.earliest_collectiondate, 
          t1.covtestdt, 
          t1.local_id, 
          t1.age_at_reported, 
          t1.inpatient, 
          t1.outcome, 
          t1.hosp_related, 
          t1.hosp_date, 
		  t1.vrvac_covid19_man1, 
          t1.vrvac_covid19_dt1, 
		  t1.vrvac_covid19_man2, 
          t1.vrvac_covid19_dt2,
		  t1.vrvac_covid19_man3, 
          t1.vrvac_covid19_dt3, 
		  t1.vrvac_covid19_man4, 
          t1.vrvac_covid19_dt4,
		  t1.vrvac_covid19_man5,  
          t1.vrvac_covid19_dt5
      FROM ARCHIVE.CDC_04_01_22B t1;
QUIT;

DATA VB_Cases;
	set work.filter_for_cdc_04_01_22b;

	Test_date = input(earliest_collectiondate, yymmdd10.); /*create sas date from character format*/
	month_test = month(test_date); /*extract month*/
	year_test = year(test_date); /*extract year*/

	if vrvac_covid19_man1 = 3 then delete; /*removes AZD*/;
	if vrvac_covid19_man1 = 5 then delete; /*removes other manuf*/;
	if vrvac_covid19_man1 = 9 then delete; /*removes unknown manuf*/;

	if vrvac_covid19_man2 = 3 then delete;
		else if vrvac_covid19_man2 = 5 then delete;
		else if vrvac_covid19_man2 = 9 then delete;

	if vrvac_covid19_man3 = 3 then delete;
		else if vrvac_covid19_man3= 5 then delete;
		else if vrvac_covid19_man3 = 9 then delete;

	if vrvac_covid19_man4 = 3 then delete;
		else if vrvac_covid19_man4 = 5 then delete;
		else if vrvac_covid19_man4 = 9 then delete;

	if vrvac_covid19_man5 = 3 then delete;
		else if vrvac_covid19_man5 = 5 then delete;
		else if vrvac_covid19_man5 = 9 then delete;

RUN;

/*********************************************/;
/* No boosters */;
*/ Vaccine breakthrough, no third dose, mrna */;

DATA VB_cases_mrna;
	set vb_cases; 

	If vrvac_covid19_man1 = 1 /*pfizer*/ or vrvac_covid19_man1 = 2 /*moderna*/ then output;
RUN;

DATA VB_cases_mrna2;
	set vb_cases_mrna;

	If vrvac_covid19_man3 = . then output;

RUN;


*/ Vaccine breakthrough, no J&J second dose */;

DATA VB_cases_JJ;
	set vb_cases; 

	If vrvac_covid19_man1 = 4 /*Janssen*/ then output;
RUN;

DATA VB_cases_JJ2;
	set vb_cases_JJ;

	If vrvac_covid19_man2 = . then output;

RUN;

/*Combined VB no booster, mrna + J&J*/;

DATA VB_cases2; 
	set VB_cases_mrna2
		VB_cases_JJ2; 

	type = 'VB, No Booster';

RUN;


/*********************************************/;

*/ Vaccine breakthrough, mrna third dose */;

DATA VB_mrna_third;
	set VB_Cases_mrna;

	if vrvac_covid19_man3 = . then delete; /*removes those who have not had a third dose*/;

RUN; 

/* Find those who tested positive 14 days after the third dose, after August 13 2021, and before the 4th dose*/;

DATA VB_mrna_3;
	set VB_mrna_third;

	vb_day_duration = covtestdt - vrvac_covid19_dt3; /*find the difference between the dates for filtering those who meet VBB case definition*/

	if vb_day_duration >= 14 then output;

RUN;

DATA VB_mrna_3b;
	set VB_mrna_3;

	if vrvac_covid19_dt3 <= '13Aug2021'd then delete;

RUN;


DATA VB_mrna_3c;
	set VB_mrna_3b;

	if covtestdt >= vrvac_covid19_dt4 then delete;

	type = 'VB, 1 Booster';

RUN;

*/ Vaccine breakthrough, J&J second dose */;

DATA VB_cases_JJ_2;
	set VB_cases_JJ;

	vb_day_duration = covtestdt - vrvac_covid19_dt2; /*find the difference between the dates for filtering those who meet VBB case definition*/

	if vb_day_duration >= 14 then output;

RUN;


DATA VB_cases_JJ_2b;
	set VB_cases_JJ_2;

	if vrvac_covid19_dt2 <= '13Aug2021'd then delete;

RUN;


DATA VB_cases_JJ_2c;
	set VB_cases_JJ_2b;

	if covtestdt >= vrvac_covid19_dt3 then delete;

	type = 'VB, 1 Booster';

RUN;

/*Combined VB booster, mrna + J&J*/;

DATA VB_Cases3;
	set VB_mrna_3c
		VB_cases_JJ_2c;
RUN;

/*********************************************/;
*/ Vaccine breakthrough, mrna fourth dose, initial series and 2 boosters */;

DATA VB_mrna_fourth;
	set VB_Cases_mrna;

	if vrvac_covid19_man4 = . then delete; /*removes those who have not had a 4th dose*/;

RUN; 

/* Find those who tested positive 14 days after the third dose, after August 13 2021, and before the 4th dose*/;

DATA VB_mrna_4;
	set VB_mrna_fourth;

	vb_day_duration = covtestdt - vrvac_covid19_dt4; /*find the difference between the dates for filtering those who meet VBB case definition*/

	if vb_day_duration >= 14 then output;

RUN;

DATA VB_mrna_4b;
	set VB_mrna_4;

	if vrvac_covid19_dt2 <= '13Aug2021'd then delete;

RUN;

DATA VB_mrna_4c;
	set VB_mrna_4b;

	if covtestdt >= vrvac_covid19_dt5 then delete;

	type = 'VB, 2 Booster';

RUN;



*/ Vaccine breakthrough, J&J three doses, initial series and two boosters */;

DATA VB_cases_JJ_3;
	set VB_cases_JJ;

	vb_day_duration = covtestdt - vrvac_covid19_dt3; /*find the difference between the dates for filtering those who meet VBB case definition*/

	if vb_day_duration >= 14 then output;

RUN;


DATA VB_cases_JJ_3b;
	set VB_cases_JJ_3;

	if vrvac_covid19_dt2 <= '13Aug2021'd then delete;

RUN;


DATA VB_cases_JJ_3c;
	set VB_cases_JJ_3b;

	if covtestdt >= vrvac_covid19_dt3 then delete;

	type = 'VB, 2 Booster';

RUN;

/*Combined VB booster, mrna + J&J*/;

DATA VB_Cases4;
	set VB_mrna_4c
		VB_cases_JJ_3c;
RUN;

/** 3/25/22: Currently N=2 with 4th doses. Analysis is complete for now.*/;


/********************************************/;


/* Find those who tested positive 14 days after the third dose, after August 13 2021, and before the 5th dose*/;

DATA VB_mrna_5;
	set VB_Cases_mrna;

	vb_day_duration = covtestdt - vrvac_covid19_dt5; /*find the difference between the dates for filtering those who meet VBB case definition*/

	if vb_day_duration >= 14 then output;

RUN;

DATA VB_mrna_5b;
	set VB_mrna_5;

	if vrvac_covid19_dt3 <= '13Aug2021'd then delete;

RUN;

DATA VB_mrna_5c;
	set VB_mrna_5b;

	if covtestdt >= vrvac_covid19_dt5 then delete;

	type = 'VB, 3 Booster';

RUN;


/******** END OF CODE *************************************/;