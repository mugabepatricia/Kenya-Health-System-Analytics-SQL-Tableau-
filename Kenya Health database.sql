-- Beginner — Aggregations & Filtering
-- How many patients are registered per county?
SELECT 
    county, COUNT(*) AS total_patients
FROM
    patients
GROUP BY county
ORDER BY total_patients DESC;

-- What is the most common diagnosis across all visits?
SELECT 
    diagnosis, COUNT(*) AS diagnosis_count
FROM
    visits
GROUP BY diagnosis
ORDER BY diagnosis_count DESC
LIMIT 1;

-- How many visits were Inpatient vs Outpatient vs Emergency?
SELECT 
    visit_type, COUNT(*) AS total_visits
FROM
    visits
GROUP BY visit_type
ORDER BY total_visits DESC;

-- What percentage of patients are on NHIF vs out-of-pocket?
SELECT 
    insurance_type,
    COUNT(*) AS patient_count,
    ROUND(COUNT(*) * 100.0 / (SELECT 
                    COUNT(*)
                FROM
                    patients),
            1) AS percentage
FROM
    patients
GROUP BY insurance_type
ORDER BY percentage DESC;

-- How many patients were admitted, discharged, or referred?
SELECT 
    discharge_status, COUNT(*) AS patient_count
FROM
    visits
GROUP BY discharge_status;

-- What is the average BMI across all patients?
SELECT 
    ROUND(AVG(bmi), 0) AS average_bmi
FROM
    visits;

-- Which facility recorded the most visits?
SELECT 
    facility_name, COUNT(*) AS total_visits
FROM
    visits
GROUP BY facility_name
ORDER BY total_visits DESC;

-- Intermediate — JOINs, GROUP BY, CASE
-- What is the average cost of a visit by insurance type?
SELECT 
    p.insurance_type,
    ROUND(AVG(v.total_cost_kes), 2) AS average_cost
FROM
    patients p
        JOIN
    visits v ON p.patient_id = v.patient_id
GROUP BY p.insurance_type
ORDER BY average_cost DESC;

-- Which disease category has the longest average length of stay?
SELECT 
    disease_category,
    ROUND(AVG(length_of_stay), 0) AS avg_length_of_stay
FROM
    visits
WHERE
    length_of_stay > 0
GROUP BY disease_category
ORDER BY avg_length_of_stay DESC;

-- How many patients had abnormal or critical lab results? (i dont think this is correct!!!)
SELECT 
    COUNT(DISTINCT l.visit_id) AS visits_with_abnormal_labs,
    COUNT(DISTINCT v.patient_id) AS patients_with_abnormal_labs
FROM lab_results l
JOIN visits v ON l.visit_id = v.visit_id
WHERE l.result_category IN ('Abnormal', 'Critical');

-- What is the most prescribed drug class per disease category?
SELECT 
    disease_category,
    drug_class,
    COUNT(*) AS prescription_count
FROM prescriptions pr
JOIN visits v ON pr.visit_id = v.visit_id
GROUP BY disease_category, drug_class
ORDER BY disease_category, prescription_count DESC;

-- option 2 --
WITH ranked AS (
    SELECT 
        v.disease_category,
        pr.drug_class,
        COUNT(*) AS prescription_count,
        RANK() OVER (PARTITION BY v.disease_category ORDER BY COUNT(*) DESC) AS rnk
    FROM prescriptions pr
    JOIN visits v ON pr.visit_id = v.visit_id
    GROUP BY v.disease_category, pr.drug_class
)
SELECT disease_category, drug_class, prescription_count
FROM ranked
WHERE rnk = 1;

-- Which county has the highest average systolic blood pressure?
SELECT 
    p.county,
    ROUND(AVG(v.bp_systolic), 0) AS average_systolic_bp
FROM
    patients p
        JOIN
    visits v ON v.patient_id = p.patient_id
GROUP BY p.county
ORDER BY average_systolic_bp DESC;

-- How many patients visited more than once? Who are the frequent attenders?
SELECT 
    p.patient_id,
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    COUNT(v.visit_id) AS total_visits
FROM patients p
JOIN visits v ON p.patient_id = v.patient_id
GROUP BY p.patient_id, p.first_name, p.last_name
HAVING COUNT(v.visit_id) > 1
ORDER BY total_visits DESC;

-- What proportion of diabetic patients had an HbA1c test ordered?
WITH diabetics AS (
    SELECT DISTINCT patient_id
    FROM visits
    WHERE icd10_code IN ('E11', 'E14')
),
hba1c_tested AS (
    SELECT DISTINCT v.patient_id
    FROM lab_results l
    JOIN visits v ON l.visit_id = v.visit_id
    WHERE l.test_code = 'HbA1c'
)
SELECT 
    COUNT(DISTINCT d.patient_id) AS total_diabetics,
    COUNT(DISTINCT h.patient_id) AS hba1c_tested,
    ROUND(COUNT(DISTINCT h.patient_id) * 100.0 / COUNT(DISTINCT d.patient_id), 1) AS percentage_tested
FROM diabetics d
LEFT JOIN hba1c_tested h ON d.patient_id = h.patient_id;

-- What is the average BMI broken down by sex and age group (child/adult/elderly)?
SELECT 
    p.sex,
    CASE 
        WHEN p.age_years < 18 THEN 'Child'
        WHEN p.age_years BETWEEN 18 AND 59 THEN 'Adult'
        ELSE 'Elderly'
    END AS age_group,
    ROUND(AVG(v.bmi), 1) AS avg_bmi,
    COUNT(DISTINCT p.patient_id) AS patient_count
FROM patients p
JOIN visits v ON p.patient_id = v.patient_id
GROUP BY p.sex, age_group
ORDER BY p.sex, age_group;

-- Advanced — Window Functions, CTEs, Subqueries
-- Rank the top 10 most expensive visits and identify what diagnoses drove them.
with ranked_visits as (
	select
		visit_id,
		diagnosis,
		total_cost_kes,
		rank() over (order by total_cost_kes desc) as cost_rank
	from visits
)
select *
from ranked_visits
where cost_rank <= 10;

-- 17. For each patient with multiple visits, what was the time gap between visits? (readmission analysis)
WITH visit_gaps AS (
    SELECT
        patient_id,
        visit_id,
        visit_date,
        LAG(visit_date) OVER (
            PARTITION BY patient_id 
            ORDER BY visit_date
        ) AS previous_visit_date
    FROM visits
)
SELECT
    patient_id,
    visit_id,
    visit_date,
    previous_visit_date,
    DATEDIFF(visit_date, previous_visit_date) AS days_between_visits
FROM visit_gaps
WHERE previous_visit_date IS NOT NULL
ORDER BY patient_id, visit_date;

-- 18. Using a rolling window, what is the monthly trend in visit volume over the 2 years?
WITH monthly_visits AS (
    SELECT 
        DATE_FORMAT(visit_date, '%Y-%m') AS visit_month,
        COUNT(visit_id) AS total_visits
    FROM visits
    GROUP BY visit_month
),
rolling AS (
    SELECT
        visit_month,
        total_visits,
        ROUND(AVG(total_visits) OVER (
            ORDER BY visit_month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ), 1) AS rolling_3month_avg
    FROM monthly_visits
)
SELECT *
FROM rolling
ORDER BY visit_month;

-- 19. Which patients had a critical lab result but were still discharged (not admitted)?
SELECT DISTINCT
    v.visit_id,
    v.patient_id,
    v.diagnosis,
    v.discharge_status,
    l.test_name,
    l.result_category
FROM visits v
JOIN lab_results l ON v.visit_id = l.visit_id
WHERE l.result_category = 'Critical'
AND v.discharge_status = 'Discharged'
ORDER BY v.patient_id;

-- 20. What is the 30-day readmission rate by disease category?
WITH visit_gaps AS (
    SELECT
        v.patient_id,
        v.visit_id,
        v.disease_category,
        v.visit_date,
        v.discharge_status,
        LAG(v.visit_date) OVER (
            PARTITION BY v.patient_id 
            ORDER BY v.visit_date
        ) AS previous_visit_date
    FROM visits v
),
readmissions AS (
    SELECT
        patient_id,
        visit_id,
        disease_category,
        visit_date,
        previous_visit_date,
        DATEDIFF(visit_date, previous_visit_date) AS days_since_last_visit,
        CASE 
            WHEN DATEDIFF(visit_date, previous_visit_date) <= 30 THEN 1
            ELSE 0
        END AS is_readmission
    FROM visit_gaps
    WHERE previous_visit_date IS NOT NULL
)
SELECT
    disease_category,
    COUNT(visit_id) AS total_visits,
    SUM(is_readmission) AS readmissions,
    ROUND(SUM(is_readmission) * 100.0 / COUNT(visit_id), 1) AS readmission_rate_pct
FROM readmissions
GROUP BY disease_category
ORDER BY readmission_rate_pct DESC;

-- 21. Identify patients whose BMI changed significantly between visits.
WITH bmi_changes AS (
    SELECT
        patient_id,
        visit_id,
        visit_date,
        bmi,
        LAG(bmi) OVER (
            PARTITION BY patient_id 
            ORDER BY visit_date
        ) AS previous_bmi
    FROM visits
    WHERE bmi IS NOT NULL
),
significant_changes AS (
    SELECT
        patient_id,
        visit_id,
        visit_date,
        previous_bmi,
        bmi AS current_bmi,
        ROUND(bmi - previous_bmi, 1) AS bmi_change
    FROM bmi_changes
    WHERE previous_bmi IS NOT NULL
    AND ABS(bmi - previous_bmi) >= 2
)
SELECT
    sc.patient_id,
    p.first_name,
    p.last_name,
    sc.visit_date,
    sc.previous_bmi,
    sc.current_bmi,
    sc.bmi_change
FROM significant_changes sc
JOIN patients p ON sc.patient_id = p.patient_id
ORDER BY ABS(sc.bmi_change) DESC;

-- 22. For each facility, rank the diagnoses by frequency using DENSE_RANK().
WITH diagnosis_counts AS (
    SELECT
        facility_name,
        diagnosis,
        COUNT(*) AS diagnosis_count
    FROM visits
    GROUP BY facility_name, diagnosis
),
ranked_diagnoses AS (
    SELECT
        facility_name,
        diagnosis,
        diagnosis_count,
        DENSE_RANK() OVER (
            PARTITION BY facility_name 
            ORDER BY diagnosis_count DESC
        ) AS diagnosis_rank
    FROM diagnosis_counts
)
SELECT *
FROM ranked_diagnoses
WHERE diagnosis_rank <= 3
ORDER BY facility_name, diagnosis_rank;

-- 23. What percentage of prescriptions were only partially dispensed, and which drug classes are most affected?
WITH dispensing_summary AS (
    SELECT
        drug_class,
        COUNT(*) AS total_prescriptions,
        SUM(CASE WHEN dispensing_status = 'Partial' THEN 1 ELSE 0 END) AS partial_count
    FROM prescriptions
    GROUP BY drug_class
)
SELECT
    drug_class,
    total_prescriptions,
    partial_count,
    ROUND(partial_count * 100.0 / total_prescriptions, 1) AS partial_dispensing_pct
FROM dispensing_summary
ORDER BY partial_dispensing_pct DESC;

-- Tableau-Ready (Analytical framing)
-- 24. What is the disease burden by county? (map visualisation)
SELECT 
    p.county,
    v.disease_category,
    v.diagnosis,
    COUNT(v.visit_id) AS total_visits
FROM visits v
JOIN patients p ON v.patient_id = p.patient_id
GROUP BY p.county, v.disease_category, v.diagnosis
ORDER BY p.county, total_visits DESC;

-- 25. How does average visit cost vary by facility type and county?
SELECT 
    p.county,
    v.facility_type,
    v.facility_name,
    ROUND(AVG(v.total_cost_kes), 2) AS avg_visit_cost,
    COUNT(v.visit_id) AS total_visits
FROM visits v
JOIN patients p ON v.patient_id = p.patient_id
GROUP BY p.county, v.facility_type, v.facility_name
ORDER BY avg_visit_cost DESC;

-- 26. What is the trend of malaria, TB, and HIV diagnoses over time?
SELECT 
    DATE_FORMAT(v.visit_date, '%Y-%m') AS visit_month,
    v.diagnosis,
    v.icd10_code,
    COUNT(v.visit_id) AS total_cases
FROM visits v
WHERE v.icd10_code IN ('B50', 'A15', 'B24')
GROUP BY visit_month, v.diagnosis, v.icd10_code
ORDER BY visit_month;

SELECT 
    DATE_FORMAT(v.visit_date, '%Y-%m') AS visit_month,
    SUM(CASE WHEN v.icd10_code = 'B50' THEN 1 ELSE 0 END) AS malaria_cases,
    SUM(CASE WHEN v.icd10_code = 'A15' THEN 1 ELSE 0 END) AS tb_cases,
    SUM(CASE WHEN v.icd10_code = 'B24' THEN 1 ELSE 0 END) AS hiv_cases
FROM visits v
GROUP BY visit_month
ORDER BY visit_month;

SELECT 
    DATE_FORMAT(v.visit_date, '%Y-%m') AS visit_month,
    'Malaria' AS disease,
    SUM(CASE WHEN v.icd10_code = 'B50' THEN 1 ELSE 0 END) AS cases
FROM visits v
GROUP BY visit_month

UNION ALL

SELECT 
    DATE_FORMAT(v.visit_date, '%Y-%m') AS visit_month,
    'Tuberculosis' AS disease,
    SUM(CASE WHEN v.icd10_code = 'A15' THEN 1 ELSE 0 END) AS cases
FROM visits v
GROUP BY visit_month

UNION ALL

SELECT 
    DATE_FORMAT(v.visit_date, '%Y-%m') AS visit_month,
    'HIV' AS disease,
    SUM(CASE WHEN v.icd10_code = 'B24' THEN 1 ELSE 0 END) AS cases
FROM visits v
GROUP BY visit_month

ORDER BY visit_month, disease;



-- 27. What is the patient mortality rate (discharge status = ‘Died’) by disease category?
SELECT 
    disease_category,
    COUNT(visit_id) AS total_visits,
    SUM(CASE WHEN discharge_status = 'Died' THEN 1 ELSE 0 END) AS total_deaths,
    ROUND(SUM(CASE WHEN discharge_status = 'Died' THEN 1 ELSE 0 END) * 100.0 / COUNT(visit_id), 2) AS mortality_rate_pct
FROM visits
GROUP BY disease_category
ORDER BY mortality_rate_pct DESC;

-- 28. How does length of stay correlate with total visit cost?
SELECT 
    v.visit_id,
    v.disease_category,
    v.facility_type,
    v.length_of_stay,
    v.total_cost_kes,
    v.discharge_status,
    p.insurance_type,
    p.county
FROM visits v
JOIN patients p ON v.patient_id = p.patient_id
WHERE v.length_of_stay > 0
ORDER BY v.length_of_stay DESC;

SELECT 
    DATE_FORMAT(v.visit_date, '%Y-%m') AS visit_month,
    v.disease_category,
    COUNT(v.visit_id) AS total_visits,
    ROUND(AVG(v.total_cost_kes), 2) AS avg_cost,
    SUM(CASE WHEN v.discharge_status = 'Died' THEN 1 ELSE 0 END) AS total_deaths,
    ROUND(AVG(v.length_of_stay), 1) AS avg_length_of_stay
FROM visits v
GROUP BY visit_month, v.disease_category
ORDER BY visit_month, v.disease_category;


















