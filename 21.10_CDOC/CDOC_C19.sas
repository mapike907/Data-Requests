/* COVID-19 Among CDOC  *************  Written by M.Pike 8 OCT 2021										*/
/*																		*/
/* Purpose: Find COVID-19 Case Data utilizing CDOC's CEDR ID LIST  										*/
/*			Find COVID-19 Cases among Vaccinated and UnVax Staff   									*/
/*																   		*/
/* IN:	J:\Programs\Other Pathogens or Responses\2019-nCoV\Vaccine Breakthrough\04_Internal VB Data Requests\CDOC_5 OCT 2021\CDOC_ALL_8OCT21	*/
/*																   		*/
/* Outfile: WORK.FILTER_FOR_CDOC_ALLCASES containing all VB Cases among staff, idp			   					*/
/*																   		*/
/************************************************************************************************************************************************/;

libname severdbo odbc dsn='COVID19' schema=cases 	READ_LOCK_TYPE=NOLOCK;;
libname severson odbc dsn='COVID19' schema=dbo 		READ_LOCK_TYPE=NOLOCK;;
libname newcedrs odbc dsn='CEDRS_3_READ' schema=CEDRS 	READ_LOCK_TYPE=NOLOCK;
RUN;


DATA WORK.CDOC_ALL_8OCT21_0001;
    LENGTH
        CEDRS_ID         $ 55
        Last_Name        $ 19
        FirstName        $ 13
        Date_Birth         8
        Person             8 ;
    FORMAT
        CEDRS_ID         $CHAR55.
        Last_Name        $CHAR19.
        FirstName        $CHAR13.
        Date_Birth       DATE9.
        Person           BEST12. ;
    INFORMAT
        CEDRS_ID         $CHAR55.
        Last_Name        $CHAR19.
        FirstName        $CHAR13.
        Date_Birth       DATE9.
        Person           BEST12. ;
    INFILE 'C:\Users\mapike\AppData\Local\Temp\1\SEG18976\CDOC_ALL_8OCT21-6f9bff32ce0240a493ebd36b698ad554.txt'
        LRECL=78
        ENCODING="WLATIN1"
        TERMSTR=CRLF
        DLM='7F'x
        MISSOVER
        DSD ;
    INPUT
        CEDRS_ID         : $CHAR55.
        Last_Name        : $CHAR19.
        FirstName        : $CHAR13.
        Date_Birth       : BEST32.
        Person           : BEST32. ;
RUN;

DATA WORK.CDOC_ALL;
	set WORK.CDOC_ALL_8OCT21_0001; 
	format DOB yymmdd10. eventid 10.;
	DOB=put(date_birth, yymmdd10.);
	eventid=input(cedrs_id, 10.);
	
RUN; 
	

DATA CDOC_CEDRS;
	set severdbo.covid19_cedrs; 
RUN; 


/****************************************************************************************************************************************************************************/
/*MERGE CDOC AND CEDRS TO GET EVENT ID*********************************************************************************************************************************/
/**************************************************************************************************************************************************************************/

PROC SQL;
	CREATE TABLE MERGE AS
		SELECT A.*,  B.Last_Name, B.FirstName, B.Person, B.DOB, B.eventid

	FROM CDOC_CEDRS A LEFT JOIN CDOC_ALL B
	ON A.firstname =b.firstname and a.lastname=b.last_name and a.birthdate=b.DOB;

QUIT;

PROC SORT data=work.MERGE nodupkey;
	by eventid;
RUN; 


DATA CDOC_MERGE;
	Set merge;

	if person = 1 or person = 2 then output;  /* person = 1 is Staff; Person = 2 is IDP */

RUN; 

PROC SORT data=work.CDOC_MERGE; 
	by person;
RUN; 

PROC MEANS data= work.cdoc_merge;
	by person;
RUN;

PROC SQL;
	CREATE TABLE MERGE2 AS
		SELECT A.*,  B.Last_Name, B.FirstName, B.Person, B.DOB, B.eventid

	FROM CDOC_MERGE A LEFT JOIN CDOC_ALL B
	ON A.firstname =b.firstname and a.lastname=b.last_name and a.birthdate=b.DOB;

QUIT;

/****************************************************************************************************************************************************************************/
/*GET VB INFO FROM CEDRS_VIEW ID********************************************************************************************************************************************/
/**************************************************************************************************************************************************************************/

DATA CDOC_VB;
	Set severson.cedrs_view;
	keep eventid earliest_collectiondate breakthrough vaccine_received partialonly; 
RUN;

PROC SQL;
	CREATE TABLE MERGE3 AS
		SELECT A.*,  B.earliest_collectiondate, b.breakthrough, b.vaccine_received, b.partialonly, B.eventid

	FROM MERGE2 A LEFT JOIN CDOC_VB B
	ON A.eventid = b.eventid;

QUIT; 


PROC SORT data=work.MERGE3 nodupkey;
	by eventid;
RUN; 

PROC SORT data=work.MERGE3;
	by person;
RUN; 

PROC MEANS data= work.Merge3;
	by person;
RUN;


/* Create Month Variable */; 

DATA CDOC_ALLCASES;
	SET work.Merge3; 

	Testdt = input(earliest_collectiondate, yymmdd10.) ;  
	pos_month = month(testdt);      	/*Note if using the code after Nov 2021, you need to code for Month & Year as this data will have Dec 2020 (as month 12)*/

RUN; 


/*Reduce to time frame Jan 2021 to Sept 2021 */; 


PROC SQL;
   CREATE TABLE WORK.FILTER_FOR_CDOC_ALLCASES AS 
   SELECT t1.profileid, 
          t1.eventid, 
          t1.reinfection, 
          t1.lastname, 
          t1.firstname, 
          t1.birthdate, 
          t1.exposurefacilityname, 
          t1.earliest_collectiondate, 
          t1.Testdt, 
          t1.pos_month, 
          t1.Person, 
          t1.partialonly, 
          t1.breakthrough, 
          t1.vaccine_received
      FROM WORK.CDOC_ALLCASES t1
      WHERE t1.earliest_collectiondate >= '2021-01-01' AND t1.earliest_collectiondate <= '2021-09-30';
QUIT;

PROC SORT data=FILTER_FOR_CDOC_ALLCASES;
	by person;
RUN; 

PROC MEANS data= FILTER_FOR_CDOC_ALLCASES;
	by person;
RUN;

DATA CDOC_CASES_ALL;
	set work.filter_for_cdoc_allcases; 
RUN;
 
DATA CDOC_STAFF; 
	set Work.filter_for_cdoc_allcases; 
	if person = 1 then output;
RUN; 

DATA CDOC_IDP;
	set work.filter_for_cdoc_allcases; 
	if person = 2 then output;
RUN;

/*STAFF ANALYSIS */

PROC FREQ data=work.cdoc_staff;  /* ALL cases in Staff between 01 Jan and 30 Sept 2021 */
	tables pos_month;
	title 'All C19 Infections Among Staff by Month 2021';
RUN; 

PROC FREQ data=work.cdoc_staff;  /* VB cases in Staff between 01 Jan and 30 Sept 2021 */
	tables pos_month*breakthrough / nocol nopercent norow;
	title 'VB C19 Infections Among Staff by Month 2021';
RUN; 

PROC FREQ data=work.cdoc_staff;  /* Reinfection cases in Staff between 01 Jan and 30 Sept 2021 */
	tables pos_month*reinfection / nocol nopercent norow;
	title 'Reinfection C19 Infections Among Staff by Month 2021';
RUN; 

/* IDP ANALYSIS */

PROC FREQ data=work.cdoc_idp;  /* ALL cases in Staff between 01 Jan and 30 Sept 2021 */
	tables pos_month;
	title 'All C19 Infections Among IDP by Month 2021';
RUN; 

PROC FREQ data=work.cdoc_idp;  /* VB cases in Staff between 01 Jan and 30 Sept 2021 */
	tables pos_month*breakthrough / nocol nopercent norow;
	title 'VB C19 Infections Among IDP by Month 2021';
RUN; 

PROC FREQ data=work.cdoc_idp;  /* Reinfection cases in Staff between 01 Jan and 30 Sept 2021 */
	tables pos_month*reinfection / nocol nopercent norow;
	title 'Reinfection C19 Infections IDP Staff by Month 2021';
RUN; 

/*ALL CDOC ANALYSIS */

PROC FREQ data=work.cdoc_cases_all;  /* ALL cases at CDOC between 01 Jan and 30 Sept 2021 */
	tables pos_month;
	title 'All C19 Infections Among CDOC by Month 2021';
RUN; 

PROC FREQ data=work.cdoc_cases_all; /* VB cases at CDOC between 01 Jan and 30 Sept 2021 */
	tables pos_month*breakthrough / nocol nopercent norow;
	title 'VB C19 Infections Among CDOC by Month 2021';
RUN; 

PROC FREQ data=work.cdoc_cases_all;  /* Reinfection casesat CDOC between 01 Jan and 30 Sept 2021 */
	tables pos_month*reinfection / nocol nopercent norow;
	title 'Reinfection C19 Infections Among CDOC by Month 2021';
RUN; 


/*********** END OF CODE *********************************************************************************************************/
