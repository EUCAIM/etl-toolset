-- Step 8 ETL initialization check

CREATE TABLE jobs (id VARCHAR(250) PRIMARY KEY, filename VARCHAR(250), step  NUMERIC);

CREATE TABLE init_complete (status BOOLEAN);
INSERT INTO init_complete VALUES (TRUE);