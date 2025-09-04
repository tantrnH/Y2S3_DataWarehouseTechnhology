/* =================================== 1) Create Dimension Tables =================================== */

CREATE TABLE STUDENT_DIM (
    S_KEY                     NUMBER          NOT NULL,
    S_ID                      NUMBER          NOT NULL,
    S_NAME                    VARCHAR2(25)    NOT NULL,
    S_DOB                     DATE            NOT NULL,
    S_CITY                    VARCHAR2(15)    NOT NULL,
    S_STATE                   VARCHAR2(15)    NOT NULL,
    S_COUNTRY                 VARCHAR2(15)    NOT NULL,
    S_DATE_JOINED             DATE            NOT NULL,
    S_CGPA                    NUMBER(3,2)     NOT NULL,
    S_FACULTY_ENROLLED        VARCHAR2(20)    NOT NULL,
    S_HIGHEST_QUALIFICATION   VARCHAR2(15)    NOT NULL,
    CONSTRAINT STUDENT_DIM_PK PRIMARY KEY(S_KEY)
);

CREATE SEQUENCE STUDENT_DIM_SEQ START WITH 1234 INCREMENT BY 1;

CREATE TABLE COURSE_DIM (
    COURSE_KEY              NUMBER          NOT NULL,  
    COURSE_ID               NUMBER          NOT NULL,
    COURSE_TITLE            VARCHAR2(50)    NOT NULL,
    FACULTY_NAME            VARCHAR2(25)    NOT NULL,
    MAX_CAPACITY            NUMBER          NOT NULL,
    EFFECTIVE_START_DATE    DATE            NOT NULL,
    EFFECTIVE_END_DATE      DATE            NOT NULL,
    CONSTRAINT COURSE_DIM_PK PRIMARY KEY(COURSE_KEY)
);

CREATE SEQUENCE COURSE_DIM_SEQ START WITH 1234 INCREMENT BY 1;

CREATE TABLE DATE_DIM (
    DATE_KEY            NUMBER          NOT NULL,
    CAL_DATE            DATE            NOT NULL,
    ACAD_YEAR           VARCHAR2(9)     NOT NULL,
    FULL_DESC           VARCHAR2(40),  
    DAY_WEEK            NUMBER(1),
    DAY_NUM_MONTH       NUMBER(2),
    DAY_NUM_YEAR        NUMBER(3),
    LAST_DAY_IND        CHAR(1),
    CAL_WEEK_END_DATE   DATE,
    CAL_WEEK_YEAR       NUMBER(2),
    MONTH_NAME          VARCHAR2(9),
    CAL_MONTH_YEAR      NUMBER(2),
    CAL_YEAR_MONTH      CHAR(7),
    CAL_QUARTER         CHAR(2),
    CAL_YEAR_QUARTER    CHAR(7),
    CAL_YEAR            NUMBER(4),
    HOLIDAY_IND         CHAR(1),
    WEEKDAY_IND         CHAR(1),     
    CONSTRAINT DATE_DIM_PK PRIMARY KEY(DATE_KEY)
);

CREATE TABLE ENROLLMENT_FACT(
    S_KEY           NUMBER      NOT NULL,
    COURSE_KEY      NUMBER      NOT NULL,
    DATE_KEY        NUMBER      NOT NULL,
    SE_ID           NUMBER      NOT NULL,
    REGISTER_DATE   DATE        NOT NULL,
    GRADE           VARCHAR2(3) NOT NULL,     
    FEE_PER_CREDIT  NUMBER(6,2) NOT NULL,
    CREDIT_HOUR     NUMBER(3)   NOT NULL,  
    TOTAL_FEES      NUMBER(8,2) NOT NULL,
    CONSTRAINT EF_PK PRIMARY KEY(S_KEY, COURSE_KEY, DATE_KEY, SE_ID),
    CONSTRAINT EF_COURSE_FK FOREIGN KEY(COURSE_KEY) REFERENCES COURSE_DIM(COURSE_KEY),
    CONSTRAINT EF_DATE_FK   FOREIGN KEY(DATE_KEY)   REFERENCES DATE_DIM(DATE_KEY),
    CONSTRAINT EF_S_FK      FOREIGN KEY(S_KEY)      REFERENCES STUDENT_DIM(S_KEY),
    CONSTRAINT EF_SE_FK     FOREIGN KEY(SE_ID)      REFERENCES Semester_Enrollment(SE_ID)
);

/* =================================== 2) UPDATE ACADEMIC YEAR =================================== */

UPDATE DATE_DIM d
SET ACAD_YEAR = CASE
  WHEN d.CAL_DATE BETWEEN DATE '2025-06-16' AND DATE '2026-04-25' THEN '2025/26'
  WHEN d.CAL_DATE BETWEEN DATE '2026-06-29' AND DATE '2027-04-24' THEN '2026/27'
  ELSE d.ACAD_YEAR
END;

/* =================================== 3) Initial Loading for Fact Table =================================== */

INSERT INTO ENROLLMENT_FACT (
  S_KEY, 
  COURSE_KEY, 
  DATE_KEY, 
  SE_ID,
  REGISTER_DATE, 
  GRADE, 
  FEE_PER_CREDIT, 
  CREDIT_HOUR, 
  TOTAL_FEES
)
SELECT
  sd.S_KEY,                               
  cd.COURSE_KEY,                           
  TO_NUMBER(TO_CHAR(cel.CEL_register_date,'YYYYMMDD')) AS DATE_KEY,
  se.SE_ID,                                
  cel.CEL_register_date,
  cel.CEL_grade,
  cl.CL_fee_per_credit,
  c.C_credit_hour,
  (cl.CL_fee_per_credit * c.C_credit_hour) AS TOTAL_FEES
FROM   COURSE_ENROLL_LIST   cel                 
JOIN   SEMESTER_ENROLLMENT  se  ON se.SE_ID         = cel.SE_ID
JOIN   STUDENT              s   ON s.S_ID           = se.SE_Student_ID
JOIN   STUDENT_DIM          sd  ON sd.S_ID          = s.S_ID           
JOIN   COURSE_LIST          cl  ON cl.CL_ID         = cel.CL_ID
JOIN   COURSE               c   ON c.C_ID           = cl.CL_Course_ID
JOIN   COURSE_DIM           cd  ON cd.COURSE_ID     = c.C_ID           
JOIN   DATE_DIM             d   ON d.CAL_DATE       = TRUNC(cel.CEL_register_date);
