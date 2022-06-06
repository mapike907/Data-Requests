
/*****************************************************************************************************/
/** 	Request: Create a data viz that is similar to Seattle King County for VB, VBB, Unvaccinated	**/
/**																									**/
/**																									**/															   
/**		Requested by: Alicia Cronquist and Kaitlin Harame											**/
/**		Written by: M. Pike, May 16, 2022															**/
/**																									**/
/**		Creates output for Tableau																	**/
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
		  t1.age_at_reported,
		  t1.hospitalized_cophs,
		  t1.reinfection, 
          t1.breakthrough, 
		  t1.breakthrough_booster
      FROM COVID.cedrs_view t1
      WHERE t1.earliest_collectiondate >= '2022-03-01'; 
QUIT;


/*Step 2: Create Age Groups for the numerator */;

DATA VB_data;
	set work.filter_for_cedrs_view; 

	format status $20. age $18.;

		/*age with traditional CDPHE agegroups */;

	if age_at_reported >= 5 and age_at_reported <= 11 then age = '5-11';
		else if age_at_reported >= 12 and age_at_reported <= 17 then age = '12-17';
		else if age_at_reported >= 18 and age_at_reported <= 24 then age = '18-24';
		else if age_at_reported >= 25 and age_at_reported <= 29 then age = '25-29';
		else if age_at_reported >= 30 and age_at_reported <= 39 then age = '30-39';
		else if age_at_reported >= 40 and age_at_reported <= 49 then age = '40-49';
		else if age_at_reported >= 50 and age_at_reported <= 59 then age = '50-59';
		else if age_at_reported >= 60 and age_at_reported <= 69 then age = '60-69';
		else if age_at_reported >= 70 and age_at_reported <= 79 then age = '70-79';
		else if age_at_reported >= 80 then age = '80+';
		else if age_at_reported <= 4 then age = '0-4';
	
	if breakthrough = 1 and breakthrough_booster = 0 then status = 'Vaccinated';
		else if breakthrough = 0 and breakthrough_booster = 0 then status = 'Unvaccinated';

	if breakthrough = 1 and breakthrough_booster = 1 then status = 'Boosted'; 

RUN; 

DATA VB_march;
	set VB_Data; 
	month = 'march';
	if earliest_collectiondate >= '2022-03-01' and earliest_collectiondate =< '2022-03-31' then output;
RUN;

DATA VB_april;
	set VB_Data; 
	month = 'april';
	if earliest_collectiondate >= '2022-04-01' and earliest_collectiondate =< '2022-04-30' then output;
RUN;

DATA VB_may;
	set VB_Data; 
	month = 'may';
	if earliest_collectiondate >= '2022-05-01' and earliest_collectiondate =< '2022-05-16' then output;
RUN;

/*Step 3: Get the counts of each age group*/;

PROC FREQ data=VB_March;
	tables status*age*month / out=work.VB_cases_march nocol nocum norow nopercent; 
	title 'Sum of Age, by agegroup';
RUN;

PROC FREQ data=VB_April;
	tables status*age*month / out=work.VB_cases_april nocol nocum norow nopercent; 
	title 'Sum of Age, by agegroup';
RUN;

PROC FREQ data=VB_May;
	tables status*age*month / out=work.VB_cases_may nocol nocum norow nopercent; 
	title 'Sum of Age, by agegroup';
RUN;

DATA VB_Combi;
	set work.VB_cases_march
		work.VB_cases_april
		work.VB_cases_may;
RUN;

DATA Hosp_march;
	set VB_march; 
	
	if hosptialized_cophs = 1 then output;
RUN;

DATA Hosp_april;
	set VB_april; 
	
	if hosptialized_cophs = 1 then output;
RUN;

DATA Hosp_may;
	set VB_may; 
	
	if hosptialized_cophs = 1 then output;
RUN;


PROC FREQ data=Hosp_march;
	tables status*age*month / out=work.VB_hoscases_march nocol nocum norow nopercent; 
	title 'Sum of Age, by agegroup';
RUN;

PROC FREQ data=Hosp_april;
	tables status*age*month / out=work.VB_hoscases_april nocol nocum norow nopercent; 
	title 'Sum of Age, by agegroup';
RUN;

PROC FREQ data=Hosp_may;
	tables status*age*month / out=work.VB_hoscases_may nocol nocum norow nopercent; 
	title 'Sum of Age, by agegroup';
RUN;

/*Step 4: Pull Population Data, i.e. Denominatior: 15th each month */;

PROC SQL;
   CREATE TABLE population AS 
   SELECT *
      FROM TABLEAU.vaxunvax_addtnl_age
      WHERE date = '2022-03-15' or date = '2022-04-15' or date = '2022-05-15';
QUIT;

/*Step 4a: Population, March 2022*/;
DATA Pop_March;
	set population;
	
	month = 'march';

	format agegroup $9.;

	if age >= 5 and age <= 11 then agegroup = '5-11';
		else if age >= 12 and age <= 17 then agegroup = '12-17';
		else if age >= 18 and age <= 24 then agegroup = '18-24';
		else if age >= 25 and age <= 29 then agegroup = '25-29';
		else if age >= 30 and age <= 39 then agegroup = '30-39';
		else if age >= 40 and age <= 49 then agegroup = '40-49';
		else if age >= 50 and age <= 59 then agegroup = '50-59';
		else if age >= 60 and age <= 69 then agegroup = '60-69';
		else if age >= 70 and age <= 79 then agegroup = '70-79';
		else if age >= 80 then agegroup = '80+';
		else if age <= 4 then agegroup = '0-4';

	if date = '2022-03-15' then output;
RUN;

PROC SQL; 

	create table Pop_sum_031522 as
 	select 	date, 
			month,
			agegroup,
			total_not_fully_vaccinated,
			total_fully_vaccinated,
			total_fully_vaccinated_addtnl,
         
	sum(total_not_fully_vaccinated) as Sum_Unvax,
	sum(total_fully_vaccinated) as Sum_vaxed,
	sum(total_fully_vaccinated_addtnl) as Sum_boosted

	FROM pop_march
	GROUP BY agegroup;
QUIT; 

DATA march_pop;
	set Pop_sum_031522; 

	by agegroup;

	if first.agegroup then output;

	drop total_fully_vaccinated total_fully_vaccinated_addtnl total_not_fully_vaccinated; 
RUN;


/*Step 4b: Population, April 2022*/;

DATA Pop_April;
	set population;

	format agegroup $9.;

	month = 'april';

	if age >= 5 and age <= 11 then agegroup = '5-11';
		else if age >= 12 and age <= 17 then agegroup = '12-17';
		else if age >= 18 and age <= 24 then agegroup = '18-24';
		else if age >= 25 and age <= 29 then agegroup = '25-29';
		else if age >= 30 and age <= 39 then agegroup = '30-39';
		else if age >= 40 and age <= 49 then agegroup = '40-49';
		else if age >= 50 and age <= 59 then agegroup = '50-59';
		else if age >= 60 and age <= 69 then agegroup = '60-69';
		else if age >= 70 and age <= 79 then agegroup = '70-79';
		else if age >= 80 then agegroup = '80+';
		else if age <= 4 then agegroup = '0-4';

	if date = '2022-04-15' then output;
RUN;

PROC SQL; 

	create table Pop_sum_041522 as
 	select 	age,
			month,
			agegroup,
			total_not_fully_vaccinated,
			total_fully_vaccinated,
			total_fully_vaccinated_addtnl,
         
	sum(total_not_fully_vaccinated) as Sum_Unvax,
	sum(total_fully_vaccinated) as Sum_vaxed,
	sum(total_fully_vaccinated_addtnl) as Sum_boosted

	FROM pop_april
	GROUP BY agegroup;
QUIT; 

DATA april_pop;
	set Pop_sum_041522; 

	by agegroup;

	if first.agegroup then output;

	drop age total_not_fully_vaccinated total_with_booster total_without_booster; 
RUN;


/*Step 4c: Population, May 2022*/;
Data Pop_May;
	set population;
	month = 'may';
	
	if age >= 5 and age <= 11 then agegroup = '5-11';
		else if age >= 12 and age <= 17 then agegroup = '12-17';
		else if age >= 18 and age <= 24 then agegroup = '18-24';
		else if age >= 25 and age <= 29 then agegroup = '25-29';
		else if age >= 30 and age <= 39 then agegroup = '30-39';
		else if age >= 40 and age <= 49 then agegroup = '40-49';
		else if age >= 50 and age <= 59 then agegroup = '50-59';
		else if age >= 60 and age <= 69 then agegroup = '60-69';
		else if age >= 70 and age <= 79 then agegroup = '70-79';
		else if age >= 80 then agegroup = '80+';
		else if age <= 4 then agegroup = '0-4';

	if date = '2022-05-15' then output;
	
RUN;

PROC SQL; 

	create table Pop_sum_051522 as
 	select 	age,
			month,
			date, 
			agegroup,
			total_not_fully_vaccinated,
			total_fully_vaccinated,
			total_fully_vaccinated_addtnl,
         
    
	sum(total_not_fully_vaccinated) as Sum_Unvax,
	sum(total_fully_vaccinated) as Sum_vaxed,
	sum(total_fully_vaccinated_addtnl) as Sum_boosted

	FROM pop_may
	GROUP BY agegroup;
QUIT; 

DATA may_pop;
	set Pop_sum_051522; 

	by agegroup;

	if first.agegroup then output;
	drop age total_fully_vaccinated total_fully_vaccinated_addtnl total_not_fully_vaccinated; 
RUN;

Data Combine_pop;
	set march_pop
		april_pop
		may_pop;
RUN; 








/* Calculations */;


Data Cases_Pop_vax;
	set Cases_Population_vax;

	format type $20.;

	cases_per100k = ((count/Sum_vaxed)*100000); 
	
	if  agegrp3 = '5-11' then weight = 0.0879;
		else if agegrp3 = '12-17' then weight = 0.0817;
		else if agegrp3 = '18-22' then weight = 0.0737;
		else if agegrp3 = '30-39' then weight = 0.1465550;
		else if agegrp3 = '40-49' then weight = 0.1292410;
		else if agegrp3 = '50-59' then weight = 0.1236430;
		else if agegrp3 = '60-69' then weight = 0.1113738;
		else if agegrp3 = '70-79' then weight = 0.0670162;
		else if agegrp3 = '80+'   then weight = 0.0327354;

	cases_wt = cases_per100k*weight;

	type = 'vaccinated';

RUN;


/*Step 7b: Vaccinated with Booster, LEFT JOIN, Cases and population data */;

PROC SQL;
	create table Cases_Population_boosted

	as select distinct v.age3, v.count, e.sum_vaxed_booster

	from age3_cases_sum v

	left join pop_sums_agegrp3_a e on v.age3 = e.agegrp3

;
quit;

/* Calculations */;


Data Cases_Pop_vaxbooster;
	set Cases_Population_boosted;

	format type $30.;

	cases_per100k = ((count/Sum_vaxed_booster)*100000); 
	
	if  agegrp3 = '5-11' then weight = 0.0829811;
		else if agegrp3 = '12-19' then weight = 0.1046481;
		else if agegrp3 = '20-29' then weight = 0.1460654;
		else if agegrp3 = '30-39' then weight = 0.1465550;
		else if agegrp3 = '40-49' then weight = 0.1292410;
		else if agegrp3 = '50-59' then weight = 0.1236430;
		else if agegrp3 = '60-69' then weight = 0.1113738;
		else if agegrp3 = '70-79' then weight = 0.0670162;
		else if agegrp3 = '80+'   then weight = 0.0327354;


	cases_wt = cases_per100k*weight;

	type = 'vax w booster';

RUN;


/*Step 7c: Unvaccinated, LEFT JOIN, Cases and population data */;

PROC SQL;
	create table Cases_Population_unvax

	as select distinct v.age3, v.count, e.sum_unvaxed

	from age3_cases_sum v

	left join pop_sums_agegrp3_a e on v.age3 = e.agegrp3

;
quit;

/* Calculations */;


Data Cases_Pop_unvax;
	set Cases_Population_unvax;

	format type $40.;

	cases_per100k = ((count/Sum_unvaxed)*100000); 
	
	if  agegrp3 = '5-11' then weight = 0.0829811;
		else if agegrp3 = '12-19' then weight = 0.1046481;
		else if agegrp3 = '20-29' then weight = 0.1460654;
		else if agegrp3 = '30-39' then weight = 0.1465550;
		else if agegrp3 = '40-49' then weight = 0.1292410;
		else if agegrp3 = '50-59' then weight = 0.1236430;
		else if agegrp3 = '60-69' then weight = 0.1113738;
		else if agegrp3 = '70-79' then weight = 0.0670162;
		else if agegrp3 = '80+'   then weight = 0.0327354;

	cases_wt = cases_per100k*weight;

	type = 'unvaccinated';

RUN;


DATA VB_VBB_Age_Pop;
	set Cases_Pop_vax
		Cases_Pop_vaxbooster
		Cases_Pop_unvax;

	keep age3 cases_per100k
RUN;



/*************************************************/;
/*Extra code for later*/;
	

DATA VB_data;
	set work.filter_for_cedrs_view; 

	format status $20. age $18. age2 $18. age3 $18.;

		/*age focusing on younger individuals */;
	if age_at_reported >= 5 and age_at_reported <= 11 then age = '5-11';
		else if age_at_reported >= 12 and age_at_reported <= 15 then age = '12-15';
		else if age_at_reported >= 16 and age_at_reported <= 17 then age = '16-17';
		else if age_at_reported >= 18 and age_at_reported <= 29 then age = '18-29';
		else if age_at_reported >= 30 and age_at_reported <= 49 then age = '30-49';
		else if age_at_reported >= 50 and age_at_reported <= 64 then age = '50-64';
		else if age_at_reported >= 65 then age = '65+';
		else if age_at_reported <= 4 then delete;
		
		/*age focusing on teens/college students individuals */;
	if age_at_reported >= 5 and age_at_reported <= 11 then age2 = '5-11';
		else if age_at_reported >= 12 and age_at_reported <= 17 then age2 = '12-17';
		else if age_at_reported >= 18 and age_at_reported <= 22 then age2 = '18-22';
		else if age_at_reported >= 23 and age_at_reported <= 29 then age2 = '23-29';
		else if age_at_reported >= 30 and age_at_reported <= 49 then age2 = '30-49';
		else if age_at_reported >= 50 and age_at_reported <= 64 then age2 = '50-64';
		else if age_at_reported >= 65 then age2 = '65+';
		else if age_at_reported <= 4 then delete;

		/*age with traditional CDPHE agegroups */;
	if age_at_reported >= 5 and age_at_reported <= 11 then age3 = '5-11';
		else if age_at_reported >= 12 and age_at_reported <= 17 then age3 = '12-17';
		else if age_at_reported >= 18 and age_at_reported <= 29 then age3 = '18-29';
		else if age_at_reported >= 30 and age_at_reported <= 39 then age3 = '30-39';
		else if age_at_reported >= 40 and age_at_reported <= 49 then age3 = '40-49';
		else if age_at_reported >= 50 and age_at_reported <= 59 then age3 = '50-59';
		else if age_at_reported >= 60 and age_at_reported <= 69 then age3 = '60-69';
		else if age_at_reported >= 70 then age3 = '70+';
		else if age_at_reported <= 4 then delete;
	
	if breakthrough = 1 and breakthrough_booster = 0 then status = 'Fully Vaccinated';
		else if breakthrough = 0 and breakthrough_booster = 0 then status = 'Not Fully Vaccinated';

	if breakthrough = 1 and breakthrough_booster = 1 then status = 'Boosted'; 

RUN; 

DATA age1;
	set VB_Data;

	Format type $18.;

	type = 'age group 1';

	retain eventid age status; 
	drop age_at_reported breakthrough breakthrough_booster earliest_collectiondate profileid age2 age3 reinfection; 

RUN;

DATA age2;
	set VB_Data;

	Format type $18.;

	type = 'age group 2';

	retain eventid age2 status; 
	drop age_at_reported breakthrough breakthrough_booster earliest_collectiondate profileid age1 age3 reinfection; 
RUN;

DATA END;
	set START;

	/*age focusing on younger individuals */;
	if age >= 5 and age <= 11 then agegrp1 = '5-11';
		else if age >= 12 and age <= 15 then agegrp1 = '12-15';
		else if age >= 16 and age <= 17 then agegrp1 = '16-17';
		else if age >= 18 and age <= 29 then agegrp1 = '18-29';
		else if age >= 30 and age <= 49 then agegrp1 = '30-49';
		else if age >= 50 and age <= 64 then agegrp1 = '50-64';
		else if age >= 65 then agegrp1 = '65+';
		else if age <= 4 then delete; 

	/*age focusing on teens/college students individuals */;
	if age >= 5 and age <= 11 then agegrp2 = '5-11';
		else if age >= 12 and age <= 17 then agegrp2 = '12-17';
		else if age >= 18 and age <= 22 then agegrp2 = '18-22';
		else if age >= 23 and age <= 29 then agegrp2 = '23-29';
		else if age >= 30 and age <= 49 then agegrp2 = '30-49';
		else if age >= 50 and age <= 64 then agegrp2 = '50-64';
		else if age >= 65 then agegrp2 = '65+';
		else if age <= 4 then delete; 
RUN; 


/*agegrp2*/;

PROC SQL; 

	create table Pop_sums_agegrp2 as
 	select 	age,
			date, 
			agegrp2,
			total_fully_vaccinated_addtnl, 
			total_fully_vaccinated,
			total_not_fully_vaccinated,
         
	sum(total_fully_vaccinated_addtnl) as Sum_vaxed_booster,
	sum(total_fully_vaccinated) as Sum_vaxed,
	sum(total_not_fully_vaccinated) as Sum_Unvaxed

	FROM population_1
	GROUP BY agegrp2;
QUIT; 


DATA pop_sums_agegrp2_a;
	set pop_sums_agegrp1;

	by agegrp2; 

	keep agegrp2 date Sum_Unvaxed Sum_vaxed Sum_vaxed_booster; 
	if first.agegrp2 then output;

RUN; 

DATA pop_sums_agegrp2_a1;
	set pop_sums_agegrp2_a;

	format type $15. agegrp $10.; 

	type = 'age group 2';
	agegrp = agegrp2; 

	drop date agegrp2;

RUN; 

/*agegrp3*/;

PROC SQL; 

	create table Pop_sums_agegrp3 as
 	select 	age,
			date, 
			agegrp3,
			total_fully_vaccinated_addtnl, 
			total_fully_vaccinated,
			total_not_fully_vaccinated,
         

	sum(total_fully_vaccinated_addtnl) as Sum_vaxed_booster,
	sum(total_fully_vaccinated) as Sum_vaxed,
	sum(total_not_fully_vaccinated) as Sum_Unvaxed

	FROM population_1
	GROUP BY agegrp3;
QUIT; 


DATA pop_sums_agegrp3_a;
	set pop_sums_agegrp3;

	by agegrp3; 

	keep agegrp3 date Sum_Unvaxed Sum_vaxed Sum_vaxed_booster; 
	if first.agegrp3 then output;

RUN; 

DATA pop_sums_agegrp3_a1;
	set pop_sums_agegrp3_a;

	format type $15. agegrp $10.; 

	type = 'age group 3';
	agegrp = agegrp3; 

	drop date agegrp3;

RUN; 

/*Combine all three age groups into one file*/;

DATA Combine_pop;
	set pop_sums_agegrp1_a1
		pop_sums_agegrp2_a1
		pop_sums_agegrp3_a1; 

RUN; 


/*LEFT JOIN, Cases and population data*/;

PROC SQL;
	create table Cases_Population

	as select distinct *

	from population_1 v

	left join combine_pop e on v.agegrp1 = e.month_test and v.agegrp = e.agegrp

	order by v.month_test

;
quit;

/*******************************************/