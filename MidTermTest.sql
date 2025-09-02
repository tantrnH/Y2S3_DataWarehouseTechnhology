/* =================================== Create Dimension Tables =================================== */

/* 1) DIM_DATE */
CREATE TABLE DIM_DATE (
  Date_Key      NUMBER(8)  NOT NULL,
  Cal_Date      DATE  NOT NULL,
  Day_Name      VARCHAR2(9),
  Day_Num_Week  NUMBER(1),
