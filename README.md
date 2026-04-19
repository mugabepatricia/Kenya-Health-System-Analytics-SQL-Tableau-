# Kenya Health System Analytics Project

## Overview
An end-to-end health data analysis project built on a synthetic but clinically realistic dataset modelled on the Kenyan public health system. 

The project demonstrates proficiency in relational database design, advanced SQL querying, and interactive data visualisation using Tableau.

## Dataset
- 4 relational tables: patients, visits, lab_results, prescriptions
- 1,200 patients | 1,800 clinical visits | 1,400 lab results | 1,200 prescriptions
- Data covers 28 facilities across 15 Kenyan counties (2022–2024)
- Diagnoses coded using ICD-10 classification
- Realistic clinical variables: vitals, BMI, length of stay, discharge outcomes

## Tools Used
- MySQL — database design, querying, and analysis
- Tableau Public — interactive dashboard visualisation
- Claude AI to create dataset

## SQL Concepts Demonstrated
- Complex JOINs across multiple tables
- Aggregations with GROUP BY and HAVING
- Common Table Expressions (CTEs)
- Window functions: RANK(), DENSE_RANK(), ROW_NUMBER(), LAG()
- Date functions: DATEDIFF(), DATE_FORMAT()
- CASE WHEN statements for clinical classification
- Subqueries and flag-then-aggregate pattern
- Rolling averages for time series analysis

## Key Analytical Questions Answered
- What is the 30-day readmission rate by disease category?
- Which disease categories have the highest patient mortality rates?
- How does average visit cost vary by insurance type and facility?
- Which counties carry the highest infectious disease burden?
- Are there patients with critical lab results who were discharged without admission?
- What is the monthly trend of malaria, TB, and HIV cases over 2 years?

## Key Insights
- Respiratory disease carries the highest patient mortality rate at 5.9%, followed by Perinatal conditions at 4.9% — highlighting neonatal and respiratory care as priority intervention areas

- Cardiovascular disease accounts for the highest number of deaths (7) despite a moderate mortality rate, reflecting its high visit volume across all counties

- No strong correlation was found between length of stay and total visit cost, suggesting that diagnosis type and facility level are stronger cost drivers than admission duration in this health system

- Kericho County Referral Hospital recorded the highest average visit cost at KES 621,380 while Karuri Sub-County Hospital recorded the lowest at KES 488,193 — a 27% cost gap between facility levels

- Malaria, TB and HIV cases show no consistent seasonal pattern over the 2-year period, with sporadic spikes suggesting outbreak episodes rather than seasonal transmission cycles

- Out-of-pocket patients represent 30% of all visits despite NHIF being the dominant insurer at 40%, indicating a significant proportion of the population remains financially vulnerable to healthcare costs

- Gastrointestinal disease recorded the highest visit volume at 274 visits, pointing to potential water, sanitation and hygiene challenges across the catchment counties

- A subset of patients with critical lab results were discharged without admission — a patient safety signal warranting clinical audit

## Dashboards
Two interactive Tableau dashboards:

### Clinical Outcomes Dashboard
- Malaria, TB & HIV disease trend (line chart)
- Mortality rate by disease category (bar chart with average reference line)
- Mortality summary table

### Operations & Finance Dashboard
- Average visit cost by facility (ranked bar chart)
- Disease burden by county (stacked bar chart)
- Length of stay vs visit cost (scatter plot)
- Disease activity heatmap by category and month

## View the Dashboard
- <a href="https://public.tableau.com/app/profile/patricia.mbabazi.mugabe/viz/KenyanClinicalOutcomesdashboard/ClinicalOutcomes">Clinical Outcomes Dashboard</a>
- <a href="https://public.tableau.com/app/profile/patricia.mbabazi.mugabe/viz/OperationsFinancedashboard/OperationsFinance">Operations & Finance Dashboard</a>

## Project Structure
- <a href="https://github.com/mugabepatricia/Kenya-Health-System-Analytics-SQL-Tableau-/blob/main/Kenya%20Health%20database.sql">Kenyan Health SQL code</a>

## About
Built as a portfolio project during a transition from clinical medicine (MBChB) into health data analytics. Domain knowledge from medical training informed the clinical relevance of the analytical questions and interpretation of results.

