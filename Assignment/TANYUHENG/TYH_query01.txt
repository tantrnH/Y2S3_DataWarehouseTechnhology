-- =======================================================================================================
-- ======== Month ========
-- =======================================================================================================
SET PAGESIZE 50
SET LINESIZE 200

COLUMN MEMBERSHIPTYPE              HEADING 'Membership_Type'        FORMAT A15
COLUMN YEAR_MONTH                  HEADING 'Year-Month'             FORMAT A10
COLUMN BOOKLOANINMONTHS            HEADING 'BookLoans'              FORMAT 999,999,990
COLUMN AVGLOANDURATIONDAYS         HEADING 'Avg_Loan_Days'          FORMAT 999.99
COLUMN HIT_MAXBOOKUTI_PERC         HEADING 'Hit_MaxBookUti_%'       FORMAT 999.99
COLUMN HIT_MAXRESRUTI_PERC         HEADING 'Hit_MaxResvUti_%'       FORMAT 999.99
COLUMN TOTALOVERDUE                HEADING 'Total_Overdue'          FORMAT 999,999,990
COLUMN AVGOVERDUEDAYS              HEADING 'Avg_Overdue_Days'       FORMAT 999.99

-- ======== Monthly view with "hit max" percentages ========
CREATE OR REPLACE VIEW V_MEMBERSHIP_UTILISATION_REP_M AS
WITH
loans_m AS (  
  SELECT
    m.MembershipType,
    TO_CHAR(d.Cal_Date,'YYYY-MM')               AS Year_Month,
    COUNT(*)                                    AS BookLoanInMonths,
    ROUND(AVG(NVL(bl.LoanDays,0)), 2)           AS AvgLoanDurationDays,
    SUM(CASE WHEN NVL(bl.OverdueDays,0) > 0 THEN 1 ELSE 0 END) AS TotalOverdue,
    ROUND(AVG(NVL(bl.OverdueDays,0)), 2)        AS AvgOverdueDays
  FROM FACT_BookLoan bl
  JOIN DIM_Member m ON m.Member_KEY = bl.Member_KEY
  JOIN DIM_Date   d ON d.Date_KEY   = bl.LoanDate_KEY
  WHERE d.Cal_Date BETWEEN DATE '2024-01-01' AND DATE '2025-06-30'
  GROUP BY m.MembershipType, TO_CHAR(d.Cal_Date,'YYYY-MM')
),
book_hit_m AS (  
  SELECT
    t.MembershipType,
    t.Year_Month,
    COUNT(DISTINCT CASE WHEN t.MaxBookLoan > 0 THEN t.MemberID END) AS denom_members,
    COUNT(DISTINCT CASE WHEN t.MaxBookLoan > 0 AND t.LoansInMonth >= t.MaxBookLoan THEN t.MemberID END) AS hit_members
  FROM (
    SELECT
      m.MembershipType,
      TO_CHAR(d.Cal_Date,'YYYY-MM') AS Year_Month,
      m.MemberID,
      m.MaxBookLoan,
      COUNT(*) AS LoansInMonth
    FROM FACT_BookLoan bl
    JOIN DIM_Member m ON m.Member_KEY = bl.Member_KEY
    JOIN DIM_Date   d ON d.Date_KEY   = bl.LoanDate_KEY
    WHERE d.Cal_Date BETWEEN DATE '2024-01-01' AND DATE '2025-06-30'
    GROUP BY m.MembershipType, TO_CHAR(d.Cal_Date,'YYYY-MM'), m.MemberID, m.MaxBookLoan
  ) t
  GROUP BY t.MembershipType, t.Year_Month
),
resv_hit_m AS (  
  SELECT
    t.MembershipType,
    t.Year_Month,
    COUNT(DISTINCT CASE WHEN t.MaxReservation > 0 THEN t.MemberID END) AS denom_members,
    COUNT(DISTINCT CASE WHEN t.MaxReservation > 0 AND t.ResvInMonth >= t.MaxReservation THEN t.MemberID END) AS hit_members
  FROM (
    SELECT
      m.MembershipType,
      TO_CHAR(d.Cal_Date,'YYYY-MM') AS Year_Month,
      m.MemberID,
      m.MaxReservation,
      COUNT(*) AS ResvInMonth
    FROM FACT_Reservation r
    JOIN DIM_Member m ON m.Member_KEY = r.Member_KEY
    JOIN DIM_Date   d ON d.Date_KEY   = r.ReservationDate_KEY
    WHERE d.Cal_Date BETWEEN DATE '2024-01-01' AND DATE '2025-06-30'
      AND UPPER(r.ReservationStatus) = 'SUCCESS'
    GROUP BY m.MembershipType, TO_CHAR(d.Cal_Date,'YYYY-MM'), m.MemberID, m.MaxReservation
  ) t
  GROUP BY t.MembershipType, t.Year_Month
)
SELECT
  l.MembershipType,
  l.Year_Month,
  l.BookLoanInMonths,
  l.AvgLoanDurationDays,
  ROUND(NVL(bh.hit_members * 100.0 / NULLIF(bh.denom_members,0), 0), 2) AS Hit_MaxBookUti_Perc,
  ROUND(NVL(rh.hit_members * 100.0 / NULLIF(rh.denom_members,0), 0), 2) AS Hit_MaxResrUti_Perc,
  l.TotalOverdue,
  l.AvgOverdueDays
FROM loans_m l
LEFT JOIN book_hit_m bh
  ON bh.MembershipType = l.MembershipType
 AND bh.Year_Month     = l.Year_Month
LEFT JOIN resv_hit_m rh
  ON rh.MembershipType = l.MembershipType
 AND rh.Year_Month     = l.Year_Month
;


SELECT
  MembershipType,
  Year_Month,
  BookLoanInMonths,
  AvgLoanDurationDays,
  Hit_MaxBookUti_Perc,
  Hit_MaxResrUti_Perc,
  TotalOverdue,
  AvgOverdueDays
FROM V_MEMBERSHIP_UTILISATION_REP_M
ORDER BY
  CASE UPPER(MembershipType)
    WHEN 'BASIC'         THEN 1
    WHEN 'STANDARD'      THEN 2
    WHEN 'PREMIUM'       THEN 3
    WHEN 'STUDENT'       THEN 4
    WHEN 'INSTITUTIONAL' THEN 5
    ELSE 99
  END,
  (TO_NUMBER(SUBSTR(Year_Month,1,4))*100 + TO_NUMBER(SUBSTR(Year_Month,6,2)));
