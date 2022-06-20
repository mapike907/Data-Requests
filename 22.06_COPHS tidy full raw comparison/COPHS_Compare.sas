

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
/* 6/16/22: COPHS_full, N = 62,283 */;

PROC MEANS data=hospital.cophs_tidy;
	title 'means cophs_tidy';
RUN; 
/* 6/16/22: COPHS_tidy, N = 72,476 with eventIDs in only 55,493*/;

/*How many missing eventIDs in cophs_tidy?*/;
DATA tidy_missing;
	set hospital.cophs_tidy;

	if eventid = . then output;
RUN;
/* 6/16/22: Missing eventIDs = 17,515 */;

/*Import raw file from K drive from 6/16/22 and rename variables to match cophs_tidy*/;

DATA raw;
	set work.expanded_format_covid_patient_da; 

	format hospital_admission_date $18. dob mmddyy10.;

	rename 'MR Number'n = mr_number 'First Name'n = first_name 'Last Name'n = last_name 'Hospital Admission Date  (MM/DD/'n = hospital_admission_date; 
RUN; 
/* 6/16/22: Raw, N = 62,283 */;


/*create local version of hospital.cophs_tidy*/;

DATA cophs_tidy;
	set hospital.cophs_tidy; 
RUN; 

/*create local version of hospital.cophs_full*/;

DATA cophs_full;
	set hospital.cophs_full; 
		rename 'MR Number'n = mr_number 'First Name'n = first_name 'Last Name'n = last_name 'Hospital Admission Date  (MM/DD/'n = hospital_admission_date 'DOB (MM/DD/YYYY)'n=dob; 
RUN; 

/********************************************************************************************************************************************************************************/;
/* How many duplicates in COPHS_tidy?*/;

PROC SORT data=cophs_tidy nodupkey dupout=cophs_tidy_dups; by first_name last_name dob; RUN;

PROC MEANS data=cophs_tidy; 
	title 'means cophs_tidy_nodups';
RUN;

/* How many duplicate in COPHS_full?*/;

Data cophs_full1;
	set cophs_full;
	bday = input('DOB (MM DD YYYY)'n,yymmdd10.);
	format bday mmddyy10.;
RUN;

Data cophs_full2;
	set cophs_full1 (rename=(bday=dob));
RUN;



PROC SORT data=cophs_full2 nodupkey dupout=cophs_full2_dups; by first_name last_name dob; RUN;

PROC MEANS data=cophs_full; 
	title 'means cophs_full_nodups';
RUN;

/* How many duplciate mr_numbers in raw?*/; 
PROC SORT data=raw nodupkey dupout=raw_dups; by first_name last_name dob; RUN;

PROC MEANS data=raw_dups; 
	title 'means ';
RUN;

/*************************************************************************************************************/;

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
	set raw_short;
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

/* How many duplicates are in tidy_short2 and raw_short2?*/;

PROC SORT data=tidy_short2; by first_name last_name dob; RUN;
PROC SORT data=raw_short2;  by first_name last_name dob; RUN; 

DATA  match nomatch ;
	merge raw_short2 (in=a) tidy_short2 (in=b) ;
	by first_name last_name dob;
	if a and b then output match ;
	else output nomatch ;
RUN ;



PROC SORT data=tidy_short2; by first_name last_name hospital_admission_date dob; RUN;
PROC SORT data=raw_short2;  by first_name last_name hospital_admission_date dob; RUN; 

DATA  match2 nomatch2 ;
	merge raw_short2 (in=a) tidy_short2 (in=b) ;
	by first_name last_name hospital_admission_date dob;
	if a and b then output match2 ;
	else output nomatch2 ;
RUN ;



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

/* 6/16/22: N = 1 observation.*/;


/* Matches both name, dob hospital_admission_date = match; if does not match = nomatch */;

PROC SORT data=raw_short2; by first_name last_name hospital_admission_date; RUN;
PROC SORT data=tidy_short2; by first_name last_name hospital_admission_date; RUN;

DATA  match3 nomatch3 ;
	merge raw_short (in=a) tidy_short2 (in=b) ;
	by first_name last_name hospital_admission_date;
	if a and b then output match3 ;
	else output nomatch3 ;
RUN ;
/* mr_number and hospital_admission_date do not match in 2 records*/;


/* Matches mr_number, first name, last name, admission date = match2; if does not match = nomatch2 */;

PROC SORT data=raw_short2; by first_name last_name hospital_admission_date dob; RUN;
PROC SORT data=tidy_short2; by first_name last_name hospital_admission_date dob; RUN;

DATA  match4 nomatch4 ;
	merge raw_short2 (in=a) tidy_short2 (in=b) ;
	by first_name last_name  hospital_admission_date dob;
	if a and b then output match4 ;
	else output nomatch4;
RUN ;
/* mr_number, first name, last name and hospital_admission_date do not match in 8 records*/;


/* Matches mr_number, first name, last name, admission date, dob = match2a; if does not match = nomatch2a */;

PROC SORT data=raw_short2; by mr_number first_name last_name hospital_admission_date dob; RUN;
PROC SORT data=tidy_short2; by mr_number first_name last_name hospital_admission_date dob; RUN;

DATA  match2a nomatch2a ;
	merge raw_short2 (in=a) tidy_short2 (in=b) ;
	by mr_number first_name last_name  hospital_admission_date dob;
	if a and b then output match2a ;
	else output nomatch2a ;
RUN ;
/* mr_number, first name, last name, hospital_admission_date, and dob do not match in 8 records*/;

/********************************************************************************************************************************************************************************/;


/*QUESTION: What cases are in full that are not in tidy?*/;


PROC SQL;
   CREATE TABLE FULL_SHORT AS 
   SELECT t1.'MR Number'n, 
          t1.'Last Name'n, 
          t1.'First Name'n, 
          t1.'Hospital Admission Date  (MM DD 'n, 
          t1.'DOB (MM DD YYYY)'n
      FROM HOSPITAL.cophs_full t1;
QUIT;

DATA full_short2;
	set full_short; 
		rename 'MR Number'n = mr_number 'First Name'n = first_name 'Last Name'n = last_name 'Hospital Admission Date  (MM/DD/'n = hospital_admission_date 'DOB (MM DD YYYY)'n=dob; 
RUN; 


/*format hosptial_admission_date in full_short*/;

DATA full_out;
	set work.full_short2;

	date = input('Hospital Admission Date  (MM DD'n,yymmdd10.);

	format date mmddyy10.;

	
RUN;

/*renaming date to hospital_admission_date*/;

DATA full_short2b;
	set full_out (rename=(date=hospital_admission_date));
		date2 = input(dob,yymmdd10.); 
	format date2 mmddyy10.;
	drop 'Hospital Admission Date  (MM DD'n dob; 
RUN;

DATA full_short2c;
	set full_short2b (rename=(date2=dob));
RUN;


/*subquery: use NOT IN operator, which tells system not to include records from dataset2 (full_short2)
A PROC SQL subquery returns a single row and column. This method uses a subquery in its SELECT 
clause to select ID from table two. The subquery is evaluated first, and then it returns the id from 
table two to the outer query.*/;

/* Compare data by mr_number */;
PROC SQL;
	create table In_Full_Not_Tidy as
	select * from full_short2c
	where mr_number not in (select mr_number from tidy_short2);
QUIT;
/* ANSWER: N = 0 observations */;

/* Matches both mr_number and hospital_admission_date = match3; if does not match = nomatch3 */;

PROC SORT data=full_short2c nodupkey dupout=full_short2c_dup; by mr_number hospital_admission_date; RUN;
PROC SORT data=tidy_short2 nodupkey dupout=tidy_short_dup; by mr_number hospital_admission_date; RUN;

DATA  match3 nomatch3 ;
	merge full_short2c (in=a) tidy_short2 (in=b) ;
	by mr_number hospital_admission_date;
	if a and b then output match3 ;
	else output nomatch3 ;
RUN ;

/* mr_number and hospital_admission_date do not match in 0 records*/;

Proc sort data=nomatch3 nodupkey dupout=nomatch3_dup; by mr_number hospital_admission_date; RUN;


/* Matches mr_number, first name, last name, admission date = match4; if does not match = nomatch4 */;

PROC SORT data=full_short2c; by mr_number first_name last_name hospital_admission_date; RUN;
PROC SORT data=tidy_short2; by mr_number first_name last_name hospital_admission_date; RUN;

DATA  match4 nomatch4 ;
	merge full_short2c (in=a) tidy_short2 (in=b) ;
	by mr_number first_name last_name  hospital_admission_date;
	if a and b then output match4 ;
	else output nomatch4 ;
RUN ;

/* mr_number, first name, last name and hospital_admission_date do not match in 2 records*/;


/* Matches mr_number, first name, last name, admission date, dob = match5; if does not match = nomatch5 */;

PROC SORT data=full_short2c; by mr_number first_name last_name hospital_admission_date dob; RUN;
PROC SORT data=tidy_short2; by mr_number first_name last_name hospital_admission_date dob; RUN;

DATA  match5 nomatch5 ;
	merge full_short2c (in=a) tidy_short2 (in=b) ;
	by mr_number first_name last_name  hospital_admission_date;
	if a and b then output match5 ;
	else output nomatch5 ;
RUN ;

/********************************************************************************************************************************************************************************/;


/*QUESTION: What cases are in full that are missing in tidy?*/;


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
/* NoMatch4: N= 2 obs. Same person, duplicate for mr_number, name, admit date */;


/* How many hospitalized in cedrs_view? */;

PROC FREQ data=covid.cedrs_view; 
	tables hospitalized; 
	title 'hospitalized';
RUN; 

PROC FREQ data=covid.cedrs_view; 
	tables hospitalized_cophs; 
	title 'hospitalized_cophs';
RUN; 


/*what cases are in RAW that are not in cedrs for hospitalized*/;

/*need to pull names from cedrs to match to raw file*/;

PROC SQL;
   CREATE TABLE WORK.QUERY_FOR_COVID19_CEDRS AS 
   SELECT t1.eventid, 
          t1.firstname, 
          t1.lastname, 
          t1.birthdate, 
          t1.hospitalizedyesno, 
          t1.hospitalizedid
      FROM COVCASE.covid19_cedrs t1;
QUIT;

PROC contents data=work.query_for_covid19_cedrs; run; 

PROC FREQ data=work.query_for_covid19_cedrs; 
	tables hospitalizedyesno; 
RUN;

/*format data*/;

DATA CEDRS;
	set work.query_for_covid19_cedrs (rename=(firstname=first_name lastname=last_name)); 
	dob = input(birthdate,yymmdd10.);
	format dob mmddyy10.; 

	if hospitalizedyesno= 'Yes' then output;

drop birthdate;

RUN; 

PROC SORT data=raw_short2 nodup dupout=raw_short2_dup; by first_name last_name dob ; RUN;
PROC SORT data=cedrs nodup dupout=cedrs_dup; by first_name last_name dob; RUN;

DATA  match6 nomatch6 ;
	merge raw_short2 (in=a) cedrs (in=b) ;
	by first_name last_name dob;
	if a and b then output match6 ;
	else output nomatch6 ;
RUN ;
/* match6 = 45,434 and nomatch6 = 33,870.*/;


/* Left join raw file to cedrs to look for matches and compare to match6*/;

proc sql;
	create table raw_cedrs		
	as select distinct *
	from work.raw_short2 as p
	left join work.cedrs q on p.first_name = q.first_name and p.last_name = q.last_name and p.dob=q.dob;
quit; 
/* Matches: N = 59,245 */;

DATA raw_cedrs_eventid;
	set raw_cedrs;

	if eventid = . then output;
RUN; 
/* EventID is missing in 13,438*/;

/*Duplicates in raw_cedrs?*/;
PROC SORT data=raw_cedrs nodup dupout=raw_cedrs_dup; by mr_number ; RUN;/*no dups*/;


/* what happens when we compare raw to zDSI_events?*/;

PROC SQL;
   CREATE TABLE WORK.QUERY_FOR_ZDSI_EVENTS AS 
   SELECT t1.EventID, 
          t1.Disease, 
          t1.HospitalizedYesNo
      FROM NEWCEDRS.zDSI_Events t1
	  where disease = 'COVID-19';
QUIT;


proc sql;
	create table raw_cedrs		
	as select distinct *
	from work.raw_short2 as p
	left join work.cedrs q on p.first_name = q.first_name and p.last_name = q.last_name and p.dob=q.dob;
quit; 


PROC SORT data=cedrs_tidy nodupkey dupout=cedrs_tidy2_dup; by eventid; RUN; 
PROC SORT data=work..raw_short2 nodupkey dupout=raw_dup; by eventid; run; 


DATA  match7 nomatch7 ;
	merge cedrs_ (in=a) work.raw_short2 (in=b) ;
	by eventid;
	if a and b then output match7 ;
	else output nomatch7;
RUN ;

start
/*trouble here == want to pull out the hosptialized = yes - SAS not liking it!*/;

Data nomatch;
	set nomatch7;

	if hospitalizedyesno = 'no' then hosp = 0;
		else if hospitalizedyesno = '' then hosp = 0;
		else if hospitalizedyesno = 'yes' then hosp = 1;

	format hosp 2.;

RUN; 


proc sql;
	create table cedrs_tidy3
		
	as select distinct *
	from work.cedrs_tidy as p
	left join work.QUERY_FOR_ZDSI_EVENTS q on p.eventid = q.eventid
;
quit; 

PROC SORT data=cedrs_tidy3 nodupkey dupout=cedrs_tidy3_dup; by mr_number; RUN; 

Data clean1; 
	set cedrs_tidy3;

	if disease = '' then output;
RUN;


/*END OF CODE*/;

