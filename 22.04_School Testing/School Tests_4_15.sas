/*****************************************************************************************************/
/** 	School COVID Testing: Antigen and Molecular													**/
/**															  				   						**/					**/
/**																									**/															   
/** 																								**/
/**		Written by: M. Pike, April 11, 2022															**/
/*****************************************************************************************************/;


libname elr_dw	 odbc dsn='ELR_DW' 			schema=dbo 		READ_LOCK_TYPE=NOLOCK; /*138 - DBO,ELR */;
libname c19_tst	 odbc dsn='COVID19' 	    schema=tests	READ_LOCK_TYPE=NOLOCK; /* 144 - Tests */;
libname covid19  odbc dsn='Tableau' 		schema=ciis 	READ_LOCK_TYPE=NOLOCK; /* 144 - CIIS */;
libname covid	 odbc dsn='COVID19' 	    schema=dbo		READ_LOCK_TYPE=NOLOCK; /* 144 - DBO */;
libname covcase	 odbc dsn='COVID19' 	    schema=cases	READ_LOCK_TYPE=NOLOCK; /* 144 - DBO */;
libname archive 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Vaccine Breakthrough\07_Data\archive';

/* Pull from ELR */;

PROC SQL;
   CREATE TABLE WORK.ELR_Data AS 
   SELECT t1.patientid, 
          t1.date_of_birth, 
          t1.gender, 
          t1.collectiondate, 
          t1.test_loinc,
          t1.covid19negative
      FROM ELR_DW.viewPatientTestELR t1
	  WHERE t1.CollectionDate >= '5Sep2021:0:0:0'dt AND t1.Date_of_Birth >= '01/01/2001';
QUIT;


PROC SQL;
   CREATE TABLE WORK.FILTER_FOR_ELR_DATA AS 
   SELECT t1.PatientID, 
          t1.Date_of_Birth, 
          t1.Gender, 
          t1.CollectionDate, 
          t1.Test_LOINC, 
          t1.COVID19Negative
      FROM WORK.ELR_DATA t1
      WHERE t1.Test_LOINC = '94558-4' OR t1.Test_LOINC = '95209-3' OR t1.Test_LOINC = '95209-4'
			OR t1.Test_LOINC = '97097-0' OR t1.Test_LOINC ='96119-3' OR t1.Test_LOINC ='94500-6'
			OR t1.Test_LOINC = '94309-2' OR t1.Test_LOINC ='94533-7' OR t1.Test_LOINC ='94845-5'
			OR t1.Test_LOINC = '94534-5' OR t1.Test_LOINC ='95409-9' OR t1.Test_LOINC ='94531-1'
			OR t1.Test_LOINC = '96448-6' OR t1.Test_LOINC ='41458-1' OR t1.Test_LOINC ='94565-9'
			OR t1.Test_LOINC = '95406-5' OR t1.Test_LOINC ='99999-9' OR t1.Test_LOINC ='94559-2'
			OR t1.Test_LOINC = '94760-6' OR t1.Test_LOINC ='94759-8' OR t1.Test_LOINC ='96094-8'
			OR t1.Test_LOINC = '414458-1' OR t1.Test_LOINC ='94306-8' OR t1.Test_LOINC ='94640-0'
			OR t1.Test_LOINC = '94756-4' OR t1.Test_LOINC ='94757-2' OR t1.Test_LOINC ='94568-9'
			OR t1.Test_LOINC = '95425-5' OR t1.Test_LOINC ='94502-2' OR t1.Test_LOINC ='96986-5'
			OR t1.Test_LOINC = '95608-6';
QUIT;

DATA elr_data2;
	set WORK.FILTER_FOR_ELR_DATA; 

	format collectdt mmddyy10. dob mmddyy10.;

	collectdt = datepart(collectiondate);
	dob = input(date_of_birth, mmddyy10.);

RUN;

DATA elr_data3;
	set elr_data2;

	format age 3.;

	age_days = collectdt - dob; 

	age = (age_days/365);

RUN;

DATA elr_age;
	set work.elr_data3; 

	if age >= 5 and age <= 17 then output;

	drop collectdt dob age_days; 

RUN; 

Data archive.elr_tests; 
	set elr_age;
RUN;

/***************************/;
/***************************/;

/*Acquire all PCR tests*/;

PROC SQL;
   CREATE TABLE WORK.FILTER_FOR_PCR_VIEW AS 
   SELECT t1.patientid, 
          t1.date_of_birth, 
          t1.gender, 
          t1.collectiondate, 
          t1.result, 
          t1.test_type, 
          t1.covid19negative
      FROM COVID.pcr_view t1;
QUIT;

/* Calculate age from date_of_birth to collectiondate */;
/* Filter for ages 5 to 17 YO */;

DATA pcr_view_age;
	set WORK.FILTER_FOR_PCR_VIEW; 

	format age 3.;

	Collect_dt = input(collectiondate, yymmdd10.);
	dob = input(date_of_birth, yymmdd10.);

	age_days = collect_dt - dob; 

	age = (age_days/365);
RUN;

DATA pcr_age;
	set work.pcr_view_age; 

	Type_of_test = 'Molecular';

	if age >= 5 and age <= 17 then output;

	drop collect_dt dob age_days; 

RUN; 

/* work.pcr_age, N = 1513506 */;

/*******************************************/;
/*******************************************/;

/*Acquire all Antigen tests*/;

PROC SQL;
   CREATE TABLE WORK.FILTER_FOR_ANTIGEN AS 
   SELECT t1.patientid, 
          t1.date_of_birth, 
          t1.gender, 
          t1.collectiondate, 
		  t1.result, 
          t1.test_type, 
          t1.covid19negative
      FROM C19_TST.antigen t1;
QUIT;


/* Calculate age from date_of_birth to collectiondate */;
/* Filter for ages 5 to 17 YO */;

DATA antigen_age;
	set WORK.FILTER_FOR_ANTIGEN; 

	format age 3.;

	Collect_dt = input(collectiondate, yymmdd10.);
	dob = input(date_of_birth, yymmdd10.);

	age_days = collect_dt - dob; 

	age = (age_days/365);
RUN;

DATA antigen_age;
	set work.antigen_age; 

	Type_of_test = 'Antigen'; 

	if age >= 5 and age <= 17 then output;

	drop collect_dt dob age_days; 

RUN; 
/* Antigen_age, N = 338145 */;

/*******************************************/;
/*******************************************/;


/* Combine PCR and Antigen into one file for Tableau */
/* Select for dates 9/5/2021 to present */;

DATA School_tests_a;
	set work.pcr_age
		work.antigen_age;

	if collectiondate >= '2021-09-05' then output;

RUN; 

/* 
NOTE: There were 1513506 observations read from the data set WORK.PCR_AGE.
NOTE: There were 338145 observations read from the data set WORK.ANTIGEN_AGE.
NOTE: The data set WORK.SCHOOL_TESTS has 978500 observations and 9 variables.
*/;

/* Create Week Variable */;

DATA school_tests_b;
	set school_tests_a;

	format week 3.;

	if collectiondate >= '2021-09-05' and collectiondate <= '2021-09-11' then week = 1;
		else if collectiondate >= '2021-09-12' and collectiondate <= '2021-09-18' then week = 2;
		else if collectiondate >= '2021-09-19' and collectiondate <= '2021-09-25' then week = 3;
		else if collectiondate >= '2021-09-26' and collectiondate <= '2021-10-02' then week = 4;
		else if collectiondate >= '2021-10-03' and collectiondate <= '2021-10-09' then week = 5; 

		else if collectiondate >= '2021-10-10' and collectiondate <= '2021-10-16' then week = 6;
		else if collectiondate >= '2021-10-17' and collectiondate <= '2021-10-23' then week = 7;
		else if collectiondate >= '2021-10-24' and collectiondate <= '2021-10-30' then week = 8;
		else if collectiondate >= '2021-10-31' and collectiondate <= '2021-11-06' then week = 9; 
		else if collectiondate >= '2021-11-07' and collectiondate <= '2021-11-13' then week = 10;

		else if collectiondate >= '2021-11-14' and collectiondate <= '2021-11-20' then week = 11;
		else if collectiondate >= '2021-11-21' and collectiondate <= '2021-11-27' then week = 12;
		else if collectiondate >= '2021-11-28' and collectiondate <= '2021-12-04' then week = 13;
		else if collectiondate >= '2021-12-05' and collectiondate <= '2021-12-11' then week = 14;
		else if collectiondate >= '2021-12-12' and collectiondate <= '2021-12-18' then week = 15; 

		else if collectiondate >= '2021-12-19' and collectiondate <= '2021-12-25' then week = 16;
		else if collectiondate >= '2021-12-26' and collectiondate <= '2022-01-01' then week = 17;
		else if collectiondate >= '2022-01-02' and collectiondate <= '2022-01-08' then week = 18;
		else if collectiondate >= '2022-01-09' and collectiondate <= '2022-01-15' then week = 19;
		else if collectiondate >= '2022-01-16' and collectiondate <= '2022-01-22' then week = 20;

		else if collectiondate >= '2022-01-23' and collectiondate <= '2022-01-29' then week = 21;
		else if collectiondate >= '2022-01-30' and collectiondate <= '2022-02-05' then week = 22;
		else if collectiondate >= '2022-02-06' and collectiondate <= '2022-02-12' then week = 23;
		else if collectiondate >= '2022-02-13' and collectiondate <= '2022-02-19' then week = 24;
		else if collectiondate >= '2022-02-20' and collectiondate <= '2022-02-26' then week = 25;
		
		else if collectiondate >= '2022-02-27' and collectiondate <= '2022-03-05' then week = 26;
		else if collectiondate >= '2022-03-06' and collectiondate <= '2022-03-12' then week = 27;
		else if collectiondate >= '2022-03-13' and collectiondate <= '2022-03-19' then week = 28;
		else if collectiondate >= '2022-03-20' and collectiondate <= '2022-03-26' then week = 29;
		else if collectiondate >= '2022-03-27' and collectiondate <= '2022-04-02' then week = 30;
		else if collectiondate >= '2022-04-03' and collectiondate <= '2022-04-09' then week = 31;

		else if collectiondate >= '2022-04-10' and collectiondate <= '2022-04-16' then week = 32;

RUN; 

DATA school_tests_c;
	set school_tests_b;

	format wk $15.;

	if week = 1 then wk = '9/5-9/11';
		else if week = 2 then wk = '9/12-9/18';
		else if week = 3 then wk = '9/19-9/25';
		else if week = 4 then wk = '9/26-10/2';
		else if week = 5 then wk = '10/3-10/9';

		else if week = 6 then wk = '10/10-10/16';
		else if week = 7 then wk = '10/17-10/23';
		else if week = 8 then wk = '10/24-10/30';
		else if week = 9 then wk = '10/31-11/6';
		else if week = 10 then wk = '11/7-11/13';

		else if week = 11 then wk = '11/14-11/20';
		else if week = 12 then wk = '11/21-11/27';
		else if week = 13 then wk = '11/28-12/4';
		else if week = 14 then wk = '12/5-12/11';
		else if week = 15 then wk = '12/12-12/18';

		else if week = 16 then wk = '12/19-12/25';
		else if week = 17 then wk = '12/26-1/1';
		else if week = 18 then wk = '1/2-1/8';
		else if week = 19 then wk = '1/9-1/15';
		else if week = 20 then wk = '1/16-1/22';

		else if week = 21 then wk = '1/23-1/29';
		else if week = 22 then wk = '1/30-2/5';
		else if week = 23 then wk = '2/6-2/12';
		else if week = 24 then wk = '2/13-2/19';
		else if week = 25 then wk = '2/20-2/26';
		
		else if week = 26 then wk = '2/27-3/5';
		else if week = 27 then wk = '3/6-3/12';
		else if week = 28 then wk = '3/13-3/19';
		else if week = 29 then wk = '3/20-3/26';
		else if week = 30 then wk = '3/27-4/2';

		else if week = 31 then wk = '4/3-4/9';
		else if week = 32 then wk = '4/10-4/16';

RUN; 

/* Data Checks */;

DATA missing;
	set work.school_tests_c; 

	if week = . then output;
RUN;
/* 1 missing: Collection date is 2022-12-27 and is likely entered incorrectly. Omitting this record */;

DATA school_tests;
	set work.school_tests_c; 
	
	if patientid = 22043434 then delete;

RUN;

/* Finish checking data */;

PROC FREQ data=School_tests;
	tables age; 
	title 'ages';
RUN; 

PROC FREQ data=School_tests;
	tables week; 
	title 'week';
RUN; 

PROC FREQ data=School_tests;
	tables wk; 
	title 'wk';
RUN; 

PROC FREQ data=School_tests;
	tables Type_of_test; 
	title 'Type_of_test';
RUN; 

PROC FREQ data=School_tests;
	tables collectiondate; 
	title 'collection date';
RUN;

PROC FREQ data=School_tests;
	tables covid19negative;
	title 'covid19negative';
RUN;

/* Use export tool on SAS Enterprise Guide: work.school_tests. */;

/* END OF CODE*/ ; 








