--------------------------------------------------------------------------------------------------------------------------------------------------------
--                                          WATERS CORP.
--
--				               nugenesis9_PreInstall_checklist_r1.sql
--
--  This script is intended to check for known issues which will interfere with a successful installation of the NuGenesis 9 schemas on a Linux database.
-- 
--  PERSON			REVISION		DATE		REASON
--  MMorrison			1			2022-01-14	CREATION.  Forked from the NG9 db_onitor script r5.
--  MMorrison			2			2022-01-17	Removed sec_case_sensitive_logon.  Removed duplicate checks of nls_characterset.  Report on nls_length_semantics and recyclebin.
-- 									Report on redo log sizing.
---------------------------------------------------------------------------------------------------------------------------------------------------------
SET FEEDBACK OFF LINESIZE 500 PAGESIZE 200 TRIMSPOOL ON TIMING OFF ECHO OFF DOC OFF TRIM ON verify off SERVEROUTPUT ON SIZE 1000000 heading ON define ON
TTITLE OFF
COLUMN file NEW_VALUE file NOPRINT 
COLUMN BYTES 			FORMAT 999,999,999,999 heading 'Size'
COLUMN TODAY 			FORMAT a30
COLUMN CREATED 			FORMAT A20
COLUMN FILE_NAME 		FORMAT A70
COLUMN TABLESPACE_NAME 		FORMAT A35
COLUMN TEMPORARY_TABLESPACE 	FORMAT A15 HEADING 'TEMPORARY'
COLUMN USERNAME			FORMAT A20
COLUMN NAME 			FORMAT A30
COLUMN OWNER 			FORMAT A15
COLUMN OBJECT_TYPE 		FORMAT A15
COLUMN OBJECT_NAME 		FORMAT A30
COLUMN CREATED 			FORMAT A15
COLUMN VERSION_NUMBER 		FORMAT A12
COLUMN TIMEDIFF 		FORMAT A15
COLUMN TRIGGERING_EVENT		FORMAT A10
COLUMN TABLE_NAME 		FORMAT A25
COLUMN SCHEMA_USER		FORMAT A15
COLUMN INTERVAL			FORMAT A20
COLUMN WHAT			FORMAT A25
COLUMN SEGMENT_NAME 		FORMAT A40
COLUMN CLUSTER_NAME		FORMAT A40
COLUMN comp_name format a30

ALTER SESSION SET NLS_DATE_FORMAT = "MM/DD/YYYY";
COLUMN file NEW_VALUE file NOPRINT 
SELECT 'NuGenesis9_PreInstall_checklist_r1_'||to_char(sysdate,'yyyy-mm-dd-hh24miss')||'.log' "file" FROM DUAL;
SPOOL &file

-- Declare variables for various NG9 schema options.
VARIABLE	v_ConnTableCount	NUMBER;
VARIABLE	v_SlimSchemaPresent	NUMBER;
VARIABLE	v_WDMSchemaPresent	NUMBER;
VARIABLE	v_SAPTableCount		NUMBER;
VARIABLE	v_Partitioning		NUMBER;
VARIABLE	v_LMSSchemaVerAsNum	NUMBER;
VARIABLE	v_LMSSchemaVer		CHAR(10);
VARIABLE	V_NGContainerName	CHAR(500);
SELECT	TO_CHAR(sysdate,'YYYY-MM-DD HH24:MI:SS') today from sys.dual;

PROMPT
prompt           ******************************************************
prompt           *      NuGenesis 9  Pre-Installation Report          *
prompt           ******************************************************
prompt
prompt		  THIS SCRIPT MUST BE EXECUTED WITH DBA PRIVILEGES IN THE SDMS CONTAINER!
PROMPT
SELECT SYS_CONTEXT('USERENV','CURRENT_USER') "CurrentUsername" FROM dual;
PROMPT
PROMPT ___________________________________________________________________________________________________________
PROMPT Oracle database and instance version info
PROMPT

SELECT BANNER FROM V$VERSION;
SELECT instance_name, host_name, status, archiver, database_status FROM v$instance;

PROMPT
PROMPT Oracle component information for this database instance:
SELECT comp_name, version, status, modified FROM DBA_REGISTRY;

PROMPT
PROMPT List of installed Oracle patches:
SELECT patch_id, status FROM sys.registry$sqlpatch;

COLUMN DBID HEADING "DATABASE ID"
COLUMN PLATFORM_NAME FORMAT A35 HEADING "OS"
COLUMN PLATFORM_ID HEADING "OS ID"
COLUMN CDB FORMAT A35 HEADING "CONTAINER DB"

PROMPT
SELECT cdb, con_id, open_mode, con_dbid, dbid, platform_name, platform_id, created, resetlogs_time FROM v$database;

COLUMN COMP_NAME	FORMAT	A40 HEADING "COMPONENT NAME"
COLUMN VERSION		FORMAT A12
COLUMN value		FORMAT a50
COLUMN name		FORMAT a30
col parameter		format a30
PROMPT
PROMPT List of installed Oracle components:
SELECT COMP_NAME, VERSION, STATUS, MODIFIED FROM DBA_REGISTRY;

PROMPT
PROMPT List of installed Oracle patches:
SELECT patch_id, status FROM sys.registry$sqlpatch;

PROMPT
PROMPT DATABASE LANGUAGE SETTINGS:
SELECT * FROM NLS_DATABASE_PARAMETERS;

col Parameter format a40
col value format a10

PROMPT
PROMPT ______________________________________________________________________________________
PROMPT Checking for the DB options which impact NuGenesis:
PROMPT
DECLARE
v_Count 	PLS_INTEGER := 0;
BEGIN
	SELECT COUNT(*) INTO v_Count FROM v$option WHERE parameter = 'Partitioning' AND value = 'TRUE';
	IF (v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('The Partitioning option is enabled in this instance');
	ELSIF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('The Partitioning option is NOT enabled in this instance');
	END IF;

	SELECT COUNT(*) INTO v_Count FROM v$option WHERE parameter = 'Advanced Compression' AND value = 'TRUE';
	IF (v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('The Advanced Compression option is enabled in this instance');
	ELSIF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('The Advanced Compression option is NOT enabled in this instance');
	END IF;

	SELECT COUNT(*) INTO v_Count FROM v$option WHERE parameter = 'Advanced Index Compression' AND value = 'TRUE';
	IF (v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('The Advanced Index Compression option is enabled in this instance');
	ELSIF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('The Advanced Index Compression option is NOT enabled in this instance');
	END IF;
END;
/

PROMPT
PROMPT List of the installed database options:
SELECT * FROM v$option WHERE value != 'FALSE';

PROMPT
PROMPT ______________________________________________________________________________________
PROMPT Checking the database parameters which impact NuGenesis
PROMPT
DECLARE
v_ParamValue		v$parameter.value%TYPE;
v_val			PLS_INTEGER;

BEGIN
	SELECT VALUE INTO v_ParamValue FROM V$PARAMETER WHERE NAME ='db_securefile';
	IF (v_ParamValue = 'PREFERRED')		THEN	DBMS_OUTPUT.PUT_LINE('-- db_securefile='||v_ParamValue||' in this database.  NuGenesis 9 expects db_securefile to be set to "PREFERRED".');
	ELSE						DBMS_OUTPUT.PUT_LINE('-- !!! WARNING: db_securefile='||v_ParamValue||' in this database.  NuGenesis 9 expects db_securefile to be set to "PREFERRED".');
	END IF;

	SELECT value INTO v_ParamValue FROM v$parameter WHERE name = 'db_block_size';
	IF v_ParamValue < 8192			THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: db_block size='||v_ParamValue||' in this database!  NuGenesis expects a block size of at least 8192!');
	ELSE						DBMS_OUTPUT.PUT_LINE('-- db_block size='||v_ParamValue||' in this database.  No action is necessary.');
	END IF;

	SELECT TO_NUMBER(VALUE) INTO v_val FROM V$PARAMETER WHERE NAME = 'job_queue_processes';
	IF (v_val >= 1000)			THEN	DBMS_OUTPUT.PUT_LINE('-- job_queue_processes='||v_val||' in this database.  No action is necessary.');
	ELSE						DBMS_OUTPUT.PUT_LINE('-- !!! WARNING: job_queue_processes='||v_val||' in this database!  This must be set to at least 1000 for NuGenesis databases.');
	END IF;

	SELECT VALUE INTO v_ParamValue FROM NLS_DATABASE_PARAMETERS WHERE parameter = 'NLS_CHARACTERSET';
	IF v_Paramvalue = 'AL32UTF8'		THEN	DBMS_OUTPUT.PUT_LINE ('-- nls_characterset='||v_ParamValue||' in this database. This is the correct characterset for NuGenesis.');
	ELSIF v_Paramvalue != 'AL32UTF8'	THEN	DBMS_OUTPUT.PUT_LINE ('-- !!!!! ERROR: nls_characterset='||v_Paramvalue||'! NuGenesis 9 requires the AL32UTF8 characterset!');
	END IF;

	SELECT VALUE INTO v_ParamValue FROM NLS_DATABASE_PARAMETERS WHERE parameter = 'NLS_LENGTH_SEMANTICS';
	IF v_Paramvalue = 'BYTE'		THEN	DBMS_OUTPUT.PUT_LINE ('-- nls_length_semantics='||v_ParamValue||' in this database. This is the correct setting for NuGenesis.');
	ELSIF v_Paramvalue != 'BYTE'		THEN	DBMS_OUTPUT.PUT_LINE ('-- !!! WARNING: nls_length_semantics='||v_Paramvalue||'! NuGenesis 9 requires ''BYTE'' for nls_length_semantics.');
	END IF;

	SELECT value INTO v_ParamValue FROM v$parameter WHERE name = 'compatible';
	IF 	(v_ParamValue LIKE '12.1%')					THEN	DBMS_OUTPUT.PUT_LINE('-- !!! WARNING: compatible='||v_ParamValue||' in this CDB!  A compatibility level of 12.2.0 or higher is recommended for NuGenesis 9 databases.');
	ELSIF	(v_ParamValue LIKE '12.2%' OR v_ParamValue LIKE '19.0%')	THEN	DBMS_OUTPUT.PUT_LINE('-- compatible='||v_ParamValue||' in this CDB.  This is the recommended setting for NuGenesis 9.');
	ELSE										DBMS_OUTPUT.PUT_LINE('-- Unknown value for compatible='||v_ParamValue);
	END IF;

	SELECT value INTO v_ParamValue FROM v$parameter WHERE name = 'recyclebin';
	DBMS_OUTPUT.PUT_LINE('-- recyclebin='||v_ParamValue||' in this database.');
END;
/

col value format a15
PROMPT
PROMPT List of the database configuration parameters:
SELECT name, value FROM v$parameter WHERE name IN ('cpu_count','shared_pool_size','db_cache_size','db_block_size','db_file_multiblock_read_count','parallel_automatic_tuning','text_enable','optimizer_percent_parallel','sql_version','optimizer_mode','open_cursors','db_name','sort_area_size','sort_area_retained_size','instance_name','db_files') ORDER BY name;

col property_name format a30
col property_value format a60
PROMPT
PROMPT ______________________________________________________________________________________
PROMPT Checking the database properties in this PDB which impact NuGenesis
PROMPT
DECLARE
v_ParamValue		database_properties.property_value%TYPE;
v_Count			PLS_INTEGER;

BEGIN
	SELECT COUNT(*) INTO v_Count FROM database_properties WHERE property_name = 'DEFAULT_TBS_TYPE';
	IF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('Database property DEFAULT_TBS_TYPE is not present in this PDB');
	ELSIF (v_Count = 1)	THEN
		SELECT property_value INTO v_ParamValue FROM database_properties WHERE property_name = 'DEFAULT_TBS_TYPE';
		DBMS_OUTPUT.PUT_LINE('Default tablespace type: '||v_ParamValue);
		IF (v_ParamValue = 'SMALLFILE')	THEN	DBMS_OUTPUT.PUT_LINE('-- This is the expected default tablespace type for NuGenesis.');
		ELSIF (v_ParamValue = 'BIGFILE')	THEN	DBMS_OUTPUT.PUT_LINE('-- !!! WARNING: BIGFILE tablespaces are not compatible with the NuGenesis schema installation scripts!  Set the DEFAULT_TBS_TYPE property to SMALLFILE before starting the installation!');
		ELSE						DBMS_OUTPUT.PUT_LINE('-- It is not known what effect this tablespace type will have on NuGenesis.  The installation scripts expect SMALLFILE tablespaces, and it is recommended to set DEFAULT_TBS_TYPE to SMALLFILE before starting the installation.');
		END IF;
	END IF;
END;
/

PROMPT
PROMPT ______________________________________________________________________________________
PROMPT Checking the REDO LOG parameters
PROMPT
DECLARE
v_Count			PLS_INTEGER;
v_LogGroupNo		v$log.group#%TYPE;
v_LogGroupSize		v$log.bytes%TYPE;
CURSOR C_RedoLogGroups IS SELECT group#, bytes FROM v$log;
BEGIN
	SELECT COUNT(*) INTO v_Count FROM v$log;
	DBMS_OUTPUT.PUT_LINE('-- Number of REDO logs: '||v_Count|| ' (expected: at least 3)');
	IF (v_Count < 3)	THEN	DBMS_OUTPUT.PUT_LINE('-- -- !!! WARNING: The number of REDO logs is less than expected for NuGenesis.');
	END IF;

	DBMS_OUTPUT.PUT_LINE('-- Checking the size of each REDO log group...');
	OPEN C_RedoLogGroups;
	LOOP
		FETCH C_RedoLogGroups INTO v_LogGroupNo, v_LogGroupSize;
		EXIT WHEN C_RedoLogGroups%NOTFOUND;

		IF (v_LogGroupSize < 200000000)	THEN	DBMS_OUTPUT.PUT_LINE('-- -- !!! WARNING: the size of redo log group no. '||v_LogGroupNo||', '||v_LogGroupSize||' bytes, is less than required for NuGenesis (expected: at least 200,000,000).');
		ELSE					DBMS_OUTPUT.PUT_LINE('-- -- The size of redo log group no. '||v_LogGroupNo||' is '||v_LogGroupSize||' bytes (expected: at least 200,000,000).');
		END IF;
	END LOOP;
	CLOSE C_RedoLogGroups;
END;
/

PROMPT
PROMPT ______________________________________________________________________________________
PROMPT Checking for the TEMP tablespace ...
PROMPT
DECLARE
v_Count		PLS_INTEGER := 0;

BEGIN
	SELECT COUNT(*) INTO v_Count FROM dba_tablespaces WHERE tablespace_name = 'TEMP' AND contents = 'TEMPORARY';
	IF (v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('A temporary tablespace named TEMP exists in this database.');
	ELSIF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: a temporay tablespace named TEMP does not exist in this database!  The NuGenesis schema installation scripts require a temp tablespace named TEMP for the schema accounts.');
	END IF;
END;
/

PROMPT
PROMPT ______________________________________________________________________________________
PROMPT Determining whether this script is running in a containerized database...
PROMPT
DECLARE
v_cdb		VARCHAR2(3);
BEGIN
	SELECT cdb INTO v_cdb FROM v$database;
	IF (v_cdb = 'YES')	THEN	DBMS_OUTPUT.PUT_LINE('This is a containerized database.');
	ELSIF (v_cdb = 'NO')	THEN	DBMS_OUTPUT.PUT_LINE('This is not a container database.');
	ELSE				DBMS_OUTPUT.PUT_LINE('Unknown value for the CDB property in v$database: '||v_cdb);
	END IF;
END;
/

col CurrentContainerID format a10
col CurrentContainerName format a50
SELECT SYS_CONTEXT('USERENV','CON_ID') "CurrentContainerID", SYS_CONTEXT('USERENV','CON_NAME') "CurrentContainerName" FROM dual;

PROMPT
PROMPT List of containers in this database:
SELECT con_id, dbid, name, open_mode FROM v$containers;

PROMPT
PROMPT
PROMPT ______________________________________________________________________________________
PROMPT Determining if this database instance is in an Oracle real application cluster (RAC)
PROMPT
DECLARE
v_val		VARCHAR2(4000);

BEGIN
	SELECT VALUE INTO v_val FROM V$PARAMETER WHERE NAME = 'cluster_database';
	IF v_val = 'TRUE'	THEN	DBMS_OUTPUT.PUT_LINE('The cluster_database parameter for this database is true, indicating a RAC installation');
	ELSIF v_val = 'FALSE'	THEN	DBMS_OUTPUT.PUT_LINE('The cluster_database parameter for this database is false, indicating this is not a RAC installation');
	ELSE				DBMS_OUTPUT.PUT_LINE('Unknown value for the cluster_database parameter in this database: '||v_val);
	END IF;
END;
/

PROMPT
PROMPT ______________________________________________________________________________________
PROMPT Checking the database character set ...
PROMPT
DECLARE
v_value		VARCHAR2(120);

BEGIN
	SELECT VALUE INTO v_value FROM NLS_DATABASE_PARAMETERS WHERE PARAMETER = 'NLS_CHARACTERSET';
	IF v_value = 'AL32UTF8'		THEN	DBMS_OUTPUT.PUT_LINE ('This database has the correct nls_characterset for NuGenesis 9: '||v_value);
	ELSIF v_value != 'AL32UTF8'	THEN	DBMS_OUTPUT.PUT_LINE ('!!!!! ERROR: incompatible nls_characterset! The nls_characterset for this database is: '||v_value||'! (expected: AL32UTF8)');
	END IF;
END;
/

PROMPT
PROMPT List of tablsepaces in this database:
SELECT tablespace_name, status, contents, logging, encrypted, bigfile FROM dba_tablespaces ORDER BY tablespace_name;


PROMPT
PROMPT
PROMPT ****************************************************************************************************************
PROMPT Verifying the Oracle Text configuration in this database instance...
PROMPT ****************************************************************************************************************
PROMPT
PROMPT

DECLARE 
v_Count		PLS_INTEGER := 0;
v_ExpectedNo	PLS_INTEGER;
v_object	VARCHAR2(500);	
v_SchemaName	VARCHAR2(500);
v_PrefName	ctxsys.ctx_preferences.pre_name%TYPE;

TYPE ObjList	IS TABLE OF VARCHAR2(500);
t_PrefsList	ObjList;
t_SchemaList	ObjList;
t_PrivsList	ObjList;

CURSOR C_INVAL IS SELECT OBJECT_NAME FROM DBA_OBJECTS where OWNER = 'CTXSYS' and status = 'INVALID';

BEGIN
	SELECT COUNT(COMP_NAME) INTO v_Count FROM DBA_REGISTRY WHERE COMP_NAME = 'Oracle Text';
	IF (v_Count > 0)	THEN
		DBMS_OUTPUT.PUT_LINE('This database instance was created with the Oracle Text option.');

		SELECT schema INTO v_SchemaName FROM dba_registry WHERE comp_Name = 'Oracle Text';
		IF (v_SchemaName = 'CTXSYS')	THEN	DBMS_OUTPUT.PUT_LINE('-- The schema for Oracle Text is CTXSYS.');
		ELSE					DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: the schema for Oracle Text is '||v_SchemaName||'; expected CTXSYS!');
		END IF;

		SELECT COUNT(*) INTO v_Count FROM dba_objects WHERE owner = 'SYS' AND object_name LIKE 'CTX%';
		IF (v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('-- SYS does not own any CTX objects.'); -- In aproperly installed database, sys will own CTXAGIMP, a defined type within the database.
		ELSIF (v_Count > 1)	THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: SYS owns 1 or more CTX objects!  All Oracle Text objects should be owned by CTXSYS!');
		END IF;

		select COUNT(OBJECT_NAME) INTO v_Count from dba_objects where OWNER = 'CTXSYS' and status = 'INVALID';
		IF v_Count = 0 THEN	DBMS_OUTPUT.PUT_LINE('-- All objects owned by ctxsys have a valid status.');
		ELSIF v_Count > 0 THEN
			DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: the following objects owned by ctxsys have an invalid status!');
			OPEN C_INVAL;
			LOOP
				FETCH C_INVAL INTO v_object;
				EXIT WHEN C_INVAL%NOTFOUND;
				DBMS_OUTPUT.PUT_LINE('-- '||v_object);
			END LOOP;
			CLOSE C_INVAL;
		END IF;

		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('Determining whether the default Oracle Text preferences are present...');
		t_PrefsList  := ObjList('DEFAULT_CLASSIFIER','DEFAULT_CLUSTERING','DEFAULT_DATASTORE','DEFAULT_EXTRACT_LEXER','DEFAULT_LEXER','DEFAULT_STORAGE','DEFAULT_WORDLIST');
		v_ExpectedNo := t_PrefsList.COUNT;
		SELECT COUNT(PRE_NAME) INTO v_Count  FROM  CTXSYS.CTX_PREFERENCES WHERE PRE_OWNER = 'CTXSYS';
		IF (v_Count < v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: ctxsys has less than the expected number of Oracle Text default preferences (at least'||v_ExpectedNo||' expected, '||v_Count||' found)!');
		ELSIF (v_Count >= v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('Ctxsys has the expected number of Oracle Text default preferences (at least '||v_ExpectedNo||' expected, '||v_Count||' found)');
		END IF;

		FOR indx in 1 .. t_PrefsList.COUNT
		LOOP
			SELECT COUNT(PRE_NAME) INTO v_Count  FROM  CTXSYS.CTX_PREFERENCES WHERE PRE_OWNER = 'CTXSYS' AND PRE_NAME = t_PrefsList(indx);
			IF v_Count = 0 THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: default preference: '||t_PrefsList(indx)||' is not present');
			ELSE			DBMS_OUTPUT.PUT_LINE('-- default preference: '||t_PrefsList(indx)||' is present');
			END IF;
		END LOOP;
	ELSIF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: this database instance was created without the oracle text option!  Have the customer dba install this oracle component, it is absolutely required for NuGenesis databases!!!!!');
	END IF;
END;
/

PROMPT
PROMPT _________________________________________________________________________________________________________
PROMPT Reporting on the database initialization parameters:
PROMPT
DECLARE
v_Count		PLS_INTEGER := 0;

BEGIN
	SELECT COUNT(*) INTO v_Count FROM v$spparameter;
	IF	(v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('For this database the initialization parameters are managed by an init.ora file');
	ELSIF	(v_Count > 0)	THEN	DBMS_OUTPUT.PUT_LINE('For this database the initialization parameters are managed by an SPfile');
	END IF;
END;
/

spool off
