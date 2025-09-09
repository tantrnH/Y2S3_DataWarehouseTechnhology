SET PAGESIZE 50
SET LINESIZE 200
SET TRIMSPOOL ON

COLUMN MEMBERSHIPTYPE                                       FORMAT A15
COLUMN YEAR_MONTH               HEADING 'Year-Month'        FORMAT A10
COLUMN YEAR_QTR                 HEADING 'Year-Quarter'      FORMAT A10
COLUMN OVERDUE_RATE_PCT         HEADING 'Overdue %'         FORMAT 999.99
COLUMN AVG_OVERDUE_DAYS         HEADING 'Avg Overdue Days'  FORMAT 999.99
COLUMN TOTAL_LOANS              HEADING 'Total_Loans'       FORMAT 999,999,990
COLUMN OVERDUE_LOANS            HEADING 'Overdue_Loans'     FORMAT 999,999,990
COLUMN AGE_BAND                 HEADING 'Age Band'          FORMAT A8
COLUMN MEMBERS_WITH_ACTIVITY    HEADING 'Active Members'    FORMAT 999,999,990
COLUMN REPEAT_OFFENDERS         HEADING 'Repeat Offenders'  FORMAT 999,999,990
COLUMN REPEAT_OFFENDER_RATE_PCT HEADING 'Repeat %'          FORMAT 999.99


-- Month Overdue view
CREATE OR REPLACE VIEW V_OVERDUE_TIME_M AS
SELECT
  TO_CHAR(d.Cal_Date,'YYYY-MM')                               AS Year_Month,
  COUNT(*)                                                     AS Total_Loans,
  SUM(CASE WHEN NVL(bl.OverdueDays,0) > 0 THEN 1 ELSE 0 END)  AS Overdue_Loans,
  ROUND(SUM(CASE WHEN NVL(bl.OverdueDays,0) > 0 THEN 1 ELSE 0 END)*100.0 / COUNT(*), 2) AS Overdue_Rate_Pct,
  ROUND(AVG(NVL(bl.OverdueDays,0)), 2)                        AS Avg_Overdue_Days
FROM FACT_BookLoan bl
JOIN DIM_Date d ON d.Date_KEY = bl.LoanDate_KEY
WHERE d.Cal_Date BETWEEN DATE '2024-01-01' AND DATE '2025-06-30'
GROUP BY TO_CHAR(d.Cal_Date,'YYYY-MM');

SELECT
  Year_Month, Total_Loans, Overdue_Loans, Overdue_Rate_Pct, Avg_Overdue_Days
FROM V_OVERDUE_TIME_M
ORDER BY (TO_NUMBER(SUBSTR(Year_Month,1,4))*100 + TO_NUMBER(SUBSTR(Year_Month,6,2)));




-- Member behavior (age) view
SET PAGESIZE 50
SET LINESIZE 200
SET TRIMSPOOL ON

COLUMN AGE_BAND                     HEADING 'Age Band'             FORMAT A8
COLUMN MEMBERSHIPTYPE               HEADING 'Membership Type'      FORMAT A15
COLUMN TOTAL_LOANS                  HEADING 'Num_Loans'            FORMAT 999,999,990
COLUMN OVERDUE_LOANS                HEADING 'Loans_Overdue'         FORMAT 999,999,990
COLUMN OVERDUE_RATE_PCT             HEADING 'Overdue %'             FORMAT 999.99
COLUMN AVG_OVERDUE_DAYS             HEADING 'Avg Overdue Days'      FORMAT 999.99
COLUMN MEMBERS_WITH_ACTIVITY        HEADING 'Active Members'        FORMAT 999,999,990
COLUMN REPEAT_OFFENDERS             HEADING 'Repeat Offenders'      FORMAT 999,999,990
COLUMN REPEAT_OFFENDER_RATE_PCT     HEADING 'Repeat %'              FORMAT 999.99

CREATE OR REPLACE VIEW V_OVERDUE_MEMBER_BEHAVIOR AS
WITH
m0 AS (
  SELECT
    m.MemberID,
    m.MembershipType,
    TRUNC(MONTHS_BETWEEN(DATE '2025-06-30', m.DOB)/12) AS AgeYears
  FROM DIM_Member m
),
base AS (
  SELECT
    CASE
      WHEN m0.AgeYears IS NULL            THEN 'Unknown'
      WHEN m0.AgeYears < 18               THEN '<18'
      WHEN m0.AgeYears BETWEEN 18 AND 25  THEN '18-25'
      WHEN m0.AgeYears BETWEEN 26 AND 40  THEN '26-40'
      WHEN m0.AgeYears BETWEEN 41 AND 60  THEN '41-60'
      ELSE '60+'
    END AS Age_Band,
    m.MembershipType,
    COUNT(*)                                                     AS Total_Loans,
    SUM(CASE WHEN NVL(bl.OverdueDays,0) > 0 THEN 1 ELSE 0 END)   AS Overdue_Loans,
    ROUND(SUM(CASE WHEN NVL(bl.OverdueDays,0) > 0 THEN 1 ELSE 0 END)*100.0/COUNT(*), 2) AS Overdue_Rate_Pct,
    ROUND(AVG(NVL(bl.OverdueDays,0)), 2)                         AS Avg_Overdue_Days
  FROM FACT_BookLoan bl
  JOIN DIM_Date   d ON d.Date_KEY   = bl.LoanDate_KEY
  JOIN DIM_Member m ON m.Member_KEY = bl.Member_KEY
  JOIN m0 ON m0.MemberID = m.MemberID
  WHERE d.Cal_Date BETWEEN DATE '2024-01-01' AND DATE '2025-06-30'
  GROUP BY
    CASE
      WHEN m0.AgeYears IS NULL            THEN 'Unknown'
      WHEN m0.AgeYears < 18               THEN '<18'
      WHEN m0.AgeYears BETWEEN 18 AND 25  THEN '18-25'
      WHEN m0.AgeYears BETWEEN 26 AND 40  THEN '26-40'
      WHEN m0.AgeYears BETWEEN 41 AND 60  THEN '41-60'
      ELSE '60+'
    END,
    m.MembershipType
),
per_member AS (
  SELECT
    m.MemberID,
    m.MembershipType,
    TRUNC(MONTHS_BETWEEN(DATE '2025-06-30', m.DOB)/12) AS AgeYears,
    COUNT(*) AS Loans_All,
    SUM(CASE WHEN NVL(bl.OverdueDays,0)>0 THEN 1 ELSE 0 END) AS Loans_Overdue
  FROM FACT_BookLoan bl
  JOIN DIM_Member m ON m.Member_KEY = bl.Member_KEY
  JOIN DIM_Date   d ON d.Date_KEY   = bl.LoanDate_KEY
  WHERE d.Cal_Date BETWEEN DATE '2024-01-01' AND DATE '2025-06-30'
  GROUP BY m.MemberID, m.MembershipType, TRUNC(MONTHS_BETWEEN(DATE '2025-06-30', m.DOB)/12)
),
tagged AS (
  SELECT
    CASE
      WHEN AgeYears IS NULL            THEN 'Unknown'
      WHEN AgeYears < 18               THEN '<18'
      WHEN AgeYears BETWEEN 18 AND 25  THEN '18-25'
      WHEN AgeYears BETWEEN 26 AND 40  THEN '26-40'
      WHEN AgeYears BETWEEN 41 AND 60  THEN '41-60'
      ELSE '60+'
    END AS Age_Band,
    MembershipType,
    MemberID,
    Loans_All,
    Loans_Overdue,
    CASE WHEN Loans_All >= 3 AND Loans_Overdue*1.0/Loans_All >= 0.5 THEN 1 ELSE 0 END AS Is_Repeat_Offender
  FROM per_member
),
offenders AS (
  SELECT
    Age_Band,
    MembershipType,
    COUNT(*)                                                  AS Members_With_Activity,
    SUM(Is_Repeat_Offender)                                   AS Repeat_Offenders,
    ROUND(SUM(Is_Repeat_Offender)*100.0/NULLIF(COUNT(*),0),2) AS Repeat_Offender_Rate_Pct
  FROM tagged
  GROUP BY Age_Band, MembershipType
)
SELECT
  b.Age_Band,
  b.MembershipType,
  b.Total_Loans,
  b.Overdue_Loans,
  b.Overdue_Rate_Pct,
  b.Avg_Overdue_Days,
  NVL(o.Members_With_Activity,0)       AS Members_With_Activity,
  NVL(o.Repeat_Offenders,0)            AS Repeat_Offenders,
  NVL(o.Repeat_Offender_Rate_Pct,0)    AS Repeat_Offender_Rate_Pct
FROM base b
LEFT JOIN offenders o
  ON o.Age_Band = b.Age_Band
 AND o.MembershipType = b.MembershipType;



SELECT
  Age_Band,
  MembershipType,
  Total_Loans,
  Overdue_Loans,
  Overdue_Rate_Pct,
  Avg_Overdue_Days,
  Members_With_Activity,
  Repeat_Offenders,
  Repeat_Offender_Rate_Pct
FROM V_OVERDUE_MEMBER_BEHAVIOR
ORDER BY OVERDUE_RATE_PCT DESC,
         Repeat_Offenders DESC,
         Repeat_Offender_Rate_Pct DESC;
