
/*************************************************************/
/**   Check CEDRS for VB and VBB checkboxes				    **/
/**															**/
/**	  RE: VB checkboxes and VBB checkboxes in CEDRS			**/														   
/**		have been added. Need to check that they are 		**/
/**		locked and hand entry cannot enter checks.			**/
/**		Also need to confirm that it is working properly.	**/
/**															**/
/**	  Written by: M. Pike, Feb 23, 2022						**/
/*************************************************************/


libname cedrs odbc dsn='CEDRS_3_Read' schema=CEDRS;
libname covid odbc dsn='COVID19' schema=cases;



/***VB / VBB Box checked in CEDRS***/; 

proc sql;
create table denominatorvbinCEDRS
as select distinct  e.EventID, e.Disease, e.EventStatus, e.countyassigned, 
					e.ReportedDate, e.Age, e.AgeType, e.Outcome, s.vaccinebreakthrough, 
					s.vaccinebreakthroughbooster

	

	from CEDRS.zDSI_Events e 
	left join CEDRS.SurveillanceFormCOVID19 s on e.eventID = s.eventID



	where e.Deleted ne 1 and e.EventID ne . 
    and e.disease ='COVID-19' and e.EventStatus in ('Confirmed','Probable') 

	group by e.EventID
	order by e.reporteddate

;
	quit;

	
proc sort data=denominatorvbinCEDRS;
by eventID;
run;

/**********************************/;
/*** Create table for VB checks ***/;

/*Pull VB list from 144 */;
Data VB_checked;
set covid.vaccine_breakthrough;
checked=1;
run;

/*Pull VB list from CEDRS */;
Data VB_checked_events;
	set work.denominatorvbincedrs;

	if vaccinebreakthrough = 1 and vaccinebreakthroughbooster = . then output;
RUN;

/*create table that combines the two*/;

proc sql;
create table VB_combined
as select distinct  c.*, cc.*
	

	from VB_Checked_events c 
	left join VB_checked cc on c.eventID =  cc.eventID
	where vaccinebreakthrough=1

;
	quit;

/*output will have missing '.' for the checked variable*/;

Data VB_combo_misscheck;
	set VB_combined;

	if checked = . then output;  /*these are the VB=true but not checked in CEDRS */;
Run;
/* N = 2791*/;



/**********************************/;
/*** Create table for VBB checks ***/;


/*Pull VBB list from 144 */;
Data VBB_checked;
	set covid.vaccine_breakthrough_booster;
	checked=1;
run;

/*Pull VBB list from CEDRS */;
Data VBB_checked_events;
	set work.denominatorvbincedrs;

	if vaccinebreakthrough = 1 and vaccinebreakthroughbooster = 1 then output;
RUN;

/*create table that combines the two*/;

proc sql;
create table VBB_combined
as select distinct  c.*, cc.*
	

	from VBB_checked_events c 
	left join VB_checked cc on c.eventID =  cc.eventID
	where vaccinebreakthroughbooster=1

;
	quit;

/*output will have missing '.' for the checked variable*/;

Data VBB_combo_misscheck;
	set VBB_combined;

	if checked = . then output;  /*these are the VB=true but not checked in CEDRS */;
Run;
/* N = 101*/;


/*Combine VB and VBB into one data file */;

Data VB_VBB_Miss_ChkBx;
	set VB_combo_misscheck
		VBB_combo_misscheck; 
RUN;


/************* END OF CODE ************************/;


/*Pull VBB list from 144 */;
Data VBB_checked2;
	set covid.vaccine_breakthrough_booster;
	checked=1;
run;

/*Pull VBB list from CEDRS */;
Data VBB_checked_events2;
	set work.denominatorvbincedrs;

	if vaccinebreakthrough = . and vaccinebreakthroughbooster = 1 then output;
RUN;

/*create table that combines the two*/;

proc sql;
create table VBB_combined2
as select distinct  c.*, cc.*
	

	from VBB_checked_events2 c 
	left join VB_checked2 cc on c.eventID =  cc.eventID
	where vaccinebreakthroughbooster=1

;
	quit;

/*output will have missing '.' for the checked variable*/;

Data VBB_combo_misschec2k;
	set VBB_combined2;

	if checked = . then output;  /*these are the VB=true but not checked in CEDRS */;
Run;
/* N = 101*/;
