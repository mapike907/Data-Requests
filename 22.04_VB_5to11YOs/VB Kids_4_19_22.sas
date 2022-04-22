
/*****************************************************************************************************/
/** 	Vaccine Breakthrough and Hospitalizations among 5-11 YOs									**/
/**		Q: How do cases and hospitalizations among 5-11 YOs compare to those 12-17?					**/
/**																									**/															   
/**		Requested by: Rachel Herlihy																**/
/**		Written by: M. Pike, April 18, 2022															**/
/**																									**/
/*****************************************************************************************************/

libname covid	 odbc dsn='COVID19' 	    schema=dbo		READ_LOCK_TYPE=NOLOCK; /* 144 - DBO */;
libname covcase	 odbc dsn='COVID19' 	    schema=cases	READ_LOCK_TYPE=NOLOCK; /* 144 - DBO */;
libname tableau  odbc dsn='COVID19' 		schema=ciis 	READ_LOCK_TYPE=NOLOCK; /* population data */;
libname archive 'J:\Programs\Other Pathogens or Responses\2019-nCoV\Vaccine Breakthrough\07_Data\archive';

/*Step 1: Obtain cases from cedrs_view*/;

PROC SQL;
   CREATE TABLE WORK.FILTER_FOR_CEDRS_VIEW AS 
   SELECT t1.profileid, 
          t1.eventid, 
          t1.earliest_collectiondate,
		  t1.reinfection, 
          t1.age_at_reported, 
          t1.hospitalized_cophs, 
          t1.cophs_admissiondate, 
          t1.breakthrough, 
		  t1.breakthrough_booster,
          t1.vax_firstdose, 
          t1.vax_booster, 
          t1.vax_utd
      FROM COVID.cedrs_view t1
      WHERE t1.earliest_collectiondate >= '2021-12-07'; 
QUIT;

/* Step 2: Create data file with just cases for kids age 5-11 */;

DATA Kids_COVID;
	set work.filter_for_cedrs_view;

	format age_grp $6.; 

	age_grp = '5-11';

	if age_at_reported >= 5 and age_at_reported =< 11 then output;

RUN;

PROC FREQ data=kids_covid;
	tables age_at_reported;
	title 'age at reported';
RUN; 

/* Step 3: Create data file with just cases for persons > 12+ */; 

Data Kids12_17_COVID;
	set work.filter_for_cedrs_view; 

	format age_grp $6.;

	age_grp = '12-17';

	if age_at_reported >= 12 and age_at_reported <= 17 then output;

RUN;

PROC FREQ data=Kids12_17_covid;
	tables age_at_reported;
	title 'age at reported';
RUN; 


/* Step 4: Merge two files and create variable STATUS for Tableau. Export to archive folder. */;

DATA  archive.All_cases_4_19_22;
	set kids_COVID
		kids12_17_COVID;

	format status $10.;

	if breakthrough = 1 and breakthrough_booster = 0 then status = 'VB';
		else if breakthrough = 0 and breakthrough_booster = 0 then status = 'Unvax';

	if breakthrough = 1 and breakthrough_booster = 1 then status = 'VBB'; 

	if earliest_collectiondate >= '2021-04-18' then output;

RUN; 


/* Step 5: Obtain population data for the midpoint date: 02/10/22 */;

PROC SQL;
   CREATE TABLE WORK.FILTER_FOR_VAXUNVAX_ADDTNL_AGE AS 
   SELECT t1.age, 
          t1.date, 
          t1.total_fully_vaccinated_addtnl, 
          t1.total_fully_vaccinated, 
          t1.total_not_fully_vaccinated
      FROM TABLEAU.vaxunvax_addtnl_age t1
      WHERE t1.date = '2022-02-10';
QUIT;

/* Filter for age group*/;

DATA Pop_Vax_UnVax;
	Set WORK.FILTER_FOR_VAXUNVAX_ADDTNL_AGE;

	format agegrp $6.;

 	if age >= 5 and age <= 11 then agegrp = '5-11';
		else if age >= 12 and age <= 17 then agegrp = '12-17';

RUN; 


DATA Pop_Vax_UnVax_b;
	set work.pop_vax_unvax; 

	if age >=5 and age <= 17 then output;

RUN;


/* Create at table that sums all the population by agegrp */;

PROC SQL; 

	create table population as
 	select 	
			date, 
			agegrp, 
          	total_fully_vaccinated, 
          	total_not_fully_vaccinated,

	sum(total_fully_vaccinated) as Sum_total_fully_vax,
	sum(total_not_fully_vaccinated) as Sum_total_unvaxed

	FROM work.Pop_Vax_UnVax_b
	GROUP BY agegrp;
QUIT; 

/* Keep the first agegrp to get the sum for rate calculation */;

DATA population_210;
	set population;
	by agegrp;
 
	keep date agegrp Sum_total_fully_vax Sum_total_unvaxed; 

	if first.agegrp then output; 

RUN; 


/* END OF CODE */;