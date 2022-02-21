
/*****************************************************************************************************/
/** 	Delta vs Omicron Analysis of VB and VBB: Cases, Hospitalizations, & Death					**/
/**															  				   						**/
/** 	Input: 144, cedrs.cedrs_view																**/
/**		Output: Delta_vs_Omicron_VB_VBB.sas															**/	
/**															  				   						**/
/**		Data Request by A. Cronquist, question posed by Broomfield, CO LPHA	   						**/ 
/** 																								**/
/**		Program writted by: M. Pike, Feb 8, 2022													**/
/*****************************************************************************************************/


libname newcedrs odbc dsn='CEDRS_3_read' 	schema=CEDRS 	READ_LOCK_TYPE=NOLOCK;
libname tableau odbc dsn='Tableau' 			schema=ciis 	READ_LOCK_TYPE=NOLOCK; 
libname severson odbc dsn='Tableau' 		schema=dbo		READ_LOCK_TYPE=NOLOCK; 
libname archive4 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Vaccine Breakthrough\07_Data\archive4';
libname archive2 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Vaccine Breakthrough\07_Data\archive2';


/** Pull all cases from 144, Cedrs_view */

PROC SQL;
   CREATE TABLE WORK.FILTER_FOR_CEDRS_VIEW AS 
   SELECT t1.eventid, 
          t1.gender, 
		  t1.age_at_reported,
          t1.reinfection, 
          t1.earliest_collectiondate, 
          t1.hospitalized_cophs,
		  t1.deathdueto_vs_u071, 
		  t1.deathdate,
          t1.cophs_admissiondate, 
          t1.hospitalized,  
          t1.casestatus,
		  t1.vax_booster,
		  t1.vax_firstdose,
		  t1.vax_utd,
		  t1.partialonly,
		  t1.breakthrough,
		  t1.breakthrough_booster
      FROM SEVERSON.cedrs_view t1
	  where casestatus = 'confirmed' and earliest_collectiondate >= '2021-07-01';
QUIT;


/*Data clean*/;
Data work.cedrs_view;
	set work.filter_for_cedrs_view; 

	format agegrp $8.;

	if age_at_reported >= 0 and age_at_reported  <= 4 then agegrp = '0-4';
		else if age_at_reported >= 5 and age_at_reported  <= 11 then agegrp = '5-11';
		else if age_at_reported >= 12 and age_at_reported  <= 15 then agegrp = '12-15';
		else if age_at_reported >= 16 and age_at_reported  <= 19 then agegrp = '12-19';
		else if age_at_reported  >= 20 and age_at_reported  <= 29 then agegrp = '20-29';
		else if age_at_reported  >= 30 and age_at_reported  <= 39 then agegrp = '30-39';
		else if age_at_reported  >= 40 and age_at_reported  <= 49 then agegrp = '40-49';
		else if age_at_reported  >= 50 and age_at_reported  <= 59 then agegrp = '50-59';
		else if age_at_reported  >= 60 and age_at_reported  <= 69 then agegrp = '60-69';
		else if age_at_reported  >= 70 then agegrp = '70+';

	Test_date = input(earliest_collectiondate, yymmdd10.); /*create sas date from character format*/
	hosp_date = input(cophs_admissiondate, yymmdd10.); 
	death_date = input(deathdate, yymmdd10.);

	hosp_month = month(hosp_date); 
	death_month = month(death_date);
	case_month = month(test_date);

	if case_month = 7 then case_mo = 7;
		else if case_month = 8 then case_mo = 8;
		else if case_month = 9 then case_mo = 9;
		else if case_month = 10 then case_mo = 10;
		else if case_month = 11 then case_mo = 11;
		else if case_month = 12 then case_mo = 12;
		else if case_month = 1 then case_mo = 13;
		else if case_month = 2 then case_mo = 14;

	if hosp_month = 7 then hos_mo = 7;
		else if hosp_month = 8 then hos_mo = 8;
		else if hosp_month = 9 then hos_mo  = 9;
		else if hosp_month = 10 then hos_mo  = 10;
		else if hosp_month = 11 then hos_mo  = 11;
		else if hosp_month = 12 then hos_mo  = 12;
		else if hosp_month = 1 then hos_mo = 13;
		else if hosp_month = 2 then hos_mo = 14;

	if death_month = 7 then death_mo = 7;
		else if death_month = 8 then death_mo = 8;
		else if death_month = 9 then death_mo  = 9;
		else if death_month = 10 then death_mo  = 10;
		else if death_month = 11 then death_mo  = 11;
		else if death_month = 12 then death_mo  = 12;
		else if death_month = 1 then death_mo = 13;
		else if death_month = 2 then death_mo = 14;
	
RUN; 

Data archive2.DeltaOmicron_21522;
	set work.cedrs_view; 

	format status $8.;

	if breakthrough = 0 and breakthrough_booster = 0 then status = 'Unvax';
	else if breakthrough = 1 and breakthrough_booster = 0 then status = 'VB';
	else if breakthrough = 1 and breakthrough_booster = 1 then status = 'VBB';

RUN; 

