*Creating a New Library;
libname project2 '/folders/myfolders/Project';

*Importing data from the provided csv file;
PROC IMPORT OUT = project2.Fermalogis_All
FILE = "/folders/myfolders/Project/FermaLogis_Event_Type.csv"
DBMS = CSV
REPLACE;
RUN;

*Converting the Yes/No to 1/0 respectively for turnover variable;
DATA project2.Fermalogis_All;
	SET project2.Fermalogis_All;

	IF Turnover="No" THEN
		ITurnover=0;
	ELSE
		ITurnover=1;
	*Fixing 14 rows where Type is 0 but Turnover is Yes, As type;

	IF Type=0 and Turnover="Yes" THEN
		ITurnover=0;
	*Categorise based on number of company worked;

	IF NumCompaniesWorked <=4 THEN
		NumCompaniesWorked1='Less than or equal to 4 Companies';

	IF NumCompaniesWorked >4 THEN
		NumCompaniesWorked1='Greater than 4 Companies';
	* Categorize based on years at company;

	IF YearsAtCompany <=3 Then
		Datasplit='Young_Emp';

	IF YearsAtCompany > 3 Then
		Datasplit='Exp_Emp';
	* Detailing the type as IType ;

	IF Type=0 then
		IType='No turnover';
	Else IF Type=1 then
		IType='Retirement';
	Else IF Type=2 then
		IType='Vol. Resig.';
	Else IF Type=3 then
		IType='Invol. Resig';
	Else
		IType='Job Termin.';
	
	*Recoding certain categorical columns;
	IF BusiessTravel="Travel_Rarely" THEN
		ReBusinessTravel=0;
	ELSE IF BusiessTravel="Non-Travel" THEN
		ReBusinessTravel=1;
	ELSE 
		ReBusinessTravel=2;
		
	
	IF MaritalStatus="Single" THEN
		ReMaritalStatus=0;
	ELSE IF MaritalStatus="Married" THEN
		ReMaritalStatus=1;
	ELSE 
		ReMaritalStatus=2;
	
	IF EducationField="Life Sciences" THEN
		ReEducationField=0;
	ELSE IF EducationField="Other" THEN
		ReEducationField=1;
	ELSE IF EducationField="Medical" THEN
		ReEducationField=2;
	ELSE IF EducationField="Marketing" THEN
		ReEducationField=3;
	ELSE IF EducationField="Technical Degree" THEN
		ReEducationField=4;
	ELSE 
		ReEducationField=5;
	
	IF JobRole="Sales Executive" THEN
		ReJobRole=0;
	ELSE IF JobRole="Research Scientist" THEN
		ReJobRole=1;
	ELSE IF JobRole="Laboratory Technician" THEN
		ReJobRole=2;
	ELSE IF JobRole="Manufacturing Director" THEN
		ReJobRole=3;
	ELSE IF JobRole="Healthcare Representative" THEN
		ReJobRole=4;
	ELSE IF JobRole="Manager" THEN
		ReJobRole=5;
	ELSE IF JobRole="Sales Representative" THEN
		ReJobRole=6;
	ELSE IF JobRole="Research Director" THEN
		ReJobRole=7;
	ELSE 
		ReJobRole=8;
	
	
	*BonusMean;
	NumBonusAwarded=SUM(bonus_1, bonus_2, bonus_3, bonus_4, bonus_5, bonus_6, 
		bonus_7, bonus_8, bonus_9, bonus_10, bonus_11, bonus_12, bonus_13, bonus_14, 
		bonus_15, bonus_16, bonus_17, bonus_18, bonus_19, bonus_20, bonus_21, 
		bonus_22, bonus_23, bonus_24, bonus_25, bonus_26, bonus_27, bonus_28, 
		bonus_29, bonus_30, bonus_31, bonus_32, bonus_33, bonus_34, bonus_35, 
		bonus_36, bonus_37, bonus_38, bonus_39, bonus_40);
	MeanBonus=NumBonusAwarded/(YearsAtCompany-1);
	* for average bonus;

	/* below code for the exponential weights */
	ARRAY bonus(*) bonus_1-bonus_40;
	alpha=0.8;
	tbonus=bonus_1;

	DO i=2 TO (yearsAtcompany-1);
		tbonus=tbonus + (bonus(i)*((1-alpha)**(i-1)));
	END;
	tbonus=tbonus * alpha;
RUN;

***********Exploratory Data Analysis on New Variable - Event type**********;

PROC FREQ DATA=project2.Fermalogis_All;
	TABLES IType*Turnover;
	TITLE 'Frequency table for Type and Turnover';
RUN;

/* years at company based on types of turnovers*/
ODS GRAPHICS ON;
PROC anova data=project2.Fermalogis_All;
where Turnover = 'Yes';
CLASS Type;
MODEL Yearsatcompany=Type;
MEANS Type/SCHEFFE;
TITLE 'years at company based on types of turnovers';
RUN;


/* Contribution of Marital Status to Attrition*/
PROC SGPLOT data=project2.Fermalogis_All;
	VBAR IType/ GROUP=MaritalStatus groupdisplay=cluster;
	TITLE 'Event Type by Marital Status for All Employees';
RUN;

/* Contribution of department to Attrition*/
PROC SGPLOT data=project2.Fermalogis_All;
	VBAR IType / GROUP=department groupdisplay=cluster;
	TITLE 'Event Type by department for All Employees';
RUN;

/* Contribution of Jobrole to Attrition*/
PROC SGPLOT data=project2.Fermalogis_All;
	VBAR IType/ GROUP=jobrole groupdisplay=cluster;
	TITLE 'Event Type by Job role for All Employees';
RUN;

/* Contribution of Age to Event Type*/
proc sql ;
	create table rec_tablevisual as select count(employeeNumber) as empCount, Age, 
		Type from project2.Fermalogis_All group by Age, Type;

PROC SGPLOT DATA=rec_tablevisual;
	SERIES X=Age Y=empCount / group=Type;
	XAXIS TYPE=DISCRETE;
	XAXIS LABEL='Age of Employee';
	YAXIS LABEL='Count of Employees' VALUES=(0 TO 30 BY 2);
	TITLE 'Event Type by Age for All Employees';
RUN;

*Bar plot for Event Type vs Monthly Salary;

PROC SGPLOT DATA=project2.Fermalogis_All;
	histogram MonthlyIncome/ showbins;
	density MonthlyIncome/type=kernel;
	Title 'MonthlyIncomeDistribution of employees with Kernel Distribution';
run;

PROC SGPLOT DATA=project2.Fermalogis_All;
	VBAR IType/ RESPONSE=MonthlyIncome STAT=MEAN;
	Title 'Bar plot for Event Type vs Monthly Income';
run;

PROC SGPLOT DATA=project2.Fermalogis_All;
	vbox MonthlyIncome/ Category=IType;
	Title 'Monthly income of employees with event type';
Run;

*Bar plot for Event Type vs Over Time;

PROC SGPLOT DATA=project2.Fermalogis_All;
	VBAR IType/ GROUP=OverTime;
	Title 'Bar plot for Event type vs Over Time ';
run;

*Association of event type and OverTime ;

PROC FREQ DATA=project2.Fermalogis_All;
	TABLES IType* OverTime / CHISQ;
	TITLE 'Association of event type and OverTime ';
RUN;

*Bar plot for Event Type vs Stock Option Level;

PROC SGPLOT DATA=project2.Fermalogis_All;
	VBAR IType/ GROUP=StockOptionLevel;
	Title 'Bar plot for event type vs Stock Option Level ';
run;

*Association of event type and StockOptionLevel;

PROC FREQ DATA=project2.Fermalogis_All;
	TABLES IType* StockOptionLevel / CHISQ;
	TITLE 'Association of event type and Stock Option Level ';
RUN;

*Bar plot for Event Type vs Business Travel;

PROC SGPLOT DATA=project2.Fermalogis_All;
	VBAR IType/ GROUP=BusinessTravel;
	Title 'Bar plot for Event type vs Business Travel ';
run;

*Association of event type and Business Travel;

PROC FREQ DATA=project2.Fermalogis_All;
	TABLES IType* BusinessTravel / CHISQ;
	TITLE 'Association of event type and Business Travel';
RUN;

*Association of Attrition and EnvironmentSatisfaction;

PROC FREQ DATA=project2.Fermalogis_All;
	TABLES IType* EnvironmentSatisfaction / CHISQ;
	TITLE 'Association of event type and Environment Satisfaction ';
RUN;

PROC FREQ DATA=project2.Fermalogis_All;
	TABLES IType * JobSatisfaction / CHISQ;
	TITLE 'Association of event type and JobSatisfaction ';
RUN;

***********End of Exploratory Data Analysis**********;


***********Finding if any variables that would affect hazard non-proportionally**********;

***********Martingale Residuals Method**********;
ODS GRAPHICS ON;
PROC PHREG DATA=Project2.fermalogis_all;
	CLASS BusinessTravel Department Education EducationField 
		EnvironmentSatisfaction Gender JobInvolvement JobLevel JobRole 
		JobSatisfaction MaritalStatus OverTime PerformanceRating 
		RelationshipSatisfaction StockOptionLevel WorkLifeBalance;
	MODEL YearsAtCompany*Type(0)=Age BusinessTravel DailyRate Department 
		DistanceFromHome Education EducationField EnvironmentSatisfaction Gender 
		HourlyRate JobInvolvement JobLevel JobRole JobSatisfaction MaritalStatus 
		MonthlyIncome MonthlyRate NumCompaniesWorked OverTime PercentSalaryHike 
		PerformanceRating RelationshipSatisfaction StockOptionLevel TotalWorkingYears 
		TrainingTimesLastYear WorkLifeBalance YearsInCurrentRole 
		YearsSinceLastPromotion YearsWithCurrManager / TIES=EFRON;
	ASSESS PH / RESAMPLE;
RUN;

***********End of Martingale Residuals Method**********;


***************Shoenfeld Residuals Method**************;
PROC PHREG DATA=Project2.fermalogis_all;
	CLASS BusinessTravel Department Education EducationField 
		EnvironmentSatisfaction Gender JobInvolvement JobLevel JobRole 
		JobSatisfaction MaritalStatus OverTime PerformanceRating 
		RelationshipSatisfaction StockOptionLevel WorkLifeBalance;
	MODEL YearsAtCompany*Type(0)=Age BusinessTravel DailyRate Department 
		DistanceFromHome Education EducationField EnvironmentSatisfaction Gender 
		HourlyRate JobInvolvement JobLevel JobRole JobSatisfaction MaritalStatus 
		MonthlyIncome MonthlyRate NumCompaniesWorked OverTime PercentSalaryHike 
		PerformanceRating RelationshipSatisfaction StockOptionLevel TotalWorkingYears 
		TrainingTimesLastYear WorkLifeBalance YearsInCurrentRole 
		YearsSinceLastPromotion YearsWithCurrManager 
		/TIES=EFRON;
	
	OUTPUT OUT=b RESSCH=schAge schBusinessTravel1 schBusinessTravel2 schDailyRate 
		schDepartment1 schDepartment2 schDistanceFromHome schEducation1 schEducation2 
		schEducation3 schEducation4 schEducationField1 schEducationField2 
		schEducationField3 schEducationField4 schEducationField5 
		schEnvironmentSatisfaction1 schEnvironmentSatisfaction2 
		schEnvironmentSatisfaction3 schGender schHourlyRate schJobInvolvement1 
		schJobInvolvement2 schJobInvolvement3 schJobLevel1 schJobLevel2 schJobLevel3 
		schJobLevel4 schJobRole1 schJobRole2 schJobRole3 schJobRole4 schJobRole5 
		schJobRole6 schJobRole7 schJobRole8 schJobSatisfaction1 schJobSatisfaction2 
		schJobSatisfaction3 schMaritalStatus1 schMaritalStatus2 schMonthlyIncome 
		schMonthlyRate schNumCompaniesWorked schOverTime schPercentSalaryHike 
		schPerformanceRating schRelationshipSatisfaction1 
		schRelationshipSatisfaction2 schRelationshipSatisfaction3 
		schStockOptionLevel1 schStockOptionLevel2 schStockOptionLevel3 
		schTotalWorkingYears schTrainingTimesLastYear schWorkLifeBalance1 
		schWorkLifeBalance2 schWorkLifeBalance3 schYearsInCurrentRole 
		schYearsSinceLastPromotion schYearsWithCurrManager ;
RUN;

/*plot the residuals and see how it's calculated*/
DATA b;
	SET b;
	id=_n_;
RUN;

proc sgplot data=b;
	scatter x=YearsAtCompany y=schAge / datalabel=X;
run;

proc sgplot data=b;
	scatter x=YearsAtCompany y=schTotalWorkingYears / datalabel=X;
run;

/*find the correlations with week and functions of week*/
DATA c;
	SET b;
	YearsAtCompany2=YearsAtCompany**2;
RUN;

PROC CORR data=c;
	VAR YearsAtCompany YearsAtCompany2;
	WITH schAge schBusinessTravel1 schBusinessTravel2 schDailyRate schDepartment1 
		schDepartment2 schDistanceFromHome schEducation1 schEducation2 schEducation3 
		schEducation4 schEducationField1 schEducationField2 schEducationField3 
		schEducationField4 schEducationField5 schEnvironmentSatisfaction1 
		schEnvironmentSatisfaction2 schEnvironmentSatisfaction3 schGender 
		schHourlyRate schJobInvolvement1 schJobInvolvement2 schJobInvolvement3 
		schJobLevel1 schJobLevel2 schJobLevel3 schJobLevel4 schJobRole1 schJobRole2 
		schJobRole3 schJobRole4 schJobRole5 schJobRole6 schJobRole7 schJobRole8 
		schJobSatisfaction1 schJobSatisfaction2 schJobSatisfaction3 schMaritalStatus1 
		schMaritalStatus2 schMonthlyIncome schMonthlyRate schNumCompaniesWorked 
		schOverTime schPercentSalaryHike schPerformanceRating 
		schRelationshipSatisfaction1 schRelationshipSatisfaction2 
		schRelationshipSatisfaction3 schStockOptionLevel1 schStockOptionLevel2 
		schStockOptionLevel3 schTotalWorkingYears schTrainingTimesLastYear 
		schWorkLifeBalance1 schWorkLifeBalance2 schWorkLifeBalance3 
		schYearsInCurrentRole schYearsSinceLastPromotion schYearsWithCurrManager;
RUN;

***********End of Shoenfeld Residuals Method**********;


*****************************************************************************************;

**********Competent Risk************;
*************Find whether the hazard rates are same for all events?************;

/*Graphically test for linear relation between type hazards*/
DATA Retire;
	/*create Retirement turnover data*/
	SET project2.Fermalogis_All;
	event=(Type=1);  	/*this is for censoring out other types, another way to write if statement*/
	Etype='Retire';

DATA VolRes;
	/*create voluntary resignation data*/
	SET project2.Fermalogis_All;
	event=(Type=2);
	Etype='VolRes';

DATA InvolRes;
	/*create involuntary resignation data*/
	SET project2.Fermalogis_All;
	event=(Type=3);
	Etype='InVolR';

DATA Fired;
	/*create fired data*/
	SET project2.Fermalogis_All;
	event=(Type=4);
	Etype='EFired';

DATA combine;
	/*we combined the datasets to use them as strata in the graphical analysis*/
	SET Retire VolRes InvolRes Fired;

PROC LIFETEST DATA=COMBINE PLOTS=LLS;
	/*LLS plot is requested*/
	TIME yearsatcompany*event(0);
	STRATA Etype /diff=all;
RUN;

**************Statistical test to check if any events can be merged*************;

*********Nested Model*********;
PROC PHREG DATA=Project2.fermalogis_all;
	CLASS BusinessTravel Department Education EducationField 
		EnvironmentSatisfaction Gender JobInvolvement JobLevel JobRole 
		JobSatisfaction MaritalStatus OverTime PerformanceRating 
		RelationshipSatisfaction StockOptionLevel WorkLifeBalance;
	MODEL YearsAtCompany*Type(0)=Age BusinessTravel DailyRate Department 
		DistanceFromHome Education EducationField EnvironmentSatisfaction Gender 
		HourlyRate JobInvolvement JobLevel JobRole JobSatisfaction MaritalStatus 
		MonthlyIncome MonthlyRate NumCompaniesWorked OverTime PercentSalaryHike 
		PerformanceRating RelationshipSatisfaction StockOptionLevel TotalWorkingYears 
		TrainingTimesLastYear WorkLifeBalance YearsInCurrentRole 
		YearsSinceLastPromotion YearsWithCurrManager MeanBonus
		IBusinessTravel IDailyrate IDistancefromHome IEducationField 
		IJoblevel IJobSatisfaction IMaritalStatus IMonthlyIncome 
		ITotalWorkingYears IYearsInCurrentRole IYearsWithCurrManager IJobRole
		/TIES=EFRON selection=backward;
	
	IBusinessTravel=YearsAtCompany*ReBusinessTravel;
	IDailyrate=YearsAtCompany*Dailyrate;
	IDistancefromHome=YearsAtCompany*DistancefromHome;
	IEducationField=YearsAtCompany*ReEducationField;
	IJoblevel=YearsAtCompany*Joblevel;
	IJobSatisfaction=YearsAtCompany*JobSatisfaction;
	IMaritalStatus=YearsAtCompany*ReMaritalStatus;
	IMonthlyIncome=YearsAtCompany*MonthlyIncome;
	ITotalWorkingYears=YearsAtCompany*TotalWorkingYears;
	IYearsInCurrentRole=YearsAtCompany*YearsInCurrentRole;
	IYearsWithCurrManager=YearsAtCompany*YearsWithCurrManager;
	IJobRole=YearsAtCompany*ReJobRole;	
	*STRATA Datasplit;
RUN;

*censoring except 1;

PROC PHREG DATA=Project2.fermalogis_all;
	CLASS BusinessTravel Department Education EducationField 
		EnvironmentSatisfaction Gender JobInvolvement JobLevel JobRole 
		JobSatisfaction MaritalStatus OverTime PerformanceRating 
		RelationshipSatisfaction StockOptionLevel WorkLifeBalance;
	MODEL YearsAtCompany*Type(0,2,3,4)=Age BusinessTravel DailyRate Department 
		DistanceFromHome Education EducationField EnvironmentSatisfaction Gender 
		HourlyRate JobInvolvement JobLevel JobRole JobSatisfaction MaritalStatus 
		MonthlyIncome MonthlyRate NumCompaniesWorked OverTime PercentSalaryHike 
		PerformanceRating RelationshipSatisfaction StockOptionLevel TotalWorkingYears 
		TrainingTimesLastYear WorkLifeBalance YearsInCurrentRole 
		YearsSinceLastPromotion YearsWithCurrManager MeanBonus
		IBusinessTravel IDailyrate IDistancefromHome IEducationField 
		IJoblevel IJobSatisfaction IMaritalStatus IMonthlyIncome 
		ITotalWorkingYears IYearsInCurrentRole IYearsWithCurrManager IJobRole
		/TIES=EFRON selection=backward maxiter=1000;
	
	IBusinessTravel=YearsAtCompany*ReBusinessTravel;
	IDailyrate=YearsAtCompany*Dailyrate;
	IDistancefromHome=YearsAtCompany*DistancefromHome;
	IEducationField=YearsAtCompany*ReEducationField;
	IJoblevel=YearsAtCompany*Joblevel;
	IJobSatisfaction=YearsAtCompany*JobSatisfaction;
	IMaritalStatus=YearsAtCompany*ReMaritalStatus;
	IMonthlyIncome=YearsAtCompany*MonthlyIncome;
	ITotalWorkingYears=YearsAtCompany*TotalWorkingYears;
	IYearsInCurrentRole=YearsAtCompany*YearsInCurrentRole;
	IYearsWithCurrManager=YearsAtCompany*YearsWithCurrManager;
	IJobRole=YearsAtCompany*ReJobRole;	
	*STRATA Datasplit;
RUN;


*censoring except 2;

PROC PHREG DATA=Project2.fermalogis_all;
	CLASS BusinessTravel Department Education EducationField 
		EnvironmentSatisfaction Gender JobInvolvement JobLevel JobRole 
		JobSatisfaction MaritalStatus OverTime PerformanceRating 
		RelationshipSatisfaction StockOptionLevel WorkLifeBalance;
	MODEL YearsAtCompany*Type(0,1,3,4)=Age BusinessTravel DailyRate Department 
		DistanceFromHome Education EducationField EnvironmentSatisfaction Gender 
		HourlyRate JobInvolvement JobLevel JobRole JobSatisfaction MaritalStatus 
		MonthlyIncome MonthlyRate NumCompaniesWorked OverTime PercentSalaryHike 
		PerformanceRating RelationshipSatisfaction StockOptionLevel TotalWorkingYears 
		TrainingTimesLastYear WorkLifeBalance YearsInCurrentRole 
		YearsSinceLastPromotion YearsWithCurrManager MeanBonus
		IBusinessTravel IDailyrate IDistancefromHome IEducationField 
		IJoblevel IJobSatisfaction IMaritalStatus IMonthlyIncome 
		ITotalWorkingYears IYearsInCurrentRole IYearsWithCurrManager IJobRole
		/TIES=EFRON selection=backward maxiter=1000;
	
	IBusinessTravel=YearsAtCompany*ReBusinessTravel;
	IDailyrate=YearsAtCompany*Dailyrate;
	IDistancefromHome=YearsAtCompany*DistancefromHome;
	IEducationField=YearsAtCompany*ReEducationField;
	IJoblevel=YearsAtCompany*Joblevel;
	IJobSatisfaction=YearsAtCompany*JobSatisfaction;
	IMaritalStatus=YearsAtCompany*ReMaritalStatus;
	IMonthlyIncome=YearsAtCompany*MonthlyIncome;
	ITotalWorkingYears=YearsAtCompany*TotalWorkingYears;
	IYearsInCurrentRole=YearsAtCompany*YearsInCurrentRole;
	IYearsWithCurrManager=YearsAtCompany*YearsWithCurrManager;
	IJobRole=YearsAtCompany*ReJobRole;	
	*STRATA Datasplit;
RUN;

*censoring except 3;

PROC PHREG DATA=Project2.fermalogis_all;
	CLASS BusinessTravel Department Education EducationField 
		EnvironmentSatisfaction Gender JobInvolvement JobLevel JobRole 
		JobSatisfaction MaritalStatus OverTime PerformanceRating 
		RelationshipSatisfaction StockOptionLevel WorkLifeBalance;
	MODEL YearsAtCompany*Type(0,1,2,4)=Age BusinessTravel DailyRate Department 
		DistanceFromHome Education EducationField EnvironmentSatisfaction Gender 
		HourlyRate JobInvolvement JobLevel JobRole JobSatisfaction MaritalStatus 
		MonthlyIncome MonthlyRate NumCompaniesWorked OverTime PercentSalaryHike 
		PerformanceRating RelationshipSatisfaction StockOptionLevel TotalWorkingYears 
		TrainingTimesLastYear WorkLifeBalance YearsInCurrentRole 
		YearsSinceLastPromotion YearsWithCurrManager MeanBonus
		IBusinessTravel IDailyrate IDistancefromHome IEducationField 
		IJoblevel IJobSatisfaction IMaritalStatus IMonthlyIncome 
		ITotalWorkingYears IYearsInCurrentRole IYearsWithCurrManager IJobRole
		/TIES=EFRON selection=backward maxiter=1000;
	
	IBusinessTravel=YearsAtCompany*ReBusinessTravel;
	IDailyrate=YearsAtCompany*Dailyrate;
	IDistancefromHome=YearsAtCompany*DistancefromHome;
	IEducationField=YearsAtCompany*ReEducationField;
	IJoblevel=YearsAtCompany*Joblevel;
	IJobSatisfaction=YearsAtCompany*JobSatisfaction;
	IMaritalStatus=YearsAtCompany*ReMaritalStatus;
	IMonthlyIncome=YearsAtCompany*MonthlyIncome;
	ITotalWorkingYears=YearsAtCompany*TotalWorkingYears;
	IYearsInCurrentRole=YearsAtCompany*YearsInCurrentRole;
	IYearsWithCurrManager=YearsAtCompany*YearsWithCurrManager;
	IJobRole=YearsAtCompany*ReJobRole;	
	*STRATA Datasplit;
RUN;


*censoring except 4;

PROC PHREG DATA=Project2.fermalogis_all;
	CLASS BusinessTravel Department Education EducationField 
		EnvironmentSatisfaction Gender JobInvolvement JobLevel JobRole 
		JobSatisfaction MaritalStatus OverTime PerformanceRating 
		RelationshipSatisfaction StockOptionLevel WorkLifeBalance bonus_1;
	MODEL YearsAtCompany*Type(0,1,2,3)=Age BusinessTravel DailyRate Department 
		DistanceFromHome Education EducationField EnvironmentSatisfaction Gender 
		HourlyRate JobInvolvement JobLevel JobRole JobSatisfaction MaritalStatus 
		MonthlyIncome MonthlyRate NumCompaniesWorked OverTime PercentSalaryHike 
		PerformanceRating RelationshipSatisfaction StockOptionLevel TotalWorkingYears 
		TrainingTimesLastYear WorkLifeBalance YearsInCurrentRole 
		YearsSinceLastPromotion YearsWithCurrManager bonus_1
		IBusinessTravel IDailyrate IDistancefromHome IEducationField 
		IJoblevel IJobSatisfaction IMaritalStatus IMonthlyIncome 
		ITotalWorkingYears IYearsInCurrentRole IYearsWithCurrManager IJobRole
		/TIES=EFRON selection=backward maxiter=1000;
	
	IBusinessTravel=YearsAtCompany*ReBusinessTravel;
	IDailyrate=YearsAtCompany*Dailyrate;
	IDistancefromHome=YearsAtCompany*DistancefromHome;
	IEducationField=YearsAtCompany*ReEducationField;
	IJoblevel=YearsAtCompany*Joblevel;
	IJobSatisfaction=YearsAtCompany*JobSatisfaction;
	IMaritalStatus=YearsAtCompany*ReMaritalStatus;
	IMonthlyIncome=YearsAtCompany*MonthlyIncome;
	ITotalWorkingYears=YearsAtCompany*TotalWorkingYears;
	IYearsInCurrentRole=YearsAtCompany*YearsInCurrentRole;
	IYearsWithCurrManager=YearsAtCompany*YearsWithCurrManager;
	IJobRole=YearsAtCompany*ReJobRole;	
	*STRATA Datasplit;
RUN;

*Log Ratio Test;
DATA LogRatioTest_DoWeNeedFourModels;
	Nested=1345.030;
	Retirement=129.933;
	Vol_Res=498.758;
	InVol_Res=294.975;
	Fired=213.825;
	Total=Retirement + Vol_Res+ InVol_Res+Fired;
	Diff=Nested - Total;
	P_value=1 - probchi(Diff, 100);
	*30 coef. in 3 models - 10 coef. in nested;
RUN;

PROC PRINT DATA=LogRatioTest_DoWeNeedFourModels;
	FORMAT P_Value 5.3;
RUN;

******Test to check if we can combine volRes & Non vol Res;
PROC PHREG DATA=Project2.fermalogis_all;
	CLASS BusinessTravel Department Education EducationField 
		EnvironmentSatisfaction Gender JobInvolvement JobLevel JobRole 
		JobSatisfaction MaritalStatus OverTime PerformanceRating 
		RelationshipSatisfaction StockOptionLevel WorkLifeBalance;
	MODEL YearsAtCompany*Type(0,1,4)=Age BusinessTravel DailyRate Department 
		DistanceFromHome Education EducationField EnvironmentSatisfaction Gender 
		HourlyRate JobInvolvement JobLevel JobRole JobSatisfaction MaritalStatus 
		MonthlyIncome MonthlyRate NumCompaniesWorked OverTime PercentSalaryHike 
		PerformanceRating RelationshipSatisfaction StockOptionLevel TotalWorkingYears 
		TrainingTimesLastYear WorkLifeBalance YearsInCurrentRole 
		YearsSinceLastPromotion YearsWithCurrManager MeanBonus
		IBusinessTravel IDailyrate IDistancefromHome IEducationField 
		IJoblevel IJobSatisfaction IMaritalStatus IMonthlyIncome 
		ITotalWorkingYears IYearsInCurrentRole IYearsWithCurrManager IJobRole
		/TIES=EFRON selection=backward;
	
	IBusinessTravel=YearsAtCompany*ReBusinessTravel;
	IDailyrate=YearsAtCompany*Dailyrate;
	IDistancefromHome=YearsAtCompany*DistancefromHome;
	IEducationField=YearsAtCompany*ReEducationField;
	IJoblevel=YearsAtCompany*Joblevel;
	IJobSatisfaction=YearsAtCompany*JobSatisfaction;
	IMaritalStatus=YearsAtCompany*ReMaritalStatus;
	IMonthlyIncome=YearsAtCompany*MonthlyIncome;
	ITotalWorkingYears=YearsAtCompany*TotalWorkingYears;
	IYearsInCurrentRole=YearsAtCompany*YearsInCurrentRole;
	IYearsWithCurrManager=YearsAtCompany*YearsWithCurrManager;
	IJobRole=YearsAtCompany*ReJobRole;	
	*STRATA Datasplit;
RUN;

DATA LogRatioTest_DoWeNeedFourModels;
	Nested=866;
	Retirement=129.933;
	Vol_Res=498.758;
	InVol_Res=294.975;
	Fired=213.825;
	Total= Vol_Res+ InVol_Res;
	Diff=Nested - Total;
	P_value=1 - probchi(Diff, 15);
	*30 coef. in 3 models - 10 coef. in nested;
RUN;