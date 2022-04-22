
/***	Questions around differences in Vax data from line list vs aggregate			   	**/
/**													**/
/**													**/
/**		Written by: M. Pike, April 22, 2022							**/
/**													**/
/*********************************************************************************************************/

libname newcedrs odbc dsn='CEDRS_3_read' 	schema=CEDRS 	READ_LOCK_TYPE=NOLOCK; /*66 - CEDRS */;
libname covidvax odbc dsn='covid_vaccine' 	schema=tab 	READ_LOCK_TYPE=NOLOCK; /* 138 - CIIS */;
libname covcase	 odbc dsn='COVID19' 	    	schema=cases	READ_LOCK_TYPE=NOLOCK; /* 144 - DBO */;
libname covid	 odbc dsn='COVID19' 	    	schema=dbo	READ_LOCK_TYPE=NOLOCK; /* 144 - DBO */;
libname covid19  odbc dsn='Tableau' 		schema=ciis 	READ_LOCK_TYPE=NOLOCK; /* 144 - CIIS */;


/* DATA PULL 1 - this is code from the vaccine breakthrough linelist*/;

/*pull vaccinations from ciis.case_iz, creates variable vax_date from vaccination_date */; 
proc sql;
create table vaccines
as select distinct v.EventID, v.vaccination_date, input(v.vaccination_date, anydtdtm.) as Vax_Date format=dtdate9., v.Vaccination_Code

	from covid19.case_iz v

	order by v.EventID, vax_date
;
quit;

/*Create DOSE variable that begins at first eventid and numbers doses 1 to whatever number of doses received*/;

data vaccines2;
	set vaccines;
	dose + 1;
	by eventid;
	if first.eventID then dose = 1;
run;

/*transpose the axes prior to joining*/;

proc transpose data=vaccines2 out=wide1 prefix=vax_date_;
	by eventid;
	id dose;
	var vax_date;
 run;

 proc transpose data=vaccines2 out=wide2 prefix=manufacturer_code_;
	by eventid;
	id dose;
	var vaccination_code;
 run;

/* Merge the two output files (wide1 and wide2) by eventid. This has all vaccination dates, and all vaccine manufacturers*/;

data ciis_vax_all;
	merge wide1 wide2;
	by eventID;
	drop _name_ _label_;
run;

/* Pull vaccines from CEDRS grid */;
proc sql;
create table vaccines_cedrs
as select distinct v.EventID, v.VaccinationDate,
	v.VaccinationManufacturer

	from NewCedrs.SurveillanceFormVax v
	left join NewCEDRS.zDSI_Events e on v.EventID = e.EventID

	where e.disease ='COVID-19'

	order by v.EventID, v.VaccinationDate

;
quit;

/* get doses in correct order*/;

data vaccines_cedrs;
	set vaccines_cedrs;
	dose + 1;
	by eventid;
	if first.eventID then dose = 1;
run;

/* Transpose variables to make tables appropriate for joining/merging later */;
 
proc transpose data=vaccines_cedrs out=wide1b prefix=vax_date_;
	by eventid;
	id dose;
	var VaccinationDate;
 run;

 proc transpose data=vaccines_cedrs out=wide2b prefix=VaccinationManufacturer_;
	by eventid;
	id dose;
	var VaccinationManufacturer;
 run;


/* merge all wide files into cedrs_vax_all & fix manufacturer codes */;

data cedrs_vax_all;
	merge wide1b wide2b;
	by eventID;
	drop _name_ _label_;

if VaccinationManufacturer_1 = 1406 then manufacturer_code_1 = 'COVID-19 Vector-NR (JSN)';
	else if VaccinationManufacturer_1 = 4140 then manufacturer_code_1 = 'COVID-19 mRNA (MOD)';
	else if VaccinationManufacturer_1 = 1424 then manufacturer_code_1 = 'COVID 12+yrs PURPLE CAP';
	else if VaccinationManufacturer_1 = 1435 then manufacturer_code_1 = 'COVID-19 UF';
if manufacturer_code_1 = '' then manufacturer_code_1 = 'COVID-19 UF';

if VaccinationManufacturer_2 = 1406 then manufacturer_code_2 = "COVID-19 Vector-NR (JSN)";
	else if VaccinationManufacturer_2 = 4140 then manufacturer_code_2 = 'COVID-19 mRNA (MOD)';
	else if VaccinationManufacturer_2 = 1424 then manufacturer_code_2 = 'COVID 12+yrs PURPLE CAP';
	else if VaccinationManufacturer_2 = 1435 then manufacturer_code_2 = 'COVID-19 UF';	 

if VaccinationManufacturer_3 = 1406 then manufacturer_code_3 = "COVID-19 Vector-NR (JSN)";
	else if VaccinationManufacturer_3 = 4140 then manufacturer_code_3 = 'COVID-19 mRNA (MOD)';
	else if VaccinationManufacturer_3 = 1424 then manufacturer_code_3 = 'COVID 12+yrs PURPLE CAP';
	else if VaccinationManufacturer_3 = 1435 then manufacturer_code_3 = 'COVID-19 UF';
	else manufacturer_code_3 = '';	 

if VaccinationManufacturer_4 = 1406 then manufacturer_code_4 = "COVID-19 Vector-NR (JSN)";
	else if VaccinationManufacturer_4 = 4140 then manufacturer_code_4 = 'COVID-19 mRNA (MOD)';
	else if VaccinationManufacturer_4 = 1424 then manufacturer_code_4 = 'COVID 12+yrs PURPLE CAP';
	else if VaccinationManufacturer_4 = 1435 then manufacturer_code_4 = 'COVID-19 UF';
	else manufacturer_code_4 = "";	

if VaccinationManufacturer_5 = 1406 then manufacturer_code_5 = "COVID-19 Vector-NR (JSN)";
	else if VaccinationManufacturer_5 = 4140 then manufacturer_code_5 = 'COVID-19 mRNA (MOD)';
	else if VaccinationManufacturer_5 = 1424 then manufacturer_code_5 = 'COVID 12+yrs PURPLE CAP';
	else if VaccinationManufacturer_5 = 1435 then manufacturer_code_5 = 'COVID-19 UF';
	else Manufacturer_code_5 = "";
 
DROP 	VaccinationManufacturer_1 VaccinationManufacturer_2 VaccinationManufacturer_3 
		VaccinationManufacturer_4 VaccinationManufacturer_5 VaccinationManufacturer_6; 

run;

/* COMBINE: Merge CEDRS & CIIS vax data*/;

data combine_datapull_1;
	set Ciis_vax_all cedrs_vax_all (in=i); 
	if i then CIIS = "2";   
		else CIIS = "1";
run;

/***Identify duplicates and drop duplicates***/;
proc sort data=combine_datapull_1;
	by EventID CIIS;
run;

proc sort data=combine_datapull_1 nodupkey;
	by EventID;
run;



/***************************************/;
/***************************************/;
/***************************************/;

/* DATA PULL 2 - This is code translated from R code written by R.Severson and Mayra*/;

/*Pull cases from Cedrs_III_Wearhouse (cedrs_view) */;

PROC SQL;
   CREATE TABLE cases_Cedrs3WH AS 
   SELECT DISTINCT 	eventid, 
       				profileid, 
					age_at_reported,
          			breakthrough, 
          			partialonly, 
          			outcome, 
          			deathdate, 
          			earliest_collectiondate, 
          			vaccine_received, 
          			vax_utd
      FROM COVID.cedrs_view;
QUIT;

/*Pull birthdays from covcase.covid19_cedrs & left join to work.cases_Cedrs3WH and all_case_iz */;

PROC SQL;
   CREATE TABLE birthday AS 
   SELECT DISTINCT	eventid, 
          			birthdate
      FROM COVCASE.covid19_cedrs;
QUIT;

/* create table cases from cases_cedrs3WH and left join birthday and ciis.all_case_iz*/;

PROC SQL;
	CREATE TABLE cases AS

	SELECT DISTINCT e.*, s.*, z.* 	 

	FROM cases_Cedrs3WH e

	LEFT JOIN birthday s on e.eventid = s.eventid  
	LEFT JOIN covid19.all_case_iz z on e.eventid = z.eventid ; 

QUIT; 

/*remove any missing patient_id*/;

DATA all_cases;
	set cases;

	if patient_id = . then delete; 

RUN;


PROC MEANS data=all_cases;
RUN;

/*N = 1,025,541 */;


/*Pull vaccination doses and dates from covid_vaccine.tab.patient_UTD_Status and left join with tab.LPHA_Patients*/;

 PROC SQL;
 	CREATE TABLE doses AS

	SELECT DISTINCT e.*, s.patient_id, s.vaccination_date, s.vaccination_code

	FROM covidvax.Patient_UTD_Status e
	LEFT JOIN covidvax.LPHA_Patients s on e.patient_id = s.patient_id
	;
QUIT; 

/*Grab manual entry & filter for COVID, from cedrs.SuveillanceFormVax and left join zDSI_Events*/; 

PROC SQL;
	CREATE TABLE cases_manual AS

	SELECT DISTINCT e.eventid, z.disease, e.VaccinationDate, e.vaccinationmanufacturer, e.deleted, z.eventid, 
			z.disease

	FROM newcedrs.SurveillanceFormVax e

	LEFT JOIN newcedrs.zDSI_Events z on e.Eventid = z.eventid
		WHERE e.deleted ne 1 and e.EventId ne . AND z.disease = 'COVID-19'
	
	GROUP BY e.eventid
; 
QUIT; 

/*N = 5,408*/;

/*Combine all_cases, doses, cases_manual into table cases_doses */;

PROC SQL;
	CREATE TABLE cases_doses AS

	SELECT DISTINCT e.*, s.*, z.*

	FROM all_cases e 
	LEFT JOIN doses s on e.EventID = s.Patient_ID
	LEFT JOIN cases_manual z on e.EventID = z.EventID

	GROUP BY e.EventID

	; 
QUIT; 

/* COMBINE Pull 1 and 2 to compare differences: File provided in email */;

PROC SQL; 
	CREATE TABLE combine AS

	SELECT DISTINCT e.*, z.*

	FROM cases_doses e

	LEFT JOIN combine_datapull_1 z on e.EventID = z.EventID

	GROUP BY e.EventID
;
QUIT; 

 
/* QUESTIONS? 
	(1) Dates for "first_vacc_date" do not match Vax_date_1.
 
	(2) UTD_on (up to date on) does not match the final vaccination date "Vax_date_X". 
		For instance, 
			EventID 534003, First_vacc_date: 6 APR 2021; UTD_on: 06 APR 2021, Vax_date_4 = 01 APR 2021. 
			EventID 534130, First_vacc_date: 6 APR 2021; UTD_on: 27 APR 2021; Vax_date_1: 10 MAY 2021; Vax_date_2: 07 JUNE 21

*/;
























proc sql;
create table vaccines
as select distinct v.EventID, v.vaccination_date, input(v.vaccination_date, anydtdtm.) as Vax_Date format=dtdate9., v.Vaccination_Code

	from covid19.case_iz v

	order by v.EventID, vax_date
;
quit;

data vaccines2;
	set vaccines;
	dose + 1;
	by eventid;
	if first.eventID then dose = 1;
run;

proc transpose data=vaccines2 out=wide1 prefix=vax_date_;
	by eventid;
	id dose;
	var vax_date;
 run;

 proc transpose data=vaccines2 out=wide2 prefix=manufacturer_code_;
	by eventid;
	id dose;
	var vaccination_code;
 run;


/* This has all vaccination dates, and all vaccine manufacturers*/;

data ciis_vax_all;
	merge wide1 wide2;
	by eventID;
	drop _name_ _label_;
run;
