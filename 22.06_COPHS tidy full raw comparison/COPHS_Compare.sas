

/********************************************************/
/** 	COPHS Analysis for Tye						   **/
/**													   **/
/** 	Comparing Cophs_tidy to Cophs_full to Raw	   **/
/**													   **/
/**		Written by: M. Pike, June 13, 2022			   **/															
/********************************************************/; 


libname newcedrs 	odbc dsn='CEDRS_3_read' schema=CEDRS 	READ_LOCK_TYPE=NOLOCK; /*66 - CEDRS */;
libname covcase	 	odbc dsn='COVID19' 	    schema=cases	READ_LOCK_TYPE=NOLOCK; /* 144 - cases */;
libname hospital	odbc dsn='COVID19'		schema=hospital READ_LOCK_TYPE=NOLOCK; /* 144 - Hospitals */;
libname elr_dw	 	odbc dsn='ELR_DW' 		schema=dbo		READ_LOCK_TYPE=NOLOCK; /* ELR */;
libname archive 'O:\Programs\Other Pathogens or Responses\2019-nCoV\Vaccine Breakthrough\07_Data\archive';

/* How many cases?*/;

PROC MEANS data=hospital.cophs_full;
	title 'means cophs_full';
RUN; 
/* COPHS_full, N = 62,201 */;

PROC MEANS data=hospital.cophs_tidy;
	title 'means cophs_tidy';
RUN; 
/* COPHS_tidy, N = 72,476 with eventIDs in only 55,493*/;

/*How many missing eventIDs in cophs_tidy?*/;
DATA tidy_missing;
	set hospital.cophs_tidy;

	if eventid = . then output;
RUN;
/* Missing eventIDs = 16,983 */;



/*Import raw file from K drive from 6/13/22 and rename variables to match cophs_tidy*/;

DATA raw;
	set work.expanded_format_covid_patient_da; 

	format hospital_admission_date $18. dob mmddyy10.;

	rename 'MR Number'n = mr_number 'First Name'n = first_name 'Last Name'n = last_name 'Hospital Admission Date  (MM/DD/'n = hospital_admission_date; 
RUN; 
/* Raw, N = 61,726 */;


/*create local version of hospital.cophs_tidy*/;

DATA cophs_tidy;
	set hospital.cophs_tidy; 
RUN; 

/*create local version of hospital.cophs_full*/;

DATA cophs_full;
	set hospital.cophs_full; 
		rename 'MR Number'n = mr_number 'First Name'n = first_name 'Last Name'n = last_name 'Hospital Admission Date  (MM/DD/'n = hospital_admission_date 'DOB (MM/DD/YYYY)'n; 
RUN; 

/********************************************************************************************************************************************************************************/;


/*QUESTION: What cases are in raw that are not in tidy?*/;

/* Compare data by mr_number, pull a shortened version of what's on the server */;
PROC SQL;
   CREATE TABLE RAW_SHORT AS 
   SELECT t1.mr_number, 
          t1.last_name, 
          t1.first_name, 
          t1.hospital_admission_date, 
          t1.'DOB (MM/DD/YYYY)'n
      FROM WORK.RAW t1;
QUIT;

DATA raw_short2;
	set raw_out;
	dob = 'DOB (MM/DD/YYYY)'n; 
	format dob mmddyy10.;
	drop bday;
RUN;

PROC SQL;
   CREATE TABLE TIDY_SHORT AS 
   SELECT t1.mr_number, 
          t1.last_name, 
          t1.first_name, 
          t1.hospital_admission_date, 
          t1.dob
      FROM HOSPITAL.cophs_tidy t1;
QUIT;

/*format hosptial_admission_date in tidy_short*/;

DATA tidy_out;
	set tidy_short;

	date = input(hospital_admission_date,yymmdd10.);
	bday = input(dob,yymmdd10.);
	format date mmddyy10. bday mmddyy10.;
	drop hospital_admission_date dob; 
	
RUN;

/*renaming date to hospital_admission_date*/;

DATA tidy_short2;
	set tidy_out (rename=(date=hospital_admission_date) rename=(bday=dob));
RUN;

/*subquery: use NOT IN operator, which tells system not to include records from dataset2 (tidy_short2)
A PROC SQL subquery returns a single row and column. This method uses a subquery in its SELECT 
clause to select ID from table two. The subquery is evaluated first, and then it returns the id from 
table two to the outer query.*/;

/* Compare data by mr_number */;
PROC SQL;
	create table In_Raw_Not_Tidy as
	select * from raw_short2
	where mr_number not in (select mr_number from tidy_short2);
QUIT;

/* N = 7082 observations, duplicate mr_numbers are in this output but hospital_admission_dates appear to be different */;


/* Matches both mr_number and hospital_admission_date = match; if does not match = nomatch */;

PROC SORT data=raw_short; by mr_number hospital_admission_date; RUN;
PROC SORT data=tidy_short2; by mr_number hospital_admission_date; RUN;

DATA  match nomatch ;
	merge raw_short (in=a) tidy_short2 (in=b) ;
	by mr_number hospital_admission_date;
	if a and b then output match ;
	else output nomatch ;
RUN ;
/* mr_number and hospital_admission_date do not match in 7,604 records*/;


/* Matches mr_number, first name, last name, admission date = match2; if does not match = nomatch2 */;

PROC SORT data=raw_short; by mr_number first_name last_name hospital_admission_date; RUN;
PROC SORT data=tidy_short2; by mr_number first_name last_name hospital_admission_date; RUN;

DATA  match2 nomatch2 ;
	merge raw_short (in=a) tidy_short2 (in=b) ;
	by mr_number first_name last_name  hospital_admission_date;
	if a and b then output match2 ;
	else output nomatch2 ;
RUN ;
/* mr_number, first name, last name and hospital_admission_date do not match in 7,610 records*/;


/* Matches mr_number, first name, last name, admission date, dob = match2a; if does not match = nomatch2a */;

PROC SORT data=raw_short2; by mr_number first_name last_name hospital_admission_date dob; RUN;
PROC SORT data=tidy_short2; by mr_number first_name last_name hospital_admission_date dob; RUN;

DATA  match2a nomatch2a ;
	merge raw_short2 (in=a) tidy_short2 (in=b) ;
	by mr_number first_name last_name  hospital_admission_date dob;
	if a and b then output match2a ;
	else output nomatch2a ;
RUN ;
/* mr_number, first name, last name, hospital_admission_date, and dob do not match in 7,610 records*/;

/********************************************************************************************************************************************************************************/;


/*QUESTION: What cases are in full that are not in tidy?*/;

PROC SQL;
   CREATE TABLE FULL_SHORT AS 
   SELECT t1.mr_number, 
          t1.last_name, 
          t1.first_name, 
          t1.'Hospital Admission Date  (MM DD'n, 
          t1.'DOB (MM DD YYYY)'n
      FROM WORK.COPHS_FULL t1;
QUIT;


/*format hosptial_admission_date in full_short*/;


DATA full_out;
	set full_short;

	date = input('Hospital Admission Date  (MM DD'n,yymmdd10.);
	bday = input('dob (mm dd yyyy)'n,yymmdd10.);

	format date mmddyy10. bday mmddyy10.;

	
RUN;

/*renaming date to hospital_admission_date*/;

DATA full_short2;
	set full_out (rename=(date=hospital_admission_date) rename=(bday=dob));
	drop 'Hospital Admission Date  (MM DD'n  'DOB (MM DD YYYY)'n; 
RUN;


/*subquery: use NOT IN operator, which tells system not to include records from dataset2 (full_short2)
A PROC SQL subquery returns a single row and column. This method uses a subquery in its SELECT 
clause to select ID from table two. The subquery is evaluated first, and then it returns the id from 
table two to the outer query.*/;

/* Compare data by mr_number */;
PROC SQL;
	create table In_Full_Not_Tidy as
	select * from full_short2
	where mr_number not in (select mr_number from tidy_short2);
QUIT;
/* ANSWER: N = 0 observations */;

/* Matches both mr_number and hospital_admission_date = match3; if does not match = nomatch3 */;

PROC SORT data=full_short2; by mr_number hospital_admission_date; RUN;
PROC SORT data=tidy_short2; by mr_number hospital_admission_date; RUN;

DATA  match3 nomatch3 ;
	merge full_short2 (in=a) tidy_short2 (in=b) ;
	by mr_number hospital_admission_date;
	if a and b then output match3 ;
	else output nomatch3 ;
RUN ;

/* mr_number and hospital_admission_date do not match in 0 records*/;


/* Matches mr_number, first name, last name, admission date = match4; if does not match = nomatch4 */;

PROC SORT data=full_short2; by mr_number first_name last_name hospital_admission_date; RUN;
PROC SORT data=tidy_short2; by mr_number first_name last_name hospital_admission_date; RUN;

DATA  match4 nomatch4 ;
	merge full_short2 (in=a) tidy_short2 (in=b) ;
	by mr_number first_name last_name  hospital_admission_date;
	if a and b then output match4 ;
	else output nomatch4 ;
RUN ;

/* mr_number, first name, last name and hospital_admission_date do not match in 2 records*/;



/********************************************************************************************************************************************************************************/;


/*QUESTION: What cases are in tidy that are not in full?*/;


/*subquery: use NOT IN operator, which tells system not to include records from dataset2 (full_short2)
A PROC SQL subquery returns a single row and column. This method uses a subquery in its SELECT 
clause to select ID from table two. The subquery is evaluated first, and then it returns the id from 
table two to the outer query.*/;

/* Compare data by mr_number */;
PROC SQL;
	create table In_Tidy_Not_Full as
	select * from tidy_short2
	where mr_number not in (select mr_number from full_short2);
QUIT;
/* ANSWER: N = 0 observations */;

/* Matches both mr_number and hospital_admission_date = match5; if does not match = nomatch5 */;

PROC SORT data=full_short2 nodup dupout=full_short2dup; by mr_number hospital_admission_date; RUN;
PROC SORT data=tidy_short2 nodup dupout=tidy_short2dup; by mr_number hospital_admission_date; RUN;

DATA  match5 nomatch5 ;
	merge tidy_short2 (in=a) full_short2 (in=b) ;
	by mr_number hospital_admission_date;
	if a and b then output match5 ;
	else output nomatch5 ;
RUN ;
/* mr_number and hospital_admission_date do not match in 0 records*/;


/* Matches mr_number, first name, last name, admission date = match4; if does not match = nomatch4 */;

PROC SORT data=full_short2; by mr_number first_name last_name hospital_admission_date; RUN;
PROC SORT data=tidy_short2; by mr_number first_name last_name hospital_admission_date; RUN;

DATA  match4 nomatch4 ;
	merge full_short2 (in=a) tidy_short2 (in=b) ;
	by mr_number first_name last_name  hospital_admission_date;
	if a and b then output match4 ;
	else output nomatch4 ;
RUN ;

/*END OF CODE*/;

