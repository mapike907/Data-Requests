
/*****************************************************************************************************/
/** 	Evaluation of hand-entered vaccination data vs CIIS imported data in CEDRS		    **/
/**												    **/
/**	Q: What proportions of cases since 01/01/21 do we have a CIIS match for vaccination?	    **/
/**	Data request from: Alicia Cronquist					  		    **/
/** 											            **/				
/** 												    **/
/**	Writted by: M. Pike, Feb 1, 2022							    **/
/** 	Updated by: M. Pike, Feb 4, 2022							    **/	
/*****************************************************************************************************/

libname newcedrs odbc dsn='CEDRS_3_READ' schema=CEDRS 	READ_LOCK_TYPE=NOLOCK; 
libname ciis     odbc dsn='Tableau' 	 schema=ciis	READ_LOCK_TYPE=NOLOCK; 
libname severson odbc dsn='Tableau' 	 schema=dbo	READ_LOCK_TYPE=NOLOCK; 
libname archive4 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Vaccine Breakthrough\07_Data\archive4'; 

/*Q1: Find the denominator: How many COVID-19 Cases?*/;

PROC SQL;
   CREATE TABLE WORK.FILTER_FOR_CEDRS_VIEW AS 
   SELECT t1.eventid, 
          t1.collectiondate, 
          t1.vax_booster, 
          t1.vax_firstdose, 
          t1.earliest_collectiondate, 
          t1.vax_utd, 
          t1.breakthrough, 
          t1.breakthrough_booster
      FROM SEVERSON.cedrs_view t1
	  WHERE t1.earliest_collectiondate >= '2021-01-01';
QUIT;


PROC SQL;
    select count(*) as N from work.filter_for_cedrs_view;
QUIT;
 
PROC SQL noprint;
    select count(*) into :nobs_1 separated by ' '
        from work.filter_for_cedrs_view;
QUIT;
%put &=nobs_1.;

/* Answer: N = 894,086 */;

/************************************************************/;
/*Q2: How many eventids are coming in from CIIS? */; 

PROC SQL;
   CREATE TABLE WORK.FILTER_FOR_CASE_IZ AS 
   SELECT t1.eventid, 
          t1.vaccination_date, 
          t1.vaccination_code, 
          t1.manufacturer_code
      FROM CIIS.case_iz t1;
QUIT;

PROC SORT data=work.filter_for_case_iz nodupkey ; 
	by eventid; 
RUN; 

PROC SORT data=work.FILTER_FOR_CEDRS_VIEW nodupkey; 
	by eventid; 
RUN; 

/* create new table that matches on eventid to cedrs_view, to eliminate eventids that are not in 2021*/;
PROC SQL; 
	create table case_cedrs_combi as	

	select * from work.filter_for_cedrs_view as x , work.filter_for_case_iz as y
		where x.eventid = y.eventid;
QUIT; 

PROC CONTENTS data=work.case_cedrs_combi; 
RUN; 

/* Answer: N = 441,256 */;


/*Q2a: How many eventids are coming in from CIIS that are VB?*/;

PROC FREQ data=work.case_cedrs_combi;
	tables breakthrough; 
RUN; 
/* Answer: N = 292,623*/;


/*Q2b: How many eventids are coming in from CIIS that are VB+B?*/;

PROC FREQ data=work.case_cedrs_combi;
	tables breakthrough_booster; 
RUN; 

/* Answer: N = 65,073*/;

/************************************************************/;
/*Q3: How many eventids are from cedrs.SurveillanceFormVax (manual entry)? */;

PROC SQL;
   CREATE TABLE WORK.FILTER_FOR_SURVEILLANCEFORMVAX AS 
   SELECT t1.EventID, 
          t1.VaccinationDate, 
          t1.VaccinationManufacturer
      FROM NEWCEDRS.SurveillanceFormVax t1
      WHERE t1.VaccinationManufacturer = 1406 OR t1.VaccinationManufacturer = 4140 OR t1.VaccinationManufacturer = 1424 
           OR t1.VaccinationManufacturer = 1435; 
QUIT; 


/* create new table that matches on eventid to cedrs_view, to eliminate eventids that are not in 2021*/;
PROC SQL; 
	create table SurFmVax_cedrs as	

	select * from work.filter_for_cedrs_view as x , work.FILTER_FOR_SURVEILLANCEFORMVAX as y
		where x.eventid = y.eventid;
QUIT; 

PROC CONTENTS data=work.SurFmVax_cedrs; 
RUN; 

/* Answer: N = 130,135 */;


/*Q3a: How many eventids are coming in from cedrs.SurveillanceFormVax that are VB?*/;

PROC FREQ data=work.SurFmVax_cedrs;
	tables breakthrough; 
RUN; 
/* Answer: N = 112,448 */;


/*Q3b: How many eventids are coming in from cedrs.SurveillanceFormVax that are VB+B?*/;

PROC FREQ data=work.SurFmVax_cedrs;
	tables breakthrough_booster; 
RUN; 

/* Answer: N = 24,784 */;


/************************************************************/;
/*Q4: Who doesn't exist in ciis.case_iz (CIIS Entry) but is in SurveillanceFormVax (manual data entry)?*/

DATA case_iz_exp;
	set work.case_cedrs_combi; 

	retain eventid ciis_vax;

	Ciis_vax = 1; */Used to track those entries coming in from CIIS*/;

	drop manufacturer_code vaccination_code vaccination_date; 

RUN; 

DATA surv_vax_form; 
	set work.SurFmVax_cedrs; 

	retain EventID ciis_vax;

	Ciis_vax = 0;  */Used to track those entries coming in from manual entry*/;

	drop VaccinationDate VaccinationManufacturer; 

RUN; 

PROC SORT data=case_iz_exp;
	by eventid;
RUN; 

PROC SORT data=surv_vax_form;
	by eventid; 
RUN; 

/*Combine the two datafiles */;

DATA combine; 
	set case_iz_exp
		surv_vax_form;
RUN; 

PROC CONTENTS data=work.combine; 
RUN; 

/* Total N = 571,391*/;

PROC SORT data=combine nodupkey dupout=combine_dups; /*remove duplicates in both imported files*/
 	by eventid; 
RUN; 

PROC CONTENTS data=work.combine; 
RUN; 
		/* work.combine, N = 449,987. These eventids were unique to each */;

PROC CONTENTS data=work.combine_dups; 
RUN; 
/* ANSWER: work.combine_dups, N = 121,404. These eventids were in both: surveillanceformvax & ciis.case_iz*/;


/************************************************************/;
/* Q5: How many were only from manual entry?*/;

PROC FREQ data=combine;
	tables ciis_vax;
RUN;

/*ANSWER: Manual entry, N = 8,731  							*/
	/* Came in from CIIS: 441,256 - answer to Q2			*/
	/* Came in from Surveillanceformvax (mannually): 8,731 */;


/************************************************************/;

/* PART 2: Evaluate Manual Entry vaccinations: How Complete are the manual entries?*/;


/* Extract only those eventids that are manual entry, ciis_vax = 0*/;
DATA manual_entry;
	set work.combine;

	if ciis_vax = 0 then output; 

RUN;

/* N = 8,731 */;

/* Merge with SurveillanceFormVax to get additional hand entry variables*/;

PROC SQL;
	create table manual_exp as 
		select * from NEWCEDRS.SurveillanceFormVax as x

		left join manual_entry as y 

		on x.eventid = y.eventid;
QUIT; 

/* Select only those we are manual entry for COVID*/;

DATA manual_exp1;
	set manual_exp; 

	if ciis_vax = 0 then output; 

RUN; 

/* Manual_exp1 has 16,705 observations. The variable EventID has more than one vaccination record per EventID.  */;

PROC SORT data=work.manual_exp1; 
	by EventID; 
RUN; 

PROC FREQ Data=manual_exp1;
	tables VaccinationManufacturer; 
RUN;

PROC FREQ Data=manual_exp1;
	tables DoseSourceOther; 
RUN;

DATA manual_lotnu;
	set manual_exp1;

	if lotnumber = '' then output;
RUN; 


/******** END OF CODE **************/;
