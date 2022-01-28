/* COVID-19 VB Case Counts in CO*************  Written by M.Pike 12 OCT 2021																	*/
/*																   																				*/
/* Purpose: Find COVID-19 VB Cases, Statewide (from 144) 																						*/
/*			Find COVID-19 VB Cases, Countywide (from 144) 		 																				*/
/*																   																				*/
/* IN:	Cedrs_view																																*/
/*																   																				*/
/* OUT: WORK.FILTER_FOR_CDOC_ALLCASES containing all VB Cases among staff, idp				   													*/
/*																   																				*/
/************************************************************************************************************************************************/;

libname severdbo odbc dsn='COVID19' schema=cases READ_LOCK_TYPE=NOLOCK;;
libname severson odbc dsn='COVID19' schema=dbo READ_LOCK_TYPE=NOLOCK;;
libname newcedrs odbc dsn='CEDRS_3_READ' schema=CEDRS READ_LOCK_TYPE=NOLOCK;
RUN;

DATA VB_Statewide; 
	set severson.cedrs_view;

	if breakthrough = 1 then output; 

RUN; 

PROC MEANS data=work.VB_STATEWIDE;   /*Total number of VB in State */
RUN; 


PROC FREQ data=work.vb_statewide; 
	tables countyassigned; 
	title 'VB Cases in CO Counties';
RUN; 

DATA VB_ELPASO; 
	set VB_statewide; 

	if countyassigned = 'EL PASO' then output; 

RUN; 

PROC FREQ data=vb_elpaso; 
	tables age_group; 
	title 'Age Group Among VB Cases in El Paso County'; 
RUN; 