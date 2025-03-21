use capstoneProject;

-- Data Exploration & Preprocessing (SQL)

-- Load the dataset and preview data
SELECT * FROM Encounters;
SELECT * FROM Patients;
SELECT * FROM Procedures;
SELECT * FROM Payers;
SELECT * FROM Organizations;

-- Check for missing values and inconsistencies
SELECT * FROM Encounters;
SELECT COUNT(*) FROM Encounters WHERE REASONCODE is null;
SELECT COUNT(*) FROM Encounters WHERE  REASONDESCRIPTION IS NULL;

SELECT * FROM Patients;
SELECT COUNT(*) FROM Patients WHERE DEATHDATE IS NULL;
SELECT COUNT(*) FROM Patients WHERE SUFFIX IS NULL;
SELECT COUNT(*) FROM Patients WHERE MAIDEN IS NULL;
SELECT COUNT(*) FROM Patients WHERE ZIP IS NULL;


SELECT * FROM Procedures;
SELECT COUNT(*) FROM Procedures WHERE REASONCODE IS NULL;
SELECT COUNT(*) FROM Procedures WHERE REASONDESCRIPTION IS NULL;

SELECT * FROM Payers;
SELECT COUNT(*) FROM payers WHERE ADDRESS IS NULL;
SELECT COUNT(*) FROM payers WHERE CITY IS NULL;
SELECT COUNT(*) FROM payers WHERE STATE_HEADQUARTERED IS NULL;
SELECT COUNT(*) FROM payers WHERE ZIP IS NULL;
SELECT COUNT(*) FROM payers WHERE PHONE IS NULL;

-- 
-- Data Cleaning (Example: Handling Nulls in Encounters)

DELETE FROM Encounters
WHERE REASONCODE IS NULL OR REASONDESCRIPTION IS NULL;

--Removing Duplicates
WITH CTE AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY REASONCODE, REASONDESCRIPTION ORDER BY REASONCODE, REASONDESCRIPTION) AS RN
    FROM Encounters
)
DELETE FROM CTE WHERE RN > 1;




-- FROM PATIENTS (null values)
DELETE FROM Patients
WHERE DEATHDATE IS NULL OR SUFFIX IS NULL OR MAIDEN IS NULL OR ZIP IS NULL;

-- Removing Duplicates
WITH CTE AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY DEATHDATE, SUFFIX, MAIDEN, ZIP ORDER BY DEATHDATE, SUFFIX, MAIDEN, ZIP) AS rn
    FROM Patients
)
DELETE FROM CTE
WHERE rn > 1;

--From Procedures;(NULL VALUES)
DELETE FROM procedures
WHERE REASONCODE IS NULL OR REASONDESCRIPTION IS NULL;

-- Remove duplicates

WITH CTE AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY Reasoncode, reasondescription ORDER BY Reasoncode, reasondescription) AS rn
    FROM procedures
)
DELETE FROM CTE
WHERE rn > 1;


--from Payers(NULL VALUES)
DELETE FROM payers
WHERE ADDRESS IS NULL OR CITY IS NULL OR STATE_HEADQUARTERED IS NULL OR ZIP IS NULL OR PHONE IS NULL;
 
 -- remove Duplicates
 WITH CTE AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY address, city, state_headquartered, zip, phone ORDER BY address, city, state_headquartered, zip, phone) AS rn
    FROM payers
)
DELETE FROM CTE
WHERE rn > 1



-- 2.  SQL Analysis Tasks
--((a) Evaluating Financial Risk by Encounter Outcome
--Identify high-risk ReasonCodes based on uncovered costs.)

SELECT ReasonCode, SUM(TOTAL_CLAIM_COST - PAYER_COVERAGE) AS UncoveredCost
FROM Encounters
GROUP BY ReasonCode
ORDER BY UncoveredCost DESC;
-- Second option
SELECT e.Id AS EncounterID, e.REASONCODE, e.REASONDESCRIPTION,
       e.TOTAL_CLAIM_COST, e.PAYER_COVERAGE, 
       (e.TOTAL_CLAIM_COST - e.PAYER_COVERAGE) AS UncoveredCost
FROM encounters e
WHERE (e.TOTAL_CLAIM_COST - e.PAYER_COVERAGE) > 0
ORDER BY UncoveredCost DESC;

--(b) Identifying Patients with Frequent High-Cost Encounters

SELECT ID
FROM Encounters
WHERE YEAR(START) = YEAR(GETDATE())  -- Or YEAR(CURDATE()) for MySQL
  AND TOTAL_CLAIM_COST > 10000
GROUP BY ID
HAVING COUNT(*) > 3;

-- second option
SELECT e.PATIENT, COUNT(e.Id) AS EncounterCount
FROM encounters e
WHERE YEAR(e.START) = 2024 AND e.TOTAL_CLAIM_COST > 10000
GROUP BY e.PATIENT
HAVING COUNT(e.Id) > 3;

-- (C) Identifying Risk Factors Based on Demographics and Diagnosis Codes
 
SELECT TOP 3 ENCOUNTERCLASS, COUNT(*) AS Frequency
FROM Encounters
GROUP BY ENCOUNTERCLASS
ORDER BY Frequency DESC;

-- Second option
SELECT e.REASONCODE, e.REASONDESCRIPTION, COUNT(e.Id) AS Frequency,
       p.GENDER, p.RACE, p.ETHNICITY
FROM encounters e
JOIN patients p ON e.PATIENT = p.Id
WHERE e.REASONCODE IS NOT NULL
GROUP BY e.REASONCODE, e.REASONDESCRIPTION, p.GENDER, p.RACE, p.ETHNICITY
ORDER BY Frequency DESC;


-- Analyze affected demographics (example: age)
SELECT ETHNICITY, COUNT(*) AS PatientCount
FROM Encounters E
JOIN Patients P ON E.ID = P.ID
WHERE E.ENCOUNTERCLASS = 'TopDiagnosisCode'  -- Replace with actual top code
GROUP BY ETHNICITY;

--(d) Assessing Payer Contributions for Different Procedure Types
SELECT DESCRIPTION, PAYER, SUM(Total_Claim_Cost) AS Total_Claim_Cost, SUM(PAYER_COVERAGE) AS Payer_Coverage
FROM Encounters
GROUP BY DESCRIPTION, PAYER;

--second Option
SELECT pr.CODE AS ProcedureCode, pr.DESCRIPTION, p.NAME AS PayerName,
       SUM(e.PAYER_COVERAGE) AS TotalPayerCoverage,
       SUM(e.TOTAL_CLAIM_COST) AS TotalClaimCost,
       (SUM(e.PAYER_COVERAGE) / SUM(e.TOTAL_CLAIM_COST)) * 100 AS CoveragePercentage
FROM procedures pr
JOIN encounters e ON pr.ENCOUNTER = e.Id
JOIN payers p ON e.PAYER = p.Id
GROUP BY pr.CODE, pr.DESCRIPTION, p.NAME;


--(e) Identifying Patients with Multiple Procedures Across Encounte


SELECT pr.PATIENT, COUNT(DISTINCT pr.ENCOUNTER) AS TotalEncounters,
       COUNT(DISTINCT pr.CODE) AS TotalProcedures
FROM procedures pr
GROUP BY pr.PATIENT
HAVING COUNT(DISTINCT pr.ENCOUNTER) > 1 AND COUNT(DISTINCT pr.CODE) > 1;

--(f) Analyzing Patient Encounter Duration

 SELECT e.Id AS EncounterID, o.NAME AS OrganizationName,
       DATEDIFF(HOUR, e.START, e.STOP) AS DurationHours
FROM encounters e
JOIN organizations o ON e.ORGANIZATION = o.Id
WHERE DATEDIFF(HOUR, e.START, e.STOP) > 24
ORDER BY DurationHours DESC;

