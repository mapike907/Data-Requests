
/*****************************************************************************************************/
/** 	COVID-19 Cases in VB + Booster / with and without 14-day lag from vaccination				**/
/**															  				   						**/
/** 	Q: Do case counts look different between 14-day and not using 14-day lag on booster dose	**/
/**																									**/
/**     Uses cedrs_view to capture cases															**/
/**																									**/															   
/** 																								**/
/**		Written by: M. Pike, Feb 5, 2022															**/
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
          t1.earliest_collectiondate, 
          t1.vax_firstdose, 
          t1.vax_utd, 
		  t1.vaccine_received,
          t1.breakthrough, 
          t1.breakthrough_booster, 
          t1.vax_booster
      FROM SEVERSON.cedrs_view t1;
QUIT;


/*Create a file with VBB cases*/; 

DATA VB_VBB_analysis_test;
	set WORK.FILTER_FOR_CEDRS_VIEW;

	Test_date = input(earliest_collectiondate, yymmdd10.); /*create sas date from character format*/
	month_test = month(test_date); /*extract month*/
	year_test = year(test_date); /*extract year*/
	vax_date = input(vax_booster, yymmdd10.); /*create sas date from character format*/

	vb_day_duration = test_date - vax_date; /*find the difference between the dates for filtering those who meet VBB case definition*/

RUN; 



/*VBB with 14-day lag */;

DATA work.VB_Booster_144_14day;
	set VB_VBB_analysis_test;

	if breakthrough = 1 and vax_booster = '' then boosted_case = 0; /*vaccinated cases that have not recieved a third dose*/
		else if breakthrough = 1 and vax_booster < '2021-08-13' then boosted_case = 0; /*vaccinated cases who recieved a third dose before CDC dates*/;

	if breakthrough = 1 and vax_booster >= '2021-08-13' and vb_day_duration >= 14 then boosted_case = 1; /*definition for breakthrough boosted cases, 14-day lag*/;
	if breakthrough = 0 then delete; /*these are the unvaccinated*/

RUN; 

DATA VB_Booster_14day;
	set work.VB_Booster_144_14day;

	if breakthrough = 1 and boosted_case = 1 then output;
RUN;

PROC SORT data=work.vb_booster_14day nodup; 
	by eventid;
RUN; 

PROC FREQ data=work.vb_booster_14day; 
	tables boosted_case; 
RUN; 

/* Boosted_case =1; N = 66,549*/;

PROC FREQ data=work.VB_Booster_14day;
	tables month_test / nocol nocum norow nopercent; 
RUN;


/*VBB WITHOUT 14-day lag */;

DATA work.VB_Booster_144_No14;
	set VB_VBB_analysis_test;

	if breakthrough = 1 and vax_booster >= '2021-08-13' and vb_day_duration >= 1 then boosted_case = 2; /*These do not have a 14-day lag*/;
	if breakthrough = 1 and boosted_case = 2 then output;

RUN; 

/* Boosted_case = 2 ; N = 77,970*/; 

PROC SORT data=work.vb_booster_144_No14 nodup; 
	by eventid;
RUN; 

PROC FREQ data=work.vb_booster_144_No14; 
	tables boosted_case; 
RUN; 


PROC FREQ data=work.VB_Booster_144_no14;
	tables month_test / nocol nocum norow nopercent; 
RUN;
