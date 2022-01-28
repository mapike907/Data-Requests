****************************************;
*Melissa Pike 8-18-2021*****************;
*CEDRS VB Checkbox Clean Up*************;
*                                       ;
****************************************;


libname newcedrs odbc dsn='CEDRS_3_Read' schema=CEDRS;
libname severson odbc dsn='COVID19' schema=cases;
run;


		/***VB Box checked in CEDRS***/
proc sql;
create table denominatorvbinCEDRS
as select distinct  e.EventID, e.Disease, e.EventStatus, e.countyassigned, e.ReportedDate, e.Age, e.AgeType, e.Outcome, s.vaccinebreakthrough

	

	from NewCEDRS.zDSI_Events e 
	left join NewCEDRS.SurveillanceFormCOVID19 s on e.eventID = s.eventID



	where e.Deleted ne 1 and e.EventID ne . 
    and e.disease ='COVID-19' and e.EventStatus in ('Confirmed','Probable') and s.vaccinebreakthrough=1 

	group by e.EventID
	order by e.reporteddate

;
	quit;



Data checked;
set severson.vaccine_breakthrough;
checked=1;
run;

Data unchecked;
set severson.vaccine_breakthrough_uncheck;
unchecked=1;
run;

proc sort data=denominatorvbinCEDRS;
by eventID;
run;

proc sort data=checked;
by eventID;
run;

proc sort data=unchecked;
by eventID;
run;


proc sql;
create table combined
as select distinct  c.*, cc.*, u.*
	

	from denominatorvbinCEDRS c 
	left join checked cc on c.eventID =  cc.eventID
	left join unchecked u on c.eventID = u.eventID

;
	quit;

data VBcheckUnCheck;
	set combined;

	if checked = . and unchecked = . then output; 
run;

/* Check Previous Runs with Current Run */; 



PROC SORT data=WORK.'VBCHECKUNCHECK_20 Sept Comb'n
	out=Comb_without_dupRecs
	NODUPRECS ;
   
		By eventid;
RUN; 

DATA new_list;
	set WORK.'VBCHECKUNCHECK_20 Sept Comb'n;

	if 'Name Change'n = '.' then output;
RUN; 



