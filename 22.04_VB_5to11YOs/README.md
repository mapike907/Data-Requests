# Vaccine Breakthrough, Children 5-11 YO, Cases and Hospitalizations

Requested by CDPHE, April 18, 2022

Methods, Cases:
- Pulled the following variables from cedrs.cedrs_view: EventID,  age_at_reported, reinfection, earliest_collectiondate, hospitalized_cophs, cophs_admissiondate, vax_booster, vax_firstdose, vax_utd, breakthrough, breakthrough_booster.
- Filtered on earliest_collectiondate >= 2021-12-07.
- Created age_grp: 5-11, 12+.
- Created variable status for Tableau: 
    Unvaccinated: breakthrough = 0 and breakthrough_booster = 0
    VB: breakthrough = 1 and breakthrough_booster = 0
    VBB: breakthrough = 1 and breakthrough_booster = 1

Methods, Population:
- Midpoint between 12/7/21 and 4/18/22: 02/10/22
- Population data: used ciis.vaxunvax_addtnl_age to pull population data for 2/10/2022 by age. 
- Filtered by age groups: 5-11; 12+
- Summation of the following: 
    sum(total_fully_vaccinated) as Sum_total_fully_vax, sum(total_not_fully_vaccinated) as Sum_total_unvaxed
- Population data calculated in spreadsheet: https://docs.google.com/spreadsheets/d/1SnbOSvvJZXiA32r6ypEtUj2P7jYUy9wJxanLnlYQFiY/edit?usp=sharing


