
/*****************************************************************************************************/
/** 	Evaluate Larimer County in COPHS															**/
/**																									**/
/**																									**/															   
/**		Requested by: Alicia Cronquist, Nina LPHA in Larimer										**/
/**		Written by: M. Pike, June 20, 2022															**/
/**																									**/
/**		Outputs: Evaluates COPHS/CEDRS for missing hospitalizations									**/
/*****************************************************************************************************/

libname covid	 odbc dsn='COVID19' 	    schema=dbo		READ_LOCK_TYPE=NOLOCK; /* 144 - DBO */;
libname covcase	 odbc dsn='COVID19' 	    schema=cases	READ_LOCK_TYPE=NOLOCK; /* 144 - Cases */;
libname hospital odbc dsn='COVID19' 		schema=hospital READ_LOCK_TYPE=NOLOCK; /* 144 - Hospitals */;
libname ciis	 odbc dsn='COVID19' 		schema=ciis 	READ_LOCK_TYPE=NOLOCK; /* 144 - ciis population data */;
libname archive 'O:\Programs\Other Pathogens or Responses\2019-nCoV\Vaccine Breakthrough\07_Data\archive';

DATA COPHS_larimer;
	set work.cophs_hospitalization_2022_06_17; 

	format 'Hospital.Admission.Date...MM.DD.'n mmddyy10. 'dob..mm.dd.yyyy.'n mmddyy10.; 
	
RUN;

DATA COPHS_larimer2;
	set cophs_larimer;


	hospital_admission_date = 'Hospital.Admission.Date...MM.DD.'n; 
	dob='dob..mm.dd.yyyy.'n;

	format hospital_admission_date mmddyy10. dob mmddyy10.;

	drop 'Hospital.Admission.Date...MM.DD.'n 'dob..mm.dd.yyyy.'n; 
	
RUN;


PROC SQL;
   CREATE TABLE WORK.CEDRS AS 
   SELECT t1.profileid, 
          t1.eventid, 
          t1.hospitalized_cophs, 
          t1.hospitalized, 
          t1.cophs_admissiondate, 
          t1.countyassigned
      FROM COVID.cedrs_view t1
      WHERE t1.countyassigned = 'Larimer';
QUIT;


proc sql;
create table covid19_birthday
	as select distinct 	EventID, Birthdate

	from covcase.covid19_cedrs
;
quit;

/*Merge Cedrs_view with Profiles to bring in birthdate */; 

proc sql;
	create table bday_cedrs
		
	as select distinct *
	from work.cedrs as p
	left join work.covid19_birthday q on p.EventID = q.EventID
;
quit; 

DATA CEDRS_clean;
	set bday_cedrs;

	hospital_admission_date = input('cophs_admissiondate'n, yymmdd10.);
	dob = input('birthdate'n, yymmdd10.);

	format hospital_admission_date mmddyy10. dob mmddyy10.;

	if hospitalized = 1 then output; 
RUN;


/* What is missing ?*/;

PROC SORT data=COPHS_larimer2; by dob hospital_admission_date; RUN;
PROC SORT data=CEDRS_clean;  by dob hospital_admission_date; RUN; 

DATA  match nomatch ;
	merge COPHS_larimer2 (in=a) CEDRS_clean (in=b) ;
	by dob hospital_admission_date;
	if a and b then output match ;
	else output nomatch ;
RUN ;

DATA test; 
	set nomatch;

	if Hospitalized_cophs = 0 and hospitalized = 1 then output;
RUN; 


DATA larimer_noCEDRS; 
	set nomatch;

	if Hospitalized_cophs = . and hospitalized = . then output;
RUN; 

/*END OF CODE*/;

