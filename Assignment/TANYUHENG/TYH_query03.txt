SET PAGESIZE 50
SET LINESIZE 200
SET TRIMSPOOL ON

COLUMN CATEGORY               HEADING 'Staff WPS Category'        FORMAT A20
COLUMN TOTAL_RECORDS          HEADING 'Number of Records'          FORMAT 999,999,990
COLUMN NUM_STAFF              HEADING 'Number of Staff'            FORMAT 999,999,990
COLUMN TOTAL_SALARY           HEADING 'Total Salary Expenses'      FORMAT 999,999,990
COLUMN "Workload/Salary"      FORMAT 999,999,990.99


CREATE OR REPLACE VIEW V_STAFF_WPS_BASE AS
WITH loan AS (
  SELECT bl.Staff_KEY, COUNT(*) AS loans
  FROM FACT_BookLoan bl
  JOIN DIM_Date d ON d.Date_KEY = bl.LoanDate_KEY
  WHERE d.Cal_Date BETWEEN DATE '2024-01-01' AND DATE '2025-06-30'
  GROUP BY bl.Staff_KEY
),
resv AS (
  SELECT r.Staff_KEY, COUNT(*) AS resvs
  FROM FACT_Reservation r
  JOIN DIM_Date d ON d.Date_KEY = r.ReservationDate_KEY
  WHERE d.Cal_Date BETWEEN DATE '2024-01-01' AND DATE '2025-06-30'
  GROUP BY r.Staff_KEY
)
SELECT
  s.StaffID,
  s.Salary,
  NVL(l.loans,0) + NVL(r.resvs,0)        AS Total_Records,
  CASE WHEN s.Salary > 0 THEN (NVL(l.loans,0) + NVL(r.resvs,0))*1.0 / s.Salary END AS WPS
FROM DIM_Staff s
LEFT JOIN loan l ON l.Staff_KEY = s.Staff_KEY
LEFT JOIN resv r ON r.Staff_KEY = s.Staff_KEY
WHERE s.Salary IS NOT NULL;


CREATE OR REPLACE VIEW V_STAFF_WPS_BUCKET AS
WITH base AS (
  SELECT StaffID, Salary, Total_Records, NVL(WPS,0) AS WPS
  FROM V_STAFF_WPS_BASE
),
stats AS (
  SELECT MIN(WPS) AS min_wps, MAX(WPS) AS max_wps
  FROM base
),
bucketed AS (
  SELECT
    b.*,
    s.min_wps,
    s.max_wps,
    (s.max_wps - s.min_wps) AS wps_range,
    CASE
      WHEN (s.max_wps - s.min_wps) = 0 THEN 'Qualified60'
      WHEN b.WPS >= s.min_wps + 0.8*(s.max_wps - s.min_wps) THEN 'Top20'
      WHEN b.WPS <  s.min_wps + 0.2*(s.max_wps - s.min_wps) THEN 'Underperformance20'
      ELSE 'Qualified60'
    END AS category
  FROM base b CROSS JOIN stats s
)
SELECT
  category,
  SUM(Total_Records) AS total_records,
  COUNT(*)           AS num_staff,
  SUM(NVL(Salary,0)) AS total_salary
FROM bucketed
GROUP BY category;


SELECT
  CASE category
    WHEN 'Top20'              THEN 'Top20'
    WHEN 'Qualified60'        THEN 'Qualified60'
    WHEN 'Underperformance20' THEN 'Underperformance20'
  END AS Category,
  total_records      AS "Number of Records",
  num_staff          AS "Number of Staff",
  total_salary       AS "Total Salary Expenses",
  ROUND(total_salary * 1.0 / NULLIF(total_records,0), 2) AS "Workload/Salary"
FROM V_STAFF_WPS_BUCKET
ORDER BY
  CASE category
    WHEN 'Top20'              THEN 1
    WHEN 'Qualified60'        THEN 2
    WHEN 'Underperformance20' THEN 3
    ELSE 99
  END;
