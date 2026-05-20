-- Step 8 ETL initialization check

CREATE TABLE IF NOT EXISTS jobs (id VARCHAR(250) PRIMARY KEY, filename VARCHAR(250), step  NUMERIC);

CREATE TABLE IF NOT EXISTS init_complete (status BOOLEAN);
INSERT INTO init_complete VALUES (TRUE);