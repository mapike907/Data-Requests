# Vaccine Breakthrough, Children 5-11 and 12-17 YO, Cases and Hospitalizations

Requested by CDPHE, April 18, 2022

Methods, Cases:
- Pulled the following variables from cedrs.cedrs_view: EventID,  age_at_reported, reinfection, earliest_collectiondate, hospitalized_cophs, cophs_admissiondate, vax_booster, vax_firstdose, vax_utd, breakthrough, breakthrough_booster.
- Filtered on earliest_collectiondate >= 2021-12-07.
- Created age_grp: 5-11, 12-17.
- Created variable status for Tableau: 
    Unvaccinated: breakthrough = 0 and breakthrough_booster = 0
    VB: breakthrough = 1 and breakthrough_booster = 0
    VBB: breakthrough = 1 and breakthrough_booster = 1

Methods, Population:
- Midpoint between 12/7/21 and 4/18/22: 02/10/22
- Population data: used ciis.vaxunvax_addtnl_age to pull population data for 2/10/2022 by age. 
- Filtered by age groups: 5-11; 12-17
- Summation of the following: 
    sum(total_fully_vaccinated) as Sum_total_fully_vax, sum(total_not_fully_vaccinated) as Sum_total_unvaxed
- Population data calculated in spreadsheet within github folder.


<img src="https://github.com/mapike907/Images/blob/main/COVID_511_Slide1.PNG" alt="VB_kids" width="700"/> 
Figure above: Data obtained from cedrs_view on 4/18/22. Analysis was performed on 4/18/22. CDC approved use of Pfizer vaccination on 11/2/21. Earliest_collectiondate was 12/07/21. Age group 5-11 years old is currently ineligible for a booster dose. 

/
/

<img src="https://github.com/mapike907/Images/blob/main/COVID_511_Slide3.PNG" alt="VB_kids3" width="700"/> 
Figure above: Data obtained from cedrs.cedrs_view on 4/18/22. Analysis was performed on 4/18/22. CDC approved use of Pfizer vaccination on 11/2/21. Earliest_collectiondate was 12/07/21. Age group 5-11 years old is currently ineligible for a booster dose. Hospitalization data lags by two weeks.


/
/

<img src="https://github.com/mapike907/Images/blob/main/COVID_511_Slide5.PNG" alt="VB_kids5" width="700"/> 
Figure above: Cases from 12/7/21 to 4/18/22. Analysis performed on 4/18/22.

/
/


<img src="https://github.com/mapike907/Images/blob/main/COVID_511_Slide6.PNG" alt="VB_kids6" width="700"/> 
Figure above: Hospitalization cases obtained from 12/7/21 to 4/18/22. Analysis performed on 4/18/22. Hospitalization data lags by two weeks.


