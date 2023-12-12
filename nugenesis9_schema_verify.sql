--------------------------------------------------------------------------------------------------------------------------------
--                                                      Waters Corporation
--                                                      nugenesis_9_schema_verify
-- Person	Version 	Date		Reason
-- DBREIDING	1		06-15-18	Creation
-- DBREIDING	2		07-06-18	Detect presence of Oracle 12 container database
-- DBREIDING	3		08-07-18	Updated For NuGenesis 9 Build 02
-- DBREIDING	4		08-08-18	Use NGSYSUSER.NCONFIG.NGKEYVALUE COLUMN TO CONFIRM SDMS VERSION
-- DBREIDING	5		08-09-18	NuGenesis 9 NOT SUPPORTED ON ORACLE 12.1.x, Check for ELNPROD USER_DATASTORE(S), Check for Smart Procedure Database Updates
-- DBREIDING	6		01-15-19
-- DBREIDING	7		01-16-19
-- DBREIDING	8		02-13-19 	CHANGE COLUMN WIDTHS, REPORTING FOR NGSYSUSER AND NGSDMS60 OBJECT PRIVILEGES. ELNPROD INDEX REPORTING
-- DBREIDING	9		04-24-19	Report on nologging indicies and tables in the elnprod schema.
-- DBREIDING	10		06-25-19	Update for Nugenesis 9 Sr1 Database Updates.
-- DBREIDING	11		07-25-19	Do not report on WATUTCSYNC Job
-- DBREIDING	12		09-18-19	Add Constraint Check
-- DBREIDING	13		09-25-19	List Nologging FUNCTION-BASED NORMAL indexes
-- DBREIDING	14		10-17-19	Report Failed SR1 updates only for SCHEMAVER = 800
-- DBREIDING	15		11-13-19	Correct ELNPROD Table Count Reporting
-- DBREIDING	16		11-14-19	Check for presence of DR$ADVANCE_SEARCH$U, report on absence.
-- MMORRISON	17		2020-01-06	Update for LMS v9.0.2
-- MMORRISON	18		2020-01-09	Update for LMS 9.0.2 Hotfix 1.  Remove warnings on the LMS schema version.
-- MMORRISON	19		2020-01-16	Display the SDMS and LMS shema version info and simplify the PLSQL check on the Oracle and schema version numbers.
-- 						Remove duplicate queries on tablespace quotas. Correct a typo in rev. 18 for the 9.0.2 update checks. Remove references to SDMS 8.
-- MMORRISON	20		2020-01-20	Added a check for the database timezone file.  Simplified the Oracle Text queries.  Consolidated the Oracle Text verifications into one part of the script.
-- 						Report on the expected NuGenesis sequences.  Report on whether Stability, WDM, or Connectors are installed.  Report on DB links for NG Connectors.
-- 						Report on the expected NG synonyms.  Report on missing DR$..$U tables.
-- MMORRISON	21		2020-02-06	Report on table names when they're present, not just missing.  Show a full list of tables in the NG schemas.  Show a full list of NG indexes.
-- 						Use the correct table lists for the NG clusters.  Check for the presence of LDAP params in SDMS before reporting on them; the params are not present in a new install.
-- 						Correct the expected list entries for the Smart Procedures updates.  Detect whether LMS-SAP interface is installed.  Update the expected system privs and roles list
-- 						to better match a new database install.
-- MMORRISON	22		2020-02-11	Remove the SYSC-constraint from the listed of expected primary key constraints for Elnprod.  Change the code to report an error only if the number of found constraints
-- 						is less than the expected number.  List the installed Oracle patches.  Report on nglastid for the SDMS admin project.  Report on addition schema objects for Connectors.
-- 						Revise the lists of expected triggers, constraints, and indexes to better match a new NG9 install.
-- MMorrison	23		2020-02-18	Report on the LMS Data Location in SDMS.  Report on db_links owned by NG schemas.
-- MMorrison	24		2020-04-17	Restarting the r-numbering in the file name.  For a list of all changes between r23 and 24, please see the changelog in the bitbucket repository.
-- MMorrison	25		2020-04-21	Display lists of NG views and synonyms.
-- MMorrison    26		2020-04-30	Removed SYS_EXPORT_ table from the expected table list for ELNPROD.  Filter out SYS_ tables when getting the count of tables per schema owner.
-- MMorrison    27		2020-05-04	Modified the check for NuGenesis schema accounts to allow ngprofile or sdmsprofile on each account.  Fix an incorrect variable name.  Added some commentary text.
-- MMorrison	28		2020-05-07	Fix the query on schema tables to exclude only the SYS_EXPORT_ and SYS_IMPORT_ and not exclude any valid schema tables.  Per 9.0.2 phase 3, 19c v19.6 is now a valid DB version.
-- MMorrison    29		2020-06-03	Modify the queries on the DB version to account for the new version scheme in Oracle 19c.
-- MMorrison	30		2020-07-01	Check for grants made to the PUBLIC account.  Add a new section to check for privs necessary for SDMS email notifications.  Corrected error message when finding a primary key
-- 						constraint using the wrong index.  First updates for NuGenesis 9.1.
-- MMorrison	31		2020-08-11	Resolved the script error when running r30 on an NG 9.0 DB.Corrected the expected table lists for 9.1 and 9.0.
-- MMorrison	32		2020-08-13	Use 9.0- and 9.1-specific lists for the privileges assigned to ngsdms70proxyrole.
-- MMorrison	33		2020-09-24	Reformat privilege lists for ngsdms70proxyrole to fit within the 2499-char limit for PLSQL lines.
-- MMorrison	34		2020-10-13	Modify the queries which check for non-NG objects in NG schemas so that WDM-owned objects are not flagged by the queries.
-- MMrrison	35		2020-10-15	Do not query for most recent run date and status if the details are not in the database.
-- MMorrison	36		2020-10-20	Reduce the number of expected normal and LOB indexes for ELNPROD.  SYS_EXPORT tables have 8 indexes on them, and dropping the table would cause errors to appear in r35 and earlier.
-- MMorrison	37		2020-11-03	Adjust the number of LOB and IOT-TOP indexes for elnprod in NG9.0.x based on Oracle version.  9.0.2 on Linux is supported on ORacle 19c, and in this version, creates fewer indexes vs. 12c.
-- MMorrison	38		2020-11-23	Show the current user.  Use separate LSQL blocks for the schema version info in case on of the schemas is not found or cannot be queried.
-- MMorrison	39		2020-12-03	Remove the DR-dollar-NAME-dollar-R tables from the list of expected tables for NGSDMS60 and ELNPROD if the schema ver is 9.0.x and the Oracle ver is 19.
-- MMorrison	40		2020-12-07	Remove duplicate table names from the expected table lists for elnprod.
-- MMorrison	41		2021-02-05	Remove Connect and Resource fro mthe expected roles for ngsdms60.  Check for execute on ctxddl or the role ctxapp.  Skip the 9.0.1 or 9.0.2 schema checks if the installed version does not match.
--						Check for leftover CMP3$ and CMP4$ tables in the NG schemas.
-- MMorrison    42		2021-02-24	Remove the warning message for non-19.6 versions of 19c.  NG 9.1 is supported on any available patchset for 19c.  Correct a syntax error in the section on the 901 schema updates.
--						Add Connectors_Plugins to the list of tables for the Conectors.  Report on the WATERSMON user for the Waters System Monitor.
-- MMorrison	43		2021-03-19	Check the default tablespace type in database_properties.  Report the script revision number in the log file.  Check for unexpected triggers owned by the NuGenesis schemas.
-- MMorrison	44		2021-05-06	Fixed a bug in detection of the WSM schema.  Reduce the minimum  number of normal indexes for elnprod from 532 to 520.  Change the text of the output to show that the expected no of indexes is the minimum number expected.
-- MMorrison    45		2021-07-20	Report on NuGenesis tables, lobs, and partitions which use advanced compression.  Reduce the minimum  number of normal indexes for elnprod from 520 to 510. Update for 9.1 HF2.
-- MMorrison    46		2021-08-25	First version to support NuGenesis 9.2.
-- MMorrison    47		2021-09-09	Corrected a few typoes.  Changed the Oracle version check to state that 19c is an acceptable version for Nugeenesis 9.1 or 9.2.  Flag errors only if schemaver 910 remains after a 9.2 upgrade.
-- MMorrison    48		2022-02-14	Check for ngprojmgr in ngusers and ngusersauthmode.
-- MMorrison	49		2022-03-15	Dont check the GETINSTRUMENTS job name when verifying the schema changes in DRG0537.wts.  The job name was changed from the pre-release to the released builds. display the job name for GEINSTRUMENTS and CHECKFITFORUSE jobs.
-- MMorrison	50		2022-04-28	Support LMS 1.0.0.1 / 9.2 Hotfix 1
-- MMorrison	51		2022-07-21	Support for NuGenesis 9.3
-- MMorrison	52		2022-07-28	Fixed a bug in the elnprod tables verification.  For 0543DRG.wts, check the defaultreportref, not the report ref because the update script uloads the new template to the default report ref, not report ref.
-- MMorrison	53		2022-10-07	Display error messages if the schemas report as version 8.  Set the LMS schema ver as num to 0 if the LMS schema version is not known.
-- MMorrison	54		2022-10-26	Prevent ORA00942 errors on inv_instrument_hub in the 9.2 HF1 updates verification when running on prior versions of the schema. Set correct no. of views, functions, procedures expected for elnprod; correct no. of PK constraints and obj privs for ngsdms60 and ngproxy; for NG 9.3.
-- MMorrison	55		2023-10-03	Support for NuGenesis 9.3.1. Show the supported NG versions in the script header.
-- MMorrison	56		2023-10-30	Correct the elnprod table list for NG 9.3.1.  Check dba_ind_partititions for index state and logging in case of partitioned indexes.
-------------------------------------------------------------------------------------------------------------------------------
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
COLUMN value 			FORMAT a20

ALTER SESSION SET NLS_DATE_FORMAT = "MM/DD/YYYY";
SELECT 'NuGenesis9_SchemaVerify_r56_'||to_char(sysdate,'yyyy-mm-dd_hh24-mi-ss')||'.log' "file" FROM DUAL;
SPOOL &file 
SET define OFF
VARIABLE	v_ConnTableCount	NUMBER;
VARIABLE	v_SlimSchemaPresent	NUMBER;
VARIABLE	v_WDMSchemaPresent	NUMBER;
VARIABLE	v_WSMSchemaPresent	NUMBER;
VARIABLE	v_SAPTableCount		NUMBER;
VARIABLE	v_Partitioning		NUMBER;
VARIABLE	v_LMSSchemaVerAsNum	NUMBER;
VARIABLE	v_LMSSchemaVer		CHAR(10);
VARIABLE	V_OracleVer		CHAR(64);
VARIABLE	v_SDMSSchemaVer		CHAR(10);
VARIABLE	v_BlobConv_Offset	NUMBER;
VARIABLE	v_BlobConv_CSID	NUMBER;
VARIABLE	v_BlobConv_Lang	NUMBER;
VARIABLE	v_BlobConv_Warning	NUMBER;

SELECT	TO_CHAR(sysdate,'YYYY-MM-DD HH24:MI:SS') today FROM sys.dual;

prompt           *******************************************************
prompt           * NuGenesis 9 schema verification script, revision 56 *
prompt           *         For NuGenesis versions 9.0 - 9.3.1          *
prompt           *******************************************************
prompt
prompt		  THIS SCRIPT MUST BE EXECUTED WITH DBA PRIVILEGES in the SDMS CONTAINER!
PROMPT
SELECT SYS_CONTEXT('USERENV','CURRENT_USER') "CurrentUsername" FROM dual;
PROMPT
PROMPT ___________________________________________________________________________________________________________
PROMPT Oracle database and instance version info
PROMPT

COLUMN BANNER FORMAT A85 HEADING "VERSION"
SELECT BANNER FROM V$VERSION;

COLUMN HOST_NAME FORMAT A35
SELECT INSTANCE_NAME, HOST_NAME, STATUS, ARCHIVER, DATABASE_STATUS FROM V$INSTANCE;

COLUMN DBID HEADING "DATABASE ID"
COLUMN PLATFORM_NAME FORMAT A35 HEADING "OS"
COLUMN PLATFORM_ID HEADING "OS ID"
COLUMN CDB FORMAT A20 HEADING "CONTAINER DB"
SELECT CDB, CON_ID, OPEN_MODE, CON_DBID, DBID, PLATFORM_NAME, PLATFORM_ID FROM V$DATABASE;

PROMPT
PROMPT ___________________________________________________________________________________________________________
PROMPT SDMS and LMS schema version info
PROMPT

BEGIN
	:v_BlobConv_Offset := 1; -- Initialize variables for the BLOB-to-CLOB conversion function.
	:v_BlobConv_CSID := DBMS_LOB.DEFAULT_CSID;
	:v_BlobConv_Lang := DBMS_LOB.DEFAULT_LANG_CTX;
END;
/

-- Use separate PLSQL blocks for each product schema, in case one of them cannot be queried, so that the script can gather as much info about the schemas as possible.
BEGIN
	SELECT NGKEYVALUE INTO :V_SDMSSchemaVer FROM NGSYSUSER.NGCONFIG WHERE NGKEYID = 'BUILDNUMBER';
	DBMS_OUTPUT.PUT_LINE('SDMS schema version: '||:V_SDMSSchemaVer);

	IF (:V_SDMSSchemaVer LIKE 'NG80%')	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: the SDMS schema reports as version 8!  In a NuGenesis 9 database this version should be at least 9.0!');
	END IF;
END;
/

DECLARE
v_LMSSchemaDate		VARCHAR2(8000 CHAR);
v_valcodedesc		VARCHAR2(8000 CHAR);

BEGIN
	-- Get and translate the LMS schema version to a number using a table of known versions.  Using a number allows us to tailor the script expectations for the schema objects to the version installed.
	SELECT TRIM(longalphavalue), VALUECODEDESCRIPTION, ALPHAVALUE INTO  :v_LMSSchemaVer, v_valcodedesc, v_LMSSchemaDate FROM ELNPROD.SYSTEMVALUES WHERE SYSTEMTYPEID = 'DRG_SYSTEM' AND VALUECODE = 'DB_BUILDINFO';
	DBMS_OUTPUT.PUT_LINE('LMS schema version : '||:v_LMSSchemaVer||' / '||v_LMSSchemaDate|| ' / '||v_valcodedesc);
	IF	(:v_LMSSchemaVer LIKE '8.0%')		THEN
		:v_LMSSchemaVerAsNum := 8000;
		DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: the Elnprod schema reports as version 8!  In a NuGenesis 9 database this version should be at least 9.0!  Please upgrade the schema to NG9 to be compatible with this script.');
	ELSIF	(:v_LMSSchemaVer LIKE '9.0 %')		THEN	:v_LMSSchemaVerAsNum := 9000;
	ELSIF	(:v_LMSSchemaVer LIKE '9.0.1%')		THEN	:v_LMSSchemaVerAsNum := 9010;
	ELSIF	(:v_LMSSchemaVer LIKE '9.0.2%')		THEN	:v_LMSSchemaVerAsNum := 9020;
	ELSIF	(:v_LMSSchemaVer LIKE '9.1%')		THEN	
		IF (:v_LMSSchemaVer LIKE '%HF2%')	THEN	:v_LMSSchemaVerAsNum := 9102;
		ELSE						:v_LMSSchemaVerAsNum := 9100;
		END IF;
	ELSIF	(:v_LMSSchemaVer LIKE '9.2%')		THEN	
		IF (:v_LMSSchemaVer LIKE '%HF1%')	THEN	:v_LMSSchemaVerAsNum := 9201;
		ELSE						:v_LMSSchemaVerAsNum := 9200;
		END IF;
	ELSIF (:v_LMSSchemaVer LIKE '9.3%')		THEN
		IF (:V_SDMSSchemaVer = 'NG930')		THEN	:v_LMSSchemaVerAsNum := 9300;
		ELSIF (:V_SDMSSchemaVer = 'NG931')	THEN	:v_LMSSchemaVerAsNum := 9310; -- Check the SDMS schema version for v9.3.1 as the elnprod schema is not updated in this release.
		END IF;
	ELSE
		DBMS_OUTPUT.PUT_LINE('!!! WARNING: unknown schema version.  This script cannot verify the NuGenesis schemas for unknown versions of NuGenesis (or versions prior to 9.0).');
		:v_LMSSchemaVerAsNum := 0; -- Unknown version, so set this to 0, rather than trying to tease out digits from the schema version string.
	END IF;
	DBMS_OUTPUT.PUT_LINE('-- NuGenesis schema version as number: '||:v_LMSSchemaVerAsNum);
END;
/

DECLARE
v_rel			VARCHAR2(64);
v_SQLQuery		VARCHAR2(4000);

BEGIN
	SELECT SUBSTR(VERSION, 1, 4) INTO v_rel FROM PRODUCT_COMPONENT_VERSION WHERE PRODUCT LIKE 'Oracle%';
	DBMS_OUTPUT.PUT_LINE('.');

	DBMS_OUTPUT.PUT_LINE('Determining whether the optional NuGenesis modules are present in this database...');
	SELECT COUNT(TABLE_NAME) INTO :v_ConnTableCount FROM DBA_TABLES WHERE OWNER = 'ELNPROD'	AND TABLE_NAME LIKE 'CONNECTORS_%';
	IF (:v_ConnTableCount > 0)	THEN		DBMS_OUTPUT.PUT_LINE('-- The NuGenesis Connectors are installed in this PDB.  Verification of the Connectors schema will be handled later in this script.');
	ELSE						DBMS_OUTPUT.PUT_LINE('-- The NuGenesis Connectors are NOT installed in this PDB.');
	END IF;

	SELECT COUNT(*) INTO :v_SlimSchemaPresent FROM dba_users WHERE username = 'SLIM';
	IF (:v_SlimSchemaPresent = 1)	THEN		DBMS_OUTPUT.PUT_LINE('-- The NuGenesis Stability module is installed in this PDB.  Verification of the Stability schema is in a separate script.');
	ELSE						DBMS_OUTPUT.PUT_LINE('-- The NuGenesis Stability module is NOT installed in this PDB.');
	END IF;

	SELECT COUNT(*) INTO :v_WDMSchemaPresent FROM dba_users WHERE username = 'WATERS';
	IF (:v_WDMSchemaPresent = 1)	THEN		DBMS_OUTPUT.PUT_LINE('-- The Waters Database Manager is installed in this PDB.  Verification of the WDM schema is in a separate script.');
	ELSE						DBMS_OUTPUT.PUT_LINE('-- The Waters Database Manager is NOT installed in this PDB.');
	END IF;

	SELECT COUNT(*) INTO :v_SAPTableCount FROM dba_tables WHERE owner = 'ELNPROD' AND table_name LIKE 'IF_%';
	IF (:v_SAPTableCount > 0)	THEN		DBMS_OUTPUT.PUT_LINE('-- The LMS-SAP Interface is installed in this PDB.  Verification of the SAP Interface schema will be handled later in this script.');
	ELSE						DBMS_OUTPUT.PUT_LINE('-- The LMS-SAP Interface is NOT installed in this PDB.');
	END IF;

	SELECT COUNT(*) INTO :v_WSMSchemaPresent FROM dba_users WHERE username = 'WATERSMON';
	IF (:v_WSMSchemaPresent = 1)	THEN		DBMS_OUTPUT.PUT_LINE('-- The Waters System Monitor is installed in this PDB.  Verification of the WSM schema is in a separate script.');
	ELSE						DBMS_OUTPUT.PUT_LINE('-- The Waters System Monitor is NOT installed in this PDB.');
	END IF;

	DBMS_OUTPUT.PUT_LINE('.');

	-- Oracle 19c hides the full version number in the version_full column rather than in the version column. Use an execute statement here so that this check doesn't fail on Oracle 12 systems.
	v_SQLQuery := 'SELECT version_full FROM PRODUCT_COMPONENT_VERSION WHERE PRODUCT LIKE ''Oracle%'' ';
	IF (v_rel LIKE'19.0%')	THEN	EXECUTE IMMEDIATE v_SqlQuery INTO v_rel;
	END IF;

	:V_OracleVer := v_rel;
	DBMS_OUTPUT.PUT_LINE('Oracle Database version: '||v_rel);
	DBMS_OUTPUT.PUT_LINE('.');
	
	IF	(:v_LMSSchemaVerAsNum >= 9000 AND :v_LMSSchemaVerAsNum <9100)	THEN
		IF	(v_rel LIKE '12.2%' OR v_rel LIKE '19.6%')	THEN	DBMS_OUTPUT.PUT_LINE('This is an Oracle '||v_rel||' database.  This is a tested and certified version of Oracle Database for NuGenesis 9.0.');
		ELSE								DBMS_OUTPUT.PUT_LINE('!!! WARNING: NuGenesis 9.0 has not been tested or certified on version '||v_rel||'!');
		END IF;
	ELSIF	(:v_LMSSchemaVerAsNum >= 9100)	THEN
		IF	(v_rel LIKE '19.%')	THEN				DBMS_OUTPUT.PUT_LINE('This is an Oracle '||v_rel||' database.  This is an approved version of Oracle Database for NuGenesis 9.1 / 9.2 / 9.3.');
		ELSE								DBMS_OUTPUT.PUT_LINE('!!! WARNING: NuGenesis 9.1 / 9.2 have not been tested or certified on version '||v_rel||'!');
		END IF;
	END IF;
END;
/

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
	IF (v_Count = 1)	THEN
		:v_Partitioning := 1; -- We'll use the result of this check later in the script when we verify the number of SDMS tablespaces in the database.
		DBMS_OUTPUT.PUT_LINE('The Partitioning option is enabled in this instance');
	ELSIF (v_Count = 0)	THEN
		:v_Partitioning := 0;
		DBMS_OUTPUT.PUT_LINE('The Partitioning option is NOT enabled in this instance');
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
	IF (v_ParamValue = 'PREFERRED')		THEN	DBMS_OUTPUT.PUT_LINE('db_securefile='||v_ParamValue||' in this database.  NuGenesis 9 expects db_securefile to be set to "PREFERRED".');
	ELSE						DBMS_OUTPUT.PUT_LINE('!!! WARNING: db_securefile='||v_ParamValue||' in this database.  NuGenesis 9 expects db_securefile to be set to "PREFERRED".');
	END IF;

	DBMS_OUTPUT.PUT_LINE('.');

	SELECT value INTO v_ParamValue FROM v$parameter WHERE name = 'db_block_size';
	IF v_ParamValue < 8192			THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: db_lock size='||v_ParamValue||' in this database!  NuGenesis expects a block size of at least 8192.');
	ELSE						DBMS_OUTPUT.PUT_LINE('db_block size='||v_ParamValue||' in this database.  No action is necessary.');
	END IF;

	DBMS_OUTPUT.PUT_LINE('.');

	SELECT value INTO v_ParamValue FROM v$parameter WHERE name = 'sec_case_sensitive_logon';
	IF 	(v_ParamValue = 'FALSE')	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: sec_case_sensitive_logon='||v_ParamValue||' in this database!  NuGenesis 9 expects sec_case_sensitive_logon=TRUE!');
	ELSIF	(v_ParamValue = 'TRUE')		THEN	DBMS_OUTPUT.PUT_LINE('sec_case_sensitive_logon='||v_ParamValue||' in this database.  This is the expected setting for NuGenesis 9.');
	ELSE						DBMS_OUTPUT.PUT_LINE('Unknown value for sec_case_sensitive_logon='||v_ParamValue);
	END IF;

	DBMS_OUTPUT.PUT_LINE('.');

	SELECT TO_NUMBER(VALUE) INTO v_val FROM V$PARAMETER WHERE NAME = 'job_queue_processes';
	IF (v_val >= 1000)			THEN	DBMS_OUTPUT.PUT_LINE('job_queue_processes='||v_val||' in this database.  No action is necessary.');
	ELSE						DBMS_OUTPUT.PUT_LINE('!!! WARNING: job_queue_processes='||v_val||' in this database!  This must be set to at least 1000 for NuGenesis databases.');
	END IF;

	DBMS_OUTPUT.PUT_LINE('.');

	SELECT VALUE INTO v_ParamValue FROM NLS_DATABASE_PARAMETERS WHERE PARAMETER = 'NLS_CHARACTERSET';
	IF v_Paramvalue = 'AL32UTF8'		THEN	DBMS_OUTPUT.PUT_LINE ('nls_characterset='||v_ParamValue||' in this database. This is the correct characterset for NuGenesis.');
	ELSIF v_Paramvalue != 'AL32UTF8'	THEN	DBMS_OUTPUT.PUT_LINE ('!!!!! ERROR: INCOMPATIBLE NLS_CHARACTERSET! THE NLS_CHARACTERSET FOR THIS DATABASE IS: '||v_Paramvalue||'! NuGenesis 9 REQUIRES THE AL32UTF8 CHARACTERSET');
	END IF;
END;
/

PROMPT
PROMPT List of the database configuration parameters:
SELECT name, value FROM v$parameter WHERE name IN ('cpu_count','shared_pool_size','db_cache_size','db_block_size','db_file_multiblock_read_count','parallel_automatic_tuning','text_enable','optimizer_percent_parallel','sql_version','optimizer_mode','open_cursors','db_name','sort_area_size','sort_area_retained_size','instance_name','db_files');

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
	END IF;
END;
/

PROMPT
PROMPT ______________________________________________________________________________________
PROMPT Checking the database timezone information
PROMPT
DECLARE
v_Count			PLS_INTEGER := 0;
v_TZVersion		NUMBER;
v_ExpectedNo		NUMBER := 31.0;
BEGIN
	SELECT version INTO v_TZVersion FROM v$timezone_file;
	DBMS_OUTPUT.PUT_LINE('Installed time zone data version: '||v_TZVersion);
	IF (v_TZVersion < v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('!!! WARNING: the time zone data installed in this instance is less than v31.  This may cause ORA-30091 errors when importing dump files with "timestamp with time zone" columns, such as for the NuGenesis Stability module.');
	END IF;
END;
/
-- DBREIDING, IF DBA HAS LOGGED INTO THE XDB$ROOT OR A CONTAINER WHICH DOES NOT HAVE THE NUGENESIS SCHEMA, 
-- CHANGE TO THE CONTAINER CONTAINING THE SDMS SCHEMA IF THERE IS ONLY ONE CONTAINER WITH NUGENESIS SCHEMA.

PROMPT
PROMPT ______________________________________________________________________________________
PROMPT Determining whether this script is running in a containerized database...
PROMPT
DECLARE
v_cnt		PLS_INTEGER;
v_cnt1		PLS_INTEGER;
v_Count		PLS_INTEGER;
v_cdb		VARCHAR2(3);
v_conid		NUMBER;
v_conid1	NUMBER;
v_conname	VARCHAR2(128);

BEGIN
	SELECT cdb INTO v_cdb FROM V$DATABASE;
	IF v_cdb = 'YES' THEN
		DBMS_OUTPUT.PUT_LINE('CDB=Yes, this is a containerized database.');

		SELECT COUNT(USERNAME) INTO v_cnt FROM DBA_USERS WHERE USERNAME = 'NGSDMS60';
		-- DETERMINE IF CONNECTED TO CDB$ROOT
		SELECT COUNT(CON_ID) INTO v_cnt1 FROM V$PDBS;
		IF v_cnt = 0 OR v_cnt1 > 0 THEN
			-- DETERMINE IF MORE THAN ON PDB CONTAINS NUGENESIS SCHEMA
			SELECT COUNT(CON_ID) INTO v_Count FROM CDB_USERS WHERE USERNAME IN ('NGSDMS60');
			-- IF MORE THAN ONE CONTAINER WITH NUGENESIS, INFORM USER.
			IF (v_Count > 1)	THEN	DBMS_OUTPUT.PUT_LINE('You have logged into cdb$root using sqlplus.  For this script to execute correctly, you must login to one of the containers in which the NuGenesis 9 schema has been created.  The nugenesis schema has been created in: '||v_Count ||' containters');
			ELSIF (v_Count = 1)	THEN
				SELECT con_id INTO v_conid1 FROM cdb_users WHERE username IN ('NGSDMS60');
				SELECT name INTO v_ConName FROM v$PDBs WHERE con_id = v_ConID1;
				DBMS_OUTPUT.PUT_LINE('The NuGenesis schema is in container ID: '||v_conid1||'	name: '||v_ConName);
			ELSIF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('This is a container database, but the NuGenesis 9 Schema is not present in any CDB.');
			END IF;
		END IF;
	ELSIF v_cdb = 'NO'	THEN	DBMS_OUTPUT.PUT_LINE('This is not a containerized database.');
	ELSE				DBMS_OUTPUT.PUT_LINE('Unknown value for the CDB property in v$database: '||v_cdb);
	END IF;
END;
/

PROMPT
SELECT SYS_CONTEXT('USERENV','CON_ID') "CurrentContainerID", SYS_CONTEXT('USERENV','CON_NAME') "CurrentContainerName" FROM dual;

PROMPT
PROMPT ______________________________________________________________________________________
PROMPT Checking whether the NuGenesis schema accounts have the correct privileges for the Waters licensing process
PROMPT
DECLARE
v_Count		PLS_INTEGER := 0;

BEGIN
	SELECT COUNT(PRIVILEGE) INTO v_Count FROM DBA_TAB_PRIVS WHERE GRANTEE = 'NGSDMS70PROXYROLE' AND TABLE_NAME = 'V_$DATABASE' AND PRIVILEGE = 'SELECT';
	IF v_Count > 0 THEN	DBMS_OUTPUT.PUT_LINE('NGSDMS70PROXYROLE HAS BEEN GRANTED SELECT ON V_$DATABASE');
	ELSIF v_Count = 0 THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: ngsdms70proxyrole has not been granted select on v_$database!  This privilege is absolutely required by the licensing process!  You will not be able to add SDMS licenses until this privilege is granted!');
	END IF;

	SELECT COUNT(PRIVILEGE) INTO v_Count FROM DBA_TAB_PRIVS WHERE GRANTEE = 'ELNPROD' AND TABLE_NAME = 'V_$DATABASE' AND PRIVILEGE = 'SELECT';
	IF v_Count > 0 THEN	DBMS_OUTPUT.PUT_LINE('ELNPROD HAS BEEN GRANTED SELECT ON V_$DATABASE');
	ELSIF v_Count = 0 THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: Elnprod has not been granted select on v_$database!  This privilege is absolutely required by the licensing process!  You will not be able to add LMS licenses until this privilege is granted!');
	END IF;
END;
/

PROMPT
PROMPT ***************************************************************************************************************************************
PROMPT Verifying the NuGenesis schema accounts...
PROMPT ***************************************************************************************************************************************
PROMPT

PROMPT
PROMPT
PROMPT ___________________________________________________________________________________________________________
PROMPT Check for the NuGenesis 9 schema accounts
PROMPT
DECLARE
v_Count			PLS_INTEGER := 0;
v_ExpectedNo		PLS_INTEGER;
v_AcctProfile		dba_users.profile%TYPE;
v_AcctStatus		dba_users.account_status%TYPE;
v_AcctName		dba_users.username%TYPE;
v_AcctPwdTime		dba_profiles.limit%TYPE;
v_AcctDefTbs		dba_users.default_tablespace%TYPE;

TYPE ObjList		IS TABLE OF VARCHAR2(500);
t_SchemaAccounts	ObjList;
t_AccountStatuses	ObjList;
t_AccountProfiles	ObjList;
t_AccountDefTbs		ObjList;

BEGIN
	t_SchemaAccounts  := ObjList('NGSYSUSER',       'NGSTATICUSER','NGPROXY',    'NGSDMS60',        'NGPROJMGR',  'ELNPROD',    'SPSV');
	t_AccountStatuses := ObjList('EXPIRED & LOCKED','OPEN',        'OPEN',       'EXPIRED & LOCKED','OPEN',       'OPEN',       'OPEN');
	t_AccountProfiles := ObjList('NGPROFILE',       'SDMSPROFILE', 'SDMSPROFILE','NGPROFILE',       'NGPROFILE',  'SDMSPROFILE','SDMSPROFILE');
	t_AccountDefTbs   := ObjList('SYSUSERDATA',     'SDMS80DATA',  'SDMS80DATA', 'SDMS80DATA',      'SDMS80DATA', 'QDISR_DATA', 'QDISR_DATA');
	v_ExpectedNo      := t_SchemaAccounts.COUNT;

	SELECT COUNT(*) INTO v_Count FROM dba_users WHERE username IN ('NGSYSUSER','NGSTATICUSER','NGPROXY','NGSDMS60','NGPROJMGR','ELNPROD','SPSV');
	IF (v_Count < v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: fewer than the expected number of NuGenesis 9 accounts are present in this DB instance ('||v_ExpectedNo||' expected, '||v_Count||' found)!');
	ELSIF (v_Count = v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('The expected number of NuGenesis 9 accounts are present in this DB instance ('||v_ExpectedNo||' expected, '||v_Count||' found).');
	ELSIF (v_Count > v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('!!! WARNING: more than expected number of NuGenesis 9 accounts are present in this DB instance ('||v_ExpectedNo||' expected, '||v_Count||' found)!');
	END IF;

	FOR indx IN 1 .. t_SchemaAccounts.COUNT
	LOOP
		v_AcctName := t_SchemaAccounts(indx);
		SELECT COUNT(*) INTO v_Count FROM dba_users WHERE username = v_AcctName;
		IF (v_Count = 1) 	THEN
			DBMS_OUTPUT.PUT_LINE('The '||v_AcctName||' account has been created.');
			SELECT account_status, profile, default_tablespace INTO v_AcctStatus, v_AcctProfile, v_AcctDefTbs FROM dba_users WHERE username = v_AcctName;

			IF	(v_AcctStatus = t_AccountStatuses(indx))	THEN	DBMS_OUTPUT.PUT_LINE('-- status: '||v_AcctStatus||' (expected: '||t_AccountStatuses(indx)||')');
			ELSE								DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: status: '||v_AcctStatus||' (expected: '||t_AccountStatuses(indx)||')!');
			END IF;

			IF	(v_AcctProfile IN('NGPROFILE','SDMSPROFILE'))	THEN	DBMS_OUTPUT.PUT_LINE('-- profile: '||v_AcctProfile||' (expected: NGPROFILE or SDMSPROFILE)');
			ELSE								DBMS_OUTPUT.PUT_LINE('-- !!! WARNING: profile: '||v_AcctProfile||' (expected: NGPROFILE or SDMSPROFILE)!');
			END IF;

			IF	(v_AcctDefTbs = t_AccountDefTbs(indx))		THEN	DBMS_OUTPUT.PUT_LINE('-- default tablespace: '||v_AcctDefTbs||' (expected: '||t_AccountDefTbs(indx)||')');
			ELSE								DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: default tablespace: '||v_AcctDefTbs||' (expected: '||t_AccountDefTbs(indx)||')!');
			END IF;
		ELSIF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: the '||v_AcctName||' account has not been created!');
		END IF;

		DBMS_OUTPUT.PUT_LINE ('.');
	END LOOP;
END;
/

SELECT username, created, default_tablespace, temporary_tablespace, profile FROM dba_users WHERE username IN ('NGSYSUSER', 'NGSTATICUSER', 'NGPROXY', 'NGSDMS60', 'NGPROJMGR', 'ELNPROD', 'SPSV'); 

PROMPT
PROMPT
PROMPT ___________________________________________________________________________________________________________
PROMPT Check for the expected Oracle user profiles
PROMPT
DECLARE
v_Count			PLS_INTEGER := 0;

TYPE ObjList		IS TABLE OF VARCHAR2(500);
t_AccountProfiles	ObjList;

BEGIN
	IF(:v_SlimSchemaPresent = 1)	THEN	t_AccountProfiles := ObjList('NGPROFILE','SDMSPROFILE','SLIMPROFILE');
	ELSE					t_AccountProfiles := ObjList('NGPROFILE','SDMSPROFILE');
	END IF;

	FOR indx IN 1 .. t_AccountProfiles.COUNT
	LOOP
		SELECT COUNT(*) INTO v_Count FROM dba_profiles WHERE profile = t_AccountProfiles(indx);
		IF (v_Count > 0)	THEN	DBMS_OUTPUT.PUT_LINE(t_AccountProfiles(indx) || ' is present');
		ELSE				DBMS_OUTPUT.PUT_LINE('!!! WARNING: ' || t_AccountProfiles(indx) || ' is NOT present');
		END IF;
	END LOOP;
END;
/

PROMPT
PROMPT _________________________________________________________________________________________________
PROMPT Determining whether the expected tablespaces and quotas are present for the NuGenesis schemas
PROMPT

DECLARE
v_Count		NUMBER;
v_SchemaName	VARCHAR2(100);
v_ExpectedNo	PLS_INTEGER;
v_TblspcName	VARCHAR2(500);
v_TblspcQuota	NUMBER;
TYPE ObjList	IS TABLE OF VARCHAR2(500);
TYPE NumList	IS TABLE OF NUMBER;
t_SchemaList	ObjList;
t_TblspcList	ObjList;
t_QuotaList	NumList;

CURSOR C_SDMS80DATA_Tblspcs IS	SELECT tablespace_name FROM dba_tablespaces WHERE tablespace_name LIKE 'SDMS80DATA%';

BEGIN
	t_TblspcList := ObjList('QDISR_DATA','QDISR_LOBS','SDMS80IDX','SDMS80LOBDATA','SYSUSERDATA','SYSUSERIDX');

	-- Use special handling for the SDMS80DATA tablespaces because there may be 1 or over 100 such tablespaces.  Both configurations are valid for NuGenesis.  Check for partitioned tables owned by NGSDMS60
	-- and report the results of that check, to aid in troubleshooting the problems that will inevitably occur in non-standard configurations.  0 partition tables means that there should be 1 SDMS80DATA tablespace;
	-- otherwise, there should be over 100 tablespaces, named SDMS80DATA_Pxx, to match the partition name.  The number of tablespaces is not fixed; there may be more needed if a customer implements many projects in SDMS.
	-- The partitioning strategy in SDMS is a hash partition of ngtags, ngcontentmaster, and ngcontentdetails by project GUID.
	-- 1 tablespace is expected if the "No Partitioning" installation process was used.  This process is often used for customers who purchase an Oracle DB license sans the Partitioning option; however, nothing prevents
	-- the execution of the NoPartitioning process on a DB with the Partitioning option.  Therefore, using the presence of that option is not a good check in this script.
	DBMS_OUTPUT.PUT_LINE('Checking for partitioned tables owned by NGSDMS60:');
	SELECT COUNT(*) INTO v_Count FROM dba_tables WHERE owner = 'NGSDMS60' AND partitioned = 'YES';
	IF (v_Count = 0)	THEN
		DBMS_OUTPUT.PUT_LINE('-- 0 partitioned tables are owned by NGSDMS60; therefore expecting SDMS80DATA tablespace to be non-partitioned and setting the expected number to 1');
		v_ExpectedNo := 1;
	ELSIF (v_Count > 0)	THEN
		DBMS_OUTPUT.PUT_LINE('-- '||v_Count||' partitioned table(s) are owned by NGSDMS60; therefore expecting SDMS80DATA tablespace to be partitioned and setting the expected minimum number to 100.');
		v_ExpectedNo := 100;
	END IF;

	DBMS_OUTPUT.PUT_LINE('.');
	DBMS_OUTPUT.PUT_LINE ('Checking the SDMS80DATA tablespaces:');
	SELECT COUNT(*) INTO v_Count FROM dba_tablespaces WHERE tablespace_name LIKE 'SDMS80DATA%';
	IF (v_Count >= v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE ('-- The expected number of SDMS80DATA tablespaces was found (at least '||v_ExpectedNo||' expected, '||v_Count||' found)');
	ELSE					DBMS_OUTPUT.PUT_LINE ('-- !!!!! ERROR: less than the expected number of SDMS80DATA tablespaces was found (at least '||v_ExpectedNo||' expected, '||v_Count||' found)!');
	END IF;

	DBMS_OUTPUT.PUT_LINE ('.');
	DBMS_OUTPUT.PUT_LINE ('Checking the quotas on the SDMS80DATA tablespaces; errors, if any, will be listed below (expected: NGSDMS60 with unlimited quota on SDMS80DATA tablespaces)');
	OPEN C_SDMS80DATA_Tblspcs;
	LOOP
		FETCH C_SDMS80DATA_Tblspcs INTO v_TblspcName;
		EXIT WHEN C_SDMS80DATA_Tblspcs%NOTFOUND;

		SELECT COUNT(*) INTO v_Count FROM dba_ts_quotas WHERE username = 'NGSDMS60' AND tablespace_name = v_TblspcName;
		IF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE ('-- !!!!! ERROR: NGSDMS60 does not have a quota on tablespace '||v_TblspcName||'!');
		ELSIF (v_Count = 1)	THEN
			SELECT max_bytes INTO v_TblspcQuota FROM dba_ts_quotas WHERE username = 'NGSDMS60' AND tablespace_name = v_TblspcName;
			IF (v_TblspcQuota != -1)	THEN	DBMS_OUTPUT.PUT_LINE ('-- !!!!! ERROR: NGSDMS60 does not have the expected quota quota on tablespace '||v_TblspcName||' (expected: -1, '||v_TblspcQuota||' found)!');	END IF;
		END IF;
	END LOOP;
	CLOSE C_SDMS80DATA_Tblspcs;

	DBMS_OUTPUT.PUT_LINE ('.');
	DBMS_OUTPUT.PUT_LINE ('Checking the non-partitioned NuGenesis tablespaces by name:');
	FOR indx IN 1 .. t_TblspcList.COUNT
	LOOP
		v_TblspcName := t_TblspcList(indx);
		IF (v_TblspcName = 'QDISR_DATA')	THEN
			t_SchemaList := ObjList('ELNPROD','SPSV');
			t_QuotaList  := NumList(-1, -1);
		ELSIF (v_TblspcName = 'QDISR_LOBS')	THEN
			t_SchemaList := ObjList('ELNPROD','SPSV');
			t_QuotaList  := NumList(-1, -1);
		ELSIF (v_TblspcName = 'SDMS80IDX')		THEN
			t_SchemaList := ObjList('NGSDMS60');
			t_QuotaList  := NumList(-1);
		ELSIF (v_TblspcName = 'SDMS80LOBDATA')	THEN
			t_SchemaList := ObjList('NGSDMS60');
			t_QuotaList  := NumList(-1);
		ELSIF (v_TblspcName = 'SYSUSERDATA')	THEN
			t_SchemaList := ObjList('NGSYSUSER');
			t_QuotaList  := NumList(-1);
		ELSIF (v_TblspcName = 'SYSUSERIDX')	THEN
			t_SchemaList := ObjList('NGSYSUSER');
			t_QuotaList  := NumList(-1);
		END IF;

		SELECT COUNT(*) INTO v_Count FROM dba_tablespaces WHERE tablespace_name = v_TblspcName;
		IF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE ('!!!!! ERROR: the tablespace '||v_TblspcName||' does not exist!');
		ELSIF (v_Count = 1)	THEN
			DBMS_OUTPUT.PUT_LINE ('The tablespace '||v_TblspcName||' exists.');
		END IF;

		FOR indx2 IN 1 .. t_SchemaList.COUNT
		LOOP
			v_SchemaName  := t_SchemaList(indx2);
			v_TblspcQuota := t_QuotaList(indx2);
			SELECT COUNT(*) INTO v_Count FROM dba_ts_quotas WHERE username = v_SchemaName AND tablespace_name = v_TblspcName AND max_bytes = v_TblspcQuota;
			IF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE ('-- !!!!! ERROR: '||v_SchemaName||' does not have an unlimited quota on '||v_TblspcName||'!');
			ELSIF (v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE ('-- '||v_SchemaName||' has an unlimited quota on '||v_TblspcName);
			END IF;
		END LOOP;
		DBMS_OUTPUT.PUT_LINE ('.');		
	END LOOP;
END;
/

COLUMN USERNAME		FORMAT A17
COLUMN QUOTA		FORMAT A16 
column tablespace_name	format a25
PROMPT
PROMPT NUGENESIS TABLESPACES:
SELECT TABLESPACE_NAME, FILE_NAME, BYTES/1048576 "SIZE MB", AUTOEXTENSIBLE||'       ' "AUTOEXTEND", MAXBYTES/1048576 "MAXSIZE MB", ROUND(INCREMENT_BY/1048576,3) "INCREMENT MB" FROM dba_data_files;

SELECT username, tablespace_name, REPLACE(max_bytes, '-1', 'UNLIMITED') "Quota" FROM dba_ts_quotas WHERE username IN ('NGSDMS60', 'NGSYSUSER', 'ELNPROD', 'SPSV') ORDER BY username;


PROMPT _________________________________________________________________________________________________
PROMPT Determining if the ngproxy account has been correctly configured...
PROMPT

DECLARE 
v_Count		PLS_INTEGER;

BEGIN
	SELECT COUNT(*) INTO v_Count FROM NGSYSUSER.NGPROXYINFO;
	IF (v_Count > 0)	THEN	DBMS_OUTPUT.PUT_LINE ('The ngsysuser.ngproxychange procedure has been successfully executed; connectivity for the ngproxy account has been established.');
	ELSE				DBMS_OUTPUT.PUT_LINE ('!!!!! ERROR: the ngsysuser.ngproxychange procedure was not executed! Connectivity for the ngproxy account has not been established! Users will be unable to login to WebVision');
	END IF;
END;
/

PROMPT
PROMPT ***************************************************************************************************************************************
PROMPT Verifying the NuGenesis schema objects in this database instance...
PROMPT ***************************************************************************************************************************************
PROMPT

PROMPT
PROMPT _________________________________________________________________________________________________
PROMPT Checking the oracle recyclebin for objects owned by the NuGenesis schemas
PROMPT

DECLARE 
v_Count		PLS_INTEGER;

BEGIN
	SELECT COUNT(*) INTO v_Count FROM DBA_RECYCLEBIN WHERE OWNER IN ('NGSDMS60', 'NGSYSUSER', 'ELNPROD', 'SPSV');
	IF v_Count > 0 THEN	DBMS_OUTPUT.PUT_LINE('The NuGenesis schemas own objects in the Oracle recycle bin.  These objects are not required.  Execute the command ''purge dba_recyclebin'' with SYSDBA privileges to remove these objects.');
	ELSE			DBMS_OUTPUT.PUT_LINE('The NuGenesis schemas do not own objects in the Oracle recycle bin.');
	END IF;
END;
/
CLEAR BREAKS

PROMPT
PROMPT _________________________________________________________________________________________________
PROMPT Determining the number of objects owned by the NuGenesis schemas
PROMPT
PROMPT Number of objects owned by the NuGenesis schemas:
SELECT owner, COUNT(*) "ObjCount" FROM dba_objects WHERE owner IN ('NGSYSUSER', 'NGSDMS60', 'ELNPROD', 'SPSV') AND object_name NOT LIKE 'BIN$' GROUP BY owner ORDER BY owner;

PROMPT
PROMPT
PROMPT Number of objects owned by the NuGenesis schemas broken down by object type:
SELECT owner, object_type, COUNT(*) "ObjCount" FROM dba_objects WHERE owner IN ('NGSYSUSER', 'NGSDMS60', 'ELNPROD', 'SPSV') AND object_name NOT LIKE 'BIN$' GROUP BY owner, object_type ORDER BY owner, object_type;

PROMPT
PROMPT
PROMPT _________________________________________________________________________________________________
PROMPT Determining whether the expected tables are present in the NuGenesis schemas...
PROMPT

DECLARE
v_Count		PLS_INTEGER := 0;
v_TableName	SYS.DBA_TABLES.TABLE_NAME%TYPE;
v_ExpectedNo	PLS_INTEGER;
v_SchemaName	VARCHAR2(500);
TYPE ObjList	IS TABLE OF VARCHAR2(10000);
t_TableList	ObjList;
t_TempTableList	ObjList;
t_SchemaList	ObjList;

BEGIN
	t_SchemaList := ObjList('NGSDMS60','NGSYSUSER','ELNPROD');
	FOR ind IN 1 .. t_SchemaList.COUNT
	LOOP
		v_SchemaName := t_SchemaList(ind); -- Select a schema from the list
		IF (v_SchemaName = 'NGSDMS60') THEN -- Load the table variables with lists appropriate for the schema and product version
			IF	(:v_LMSSchemaVerAsNum >= 9000 AND :v_LMSSchemaVerAsNum < 9100)	THEN	
				IF	(:V_OracleVer LIKE '12%')	THEN	t_TableList := ObjList('DR$ADVANCE_SEARCH$I','DR$ADVANCE_SEARCH$K','DR$ADVANCE_SEARCH$N','DR$ADVANCE_SEARCH$R','DR$ADVANCE_SEARCH$U','NGARCHIVEDEVICES','NGCONTENTDETAIL','NGCONTENTMASTER','NGFIELDS','NGFIELDVAL','NGLEGAL_HOLD_ASSIGN','NGLEGAL_HOLD_DEF','NGOBJNUMINFO','NGPOLICY_EVENTS','NGPROJDEFS','NGPROJDEFS_TOPURGE','NGPROJMISCDATA','NGPROJSTORES','NGPROJTPL','NGPROJVIEW','NGPROJVIEWFIELDS','NGPROJVIEWFILTERS','NGRETENTION_POLICY','NGSERVERSTORES','NGTABLES','NGTAGS','NGUSERPREFS','NGVOLUMECLONES','NGVOLUMELIFECYCLE');
				ELSIF	(:V_OracleVer LIKE '19%')	THEN	t_TableList := ObjList('DR$ADVANCE_SEARCH$I','DR$ADVANCE_SEARCH$K','DR$ADVANCE_SEARCH$N','DR$ADVANCE_SEARCH$U','NGARCHIVEDEVICES','NGCONTENTDETAIL','NGCONTENTMASTER','NGFIELDS','NGFIELDVAL','NGLEGAL_HOLD_ASSIGN','NGLEGAL_HOLD_DEF','NGOBJNUMINFO','NGPOLICY_EVENTS','NGPROJDEFS','NGPROJDEFS_TOPURGE','NGPROJMISCDATA','NGPROJSTORES','NGPROJTPL','NGPROJVIEW','NGPROJVIEWFIELDS','NGPROJVIEWFILTERS','NGRETENTION_POLICY','NGSERVERSTORES','NGTABLES','NGTAGS','NGUSERPREFS','NGVOLUMECLONES','NGVOLUMELIFECYCLE');
				ELSE						t_TableList := ObjList('UNSUPPORTED_ORACLE_VERSION');
				END IF;
			ELSIF 	(:v_LMSSchemaVerAsNum >= 9100 AND :v_LMSSchemaVerAsNum < 9300)	THEN	t_TableList := ObjList('DR$ADVANCE_SEARCH$I','DR$ADVANCE_SEARCH$K','DR$ADVANCE_SEARCH$N','DR$ADVANCE_SEARCH$U','NGARCHIVEDEVICES','NGCONTENTDETAIL','NGCONTENTMASTER','NGFIELDS','NGFIELDVAL','NGLEGAL_HOLD_ASSIGN','NGLEGAL_HOLD_DEF','NGOBJNUMINFO','NGPOLICY_EVENTS','NGPROJDEFS','NGPROJDEFS_TOPURGE','NGPROJMISCDATA','NGPROJSTORES','NGPROJTPL','NGPROJVIEW','NGPROJVIEWFIELDS','NGPROJVIEWFILTERS','NGRETENTION_POLICY','NGSERVERSTORES','NGTABLES','NGTAGS','NGUSERPREFS','NGVOLUMECLONES','NGVOLUMELIFECYCLE');
			ELSIF 	(:v_LMSSchemaVerAsNum >= 9300)					THEN	t_TableList := ObjList('DR$ADVANCE_SEARCH$I','DR$ADVANCE_SEARCH$K','DR$ADVANCE_SEARCH$N','DR$ADVANCE_SEARCH$U','NGARCHIVEDEVICES','NGCONTENTDETAIL','NGCONTENTMASTER','NGFIELDS','NGFIELDVAL','NGLEGAL_HOLD_ASSIGN','NGLEGAL_HOLD_DEF','NGOBJNUMINFO','NGPOLICY_EVENTS','NGPROJDEFS','NGPROJDEFS_TOPURGE','NGPROJMISCDATA','NGPROJSTORES','NGPROJTPL','NGPROJVIEW','NGPROJVIEWFIELDS','NGPROJVIEWFILTERS','NGRETENTION_POLICY','NGSERVERSTORES','NGTABLES','NGTAGS','NGUSERPREFS','NGVOLUMECLONES','NGVOLUMELIFECYCLE','NGUSERPREFERENCES');
			END IF;
			t_TempTableList := ObjList();
		ELSIF (v_SchemaName = 'NGSYSUSER') THEN
			t_TempTableList := ObjList('NGTEMPTBL');
			IF	(:v_LMSSchemaVerAsNum >= 9000 AND :v_LMSSchemaVerAsNum < 9100)	THEN	t_TableList := ObjList('NGAPPINFO','NGAUDITCATEGORIES','NGAUDITDETAILS','NGAUDITDETAILSVIEWS','NGAUDITMASTER','NGAUDITMASTERVIEWS','NGAUTHMODESMAP','NGCHECKPOINTS','NGCHECKVALUES','NGCONFIG','NGEMAILALERTS','NGGROUPMEMBERS','NGGROUPS','NGLOCKDETAILS','NGLOCKINFO','NGNOTIFY','NGPRIVILEGE','NGPROXYINFO','NGPWDCHGPROC','NGSCHEMAINSTALLEDINFO','NGSERVERPROJINFO','NGSTRINGLOOKUP','NGTEMPTBL','NGUSERS','NGUSERSAUTHMODE','NGVIEWMETADATA');
			ELSIF 	(:v_LMSSchemaVerAsNum >= 9100)					THEN	t_TableList := ObjList('NGAPPINFO','NGAUDITCATEGORIES','NGAUDITDETAILS','NGAUDITDETAILSVIEWS','NGAUDITMASTER','NGAUDITMASTERVIEWS','NGAUTHMODESMAP','NGCHECKPOINTS','NGCHECKVALUES','NGCONFIG','NGEMAILALERTS','NGGROUPMEMBERS','NGGROUPS','NGLOCKDETAILS','NGLOCKINFO','NGNOTIFY','NGPRIVILEGE','NGPROXYINFO','NGPWDCHGPROC','NGSCHEMAINSTALLEDINFO','NGSERVERPROJINFO','NGSTRINGLOOKUP','NGTEMPTBL','NGUSERS','NGUSERSAUTHMODE','NGVIEWMETADATA','NGUSERREFRESHTOKENS','NGAUDITCATEGORYGROUPS');
			END IF;
		ELSIF (v_SchemaName = 'ELNPROD') THEN -- ELNPROD table list for...
			IF	(:v_LMSSchemaVerAsNum >= 9000 AND :v_LMSSchemaVerAsNum < 9100)	THEN -- NG 9.0.x ...
				IF	(:V_OracleVer LIKE '12%')	THEN -- and Oracle 12
					t_TableList := ObjList('ANALYSENMETHODE','ANALYSENMETHODEA0','ANALYSISMETHODCLASSIFICATION','ANALYSISMETHODCLASSIFICATIONA0','ANALYSISMETHODLABGROUP','ANALYSISMETHODLABGROUPA0','ANALYSISMETHODPARAMETER','ANALYSISMETHODPARAMETERA0','AO_KEYWORDS','AO_KEYWORDSA0','AO_KEYWORDSA0L0','AO_KEYWORDSA0L0A0','AO_KEYWORDSL0','AO_KEYWORDSL0A0','APPENDIX','ARCHIVEREGISTRATION','ARCHIVEREGISTRATIONA0','ARCHIVEREQUESTLOG','ARCHIVEREQUESTLOGA0','ARCHIVEREQUESTORDERS','ARCHIVEREQUESTORDERSA0','ARCHIVETABLES','ARCHIVETABLESA0','ARTIKEL','ARTIKELA0','ATOMS','ATOMSA0','BINARYCOLUMNS','BINARYCOLUMNSA0','BINARYDOCUMENT','BINARYDOCUMENTA0','BINARYOBJECT','BINARYOBJECTA0','BINARY_ORDER','BINARY_ORDERA0','BOND','BONDA0','CHANNEL','CHANNELA0','CODEWORDS','CODEWORDSA0','CONNECTIONCONFIG','CONNECTIONCONFIGA0','CONTAINERVIEWERCONFIGC','CONTAINERVIEWERCONFIGCA0','CONTAINERVIEWERMETHODS','CONTAINERVIEWERMETHODSA0','CONTVIEWERCOLORMETHODS','CONTVIEWERCOLORMETHODSA0','CONVERSIONFILTER','CONVERSIONFILTERA0','CONVERSIONLOG','CONVERSIONLOGA0','CONVERTCOMMENTS','CONVERTCOMMENTSA0','CONVERTSOFTWARE','CONVERTSOFTWAREA0','COSTCENTER','COSTCENTERA0','COSTCENTERTYPES',
					'COSTCENTERTYPESA0','COUNTRY','COUNTRYA0','CUSTOMER','CUSTOMERA0','CUSTOMERCOSTCENTER','CUSTOMERCOSTCENTERA0','CV_COLORRESULTMAPPING','CV_COLORRESULTMAPPINGA0','DATAFIELDS','DATAFIELDSA0','DATAQUEUE','DATAQUEUEA0','DEADLINECODE','DEADLINECODEA0','DOMAIN','DOMAINA0','DOMAINCONSTRAINT','DOMAINCONSTRAINTA0','DOMAINVALUE','DOMAINVALUEA0','DR$CTX_BINARYDOCUMENT$I','DR$CTX_BINARYDOCUMENT$K','DR$CTX_BINARYDOCUMENT$N','DR$CTX_BINARYDOCUMENT$R','DR$CTX_BINARYDOCUMENT$U','DR$TEXT_IDX_EXTERNALPLUGIN$I','DR$TEXT_IDX_EXTERNALPLUGIN$K','DR$TEXT_IDX_EXTERNALPLUGIN$N','DR$TEXT_IDX_EXTERNALPLUGIN$R','DR$TEXT_IDX_EXTERNALPLUGIN$U','DR$TEXT_IDX_LOCATION$I','DR$TEXT_IDX_LOCATION$K','DR$TEXT_IDX_LOCATION$N','DR$TEXT_IDX_LOCATION$R','DR$TEXT_IDX_LOCATION$U','DR$TEXT_IDX_MEASUREORDER$I','DR$TEXT_IDX_MEASUREORDER$K','DR$TEXT_IDX_MEASUREORDER$N','DR$TEXT_IDX_MEASUREORDER$R','DR$TEXT_IDX_MEASUREORDER$U','DR$TEXT_IDX_PHYSICALSAMPLE$I','DR$TEXT_IDX_PHYSICALSAMPLE$K','DR$TEXT_IDX_PHYSICALSAMPLE$N','DR$TEXT_IDX_PHYSICALSAMPLE$R','DR$TEXT_IDX_PHYSICALSAMPLE$U','DR$TEXT_IDX_PRODUCT$I','DR$TEXT_IDX_PRODUCT$K','DR$TEXT_IDX_PRODUCT$N','DR$TEXT_IDX_PRODUCT$R','DR$TEXT_IDX_PRODUCT$U',
					'DR$TEXT_IDX_REPORTCONFIG$I','DR$TEXT_IDX_REPORTCONFIG$K','DR$TEXT_IDX_REPORTCONFIG$N','DR$TEXT_IDX_REPORTCONFIG$R','DR$TEXT_IDX_REPORTCONFIG$U','DR$TEXT_IDX_REPORTCONFIGLIB$I','DR$TEXT_IDX_REPORTCONFIGLIB$K','DR$TEXT_IDX_REPORTCONFIGLIB$N','DR$TEXT_IDX_REPORTCONFIGLIB$R','DR$TEXT_IDX_REPORTCONFIGLIB$U','DR$TEXT_IDX_SAMPLETEMPLATE$I','DR$TEXT_IDX_SAMPLETEMPLATE$K','DR$TEXT_IDX_SAMPLETEMPLATE$N','DR$TEXT_IDX_SAMPLETEMPLATE$R','DR$TEXT_IDX_SAMPLETEMPLATE$U','DR$TEXT_IDX_SMMETHOD$I','DR$TEXT_IDX_SMMETHOD$K','DR$TEXT_IDX_SMMETHOD$N','DR$TEXT_IDX_SMMETHOD$R','DR$TEXT_IDX_SMMETHOD$U','DR$TEXT_IDX_SPECIFICATION$I','DR$TEXT_IDX_SPECIFICATION$K','DR$TEXT_IDX_SPECIFICATION$N','DR$TEXT_IDX_SPECIFICATION$R','DR$TEXT_IDX_SPECIFICATION$U','DR$TEXT_IDX_SUBMISSION$I','DR$TEXT_IDX_SUBMISSION$K','DR$TEXT_IDX_SUBMISSION$N','DR$TEXT_IDX_SUBMISSION$R','DR$TEXT_IDX_SUBMISSION$U','DR$TEXT_IDX_SUBMISSIONTEMPL$I','DR$TEXT_IDX_SUBMISSIONTEMPL$K','DR$TEXT_IDX_SUBMISSIONTEMPL$N','DR$TEXT_IDX_SUBMISSIONTEMPL$R','DR$TEXT_IDX_SUBMISSIONTEMPL$U','DR$TEXT_IDX_TEST$I','DR$TEXT_IDX_TEST$K','DR$TEXT_IDX_TEST$N','DR$TEXT_IDX_TEST$R','DR$TEXT_IDX_TEST$U','DR$TEXT_IDX_TESTDEFINITION$I',
					'DR$TEXT_IDX_TESTDEFINITION$K','DR$TEXT_IDX_TESTDEFINITION$N','DR$TEXT_IDX_TESTDEFINITION$R','DR$TEXT_IDX_TESTDEFINITION$U','DR$TEXT_IDX_TESTREQUEST$I','DR$TEXT_IDX_TESTREQUEST$K','DR$TEXT_IDX_TESTREQUEST$N','DR$TEXT_IDX_TESTREQUEST$R','DR$TEXT_IDX_TESTREQUEST$U','DR$TEXT_IDX_TESTRESULT$I','DR$TEXT_IDX_TESTRESULT$K','DR$TEXT_IDX_TESTRESULT$N','DR$TEXT_IDX_TESTRESULT$R','DR$TEXT_IDX_TESTRESULT$U','DR$TEXT_IDX_UICONFIGURATION$I','DR$TEXT_IDX_UICONFIGURATION$K','DR$TEXT_IDX_UICONFIGURATION$N','DR$TEXT_IDX_UICONFIGURATION$R','DR$TEXT_IDX_UICONFIGURATION$U','DR$TEXT_IDX_USERMESSAGE$I','DR$TEXT_IDX_USERMESSAGE$K','DR$TEXT_IDX_USERMESSAGE$N','DR$TEXT_IDX_USERMESSAGE$R','DR$TEXT_IDX_USERMESSAGE$U','DR$TEXT_IDX_USERS$I','DR$TEXT_IDX_USERS$K','DR$TEXT_IDX_USERS$N','DR$TEXT_IDX_USERS$R','DR$TEXT_IDX_USERS$U','DRG_CALENDAR','DRG_CALENDARA0','DRG_MESSPARAM_GROUPING','DRG_MESSPARAM_GROUPINGA0','DRG_METHGRP','DRG_METHGRPA0','DRG_METHGRPDETAIL','DRG_METHGRPDETAILA0','DRG_METHGRPDETMETA','DRG_METHGRPDETMETAA0','DRG_METHGRPLABGRP','DRG_METHGRPLABGRPA0','DRG_METHGRPLINK','DRG_METHGRPLINKA0','DRG_METHGRPMETA','DRG_METHGRPMETAA0','DRG_METHGRPPARAM','DRG_METHGRPPARAMA0',
					'DRG_METHGRPPARAMVALUE','DRG_METHGRPPARAMVALUEA0','DRG_METHGRPSET','DRG_METHGRPSETA0','DRG_METHGRPSIGN','DRG_METHGRPSIGNA0','DRG_PRINTHISTORY','DRG_PRINTHISTORYA0','DRG_SERVICERESULT','DRG_SERVICERESULTA0','DRG_SERVICERESULTDATA','DRG_SERVICERESULTDATAA0','DRG_SERVICERESULTMETA','DRG_SERVICERESULTMETAA0','ELABMASSIVRRETURN_NEWSTRUCTURE','ELABORDER','ELABORDERANALYSIS','ELABORDERANALYSISA0','ELABORDERSAMPLE','ELABORDERSAMPLEA0','ELAB_COMMAND','ELAB_COMMANDA0','EMPLOYEE','EMPLOYEEA0','EMPLOYEEREPRESENTATIVE','EMPLOYEEREPRESENTATIVEA0','EXPERTSYSTEM','EXPERTSYSTEMA0','EXPERTSYSTEMDATABASE','EXPERTSYSTEMDATABASEA0','EXTERNALPLUGIN','EXTERNALPLUGINA0','FIXTEXTCATALOG','FIXTEXTCATALOGA0','FIXTEXTCATEGORY','FIXTEXTCATEGORYA0','FIXTEXTE','FIXTEXTEA0','FORMAT','FORMATA0','FORMATEXTENSION','FORMATEXTENSIONA0','FORMATVERSION','FORMATVERSIONA0','FORMULATION','FORMULATIONA0','FUNCTACCESS','FUNCTACCESSA0','FUNCTION','FUNCTIONA0','GROUPPROGRAM','GROUPPROGRAMA0','GROUPS','GROUPSA0','INGREDIENT','INGREDIENTA0','INSTHUBATTRIBUTE','INSTHUBATTRIBUTEA0','INSTHUBLOG','INSTHUBLOGA0','INSTHUBREAGENT','INSTHUBREAGENTA0','INSTHUBRESULT','INSTHUBRESULTA0',
					'INSTHUBRESULTATTRIBUTE','INSTHUBRESULTATTRIBUTEA0','INSTHUBRESULTBINARY','INSTHUBRESULTBINARYA0','INSTHUBRESULTTABLEITEM','INSTHUBRESULTTABLEITEMA0','INSTRUMENT','INSTRUMENTA0','INSTRUMENTENCOMPUTER','INSTRUMENTENCOMPUTERA0','INSTRUMENTHUB','INSTRUMENTHUBA0','INSTRUMENTPARAMETER','INSTRUMENTPARAMETERA0','INSTRUMENT_ORDER','INSTRUMENT_ORDERA0','INSTRUMENT_ORDER_INFORMATION','INSTRUMENT_ORDER_INFORMATIONA0','INSTRUMENT_ORDER_MOLFILE','INSTRUMENT_ORDER_MOLFILEA0','INSTRUMENT_ORDER_RETURN','INSTRUMENT_ORDER_RETURNA0','INV_CHEMICAL','INV_CHEMICALA0','INV_CHEMICALCOMPOUND','INV_CHEMICALCOMPOUNDA0','INV_CHEMICALLOG','INV_CHEMICALLOGA0','INV_INSTRUMENT','INV_INSTRUMENTA0','INV_INSTRUMENTLOG','INV_INSTRUMENTLOGA0','JAVACLASS','JAVACLASSA0','JOBMGRCONFIG','JOBMGRCONFIGA0','JOBPARAMS','JOBPARAMSA0','JOBS','JOBSA0','JOBSCHEDULE','JOBSCHEDULEA0','JOBSCHEDULEPARAMS','JOBSCHEDULEPARAMSA0','JOBTYPEPARAMS','JOBTYPEPARAMSA0','JOBTYPES','JOBTYPESA0','KEYWORDS','KEYWORDSA0','LABGROUP','LABGROUPA0','LABGROUPEMPLOYEE','LABGROUPEMPLOYEEA0','LABGROUPLABGROUP','LABGROUPLABGROUPA0','LABGROUPNOTIFICATIONLIST','LABGROUPNOTIFICATIONLISTA0','LABGROUPNOTIFICATIONS',
					'LABGROUPNOTIFICATIONSA0','LANGUAGE','LANGUAGEA0','LICENSE','LICENSEA0','LIMSMAILINFORMATION','LIMSMAILINFORMATIONA0','LIMSSYSTEM','LIMSSYSTEMA0','LIMSSYSTEMINTERFACE','LIMSSYSTEMINTERFACEA0','LOCATION','LOCATIONA0','LONGTIMEARCHIVE','LONGTIMEARCHIVEA0','MAILBOX_COMPONENTRETURN','MAILBOX_COMPONENTRETURNA0','MAILBOX_MEASUREORDER','MAILBOX_MEASUREORDERA0','MAILBOX_METHOD','MAILBOX_METHODA0','MAILBOX_ORDERATTRIBUTES','MAILBOX_ORDERATTRIBUTESA0','MAILBOX_RESULTRETURN','MAILBOX_RESULTRETURNA0','MAILBOX_SAMPLE','MAILBOX_SAMPLEA0','MAILBOX_STRUCTUREATTRIBUTES','MAILBOX_STRUCTUREATTRIBUTESA0','MASSIVRORDERRETURN','MASSIVR_COMMAND','MASSIVR_COMMANDA0','MB_BASIC_DATA','MB_BINARYRESULT','MB_CONNECTOR_COMMAND_QUEUE','MB_LISTS','MB_LIST_COLLECTION','MB_LIST_CONTENT','MB_MAPPING','MB_MAPPING_TEST','MB_MAPPING_TESTRESULT','MB_SCHEDULE','MB_TEST','MB_TESTA0','MB_TESTREQUEST','MB_TESTREQUESTA0','MB_TESTRESULT','MB_TESTRESULTA0','MB_TRANSACTIONRESULT','MB_WHERE_CONFIG','MEASUREORDER','MEASUREORDERA0','MEASUREORDERA0L0','MEASUREORDERA0L0A0','MEASUREORDERL0','MEASUREORDERL0A0','MESSAGE','MESSAGEA0','MESSAGEATTRIBUTE','MESSAGEATTRIBUTEA0','MESSAGES','MESSAGESA0',
					'MESSPARAMETER','MESSPARAMETERA0','METADATA','METADATAA0','METHODE','METHODEA0','METHODEXPERTSYSTEM','METHODEXPERTSYSTEMA0','METHODFILE','METHODFILEA0','METHODGROUP','METHODGROUPA0','METHODGROUPDETAIL','METHODGROUPDETAILA0','METHODLABGROUP','METHODLABGROUPA0','METHODPARTSLIST','METHODPARTSLISTA0','METHODPREPARATION','METHODPREPARATIONA0','METHODRESULTTYPE','METHODRESULTTYPEA0','METHODRESULTTYPECOMPONENT','METHODRESULTTYPECOMPONENTA0','METHODSUMMARY','METHODSUMMARYA0','METHODTOPTENLIST','METHODTOPTENLISTA0','MLOG$_MEASUREORDER','MLOG$_MO_ORDERATTRIBUTES','MLOG$_MO_PARAMETERTAB','MODUL','MODULA0','MOTIVATION','MOTIVATIONA0','MO_ANALYSISMETHODSELECTION','MO_ANALYSISMETHODSELECTIONA0','MO_ANALYSISMETHODSELECTIONA0L0','MO_ANALYSISMETHODSELECTIONL0','MO_ANALYSISMETHODSELECTIONL0A0','MO_AO','MO_AOA0','MO_AOA0L0','MO_AOA0L0A0','MO_AOL0','MO_AOL0A0','MO_CODEWORDS','MO_CODEWORDSA0','MO_CODEWORDSA0L0','MO_CODEWORDSA0L0A0','MO_CODEWORDSL0','MO_CODEWORDSL0A0','MO_COSTS','MO_COSTSA0','MO_COSTSA0L0','MO_COSTSA0L0A0','MO_COSTSL0','MO_COSTSL0A0','MO_INSTRUMENT_PARAMETER','MO_INSTRUMENT_PARAMETERA0','MO_INSTRUMENT_RESULTS','MO_INSTRUMENT_RESULTSA0','MO_INSTRUMENT_RETURNS',
					'MO_INSTRUMENT_RETURNSA0','MO_INSTR_PARAM_RETURN','MO_INSTR_PARAM_RETURNA0','MO_LINK','MO_LINKA0','MO_LO','MO_LOA0','MO_LOA0L0','MO_LOA0L0A0','MO_LOL0','MO_LOL0A0','MO_LO_COSTS','MO_LO_COSTSA0','MO_LO_COSTSA0L0','MO_LO_COSTSA0L0A0','MO_LO_COSTSL0','MO_LO_COSTSL0A0','MO_LO_SAMPLE','MO_LO_SAMPLEA0','MO_LO_SAMPLEA0L0','MO_LO_SAMPLEA0L0A0','MO_LO_SAMPLEL0','MO_LO_SAMPLEL0A0','MO_MEASURESAMPLE','MO_MEASURESAMPLEA0','MO_MEASURESAMPLEA0L0','MO_MEASURESAMPLEA0L0A0','MO_MEASURESAMPLEL0','MO_MEASURESAMPLEL0A0','MO_METADATACONFIG','MO_METADATACONFIGA0','MO_METHOD','MO_METHODA0','MO_METHODA0L0','MO_METHODA0L0A0','MO_METHODL0','MO_METHODL0A0','MO_METHODMODULE','MO_METHODMODULEA0','MO_METHODMODULEA0L0','MO_METHODMODULEA0L0A0','MO_METHODMODULEEXPORT','MO_METHODMODULEEXPORTA0','MO_METHODMODULEEXPORTA0L0','MO_METHODMODULEEXPORTA0L0A0','MO_METHODMODULEEXPORTL0','MO_METHODMODULEEXPORTL0A0','MO_METHODMODULEL0','MO_METHODMODULEL0A0','MO_METHODSTRUCTURE','MO_METHODSTRUCTUREA0','MO_METHODSTRUCTUREA0L0','MO_METHODSTRUCTUREA0L0A0','MO_METHODSTRUCTUREL0','MO_METHODSTRUCTUREL0A0','MO_MOLFILE','MO_MOLFILEA0','MO_ORDERATTRIBUTES','MO_ORDERATTRIBUTESA0','MO_ORDERATTRIBUTESA0L0',
					'MO_ORDERATTRIBUTESA0L0A0','MO_ORDERATTRIBUTESL0','MO_ORDERATTRIBUTESL0A0','MO_ORDERMETHGROUP','MO_ORDERMETHGROUPA0','MO_ORDERMODIFIERS','MO_ORDERMODIFIERSA0','MO_PARAMETER','MO_PARAMETERA0','MO_PARAMETERA0L0','MO_PARAMETERA0L0A0','MO_PARAMETERL0','MO_PARAMETERL0A0','MO_PARAMETERTAB','MO_PARAMETERTABA0','MO_PROJECT','MO_PROJECTA0','MO_PROJECTA0L0','MO_PROJECTA0L0A0','MO_PROJECTL0','MO_PROJECTL0A0','MO_PUBLISHORDER','MO_PUBLISHORDERA0','MO_RDFILE','MO_RDFILEA0','MO_RDFILEA0L0','MO_RDFILEA0L0A0','MO_RDFILEL0','MO_RDFILEL0A0','MO_RDVERSION','MO_RDVERSIONA0','MO_RDVERSIONA0L0','MO_RDVERSIONA0L0A0','MO_RDVERSIONL0','MO_RDVERSIONL0A0','MO_RD_STRUCTURE','MO_RD_STRUCTUREA0','MO_RD_STRUCTUREA0L0','MO_RD_STRUCTUREA0L0A0','MO_RD_STRUCTUREL0','MO_RD_STRUCTUREL0A0','MO_REFERENCES_RESULTS','MO_REFERENCES_RESULTSA0','MO_REFERENCES_RESULTSA0L0','MO_REFERENCES_RESULTSA0L0A0','MO_REFERENCES_RESULTSL0','MO_REFERENCES_RESULTSL0A0','MO_RESULTDETAILSPECTRUM','MO_RESULTDETAILSPECTRUMA0','MO_RESULTDETAILSPECTRUMA0L0','MO_RESULTDETAILSPECTRUMA0L0A0','MO_RESULTDETAILSPECTRUML0','MO_RESULTDETAILSPECTRUML0A0','MO_RESULTEVALUATION','MO_RESULTEVALUATIONA0','MO_RESULTEVALUATIONA0L0',
					'MO_RESULTEVALUATIONA0L0A0','MO_RESULTEVALUATIONL0','MO_RESULTEVALUATIONL0A0','MO_RESULT_3DSPECTRUMDETAIL','MO_RESULT_3DSPECTRUMDETAILA0','MO_RESULT_3DSPECTRUMHEADER','MO_RESULT_3DSPECTRUMHEADERA0','MO_RESULT_BINARY','MO_RESULT_BINARYA0','MO_RESULT_BINARYA0L0','MO_RESULT_BINARYA0L0A0','MO_RESULT_BINARYL0','MO_RESULT_BINARYL0A0','MO_RESULT_CHROMATOGRAM','MO_RESULT_CHROMATOGRAMA0','MO_RESULT_CHROMATOGRAMA0L0','MO_RESULT_CHROMATOGRAMA0L0A0','MO_RESULT_CHROMATOGRAML0','MO_RESULT_CHROMATOGRAML0A0','MO_RESULT_COMPONENT','MO_RESULT_COMPONENTA0','MO_RESULT_COMPONENTA0L0','MO_RESULT_COMPONENTA0L0A0','MO_RESULT_COMPONENTL0','MO_RESULT_COMPONENTL0A0','MO_RESULT_HEADER','MO_RESULT_HEADERA0','MO_RESULT_HEADERA0L0','MO_RESULT_HEADERA0L0A0','MO_RESULT_HEADERL0','MO_RESULT_HEADERL0A0','MO_RESULT_MULTI_DETAIL','MO_RESULT_MULTI_DETAILA0','MO_RESULT_MULTI_DETAILA0L0','MO_RESULT_MULTI_DETAILA0L0A0','MO_RESULT_MULTI_DETAILL0','MO_RESULT_MULTI_DETAILL0A0','MO_RESULT_PEAKINFORMATION','MO_RESULT_PEAKINFORMATIONA0','MO_RESULT_PEAKINFORMATIONA0L0','MO_RESULT_PEAKINFORMATIONL0','MO_RESULT_PEAKINFORMATIONL0A0','MO_RESULT_SPECTRUM','MO_RESULT_SPECTRUMA0','MO_RESULT_SPECTRUMA0L0',
					'MO_RESULT_SPECTRUMA0L0A0','MO_RESULT_SPECTRUML0','MO_RESULT_SPECTRUML0A0','MO_RESULT_TEXT','MO_RESULT_TEXTA0','MO_RESULT_TEXTA0L0','MO_RESULT_TEXTA0L0A0','MO_RESULT_TEXTL0','MO_RESULT_TEXTL0A0','MO_REVIEW','MO_REVIEWA0','MO_SAMPLE','MO_SAMPLEA0','MO_SAMPLEA0L0','MO_SAMPLEA0L0A0','MO_SAMPLEL0','MO_SAMPLEL0A0','MO_SEQUENCEPARAMETER','MO_SEQUENCEPARAMETERA0','MO_SEQUENCEPARAMETERA0L0','MO_SEQUENCEPARAMETERA0L0A0','MO_SEQUENCEPARAMETERL0','MO_SEQUENCEPARAMETERL0A0','MO_SEQUENCETEMPLATE','MO_SEQUENCETEMPLATEA0','MO_SEQUENCETEMPLATEA0L0','MO_SEQUENCETEMPLATEA0L0A0','MO_SEQUENCETEMPLATEL0','MO_SEQUENCETEMPLATEL0A0','MO_SIGN','MO_SIGNA0','MO_STRUCTUREASSIGNMENT','MO_STRUCTUREASSIGNMENTA0','MO_STRUCTUREASSIGNMENTA0L0','MO_STRUCTUREASSIGNMENTA0L0A0','MO_STRUCTUREASSIGNMENTL0','MO_STRUCTUREASSIGNMENTL0A0','MO_STRUCTURE_SPECINFORESULTS','MO_STRUCTURE_SPECINFORESULTSA0','MO_SUBSTANCE','MO_SUBSTANCEA0','MO_SUBSTANCEA0L0','MO_SUBSTANCEA0L0A0','MO_SUBSTANCEL0','MO_SUBSTANCEL0A0','MO_WORKLIST','MO_WORKLISTA0','MO_WORKLISTA0L0','MO_WORKLISTA0L0A0','MO_WORKLISTL0','MO_WORKLISTL0A0','MSGHEADER','MSGHEADERA0','MSGITEM','MSGITEMA0','MSGVALUE','MSGVALUEA0','NOTIFICATION',
					'NOTIFICATIONA0','NOTIFICATIONLIST','NOTIFICATIONLISTA0','OPENORDERS','OPERATINGSYSTEM','OPERATINGSYSTEMA0','ORDERATTRIBUTES','ORDERATTRIBUTESA0','ORDERATTRIBUTESTYPE','ORDERATTRIBUTESTYPEA0','ORDERATTRIBUTES_TEXTINFO','ORDERATTRIBUTES_TEXTINFOA0','ORDERTYPE','ORDERTYPEA0','ORDERTYPEMETHODSASSIGN','ORDERTYPEMETHODSASSIGNA0','ORDERTYPERESULTTYPES','ORDERTYPERESULTTYPESA0','ORDERTYPEWEBMETHODS','ORDERTYPEWEBMETHODSA0','ORDERTYPE_LO','ORDERTYPE_LOA0','PHYSICALSAMPLE','PHYSICALSAMPLEA0','PHYSICALSAMPLETEMP','PREPARATION','PREPARATIONA0','PREPARATIONLABGROUP','PREPARATIONLABGROUPA0','PREPARATIONSTEPS','PREPARATIONSTEPSA0','PRINTER','PRINTERA0','PRODUCT','PRODUCTA0','PRODUCTCATEGORY','PRODUCTCATEGORYA0','PRODUCTTEMP','PROGRAMCONFIGURATION','PROGRAMCONFIGURATIONA0','PROJECT','PROJECTA0','PROJECTTEMPLATE','PROJECTTEMPLATEA0','PROJECTUSER','PROJECTUSERA0','PROJECT_DOCUMENT','PROJECT_DOCUMENTA0','PROJECT_ENTWICKLUNGSPLAN','PROJECT_ENTWICKLUNGSPLANA0','PROJECT_LO','PROJECT_LOA0','PROJECT_RESULT','PROJECT_RESULTA0','PROTECTIONPERIOD','PROTECTIONPERIODA0','PUBLICFILTERS','QDDPROJECT','QDDPROJECTA0','QDISCCNR','QDISRQMINTERFACE','QDISRQMINTERFACEA0','QDISSQL','REFERENCESPECTRA',
					'REFERENCESPECTRAA0','RENDITION','RENDITIONA0','REPORTCOMMENTS','REPORTCOMMENTSA0','REPORTCONFIGLABGROUP','REPORTCONFIGLABGROUPA0','REPORTCONFIGLIBRARY','REPORTCONFIGLIBRARYA0','REPORTCONFIGURATION','REPORTCONFIGURATIONA0','REPORTLABELS','REPORTLABELSA0','REPORTLAYOUT','REPORTLAYOUTA0','REPORTMETHODSVALUES','REPORTMETHODSVALUESA0','REPORTORDERSVALUES','REPORTORDERSVALUESA0','REPORTPARAMETERS','REPORTPARAMETERSA0','REPORTPICTURES','REPORTPICTURESA0','REQUESTSAMPLE','REQUESTSAMPLEA0','RESULTHIERARCHY','RESULTHIERARCHYA0','RESULTREQUIREMENTDEF','RESULTREQUIREMENTDEFA0','RESULTTYPE','RESULTTYPEA0','RESULTUNIT','RESULTUNITA0','RETRIEVERESULTLIST','RETRIEVERESULTLISTA0','SAMPLEATTRIBUTE','SAMPLEATTRIBUTEA0','SAMPLEQUALITY','SAMPLEQUALITYA0','SAMPLETEMPLATE','SAMPLETEMPLATEA0','SAMPLETEMPLATETEMP','SAMPLETEMPLLABGROUP','SAMPLETEMPLLABGROUPA0','SAMPLETEMPLRESREQUIREMENT','SAMPLETEMPLRESREQUIREMENTA0','SAMPLETEMPLSIGN','SAMPLETEMPLSIGNA0','SAMPLETEMPLTEST','SAMPLETEMPLTESTA0','SAMPLETEMPLTESTRESULT','SAMPLETEMPLTESTRESULTA0','SCREENLAYOUTCONFIGURATION','SCREENLAYOUTCONFIGURATIONA0','SCREENPROGRAM','SCREENPROGRAMA0','SEARCHCRITERIA','SEARCHCRITERIAA0','SEQUENCETEMPLATE',
					'SEQUENCETEMPLATEA0','SEQUENCETEMPLATEPARAMETER','SEQUENCETEMPLATEPARAMETERA0','SERVICEPROVIDER','SERVICEPROVIDERA0','SERVICEPROVIDERMETA','SERVICEPROVIDERMETAA0','SERVICEPROVIDERSERVICE','SERVICEPROVIDERSERVICEA0','SIGNTEMPLATE','SIGNTEMPLATEA0','SIGNTMPLHEADER','SIGNTMPLHEADERA0','SLIMLWR','SMMETHOD','SMMETHODA0','SMMETHODLABGROUP','SMMETHODLABGROUPA0','SMMETHODRESREQUIREMENT','SMMETHODRESREQUIREMENTA0','SMMETHODSIGN','SMMETHODSIGNA0','SMMETHODTEMP','SMMETHODTEST','SMMETHODTESTA0','SMMETHODTESTRESULT','SMMETHODTESTRESULTA0','SOFTWARE','SOFTWAREA0','SOFTWAREFORMAT','SOFTWAREFORMATA0','SPECIFICATION','SPECIFICATIONA0','SPECIFICATIONATTRIBUTE','SPECIFICATIONATTRIBUTEA0','SPECIFICATIONLABGROUP','SPECIFICATIONLABGROUPA0','SPECIFICATIONSAMPLETEMPLATE','SPECIFICATIONSAMPLETEMPLATEA0','SPECIFICATIONSIGN','SPECIFICATIONSIGNA0','SPECIFICATIONTEMP','SPECIFICATIONTEST','SPECIFICATIONTESTA0','SPECIFICATIONTESTRESULT','SPECIFICATIONTESTRESULTA0','SPECIFICATIONVARIANT','SPECIFICATIONVARIANTA0','SPECRESULTREQUIREMENT','SPECRESULTREQUIREMENTA0','STATUS','STATUSA0','STATUSTYPE','STATUSTYPEA0','STRUCTUREATTRIBUTES','STRUCTUREATTRIBUTESA0','STRUCTURES_DATA','STRUCTURES_DATAA0',
					'STRUCTURES_HEADER','STRUCTURES_HEADERA0','SUBMISSION','SUBMISSIONA0','SUBMISSIONSAMPLE','SUBMISSIONSAMPLEA0','SUBMISSIONTEMP','SUBMISSIONTEMPLATE','SUBMISSIONTEMPLATEA0','SUBMISSIONTEMPLATELIST','SUBMISSIONTEMPLATELISTA0','SUBMISSIONTEMPLTEMP','SUBMISSIONTEST','SUBMISSIONTESTA0','SUBMISSIONTESTRESULT','SUBMISSIONTESTRESULTA0','SUBMISSIONTESTRESULTREQ','SUBMISSIONTESTRESULTREQA0','SUBSTANCE','SUBSTANCEA0','SYSTEMTYPE','SYSTEMTYPEA0','SYSTEMVALUES','SYSTEMVALUESA0','TEST','TESTA0','TESTATTRIBUTE','TESTATTRIBUTEA0','TESTDEFINITION','TESTDEFINITIONA0','TESTGROUPMETHODPREPARATION','TESTGROUPMETHODPREPARATIONA0','TESTLOG','TESTLOGA0','TESTREQUEST','TESTREQUESTA0','TESTREQUESTATTRIBUTE','TESTREQUESTATTRIBUTEA0','TESTREQUESTSIGN','TESTREQUESTSIGNA0','TESTREQUESTTEMP','TESTRESULT','TESTRESULTA0','TESTRESULTATTRIBUTE','TESTRESULTATTRIBUTEA0','TESTRESULTDEFINITION','TESTRESULTDEFINITIONA0','TESTRESULTREQTEMPLATE','TESTRESULTREQTEMPLATEA0','TESTRESULTREQUIREMENT','TESTRESULTREQUIREMENTA0','TESTRESULTTEMPLATE','TESTRESULTTEMPLATEA0','TESTSAMPLE','TESTSAMPLEA0','TESTTEMP','THUMBNAILS','THUMBNAILSA0','UICONFIGURATION','UICONFIGURATIONA0',
					'UPLOADTEMPLATEFIELDS','UPLOADTEMPLATEFIELDSA0','UPLOADTEMPLATEHEADER','UPLOADTEMPLATEHEADERA0','UPLOADTEMPLATES','UPLOADTEMPLATESA0','USERATTRIBUTES','USERATTRIBUTESA0','USERLOG','USERLOGA0','USERMESSAGE','USERMESSAGEA0','USERPREFERENCES','USERPREFERENCESA0','USERPROGLOG','USERPROGLOGA0','USERS','USERSA0','USERSSIGNINFO','USERSSIGNINFOA0','USERTRAINING','USERTRAININGA0','USERTRAININGLOG','USERTRAININGLOGA0','WEBSESSIONS','WEBSESSIONSA0','WHERECONDITION','WHERECONDITIONA0','WORKLIST','WORKLISTA0');
				ELSIF	(:V_OracleVer LIKE '19%')	THEN -- and Oracle 19c
					t_TableList := ObjList('ANALYSENMETHODE','ANALYSENMETHODEA0','ANALYSISMETHODCLASSIFICATION','ANALYSISMETHODCLASSIFICATIONA0','ANALYSISMETHODLABGROUP','ANALYSISMETHODLABGROUPA0','ANALYSISMETHODPARAMETER','ANALYSISMETHODPARAMETERA0','AO_KEYWORDS','AO_KEYWORDSA0','AO_KEYWORDSA0L0','AO_KEYWORDSA0L0A0','AO_KEYWORDSL0','AO_KEYWORDSL0A0','APPENDIX','ARCHIVEREGISTRATION','ARCHIVEREGISTRATIONA0','ARCHIVEREQUESTLOG','ARCHIVEREQUESTLOGA0','ARCHIVEREQUESTORDERS','ARCHIVEREQUESTORDERSA0','ARCHIVETABLES','ARCHIVETABLESA0','ARTIKEL','ARTIKELA0','ATOMS','ATOMSA0','BINARYCOLUMNS','BINARYCOLUMNSA0','BINARYDOCUMENT','BINARYDOCUMENTA0','BINARYOBJECT','BINARYOBJECTA0','BINARY_ORDER','BINARY_ORDERA0','BOND','BONDA0','CHANNEL','CHANNELA0','CODEWORDS','CODEWORDSA0','CONNECTIONCONFIG','CONNECTIONCONFIGA0','CONTAINERVIEWERCONFIGC','CONTAINERVIEWERCONFIGCA0','CONTAINERVIEWERMETHODS','CONTAINERVIEWERMETHODSA0','CONTVIEWERCOLORMETHODS','CONTVIEWERCOLORMETHODSA0','CONVERSIONFILTER','CONVERSIONFILTERA0','CONVERSIONLOG','CONVERSIONLOGA0','CONVERTCOMMENTS','CONVERTCOMMENTSA0','CONVERTSOFTWARE','CONVERTSOFTWAREA0','COSTCENTER','COSTCENTERA0','COSTCENTERTYPES',
					'COSTCENTERTYPESA0','COUNTRY','COUNTRYA0','CUSTOMER','CUSTOMERA0','CUSTOMERCOSTCENTER','CUSTOMERCOSTCENTERA0','CV_COLORRESULTMAPPING','CV_COLORRESULTMAPPINGA0','DATAFIELDS','DATAFIELDSA0','DATAQUEUE','DATAQUEUEA0','DEADLINECODE','DEADLINECODEA0','DOMAIN','DOMAINA0','DOMAINCONSTRAINT','DOMAINCONSTRAINTA0','DOMAINVALUE','DOMAINVALUEA0','DR$CTX_BINARYDOCUMENT$I','DR$CTX_BINARYDOCUMENT$K','DR$CTX_BINARYDOCUMENT$N','DR$CTX_BINARYDOCUMENT$U','DR$TEXT_IDX_EXTERNALPLUGIN$I','DR$TEXT_IDX_EXTERNALPLUGIN$K','DR$TEXT_IDX_EXTERNALPLUGIN$N','DR$TEXT_IDX_EXTERNALPLUGIN$U','DR$TEXT_IDX_LOCATION$I','DR$TEXT_IDX_LOCATION$K','DR$TEXT_IDX_LOCATION$N','DR$TEXT_IDX_LOCATION$U','DR$TEXT_IDX_MEASUREORDER$I','DR$TEXT_IDX_MEASUREORDER$K','DR$TEXT_IDX_MEASUREORDER$N','DR$TEXT_IDX_MEASUREORDER$U','DR$TEXT_IDX_PHYSICALSAMPLE$I','DR$TEXT_IDX_PHYSICALSAMPLE$K','DR$TEXT_IDX_PHYSICALSAMPLE$N','DR$TEXT_IDX_PHYSICALSAMPLE$U','DR$TEXT_IDX_PRODUCT$I','DR$TEXT_IDX_PRODUCT$K','DR$TEXT_IDX_PRODUCT$N','DR$TEXT_IDX_PRODUCT$U',
					'DR$TEXT_IDX_REPORTCONFIG$I','DR$TEXT_IDX_REPORTCONFIG$K','DR$TEXT_IDX_REPORTCONFIG$N','DR$TEXT_IDX_REPORTCONFIG$U','DR$TEXT_IDX_REPORTCONFIGLIB$I','DR$TEXT_IDX_REPORTCONFIGLIB$K','DR$TEXT_IDX_REPORTCONFIGLIB$N','DR$TEXT_IDX_REPORTCONFIGLIB$U','DR$TEXT_IDX_SAMPLETEMPLATE$I','DR$TEXT_IDX_SAMPLETEMPLATE$K','DR$TEXT_IDX_SAMPLETEMPLATE$N','DR$TEXT_IDX_SAMPLETEMPLATE$U','DR$TEXT_IDX_SMMETHOD$I','DR$TEXT_IDX_SMMETHOD$K','DR$TEXT_IDX_SMMETHOD$N','DR$TEXT_IDX_SMMETHOD$U','DR$TEXT_IDX_SPECIFICATION$I','DR$TEXT_IDX_SPECIFICATION$K','DR$TEXT_IDX_SPECIFICATION$N','DR$TEXT_IDX_SPECIFICATION$U','DR$TEXT_IDX_SUBMISSION$I','DR$TEXT_IDX_SUBMISSION$K','DR$TEXT_IDX_SUBMISSION$N','DR$TEXT_IDX_SUBMISSION$U','DR$TEXT_IDX_SUBMISSIONTEMPL$I','DR$TEXT_IDX_SUBMISSIONTEMPL$K','DR$TEXT_IDX_SUBMISSIONTEMPL$N','DR$TEXT_IDX_SUBMISSIONTEMPL$U','DR$TEXT_IDX_TEST$I','DR$TEXT_IDX_TEST$K','DR$TEXT_IDX_TEST$N','DR$TEXT_IDX_TEST$U','DR$TEXT_IDX_TESTDEFINITION$I',
					'DR$TEXT_IDX_TESTDEFINITION$K','DR$TEXT_IDX_TESTDEFINITION$N','DR$TEXT_IDX_TESTDEFINITION$U','DR$TEXT_IDX_TESTREQUEST$I','DR$TEXT_IDX_TESTREQUEST$K','DR$TEXT_IDX_TESTREQUEST$N','DR$TEXT_IDX_TESTREQUEST$U','DR$TEXT_IDX_TESTRESULT$I','DR$TEXT_IDX_TESTRESULT$K','DR$TEXT_IDX_TESTRESULT$N','DR$TEXT_IDX_TESTRESULT$U','DR$TEXT_IDX_UICONFIGURATION$I','DR$TEXT_IDX_UICONFIGURATION$K','DR$TEXT_IDX_UICONFIGURATION$N','DR$TEXT_IDX_UICONFIGURATION$U','DR$TEXT_IDX_USERMESSAGE$I','DR$TEXT_IDX_USERMESSAGE$K','DR$TEXT_IDX_USERMESSAGE$N','DR$TEXT_IDX_USERMESSAGE$U','DR$TEXT_IDX_USERS$I','DR$TEXT_IDX_USERS$K','DR$TEXT_IDX_USERS$N','DR$TEXT_IDX_USERS$U','DRG_CALENDAR','DRG_CALENDARA0','DRG_MESSPARAM_GROUPING','DRG_MESSPARAM_GROUPINGA0','DRG_METHGRP','DRG_METHGRPA0','DRG_METHGRPDETAIL','DRG_METHGRPDETAILA0','DRG_METHGRPDETMETA','DRG_METHGRPDETMETAA0','DRG_METHGRPLABGRP','DRG_METHGRPLABGRPA0','DRG_METHGRPLINK','DRG_METHGRPLINKA0','DRG_METHGRPMETA','DRG_METHGRPMETAA0','DRG_METHGRPPARAM','DRG_METHGRPPARAMA0',
					'DRG_METHGRPPARAMVALUE','DRG_METHGRPPARAMVALUEA0','DRG_METHGRPSET','DRG_METHGRPSETA0','DRG_METHGRPSIGN','DRG_METHGRPSIGNA0','DRG_PRINTHISTORY','DRG_PRINTHISTORYA0','DRG_SERVICERESULT','DRG_SERVICERESULTA0','DRG_SERVICERESULTDATA','DRG_SERVICERESULTDATAA0','DRG_SERVICERESULTMETA','DRG_SERVICERESULTMETAA0','ELABMASSIVRRETURN_NEWSTRUCTURE','ELABORDER','ELABORDERANALYSIS','ELABORDERANALYSISA0','ELABORDERSAMPLE','ELABORDERSAMPLEA0','ELAB_COMMAND','ELAB_COMMANDA0','EMPLOYEE','EMPLOYEEA0','EMPLOYEEREPRESENTATIVE','EMPLOYEEREPRESENTATIVEA0','EXPERTSYSTEM','EXPERTSYSTEMA0','EXPERTSYSTEMDATABASE','EXPERTSYSTEMDATABASEA0','EXTERNALPLUGIN','EXTERNALPLUGINA0','FIXTEXTCATALOG','FIXTEXTCATALOGA0','FIXTEXTCATEGORY','FIXTEXTCATEGORYA0','FIXTEXTE','FIXTEXTEA0','FORMAT','FORMATA0','FORMATEXTENSION','FORMATEXTENSIONA0','FORMATVERSION','FORMATVERSIONA0','FORMULATION','FORMULATIONA0','FUNCTACCESS','FUNCTACCESSA0','FUNCTION','FUNCTIONA0','GROUPPROGRAM','GROUPPROGRAMA0','GROUPS','GROUPSA0','INGREDIENT','INGREDIENTA0','INSTHUBATTRIBUTE','INSTHUBATTRIBUTEA0','INSTHUBLOG','INSTHUBLOGA0','INSTHUBREAGENT','INSTHUBREAGENTA0','INSTHUBRESULT','INSTHUBRESULTA0',
					'INSTHUBRESULTATTRIBUTE','INSTHUBRESULTATTRIBUTEA0','INSTHUBRESULTBINARY','INSTHUBRESULTBINARYA0','INSTHUBRESULTTABLEITEM','INSTHUBRESULTTABLEITEMA0','INSTRUMENT','INSTRUMENTA0','INSTRUMENTENCOMPUTER','INSTRUMENTENCOMPUTERA0','INSTRUMENTHUB','INSTRUMENTHUBA0','INSTRUMENTPARAMETER','INSTRUMENTPARAMETERA0','INSTRUMENT_ORDER','INSTRUMENT_ORDERA0','INSTRUMENT_ORDER_INFORMATION','INSTRUMENT_ORDER_INFORMATIONA0','INSTRUMENT_ORDER_MOLFILE','INSTRUMENT_ORDER_MOLFILEA0','INSTRUMENT_ORDER_RETURN','INSTRUMENT_ORDER_RETURNA0','INV_CHEMICAL','INV_CHEMICALA0','INV_CHEMICALCOMPOUND','INV_CHEMICALCOMPOUNDA0','INV_CHEMICALLOG','INV_CHEMICALLOGA0','INV_INSTRUMENT','INV_INSTRUMENTA0','INV_INSTRUMENTLOG','INV_INSTRUMENTLOGA0','JAVACLASS','JAVACLASSA0','JOBMGRCONFIG','JOBMGRCONFIGA0','JOBPARAMS','JOBPARAMSA0','JOBS','JOBSA0','JOBSCHEDULE','JOBSCHEDULEA0','JOBSCHEDULEPARAMS','JOBSCHEDULEPARAMSA0','JOBTYPEPARAMS','JOBTYPEPARAMSA0','JOBTYPES','JOBTYPESA0','KEYWORDS','KEYWORDSA0','LABGROUP','LABGROUPA0','LABGROUPEMPLOYEE','LABGROUPEMPLOYEEA0','LABGROUPLABGROUP','LABGROUPLABGROUPA0','LABGROUPNOTIFICATIONLIST','LABGROUPNOTIFICATIONLISTA0','LABGROUPNOTIFICATIONS',
					'LABGROUPNOTIFICATIONSA0','LANGUAGE','LANGUAGEA0','LICENSE','LICENSEA0','LIMSMAILINFORMATION','LIMSMAILINFORMATIONA0','LIMSSYSTEM','LIMSSYSTEMA0','LIMSSYSTEMINTERFACE','LIMSSYSTEMINTERFACEA0','LOCATION','LOCATIONA0','LONGTIMEARCHIVE','LONGTIMEARCHIVEA0','MAILBOX_COMPONENTRETURN','MAILBOX_COMPONENTRETURNA0','MAILBOX_MEASUREORDER','MAILBOX_MEASUREORDERA0','MAILBOX_METHOD','MAILBOX_METHODA0','MAILBOX_ORDERATTRIBUTES','MAILBOX_ORDERATTRIBUTESA0','MAILBOX_RESULTRETURN','MAILBOX_RESULTRETURNA0','MAILBOX_SAMPLE','MAILBOX_SAMPLEA0','MAILBOX_STRUCTUREATTRIBUTES','MAILBOX_STRUCTUREATTRIBUTESA0','MASSIVRORDERRETURN','MASSIVR_COMMAND','MASSIVR_COMMANDA0','MB_BASIC_DATA','MB_BINARYRESULT','MB_CONNECTOR_COMMAND_QUEUE','MB_LISTS','MB_LIST_COLLECTION','MB_LIST_CONTENT','MB_MAPPING','MB_MAPPING_TEST','MB_MAPPING_TESTRESULT','MB_SCHEDULE','MB_TEST','MB_TESTA0','MB_TESTREQUEST','MB_TESTREQUESTA0','MB_TESTRESULT','MB_TESTRESULTA0','MB_TRANSACTIONRESULT','MB_WHERE_CONFIG','MEASUREORDER','MEASUREORDERA0','MEASUREORDERA0L0','MEASUREORDERA0L0A0','MEASUREORDERL0','MEASUREORDERL0A0','MESSAGE','MESSAGEA0','MESSAGEATTRIBUTE','MESSAGEATTRIBUTEA0','MESSAGES','MESSAGESA0',
					'MESSPARAMETER','MESSPARAMETERA0','METADATA','METADATAA0','METHODE','METHODEA0','METHODEXPERTSYSTEM','METHODEXPERTSYSTEMA0','METHODFILE','METHODFILEA0','METHODGROUP','METHODGROUPA0','METHODGROUPDETAIL','METHODGROUPDETAILA0','METHODLABGROUP','METHODLABGROUPA0','METHODPARTSLIST','METHODPARTSLISTA0','METHODPREPARATION','METHODPREPARATIONA0','METHODRESULTTYPE','METHODRESULTTYPEA0','METHODRESULTTYPECOMPONENT','METHODRESULTTYPECOMPONENTA0','METHODSUMMARY','METHODSUMMARYA0','METHODTOPTENLIST','METHODTOPTENLISTA0','MLOG$_MEASUREORDER','MLOG$_MO_ORDERATTRIBUTES','MLOG$_MO_PARAMETERTAB','MODUL','MODULA0','MOTIVATION','MOTIVATIONA0','MO_ANALYSISMETHODSELECTION','MO_ANALYSISMETHODSELECTIONA0','MO_ANALYSISMETHODSELECTIONA0L0','MO_ANALYSISMETHODSELECTIONL0','MO_ANALYSISMETHODSELECTIONL0A0','MO_AO','MO_AOA0','MO_AOA0L0','MO_AOA0L0A0','MO_AOL0','MO_AOL0A0','MO_CODEWORDS','MO_CODEWORDSA0','MO_CODEWORDSA0L0','MO_CODEWORDSA0L0A0','MO_CODEWORDSL0','MO_CODEWORDSL0A0','MO_COSTS','MO_COSTSA0','MO_COSTSA0L0','MO_COSTSA0L0A0','MO_COSTSL0','MO_COSTSL0A0','MO_INSTRUMENT_PARAMETER','MO_INSTRUMENT_PARAMETERA0','MO_INSTRUMENT_RESULTS','MO_INSTRUMENT_RESULTSA0','MO_INSTRUMENT_RETURNS',
					'MO_INSTRUMENT_RETURNSA0','MO_INSTR_PARAM_RETURN','MO_INSTR_PARAM_RETURNA0','MO_LINK','MO_LINKA0','MO_LO','MO_LOA0','MO_LOA0L0','MO_LOA0L0A0','MO_LOL0','MO_LOL0A0','MO_LO_COSTS','MO_LO_COSTSA0','MO_LO_COSTSA0L0','MO_LO_COSTSA0L0A0','MO_LO_COSTSL0','MO_LO_COSTSL0A0','MO_LO_SAMPLE','MO_LO_SAMPLEA0','MO_LO_SAMPLEA0L0','MO_LO_SAMPLEA0L0A0','MO_LO_SAMPLEL0','MO_LO_SAMPLEL0A0','MO_MEASURESAMPLE','MO_MEASURESAMPLEA0','MO_MEASURESAMPLEA0L0','MO_MEASURESAMPLEA0L0A0','MO_MEASURESAMPLEL0','MO_MEASURESAMPLEL0A0','MO_METADATACONFIG','MO_METADATACONFIGA0','MO_METHOD','MO_METHODA0','MO_METHODA0L0','MO_METHODA0L0A0','MO_METHODL0','MO_METHODL0A0','MO_METHODMODULE','MO_METHODMODULEA0','MO_METHODMODULEA0L0','MO_METHODMODULEA0L0A0','MO_METHODMODULEEXPORT','MO_METHODMODULEEXPORTA0','MO_METHODMODULEEXPORTA0L0','MO_METHODMODULEEXPORTA0L0A0','MO_METHODMODULEEXPORTL0','MO_METHODMODULEEXPORTL0A0','MO_METHODMODULEL0','MO_METHODMODULEL0A0','MO_METHODSTRUCTURE','MO_METHODSTRUCTUREA0','MO_METHODSTRUCTUREA0L0','MO_METHODSTRUCTUREA0L0A0','MO_METHODSTRUCTUREL0','MO_METHODSTRUCTUREL0A0','MO_MOLFILE','MO_MOLFILEA0','MO_ORDERATTRIBUTES','MO_ORDERATTRIBUTESA0','MO_ORDERATTRIBUTESA0L0',
					'MO_ORDERATTRIBUTESA0L0A0','MO_ORDERATTRIBUTESL0','MO_ORDERATTRIBUTESL0A0','MO_ORDERMETHGROUP','MO_ORDERMETHGROUPA0','MO_ORDERMODIFIERS','MO_ORDERMODIFIERSA0','MO_PARAMETER','MO_PARAMETERA0','MO_PARAMETERA0L0','MO_PARAMETERA0L0A0','MO_PARAMETERL0','MO_PARAMETERL0A0','MO_PARAMETERTAB','MO_PARAMETERTABA0','MO_PROJECT','MO_PROJECTA0','MO_PROJECTA0L0','MO_PROJECTA0L0A0','MO_PROJECTL0','MO_PROJECTL0A0','MO_PUBLISHORDER','MO_PUBLISHORDERA0','MO_RDFILE','MO_RDFILEA0','MO_RDFILEA0L0','MO_RDFILEA0L0A0','MO_RDFILEL0','MO_RDFILEL0A0','MO_RDVERSION','MO_RDVERSIONA0','MO_RDVERSIONA0L0','MO_RDVERSIONA0L0A0','MO_RDVERSIONL0','MO_RDVERSIONL0A0','MO_RD_STRUCTURE','MO_RD_STRUCTUREA0','MO_RD_STRUCTUREA0L0','MO_RD_STRUCTUREA0L0A0','MO_RD_STRUCTUREL0','MO_RD_STRUCTUREL0A0','MO_REFERENCES_RESULTS','MO_REFERENCES_RESULTSA0','MO_REFERENCES_RESULTSA0L0','MO_REFERENCES_RESULTSA0L0A0','MO_REFERENCES_RESULTSL0','MO_REFERENCES_RESULTSL0A0','MO_RESULTDETAILSPECTRUM','MO_RESULTDETAILSPECTRUMA0','MO_RESULTDETAILSPECTRUMA0L0','MO_RESULTDETAILSPECTRUMA0L0A0','MO_RESULTDETAILSPECTRUML0','MO_RESULTDETAILSPECTRUML0A0','MO_RESULTEVALUATION','MO_RESULTEVALUATIONA0','MO_RESULTEVALUATIONA0L0',
					'MO_RESULTEVALUATIONA0L0A0','MO_RESULTEVALUATIONL0','MO_RESULTEVALUATIONL0A0','MO_RESULT_3DSPECTRUMDETAIL','MO_RESULT_3DSPECTRUMDETAILA0','MO_RESULT_3DSPECTRUMHEADER','MO_RESULT_3DSPECTRUMHEADERA0','MO_RESULT_BINARY','MO_RESULT_BINARYA0','MO_RESULT_BINARYA0L0','MO_RESULT_BINARYA0L0A0','MO_RESULT_BINARYL0','MO_RESULT_BINARYL0A0','MO_RESULT_CHROMATOGRAM','MO_RESULT_CHROMATOGRAMA0','MO_RESULT_CHROMATOGRAMA0L0','MO_RESULT_CHROMATOGRAMA0L0A0','MO_RESULT_CHROMATOGRAML0','MO_RESULT_CHROMATOGRAML0A0','MO_RESULT_COMPONENT','MO_RESULT_COMPONENTA0','MO_RESULT_COMPONENTA0L0','MO_RESULT_COMPONENTA0L0A0','MO_RESULT_COMPONENTL0','MO_RESULT_COMPONENTL0A0','MO_RESULT_HEADER','MO_RESULT_HEADERA0','MO_RESULT_HEADERA0L0','MO_RESULT_HEADERA0L0A0','MO_RESULT_HEADERL0','MO_RESULT_HEADERL0A0','MO_RESULT_MULTI_DETAIL','MO_RESULT_MULTI_DETAILA0','MO_RESULT_MULTI_DETAILA0L0','MO_RESULT_MULTI_DETAILA0L0A0','MO_RESULT_MULTI_DETAILL0','MO_RESULT_MULTI_DETAILL0A0','MO_RESULT_PEAKINFORMATION','MO_RESULT_PEAKINFORMATIONA0','MO_RESULT_PEAKINFORMATIONA0L0','MO_RESULT_PEAKINFORMATIONL0','MO_RESULT_PEAKINFORMATIONL0A0','MO_RESULT_SPECTRUM','MO_RESULT_SPECTRUMA0','MO_RESULT_SPECTRUMA0L0',
					'MO_RESULT_SPECTRUMA0L0A0','MO_RESULT_SPECTRUML0','MO_RESULT_SPECTRUML0A0','MO_RESULT_TEXT','MO_RESULT_TEXTA0','MO_RESULT_TEXTA0L0','MO_RESULT_TEXTA0L0A0','MO_RESULT_TEXTL0','MO_RESULT_TEXTL0A0','MO_REVIEW','MO_REVIEWA0','MO_SAMPLE','MO_SAMPLEA0','MO_SAMPLEA0L0','MO_SAMPLEA0L0A0','MO_SAMPLEL0','MO_SAMPLEL0A0','MO_SEQUENCEPARAMETER','MO_SEQUENCEPARAMETERA0','MO_SEQUENCEPARAMETERA0L0','MO_SEQUENCEPARAMETERA0L0A0','MO_SEQUENCEPARAMETERL0','MO_SEQUENCEPARAMETERL0A0','MO_SEQUENCETEMPLATE','MO_SEQUENCETEMPLATEA0','MO_SEQUENCETEMPLATEA0L0','MO_SEQUENCETEMPLATEA0L0A0','MO_SEQUENCETEMPLATEL0','MO_SEQUENCETEMPLATEL0A0','MO_SIGN','MO_SIGNA0','MO_STRUCTUREASSIGNMENT','MO_STRUCTUREASSIGNMENTA0','MO_STRUCTUREASSIGNMENTA0L0','MO_STRUCTUREASSIGNMENTA0L0A0','MO_STRUCTUREASSIGNMENTL0','MO_STRUCTUREASSIGNMENTL0A0','MO_STRUCTURE_SPECINFORESULTS','MO_STRUCTURE_SPECINFORESULTSA0','MO_SUBSTANCE','MO_SUBSTANCEA0','MO_SUBSTANCEA0L0','MO_SUBSTANCEA0L0A0','MO_SUBSTANCEL0','MO_SUBSTANCEL0A0','MO_WORKLIST','MO_WORKLISTA0','MO_WORKLISTA0L0','MO_WORKLISTA0L0A0','MO_WORKLISTL0','MO_WORKLISTL0A0','MSGHEADER','MSGHEADERA0','MSGITEM','MSGITEMA0','MSGVALUE','MSGVALUEA0','NOTIFICATION',
					'NOTIFICATIONA0','NOTIFICATIONLIST','NOTIFICATIONLISTA0','OPENORDERS','OPERATINGSYSTEM','OPERATINGSYSTEMA0','ORDERATTRIBUTES','ORDERATTRIBUTESA0','ORDERATTRIBUTESTYPE','ORDERATTRIBUTESTYPEA0','ORDERATTRIBUTES_TEXTINFO','ORDERATTRIBUTES_TEXTINFOA0','ORDERTYPE','ORDERTYPEA0','ORDERTYPEMETHODSASSIGN','ORDERTYPEMETHODSASSIGNA0','ORDERTYPERESULTTYPES','ORDERTYPERESULTTYPESA0','ORDERTYPEWEBMETHODS','ORDERTYPEWEBMETHODSA0','ORDERTYPE_LO','ORDERTYPE_LOA0','PHYSICALSAMPLE','PHYSICALSAMPLEA0','PHYSICALSAMPLETEMP','PREPARATION','PREPARATIONA0','PREPARATIONLABGROUP','PREPARATIONLABGROUPA0','PREPARATIONSTEPS','PREPARATIONSTEPSA0','PRINTER','PRINTERA0','PRODUCT','PRODUCTA0','PRODUCTCATEGORY','PRODUCTCATEGORYA0','PRODUCTTEMP','PROGRAMCONFIGURATION','PROGRAMCONFIGURATIONA0','PROJECT','PROJECTA0','PROJECTTEMPLATE','PROJECTTEMPLATEA0','PROJECTUSER','PROJECTUSERA0','PROJECT_DOCUMENT','PROJECT_DOCUMENTA0','PROJECT_ENTWICKLUNGSPLAN','PROJECT_ENTWICKLUNGSPLANA0','PROJECT_LO','PROJECT_LOA0','PROJECT_RESULT','PROJECT_RESULTA0','PROTECTIONPERIOD','PROTECTIONPERIODA0','PUBLICFILTERS','QDDPROJECT','QDDPROJECTA0','QDISCCNR','QDISRQMINTERFACE','QDISRQMINTERFACEA0','QDISSQL','REFERENCESPECTRA',
					'REFERENCESPECTRAA0','RENDITION','RENDITIONA0','REPORTCOMMENTS','REPORTCOMMENTSA0','REPORTCONFIGLABGROUP','REPORTCONFIGLABGROUPA0','REPORTCONFIGLIBRARY','REPORTCONFIGLIBRARYA0','REPORTCONFIGURATION','REPORTCONFIGURATIONA0','REPORTLABELS','REPORTLABELSA0','REPORTLAYOUT','REPORTLAYOUTA0','REPORTMETHODSVALUES','REPORTMETHODSVALUESA0','REPORTORDERSVALUES','REPORTORDERSVALUESA0','REPORTPARAMETERS','REPORTPARAMETERSA0','REPORTPICTURES','REPORTPICTURESA0','REQUESTSAMPLE','REQUESTSAMPLEA0','RESULTHIERARCHY','RESULTHIERARCHYA0','RESULTREQUIREMENTDEF','RESULTREQUIREMENTDEFA0','RESULTTYPE','RESULTTYPEA0','RESULTUNIT','RESULTUNITA0','RETRIEVERESULTLIST','RETRIEVERESULTLISTA0','SAMPLEATTRIBUTE','SAMPLEATTRIBUTEA0','SAMPLEQUALITY','SAMPLEQUALITYA0','SAMPLETEMPLATE','SAMPLETEMPLATEA0','SAMPLETEMPLATETEMP','SAMPLETEMPLLABGROUP','SAMPLETEMPLLABGROUPA0','SAMPLETEMPLRESREQUIREMENT','SAMPLETEMPLRESREQUIREMENTA0','SAMPLETEMPLSIGN','SAMPLETEMPLSIGNA0','SAMPLETEMPLTEST','SAMPLETEMPLTESTA0','SAMPLETEMPLTESTRESULT','SAMPLETEMPLTESTRESULTA0','SCREENLAYOUTCONFIGURATION','SCREENLAYOUTCONFIGURATIONA0','SCREENPROGRAM','SCREENPROGRAMA0','SEARCHCRITERIA','SEARCHCRITERIAA0','SEQUENCETEMPLATE',
					'SEQUENCETEMPLATEA0','SEQUENCETEMPLATEPARAMETER','SEQUENCETEMPLATEPARAMETERA0','SERVICEPROVIDER','SERVICEPROVIDERA0','SERVICEPROVIDERMETA','SERVICEPROVIDERMETAA0','SERVICEPROVIDERSERVICE','SERVICEPROVIDERSERVICEA0','SIGNTEMPLATE','SIGNTEMPLATEA0','SIGNTMPLHEADER','SIGNTMPLHEADERA0','SLIMLWR','SMMETHOD','SMMETHODA0','SMMETHODLABGROUP','SMMETHODLABGROUPA0','SMMETHODRESREQUIREMENT','SMMETHODRESREQUIREMENTA0','SMMETHODSIGN','SMMETHODSIGNA0','SMMETHODTEMP','SMMETHODTEST','SMMETHODTESTA0','SMMETHODTESTRESULT','SMMETHODTESTRESULTA0','SOFTWARE','SOFTWAREA0','SOFTWAREFORMAT','SOFTWAREFORMATA0','SPECIFICATION','SPECIFICATIONA0','SPECIFICATIONATTRIBUTE','SPECIFICATIONATTRIBUTEA0','SPECIFICATIONLABGROUP','SPECIFICATIONLABGROUPA0','SPECIFICATIONSAMPLETEMPLATE','SPECIFICATIONSAMPLETEMPLATEA0','SPECIFICATIONSIGN','SPECIFICATIONSIGNA0','SPECIFICATIONTEMP','SPECIFICATIONTEST','SPECIFICATIONTESTA0','SPECIFICATIONTESTRESULT','SPECIFICATIONTESTRESULTA0','SPECIFICATIONVARIANT','SPECIFICATIONVARIANTA0','SPECRESULTREQUIREMENT','SPECRESULTREQUIREMENTA0','STATUS','STATUSA0','STATUSTYPE','STATUSTYPEA0','STRUCTUREATTRIBUTES','STRUCTUREATTRIBUTESA0','STRUCTURES_DATA','STRUCTURES_DATAA0',
					'STRUCTURES_HEADER','STRUCTURES_HEADERA0','SUBMISSION','SUBMISSIONA0','SUBMISSIONSAMPLE','SUBMISSIONSAMPLEA0','SUBMISSIONTEMP','SUBMISSIONTEMPLATE','SUBMISSIONTEMPLATEA0','SUBMISSIONTEMPLATELIST','SUBMISSIONTEMPLATELISTA0','SUBMISSIONTEMPLTEMP','SUBMISSIONTEST','SUBMISSIONTESTA0','SUBMISSIONTESTRESULT','SUBMISSIONTESTRESULTA0','SUBMISSIONTESTRESULTREQ','SUBMISSIONTESTRESULTREQA0','SUBSTANCE','SUBSTANCEA0','SYSTEMTYPE','SYSTEMTYPEA0','SYSTEMVALUES','SYSTEMVALUESA0','TEST','TESTA0','TESTATTRIBUTE','TESTATTRIBUTEA0','TESTDEFINITION','TESTDEFINITIONA0','TESTGROUPMETHODPREPARATION','TESTGROUPMETHODPREPARATIONA0','TESTLOG','TESTLOGA0','TESTREQUEST','TESTREQUESTA0','TESTREQUESTATTRIBUTE','TESTREQUESTATTRIBUTEA0','TESTREQUESTSIGN','TESTREQUESTSIGNA0','TESTREQUESTTEMP','TESTRESULT','TESTRESULTA0','TESTRESULTATTRIBUTE','TESTRESULTATTRIBUTEA0','TESTRESULTDEFINITION','TESTRESULTDEFINITIONA0','TESTRESULTREQTEMPLATE','TESTRESULTREQTEMPLATEA0','TESTRESULTREQUIREMENT','TESTRESULTREQUIREMENTA0','TESTRESULTTEMPLATE','TESTRESULTTEMPLATEA0','TESTSAMPLE','TESTSAMPLEA0','TESTTEMP','THUMBNAILS','THUMBNAILSA0','UICONFIGURATION','UICONFIGURATIONA0',
					'UPLOADTEMPLATEFIELDS','UPLOADTEMPLATEFIELDSA0','UPLOADTEMPLATEHEADER','UPLOADTEMPLATEHEADERA0','UPLOADTEMPLATES','UPLOADTEMPLATESA0','USERATTRIBUTES','USERATTRIBUTESA0','USERLOG','USERLOGA0','USERMESSAGE','USERMESSAGEA0','USERPREFERENCES','USERPREFERENCESA0','USERPROGLOG','USERPROGLOGA0','USERS','USERSA0','USERSSIGNINFO','USERSSIGNINFOA0','USERTRAINING','USERTRAININGA0','USERTRAININGLOG','USERTRAININGLOGA0','WEBSESSIONS','WEBSESSIONSA0','WHERECONDITION','WHERECONDITIONA0','WORKLIST','WORKLISTA0');
				ELSE	t_TableList := ObjList('UNSUPPORTED_ORACLE_VERSION');
				END IF;
			ELSIF	(:v_LMSSchemaVerAsNum >= 9100 AND :v_LMSSchemaVerAsNum < 9200)	THEN -- ELNPROD table list for NG 9.1.  Only Oracle 19c supported.
				t_TableList := ObjList('ANALYSENMETHODE','ANALYSENMETHODEA0','ANALYSISMETHODCLASSIFICATION','ANALYSISMETHODCLASSIFICATIONA0','ANALYSISMETHODLABGROUP','ANALYSISMETHODLABGROUPA0','ANALYSISMETHODPARAMETER','ANALYSISMETHODPARAMETERA0','AO_KEYWORDS','AO_KEYWORDSA0','AO_KEYWORDSA0L0','AO_KEYWORDSA0L0A0','AO_KEYWORDSL0','AO_KEYWORDSL0A0','APPENDIX','ARCHIVEREGISTRATION','ARCHIVEREGISTRATIONA0','ARCHIVEREQUESTLOG','ARCHIVEREQUESTLOGA0','ARCHIVEREQUESTORDERS','ARCHIVEREQUESTORDERSA0','ARCHIVETABLES','ARCHIVETABLESA0','ARTIKEL','ARTIKELA0','ATOMS','ATOMSA0','BINARYCOLUMNS','BINARYCOLUMNSA0','BINARYDOCUMENT','BINARYDOCUMENTA0','BINARYOBJECT','BINARYOBJECTA0','BINARY_ORDER','BINARY_ORDERA0','BOND','BONDA0','CHANNEL','CHANNELA0','CODEWORDS','CODEWORDSA0','CONNECTIONCONFIG','CONNECTIONCONFIGA0','CONTAINERVIEWERCONFIGC','CONTAINERVIEWERCONFIGCA0','CONTAINERVIEWERMETHODS','CONTAINERVIEWERMETHODSA0','CONTVIEWERCOLORMETHODS','CONTVIEWERCOLORMETHODSA0','CONVERSIONFILTER','CONVERSIONFILTERA0','CONVERSIONLOG','CONVERSIONLOGA0','CONVERTCOMMENTS','CONVERTCOMMENTSA0','CONVERTSOFTWARE','CONVERTSOFTWAREA0','COSTCENTER','COSTCENTERA0','COSTCENTERTYPES','COSTCENTERTYPESA0','COUNTRY','COUNTRYA0',
				'CUSTOMER','CUSTOMERA0','CUSTOMERCOSTCENTER','CUSTOMERCOSTCENTERA0','CV_COLORRESULTMAPPING','CV_COLORRESULTMAPPINGA0','DATAFIELDS','DATAFIELDSA0','DATAQUEUE','DATAQUEUEA0','DEADLINECODE','DEADLINECODEA0','DOMAIN','DOMAINA0','DOMAINCONSTRAINT','DOMAINCONSTRAINTA0','DOMAINVALUE','DOMAINVALUEA0','DR$CTX_BINARYDOCUMENT$I','DR$CTX_BINARYDOCUMENT$K','DR$CTX_BINARYDOCUMENT$N','DR$CTX_BINARYDOCUMENT$U','DR$TEXT_IDX_EXTERNALPLUGIN$I','DR$TEXT_IDX_EXTERNALPLUGIN$K','DR$TEXT_IDX_EXTERNALPLUGIN$N','DR$TEXT_IDX_EXTERNALPLUGIN$U','DR$TEXT_IDX_INV_CHEMICAL$I','DR$TEXT_IDX_INV_CHEMICAL$K','DR$TEXT_IDX_INV_CHEMICAL$N','DR$TEXT_IDX_INV_CHEMICAL$U','DR$TEXT_IDX_INV_INSTRUMENT$I','DR$TEXT_IDX_INV_INSTRUMENT$K','DR$TEXT_IDX_INV_INSTRUMENT$N','DR$TEXT_IDX_INV_INSTRUMENT$U','DR$TEXT_IDX_LOCATION$I','DR$TEXT_IDX_LOCATION$K','DR$TEXT_IDX_LOCATION$N','DR$TEXT_IDX_LOCATION$U','DR$TEXT_IDX_MEASUREORDER$I','DR$TEXT_IDX_MEASUREORDER$K','DR$TEXT_IDX_MEASUREORDER$N','DR$TEXT_IDX_MEASUREORDER$U','DR$TEXT_IDX_PHYSICALSAMPLE$I','DR$TEXT_IDX_PHYSICALSAMPLE$K','DR$TEXT_IDX_PHYSICALSAMPLE$N','DR$TEXT_IDX_PHYSICALSAMPLE$U','DR$TEXT_IDX_PRODUCT$I','DR$TEXT_IDX_PRODUCT$K','DR$TEXT_IDX_PRODUCT$N','DR$TEXT_IDX_PRODUCT$U',
				'DR$TEXT_IDX_REPORTCONFIG$I','DR$TEXT_IDX_REPORTCONFIG$K','DR$TEXT_IDX_REPORTCONFIG$N','DR$TEXT_IDX_REPORTCONFIG$U','DR$TEXT_IDX_REPORTCONFIGLIB$I','DR$TEXT_IDX_REPORTCONFIGLIB$K','DR$TEXT_IDX_REPORTCONFIGLIB$N','DR$TEXT_IDX_REPORTCONFIGLIB$U','DR$TEXT_IDX_SAMPLETEMPLATE$I','DR$TEXT_IDX_SAMPLETEMPLATE$K','DR$TEXT_IDX_SAMPLETEMPLATE$N','DR$TEXT_IDX_SAMPLETEMPLATE$U','DR$TEXT_IDX_SMMETHOD$I','DR$TEXT_IDX_SMMETHOD$K','DR$TEXT_IDX_SMMETHOD$N','DR$TEXT_IDX_SMMETHOD$U','DR$TEXT_IDX_SPECIFICATION$I','DR$TEXT_IDX_SPECIFICATION$K','DR$TEXT_IDX_SPECIFICATION$N','DR$TEXT_IDX_SPECIFICATION$U','DR$TEXT_IDX_SUBMISSION$I','DR$TEXT_IDX_SUBMISSION$K','DR$TEXT_IDX_SUBMISSION$N','DR$TEXT_IDX_SUBMISSION$U','DR$TEXT_IDX_SUBMISSIONTEMPL$I','DR$TEXT_IDX_SUBMISSIONTEMPL$K','DR$TEXT_IDX_SUBMISSIONTEMPL$N','DR$TEXT_IDX_SUBMISSIONTEMPL$U','DR$TEXT_IDX_TEST$I','DR$TEXT_IDX_TEST$K','DR$TEXT_IDX_TEST$N','DR$TEXT_IDX_TEST$U','DR$TEXT_IDX_TESTDEFINITION$I','DR$TEXT_IDX_TESTDEFINITION$K','DR$TEXT_IDX_TESTDEFINITION$N','DR$TEXT_IDX_TESTDEFINITION$U','DR$TEXT_IDX_TESTREQUEST$I','DR$TEXT_IDX_TESTREQUEST$K','DR$TEXT_IDX_TESTREQUEST$N','DR$TEXT_IDX_TESTREQUEST$U','DR$TEXT_IDX_TESTRESULT$I','DR$TEXT_IDX_TESTRESULT$K',
				'DR$TEXT_IDX_TESTRESULT$N','DR$TEXT_IDX_TESTRESULT$U','DR$TEXT_IDX_UICONFIGURATION$I','DR$TEXT_IDX_UICONFIGURATION$K','DR$TEXT_IDX_UICONFIGURATION$N','DR$TEXT_IDX_UICONFIGURATION$U','DR$TEXT_IDX_USERMESSAGE$I','DR$TEXT_IDX_USERMESSAGE$K','DR$TEXT_IDX_USERMESSAGE$N','DR$TEXT_IDX_USERMESSAGE$U','DR$TEXT_IDX_USERS$I','DR$TEXT_IDX_USERS$K','DR$TEXT_IDX_USERS$N','DR$TEXT_IDX_USERS$U','DRG_CALENDAR','DRG_CALENDARA0','DRG_MESSPARAM_GROUPING','DRG_MESSPARAM_GROUPINGA0','DRG_METHGRP','DRG_METHGRPA0','DRG_METHGRPDETAIL','DRG_METHGRPDETAILA0','DRG_METHGRPDETMETA','DRG_METHGRPDETMETAA0','DRG_METHGRPLABGRP','DRG_METHGRPLABGRPA0','DRG_METHGRPLINK','DRG_METHGRPLINKA0','DRG_METHGRPMETA','DRG_METHGRPMETAA0','DRG_METHGRPPARAM','DRG_METHGRPPARAMA0','DRG_METHGRPPARAMVALUE','DRG_METHGRPPARAMVALUEA0','DRG_METHGRPSET','DRG_METHGRPSETA0','DRG_METHGRPSIGN','DRG_METHGRPSIGNA0','DRG_PRINTHISTORY','DRG_PRINTHISTORYA0','DRG_SERVICERESULT','DRG_SERVICERESULTA0','DRG_SERVICERESULTDATA','DRG_SERVICERESULTDATAA0','DRG_SERVICERESULTMETA','DRG_SERVICERESULTMETAA0','ELABMASSIVRRETURN_NEWSTRUCTURE','ELABORDER','ELABORDERANALYSIS','ELABORDERANALYSISA0','ELABORDERSAMPLE','ELABORDERSAMPLEA0','ELAB_COMMAND',
				'ELAB_COMMANDA0','EMPLOYEE','EMPLOYEEA0','EMPLOYEEREPRESENTATIVE','EMPLOYEEREPRESENTATIVEA0','EXPERTSYSTEM','EXPERTSYSTEMA0','EXPERTSYSTEMDATABASE','EXPERTSYSTEMDATABASEA0','EXTERNALPLUGIN','EXTERNALPLUGINA0','FIXTEXTCATALOG','FIXTEXTCATALOGA0','FIXTEXTCATEGORY','FIXTEXTCATEGORYA0','FIXTEXTE','FIXTEXTEA0','FORMAT','FORMATA0','FORMATEXTENSION','FORMATEXTENSIONA0','FORMATVERSION','FORMATVERSIONA0','FORMULATION','FORMULATIONA0','FUNCTACCESS','FUNCTACCESSA0','FUNCTION','FUNCTIONA0','GROUPPROGRAM','GROUPPROGRAMA0','GROUPS','GROUPSA0','INGREDIENT','INGREDIENTA0','INSTHUBATTRIBUTE','INSTHUBATTRIBUTEA0','INSTHUBLOG','INSTHUBLOGA0','INSTHUBREAGENT','INSTHUBREAGENTA0','INSTHUBRESULT','INSTHUBRESULTA0','INSTHUBRESULTATTRIBUTE','INSTHUBRESULTATTRIBUTEA0','INSTHUBRESULTBINARY','INSTHUBRESULTBINARYA0','INSTHUBRESULTTABLEITEM','INSTHUBRESULTTABLEITEMA0','INSTRUMENT','INSTRUMENTA0','INSTRUMENTENCOMPUTER','INSTRUMENTENCOMPUTERA0','INSTRUMENTHUB','INSTRUMENTHUBA0','INSTRUMENTPARAMETER','INSTRUMENTPARAMETERA0','INSTRUMENT_ORDER','INSTRUMENT_ORDERA0','INSTRUMENT_ORDER_INFORMATION','INSTRUMENT_ORDER_INFORMATIONA0','INSTRUMENT_ORDER_MOLFILE','INSTRUMENT_ORDER_MOLFILEA0','INSTRUMENT_ORDER_RETURN',
				'INSTRUMENT_ORDER_RETURNA0','INV_CHEMICAL','INV_CHEMICALA0','INV_CHEMICALCOMPOUND','INV_CHEMICALCOMPOUNDA0','INV_CHEMICALLOG','INV_CHEMICALLOGA0','INV_CHEMICALTEMP','INV_INSTRUMENT','INV_INSTRUMENTA0','INV_INSTRUMENTLOG','INV_INSTRUMENTLOGA0','INV_INSTRUMENTTEMP','JAVACLASS','JAVACLASSA0','JOBMGRCONFIG','JOBMGRCONFIGA0','JOBPARAMS','JOBPARAMSA0','JOBS','JOBSA0','JOBSCHEDULE','JOBSCHEDULEA0','JOBSCHEDULEPARAMS','JOBSCHEDULEPARAMSA0','JOBTYPEPARAMS','JOBTYPEPARAMSA0','JOBTYPES','JOBTYPESA0','KEYWORDS','KEYWORDSA0','LABGROUP','LABGROUPA0','LABGROUPEMPLOYEE','LABGROUPEMPLOYEEA0','LABGROUPLABGROUP','LABGROUPLABGROUPA0','LABGROUPNOTIFICATIONLIST','LABGROUPNOTIFICATIONLISTA0','LABGROUPNOTIFICATIONS','LABGROUPNOTIFICATIONSA0','LANGUAGE','LANGUAGEA0','LICENSE','LICENSEA0','LIMSMAILINFORMATION','LIMSMAILINFORMATIONA0','LIMSSYSTEM','LIMSSYSTEMA0','LIMSSYSTEMINTERFACE','LIMSSYSTEMINTERFACEA0','LOCATION','LOCATIONA0','LONGTIMEARCHIVE','LONGTIMEARCHIVEA0','MAILBOX_COMPONENTRETURN','MAILBOX_COMPONENTRETURNA0','MAILBOX_MEASUREORDER','MAILBOX_MEASUREORDERA0','MAILBOX_METHOD','MAILBOX_METHODA0','MAILBOX_ORDERATTRIBUTES','MAILBOX_ORDERATTRIBUTESA0','MAILBOX_RESULTRETURN','MAILBOX_RESULTRETURNA0',
				'MAILBOX_SAMPLE','MAILBOX_SAMPLEA0','MAILBOX_STRUCTUREATTRIBUTES','MAILBOX_STRUCTUREATTRIBUTESA0','MASSIVRORDERRETURN','MASSIVR_COMMAND','MASSIVR_COMMANDA0','MB_BASIC_DATA','MB_BINARYRESULT','MB_CONNECTOR_COMMAND_QUEUE','MB_LISTS','MB_LIST_COLLECTION','MB_LIST_CONTENT','MB_MAPPING','MB_MAPPING_TEST','MB_MAPPING_TESTRESULT','MB_SCHEDULE','MB_TEST','MB_TESTA0','MB_TESTREQUEST','MB_TESTREQUESTA0','MB_TESTRESULT','MB_TESTRESULTA0','MB_TRANSACTIONRESULT','MB_WHERE_CONFIG','MEASUREORDER','MEASUREORDERA0','MEASUREORDERA0L0','MEASUREORDERA0L0A0','MEASUREORDERL0','MEASUREORDERL0A0','MESSAGE','MESSAGEA0','MESSAGEATTRIBUTE','MESSAGEATTRIBUTEA0','MESSAGES','MESSAGESA0','MESSPARAMETER','MESSPARAMETERA0','METADATA','METADATAA0','METHODE','METHODEA0','METHODEXPERTSYSTEM','METHODEXPERTSYSTEMA0','METHODFILE','METHODFILEA0','METHODGROUP','METHODGROUPA0','METHODGROUPDETAIL','METHODGROUPDETAILA0','METHODLABGROUP','METHODLABGROUPA0','METHODPARTSLIST','METHODPARTSLISTA0','METHODPREPARATION','METHODPREPARATIONA0','METHODRESULTTYPE','METHODRESULTTYPEA0','METHODRESULTTYPECOMPONENT','METHODRESULTTYPECOMPONENTA0','METHODSUMMARY','METHODSUMMARYA0','METHODTOPTENLIST','METHODTOPTENLISTA0','MLOG$_MEASUREORDER',
				'MLOG$_MO_ORDERATTRIBUTES','MLOG$_MO_PARAMETERTAB','MODUL','MODULA0','MOTIVATION','MOTIVATIONA0','MO_ANALYSISMETHODSELECTION','MO_ANALYSISMETHODSELECTIONA0','MO_ANALYSISMETHODSELECTIONA0L0','MO_ANALYSISMETHODSELECTIONL0','MO_ANALYSISMETHODSELECTIONL0A0','MO_AO','MO_AOA0','MO_AOA0L0','MO_AOA0L0A0','MO_AOL0','MO_AOL0A0','MO_CODEWORDS','MO_CODEWORDSA0','MO_CODEWORDSA0L0','MO_CODEWORDSA0L0A0','MO_CODEWORDSL0','MO_CODEWORDSL0A0','MO_COSTS','MO_COSTSA0','MO_COSTSA0L0','MO_COSTSA0L0A0','MO_COSTSL0','MO_COSTSL0A0','MO_INSTRUMENT_PARAMETER','MO_INSTRUMENT_PARAMETERA0','MO_INSTRUMENT_RESULTS','MO_INSTRUMENT_RESULTSA0','MO_INSTRUMENT_RETURNS','MO_INSTRUMENT_RETURNSA0','MO_INSTR_PARAM_RETURN','MO_INSTR_PARAM_RETURNA0','MO_LINK','MO_LINKA0','MO_LO','MO_LOA0','MO_LOA0L0','MO_LOA0L0A0','MO_LOL0','MO_LOL0A0','MO_LO_COSTS','MO_LO_COSTSA0','MO_LO_COSTSA0L0','MO_LO_COSTSA0L0A0','MO_LO_COSTSL0','MO_LO_COSTSL0A0','MO_LO_SAMPLE','MO_LO_SAMPLEA0','MO_LO_SAMPLEA0L0','MO_LO_SAMPLEA0L0A0','MO_LO_SAMPLEL0','MO_LO_SAMPLEL0A0','MO_MEASURESAMPLE','MO_MEASURESAMPLEA0','MO_MEASURESAMPLEA0L0','MO_MEASURESAMPLEA0L0A0','MO_MEASURESAMPLEL0','MO_MEASURESAMPLEL0A0','MO_METADATACONFIG','MO_METADATACONFIGA0','MO_METHOD',
				'MO_METHODA0','MO_METHODA0L0','MO_METHODA0L0A0','MO_METHODL0','MO_METHODL0A0','MO_METHODMODULE','MO_METHODMODULEA0','MO_METHODMODULEA0L0','MO_METHODMODULEA0L0A0','MO_METHODMODULEEXPORT','MO_METHODMODULEEXPORTA0','MO_METHODMODULEEXPORTA0L0','MO_METHODMODULEEXPORTA0L0A0','MO_METHODMODULEEXPORTL0','MO_METHODMODULEEXPORTL0A0','MO_METHODMODULEL0','MO_METHODMODULEL0A0','MO_METHODSTRUCTURE','MO_METHODSTRUCTUREA0','MO_METHODSTRUCTUREA0L0','MO_METHODSTRUCTUREA0L0A0','MO_METHODSTRUCTUREL0','MO_METHODSTRUCTUREL0A0','MO_MOLFILE','MO_MOLFILEA0','MO_ORDERATTRIBUTES','MO_ORDERATTRIBUTESA0','MO_ORDERATTRIBUTESA0L0','MO_ORDERATTRIBUTESA0L0A0','MO_ORDERATTRIBUTESL0','MO_ORDERATTRIBUTESL0A0','MO_ORDERMETHGROUP','MO_ORDERMETHGROUPA0','MO_ORDERMODIFIERS','MO_ORDERMODIFIERSA0','MO_PARAMETER','MO_PARAMETERA0','MO_PARAMETERA0L0','MO_PARAMETERA0L0A0','MO_PARAMETERL0','MO_PARAMETERL0A0','MO_PARAMETERTAB','MO_PARAMETERTABA0','MO_PROJECT','MO_PROJECTA0','MO_PROJECTA0L0','MO_PROJECTA0L0A0','MO_PROJECTL0','MO_PROJECTL0A0','MO_PUBLISHORDER','MO_PUBLISHORDERA0','MO_RDFILE','MO_RDFILEA0','MO_RDFILEA0L0','MO_RDFILEA0L0A0','MO_RDFILEL0','MO_RDFILEL0A0','MO_RDVERSION','MO_RDVERSIONA0','MO_RDVERSIONA0L0',
				'MO_RDVERSIONA0L0A0','MO_RDVERSIONL0','MO_RDVERSIONL0A0','MO_RD_STRUCTURE','MO_RD_STRUCTUREA0','MO_RD_STRUCTUREA0L0','MO_RD_STRUCTUREA0L0A0','MO_RD_STRUCTUREL0','MO_RD_STRUCTUREL0A0','MO_REFERENCES_RESULTS','MO_REFERENCES_RESULTSA0','MO_REFERENCES_RESULTSA0L0','MO_REFERENCES_RESULTSA0L0A0','MO_REFERENCES_RESULTSL0','MO_REFERENCES_RESULTSL0A0','MO_RESULTDETAILSPECTRUM','MO_RESULTDETAILSPECTRUMA0','MO_RESULTDETAILSPECTRUMA0L0','MO_RESULTDETAILSPECTRUMA0L0A0','MO_RESULTDETAILSPECTRUML0','MO_RESULTDETAILSPECTRUML0A0','MO_RESULTEVALUATION','MO_RESULTEVALUATIONA0','MO_RESULTEVALUATIONA0L0','MO_RESULTEVALUATIONA0L0A0','MO_RESULTEVALUATIONL0','MO_RESULTEVALUATIONL0A0','MO_RESULT_3DSPECTRUMDETAIL','MO_RESULT_3DSPECTRUMDETAILA0','MO_RESULT_3DSPECTRUMHEADER','MO_RESULT_3DSPECTRUMHEADERA0','MO_RESULT_BINARY','MO_RESULT_BINARYA0','MO_RESULT_BINARYA0L0','MO_RESULT_BINARYA0L0A0','MO_RESULT_BINARYL0','MO_RESULT_BINARYL0A0','MO_RESULT_CHROMATOGRAM','MO_RESULT_CHROMATOGRAMA0','MO_RESULT_CHROMATOGRAMA0L0','MO_RESULT_CHROMATOGRAMA0L0A0','MO_RESULT_CHROMATOGRAML0','MO_RESULT_CHROMATOGRAML0A0','MO_RESULT_COMPONENT','MO_RESULT_COMPONENTA0','MO_RESULT_COMPONENTA0L0','MO_RESULT_COMPONENTA0L0A0',
				'MO_RESULT_COMPONENTL0','MO_RESULT_COMPONENTL0A0','MO_RESULT_HEADER','MO_RESULT_HEADERA0','MO_RESULT_HEADERA0L0','MO_RESULT_HEADERA0L0A0','MO_RESULT_HEADERL0','MO_RESULT_HEADERL0A0','MO_RESULT_MULTI_DETAIL','MO_RESULT_MULTI_DETAILA0','MO_RESULT_MULTI_DETAILA0L0','MO_RESULT_MULTI_DETAILA0L0A0','MO_RESULT_MULTI_DETAILL0','MO_RESULT_MULTI_DETAILL0A0','MO_RESULT_PEAKINFORMATION','MO_RESULT_PEAKINFORMATIONA0','MO_RESULT_PEAKINFORMATIONA0L0','MO_RESULT_PEAKINFORMATIONL0','MO_RESULT_PEAKINFORMATIONL0A0','MO_RESULT_SPECTRUM','MO_RESULT_SPECTRUMA0','MO_RESULT_SPECTRUMA0L0','MO_RESULT_SPECTRUMA0L0A0','MO_RESULT_SPECTRUML0','MO_RESULT_SPECTRUML0A0','MO_RESULT_TEXT','MO_RESULT_TEXTA0','MO_RESULT_TEXTA0L0','MO_RESULT_TEXTA0L0A0','MO_RESULT_TEXTL0','MO_RESULT_TEXTL0A0','MO_REVIEW','MO_REVIEWA0','MO_SAMPLE','MO_SAMPLEA0','MO_SAMPLEA0L0','MO_SAMPLEA0L0A0','MO_SAMPLEL0','MO_SAMPLEL0A0','MO_SEQUENCEPARAMETER','MO_SEQUENCEPARAMETERA0','MO_SEQUENCEPARAMETERA0L0','MO_SEQUENCEPARAMETERA0L0A0','MO_SEQUENCEPARAMETERL0','MO_SEQUENCEPARAMETERL0A0','MO_SEQUENCETEMPLATE','MO_SEQUENCETEMPLATEA0','MO_SEQUENCETEMPLATEA0L0','MO_SEQUENCETEMPLATEA0L0A0','MO_SEQUENCETEMPLATEL0','MO_SEQUENCETEMPLATEL0A0',
				'MO_SIGN','MO_SIGNA0','MO_STRUCTUREASSIGNMENT','MO_STRUCTUREASSIGNMENTA0','MO_STRUCTUREASSIGNMENTA0L0','MO_STRUCTUREASSIGNMENTA0L0A0','MO_STRUCTUREASSIGNMENTL0','MO_STRUCTUREASSIGNMENTL0A0','MO_STRUCTURE_SPECINFORESULTS','MO_STRUCTURE_SPECINFORESULTSA0','MO_SUBSTANCE','MO_SUBSTANCEA0','MO_SUBSTANCEA0L0','MO_SUBSTANCEA0L0A0','MO_SUBSTANCEL0','MO_SUBSTANCEL0A0','MO_WORKLIST','MO_WORKLISTA0','MO_WORKLISTA0L0','MO_WORKLISTA0L0A0','MO_WORKLISTL0','MO_WORKLISTL0A0','MSGHEADER','MSGHEADERA0','MSGITEM','MSGITEMA0','MSGVALUE','MSGVALUEA0','NOTIFICATION','NOTIFICATIONA0','NOTIFICATIONLIST','NOTIFICATIONLISTA0','OPENORDERS','OPERATINGSYSTEM','OPERATINGSYSTEMA0','ORDERATTRIBUTES','ORDERATTRIBUTESA0','ORDERATTRIBUTESTYPE','ORDERATTRIBUTESTYPEA0','ORDERATTRIBUTES_TEXTINFO','ORDERATTRIBUTES_TEXTINFOA0','ORDERTYPE','ORDERTYPEA0','ORDERTYPEMETHODSASSIGN','ORDERTYPEMETHODSASSIGNA0','ORDERTYPERESULTTYPES','ORDERTYPERESULTTYPESA0','ORDERTYPEWEBMETHODS','ORDERTYPEWEBMETHODSA0','ORDERTYPE_LO','ORDERTYPE_LOA0','PHYSICALSAMPLE','PHYSICALSAMPLEA0','PHYSICALSAMPLETEMP','PREPARATION','PREPARATIONA0','PREPARATIONLABGROUP','PREPARATIONLABGROUPA0','PREPARATIONSTEPS','PREPARATIONSTEPSA0','PRINTER','PRINTERA0',
				'PRODUCT','PRODUCTA0','PRODUCTCATEGORY','PRODUCTCATEGORYA0','PRODUCTTEMP','PROGRAMCONFIGURATION','PROGRAMCONFIGURATIONA0','PROJECT','PROJECTA0','PROJECTTEMPLATE','PROJECTTEMPLATEA0','PROJECTUSER','PROJECTUSERA0','PROJECT_DOCUMENT','PROJECT_DOCUMENTA0','PROJECT_ENTWICKLUNGSPLAN','PROJECT_ENTWICKLUNGSPLANA0','PROJECT_LO','PROJECT_LOA0','PROJECT_RESULT','PROJECT_RESULTA0','PROTECTIONPERIOD','PROTECTIONPERIODA0','PUBLICFILTERS','QDDPROJECT','QDDPROJECTA0','QDISCCNR','QDISRQMINTERFACE','QDISRQMINTERFACEA0','QDISSQL','REFERENCESPECTRA','REFERENCESPECTRAA0','RENDITION','RENDITIONA0','REPORTCOMMENTS','REPORTCOMMENTSA0','REPORTCONFIGLABGROUP','REPORTCONFIGLABGROUPA0','REPORTCONFIGLIBRARY','REPORTCONFIGLIBRARYA0','REPORTCONFIGURATION','REPORTCONFIGURATIONA0','REPORTLABELS','REPORTLABELSA0','REPORTLAYOUT','REPORTLAYOUTA0','REPORTMETHODSVALUES','REPORTMETHODSVALUESA0','REPORTORDERSVALUES','REPORTORDERSVALUESA0','REPORTPARAMETERS','REPORTPARAMETERSA0','REPORTPICTURES','REPORTPICTURESA0','REQUESTSAMPLE','REQUESTSAMPLEA0','RESULTHIERARCHY','RESULTHIERARCHYA0','RESULTREQUIREMENTDEF','RESULTREQUIREMENTDEFA0','RESULTTYPE','RESULTTYPEA0','RESULTUNIT','RESULTUNITA0','RETRIEVERESULTLIST',
				'RETRIEVERESULTLISTA0','SAMPLEATTRIBUTE','SAMPLEATTRIBUTEA0','SAMPLEQUALITY','SAMPLEQUALITYA0','SAMPLETEMPLATE','SAMPLETEMPLATEA0','SAMPLETEMPLATETEMP','SAMPLETEMPLLABGROUP','SAMPLETEMPLLABGROUPA0','SAMPLETEMPLRESREQUIREMENT','SAMPLETEMPLRESREQUIREMENTA0','SAMPLETEMPLSIGN','SAMPLETEMPLSIGNA0','SAMPLETEMPLTEST','SAMPLETEMPLTESTA0','SAMPLETEMPLTESTRESULT','SAMPLETEMPLTESTRESULTA0','SCREENLAYOUTCONFIGURATION','SCREENLAYOUTCONFIGURATIONA0','SCREENPROGRAM','SCREENPROGRAMA0','SEARCHCRITERIA','SEARCHCRITERIAA0','SEQUENCETEMPLATE','SEQUENCETEMPLATEA0','SEQUENCETEMPLATEPARAMETER','SEQUENCETEMPLATEPARAMETERA0','SERVICEPROVIDER','SERVICEPROVIDERA0','SERVICEPROVIDERMETA','SERVICEPROVIDERMETAA0','SERVICEPROVIDERSERVICE','SERVICEPROVIDERSERVICEA0','SIGNTEMPLATE','SIGNTEMPLATEA0','SIGNTMPLHEADER','SIGNTMPLHEADERA0','SLIMLWR','SMMETHOD','SMMETHODA0','SMMETHODLABGROUP','SMMETHODLABGROUPA0','SMMETHODRESREQUIREMENT','SMMETHODRESREQUIREMENTA0','SMMETHODSIGN','SMMETHODSIGNA0','SMMETHODTEMP','SMMETHODTEST','SMMETHODTESTA0','SMMETHODTESTRESULT','SMMETHODTESTRESULTA0','SOFTWARE','SOFTWAREA0','SOFTWAREFORMAT','SOFTWAREFORMATA0','SPECIFICATION','SPECIFICATIONA0','SPECIFICATIONATTRIBUTE','SPECIFICATIONATTRIBUTEA0',
				'SPECIFICATIONLABGROUP','SPECIFICATIONLABGROUPA0','SPECIFICATIONSAMPLETEMPLATE','SPECIFICATIONSAMPLETEMPLATEA0','SPECIFICATIONSIGN','SPECIFICATIONSIGNA0','SPECIFICATIONTEMP','SPECIFICATIONTEST','SPECIFICATIONTESTA0','SPECIFICATIONTESTRESULT','SPECIFICATIONTESTRESULTA0','SPECIFICATIONVARIANT','SPECIFICATIONVARIANTA0','SPECRESULTREQUIREMENT','SPECRESULTREQUIREMENTA0','STATUS','STATUSA0','STATUSTYPE','STATUSTYPEA0','STRUCTUREATTRIBUTES','STRUCTUREATTRIBUTESA0','STRUCTURES_DATA','STRUCTURES_DATAA0','STRUCTURES_HEADER','STRUCTURES_HEADERA0','SUBMISSION','SUBMISSIONA0','SUBMISSIONSAMPLE','SUBMISSIONSAMPLEA0','SUBMISSIONTEMP','SUBMISSIONTEMPLATE','SUBMISSIONTEMPLATEA0','SUBMISSIONTEMPLATELIST','SUBMISSIONTEMPLATELISTA0','SUBMISSIONTEMPLTEMP','SUBMISSIONTEST','SUBMISSIONTESTA0','SUBMISSIONTESTRESULT','SUBMISSIONTESTRESULTA0','SUBMISSIONTESTRESULTREQ','SUBMISSIONTESTRESULTREQA0','SUBSTANCE','SUBSTANCEA0','SYSTEMTYPE','SYSTEMTYPEA0','SYSTEMVALUES','SYSTEMVALUESA0','TEST','TESTA0','TESTATTRIBUTE','TESTATTRIBUTEA0','TESTDEFINITION','TESTDEFINITIONA0','TESTGROUPMETHODPREPARATION','TESTGROUPMETHODPREPARATIONA0','TESTLOG','TESTLOGA0','TESTREQUEST','TESTREQUESTA0',
				'TESTREQUESTATTRIBUTE','TESTREQUESTATTRIBUTEA0','TESTREQUESTSIGN','TESTREQUESTSIGNA0','TESTREQUESTTEMP','TESTRESULT','TESTRESULTA0','TESTRESULTATTRIBUTE','TESTRESULTATTRIBUTEA0','TESTRESULTDEFINITION','TESTRESULTDEFINITIONA0','TESTRESULTREQTEMPLATE','TESTRESULTREQTEMPLATEA0','TESTRESULTREQUIREMENT','TESTRESULTREQUIREMENTA0','TESTRESULTTEMPLATE','TESTRESULTTEMPLATEA0','TESTSAMPLE','TESTSAMPLEA0','TESTTEMP','THUMBNAILS','THUMBNAILSA0','UICONFIGURATION','UICONFIGURATIONA0','UPLOADTEMPLATEFIELDS','UPLOADTEMPLATEFIELDSA0','UPLOADTEMPLATEHEADER','UPLOADTEMPLATEHEADERA0','UPLOADTEMPLATES','UPLOADTEMPLATESA0','USERATTRIBUTES','USERATTRIBUTESA0','USERLOG','USERLOGA0','USERMESSAGE','USERMESSAGEA0','USERPREFERENCES','USERPREFERENCESA0','USERPROGLOG','USERPROGLOGA0','USERS','USERSA0','USERSSIGNINFO','USERSSIGNINFOA0','USERTRAINING','USERTRAININGA0','USERTRAININGLOG','USERTRAININGLOGA0','WEBSESSIONS','WEBSESSIONSA0','WHERECONDITION','WHERECONDITIONA0','WORKLIST','WORKLISTA0');
			ELSIF	(:v_LMSSchemaVerAsNum >= 9200)	THEN -- ELNPROD table list for NG 9.2.
				t_TableList := ObjList('ANALYSENMETHODE','ANALYSENMETHODEA0','ANALYSISMETHODCLASSIFICATION','ANALYSISMETHODCLASSIFICATIONA0','ANALYSISMETHODLABGROUP','ANALYSISMETHODLABGROUPA0','ANALYSISMETHODPARAMETER','ANALYSISMETHODPARAMETERA0','AO_KEYWORDS','AO_KEYWORDSA0','AO_KEYWORDSA0L0','AO_KEYWORDSA0L0A0','AO_KEYWORDSL0','AO_KEYWORDSL0A0','APPENDIX','ARCHIVEREGISTRATION','ARCHIVEREGISTRATIONA0','ARCHIVEREQUESTLOG','ARCHIVEREQUESTLOGA0','ARCHIVEREQUESTORDERS','ARCHIVEREQUESTORDERSA0','ARCHIVETABLES','ARCHIVETABLESA0','ARTIKEL','ARTIKELA0','ATOMS','ATOMSA0','BINARYCOLUMNS','BINARYCOLUMNSA0','BINARYDOCUMENT','BINARYDOCUMENTA0','BINARYOBJECT','BINARYOBJECTA0','BINARY_ORDER','BINARY_ORDERA0','BOND','BONDA0','CHANNEL','CHANNELA0','CODEWORDS','CODEWORDSA0','CONNECTIONCONFIG','CONNECTIONCONFIGA0','CONTAINERVIEWERCONFIGC','CONTAINERVIEWERCONFIGCA0','CONTAINERVIEWERMETHODS','CONTAINERVIEWERMETHODSA0','CONTVIEWERCOLORMETHODS','CONTVIEWERCOLORMETHODSA0','CONVERSIONFILTER','CONVERSIONFILTERA0','CONVERSIONLOG','CONVERSIONLOGA0','CONVERTCOMMENTS','CONVERTCOMMENTSA0','CONVERTSOFTWARE','CONVERTSOFTWAREA0','COSTCENTER','COSTCENTERA0','COSTCENTERTYPES','COSTCENTERTYPESA0','COUNTRY','COUNTRYA0',
				'CUSTOMER','CUSTOMERA0','CUSTOMERCOSTCENTER','CUSTOMERCOSTCENTERA0','CV_COLORRESULTMAPPING','CV_COLORRESULTMAPPINGA0','DATAFIELDS','DATAFIELDSA0','DATAQUEUE','DATAQUEUEA0','DEADLINECODE','DEADLINECODEA0','DOMAIN','DOMAINA0','DOMAINCONSTRAINT','DOMAINCONSTRAINTA0','DOMAINVALUE','DOMAINVALUEA0','DR$CTX_BINARYDOCUMENT$I','DR$CTX_BINARYDOCUMENT$K','DR$CTX_BINARYDOCUMENT$N','DR$CTX_BINARYDOCUMENT$U','DR$TEXT_IDX_EXTERNALPLUGIN$I','DR$TEXT_IDX_EXTERNALPLUGIN$K','DR$TEXT_IDX_EXTERNALPLUGIN$N','DR$TEXT_IDX_EXTERNALPLUGIN$U','DR$TEXT_IDX_INV_CHEMICAL$I','DR$TEXT_IDX_INV_CHEMICAL$K','DR$TEXT_IDX_INV_CHEMICAL$N','DR$TEXT_IDX_INV_CHEMICAL$U','DR$TEXT_IDX_INV_INSTRUMENT$I','DR$TEXT_IDX_INV_INSTRUMENT$K','DR$TEXT_IDX_INV_INSTRUMENT$N','DR$TEXT_IDX_INV_INSTRUMENT$U','DR$TEXT_IDX_LOCATION$I','DR$TEXT_IDX_LOCATION$K','DR$TEXT_IDX_LOCATION$N','DR$TEXT_IDX_LOCATION$U','DR$TEXT_IDX_MEASUREORDER$I','DR$TEXT_IDX_MEASUREORDER$K','DR$TEXT_IDX_MEASUREORDER$N','DR$TEXT_IDX_MEASUREORDER$U','DR$TEXT_IDX_PHYSICALSAMPLE$I','DR$TEXT_IDX_PHYSICALSAMPLE$K','DR$TEXT_IDX_PHYSICALSAMPLE$N','DR$TEXT_IDX_PHYSICALSAMPLE$U','DR$TEXT_IDX_PRODUCT$I','DR$TEXT_IDX_PRODUCT$K','DR$TEXT_IDX_PRODUCT$N','DR$TEXT_IDX_PRODUCT$U',
				'DR$TEXT_IDX_REPORTCONFIG$I','DR$TEXT_IDX_REPORTCONFIG$K','DR$TEXT_IDX_REPORTCONFIG$N','DR$TEXT_IDX_REPORTCONFIG$U','DR$TEXT_IDX_REPORTCONFIGLIB$I','DR$TEXT_IDX_REPORTCONFIGLIB$K','DR$TEXT_IDX_REPORTCONFIGLIB$N','DR$TEXT_IDX_REPORTCONFIGLIB$U','DR$TEXT_IDX_SAMPLETEMPLATE$I','DR$TEXT_IDX_SAMPLETEMPLATE$K','DR$TEXT_IDX_SAMPLETEMPLATE$N','DR$TEXT_IDX_SAMPLETEMPLATE$U','DR$TEXT_IDX_SMMETHOD$I','DR$TEXT_IDX_SMMETHOD$K','DR$TEXT_IDX_SMMETHOD$N','DR$TEXT_IDX_SMMETHOD$U','DR$TEXT_IDX_SPECIFICATION$I','DR$TEXT_IDX_SPECIFICATION$K','DR$TEXT_IDX_SPECIFICATION$N','DR$TEXT_IDX_SPECIFICATION$U','DR$TEXT_IDX_SUBMISSION$I','DR$TEXT_IDX_SUBMISSION$K','DR$TEXT_IDX_SUBMISSION$N','DR$TEXT_IDX_SUBMISSION$U','DR$TEXT_IDX_SUBMISSIONTEMPL$I','DR$TEXT_IDX_SUBMISSIONTEMPL$K','DR$TEXT_IDX_SUBMISSIONTEMPL$N','DR$TEXT_IDX_SUBMISSIONTEMPL$U','DR$TEXT_IDX_TEST$I','DR$TEXT_IDX_TEST$K','DR$TEXT_IDX_TEST$N','DR$TEXT_IDX_TEST$U','DR$TEXT_IDX_TESTDEFINITION$I','DR$TEXT_IDX_TESTDEFINITION$K','DR$TEXT_IDX_TESTDEFINITION$N','DR$TEXT_IDX_TESTDEFINITION$U','DR$TEXT_IDX_TESTREQUEST$I','DR$TEXT_IDX_TESTREQUEST$K','DR$TEXT_IDX_TESTREQUEST$N','DR$TEXT_IDX_TESTREQUEST$U','DR$TEXT_IDX_TESTRESULT$I','DR$TEXT_IDX_TESTRESULT$K',
				'DR$TEXT_IDX_TESTRESULT$N','DR$TEXT_IDX_TESTRESULT$U','DR$TEXT_IDX_UICONFIGURATION$I','DR$TEXT_IDX_UICONFIGURATION$K','DR$TEXT_IDX_UICONFIGURATION$N','DR$TEXT_IDX_UICONFIGURATION$U','DR$TEXT_IDX_USERMESSAGE$I','DR$TEXT_IDX_USERMESSAGE$K','DR$TEXT_IDX_USERMESSAGE$N','DR$TEXT_IDX_USERMESSAGE$U','DR$TEXT_IDX_USERS$I','DR$TEXT_IDX_USERS$K','DR$TEXT_IDX_USERS$N','DR$TEXT_IDX_USERS$U','DRG_CALENDAR','DRG_CALENDARA0','DRG_MESSPARAM_GROUPING','DRG_MESSPARAM_GROUPINGA0','DRG_METHGRP','DRG_METHGRPA0','DRG_METHGRPDETAIL','DRG_METHGRPDETAILA0','DRG_METHGRPDETMETA','DRG_METHGRPDETMETAA0','DRG_METHGRPLABGRP','DRG_METHGRPLABGRPA0','DRG_METHGRPLINK','DRG_METHGRPLINKA0','DRG_METHGRPMETA','DRG_METHGRPMETAA0','DRG_METHGRPPARAM','DRG_METHGRPPARAMA0','DRG_METHGRPPARAMVALUE','DRG_METHGRPPARAMVALUEA0','DRG_METHGRPSET','DRG_METHGRPSETA0','DRG_METHGRPSIGN','DRG_METHGRPSIGNA0','DRG_PRINTHISTORY','DRG_PRINTHISTORYA0','DRG_SERVICERESULT','DRG_SERVICERESULTA0','DRG_SERVICERESULTDATA','DRG_SERVICERESULTDATAA0','DRG_SERVICERESULTMETA','DRG_SERVICERESULTMETAA0','ELABMASSIVRRETURN_NEWSTRUCTURE','ELABORDER','ELABORDERANALYSIS','ELABORDERANALYSISA0','ELABORDERSAMPLE','ELABORDERSAMPLEA0','ELAB_COMMAND',
				'ELAB_COMMANDA0','EMPLOYEE','EMPLOYEEA0','EMPLOYEEREPRESENTATIVE','EMPLOYEEREPRESENTATIVEA0','EXPERTSYSTEM','EXPERTSYSTEMA0','EXPERTSYSTEMDATABASE','EXPERTSYSTEMDATABASEA0','EXTERNALPLUGIN','EXTERNALPLUGINA0','FIXTEXTCATALOG','FIXTEXTCATALOGA0','FIXTEXTCATEGORY','FIXTEXTCATEGORYA0','FIXTEXTE','FIXTEXTEA0','FORMAT','FORMATA0','FORMATEXTENSION','FORMATEXTENSIONA0','FORMATVERSION','FORMATVERSIONA0','FORMULATION','FORMULATIONA0','FUNCTACCESS','FUNCTACCESSA0','FUNCTION','FUNCTIONA0','GROUPPROGRAM','GROUPPROGRAMA0','GROUPS','GROUPSA0','INGREDIENT','INGREDIENTA0','INSTHUBATTRIBUTE','INSTHUBATTRIBUTEA0','INSTHUBLOG','INSTHUBLOGA0','INSTHUBREAGENT','INSTHUBREAGENTA0','INSTHUBRESULT','INSTHUBRESULTA0','INSTHUBRESULTATTRIBUTE','INSTHUBRESULTATTRIBUTEA0','INSTHUBRESULTBINARY','INSTHUBRESULTBINARYA0','INSTHUBRESULTTABLEITEM','INSTHUBRESULTTABLEITEMA0','INSTRUMENT','INSTRUMENTA0','INSTRUMENTENCOMPUTER','INSTRUMENTENCOMPUTERA0','INSTRUMENTHUB','INSTRUMENTHUBA0','INSTRUMENTPARAMETER','INSTRUMENTPARAMETERA0','INSTRUMENT_ORDER','INSTRUMENT_ORDERA0','INSTRUMENT_ORDER_INFORMATION','INSTRUMENT_ORDER_INFORMATIONA0','INSTRUMENT_ORDER_MOLFILE','INSTRUMENT_ORDER_MOLFILEA0','INSTRUMENT_ORDER_RETURN',
				'INSTRUMENT_ORDER_RETURNA0','INV_CHEMICAL','INV_CHEMICALA0','INV_CHEMICALCOMPOUND','INV_CHEMICALCOMPOUNDA0','INV_CHEMICALLOG','INV_CHEMICALLOGA0','INV_CHEMICALTEMP','INV_INSTRUMENT','INV_INSTRUMENTA0','INV_INSTRUMENTLOG','INV_INSTRUMENTLOGA0','INV_INSTRUMENTTEMP','JAVACLASS','JAVACLASSA0','JOBMGRCONFIG','JOBMGRCONFIGA0','JOBPARAMS','JOBPARAMSA0','JOBS','JOBSA0','JOBSCHEDULE','JOBSCHEDULEA0','JOBSCHEDULEPARAMS','JOBSCHEDULEPARAMSA0','JOBTYPEPARAMS','JOBTYPEPARAMSA0','JOBTYPES','JOBTYPESA0','KEYWORDS','KEYWORDSA0','LABGROUP','LABGROUPA0','LABGROUPEMPLOYEE','LABGROUPEMPLOYEEA0','LABGROUPLABGROUP','LABGROUPLABGROUPA0','LABGROUPNOTIFICATIONLIST','LABGROUPNOTIFICATIONLISTA0','LABGROUPNOTIFICATIONS','LABGROUPNOTIFICATIONSA0','LANGUAGE','LANGUAGEA0','LICENSE','LICENSEA0','LIMSMAILINFORMATION','LIMSMAILINFORMATIONA0','LIMSSYSTEM','LIMSSYSTEMA0','LIMSSYSTEMINTERFACE','LIMSSYSTEMINTERFACEA0','LOCATION','LOCATIONA0','LONGTIMEARCHIVE','LONGTIMEARCHIVEA0','MAILBOX_COMPONENTRETURN','MAILBOX_COMPONENTRETURNA0','MAILBOX_MEASUREORDER','MAILBOX_MEASUREORDERA0','MAILBOX_METHOD','MAILBOX_METHODA0','MAILBOX_ORDERATTRIBUTES','MAILBOX_ORDERATTRIBUTESA0','MAILBOX_RESULTRETURN','MAILBOX_RESULTRETURNA0',
				'MAILBOX_SAMPLE','MAILBOX_SAMPLEA0','MAILBOX_STRUCTUREATTRIBUTES','MAILBOX_STRUCTUREATTRIBUTESA0','MASSIVRORDERRETURN','MASSIVR_COMMAND','MASSIVR_COMMANDA0','MB_BASIC_DATA','MB_BINARYRESULT','MB_CONNECTOR_COMMAND_QUEUE','MB_LISTS','MB_LIST_COLLECTION','MB_LIST_CONTENT','MB_MAPPING','MB_MAPPING_TEST','MB_MAPPING_TESTRESULT','MB_SCHEDULE','MB_TEST','MB_TESTA0','MB_TESTREQUEST','MB_TESTREQUESTA0','MB_TESTRESULT','MB_TESTRESULTA0','MB_TRANSACTIONRESULT','MB_WHERE_CONFIG','MEASUREORDER','MEASUREORDERA0','MEASUREORDERA0L0','MEASUREORDERA0L0A0','MEASUREORDERL0','MEASUREORDERL0A0','MESSAGE','MESSAGEA0','MESSAGEATTRIBUTE','MESSAGEATTRIBUTEA0','MESSAGES','MESSAGESA0','MESSPARAMETER','MESSPARAMETERA0','METADATA','METADATAA0','METHODE','METHODEA0','METHODEXPERTSYSTEM','METHODEXPERTSYSTEMA0','METHODFILE','METHODFILEA0','METHODGROUP','METHODGROUPA0','METHODGROUPDETAIL','METHODGROUPDETAILA0','METHODLABGROUP','METHODLABGROUPA0','METHODPARTSLIST','METHODPARTSLISTA0','METHODPREPARATION','METHODPREPARATIONA0','METHODRESULTTYPE','METHODRESULTTYPEA0','METHODRESULTTYPECOMPONENT','METHODRESULTTYPECOMPONENTA0','METHODSUMMARY','METHODSUMMARYA0','METHODTOPTENLIST','METHODTOPTENLISTA0','MLOG$_MEASUREORDER',
				'MLOG$_MO_ORDERATTRIBUTES','MLOG$_MO_PARAMETERTAB','MODUL','MODULA0','MOTIVATION','MOTIVATIONA0','MO_ANALYSISMETHODSELECTION','MO_ANALYSISMETHODSELECTIONA0','MO_ANALYSISMETHODSELECTIONA0L0','MO_ANALYSISMETHODSELECTIONL0','MO_ANALYSISMETHODSELECTIONL0A0','MO_AO','MO_AOA0','MO_AOA0L0','MO_AOA0L0A0','MO_AOL0','MO_AOL0A0','MO_CODEWORDS','MO_CODEWORDSA0','MO_CODEWORDSA0L0','MO_CODEWORDSA0L0A0','MO_CODEWORDSL0','MO_CODEWORDSL0A0','MO_COSTS','MO_COSTSA0','MO_COSTSA0L0','MO_COSTSA0L0A0','MO_COSTSL0','MO_COSTSL0A0','MO_INSTRUMENT_PARAMETER','MO_INSTRUMENT_PARAMETERA0','MO_INSTRUMENT_RESULTS','MO_INSTRUMENT_RESULTSA0','MO_INSTRUMENT_RETURNS','MO_INSTRUMENT_RETURNSA0','MO_INSTR_PARAM_RETURN','MO_INSTR_PARAM_RETURNA0','MO_LINK','MO_LINKA0','MO_LO','MO_LOA0','MO_LOA0L0','MO_LOA0L0A0','MO_LOL0','MO_LOL0A0','MO_LO_COSTS','MO_LO_COSTSA0','MO_LO_COSTSA0L0','MO_LO_COSTSA0L0A0','MO_LO_COSTSL0','MO_LO_COSTSL0A0','MO_LO_SAMPLE','MO_LO_SAMPLEA0','MO_LO_SAMPLEA0L0','MO_LO_SAMPLEA0L0A0','MO_LO_SAMPLEL0','MO_LO_SAMPLEL0A0','MO_MEASURESAMPLE','MO_MEASURESAMPLEA0','MO_MEASURESAMPLEA0L0','MO_MEASURESAMPLEA0L0A0','MO_MEASURESAMPLEL0','MO_MEASURESAMPLEL0A0','MO_METADATACONFIG','MO_METADATACONFIGA0','MO_METHOD',
				'MO_METHODA0','MO_METHODA0L0','MO_METHODA0L0A0','MO_METHODL0','MO_METHODL0A0','MO_METHODMODULE','MO_METHODMODULEA0','MO_METHODMODULEA0L0','MO_METHODMODULEA0L0A0','MO_METHODMODULEEXPORT','MO_METHODMODULEEXPORTA0','MO_METHODMODULEEXPORTA0L0','MO_METHODMODULEEXPORTA0L0A0','MO_METHODMODULEEXPORTL0','MO_METHODMODULEEXPORTL0A0','MO_METHODMODULEL0','MO_METHODMODULEL0A0','MO_METHODSTRUCTURE','MO_METHODSTRUCTUREA0','MO_METHODSTRUCTUREA0L0','MO_METHODSTRUCTUREA0L0A0','MO_METHODSTRUCTUREL0','MO_METHODSTRUCTUREL0A0','MO_MOLFILE','MO_MOLFILEA0','MO_ORDERATTRIBUTES','MO_ORDERATTRIBUTESA0','MO_ORDERATTRIBUTESA0L0','MO_ORDERATTRIBUTESA0L0A0','MO_ORDERATTRIBUTESL0','MO_ORDERATTRIBUTESL0A0','MO_ORDERMETHGROUP','MO_ORDERMETHGROUPA0','MO_ORDERMODIFIERS','MO_ORDERMODIFIERSA0','MO_PARAMETER','MO_PARAMETERA0','MO_PARAMETERA0L0','MO_PARAMETERA0L0A0','MO_PARAMETERL0','MO_PARAMETERL0A0','MO_PARAMETERTAB','MO_PARAMETERTABA0','MO_PROJECT','MO_PROJECTA0','MO_PROJECTA0L0','MO_PROJECTA0L0A0','MO_PROJECTL0','MO_PROJECTL0A0','MO_PUBLISHORDER','MO_PUBLISHORDERA0','MO_RDFILE','MO_RDFILEA0','MO_RDFILEA0L0','MO_RDFILEA0L0A0','MO_RDFILEL0','MO_RDFILEL0A0','MO_RDVERSION','MO_RDVERSIONA0','MO_RDVERSIONA0L0',
				'MO_RDVERSIONA0L0A0','MO_RDVERSIONL0','MO_RDVERSIONL0A0','MO_RD_STRUCTURE','MO_RD_STRUCTUREA0','MO_RD_STRUCTUREA0L0','MO_RD_STRUCTUREA0L0A0','MO_RD_STRUCTUREL0','MO_RD_STRUCTUREL0A0','MO_REFERENCES_RESULTS','MO_REFERENCES_RESULTSA0','MO_REFERENCES_RESULTSA0L0','MO_REFERENCES_RESULTSA0L0A0','MO_REFERENCES_RESULTSL0','MO_REFERENCES_RESULTSL0A0','MO_RESULTDETAILSPECTRUM','MO_RESULTDETAILSPECTRUMA0','MO_RESULTDETAILSPECTRUMA0L0','MO_RESULTDETAILSPECTRUMA0L0A0','MO_RESULTDETAILSPECTRUML0','MO_RESULTDETAILSPECTRUML0A0','MO_RESULTEVALUATION','MO_RESULTEVALUATIONA0','MO_RESULTEVALUATIONA0L0','MO_RESULTEVALUATIONA0L0A0','MO_RESULTEVALUATIONL0','MO_RESULTEVALUATIONL0A0','MO_RESULT_3DSPECTRUMDETAIL','MO_RESULT_3DSPECTRUMDETAILA0','MO_RESULT_3DSPECTRUMHEADER','MO_RESULT_3DSPECTRUMHEADERA0','MO_RESULT_BINARY','MO_RESULT_BINARYA0','MO_RESULT_BINARYA0L0','MO_RESULT_BINARYA0L0A0','MO_RESULT_BINARYL0','MO_RESULT_BINARYL0A0','MO_RESULT_CHROMATOGRAM','MO_RESULT_CHROMATOGRAMA0','MO_RESULT_CHROMATOGRAMA0L0','MO_RESULT_CHROMATOGRAMA0L0A0','MO_RESULT_CHROMATOGRAML0','MO_RESULT_CHROMATOGRAML0A0','MO_RESULT_COMPONENT','MO_RESULT_COMPONENTA0','MO_RESULT_COMPONENTA0L0','MO_RESULT_COMPONENTA0L0A0',
				'MO_RESULT_COMPONENTL0','MO_RESULT_COMPONENTL0A0','MO_RESULT_HEADER','MO_RESULT_HEADERA0','MO_RESULT_HEADERA0L0','MO_RESULT_HEADERA0L0A0','MO_RESULT_HEADERL0','MO_RESULT_HEADERL0A0','MO_RESULT_MULTI_DETAIL','MO_RESULT_MULTI_DETAILA0','MO_RESULT_MULTI_DETAILA0L0','MO_RESULT_MULTI_DETAILA0L0A0','MO_RESULT_MULTI_DETAILL0','MO_RESULT_MULTI_DETAILL0A0','MO_RESULT_PEAKINFORMATION','MO_RESULT_PEAKINFORMATIONA0','MO_RESULT_PEAKINFORMATIONA0L0','MO_RESULT_PEAKINFORMATIONL0','MO_RESULT_PEAKINFORMATIONL0A0','MO_RESULT_SPECTRUM','MO_RESULT_SPECTRUMA0','MO_RESULT_SPECTRUMA0L0','MO_RESULT_SPECTRUMA0L0A0','MO_RESULT_SPECTRUML0','MO_RESULT_SPECTRUML0A0','MO_RESULT_TEXT','MO_RESULT_TEXTA0','MO_RESULT_TEXTA0L0','MO_RESULT_TEXTA0L0A0','MO_RESULT_TEXTL0','MO_RESULT_TEXTL0A0','MO_REVIEW','MO_REVIEWA0','MO_SAMPLE','MO_SAMPLEA0','MO_SAMPLEA0L0','MO_SAMPLEA0L0A0','MO_SAMPLEL0','MO_SAMPLEL0A0','MO_SEQUENCEPARAMETER','MO_SEQUENCEPARAMETERA0','MO_SEQUENCEPARAMETERA0L0','MO_SEQUENCEPARAMETERA0L0A0','MO_SEQUENCEPARAMETERL0','MO_SEQUENCEPARAMETERL0A0','MO_SEQUENCETEMPLATE','MO_SEQUENCETEMPLATEA0','MO_SEQUENCETEMPLATEA0L0','MO_SEQUENCETEMPLATEA0L0A0','MO_SEQUENCETEMPLATEL0','MO_SEQUENCETEMPLATEL0A0',
				'MO_SIGN','MO_SIGNA0','MO_STRUCTUREASSIGNMENT','MO_STRUCTUREASSIGNMENTA0','MO_STRUCTUREASSIGNMENTA0L0','MO_STRUCTUREASSIGNMENTA0L0A0','MO_STRUCTUREASSIGNMENTL0','MO_STRUCTUREASSIGNMENTL0A0','MO_STRUCTURE_SPECINFORESULTS','MO_STRUCTURE_SPECINFORESULTSA0','MO_SUBSTANCE','MO_SUBSTANCEA0','MO_SUBSTANCEA0L0','MO_SUBSTANCEA0L0A0','MO_SUBSTANCEL0','MO_SUBSTANCEL0A0','MO_WORKLIST','MO_WORKLISTA0','MO_WORKLISTA0L0','MO_WORKLISTA0L0A0','MO_WORKLISTL0','MO_WORKLISTL0A0','MSGHEADER','MSGHEADERA0','MSGITEM','MSGITEMA0','MSGVALUE','MSGVALUEA0','NOTIFICATION','NOTIFICATIONA0','NOTIFICATIONLIST','NOTIFICATIONLISTA0','OPENORDERS','OPERATINGSYSTEM','OPERATINGSYSTEMA0','ORDERATTRIBUTES','ORDERATTRIBUTESA0','ORDERATTRIBUTESTYPE','ORDERATTRIBUTESTYPEA0','ORDERATTRIBUTES_TEXTINFO','ORDERATTRIBUTES_TEXTINFOA0','ORDERTYPE','ORDERTYPEA0','ORDERTYPEMETHODSASSIGN','ORDERTYPEMETHODSASSIGNA0','ORDERTYPERESULTTYPES','ORDERTYPERESULTTYPESA0','ORDERTYPEWEBMETHODS','ORDERTYPEWEBMETHODSA0','ORDERTYPE_LO','ORDERTYPE_LOA0','PHYSICALSAMPLE','PHYSICALSAMPLEA0','PHYSICALSAMPLETEMP','PREPARATION','PREPARATIONA0','PREPARATIONLABGROUP','PREPARATIONLABGROUPA0','PREPARATIONSTEPS','PREPARATIONSTEPSA0','PRINTER','PRINTERA0',
				'PRODUCT','PRODUCTA0','PRODUCTCATEGORY','PRODUCTCATEGORYA0','PRODUCTTEMP','PROGRAMCONFIGURATION','PROGRAMCONFIGURATIONA0','PROJECT','PROJECTA0','PROJECTTEMPLATE','PROJECTTEMPLATEA0','PROJECTUSER','PROJECTUSERA0','PROJECT_DOCUMENT','PROJECT_DOCUMENTA0','PROJECT_ENTWICKLUNGSPLAN','PROJECT_ENTWICKLUNGSPLANA0','PROJECT_LO','PROJECT_LOA0','PROJECT_RESULT','PROJECT_RESULTA0','PROTECTIONPERIOD','PROTECTIONPERIODA0','PUBLICFILTERS','QDDPROJECT','QDDPROJECTA0','QDISCCNR','QDISRQMINTERFACE','QDISRQMINTERFACEA0','QDISSQL','REFERENCESPECTRA','REFERENCESPECTRAA0','RENDITION','RENDITIONA0','REPORTCOMMENTS','REPORTCOMMENTSA0','REPORTCONFIGLABGROUP','REPORTCONFIGLABGROUPA0','REPORTCONFIGLIBRARY','REPORTCONFIGLIBRARYA0','REPORTCONFIGURATION','REPORTCONFIGURATIONA0','REPORTLABELS','REPORTLABELSA0','REPORTLAYOUT','REPORTLAYOUTA0','REPORTMETHODSVALUES','REPORTMETHODSVALUESA0','REPORTORDERSVALUES','REPORTORDERSVALUESA0','REPORTPARAMETERS','REPORTPARAMETERSA0','REPORTPICTURES','REPORTPICTURESA0','REQUESTSAMPLE','REQUESTSAMPLEA0','RESULTHIERARCHY','RESULTHIERARCHYA0','RESULTREQUIREMENTDEF','RESULTREQUIREMENTDEFA0','RESULTTYPE','RESULTTYPEA0','RESULTUNIT','RESULTUNITA0','RETRIEVERESULTLIST',
				'RETRIEVERESULTLISTA0','SAMPLEATTRIBUTE','SAMPLEATTRIBUTEA0','SAMPLEQUALITY','SAMPLEQUALITYA0','SAMPLETEMPLATE','SAMPLETEMPLATEA0','SAMPLETEMPLATETEMP','SAMPLETEMPLLABGROUP','SAMPLETEMPLLABGROUPA0','SAMPLETEMPLRESREQUIREMENT','SAMPLETEMPLRESREQUIREMENTA0','SAMPLETEMPLSIGN','SAMPLETEMPLSIGNA0','SAMPLETEMPLTEST','SAMPLETEMPLTESTA0','SAMPLETEMPLTESTRESULT','SAMPLETEMPLTESTRESULTA0','SCREENLAYOUTCONFIGURATION','SCREENLAYOUTCONFIGURATIONA0','SCREENPROGRAM','SCREENPROGRAMA0','SEARCHCRITERIA','SEARCHCRITERIAA0','SEQUENCETEMPLATE','SEQUENCETEMPLATEA0','SEQUENCETEMPLATEPARAMETER','SEQUENCETEMPLATEPARAMETERA0','SERVICEPROVIDER','SERVICEPROVIDERA0','SERVICEPROVIDERMETA','SERVICEPROVIDERMETAA0','SERVICEPROVIDERSERVICE','SERVICEPROVIDERSERVICEA0','SIGNTEMPLATE','SIGNTEMPLATEA0','SIGNTMPLHEADER','SIGNTMPLHEADERA0','SLIMLWR','SMMETHOD','SMMETHODA0','SMMETHODLABGROUP','SMMETHODLABGROUPA0','SMMETHODRESREQUIREMENT','SMMETHODRESREQUIREMENTA0','SMMETHODSIGN','SMMETHODSIGNA0','SMMETHODTEMP','SMMETHODTEST','SMMETHODTESTA0','SMMETHODTESTRESULT','SMMETHODTESTRESULTA0','SOFTWARE','SOFTWAREA0','SOFTWAREFORMAT','SOFTWAREFORMATA0','SPECIFICATION','SPECIFICATIONA0','SPECIFICATIONATTRIBUTE','SPECIFICATIONATTRIBUTEA0',
				'SPECIFICATIONLABGROUP','SPECIFICATIONLABGROUPA0','SPECIFICATIONSAMPLETEMPLATE','SPECIFICATIONSAMPLETEMPLATEA0','SPECIFICATIONSIGN','SPECIFICATIONSIGNA0','SPECIFICATIONTEMP','SPECIFICATIONTEST','SPECIFICATIONTESTA0','SPECIFICATIONTESTRESULT','SPECIFICATIONTESTRESULTA0','SPECIFICATIONVARIANT','SPECIFICATIONVARIANTA0','SPECRESULTREQUIREMENT','SPECRESULTREQUIREMENTA0','STATUS','STATUSA0','STATUSTYPE','STATUSTYPEA0','STRUCTUREATTRIBUTES','STRUCTUREATTRIBUTESA0','STRUCTURES_DATA','STRUCTURES_DATAA0','STRUCTURES_HEADER','STRUCTURES_HEADERA0','SUBMISSION','SUBMISSIONA0','SUBMISSIONSAMPLE','SUBMISSIONSAMPLEA0','SUBMISSIONTEMP','SUBMISSIONTEMPLATE','SUBMISSIONTEMPLATEA0','SUBMISSIONTEMPLATELIST','SUBMISSIONTEMPLATELISTA0','SUBMISSIONTEMPLTEMP','SUBMISSIONTEST','SUBMISSIONTESTA0','SUBMISSIONTESTRESULT','SUBMISSIONTESTRESULTA0','SUBMISSIONTESTRESULTREQ','SUBMISSIONTESTRESULTREQA0','SUBSTANCE','SUBSTANCEA0','SYSTEMTYPE','SYSTEMTYPEA0','SYSTEMVALUES','SYSTEMVALUESA0','TEST','TESTA0','TESTATTRIBUTE','TESTATTRIBUTEA0','TESTDEFINITION','TESTDEFINITIONA0','TESTGROUPMETHODPREPARATION','TESTGROUPMETHODPREPARATIONA0','TESTLOG','TESTLOGA0','TESTREQUEST','TESTREQUESTA0',
				'TESTREQUESTATTRIBUTE','TESTREQUESTATTRIBUTEA0','TESTREQUESTSIGN','TESTREQUESTSIGNA0','TESTREQUESTTEMP','TESTRESULT','TESTRESULTA0','TESTRESULTATTRIBUTE','TESTRESULTATTRIBUTEA0','TESTRESULTDEFINITION','TESTRESULTDEFINITIONA0','TESTRESULTREQTEMPLATE','TESTRESULTREQTEMPLATEA0','TESTRESULTREQUIREMENT','TESTRESULTREQUIREMENTA0','TESTRESULTTEMPLATE','TESTRESULTTEMPLATEA0','TESTSAMPLE','TESTSAMPLEA0','TESTTEMP','THUMBNAILS','THUMBNAILSA0','UICONFIGURATION','UICONFIGURATIONA0','UPLOADTEMPLATEFIELDS','UPLOADTEMPLATEFIELDSA0','UPLOADTEMPLATEHEADER','UPLOADTEMPLATEHEADERA0','UPLOADTEMPLATES','UPLOADTEMPLATESA0','USERATTRIBUTES','USERATTRIBUTESA0','USERLOG','USERLOGA0','USERMESSAGE','USERMESSAGEA0','USERPREFERENCES','USERPREFERENCESA0','USERPROGLOG','USERPROGLOGA0','USERS','USERSA0','USERSSIGNINFO','USERSSIGNINFOA0','USERTRAINING','USERTRAININGA0','USERTRAININGLOG','USERTRAININGLOGA0','WEBSESSIONS','WEBSESSIONSA0','WHERECONDITION','WHERECONDITIONA0','WORKLIST','WORKLISTA0','INV_INSTRUMENTATTRIBUTE','INV_INSTRUMENTATTRIBUTEA0','INV_CHEMICALATTRIBUTE','INV_CHEMICALATTRIBUTEA0','INV_INSTRUMENT_SYSTEM','INV_INSTRUMENT_SYSTEMA0','INV_INSTRUMENT_EXTENDED','INV_INSTRUMENT_EXTENDEDA0','MRULIST','MRULISTA0',
				'INV_INSTRUMENT_HUB','INV_INSTRUMENT_HUBA0');
				IF(:v_LMSSchemaVerAsNum >= 9201)		THEN -- ELNPROD table list for NG 9.2 hotfix 1 and 9.3.
					t_TableList(t_TableList.LAST) := 'INV_INSTRUMENT_SYNC'; -- Table inv_instrument_huba0 was deleted.  Replace it with inv_instrument_sync which is new in 9.2 HF1.
				END IF;
			END IF;
		END IF;
		v_ExpectedNo := t_TableList.COUNT;
		
		SELECT COUNT(*) INTO v_Count FROM DBA_TABLES WHERE OWNER = v_SchemaName AND table_name NOT LIKE 'BIN$%' AND table_name NOT LIKE 'SYS_EXPORT%' AND table_name NOT LIKE 'SYS_IMPORT%' AND table_name NOT LIKE 'DMP_%';
		IF (v_Count < v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: fewer than the expected number of tables are in the '||v_SchemaName||' schema ('||v_ExpectedNo||' expected, '||v_Count||' found)!');
		ELSIF (v_Count = v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('The expected number of tables are in the '||v_SchemaName||' schema ('||v_ExpectedNo||' expected, '||v_Count||' found).');
		ELSIF (v_Count > v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('More than the expected number of tables are in the '||v_SchemaName||' schema ('||v_ExpectedNo||' expected, '||v_Count||' found)');
		END IF;

		FOR indx IN 1 .. t_TableList.COUNT
		LOOP
			v_TableName := t_TableList(indx);
			SELECT COUNT(*) INTO v_Count FROM dba_tables WHERE owner = v_SchemaName AND table_name = v_TableName;
			IF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE(' -- !!!!! ERROR: table '||v_SchemaName||'.'||v_TableName||' is NOT present!');
			ELSIF (v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE(' -- Table: '||v_SchemaName||'.'||v_TableName||' is present');
			END IF;
		END LOOP;
		DBMS_OUTPUT.PUT_LINE ('.');
	END LOOP;
END;
/

col table_name format a40
col partitioned format a12
col temporary format a12
PROMPT
PROMPT List of NuGenesis tables:
SELECT owner, table_name, status, logging "Logging", partitioned "Partitioned", temporary "Temp_table" FROM dba_tables WHERE owner IN ('NGSDMS60','NGSYSUSER','ELNPROD') ORDER by owner, table_name;

PROMPT
PROMPT
PROMPT _________________________________________________________________________________________________
PROMPT Checking for partitioned tables in the NuGenesis schemas...
PROMPT
DECLARE
v_Count		PLS_INTEGER;
v_tab		VARCHAR2(30);
v_Owner		VARCHAR2(100);

CURSOR C_PART IS SELECT TABLE_NAME, owner FROM DBA_TABLES WHERE OWNER IN ('NGSDMS60', 'NGSYSUSER', 'ELNPROD') AND PARTITIONED = 'YES';

BEGIN
	SELECT COUNT(TABLE_NAME) INTO v_Count FROM DBA_TABLES WHERE OWNER IN ('NGSDMS60', 'NGSYSUSER', 'ELNPROD') AND PARTITIONED = 'YES';
	DBMS_OUTPUT.PUT_LINE('Number of partitioned tables in the NuGenesis schemas: '||v_Count);
	IF v_Count > 0 THEN
		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('Partitioned tables are listed below:');
		OPEN C_PART;
		LOOP
			FETCH C_PART INTO v_tab, v_Owner;
			EXIT WHEN C_PART%NOTFOUND;

			DBMS_OUTPUT.PUT_LINE('-- '||v_Owner||'.'||v_tab);
		END LOOP;
		CLOSE C_PART;
	END IF;
END;
/
COLUMN TABLE_NAME FORMAT A30
SELECT TABLE_NAME, PARTITIONING_TYPE, PARTITION_COUNT, STATUS FROM DBA_PART_TABLES WHERE OWNER IN ('NGSDMS60','NGSYSUSER','ELNPROD');

PROMPT
PROMPT _________________________________________________________________________________________________
PROMPT Checking for the DR$...$U tables in the NuGenesis schemas
PROMPT These tables are necessary for Oracle Text indexes in Oracle 12c but may be missing if the database was migrated from 11g.
PROMPT
DECLARE
v_Count		PLS_INTEGER;
v_ExpectedNo	PLS_INTEGER;

BEGIN
	SELECT COUNT(TABLE_NAME) INTO v_Count FROM dba_tables WHERE owner IN ('NGSDMS60') AND table_name = 'DR$ADVANCE_SEARCH$U';
	IF (v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('The NGSDMS60.DR$ADVANCE_SEARCH$U table is present.');
	ELSIF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('!!! WARNING: The NGSDMS60.DR$ADVANCE_SEARCH$U table is NOT present!  The advance search function in WebVision will not work if this table is not present.  Contact Waters Technical Support for a copy of the SDMS advance_search index rebuild procedure.');
	END IF;

	v_ExpectedNo := 20;
	DBMS_OUTPUT.PUT_LINE ('.');
	SELECT COUNT(TABLE_NAME) INTO v_Count FROM dba_tables WHERE owner IN ('ELNPROD') AND table_name LIKE 'DR$%$U';
	IF (v_Count = v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('ELNPROD has the expected number of DR$..$U tables ('||v_ExpectedNo||' expected, '||v_Count||' found).');
	ELSIF (v_Count < v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('!!! WARNING: elnprod has less than the expected number of DR$..$U tables ('||v_ExpectedNo||' expected, '||v_Count||' found).  One or more of the content search functions in LMS will not work!  Contact Waters technical support for a copy of the LMS advance_search index rebuild procedure..');
	END IF;
END;
/

PROMPT
PROMPT _________________________________________________________________________________________________
PROMPT Checking for leftover SYS_IMPORT/SYS_EXPORT tables in the NuGenesis schemas
PROMPT These tables are left over from a database export or import and can be dropped
PROMPT
DECLARE
v_Count		PLS_INTEGER;
v_Owner		VARCHAR2(100);
v_TableName	VARCHAR2(100);
v_ExpectedNo		PLS_INTEGER;

CURSOR C_SysExpImpTables IS	SELECT owner, table_name FROM dba_tables WHERE owner IN ('NGSDMS60','NGSYSUSER','ELNPROD') AND (table_name LIKE 'SYS_IMPORT%' OR table_name LIKE 'SYS_EXPORT%');

BEGIN
	SELECT COUNT(TABLE_NAME) INTO v_Count FROM dba_tables WHERE owner IN ('NGSDMS60','NGSYSUSER','ELNPROD') AND (table_name LIKE 'SYS_IMPORT%' OR table_name LIKE 'SYS_EXPORT%');
	IF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('There are no SYS_EXPORT or SYS_IMPORT tables in the NuGenesis schemas.');
	ELSIF (v_Count > 0)	THEN
		DBMS_OUTPUT.PUT_LINE('WARNING: There are '||v_Count||' SYS_IMPORT or SYS_EXPORT table(s) in the NuGenesis schemas.  These tables should be dropped:');
		OPEN C_SysExpImpTables;
		LOOP
			FETCH C_SysExpImpTables INTO v_Owner, v_TableName;
			EXIT WHEN C_SysExpImpTables%NOTFOUND;

			DBMS_OUTPUT.PUT_LINE('-- '||v_Owner||'.'||v_TableName);
		END LOOP;
		CLOSE C_SysExpImpTables;
	END IF;
END;
/

PROMPT
PROMPT _________________________________________________________________________________________________
PROMPT Checking for leftover CMP3$ and CMP4$ tables in the NuGenesis schemas.
PROMPT These tables are left over from a Compression Advisor background job and can be dropped.
PROMPT
DECLARE
v_Count		PLS_INTEGER;
v_Owner		VARCHAR2(100);
v_TableName	VARCHAR2(100);
v_ExpectedNo		PLS_INTEGER;

CURSOR C_CmpTables IS	SELECT owner, table_name FROM dba_tables WHERE owner IN ('NGSDMS60','NGSYSUSER','ELNPROD') AND (table_name LIKE 'CMP%');

BEGIN
	SELECT COUNT(*) INTO v_Count FROM dba_tables WHERE owner IN ('NGSDMS60','NGSYSUSER','ELNPROD') AND (table_name LIKE 'CMP%');
	IF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('There are no CMP3$/CMP4$ tables in the NuGenesis schemas.');
	ELSIF (v_Count > 0)	THEN
		DBMS_OUTPUT.PUT_LINE('WARNING: There are '||v_Count||' CMP$ table(s) in the NuGenesis schemas.  These tables should be dropped:');
		OPEN C_CmpTables;
		LOOP
			FETCH C_CmpTables INTO v_Owner, v_TableName;
			EXIT WHEN C_CmpTables%NOTFOUND;

			DBMS_OUTPUT.PUT_LINE('-- '||v_Owner||'.'||v_TableName);
		END LOOP;
		CLOSE C_CmpTables;
	END IF;
END;
/

PROMPT
PROMPT _________________________________________________________________________________________________
PROMPT Checking the NuGenesis schemas for tables in NOLOGGING mode

DECLARE
v_Count		PLS_INTEGER;	
v_Owner		dba_tables.owner%TYPE;
v_TableName	dba_tables.table_name%TYPE;

CURSOR C_NoLoggingTables IS	SELECT owner, table_name FROM dba_tables WHERE owner IN ('ELNPROD','NGSDMS60','NGSYSUSER') AND table_name NOT LIKE ('DR$%') AND TEMPORARY = 'N' AND LOGGING = 'NO';

BEGIN
	SELECT COUNT(TABLE_NAME) INTO v_Count FROM dba_tables WHERE owner IN ('ELNPROD','NGSDMS60','NGSYSUSER') AND TABLE_NAME NOT LIKE ('DR$%') AND TEMPORARY = 'N' AND LOGGING = 'NO';
	IF v_Count = 0 THEN	DBMS_OUTPUT.PUT_LINE('All tables in the NuGenesis schemas are in LOGGING mode.');
	ELSE
		DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: '||v_Count||' table(s) in the NuGenesis schemas have the NOLOGGING attribute!  The presence of NOLOGGING Tables can result in unrecoverable backups!  The NOLOGGING tables are listed below:');
		OPEN C_NoLoggingTables;
		LOOP
			FETCH C_NologgingTables INTO v_Owner, v_TableName;
			EXIT WHEN C_NoLoggingTables%NOTFOUND;

			DBMS_OUTPUT.PUT_LINE('-- '||v_Owner||'.'||v_TableName);
		END LOOP;
		CLOSE C_NoLoggingTables;
	END IF;
END;
/

PROMPT
PROMPT
PROMPT _________________________________________________________________________________________________
PROMPT Checking the auditing tables in the elnprod schema...
PROMPT

DECLARE
v_cnt		PLS_INTEGER;
v_Count		PLS_INTEGER := 0;
v_tableName	dba_tables.table_name%TYPE;
v_ExpectedNo	PLS_INTEGER;

CURSOR C_LMSDataTables IS SELECT table_name FROM dba_tables WHERE owner = 'ELNPROD' AND table_name NOT LIKE '%A0' AND table_name NOT LIKE '%L0' AND table_name NOT LIKE 'DR$%' AND temporary = 'N' AND table_name NOT LIKE 'MLOG$%' AND table_name NOT LIKE 'MB%' AND table_name NOT LIKE 'QDIS%' AND table_name NOT LIKE 'ELAB%' AND table_name NOT LIKE 'SYS_%' AND table_name NOT IN ('OPENORDERS','PUBLICFILTERS','SLIMLWR','MASSIVRORDERRETURN','APPENDIX');

BEGIN
	SELECT COUNT(TABLE_NAME) INTO v_Count FROM DBA_TABLES WHERE OWNER = 'ELNPROD' AND table_name NOT LIKE '%A0' AND table_name NOT LIKE '%L0' AND table_name NOT LIKE 'DR$%' AND temporary = 'N' AND table_name NOT LIKE 'MLOG$%' AND table_name NOT LIKE 'MB%' AND table_name NOT LIKE 'QDIS%'  AND table_name NOT LIKE 'ELAB%' AND table_name NOT LIKE 'SYS_%' AND table_name NOT IN ('OPENORDERS','PUBLICFILTERS','SLIMLWR','MASSIVRORDERRETURN','APPENDIX');
	DBMS_OUTPUT.PUT_LINE('Number of auditing tables: '||v_Count);
	DBMS_OUTPUT.PUT_LINE('Any auditing tables missing from the elnprod schema will be listed below . . .');

	OPEN C_LMSDataTables;
	LOOP
		FETCH C_LMSDataTables INTO v_TableName;
		EXIT WHEN C_LMSDataTables%NOTFOUND;

		v_TableName := v_TableName ||'A0';
		SELECT COUNT(*) INTO v_Count FROM dba_tables WHERE owner = 'ELNPROD' AND table_name = v_TableName;
		IF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('-- Audit table '||v_TableName||' is missing');
		END IF;
	END LOOP;
	CLOSE C_LMSDataTables;
END;
/

PROMPT
PROMPT ___________________________________________________________________________________________________________
PROMPT Determining whether the NuGenesis schemas own the expected synonyms...
PROMPT

DECLARE
v_Count			PLS_INTEGER := 0;
v_ExpectedNo		PLS_INTEGER;
v_ObjName		dba_synonyms.synonym_name%TYPE;
v_ObjStatus		dba_objects.status%TYPE;
v_SynTableOwner		dba_synonyms.table_owner%TYPE;
v_SynTableName		dba_synonyms.table_name%TYPE;
v_SchemaNAme		VARCHAR2(100);
TYPE ObjList		IS TABLE OF VARCHAR2(500);
t_SchemaList		ObjList;
t_Synonyms		ObjList;
t_SynTabOwners		OBjList;
t_SynTabNames		ObjList;

BEGIN
	t_SchemaList      := ObjList('NGSDMS60','NGSYSUSER','ELNPROD');
	FOR indx2 IN 1 .. t_SchemaList.COUNT
	LOOP
		v_SchemaName := t_SchemaList(indx2);
		IF(v_schemaName = 'NGSYSUSER')	THEN
			t_Synonyms     := ObjList('VP_ALL_TAB_COLUMNS','VP_ELN_CREATE_LGE_SYN','VP_ELN_CREATE_USER','VP_ELN_DELETE_LGE_SYN','VP_ELN_DELETE_USER','VP_ELN_GET_BUILD_INFO_SYN','VP_ELN_UPDATE_LGE_SYN','VP_ELN_UPDATE_USER','VP_ELN_UPDATE_USER_OTHER_P_S','VP_EMPLOYEE_SYN','VP_FUNCTION_SYN','VP_GROUPS_SYN','VP_LABGROUPEMPLOYEE_SYN','VP_LABGROUP_SYN','VP_USERS_SYN');
			t_SynTabOwners := ObjList('NGSYSUSER','ELNPROD','ELNPROD','ELNPROD','ELNPROD','ELNPROD','ELNPROD','ELNPROD','ELNPROD','ELNPROD','ELNPROD','ELNPROD','ELNPROD','ELNPROD','ELNPROD');
			t_SynTabNames  := ObjList('ALL_TAB_COLUMNS','ELN_CREATE_LABGROUPEMPLOYEE','ELN_CREATE_USER','ELN_DELETE_LABGROUPEMPLOYEE','ELN_DELETE_USER','ELN_GET_BUILD_INFO','ELN_UPDATE_LABGROUPEMPLOYEE','ELN_UPDATE_USER','ELN_UPDATE_USER_OTHER_PROPS','EMPLOYEE','FUNCTION','GROUPS','LABGROUPEMPLOYEE','LABGROUP','USERS');
		ELSE
			t_Synonyms     := ObjList();
			t_SynTabOwners := ObjList();
			t_SynTabNames  := ObjList();
		END IF;
		v_ExpectedNo := t_Synonyms.COUNT;

		SELECT COUNT(*) INTO v_Count FROM dba_synonyms WHERE owner = v_SchemaName;
		IF (v_Count = v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE(v_SchemaName||' owns the expected number of synonyms ('||v_ExpectedNo||' expected, '||v_Count||' found)');
		ELSIF (v_Count < v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: '||v_SchemaName||' owns less than the expected number of synonyms ('||v_ExpectedNo||' expected, '||v_Count||' found)!');
		ELSIF (v_Count > v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('WARNING: '||v_SchemaName||' owns more than the expected number of synonyms ('||v_ExpectedNo||' expected, '||v_Count||' found)');
		END IF;

		FOR indx IN 1 .. t_Synonyms.COUNT
		LOOP
			v_ObjName := t_Synonyms(indx);
			SELECT COUNT(*) INTO v_Count FROM dba_synonyms WHERE owner = v_SchemaName AND synonym_name = v_ObjName;
			IF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: '||v_SchemaName||' does not have the synonym: '||v_ObjName);
			ELSIF (v_Count = 1)	THEN
				DBMS_OUTPUT.PUT_LINE('-- Synonym '||v_SchemaName||'.'||v_ObjName||' is present');
				SELECT status INTO v_ObjStatus FROM dba_objects WHERE owner = v_SchemaName AND object_name = v_ObjName AND object_Type = 'SYNONYM';
				IF (v_ObjStatus != 'VALID')	THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: the synonym is not valid!');
				ELSE					DBMS_OUTPUT.PUT_LINE('-- the synonym is valid');
				END IF;

				SELECT table_owner, table_name INTO v_SynTableOwner, v_SynTableName FROM dba_synonyms WHERE owner = v_SchemaName AND synonym_name = v_ObjName;
				IF(v_SynTableOwner != t_SynTabOwners(indx) OR v_SynTableName != t_SynTabNames(indx))	THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: the synonym is not correctly defined!  It must point to the table '||t_SynTabOwners(indx)||'.'||t_SynTabNames(indx)||'!');
				ELSE												DBMS_OUTPUT.PUT_LINE('-- the synonym is correctly defined to the table '||t_SynTabOwners(indx)||'.'||t_SynTabNames(indx));
				END IF;
			END IF;
			DBMS_OUTPUT.PUT_LINE ('.');
		END LOOP;
		DBMS_OUTPUT.PUT_LINE ('.');
	END LOOP;
END;
/

col synonym_name format a30
col db_link format a20
PROMPT
PROMPT List of synonyms owned by the NuGenesis schemas:
SELECT owner, synonym_name, table_owner, table_name, db_link FROM dba_synonyms WHERE owner IN ('NGSDMS60','NGSYSUSER','ELNPROD') ORDER BY 1,2;

PROMPT
PROMPT ___________________________________________________________________________________________________________
PROMPT Determining if the NuGenesis schema accounts own the expected of views
PROMPT
PROMPT

DECLARE
v_Count			PLS_INTEGER := 0;
v_ExpectedNo		PLS_INTEGER;
v_ViewName		dba_views.view_name%TYPE;
v_SchemaName		VARCHAR2(500);

TYPE ObjList		IS TABLE OF VARCHAR2(500);
v_Views			ObjList;
v_Schemas		ObjList;

BEGIN
	v_Schemas	:= ObjList('NGSDMS60','NGSYSUSER','ELNPROD');
	FOR ind IN 1 .. v_Schemas.COUNT
	LOOP
		v_SchemaName := v_Schemas(ind); -- Select a schema from the list
		IF (v_SchemaName = 'NGSDMS60')		THEN -- Load the table variables with lists appropriate for the schema
			v_Views      := ObjList('NGCONTENTMASTER_INSERTVIEW','NGPROJDEFS_ALL','NGTAGS_INSERTVIEW','NGTAGS_VIEW','NGTAGSANDMODCOUNT');
		ELSIF (v_SchemaName = 'NGSYSUSER')	THEN
			IF	(:v_LMSSchemaVerAsNum >= 9000 AND :v_LMSSchemaVerAsNum < 9100)	THEN	v_Views := ObjList('NGAUDITARCHEXCEPTLISTVIEW','NGAUDITARCHIVEDEVICEVIEW','NGAUDITARCHTEMPLATESVIEW','NGAUDITEMAILNOTIFICATIONVIEW','NGAUDITEMAILNOTIFYDETAILVIEW','NGAUDITEVENT2010DETAILVIEW','NGAUDITGROUPMEMBERDETAILVIEW','NGAUDITLEGALHOLDVIEW','NGAUDITNOTIFIERDETAILVIEW','NGAUDITNOTIFIERLISTVIEW','NGAUDITPOLICYDETAILVIEW','NGAUDITPOLICYVIEW','NGAUDITPRIVSDETAILVIEW','NGAUDITPRIVSVIEW','NGAUDITPROJECTS1005DETAILVIEW','NGAUDITPROJECTS1006DETAILVIEW','NGAUDITPROJECTS1007DETAILVIEW','NGAUDITPROJECTS1008DETAILVIEW','NGAUDITPROJECTS1009DETAILVIEW','NGAUDITPROJECTSVIEW','NGAUDITREASONSDETAILVIEW','NGAUDITREASONSVIEW','NGAUDITREPORTSDETAILVIEW','NGAUDITREPORTSVIEW','NGAUDITSCRIPTSVIEW','NGAUDITSEARCHGROUPSVIEW','NGAUDITSERVER6050DETAILVIEW','NGAUDITSERVERLICENSEDETAILVIEW','NGAUDITSERVERLOCATIONVIEW','NGAUDITSERVERSERVER6204VIEW','NGAUDITSERVERSERVER6205VIEW','NGAUDITSERVERSERVER6206VIEW','NGAUDITSERVERSERVERVIEW','NGAUDITSERVERVIEWS','NGAUDITTEMPLATESVIEW','NGAUDITUSERGROUPVIEW','NGAUDITUSERVIEW','NGAUDITVIEWSDETAILVIEW','NGAUDITVIEWSVIEW','NGAUDITVOLUMELIFECYCLEVIEW','NGUSERSANDAUTHMODE_VIEW','NGUSERSANDGROUPS');
			ELSIF	(:v_LMSSchemaVerAsNum >= 9100)					THEN	v_Views := ObjList('NGAUDITARCHEXCEPTLISTVIEW','NGAUDITARCHIVEDEVICEVIEW','NGAUDITARCHTEMPLATESVIEW','NGAUDITEMAILNOTIFICATIONVIEW','NGAUDITEMAILNOTIFYDETAILVIEW','NGAUDITEVENT2010DETAILVIEW','NGAUDITGROUPMEMBERDETAILVIEW','NGAUDITLEGALHOLDVIEW','NGAUDITNOTIFIERDETAILVIEW','NGAUDITNOTIFIERLISTVIEW','NGAUDITPOLICYDETAILVIEW','NGAUDITPOLICYVIEW','NGAUDITPRIVSDETAILVIEW','NGAUDITPRIVSVIEW','NGAUDITPROJECTS1005DETAILVIEW','NGAUDITPROJECTS1006DETAILVIEW','NGAUDITPROJECTS1007DETAILVIEW','NGAUDITPROJECTS1008DETAILVIEW','NGAUDITPROJECTS1009DETAILVIEW','NGAUDITPROJECTSVIEW','NGAUDITREASONSDETAILVIEW','NGAUDITREASONSVIEW','NGAUDITREPORTSDETAILVIEW','NGAUDITREPORTSVIEW','NGAUDITSCRIPTSVIEW','NGAUDITSEARCHGROUPSVIEW','NGAUDITSERVER6050DETAILVIEW','NGAUDITSERVERLICENSEDETAILVIEW','NGAUDITSERVERLOCATIONVIEW','NGAUDITSERVERSERVER6204VIEW','NGAUDITSERVERSERVER6205VIEW','NGAUDITSERVERSERVER6206VIEW','NGAUDITSERVERSERVERVIEW','NGAUDITSERVERVIEWS','NGAUDITTEMPLATESVIEW','NGAUDITUSERGROUPVIEW','NGAUDITUSERVIEW','NGAUDITVIEWSDETAILVIEW','NGAUDITVIEWSVIEW','NGAUDITVOLUMELIFECYCLEVIEW','NGUSERSANDAUTHMODE_VIEW','NGUSERSANDGROUPS','VP_EMPLOYEE_VIEW','VP_FUNCTION_VIEW','VP_GROUPS_VIEW','VP_LABGROUPEMPLOYEE_VIEW','VP_LABGROUP_VIEW','VP_USERS_VIEW');
			ELSE										v_Views := ObjList();
			END IF;
		ELSIF (v_SchemaName = 'ELNPROD')	THEN
			IF	(:v_LMSSchemaVerAsNum >= 9000 AND :v_LMSSchemaVerAsNum < 9100)	THEN	v_Views := ObjList('SAMPLES','VIEW_CHEMICALBOOKIN','VIEW_CHEMICALCOMPOUNDS','VIEW_CHEMICALEVENTS','VIEW_CHEMICALS','VIEW_INSTRUMENTLOGS','VIEW_INSTRUMENTS','VP_DEPARTMENT','VP_LIST','VP_LIST_DESCRIPTION','VP_USER','VW_DOCUMENT','VW_DOCUMENTMETADATA','VW_DOCUMENTSECTION','VW_DOCUMENTSECTIONMETADATA','VW_DOCUMENTSECTIONVERSION','VW_DOCUMENTSIGNATURE','VW_DOCUMENTTEMPLATE','VW_TEMPLATE','VW_TEMPLATELINK','VW_TEMPLATEMETADATA','VW_TEMPLATESECTION','VW_TEMPLATESECTIONMETADATA','VW_TEMPLATEVERSION','VW_SMVALUATIONLIST','VW_VARIANTLISTVALUES');
			ELSIF	(:v_LMSSchemaVerAsNum >= 9100 AND :v_LMSSchemaVerAsNum < 9200)	THEN	v_Views := ObjList('SAMPLES','VIEW_CHEMICALBOOKIN','VIEW_CHEMICALCOMPOUNDS','VIEW_CHEMICALEVENTS','VIEW_CHEMICALS','VIEW_INSTRUMENTLOGS','VIEW_INSTRUMENTS','VP_DEPARTMENT','VP_LIST','VP_LIST_DESCRIPTION','VP_USER','VW_DOCUMENT','VW_DOCUMENTMETADATA','VW_DOCUMENTSECTION','VW_DOCUMENTSECTIONMETADATA','VW_DOCUMENTSECTIONVERSION','VW_DOCUMENTSIGNATURE','VW_DOCUMENTTEMPLATE','VW_TEMPLATE','VW_TEMPLATELINK','VW_TEMPLATEMETADATA','VW_TEMPLATESECTION','VW_TEMPLATESECTIONMETADATA','VW_TEMPLATEVERSION','VW_SMVALUATIONLIST','VW_VARIANTLISTVALUES','VW_SDMSPROJECTINFO','VW_SYSTEMFIELDCONFIGURATIONS','VW_TESTSEARCH_LOGSIGNER');
			ELSIF	(:v_LMSSchemaVerAsNum >= 9200)					THEN	v_Views := ObjList('SAMPLES','VIEW_CHEMICALBOOKIN','VIEW_CHEMICALCOMPOUNDS','VIEW_CHEMICALEVENTS','VIEW_CHEMICALS','VIEW_INSTRUMENTLOGS','VIEW_INSTRUMENTS','VP_DEPARTMENT','VP_LIST','VP_LIST_DESCRIPTION','VP_USER','VW_DOCUMENT','VW_DOCUMENTMETADATA','VW_DOCUMENTSECTION','VW_DOCUMENTSECTIONMETADATA','VW_DOCUMENTSECTIONVERSION','VW_DOCUMENTSIGNATURE','VW_DOCUMENTTEMPLATE','VW_TEMPLATE','VW_TEMPLATELINK','VW_TEMPLATEMETADATA','VW_TEMPLATESECTION','VW_TEMPLATESECTIONMETADATA','VW_TEMPLATEVERSION','VW_SMVALUATIONLIST','VW_VARIANTLISTVALUES','VW_SDMSPROJECTINFO','VW_SYSTEMFIELDCONFIGURATIONS','VW_TESTSEARCH_LOGSIGNER','VIEW_INSTRUMENTSYSTEMFITFORUSELIST','VIEW_INSTRUMENT_NODE','VIEW_INSTRUMENT_SYSTEM');
			ELSE						v_Views := ObjList();
			END IF;
		END IF;

		v_ExpectedNo := v_Views.COUNT;

		SELECT COUNT(*) INTO v_Count FROM dba_views WHERE owner = v_SchemaName;
		IF (v_Count = v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE(v_SchemaName||' owns the expected number of views ('||v_ExpectedNo||' expected, '||v_Count||' found)');
		ELSIF (v_Count < v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: '||v_SchemaName||' does NOT own the expected number of views ('||v_ExpectedNo||' expected, '||v_Count||' found)');
		ELSIF (v_Count > v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE(v_SchemaName||' owns more than the expected number of views ('||v_ExpectedNo||' expected, '||v_Count||' found)');
		END IF;

		FOR indx IN 1 .. v_Views.COUNT
		LOOP
			v_ViewName := v_Views(indx);
			SELECT COUNT(*) INTO v_Count FROM dba_views WHERE owner = v_SchemaName AND view_name = v_ViewName;
			IF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: view '||v_SchemaName||'.'||v_ViewName||' is not present!');
			ELSIF (v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('-- view '||v_SchemaName||'.'||v_ViewName||' is present');
			END IF;
		END LOOP;
		DBMS_OUTPUT.PUT_LINE ('.');
	END LOOP;
END;
/

col view_name format a30
PROMPT
PROMPT List of views owned by the NuGenesis schemas:
SELECT owner, view_name FROM dba_views WHERE owner IN ('NGSDMS60','NGSYSUSER','ELNPROD') ORDER BY owner, view_name;

PROMPT
PROMPT ___________________________________________________________________________________________________________
PROMPT Determining if the expected NuGenesis schema indexes are present and correctly configured ...
PROMPT
PROMPT

PROMPT Count of indexes in the main NuGenesis schema accounts, grouped by owner and index type:
SELECT owner, index_type, COUNT(*) FROM dba_indexes WHERE owner IN ('NGSDMS60','NGSYSUSER','ELNPROD') GROUP BY owner, index_type ORDER BY owner, index_type;

PROMPT

DECLARE
v_IndexName	dba_indexes.index_name%TYPE;
v_IndexOwner	dba_indexes.owner%TYPE;
v_IndexType	dba_indexes.index_type%TYPE;
v_IndexStatus	dba_indexes.status%TYPE;
v_IndexTabName	dba_indexes.table_name%TYPE;
v_IndexLogging	dba_indexes.logging%TYPE;
v_IndexPart	dba_indexes.partitioned%TYPE;
v_ExpectedNo	PLS_INTEGER;
v_Count		PLS_INTEGER;
v_SchemaName	VARCHAR2(500);
TYPE ObjList		IS TABLE OF VARCHAR2(500);
TYPE NumList		IS TABLE OF NUMBER;
t_IndexNameList		ObjList;
t_IndexTabNameList	OBjList;
t_IndexTypeList		ObjList;
t_ExpectedNoList	NumList;
t_SchemaList		ObjList;

CURSOR C_IndexesNoLogging IS	SELECT INDEX_NAME, owner FROM DBA_INDEXES WHERE owner IN ('ELNPROD','NGSYSUSER','NGSDMS60') AND LOGGING = 'NO';

BEGIN
	SELECT COUNT(*) INTO v_Count FROM DBA_INDEXES DI WHERE owner IN('ELNPROD','NGSDMS60','NGSYSUSER') AND LOGGING = 'NO';
	IF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('All indexes in the NuGenesis schemas are logging');
	ELSE
		DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: '||v_Count||' indexes in the NuGenesis schemas have the nologging attribute!  The presence of nologging indexes can result in unrecoverable backups!  These indexes are listed below:');
		OPEN C_IndexesNoLogging;
		LOOP
			FETCH C_IndexesNoLogging INTO v_IndexName, v_IndexOwner;
			EXIT WHEN C_IndexesNoLogging%NOTFOUND;

			DBMS_OUTPUT.PUT_LINE('-- '||v_IndexOwner||'.'||v_IndexName);
		END LOOP;
		CLOSE C_IndexesNoLogging;
	END IF;

	t_SchemaList     := ObjList('NGSDMS60','NGSYSUSER','ELNPROD');
	t_IndexTypeList  := ObjList('DOMAIN','NORMAL','CLUSTER','LOB','IOT - TOP','FUNCTION-BASED NORMAL');
	FOR indx2 IN 1 .. T_SchemaList.COUNT
	LOOP
		v_SchemaName := t_SchemaList(indx2); -- Load the table variables appropriately for the schema and product version
		IF	(v_SchemaName = 'NGSDMS60')	THEN
			IF	(:v_LMSSchemaVer LIKE '9.0%')	THEN -- expected numbers of NGSDMS60 indexes for NG 9.0
				IF	(:V_OracleVer LIKE '12%')	THEN -- ... on Oracle 12,
					t_ExpectedNoList := NumList(1, 43, 1, 11, 2, 0); -- number of expected indexes for this schema per index type
					t_IndexNameList  := ObjList('SDMS70_IND_CLU_IDX','ADVANCE_SEARCH','DR$ADVANCE_SEARCH$RC','DR$ADVANCE_SEARCH$X','LEGAL_HOLD_ASSIGN_PK','LEGAL_HOLD_DEF_PK','NGARCHIVEDEVICESGUID_UK','NGARCHIVEDEVICES_UK','NGCONTENTDETAIL_IDX1','NGCONTENTDETAIL_PK','NGCONTENTMASTER_IDX1', 'NGCONTENTMASTER_IDX2', 'NGCONTENTMASTER_IDX3', 'NGCONTENTMASTER_IDX4', 'NGCONTENTMASTER_PK','NGFIELDS_PK', 'NGFIELDS_UK', 'NGFIELDVAL_PK', 'NGOBJNUMINFO_PK', 'NGPOLICY_EVENTS_PK', 'NGPROJDEFSCLU_PK','NGPROJDEFS_PURGE_PK', 'NGPROJDEFS_TOPURGE_IDX', 'NGPROJMISCDATA_PK', 'NGPROJNAMEAPPNAMECLU_UK', 'NGPROJSTORES_UK','NGPROJSTORE_PK', 'NGPROJTPL_IDX', 'NGPROJTPL_PK', 'NGPROJVIEWFIELDS_PK', 'NGPROJVIEWFILTERS_PK', 'NGPROJVIEWCLU_PK','NGPROJVIEWCLU_UK', 'NGRETENTION_POLICY_PK', 'NGSERVERSTORES_PK', 'NGSERVERSTORES_UK', 'NGTABLES_PK', 'NGTAGS_IDX1','NGTAGS_IDX2', 'NGTAGS_PK', 'NGUSERPREFS_PK', 'NGVOLUMEGUID_UK', 'NGVOLUMELIFECYCLE_IDX');
				ELSIF	(:V_OracleVer LIKE '19%')	THEN -- ... on Oracle 19,
					t_ExpectedNoList := NumList(1, 42, 1, 10, 1, 0); -- number of expected indexes for this schema per index type
					t_IndexNameList  := ObjList('SDMS70_IND_CLU_IDX','ADVANCE_SEARCH','DR$ADVANCE_SEARCH$X','LEGAL_HOLD_ASSIGN_PK','LEGAL_HOLD_DEF_PK','NGARCHIVEDEVICESGUID_UK','NGARCHIVEDEVICES_UK','NGCONTENTDETAIL_IDX1','NGCONTENTDETAIL_PK','NGCONTENTMASTER_IDX1', 'NGCONTENTMASTER_IDX2', 'NGCONTENTMASTER_IDX3', 'NGCONTENTMASTER_IDX4', 'NGCONTENTMASTER_PK','NGFIELDS_PK', 'NGFIELDS_UK', 'NGFIELDVAL_PK', 'NGOBJNUMINFO_PK', 'NGPOLICY_EVENTS_PK', 'NGPROJDEFSCLU_PK','NGPROJDEFS_PURGE_PK', 'NGPROJDEFS_TOPURGE_IDX', 'NGPROJMISCDATA_PK', 'NGPROJNAMEAPPNAMECLU_UK', 'NGPROJSTORES_UK','NGPROJSTORE_PK', 'NGPROJTPL_IDX', 'NGPROJTPL_PK', 'NGPROJVIEWFIELDS_PK', 'NGPROJVIEWFILTERS_PK', 'NGPROJVIEWCLU_PK','NGPROJVIEWCLU_UK', 'NGRETENTION_POLICY_PK', 'NGSERVERSTORES_PK', 'NGSERVERSTORES_UK', 'NGTABLES_PK', 'NGTAGS_IDX1','NGTAGS_IDX2', 'NGTAGS_PK', 'NGUSERPREFS_PK', 'NGVOLUMEGUID_UK', 'NGVOLUMELIFECYCLE_IDX');
				END IF;
			ELSIF	(:v_LMSSchemaVerAsNum >= 9100 AND :v_LMSSchemaVerAsNum < 9200)	THEN -- expected numbers of indexes for NG 9.1
				t_ExpectedNoList := NumList(1, 44, 1, 11, 1, 0); -- number of expected indexes for this schema per index type
				t_IndexNameList  := ObjList('SDMS70_IND_CLU_IDX','ADVANCE_SEARCH','DR$ADVANCE_SEARCH$X','LEGAL_HOLD_ASSIGN_PK','LEGAL_HOLD_DEF_PK','NGARCHIVEDEVICESGUID_UK','NGARCHIVEDEVICES_UK','NGCONTENTDETAIL_IDX1','NGCONTENTDETAIL_PK','NGCONTENTMASTER_IDX1', 'NGCONTENTMASTER_IDX2', 'NGCONTENTMASTER_IDX3', 'NGCONTENTMASTER_IDX4', 'NGCONTENTMASTER_PK','NGFIELDS_PK', 'NGFIELDS_UK', 'NGFIELDVAL_PK', 'NGOBJNUMINFO_PK', 'NGPOLICY_EVENTS_PK', 'NGPROJDEFSCLU_PK','NGPROJDEFS_PURGE_PK', 'NGPROJDEFS_TOPURGE_IDX', 'NGPROJMISCDATA_PK', 'NGPROJNAMEAPPNAMECLU_UK', 'NGPROJSTORES_UK','NGPROJSTORE_PK', 'NGPROJTPL_IDX', 'NGPROJTPL_PK', 'NGPROJVIEWFIELDS_PK', 'NGPROJVIEWFILTERS_PK', 'NGPROJVIEWCLU_PK','NGPROJVIEWCLU_UK', 'NGRETENTION_POLICY_PK', 'NGSERVERSTORES_PK', 'NGSERVERSTORES_UK', 'NGTABLES_PK', 'NGTAGS_IDX1','NGTAGS_IDX2', 'NGTAGS_PK', 'NGUSERPREFS_PK', 'NGVOLUMEGUID_UK', 'NGVOLUMELIFECYCLE_IDX');
			ELSIF	(:v_LMSSchemaVerAsNum >= 9200 AND :v_LMSSchemaVerAsNum < 9300)	THEN -- expected numbers of indexes for NG 9.2
				t_ExpectedNoList := NumList(1, 44, 1, 11, 1, 0); -- number of expected indexes for this schema per index type
				t_IndexNameList  := ObjList('SDMS70_IND_CLU_IDX','ADVANCE_SEARCH','DR$ADVANCE_SEARCH$X','LEGAL_HOLD_ASSIGN_PK','LEGAL_HOLD_DEF_PK','NGARCHIVEDEVICESGUID_UK','NGARCHIVEDEVICES_UK','NGCONTENTDETAIL_IDX1','NGCONTENTDETAIL_PK','NGCONTENTMASTER_IDX1', 'NGCONTENTMASTER_IDX2', 'NGCONTENTMASTER_IDX3', 'NGCONTENTMASTER_IDX4', 'NGCONTENTMASTER_PK','NGFIELDS_PK', 'NGFIELDS_UK', 'NGFIELDVAL_PK', 'NGOBJNUMINFO_PK', 'NGPOLICY_EVENTS_PK', 'NGPROJDEFSCLU_PK','NGPROJDEFS_PURGE_PK', 'NGPROJDEFS_TOPURGE_IDX', 'NGPROJMISCDATA_PK', 'NGPROJNAMEAPPNAMECLU_UK', 'NGPROJSTORES_UK','NGPROJSTORE_PK', 'NGPROJTPL_IDX', 'NGPROJTPL_PK', 'NGPROJVIEWFIELDS_PK', 'NGPROJVIEWFILTERS_PK', 'NGPROJVIEWCLU_PK','NGPROJVIEWCLU_UK', 'NGRETENTION_POLICY_PK', 'NGSERVERSTORES_PK', 'NGSERVERSTORES_UK', 'NGTABLES_PK', 'NGTAGS_IDX1','NGTAGS_IDX2', 'NGTAGS_PK', 'NGUSERPREFS_PK', 'NGVOLUMEGUID_UK', 'NGVOLUMELIFECYCLE_IDX');
			ELSIF	(:v_LMSSchemaVerAsNum >= 9300)					THEN -- expected numbers of indexes for NG 9.3.x
				t_ExpectedNoList := NumList(1, 45, 1, 11, 1, 0); -- number of expected indexes for this schema per index type
				t_IndexNameList  := ObjList('SDMS70_IND_CLU_IDX','ADVANCE_SEARCH','DR$ADVANCE_SEARCH$X','LEGAL_HOLD_ASSIGN_PK','LEGAL_HOLD_DEF_PK','NGARCHIVEDEVICESGUID_UK','NGARCHIVEDEVICES_UK','NGCONTENTDETAIL_IDX1','NGCONTENTDETAIL_PK','NGCONTENTMASTER_IDX1', 'NGCONTENTMASTER_IDX2', 'NGCONTENTMASTER_IDX3', 'NGCONTENTMASTER_IDX4', 'NGCONTENTMASTER_PK','NGFIELDS_PK', 'NGFIELDS_UK', 'NGFIELDVAL_PK', 'NGOBJNUMINFO_PK', 'NGPOLICY_EVENTS_PK', 'NGPROJDEFSCLU_PK','NGPROJDEFS_PURGE_PK', 'NGPROJDEFS_TOPURGE_IDX', 'NGPROJMISCDATA_PK', 'NGPROJNAMEAPPNAMECLU_UK', 'NGPROJSTORES_UK','NGPROJSTORE_PK', 'NGPROJTPL_IDX', 'NGPROJTPL_PK', 'NGPROJVIEWFIELDS_PK', 'NGPROJVIEWFILTERS_PK', 'NGPROJVIEWCLU_PK','NGPROJVIEWCLU_UK', 'NGRETENTION_POLICY_PK', 'NGSERVERSTORES_PK', 'NGSERVERSTORES_UK', 'NGTABLES_PK', 'NGTAGS_IDX1','NGTAGS_IDX2', 'NGTAGS_PK', 'NGUSERPREFS_PK', 'NGVOLUMEGUID_UK', 'NGVOLUMELIFECYCLE_IDX');
			ELSE
				t_ExpectedNoList := NumList();
				t_IndexNameList := ObjList();
			END IF;
		ELSIF	(v_SchemaName = 'ELNPROD')	THEN
			IF	(:v_LMSSchemaVerAsNum >= 9000 AND :v_LMSSchemaVerAsNum < 9100)	THEN -- expected numbers of indexes for NG 9.0,
				IF	(:V_OracleVer LIKE '12%')	THEN -- ... on Oracle 12,
					IF	(:v_ConnTableCount > 0)	THEN	t_ExpectedNoList := NumList(20, 502, 0, 72, 40, 3); -- ... with Connectors
					ELSE					t_ExpectedNoList := NumList(20, 502, 0, 68, 40, 3); -- ... without Conectors
					END IF;
				ELSIF	(:V_OracleVer LIKE '19%')	THEN -- .. on Oracle 19, fewer LOB and IOT-TOP indexes are expected
					IF	(:v_ConnTableCount > 0)	THEN	t_ExpectedNoList := NumList(20, 502, 0, 52, 20, 3); -- ... with Connectors
					ELSE					t_ExpectedNoList := NumList(20, 502, 0, 48, 20, 3); -- ... without Connectors
					END IF;
				END IF;
			ELSIF	(:v_LMSSchemaVerAsNum >= 9100 AND :v_LMSSchemaVerAsNum < 9200)	THEN -- expected numbers of indexes for NG 9.1
				IF	(:v_ConnTableCount > 0)	THEN	t_ExpectedNoList := NumList(22, 510, 0, 54, 22, 3); -- NG 9.1 reduced the number of IOT-TOP and LOB indexes vs. NG 9.0
				ELSE					t_ExpectedNoList := NumList(22, 510, 0, 50, 22, 3); -- LMS Connectors adds 4 LOB indexes if installed, so adjust the LOB index expected count if Connectors is present
				END IF;
			ELSIF	(:v_LMSSchemaVerAsNum >= 9200 AND :v_LMSSchemaVerAsNum < 9300)	THEN -- expected numbers of indexes for NG 9.2
				IF	(:v_ConnTableCount > 0)	THEN	t_ExpectedNoList := NumList(22, 510, 0, 54, 22, 3); -- NG 9.1 reduced the number of IOT-TOP and LOB indexes vs. NG 9.0
				ELSE					t_ExpectedNoList := NumList(22, 510, 0, 50, 22, 3); -- LMS Connectors adds 4 LOB indexes if installed, so adjust the LOB index expected count if Connectors is present
				END IF;
			ELSIF	(:v_LMSSchemaVerAsNum >= 9300 AND :v_LMSSchemaVerAsNum < 9400)	THEN -- expected numbers of indexes for NG 9.2
				IF	(:v_ConnTableCount > 0)	THEN	t_ExpectedNoList := NumList(22, 510, 0, 54, 22, 3); -- NG 9.1 reduced the number of IOT-TOP and LOB indexes vs. NG 9.0
				ELSE					t_ExpectedNoList := NumList(22, 510, 0, 50, 22, 3); -- LMS Connectors adds 4 LOB indexes if installed, so adjust the LOB index expected count if Connectors is present
				END IF;
			ELSE						t_ExpectedNoList := NumList(); --blank out the list for other schema versions
			END IF;
			t_IndexNameList  := ObjList('IDX_UPPERDOCID','MO_ELN_RECEXP1','MO_ELN_RECEXP2','CTX_BINARYDOCUMENT','TEXT_IDX_EXTERNALPLUGIN','TEXT_IDX_LOCATION','TEXT_IDX_MEASUREORDER','TEXT_IDX_PHYSICALSAMPLE','TEXT_IDX_PRODUCT','TEXT_IDX_REPORTCONFIG','TEXT_IDX_REPORTCONFIGLIB','TEXT_IDX_SAMPLETEMPLATE','TEXT_IDX_SMMETHOD','TEXT_IDX_SPECIFICATION','TEXT_IDX_SUBMISSION','TEXT_IDX_SUBMISSIONTEMPL','TEXT_IDX_TEST','TEXT_IDX_TESTDEFINITION','TEXT_IDX_TESTREQUEST','TEXT_IDX_TESTRESULT','TEXT_IDX_UICONFIGURATION','TEXT_IDX_USERMESSAGE','TEXT_IDX_USERS');
		ELSIF	(v_SchemaName = 'NGSYSUSER')	THEN
			IF	(:v_LMSSchemaVerAsNum >= 9000 AND :v_LMSSchemaVerAsNum < 9100)	THEN
				t_ExpectedNoList := NumList(0, 26, 2, 0, 0, 0);
				t_IndexNameList := ObjList('NGAUDITMASTERVIEWS_IDX','NGAUTHMODESMAP_PK','NGCATEGORY_PKEY','NGCHECKVALUES_UK','NGCONFIG_PK','NGEMAILALERTS_UK','NGGROUPCLU_UK','NGGROUPMEMBERSCLU_IDX1','NGGROUPMEMBERSCLU_IDX2','NGGROUPSCLU_PK','NGLOCKDETAILS_PK','NGNOTIFY_PK','NGPRIVILEGECLU_IDX1','NGPRIVILEGECLU_IDX2','NGPWDCHGPROC_PK','NGSERVERPROJINFO_PK','NGSTRINGLOOKUP_PK','NGTEMPTBL_IDX','NGUSERSAUT_PK','NGUSERS_PK','NGUSERS_UK','NGVIEWID_PK','SDMS70_GROUP_IND_CLU_IDX','NGAUDITDETAILS_CLU_IDX','NGAUDITDETAILS_CLU_PK','NGAUDITDETAILSVIEWS_PK','SDMS70_AUDIT_CLU_IDX','NGAUDITMASTER_CLU_PK');
			ELSIF	(:v_LMSSchemaVerAsNum >= 9100 AND :v_LMSSchemaVerAsNum < 9300)	THEN
				t_ExpectedNoList := NumList(0, 30, 2, 0, 0, 0);
				t_IndexNameList := ObjList('NGAUDITMASTERVIEWS_IDX','NGAUTHMODESMAP_PK','NGCATEGORY_PKEY','NGCHECKVALUES_UK','NGCONFIG_PK','NGEMAILALERTS_UK','NGGROUPCLU_UK','NGGROUPMEMBERSCLU_IDX1','NGGROUPMEMBERSCLU_IDX2','NGGROUPSCLU_PK','NGLOCKDETAILS_PK','NGNOTIFY_PK','NGPRIVILEGECLU_IDX1','NGPRIVILEGECLU_IDX2','NGPWDCHGPROC_PK','NGSERVERPROJINFO_PK','NGSTRINGLOOKUP_PK','NGTEMPTBL_IDX','NGUSERSAUT_PK','NGUSERS_PK','NGUSERS_UK','NGVIEWID_PK','SDMS70_GROUP_IND_CLU_IDX','NGAUDITDETAILS_CLU_IDX','NGAUDITDETAILS_CLU_PK','NGAUDITDETAILSVIEWS_PK','SDMS70_AUDIT_CLU_IDX','NGAUDITMASTER_CLU_PK','NGAUDITMASTERCLU_IDX1','NGAUDITMASTERCLU_IDX2');
			ELSIF	(:v_LMSSchemaVerAsNum >= 9300 AND :v_LMSSchemaVerAsNum < 9310)	THEN
				t_ExpectedNoList := NumList(0, 31, 2, 0, 0, 0);
				t_IndexNameList := ObjList('NGAUDITMASTERVIEWS_IDX','NGAUTHMODESMAP_PK','NGCATEGORY_PKEY','NGCHECKVALUES_UK','NGCONFIG_PK','NGEMAILALERTS_UK','NGGROUPCLU_UK','NGGROUPMEMBERSCLU_IDX1','NGGROUPMEMBERSCLU_IDX2','NGGROUPSCLU_PK','NGLOCKDETAILS_PK','NGNOTIFY_PK','NGPRIVILEGECLU_IDX1','NGPRIVILEGECLU_IDX2','NGPWDCHGPROC_PK','NGSERVERPROJINFO_PK','NGSTRINGLOOKUP_PK','NGTEMPTBL_IDX','NGUSERSAUT_PK','NGUSERS_PK','NGUSERS_UK','NGVIEWID_PK','SDMS70_GROUP_IND_CLU_IDX','NGAUDITDETAILS_CLU_IDX','NGAUDITDETAILS_CLU_PK','NGAUDITDETAILSVIEWS_PK','SDMS70_AUDIT_CLU_IDX','NGAUDITMASTER_CLU_PK','NGAUDITMASTERCLU_IDX1','NGAUDITMASTERCLU_IDX2','NGAUDITMASTERCLU_IDX3');
			ELSIF	(:v_LMSSchemaVerAsNum >= 9310)					THEN
				t_ExpectedNoList := NumList(0, 30, 2, 0, 0, 2);
				t_IndexNameList := ObjList('NGAUDITMASTERVIEWS_IDX','NGAUTHMODESMAP_PK','NGCATEGORY_PKEY','NGCHECKVALUES_UK','NGCONFIG_PK','NGEMAILALERTS_UK','NGGROUPCLU_UK','NGGROUPMEMBERSCLU_IDX1','NGGROUPMEMBERSCLU_IDX2','NGGROUPSCLU_PK','NGLOCKDETAILS_PK','NGNOTIFY_PK','NGPRIVILEGECLU_IDX1','NGPRIVILEGECLU_IDX2','NGPWDCHGPROC_PK','NGSERVERPROJINFO_PK','NGSTRINGLOOKUP_PK','NGTEMPTBL_IDX','NGUSERSAUT_PK','NGUSERS_PK','NGUSERS_UK','NGVIEWID_PK','SDMS70_GROUP_IND_CLU_IDX','NGAUDITDETAILS_CLU_IDX','NGAUDITDETAILS_CLU_PK','NGAUDITDETAILSVIEWS_PK','SDMS70_AUDIT_CLU_IDX','NGAUDITMASTER_CLU_PK','NGAUDITMASTERCLU_IDX1','NGAUDITMASTERCLU_IDX2','NGAUDITMASTERCLU_IDX3','NGAUDITMASTERCLU_IDX4');
			ELSE
				t_ExpectedNoList := NumList();
				t_IndexNameList := ObjList();
			END IF;
		END IF;

		-- Set the expected total number of indexes for the schema by adding up the numbers in t_ExpectedNoList
		v_ExpectedNo := 0;
		FOR indxtot IN 1 .. t_ExpectedNoList.COUNT
		LOOP
			v_ExpectedNo := v_ExpectedNo + t_ExpectedNoList(indxtot);
		END LOOP;

		-- Check the total number of indexes owned by the schema, and then break it down by index type
		SELECT COUNT(*) INTO v_Count FROM DBA_INDEXES WHERE owner = v_SchemaName;
		IF (v_Count >= v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE(v_SchemaName||' owns at least the minimum number of indexes (at least '||v_ExpectedNo||' expected, '||v_Count||' found)');
		ELSE					DBMS_OUTPUT.PUT_LINE('!!! WARNING: '||v_SchemaName||' owns less than the minimum number of indexes (at least '||v_ExpectedNo||' expected, '||v_Count||' found)!');
		END IF;

		FOR indx IN 1 .. t_IndexTypeList.COUNT
		LOOP
			v_IndexType  := t_IndexTypeList(indx);
			v_ExpectedNo := t_ExpectedNoList(indx);
			SELECT COUNT(*) INTO v_Count FROM DBA_INDEXES WHERE owner = v_SchemaName AND index_type = v_IndexType;
			IF (v_Count = v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('-- '||v_SchemaName||' owns the expected number of '||v_IndexType||' indexes (minimum '||v_ExpectedNo||' expected, '||v_Count||' found)');
			ELSIF (v_Count < v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: '||v_SchemaName||' owns less than the expected number of '||v_IndexType||' indexes (minimum '||v_ExpectedNo||' expected, '||v_Count||' found)!');
			ELSIF (v_Count > v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('-- '||v_SchemaName||' owns more than the minimum number of '||v_IndexType||' indexes (minimum '||v_ExpectedNo||' expected, '||v_Count||' found)');
			END IF;
		END LOOP;

		DBMS_OUTPUT.PUT_LINE ('.');

		-- Now look for specific indexes owned by the schema based on name, owner
		FOR indx in 1 .. t_IndexNameList.COUNT
		LOOP
			SELECT COUNT(*) INTO v_Count FROM DBA_INDEXES WHERE INDEX_NAME = t_IndexNameList(indx) AND owner = v_SchemaName;
			IF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: index: '||v_SchemaName||'.'||t_IndexNameList(indx)||' is missing!');
			ELSE
				DBMS_OUTPUT.PUT_LINE('Index: '||v_SchemaName||'.'||t_IndexNameList(indx)||' is present');
				SELECT logging, status, partitioned INTO v_IndexLogging, v_IndexStatus, v_IndexPart FROM dba_indexes WHERE index_name  = t_IndexNameList(indx) AND owner = v_SchemaName;

				DBMS_OUTPUT.PUT_LINE('-- Partitioned: '||v_IndexPart);
				IF (v_IndexPart = 'YES')	THEN
					SELECT COUNT(*) INTO v_Count FROM dba_ind_partitions WHERE INDEX_NAME = t_IndexNameList(indx) AND index_owner = v_SchemaName AND status != 'USABLE';
					IF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('-- Status: all index partitions report as USABLE');
					ELSE				DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: status: '||v_Count||' partition(s) report as unusable!');
					END IF;

					SELECT COUNT(*) INTO v_Count FROM dba_ind_partitions WHERE INDEX_NAME = t_IndexNameList(indx) AND index_owner = v_SchemaName AND logging != 'YES';
					IF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('-- Logging: all index partitions report as LOGGING');
					ELSE				DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: loging: '||v_Count||' partition(s) report as not logging!');
					END IF;
				ELSE
					IF (v_IndexStatus = 'VALID')			THEN	DBMS_OUTPUT.PUT_LINE('-- Status: '||v_IndexStatus);
					ELSE							DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: status: '||v_IndexStatus||' is incorrect; it should be VALID!');
					END IF;

					IF (v_IndexLogging = 'YES')			THEN	DBMS_OUTPUT.PUT_LINE('-- Logging: '||v_IndexLogging);
					ELSE							DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: logging mode '||v_IndexLogging||' is incorrect; it should be in logging mode!');
					END IF;
				END IF;
			END IF;
		END LOOP;
		DBMS_OUTPUT.PUT_LINE ('.');
		DBMS_OUTPUT.PUT_LINE ('.');
	END LOOP;
END;
/

PROMPT
PROMPT ___________________________________________________________________________________________________________
PROMPT

col index_type format a25
col index_name format a30
col table_owner format a20
col owner format a10
col table_name format a30
PROMPT
PROMPT List of NuGenesis indexes:
SELECT owner, index_name, index_type, table_owner, table_name FROM dba_indexes WHERE owner IN ('NGSDMS60','NGSYSUSER','ELNPROD') ORDER BY owner, index_type, index_name;

PROMPT
PROMPT Local indexes owned by NuGenesis schemas:
SELECT owner, TABLE_NAME, INDEX_NAME, LOCALITY FROM DBA_PART_INDEXES WHERE owner IN ('NGSDMS60','NGSYSUSER','ELNPROD') ORDER BY owner;

PROMPT
PROMPT ***************************************************************************************************************************************
PROMPT Verifying the system and objects privileges for the NuGenesis schemas...
PROMPT ***************************************************************************************************************************************
PROMPT

PROMPT
PROMPT ______________________________________________________________________________________________
PROMPT Determining whether the expected System privileges and roles have been granted to the NuGenesis schemas
PROMPT
DECLARE
v_ExpectedNo	PLS_INTEGER;
v_Count		PLS_INTEGER;
v_SchemaName	VARCHAR2(500);
TYPE ObjList	IS TABLE OF VARCHAR2(500);
TYPE NumList	IS TABLE OF NUMBER;
t_SchemaList	ObjList;
t_RoleList	ObjList;
t_SysPrivsList	ObjList;

BEGIN
	t_SchemaList := ObjList('ELNPROD','NGPROXY','NGSDMS60','NGSTATICUSER','NGSYSUSER','NGPROJMGR','SPSV');
	FOR indx IN 1 .. t_SchemaList.COUNT
	LOOP
		v_SchemaName := t_SchemaList(indx);
		IF (v_SchemaName = 'ELNPROD')		THEN
			IF (:v_LMSSchemaVerAsNum < 9300)	THEN	t_SysPrivsList := ObjList('CREATE VIEW','MANAGE SCHEDULER','ON COMMIT REFRESH','CREATE JOB');
			ELSIF (:v_LMSSchemaVerAsNum>= 9300)	THEN	t_SysPrivsList := ObjList('CREATE VIEW','MANAGE SCHEDULER','CREATE JOB'); -- On Commit Refresh was removed from elnprod in 9.3.
			END IF;
			t_RoleList     := ObjList('RESOURCE','CONNECT','CTXAPP');
		ELSIF (v_SchemaName = 'NGPROXY')	THEN
			t_SysPrivsList := ObjList('CREATE SESSION');
			t_RoleList     := ObjList('NGSDMS70PROXYROLE','NGPASSWDROLE');
		ELSIF (v_SchemaName = 'NGSDMS60')	THEN
			t_SysPrivsList := ObjList('MANAGE SCHEDULER','CREATE VIEW','CREATE JOB','CREATE TABLE');
			IF (:v_LMSSchemaVerAsNum >= 9000 AND :v_LMSSchemaVerAsNum < 9100)	THEN	t_RoleList     := ObjList('CTXAPP'); -- only CtxApp expected for ngsdms60 in NuGenesis 9.0.
			ELSE										t_RoleList     := ObjList('CTXAPP','CONNECT','RESOURCE');
			END IF;
		ELSIF (v_SchemaName = 'NGSTATICUSER')	THEN
			t_SysPrivsList := ObjList('CREATE SESSION');
			t_RoleList     := ObjList();
		ELSIF (v_SchemaName = 'NGSYSUSER')	THEN
			t_SysPrivsList := ObjList('CREATE USER','CREATE DATABASE LINK','CREATE VIEW','CREATE SYNONYM','ALTER USER','CREATE JOB');
			t_RoleList     := ObjList('CONNECT','NGPASSWDROLE');
		ELSIF (v_SchemaName = 'NGPROJMGR')	THEN
			t_SysPrivsList := ObjList('CREATE SESSION');
			t_RoleList     := ObjList('NGPASSWDROLE');
		ELSIF (v_SchemaName = 'SPSV')		THEN
			t_SysPrivsList := ObjList();
			t_RoleList     := ObjList('CTXAPP','CONNECT','RESOURCE');
		END IF;

		v_ExpectedNo := t_SysPrivsList.COUNT;
		SELECT COUNT(*) INTO v_Count FROM dba_sys_privs WHERE grantee = v_SchemaName;
		IF (v_Count = v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE (v_SchemaName||' has the expected number of system privileges ('||v_ExpectedNo||' expected, '||v_Count||' found).');
		ELSIF (v_Count < v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE ('!!!!! ERROR: '||v_SchemaName||' has less than the expected number of system privileges ('||v_ExpectedNo||' expected, '||v_Count||' found)!');
		ELSIF (v_Count > v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE (v_SchemaName||' has more than the expected number of system privileges ('||v_ExpectedNo||' expected, '||v_Count||' found).');
		END IF;

		FOR indx2 IN 1 .. t_SysPrivsList.COUNT
		LOOP
			SELECT COUNT(*) INTO v_Count FROM dba_sys_privs WHERE grantee = v_SchemaName AND privilege = t_SysPrivsList(indx2);
			IF (v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE ('-- has the system privilege '||t_SysPRivsList(indx2));
			ELSIF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE ('-- !!!!! ERROR: does NOT have the system privilege '||t_SysPRivsList(indx2)||'!');
			END IF;
		END LOOP;

		v_ExpectedNo := t_RoleList.COUNT;
		SELECT COUNT(*) INTO v_Count FROM dba_role_privs WHERE grantee = v_SchemaName;
		IF (v_Count = v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE (v_SchemaName||' has the expected number of roles ('||v_ExpectedNo||' expected, '||v_Count||' found).');
		ELSIF (v_Count < v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE ('!!!!! ERROR: '||v_SchemaName||' has less than the expected number of roles ('||v_ExpectedNo||' expected, '||v_Count||' found)!');
		ELSIF (v_Count > v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE (v_SchemaName||' has more than the expected number of roles ('||v_ExpectedNo||' expected, '||v_Count||' found).');
		END IF;

		FOR indx2 IN 1 .. t_RoleList.COUNT
		LOOP
			SELECT COUNT(*) INTO v_Count FROM dba_role_privs WHERE grantee = v_SchemaName AND granted_role = t_RoleList(indx2);
			IF (v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE ('-- has the role '||t_RoleList(indx2));
			ELSIF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE ('-- !!!!! ERROR: does NOT have the role '||t_RoleList(indx2)||'!');
			END IF;
		END LOOP;

		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('.');
	END LOOP;
END;
/

PROMPT
PROMPT System privileges granted to nugenesis schema accounts:

COLUMN GRANTEE 		FORMAT	A18
COLUMN PRIVILEGE 	FORMAT	A30
COLUMN ADMIN_OPTION	FORMAT	A12
BREAK ON GRANTEE SKIP 1
SELECT GRANTEE, PRIVILEGE, ADMIN_OPTION FROM DBA_SYS_PRIVS WHERE grantee IN ('NGSYSUSER', 'NGPROXY', 'NGSDMS60', 'NGSTATICUSER', 'NGPROJMGR', 'ELNPROD','SPSV') ORDER BY grantee;

PROMPT
PROMPT __________________________________________________________________________________________
PROMPT Determining if the expected Object privileges have been granted to NuGenesis accounts ...
PROMPT
DECLARE
v_Count		PLS_INTEGER := 0;
v_ExpectedNo	PLS_INTEGER;
v_SchemaName	VARCHAR2(100);
v_PrivName	VARCHAR2(100);
v_ObjOwner	VARCHAR2(100);
v_ObjName	VARCHAR2(100);

TYPE ObjList		IS TABLE OF VARCHAR2(500);
t_SchemaList		ObjList;
t_PrivNameList		ObjList;
t_PrivObjOwnerList	ObjList;
t_PrivObjNameList	ObjList;

BEGIN
	t_SchemaList  := ObjList('NGSDMS70PROXYROLE','NGSDMS60','NGSTATICUSER','NGPROXY','NGPASSWDROLE','NGSYSUSER','ELNPROD','SPSV');
	FOR indx IN 1 .. t_SchemaList.COUNT
	LOOP
		v_SchemaName := t_SchemaList(indx);
		IF (v_SchemaName = 'NGPROXY')			THEN
			IF (:v_LMSSchemaVerAsNum >= 9300)					THEN
				t_PrivNameList     := ObjList('EXECUTE','EXECUTE');
				t_PrivObjOwnerList := ObjList('NGSDMS60','NGSDMS60');
				t_PrivObjNameList  := ObjList('CREATETEMPTBL','GETINDEXEDCOLUMNS');
			ELSE
				t_PrivNameList     := ObjList('EXECUTE');
				t_PrivObjOwnerList := ObjList('NGSDMS60');
				t_PrivObjNameList  := ObjList('CREATETEMPTBL');
			END IF;
		ELSIF (v_SchemaName = 'NGSDMS60')		THEN
			t_PrivNameList     := ObjList('EXECUTE','ALTER','DELETE','DELETE','DELETE','DELETE','INSERT','INSERT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','UPDATE','UPDATE','UPDATE','EXECUTE');
			t_PrivObjOwnerList := ObjList('CTXSYS','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER');
			t_PrivObjNameList  := ObjList('CTX_DDL','NGAUDITSEQ','NGLOCKDETAILS','NGTEMPTBL','NGLOCKINFO','NGPRIVILEGE','NGTEMPTBL','NGAUDITMASTER','NGCONFIG','NGLOCKDETAILS','NGTEMPTBL','NGLOCKINFO','NGAUDITSEQ','NGAUDITMASTER','NGPRIVILEGE','NGCONFIG','NGTEMPTBL','NGLOCKINFO','NGSDMS60_DEFINITIONS');
		ELSIF (v_SchemaName = 'NGSTATICUSER')		THEN
			t_PrivNameList     := ObjList('SELECT','EXECUTE');
			t_PrivObjOwnerList := ObjList('NGSYSUSER','NGSYSUSER');
			t_PrivObjNameList  := ObjList('NGCHECKVALUES','NGSDMS60_DEFINITIONS');
		ELSIF (v_SchemaName = 'NGSYSUSER')		THEN
			t_PrivNameList     := ObjList('SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','EXECUTE','EXECUTE','EXECUTE','EXECUTE','EXECUTE','EXECUTE','EXECUTE','EXECUTE');
			t_PrivObjOwnerList := ObjList('ELNPROD','ELNPROD','ELNPROD','ELNPROD','ELNPROD','ELNPROD','ELNPROD','ELNPROD','ELNPROD','ELNPROD','ELNPROD','ELNPROD','ELNPROD','ELNPROD');
			t_PrivObjNameList  := ObjList('USERS','LABGROUP','FUNCTION','LABGROUPEMPLOYEE','GROUPS','EMPLOYEE','ELN_CREATE_LABGROUPEMPLOYEE','ELN_CREATE_USER','ELN_DELETE_LABGROUPEMPLOYEE','ELN_GET_BUILD_INFO','ELN_UPDATE_LABGROUPEMPLOYEE','ELN_UPDATE_USER_OTHER_PROPS','ELN_UPDATE_USER','ELN_DELETE_USER');
		ELSIF (v_SchemaName = 'NGSDMS70PROXYROLE')	THEN
			IF (:v_LMSSchemaVerAsNum >= 9000 AND :v_LMSSchemaVerAsNum < 9100)	THEN
				t_PrivNameList     := ObjList('SELECT','DELETE','INSERT','SELECT','UPDATE','DELETE','INSERT','SELECT','UPDATE','DELETE','INSERT','SELECT','UPDATE','DELETE','INSERT','SELECT','UPDATE','DELETE','INSERT','SELECT','UPDATE','DELETE','INSERT','SELECT','UPDATE','DELETE','INSERT','SELECT','UPDATE','DELETE','INSERT','SELECT','UPDATE','DELETE','INSERT','SELECT','UPDATE','DELETE','INSERT','SELECT','UPDATE','DELETE','INSERT','SELECT','UPDATE','DELETE','INSERT','SELECT','UPDATE','DELETE','INSERT','SELECT','UPDATE','DELETE','INSERT','SELECT','UPDATE','DELETE','INSERT','SELECT','UPDATE','DELETE','INSERT','SELECT','UPDATE','DELETE','INSERT','SELECT','UPDATE','DELETE','INSERT','SELECT','UPDATE','DELETE','INSERT','SELECT','UPDATE','DELETE','INSERT','SELECT','UPDATE','DELETE','INSERT','SELECT','UPDATE','DELETE','INSERT','SELECT','UPDATE','DELETE','INSERT','SELECT','UPDATE','DELETE','INSERT','SELECT','UPDATE','DELETE','INSERT','SELECT','UPDATE','EXECUTE','EXECUTE','DELETE','INSERT','SELECT','UPDATE','DELETE','INSERT','SELECT','UPDATE','DELETE','INSERT','SELECT','UPDATE','DELETE','INSERT','SELECT','UPDATE','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','DELETE','INSERT','SELECT','UPDATE','DELETE','INSERT','SELECT','UPDATE','DELETE','INSERT','SELECT','UPDATE','DELETE','INSERT','SELECT','UPDATE','DELETE','INSERT','SELECT','UPDATE','DELETE','INSERT','SELECT','UPDATE','DELETE','INSERT','SELECT','UPDATE','DELETE','INSERT','SELECT','UPDATE','DELETE','INSERT','SELECT','UPDATE','DELETE','INSERT','SELECT','UPDATE','DELETE','INSERT','SELECT','UPDATE','DELETE','INSERT','SELECT','UPDATE','DELETE','INSERT','SELECT','UPDATE','DELETE','INSERT','SELECT','UPDATE','DELETE','INSERT','SELECT','UPDATE','DELETE','INSERT','SELECT','UPDATE','DELETE','INSERT','SELECT','UPDATE','SELECT','DELETE','INSERT','SELECT','UPDATE','DELETE','INSERT','SELECT','UPDATE','SELECT','DELETE','INSERT','SELECT','UPDATE','SELECT','DELETE','INSERT','SELECT','UPDATE','SELECT','EXECUTE','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','DELETE','INSERT','SELECT','UPDATE','DELETE','INSERT','SELECT','UPDATE','DELETE','INSERT','SELECT','UPDATE','DELETE','INSERT','SELECT','UPDATE','DELETE',
								'INSERT','SELECT','UPDATE','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','EXECUTE','EXECUTE','EXECUTE','EXECUTE','EXECUTE','EXECUTE');
				t_PrivObjOwnerList := ObjList('SYS','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER',
								'NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','ELNPROD','ELNPROD','ELNPROD','ELNPROD','ELNPROD','ELNPROD','ELNPROD','ELNPROD','ELNPROD','ELNPROD','ELNPROD','ELNPROD');
				t_PrivObjNameList  := ObjList('V_$DATABASE','NGUSERPREFS','NGUSERPREFS','NGUSERPREFS','NGUSERPREFS','NGVOLUMELIFECYCLE','NGVOLUMELIFECYCLE','NGVOLUMELIFECYCLE','NGVOLUMELIFECYCLE','NGVOLUMECLONES','NGVOLUMECLONES','NGVOLUMECLONES','NGVOLUMECLONES','NGTABLES','NGTABLES','NGTABLES','NGTABLES','NGPROJMISCDATA','NGPROJMISCDATA','NGPROJMISCDATA','NGPROJMISCDATA','NGPROJVIEWFILTERS','NGPROJVIEWFILTERS','NGPROJVIEWFILTERS','NGPROJVIEWFILTERS','NGPROJVIEWFIELDS','NGPROJVIEWFIELDS','NGPROJVIEWFIELDS','NGPROJVIEWFIELDS','NGPROJDEFS_TOPURGE','NGPROJDEFS_TOPURGE','NGPROJDEFS_TOPURGE','NGPROJDEFS_TOPURGE','NGOBJNUMINFO','NGOBJNUMINFO','NGOBJNUMINFO','NGOBJNUMINFO','NGFIELDVAL','NGFIELDVAL','NGFIELDVAL','NGFIELDVAL','NGFIELDS','NGFIELDS','NGFIELDS','NGFIELDS','NGCONTENTMASTER','NGCONTENTMASTER','NGCONTENTMASTER','NGCONTENTMASTER','NGCONTENTDETAIL','NGCONTENTDETAIL','NGCONTENTDETAIL','NGCONTENTDETAIL','NGARCHIVEDEVICES','NGARCHIVEDEVICES','NGARCHIVEDEVICES','NGARCHIVEDEVICES','NGSERVERSTORES','NGSERVERSTORES','NGSERVERSTORES','NGSERVERSTORES','NGPROJSTORES','NGPROJSTORES','NGPROJSTORES','NGPROJSTORES','NGRETENTION_POLICY','NGRETENTION_POLICY','NGRETENTION_POLICY','NGRETENTION_POLICY','NGPOLICY_EVENTS','NGPOLICY_EVENTS','NGPOLICY_EVENTS','NGPOLICY_EVENTS','NGLEGAL_HOLD_ASSIGN','NGLEGAL_HOLD_ASSIGN','NGLEGAL_HOLD_ASSIGN','NGLEGAL_HOLD_ASSIGN','NGLEGAL_HOLD_DEF','NGLEGAL_HOLD_DEF','NGLEGAL_HOLD_DEF','NGLEGAL_HOLD_DEF','NGTAGSANDMODCOUNT','NGTAGSANDMODCOUNT','NGTAGSANDMODCOUNT','NGTAGSANDMODCOUNT','NGTAGS_VIEW','NGTAGS_VIEW','NGTAGS_VIEW','NGTAGS_VIEW','NGPROJDEFS_ALL','NGPROJDEFS_ALL','NGPROJDEFS_ALL','NGPROJDEFS_ALL','NGTAGS_INSERTVIEW','NGTAGS_INSERTVIEW','NGTAGS_INSERTVIEW','NGTAGS_INSERTVIEW','NGCONTENTMASTER_INSERTVIEW','NGCONTENTMASTER_INSERTVIEW','NGCONTENTMASTER_INSERTVIEW','NGCONTENTMASTER_INSERTVIEW','NGSDMS_CLOB_DEFINITIONS','NGSDMS_VERSION_DEFINITIONS','NGPROJDEFS','NGPROJDEFS','NGPROJDEFS','NGPROJDEFS','NGPROJVIEW','NGPROJVIEW','NGPROJVIEW','NGPROJVIEW','NGTAGS','NGTAGS','NGTAGS','NGTAGS','NGPROJTPL','NGPROJTPL','NGPROJTPL','NGPROJTPL','NGAUDITARCHIVEDEVICEVIEW','NGAUDITEMAILNOTIFYDETAILVIEW','NGAUDITEMAILNOTIFICATIONVIEW','NGAUDITNOTIFIERDETAILVIEW','NGAUDITNOTIFIERLISTVIEW','NGAUDITPRIVSDETAILVIEW','NGAUDITPRIVSVIEW','NGAUDITPROJECTS1005DETAILVIEW','NGAUDITPROJECTS1006DETAILVIEW','NGAUDITPROJECTS1007DETAILVIEW','NGAUDITPROJECTS1008DETAILVIEW','NGAUDITPROJECTS1009DETAILVIEW',
								'NGAUDITPROJECTSVIEW','NGAUDITREASONSDETAILVIEW','NGAUDITREASONSVIEW','NGAUDITREPORTSDETAILVIEW','NGAUDITEVENT2010DETAILVIEW','NGAUDITSERVERLOCATIONVIEW','NGAUDITSERVERSERVERVIEW','NGAUDITSERVERSERVER6204VIEW','NGAUDITSERVERSERVER6205VIEW','NGAUDITSERVERSERVER6206VIEW','NGAUDITSERVER6050DETAILVIEW','NGAUDITSERVERLICENSEDETAILVIEW','NGAUDITSERVERVIEWS','NGAUDITTEMPLATESVIEW','NGAUDITSCRIPTSVIEW','NGAUDITARCHTEMPLATESVIEW','NGAUDITARCHEXCEPTLISTVIEW','NGAUDITSEARCHGROUPSVIEW','NGAUDITUSERGROUPVIEW','NGAUDITGROUPMEMBERDETAILVIEW','NGAUDITUSERVIEW','NGCONFIG','NGCONFIG','NGCONFIG','NGCONFIG','NGLOCKDETAILS','NGLOCKDETAILS','NGLOCKDETAILS','NGLOCKDETAILS','NGTEMPTBL','NGTEMPTBL','NGTEMPTBL','NGTEMPTBL','NGNOTIFY','NGNOTIFY','NGNOTIFY','NGNOTIFY','NGAUDITCATEGORIES','NGAUDITCATEGORIES','NGAUDITCATEGORIES','NGAUDITCATEGORIES','NGAUDITMASTERVIEWS','NGAUDITMASTERVIEWS','NGAUDITMASTERVIEWS','NGAUDITMASTERVIEWS','NGAUDITDETAILSVIEWS','NGAUDITDETAILSVIEWS','NGAUDITDETAILSVIEWS','NGAUDITDETAILSVIEWS','NGAUTHMODESMAP','NGAUTHMODESMAP','NGAUTHMODESMAP','NGAUTHMODESMAP','NGSTRINGLOOKUP','NGSTRINGLOOKUP','NGSTRINGLOOKUP','NGSTRINGLOOKUP','NGUSERSAUTHMODE','NGUSERSAUTHMODE','NGUSERSAUTHMODE','NGUSERSAUTHMODE','NGUSERS','NGUSERS','NGUSERS','NGUSERS','NGSERVERPROJINFO','NGSERVERPROJINFO','NGSERVERPROJINFO','NGSERVERPROJINFO','NGSCHEMAINSTALLEDINFO','NGSCHEMAINSTALLEDINFO','NGSCHEMAINSTALLEDINFO','NGSCHEMAINSTALLEDINFO','NGPROXYINFO','NGPROXYINFO','NGPROXYINFO','NGPROXYINFO','NGAPPINFO','NGAPPINFO','NGAPPINFO','NGAPPINFO','NGLOCKINFO','NGLOCKINFO','NGLOCKINFO','NGLOCKINFO','NGCHECKVALUES','NGCHECKVALUES','NGCHECKVALUES','NGCHECKVALUES','NGPWDCHGPROC','NGVIEWMETADATA','NGVIEWMETADATA','NGVIEWMETADATA','NGVIEWMETADATA','NGEMAILALERTS','NGEMAILALERTS','NGEMAILALERTS','NGEMAILALERTS','NGAUDITSEQ','NGCHECKPOINTS','NGCHECKPOINTS','NGCHECKPOINTS','NGCHECKPOINTS','NGUSERSANDGROUPS','NGUSERSANDAUTHMODE_VIEW','NGUSERSANDAUTHMODE_VIEW','NGUSERSANDAUTHMODE_VIEW','NGUSERSANDAUTHMODE_VIEW','NGAUDITREPORTSVIEW','NGSDMS60_DEFINITIONS','NGAUDITVIEWSDETAILVIEW','NGAUDITVIEWSVIEW','NGAUDITVOLUMELIFECYCLEVIEW','NGAUDITPOLICYVIEW','NGAUDITPOLICYDETAILVIEW','NGAUDITLEGALHOLDVIEW','NGGROUPS','NGGROUPS','NGGROUPS','NGGROUPS','NGGROUPMEMBERS','NGGROUPMEMBERS','NGGROUPMEMBERS','NGGROUPMEMBERS','NGAUDITDETAILS','NGAUDITDETAILS','NGAUDITDETAILS','NGAUDITDETAILS','NGAUDITMASTER','NGAUDITMASTER',
								'NGAUDITMASTER','NGAUDITMASTER','NGPRIVILEGE','NGPRIVILEGE','NGPRIVILEGE','NGPRIVILEGE','USERS','LABGROUP','FUNCTION','LABGROUPEMPLOYEE','GROUPS','EMPLOYEE','ELN_GET_BUILD_INFO','ELN_UPDATE_LABGROUPEMPLOYEE','ELN_UPDATE_USER_OTHER_PROPS','ELN_CREATE_LABGROUPEMPLOYEE','ELN_UPDATE_USER','ELN_DELETE_USER');
			ELSIF (:v_LMSSchemaVerAsNum >= 9100 AND :v_LMSSchemaVerAsNum < 9300)	THEN
				t_PrivNameList     := ObjList('DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE',
								'UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','EXECUTE','EXECUTE','EXECUTE','EXECUTE','EXECUTE','EXECUTE','EXECUTE','EXECUTE','EXECUTE','EXECUTE','EXECUTE','EXECUTE','EXECUTE','EXECUTE','EXECUTE','EXECUTE','EXECUTE','EXECUTE','EXECUTE','EXECUTE');
				t_PrivObjOwnerList := ObjList('NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','SYS','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER',
								'NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','ELNPROD','ELNPROD','ELNPROD','ELNPROD','ELNPROD','ELNPROD','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSDMS60','NGSDMS60','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','ELNPROD','ELNPROD','ELNPROD','ELNPROD','ELNPROD','ELNPROD','ELNPROD','ELNPROD');
				t_PrivObjNameList  := ObjList('NGUSERPREFS','NGVOLUMELIFECYCLE','NGVOLUMECLONES','NGTAGS','NGTABLES','NGPROJMISCDATA','NGPROJVIEWFILTERS','NGPROJVIEWFIELDS','NGPROJTPL','NGPROJDEFS_TOPURGE','NGOBJNUMINFO','NGFIELDVAL','NGFIELDS','NGCONTENTMASTER','NGCONTENTDETAIL','NGARCHIVEDEVICES','NGSERVERSTORES','NGPROJSTORES','NGRETENTION_POLICY','NGPOLICY_EVENTS','NGLEGAL_HOLD_ASSIGN','NGLEGAL_HOLD_DEF','NGTAGSANDMODCOUNT','NGTAGS_VIEW','NGPROJDEFS_ALL','NGTAGS_INSERTVIEW','NGCONTENTMASTER_INSERTVIEW','NGPROJDEFS','NGPROJVIEW','NGCONFIG','NGLOCKDETAILS','NGTEMPTBL','NGNOTIFY','NGAUDITCATEGORYGROUPS','NGAUDITCATEGORIES','NGAUDITMASTERVIEWS','NGAUDITDETAILSVIEWS','NGAUTHMODESMAP','NGSTRINGLOOKUP','NGUSERSAUTHMODE','NGUSERS','NGSERVERPROJINFO','NGSCHEMAINSTALLEDINFO','NGPROXYINFO','NGAPPINFO','NGLOCKINFO','NGCHECKVALUES','NGVIEWMETADATA','NGEMAILALERTS','NGUSERREFRESHTOKENS','NGCHECKPOINTS','NGUSERSANDAUTHMODE_VIEW','NGPRIVILEGE','NGGROUPS','NGGROUPMEMBERS','NGAUDITDETAILS','NGAUDITMASTER','NGUSERPREFS','NGVOLUMELIFECYCLE','NGVOLUMECLONES','NGTAGS','NGTABLES','NGPROJMISCDATA','NGPROJVIEWFILTERS','NGPROJVIEWFIELDS','NGPROJTPL','NGPROJDEFS_TOPURGE','NGOBJNUMINFO','NGFIELDVAL','NGFIELDS','NGCONTENTMASTER','NGCONTENTDETAIL','NGARCHIVEDEVICES','NGSERVERSTORES','NGPROJSTORES','NGRETENTION_POLICY','NGPOLICY_EVENTS','NGLEGAL_HOLD_ASSIGN','NGLEGAL_HOLD_DEF','NGTAGSANDMODCOUNT','NGTAGS_VIEW','NGPROJDEFS_ALL','NGTAGS_INSERTVIEW','NGCONTENTMASTER_INSERTVIEW','NGPROJDEFS','NGPROJVIEW','NGCONFIG','NGLOCKDETAILS','NGTEMPTBL','NGNOTIFY','NGAUDITCATEGORYGROUPS','NGAUDITCATEGORIES','NGAUDITMASTERVIEWS','NGAUDITDETAILSVIEWS','NGAUTHMODESMAP','NGSTRINGLOOKUP','NGUSERSAUTHMODE','NGUSERS','NGSERVERPROJINFO','NGSCHEMAINSTALLEDINFO','NGPROXYINFO','NGAPPINFO','NGLOCKINFO','NGCHECKVALUES','NGVIEWMETADATA','NGEMAILALERTS','NGUSERREFRESHTOKENS','NGCHECKPOINTS','NGUSERSANDAUTHMODE_VIEW','NGPRIVILEGE','NGGROUPS','NGGROUPMEMBERS','NGAUDITDETAILS','NGAUDITMASTER','V_$DATABASE','NGUSERPREFS','NGVOLUMELIFECYCLE','NGVOLUMECLONES','NGTAGS','NGTABLES','NGPROJMISCDATA','NGPROJVIEWFILTERS','NGPROJVIEWFIELDS','NGPROJTPL','NGPROJDEFS_TOPURGE','NGOBJNUMINFO','NGFIELDVAL','NGFIELDS','NGCONTENTMASTER','NGCONTENTDETAIL','NGARCHIVEDEVICES','NGSERVERSTORES','NGPROJSTORES','NGRETENTION_POLICY','NGPOLICY_EVENTS','NGLEGAL_HOLD_ASSIGN','NGLEGAL_HOLD_DEF','NGTAGSANDMODCOUNT','NGTAGS_VIEW','NGPROJDEFS_ALL','NGTAGS_INSERTVIEW','NGCONTENTMASTER_INSERTVIEW',
								'NGPROJDEFS','NGPROJVIEW','NGCONFIG','NGLOCKDETAILS','NGTEMPTBL','NGNOTIFY','NGAUDITCATEGORYGROUPS','NGAUDITCATEGORIES','NGAUDITMASTERVIEWS','NGAUDITDETAILSVIEWS','NGAUTHMODESMAP','NGSTRINGLOOKUP','NGUSERSAUTHMODE','NGUSERS','NGSERVERPROJINFO','NGSCHEMAINSTALLEDINFO','NGPROXYINFO','NGAPPINFO','NGLOCKINFO','NGCHECKVALUES','NGPWDCHGPROC','NGVIEWMETADATA','NGEMAILALERTS','NGUSERREFRESHTOKENS','NGAUDITSEQ','NGCHECKPOINTS','NGUSERSANDGROUPS','NGUSERSANDAUTHMODE_VIEW','NGAUDITREPORTSVIEW','NGAUDITARCHIVEDEVICEVIEW','NGAUDITEMAILNOTIFYDETAILVIEW','NGAUDITEMAILNOTIFICATIONVIEW','NGAUDITNOTIFIERDETAILVIEW','NGAUDITNOTIFIERLISTVIEW','NGAUDITPRIVSDETAILVIEW','NGAUDITPRIVSVIEW','NGAUDITPROJECTS1005DETAILVIEW','NGAUDITPROJECTS1006DETAILVIEW','NGAUDITPROJECTS1007DETAILVIEW','NGAUDITPROJECTS1008DETAILVIEW','NGAUDITPROJECTS1009DETAILVIEW','NGAUDITPROJECTSVIEW','NGAUDITREASONSDETAILVIEW','NGAUDITREASONSVIEW','NGAUDITREPORTSDETAILVIEW','NGAUDITEVENT2010DETAILVIEW','NGAUDITSERVERLOCATIONVIEW','NGAUDITSERVERSERVERVIEW','NGAUDITSERVERSERVER6204VIEW','NGAUDITSERVERSERVER6205VIEW','NGAUDITSERVERSERVER6206VIEW','NGAUDITSERVER6050DETAILVIEW','NGAUDITSERVERLICENSEDETAILVIEW','NGAUDITSERVERVIEWS','NGAUDITTEMPLATESVIEW','NGAUDITSCRIPTSVIEW','NGAUDITARCHTEMPLATESVIEW','NGAUDITARCHEXCEPTLISTVIEW','NGAUDITSEARCHGROUPSVIEW','NGAUDITUSERGROUPVIEW','NGAUDITGROUPMEMBERDETAILVIEW','NGAUDITUSERVIEW','NGAUDITVIEWSDETAILVIEW','NGAUDITVIEWSVIEW','NGAUDITVOLUMELIFECYCLEVIEW','NGAUDITPOLICYVIEW','NGAUDITPOLICYDETAILVIEW','NGAUDITLEGALHOLDVIEW','NGPRIVILEGE','NGGROUPS','NGGROUPMEMBERS','NGAUDITDETAILS','NGAUDITMASTER','VP_EMPLOYEE_VIEW','VP_FUNCTION_VIEW','VP_GROUPS_VIEW','VP_LABGROUP_VIEW','VP_LABGROUPEMPLOYEE_VIEW','VP_USERS_VIEW','EMPLOYEE','USERS','LABGROUP','LABGROUPEMPLOYEE','FUNCTION','GROUPS','NGUSERPREFS','NGVOLUMELIFECYCLE','NGVOLUMECLONES','NGTAGS','NGTABLES','NGPROJMISCDATA','NGPROJVIEWFILTERS','NGPROJVIEWFIELDS','NGPROJTPL','NGPROJDEFS_TOPURGE','NGOBJNUMINFO','NGFIELDVAL','NGFIELDS','NGCONTENTMASTER','NGCONTENTDETAIL','NGARCHIVEDEVICES','NGSERVERSTORES','NGPROJSTORES','NGRETENTION_POLICY','NGPOLICY_EVENTS','NGLEGAL_HOLD_ASSIGN','NGLEGAL_HOLD_DEF','NGTAGSANDMODCOUNT','NGTAGS_VIEW','NGPROJDEFS_ALL','NGTAGS_INSERTVIEW','NGCONTENTMASTER_INSERTVIEW','NGPROJDEFS','NGPROJVIEW','NGCONFIG','NGLOCKDETAILS','NGTEMPTBL','NGNOTIFY','NGAUDITCATEGORYGROUPS','NGAUDITCATEGORIES','NGAUDITMASTERVIEWS',
								'NGAUDITDETAILSVIEWS','NGAUTHMODESMAP','NGSTRINGLOOKUP','NGUSERSAUTHMODE','NGUSERS','NGSERVERPROJINFO','NGSCHEMAINSTALLEDINFO','NGPROXYINFO','NGAPPINFO','NGLOCKINFO','NGCHECKVALUES','NGVIEWMETADATA','NGEMAILALERTS','NGUSERREFRESHTOKENS','NGCHECKPOINTS','NGUSERSANDAUTHMODE_VIEW','NGPRIVILEGE','NGGROUPS','NGGROUPMEMBERS','NGAUDITDETAILS','NGAUDITMASTER','NGSDMS_CLOB_DEFINITIONS','NGSDMS_VERSION_DEFINITIONS','VP_DATA_LCN_CONFIG_LOAD','VP_DATA_LCN_CONFIG_SAVE','VP_DATA_LCN_CONFIG_TEST','NGSDMS60USERMGMT','NGSDMS60_DEFINITIONS','VP_ELN_GET_BUILD_INFO_PROC','VP_ELN_UPDATE_USER_OTHER_P_P','VP_ELN_CREATE_LGE_PROC','VP_ELN_UPDATE_LGE_PROC','VP_ELN_DELETE_LGE_PROC','ELN_GET_BUILD_INFO','ELN_UPDATE_LABGROUPEMPLOYEE','ELN_CREATE_USER','ELN_DELETE_USER','ELN_CREATE_LABGROUPEMPLOYEE','ELN_UPDATE_USER_OTHER_PROPS','ELN_DELETE_LABGROUPEMPLOYEE','ELN_UPDATE_USER');
			ELSIF (:v_LMSSchemaVerAsNum >= 9300)					THEN
				t_PrivNameList     := ObjList('DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','DELETE','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','INSERT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','SELECT','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE',
								'UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','EXECUTE','EXECUTE','EXECUTE','EXECUTE','EXECUTE','EXECUTE','EXECUTE','EXECUTE','EXECUTE','EXECUTE','EXECUTE','EXECUTE','EXECUTE','EXECUTE','EXECUTE','EXECUTE','EXECUTE','EXECUTE','EXECUTE','EXECUTE','INSERT','UPDATE','DELETE','SELECT');
				t_PrivObjOwnerList := ObjList('NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','SYS','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER',
								'NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','ELNPROD','ELNPROD','ELNPROD','ELNPROD','ELNPROD','ELNPROD','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSDMS60','NGSDMS60','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','NGSYSUSER','ELNPROD','ELNPROD','ELNPROD','ELNPROD','ELNPROD','ELNPROD','ELNPROD','ELNPROD','NGSDMS60','NGSDMS60','NGSDMS60','NGSDMS60');
				t_PrivObjNameList  := ObjList('NGUSERPREFS','NGVOLUMELIFECYCLE','NGVOLUMECLONES','NGTAGS','NGTABLES','NGPROJMISCDATA','NGPROJVIEWFILTERS','NGPROJVIEWFIELDS','NGPROJTPL','NGPROJDEFS_TOPURGE','NGOBJNUMINFO','NGFIELDVAL','NGFIELDS','NGCONTENTMASTER','NGCONTENTDETAIL','NGARCHIVEDEVICES','NGSERVERSTORES','NGPROJSTORES','NGRETENTION_POLICY','NGPOLICY_EVENTS','NGLEGAL_HOLD_ASSIGN','NGLEGAL_HOLD_DEF','NGTAGSANDMODCOUNT','NGTAGS_VIEW','NGPROJDEFS_ALL','NGTAGS_INSERTVIEW','NGCONTENTMASTER_INSERTVIEW','NGPROJDEFS','NGPROJVIEW','NGCONFIG','NGLOCKDETAILS','NGTEMPTBL','NGNOTIFY','NGAUDITCATEGORYGROUPS','NGAUDITCATEGORIES','NGAUDITMASTERVIEWS','NGAUDITDETAILSVIEWS','NGAUTHMODESMAP','NGSTRINGLOOKUP','NGUSERSAUTHMODE','NGUSERS','NGSERVERPROJINFO','NGSCHEMAINSTALLEDINFO','NGPROXYINFO','NGAPPINFO','NGLOCKINFO','NGCHECKVALUES','NGVIEWMETADATA','NGEMAILALERTS','NGUSERREFRESHTOKENS','NGCHECKPOINTS','NGUSERSANDAUTHMODE_VIEW','NGPRIVILEGE','NGGROUPS','NGGROUPMEMBERS','NGAUDITDETAILS','NGAUDITMASTER','NGUSERPREFS','NGVOLUMELIFECYCLE','NGVOLUMECLONES','NGTAGS','NGTABLES','NGPROJMISCDATA','NGPROJVIEWFILTERS','NGPROJVIEWFIELDS','NGPROJTPL','NGPROJDEFS_TOPURGE','NGOBJNUMINFO','NGFIELDVAL','NGFIELDS','NGCONTENTMASTER','NGCONTENTDETAIL','NGARCHIVEDEVICES','NGSERVERSTORES','NGPROJSTORES','NGRETENTION_POLICY','NGPOLICY_EVENTS','NGLEGAL_HOLD_ASSIGN','NGLEGAL_HOLD_DEF','NGTAGSANDMODCOUNT','NGTAGS_VIEW','NGPROJDEFS_ALL','NGTAGS_INSERTVIEW','NGCONTENTMASTER_INSERTVIEW','NGPROJDEFS','NGPROJVIEW','NGCONFIG','NGLOCKDETAILS','NGTEMPTBL','NGNOTIFY','NGAUDITCATEGORYGROUPS','NGAUDITCATEGORIES','NGAUDITMASTERVIEWS','NGAUDITDETAILSVIEWS','NGAUTHMODESMAP','NGSTRINGLOOKUP','NGUSERSAUTHMODE','NGUSERS','NGSERVERPROJINFO','NGSCHEMAINSTALLEDINFO','NGPROXYINFO','NGAPPINFO','NGLOCKINFO','NGCHECKVALUES','NGVIEWMETADATA','NGEMAILALERTS','NGUSERREFRESHTOKENS','NGCHECKPOINTS','NGUSERSANDAUTHMODE_VIEW','NGPRIVILEGE','NGGROUPS','NGGROUPMEMBERS','NGAUDITDETAILS','NGAUDITMASTER','V_$DATABASE','NGUSERPREFS','NGVOLUMELIFECYCLE','NGVOLUMECLONES','NGTAGS','NGTABLES','NGPROJMISCDATA','NGPROJVIEWFILTERS','NGPROJVIEWFIELDS','NGPROJTPL','NGPROJDEFS_TOPURGE','NGOBJNUMINFO','NGFIELDVAL','NGFIELDS','NGCONTENTMASTER','NGCONTENTDETAIL','NGARCHIVEDEVICES','NGSERVERSTORES','NGPROJSTORES','NGRETENTION_POLICY','NGPOLICY_EVENTS','NGLEGAL_HOLD_ASSIGN','NGLEGAL_HOLD_DEF','NGTAGSANDMODCOUNT','NGTAGS_VIEW','NGPROJDEFS_ALL','NGTAGS_INSERTVIEW','NGCONTENTMASTER_INSERTVIEW',
								'NGPROJDEFS','NGPROJVIEW','NGCONFIG','NGLOCKDETAILS','NGTEMPTBL','NGNOTIFY','NGAUDITCATEGORYGROUPS','NGAUDITCATEGORIES','NGAUDITMASTERVIEWS','NGAUDITDETAILSVIEWS','NGAUTHMODESMAP','NGSTRINGLOOKUP','NGUSERSAUTHMODE','NGUSERS','NGSERVERPROJINFO','NGSCHEMAINSTALLEDINFO','NGPROXYINFO','NGAPPINFO','NGLOCKINFO','NGCHECKVALUES','NGPWDCHGPROC','NGVIEWMETADATA','NGEMAILALERTS','NGUSERREFRESHTOKENS','NGAUDITSEQ','NGCHECKPOINTS','NGUSERSANDGROUPS','NGUSERSANDAUTHMODE_VIEW','NGAUDITREPORTSVIEW','NGAUDITARCHIVEDEVICEVIEW','NGAUDITEMAILNOTIFYDETAILVIEW','NGAUDITEMAILNOTIFICATIONVIEW','NGAUDITNOTIFIERDETAILVIEW','NGAUDITNOTIFIERLISTVIEW','NGAUDITPRIVSDETAILVIEW','NGAUDITPRIVSVIEW','NGAUDITPROJECTS1005DETAILVIEW','NGAUDITPROJECTS1006DETAILVIEW','NGAUDITPROJECTS1007DETAILVIEW','NGAUDITPROJECTS1008DETAILVIEW','NGAUDITPROJECTS1009DETAILVIEW','NGAUDITPROJECTSVIEW','NGAUDITREASONSDETAILVIEW','NGAUDITREASONSVIEW','NGAUDITREPORTSDETAILVIEW','NGAUDITEVENT2010DETAILVIEW','NGAUDITSERVERLOCATIONVIEW','NGAUDITSERVERSERVERVIEW','NGAUDITSERVERSERVER6204VIEW','NGAUDITSERVERSERVER6205VIEW','NGAUDITSERVERSERVER6206VIEW','NGAUDITSERVER6050DETAILVIEW','NGAUDITSERVERLICENSEDETAILVIEW','NGAUDITSERVERVIEWS','NGAUDITTEMPLATESVIEW','NGAUDITSCRIPTSVIEW','NGAUDITARCHTEMPLATESVIEW','NGAUDITARCHEXCEPTLISTVIEW','NGAUDITSEARCHGROUPSVIEW','NGAUDITUSERGROUPVIEW','NGAUDITGROUPMEMBERDETAILVIEW','NGAUDITUSERVIEW','NGAUDITVIEWSDETAILVIEW','NGAUDITVIEWSVIEW','NGAUDITVOLUMELIFECYCLEVIEW','NGAUDITPOLICYVIEW','NGAUDITPOLICYDETAILVIEW','NGAUDITLEGALHOLDVIEW','NGPRIVILEGE','NGGROUPS','NGGROUPMEMBERS','NGAUDITDETAILS','NGAUDITMASTER','VP_EMPLOYEE_VIEW','VP_FUNCTION_VIEW','VP_GROUPS_VIEW','VP_LABGROUP_VIEW','VP_LABGROUPEMPLOYEE_VIEW','VP_USERS_VIEW','EMPLOYEE','USERS','LABGROUP','LABGROUPEMPLOYEE','FUNCTION','GROUPS','NGUSERPREFS','NGVOLUMELIFECYCLE','NGVOLUMECLONES','NGTAGS','NGTABLES','NGPROJMISCDATA','NGPROJVIEWFILTERS','NGPROJVIEWFIELDS','NGPROJTPL','NGPROJDEFS_TOPURGE','NGOBJNUMINFO','NGFIELDVAL','NGFIELDS','NGCONTENTMASTER','NGCONTENTDETAIL','NGARCHIVEDEVICES','NGSERVERSTORES','NGPROJSTORES','NGRETENTION_POLICY','NGPOLICY_EVENTS','NGLEGAL_HOLD_ASSIGN','NGLEGAL_HOLD_DEF','NGTAGSANDMODCOUNT','NGTAGS_VIEW','NGPROJDEFS_ALL','NGTAGS_INSERTVIEW','NGCONTENTMASTER_INSERTVIEW','NGPROJDEFS','NGPROJVIEW','NGCONFIG','NGLOCKDETAILS','NGTEMPTBL','NGNOTIFY','NGAUDITCATEGORYGROUPS','NGAUDITCATEGORIES','NGAUDITMASTERVIEWS',
								'NGAUDITDETAILSVIEWS','NGAUTHMODESMAP','NGSTRINGLOOKUP','NGUSERSAUTHMODE','NGUSERS','NGSERVERPROJINFO','NGSCHEMAINSTALLEDINFO','NGPROXYINFO','NGAPPINFO','NGLOCKINFO','NGCHECKVALUES','NGVIEWMETADATA','NGEMAILALERTS','NGUSERREFRESHTOKENS','NGCHECKPOINTS','NGUSERSANDAUTHMODE_VIEW','NGPRIVILEGE','NGGROUPS','NGGROUPMEMBERS','NGAUDITDETAILS','NGAUDITMASTER','NGSDMS_CLOB_DEFINITIONS','NGSDMS_VERSION_DEFINITIONS','VP_DATA_LCN_CONFIG_LOAD','VP_DATA_LCN_CONFIG_SAVE','VP_DATA_LCN_CONFIG_TEST','NGSDMS60USERMGMT','NGSDMS60_DEFINITIONS','VP_ELN_GET_BUILD_INFO_PROC','VP_ELN_UPDATE_USER_OTHER_P_P','VP_ELN_CREATE_LGE_PROC','VP_ELN_UPDATE_LGE_PROC','VP_ELN_DELETE_LGE_PROC','ELN_GET_BUILD_INFO','ELN_UPDATE_LABGROUPEMPLOYEE','ELN_CREATE_USER','ELN_DELETE_USER','ELN_CREATE_LABGROUPEMPLOYEE','ELN_UPDATE_USER_OTHER_PROPS','ELN_DELETE_LABGROUPEMPLOYEE','ELN_UPDATE_USER','NGUSERPREFERENCES','NGUSERPREFERENCES','NGUSERPREFERENCES','NGUSERPREFERENCES');
			ELSE
				t_PrivNameList     := ObjList();
				t_PrivObjOwnerList := ObjList();
				t_PrivObjNameList  := ObjList();
			END IF;		
		ELSIF (v_SchemaName = 'SPSV')			THEN
			t_PrivNameList     := ObjList('EXECUTE');
			t_PrivObjOwnerList := ObjList('CTXSYS');
			t_PrivObjNameList  := ObjList('CTX_DDL');
		ELSIF (v_SchemaName = 'NGPASSWDROLE')		THEN
			t_PrivNameList     := ObjList('EXECUTE');
			t_PrivObjOwnerList := ObjList('NGSYSUSER');
			t_PrivObjNameList  := ObjList('CHANGE_PSWD');
		ELSIF (v_SchemaName = 'ELNPROD')		THEN
			IF (:v_LMSSchemaVerAsNum >= 9000 AND :v_LMSSchemaVerAsNum < 9100)	THEN
				t_PrivNameList     := ObjList('SELECT','EXECUTE');
				t_PrivObjOwnerList := ObjList('SYS','CTXSYS');
				t_PrivObjNameList  := ObjList('V_$DATABASE','CTX_DDL');
			ELSIF (:v_LMSSchemaVerAsNum >= 9100)	THEN
				t_PrivNameList     := ObjList('SELECT','EXECUTE','SELECT','SELECT','SELECT','SELECT');
				t_PrivObjOwnerList := ObjList('SYS','CTXSYS','NGSDMS60','NGSDMS60','NGSYSUSER','NGSYSUSER');
				t_PrivObjNameList  := ObjList('V_$DATABASE','CTX_DDL','NGTAGS','NGPROJDEFS','NGUSERS','NGUSERSAUTHMODE');
			ELSE
				t_PrivNameList     := ObjList();
				t_PrivObjOwnerList := ObjList();
				t_PrivObjNameList  := ObjList();
			END IF;
		END IF;

		v_ExpectedNo := t_PrivNameList.COUNT;
		SELECT COUNT(*) INTO v_Count FROM dba_tab_privs WHERE grantee = v_SchemaName;
		IF (v_Count = v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE (v_SchemaName||' has been granted the expected number of object privileges: ('||v_ExpectedNo||' expected, '||v_Count||' found).');
		ELSIF (v_Count < v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE ('!!!!! ERROR: '||v_SchemaName||' has not been granted the expected number of object privileges: ('||v_ExpectedNo||' expected, '||v_Count||' found)!');
		ELSIF (v_Count > v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE (v_SchemaName||' has been granted more than the expected number of object privileges: ('||v_ExpectedNo||' expected, '||v_Count||' found).');
		END IF;
	
		FOR indx2 IN 1.. t_PrivNameList.COUNT
		LOOP
			v_PrivName := t_PrivNameList(indx2);
			v_ObjOwner := t_PrivObjOwnerList(indx2);
			v_ObjName  := t_PrivObjNameList(indx2);
			SELECT COUNT(*) INTO v_Count FROM dba_tab_privs WHERE grantee = v_SchemaName AND privilege = v_PrivName AND owner = v_ObjOwner AND table_name = v_ObjName;
			IF (v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE ('-- '||v_SchemaName||' has been granted '||v_PrivName||' on '||v_ObjOwner||'.'||v_ObjName);
			ELSE				DBMS_OUTPUT.PUT_LINE ('-- !!!!! ERROR: '||v_SchemaName||' has NOT been granted '||v_PrivName||' on '||v_ObjOwner||'.'||v_ObjName||'!');
			END IF;
		END LOOP;

		DBMS_OUTPUT.PUT_LINE ('.');
	END LOOP;
END;
/

PROMPT
PROMPT
PROMPT ________________________________________________________________________________________________________
PROMPT Determining if the sdms 9 schema contains the correct number of roles ...
PROMPT At least one role: (ngsdms70proxyrole) should be present
PROMPT
DECLARE	
v_Count		INTEGER;
v_RoleName	VARCHAR2(100);

BEGIN
	v_RoleName := 'NGSDMS70PROXYROLE';
	SELECT COUNT(ROLE) INTO v_Count FROM DBA_ROLES WHERE ROLE IN (v_RoleName);
	IF (v_count = 1)	THEN	DBMS_OUTPUT.PUT_LINE ('The nugenesis role '||v_RoleName||' is present.');
	ELSIF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE ('!!!!! ERROR: the nugenesis role '||v_RoleName||' has not been created!');
	END IF;

	v_RoleName := 'NGPASSWDROLE';
	SELECT COUNT(ROLE) INTO v_Count FROM DBA_ROLES WHERE ROLE IN (v_RoleName);
	IF (v_count = 1)	THEN	DBMS_OUTPUT.PUT_LINE ('The nugenesis role '||v_RoleName||' is present.');
	ELSIF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE ('The nugenesis role '||v_RoleName||' has not been created.  This is OK; this role is optional.');
	END IF;
END;
/

PROMPT
PROMPT
PROMPT ________________________________________________________________________________________________________
PROMPT Determining if ngsdms70proxyrole has been granted to the expected accounts ...
PROMPT
DECLARE 
v_count		INTEGER;
v_user		VARCHAR2(50);
v_ExpectedNo	PLS_INTEGER;

TYPE ObjList		IS TABLE OF VARCHAR2(500);
t_SchemaList		ObjList;

BEGIN
	t_SchemaList := ObjList('SYS','NGPROXY');
	v_ExpectedNo := t_SchemaList.COUNT;

	SELECT COUNT(GRANTEE) INTO v_Count FROM DBA_ROLE_PRIVS WHERE GRANTED_ROLE = 'NGSDMS70PROXYROLE';
	IF (v_count >= v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE ('The ngsdms70proxyrole role has been granted to the expected number of user accounts: (at least '||v_ExpectedNo||' expected, '||v_Count||' found).');
	ELSE					DBMS_OUTPUT.PUT_LINE ('!!!!! ERROR: The ngsdms70proxyrole role has NOT been granted to the expected number of user accounts: ('||v_ExpectedNo||' expected, '||v_Count||' found)!');
	END IF;

	FOR indx IN 1 .. t_SchemaList.COUNT
	LOOP
		v_user := t_SchemaList(indx);
		SELECT COUNT(GRANTEE) INTO v_Count FROM DBA_ROLE_PRIVS WHERE GRANTED_ROLE = 'NGSDMS70PROXYROLE' AND grantee IN (v_user);
		IF (v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE ('-- ngsdms70proxyrole has been granted to '||v_user);
		ELSE				DBMS_OUTPUT.PUT_LINE ('-- !!!!! ERROR: ngsdms70proxyrole has not been granted to '||v_user||'!');
		END IF;
	END LOOP;
END;
/

PROMPT
PROMPT ________________________________________________________________________________________________________
PROMPT Determining if the necessary object privileges are present for SDMS email notifications ...
PROMPT
DECLARE 
v_Count		INTEGER;
v_ExpectedNo	INTEGER;

BEGIN
	v_ExpectedNo := 1;
	-- SDMS requires access to the Oracle packages utl_tcp and utl_smtp, either through grants to the PUBLIC account or through grants to NGSYSUSER.

	SELECT COUNT(*) INTO v_Count FROM DBA_TAB_PRIVS WHERE GRANTEE='PUBLIC' AND table_name = 'UTL_TCP' AND privilege = 'EXECUTE';
	IF (v_count >= v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE ('PUBLIC has execute rights on the UTL_TCP package.');
	ELSE
		SELECT COUNT(*) INTO v_Count FROM DBA_TAB_PRIVS WHERE GRANTEE='NGSYSUSER' AND table_name = 'UTL_TCP' AND privilege = 'EXECUTE';
		IF (v_count >= v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE ('NGSYSUSER has execute rights on the UTL_TCP package.');
		ELSE					DBMS_OUTPUT.PUT_LINE ('!!! WARNING: Neither PUBLIC nor NGSYSUSER have been granted EXECUTE on the package UTL_TCP!  SDMS will not be able to send email notifications!');
		END IF;
	END IF;

	SELECT COUNT(*) INTO v_Count FROM DBA_TAB_PRIVS WHERE GRANTEE='PUBLIC' AND table_name = 'UTL_SMTP' AND privilege = 'EXECUTE';
	IF (v_count >= v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE ('PUBLIC has execute rights on the UTL_SMTP package.');
	ELSE
		SELECT COUNT(*) INTO v_Count FROM DBA_TAB_PRIVS WHERE GRANTEE='NGSYSUSER' AND table_name = 'UTL_SMTP' AND privilege = 'EXECUTE';
		IF (v_count >= v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE ('NGSYSUSER has execute rights on the UTL_SMTP package.');
		ELSE					DBMS_OUTPUT.PUT_LINE ('!!! WARNING: Neither PUBLIC nor NGSYSUSER have been granted EXECUTE on the package UTL_SMTP!  SDMS will not be able to send email notifications!');
		END IF;
	END IF;
END;
/

PROMPT
PROMPT ________________________________________________________________________________________________________
PROMPT

COLUMN role		FORMAT A30
COLUMN TABLE_NAME 	FORMAT A35
COLUMN GRANTEE		FORMAT A20
COLUMN GRANTOR		FORMAT A10
COLUMN PRIVILEGE	FORMAT A10
COLUMN granted_role	FORMAT A30

PROMPT
PROMPT
PROMPT LIST OF NUGENESIS ROLES:
SELECT role, role_id FROM DBA_ROLES WHERE ROLE LIKE 'NG%';

PROMPT
PROMPT
PROMPT List of object privileges granted the NuGenesis schemas and roles:
SELECT grantee, privilege, grantor, table_name FROM DBA_TAB_PRIVS WHERE grantee IN ('NGSDMS70PROXYROLE','NGSTATICUSER','NGPROXY','NGSDMS60','NGSYSUSER','NGPROJMGR','ELNPROD') AND table_name NOT LIKE 'BIN%' ORDER BY grantee, table_name;

PROMPT
PROMPT
PROMPT List of all privileges granted to NGSDMS70PROXYROLE:
SELECT * FROM DBA_ROLE_PRIVS WHERE GRANTED_ROLE = 'NGSDMS70PROXYROLE';

PROMPT
PROMPT
PROMPT ****************************************************************************************************************
PROMPT Verifying the objects in the NuGenesis schemas...
PROMPT ****************************************************************************************************************
PROMPT
PROMPT

PROMPT
PROMPT __________________________________________________________________________________________
PROMPT Checking the primary key constraints owned by the NuGenesis schemas...
PROMPT
DECLARE
v_Count		PLS_INTEGER;
v_ConsName	SYS.DBA_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
v_ConsIndxName	SYS.DBA_CONSTRAINTS.INDEX_NAME%TYPE;
v_ConsTablName	SYS.DBA_CONSTRAINTS.TABLE_NAME%TYPE;
v_ExpectedNo	PLS_INTEGER;
v_SchemaName	VARCHAR2(500);
v_SQLQuery	VARCHAR2(4000 CHAR);

TYPE ObjList	IS TABLE OF VARCHAR2(500);
t_SchemaList	ObjList;
t_ConsNameList	ObjList;
t_ConsIndxList	ObjList;
t_ConsTablList	ObjList;

BEGIN
	t_SchemaList := ObjList('NGSDMS60','NGSYSUSER','ELNPROD');
	FOR indx2 IN 1 .. t_SchemaList.COUNT
	LOOP
		v_SchemaName := t_SchemaList(indx2);
		IF(v_SchemaName = 'NGSDMS60') THEN
			IF	(:v_LMSSchemaVerAsNum >= 9000 AND :v_LMSSchemaVerAsNum < 9300)	THEN
				t_ConsNameList := ObjList('NGRETENTION_POLICY_PK','NGPOLICY_EVENTS_PK','LEGAL_HOLD_ASSIGN_PK','LEGAL_HOLD_DEF_PK','NGUSERPREFS_PK','NGTAGS_PK','NGTABLES_PK','NGPROJVIEWFILTERS_PK','NGPROJVIEWFIELDS_PK','NGPROJVIEWCLU_PK','NGPROJTPL_PK','NGPROJDEFS_PURGE_PK','NGPROJDEFSCLU_PK','NGOBJNUMINFO_PK','NGFIELDVAL_PK','NGFIELDS_PK','NGCONTENTMASTER_PK','NGCONTENTDETAIL_PK','NGPROJMISCDATA_PK','NGPROJSTORE_PK','NGSERVERSTORES_PK');
				t_ConsIndxList := ObjList('NGRETENTION_POLICY_PK','NGPOLICY_EVENTS_PK','LEGAL_HOLD_ASSIGN_PK','LEGAL_HOLD_DEF_PK','NGUSERPREFS_PK','NGTAGS_PK','NGTABLES_PK','NGPROJVIEWFILTERS_PK','NGPROJVIEWFIELDS_PK','NGPROJVIEWCLU_PK','NGPROJTPL_PK','NGPROJDEFS_PURGE_PK','NGPROJDEFSCLU_PK','NGOBJNUMINFO_PK','NGFIELDVAL_PK','NGFIELDS_PK','NGCONTENTMASTER_PK','NGCONTENTDETAIL_PK','NGPROJMISCDATA_PK','NGPROJSTORE_PK','NGSERVERSTORES_PK');
				t_ConsTablList := ObjList('NGRETENTION_POLICY','NGPOLICY_EVENTS','NGLEGAL_HOLD_ASSIGN','NGLEGAL_HOLD_DEF','NGUSERPREFS','NGTAGS','NGTABLES','NGPROJVIEWFILTERS','NGPROJVIEWFIELDS','NGPROJVIEW','NGPROJTPL','NGPROJDEFS_TOPURGE','NGPROJDEFS','NGOBJNUMINFO','NGFIELDVAL','NGFIELDS','NGCONTENTMASTER','NGCONTENTDETAIL','NGPROJMISCDATA','NGPROJSTORES','NGSERVERSTORES');
			ELSIF	(:v_LMSSchemaVerAsNum >= 9300)					THEN
				t_ConsNameList := ObjList('NGRETENTION_POLICY_PK','NGPOLICY_EVENTS_PK','LEGAL_HOLD_ASSIGN_PK','LEGAL_HOLD_DEF_PK','NGUSERPREFS_PK','NGTAGS_PK','NGTABLES_PK','NGPROJVIEWFILTERS_PK','NGPROJVIEWFIELDS_PK','NGPROJVIEWCLU_PK','NGPROJTPL_PK','NGPROJDEFS_PURGE_PK','NGPROJDEFSCLU_PK','NGOBJNUMINFO_PK','NGFIELDVAL_PK','NGFIELDS_PK','NGCONTENTMASTER_PK','NGCONTENTDETAIL_PK','NGPROJMISCDATA_PK','NGPROJSTORE_PK','NGSERVERSTORES_PK','NGUSERPREFERENCES_PK');
				t_ConsIndxList := ObjList('NGRETENTION_POLICY_PK','NGPOLICY_EVENTS_PK','LEGAL_HOLD_ASSIGN_PK','LEGAL_HOLD_DEF_PK','NGUSERPREFS_PK','NGTAGS_PK','NGTABLES_PK','NGPROJVIEWFILTERS_PK','NGPROJVIEWFIELDS_PK','NGPROJVIEWCLU_PK','NGPROJTPL_PK','NGPROJDEFS_PURGE_PK','NGPROJDEFSCLU_PK','NGOBJNUMINFO_PK','NGFIELDVAL_PK','NGFIELDS_PK','NGCONTENTMASTER_PK','NGCONTENTDETAIL_PK','NGPROJMISCDATA_PK','NGPROJSTORE_PK','NGSERVERSTORES_PK','NGUSERPREFERENCES_PK');
				t_ConsTablList := ObjList('NGRETENTION_POLICY','NGPOLICY_EVENTS','NGLEGAL_HOLD_ASSIGN','NGLEGAL_HOLD_DEF','NGUSERPREFS','NGTAGS','NGTABLES','NGPROJVIEWFILTERS','NGPROJVIEWFIELDS','NGPROJVIEW','NGPROJTPL','NGPROJDEFS_TOPURGE','NGPROJDEFS','NGOBJNUMINFO','NGFIELDVAL','NGFIELDS','NGCONTENTMASTER','NGCONTENTDETAIL','NGPROJMISCDATA','NGPROJSTORES','NGSERVERSTORES','NGUSERPREFERENCES');
			END IF;
		ELSIF(v_SchemaName = 'NGSYSUSER') THEN
			IF	(:v_LMSSchemaVerAsNum >= 9000 AND :v_LMSSchemaVerAsNum < 9100)	THEN
				t_ConsNameList := ObjList('NGCATEGORY_PKEY','NGVIEWID_PK','NGAUDITDETAILS_CLU_PK','NGAUDITMASTER_CLU_PK','NGAUDITDETAILSVIEWS_PK','NGAUTHMODESMAP_PK','NGCONFIG_PK','NGLOCKDETAILS_PK','NGNOTIFY_PK','NGSERVERPROJINFO_PK','NGSTRINGLOOKUP_PK','NGUSERS_PK','NGUSERSAUT_PK','NGPWDCHGPROC_PK','NGGROUPSCLU_PK');
				t_ConsIndxList := ObjList('NGCATEGORY_PKEY','NGVIEWID_PK','NGAUDITDETAILS_CLU_PK','NGAUDITMASTER_CLU_PK','NGAUDITDETAILSVIEWS_PK','NGAUTHMODESMAP_PK','NGCONFIG_PK','NGLOCKDETAILS_PK','NGNOTIFY_PK','NGSERVERPROJINFO_PK','NGSTRINGLOOKUP_PK','NGUSERS_PK','NGUSERSAUT_PK','NGPWDCHGPROC_PK','NGGROUPSCLU_PK');
				t_ConsTablList := ObjList('NGAUDITCATEGORIES','NGAUDITMASTERVIEWS','NGAUDITDETAILS','NGAUDITMASTER','NGAUDITDETAILSVIEWS','NGAUTHMODESMAP','NGCONFIG','NGLOCKDETAILS','NGNOTIFY','NGSERVERPROJINFO','NGSTRINGLOOKUP','NGUSERS','NGUSERSAUTHMODE','NGPWDCHGPROC','NGGROUPS');
			ELSIF	(:v_LMSSchemaVerAsNum >= 9100 AND :v_LMSSchemaVerAsNum < 9200)	THEN
				t_ConsNameList := ObjList('NGCATEGORY_PKEY',  'NGVIEWID_PK',       'NGAUDITDETAILS_CLU_PK','NGAUDITMASTER_CLU_PK','NGAUDITDETAILSVIEWS_PK','NGAUTHMODESMAP_PK','NGCONFIG_PK','NGLOCKDETAILS_PK','NGNOTIFY_PK','NGSERVERPROJINFO_PK','NGSTRINGLOOKUP_PK','NGUSERS_PK','NGUSERSAUT_PK','NGPWDCHGPROC_PK','NGGROUPSCLU_PK','NGTOKENGUID_PK','NGCATEGORYGROUP_PK');
				t_ConsIndxList := ObjList('NGCATEGORY_PKEY',  'NGVIEWID_PK',       'NGAUDITDETAILS_CLU_PK','NGAUDITMASTER_CLU_PK','NGAUDITDETAILSVIEWS_PK','NGAUTHMODESMAP_PK','NGCONFIG_PK','NGLOCKDETAILS_PK','NGNOTIFY_PK','NGSERVERPROJINFO_PK','NGSTRINGLOOKUP_PK','NGUSERS_PK','NGUSERSAUT_PK','NGPWDCHGPROC_PK','NGGROUPSCLU_PK','NGTOKENGUID_PK','NGCATEGORYGROUP_PK');
				t_ConsTablList := ObjList('NGAUDITCATEGORIES','NGAUDITMASTERVIEWS','NGAUDITDETAILS','NGAUDITMASTER','NGAUDITDETAILSVIEWS','NGAUTHMODESMAP','NGCONFIG','NGLOCKDETAILS','NGNOTIFY','NGSERVERPROJINFO','NGSTRINGLOOKUP','NGUSERS','NGUSERSAUTHMODE','NGPWDCHGPROC','NGGROUPS','NGUSERREFRESHTOKENS','NGAUDITCATEGORYGROUPS');
			ELSIF	(:v_LMSSchemaVerAsNum >= 9200)					THEN
				t_ConsNameList := ObjList('NGCATEGORY_PKEY',  'NGVIEWID_PK',       'NGAUDITDETAILS_CLU_PK','NGAUDITMASTER_CLU_PK','NGAUDITDETAILSVIEWS_PK','NGAUTHMODESMAP_PK','NGCONFIG_PK','NGLOCKDETAILS_PK','NGNOTIFY_PK','NGSERVERPROJINFO_PK','NGSTRINGLOOKUP_PK','NGUSERS_PK','NGUSERSAUT_PK','NGPWDCHGPROC_PK','NGGROUPSCLU_PK','NGTOKENGUID_PK','NGCATEGORYGROUP_PK');
				t_ConsIndxList := ObjList('NGCATEGORY_PKEY',  'NGVIEWID_PK',       'NGAUDITDETAILS_CLU_PK','NGAUDITMASTER_CLU_PK','NGAUDITDETAILSVIEWS_PK','NGAUTHMODESMAP_PK','NGCONFIG_PK','NGLOCKDETAILS_PK','NGNOTIFY_PK','NGSERVERPROJINFO_PK','NGSTRINGLOOKUP_PK','NGUSERS_PK','NGUSERSAUT_PK','NGPWDCHGPROC_PK','NGGROUPSCLU_PK','NGTOKENGUID_PK','NGCATEGORYGROUP_PK');
				t_ConsTablList := ObjList('NGAUDITCATEGORIES','NGAUDITMASTERVIEWS','NGAUDITDETAILS','NGAUDITMASTER','NGAUDITDETAILSVIEWS','NGAUTHMODESMAP','NGCONFIG','NGLOCKDETAILS','NGNOTIFY','NGSERVERPROJINFO','NGSTRINGLOOKUP','NGUSERS','NGUSERSAUTHMODE','NGPWDCHGPROC','NGGROUPS','NGUSERREFRESHTOKENS','NGAUDITCATEGORYGROUPS');
			END IF;
		ELSIF(v_SchemaName = 'ELNPROD') THEN
			IF (:v_LMSSchemaVerAsNum>= 9000 AND :v_LMSSchemaVerAsNum < 9300)	THEN -- 10 PK constraints in elnprod 9.0 through 9.2.
				 t_ConsNameList := ObjList('MBWHERECONFIG',  'MBLISTS1','PK_MB_TESTREQUEST','MBMAPPING1','PK_MESSAGEATTRIBUTE','PK_MB_TEST','MBSCHEDULE', 'CS_MB_TRANSACTIONRESULT','PK_MB_TESTRESULT','PK_MESSAGE');
				t_ConsIndxList := ObjList('MBWHERECONFIG',  'MBLISTS1','PK_MB_TESTREQUEST','MBMAPPING1','PK_MESSAGEATTRIBUTE','PK_MB_TEST','MBSCHEDULE', 'CS_MB_TRANSACTIONRESULT','PK_MB_TESTRESULT','PK_MESSAGE');
				t_ConsTablList := ObjList('MB_WHERE_CONFIG','MB_LISTS','MB_TESTREQUEST',   'MB_MAPPING','MESSAGEATTRIBUTE',   'MB_TEST',   'MB_SCHEDULE','MB_TRANSACTIONRESULT',   'MB_TESTRESULT',   'MESSAGE');
			ELSIF	(:v_LMSSchemaVerAsNum >= 9300)					THEN -- 6 primary key constraints added to elnprod in 9.3.
				IF	(:v_ConnTableCount = 0)					THEN 
					t_ConsNameList := ObjList('MBWHERECONFIG',  'MBLISTS1','PK_MB_TESTREQUEST','MBMAPPING1','PK_MESSAGEATTRIBUTE','PK_MB_TEST','MBSCHEDULE', 'CS_MB_TRANSACTIONRESULT','PK_MB_TESTRESULT','PK_MESSAGE','SYS_C%',        'XPKINV_INSTRUMENT_EXTENDED','XPKINV_INSTRUMENT_HUB','XPKINV_INSTRUMENT_SYNC','XPKINV_INSTRUMENT_SYSTEM','XPKMRULIST');
					t_ConsIndxList := ObjList('MBWHERECONFIG',  'MBLISTS1','PK_MB_TESTREQUEST','MBMAPPING1','PK_MESSAGEATTRIBUTE','PK_MB_TEST','MBSCHEDULE', 'CS_MB_TRANSACTIONRESULT','PK_MB_TESTRESULT','PK_MESSAGE','XPKMO_LO_COSTS','XPKINV_INSTRUMENT_EXTENDED','XPKINV_INSTRUMENT_HUB','XPKINV_INSTRUMENT_SYNC','XPKINV_INSTRUMENT_SYSTEM','XPKMRULIST');
					t_ConsTablList := ObjList('MB_WHERE_CONFIG','MB_LISTS','MB_TESTREQUEST',   'MB_MAPPING','MESSAGEATTRIBUTE',   'MB_TEST',   'MB_SCHEDULE','MB_TRANSACTIONRESULT',   'MB_TESTRESULT',   'MESSAGE',   'MO_LO_COSTS',   'INV_INSTRUMENT_EXTENDED',   'INV_INSTRUMENT_HUB',   'INV_INSTRUMENT_SYNC',   'INV_INSTRUMENT_SYSTEM',   'MRULIST');
				ELSIF	(:v_ConnTableCount > 0)					THEN -- 10 primary key constraints added to elnprod for the connectors in 9.3.
					t_ConsNameList := ObjList('MBWHERECONFIG',  'MBLISTS1','PK_MB_TESTREQUEST','MBMAPPING1','PK_MESSAGEATTRIBUTE','PK_MB_TEST','MBSCHEDULE', 'CS_MB_TRANSACTIONRESULT','PK_MB_TESTRESULT','PK_MESSAGE','SYS_C%',        'XPKINV_INSTRUMENT_EXTENDED','XPKINV_INSTRUMENT_HUB','XPKINV_INSTRUMENT_SYNC','XPKINV_INSTRUMENT_SYSTEM','XPKMRULIST','XPKCONNECTORS_CONFIGURATION','XPKCONNECTORS_LIMSRESTRICTED','XPKCONNECTORS_LIMSUNRESTRICTED','XPKCONNECTORS_MAPPING','XPKCONNECTORS_SDMS','XPKCONNECTORS_PLUGINS','XPKCONNECTORS_SDMSDELLIST','XPKCONNECTORS_SDMSEXCLLIST','XPKCONNECTORS_SETTINGS','XPKCONNECTORS_TARGET');
					t_ConsIndxList := ObjList('MBWHERECONFIG',  'MBLISTS1','PK_MB_TESTREQUEST','MBMAPPING1','PK_MESSAGEATTRIBUTE','PK_MB_TEST','MBSCHEDULE', 'CS_MB_TRANSACTIONRESULT','PK_MB_TESTRESULT','PK_MESSAGE','XPKMO_LO_COSTS','XPKINV_INSTRUMENT_EXTENDED','XPKINV_INSTRUMENT_HUB','XPKINV_INSTRUMENT_SYNC','XPKINV_INSTRUMENT_SYSTEM','XPKMRULIST','XPKCONNECTORS_CONFIGURATION','XPKCONNECTORS_LIMSRESTRICTED','XPKCONNECTORS_LIMSUNRESTRICTED','XPKCONNECTORS_MAPPING','XPKCONNECTORS_SDMS','XPKCONNECTORS_PLUGINS','XPKCONNECTORS_SDMSDELLIST','XPKCONNECTORS_SDMSEXCLLIST','XPKCONNECTORS_SETTINGS','XPKCONNECTORS_TARGET');
					t_ConsTablList := ObjList('MB_WHERE_CONFIG','MB_LISTS','MB_TESTREQUEST',   'MB_MAPPING','MESSAGEATTRIBUTE',   'MB_TEST',   'MB_SCHEDULE','MB_TRANSACTIONRESULT',   'MB_TESTRESULT',   'MESSAGE',   'MO_LO_COSTS',   'INV_INSTRUMENT_EXTENDED',   'INV_INSTRUMENT_HUB',   'INV_INSTRUMENT_SYNC',   'INV_INSTRUMENT_SYSTEM',   'MRULIST',   'CONNECTORS_CONFIGURATION',   'CONNECTORS_LIMSRESTRICTED',   'CONNECTORS_LIMSUNRESTRICTED'   ,'CONNECTORS_MAPPING',   'CONNECTORS_SDMS',   'CONNECTORS_PLUGINS',   'CONNECTORS_SDMSDELLIST',   'CONNECTORS_SDMSEXCLLIST',   'CONNECTORS_SETTINGS',   'CONNECTORS_TARGET');
				END IF;
			END IF;
		END IF;
		v_ExpectedNo := t_ConsNameList.COUNT;

		SELECT COUNT(constraint_name) INTO v_Count FROM dba_constraints WHERE owner = v_SchemaName AND CONSTRAINT_TYPE = 'P' AND table_name NOT LIKE 'DR%' AND TABLE_NAME NOT LIKE 'BIN$%';
		IF	(v_Count = v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('The '||v_SchemaName||' schema owns the correct number of primary key constraints ('||v_ExpectedNo||' expected, '||v_Count||' found)');
		ELSIF	(v_Count < v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: The '||v_schemaName||' schema owns less than the expected number of primary key constraints ('||v_ExpectedNo||' expected, '||v_Count||' found)!');
		ELSIF	(v_Count > v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('The '||v_schemaName||' schema owns more than the expected number of primary key constraints ('||v_ExpectedNo||' expected, '||v_Count||' found)');
		END IF;

		FOR indx IN 1 .. t_ConsNameList.COUNT
		LOOP
			v_ConsName := t_ConsNameList(indx);
			SELECT COUNT(*) INTO v_Count FROM dba_constraints WHERE owner = v_SchemaName AND constraint_name LIKE v_ConsName;
			IF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: Primary key constraint: '||v_SchemaName||'.'||v_ConsName||' is not present!');
			ELSE
				DBMS_OUTPUT.PUT_LINE('Primary key constraint: '||v_SchemaName||'.'||v_ConsName||' is present');
				IF v_ConsName LIKE '%\%%' ESCAPE '\'		THEN	v_SQLQuery := 'SELECT index_name, table_name FROM dba_constraints WHERE owner = '''|| v_SchemaName ||''' AND constraint_name LIKE ''' || v_ConsName||''' AND index_name = '''||t_ConsIndxList(indx)|| '''';
				ELSE							v_SQLQuery := 'SELECT index_name, table_name FROM dba_constraints WHERE owner = '''|| v_SchemaName ||''' AND constraint_name = ''' || v_ConsName||'''';
				END IF;
				EXECUTE IMMEDIATE v_SQLQuery INTO v_ConsIndxName, v_ConsTablName;
				
				IF (v_ConsTablName = t_ConsTablList(indx))	THEN	DBMS_OUTPUT.PUT_LINE('-- on table: '||v_ConsTablName||' is correct (expected '||t_ConsTablList(indx)||')');
				ELSE							DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: on table: '||v_ConsTablName||' is NOT correct (expected '||t_ConsTablList(indx)||')!');
				END IF;
	
				IF (v_ConsIndxName = t_ConsIndxList(indx))	THEN	DBMS_OUTPUT.PUT_LINE('-- with index: '||v_ConsIndxName||' is correct (expected '||t_ConsIndxList(indx)||')');
				ELSE							DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: with index: '||v_ConsIndxName||' is NOT correct (expected '||t_ConsIndxList(indx)||')!');
				END IF;
				DBMS_OUTPUT.PUT_LINE('.');
			END IF;
		END LOOP;
		DBMS_OUTPUT.PUT_LINE('.');
	END LOOP;
END;
/

PROMPT
PROMPT __________________________________________________________________________________________
PROMPT Checking the non-primary key constraints in the NuGenesis schemas...
PROMPT
DECLARE
v_constab		SYS.DBA_CONSTRAINTS.TABLE_NAME%TYPE;
v_constat		SYS.DBA_CONSTRAINTS.STATUS%TYPE;
v_Count			PLS_INTEGER;
v_ConsName		SYS.DBA_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
v_ExpectedNo		PLS_INTEGER;
v_SchemaName		VARCHAR2(500);

TYPE ObjList		IS TABLE OF VARCHAR2(500);
TYPE NumList		IS TABLE OF NUMBER;

t_SchemaList		ObjList;
t_ExpectedNoList	NumList;

CURSOR C_CONSTAT	IS SELECT constraint_name, table_name, status FROM dba_constraints WHERE owner = v_SchemaName AND TABLE_NAME NOT LIKE 'BIN%' AND TABLE_NAME NOT LIKE '%BAK' AND STATUS != 'ENABLED';

BEGIN
	t_SchemaList     := ObjList('NGSDMS60','NGSYSUSER','ELNPROD');
	t_ExpectedNoList := NumList(30, 76, 1900);
	FOR indx IN 1 .. t_SchemaList.COUNT
	LOOP
		v_SchemaName := t_SchemaList(indx);
		v_ExpectedNo := t_ExpectedNolist(indx);

		SELECT COUNT(constraint_name) INTO v_Count from dba_constraints where owner = v_SchemaName AND TABLE_NAME NOT LIKE 'BIN%' AND TABLE_NAME NOT LIKE 'DR%' AND TABLE_NAME NOT LIKE '%BAK';
		IF (v_Count >= v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('The '||v_SchemaName||' schema owns the expected number of constraints (at least '||v_ExpectedNo||' expected, '||v_Count||' found)');
		ELSE					DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: the '||v_SchemaName||' schema owns less than the expected number of constraints (at least '||v_ExpectedNo||' expected, '||v_Count||' found)!');
		END IF;

		SELECT COUNT(constraint_name) INTO v_Count FROM dba_constraints WHERE owner = v_SchemaName AND TABLE_NAME NOT LIKE 'BIN%' AND TABLE_NAME NOT LIKE 'DR%'	AND TABLE_NAME NOT LIKE '%BAK' AND STATUS != 'ENABLED';
		IF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('All constraints owned by '||v_SchemaName||' are enabled.');
		ELSE
			DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: some constraints owned by '||v_SchemaName||' are not enabled (0 expected, '||v_Count||' found)!');
			OPEN C_CONSTAT;
			LOOP
				FETCH C_CONSTAT INTO v_consname,v_constab,v_constat;
				EXIT WHEN C_CONSTAT%NOTFOUND;
	
				DBMS_OUTPUT.PUT_LINE('-- Constraint '||v_consname||' on table '||v_constab||' has a status of '||v_constat||'!');
			END LOOP;
			CLOSE C_CONSTAT;
		END IF;
		DBMS_OUTPUT.PUT_LINE('.');
	END LOOP;
END;
/

col constraint_name format a30
PROMPT
PROMPT
PROMPT List of all NuGenesis constraints:
SELECT owner, TABLE_NAME, CONSTRAINT_NAME, CONSTRAINT_TYPE, STATUS, INDEX_NAME FROM dba_constraints WHERE owner IN ('NGSDMS60','NGSYSUSER','ELNPROD') AND table_name NOT LIKE 'DR%' AND table_name NOT LIKE 'BIN%' AND TABLE_NAME NOT LIKE '%BAK' ORDER BY owner, table_name;

PROMPT
PROMPT _________________________________________________________________________________________________________________________
PROMPT Checking for nologging lobsegments in the NuGenesis schemas . . .
PROMPT
DECLARE 
v_Count		PLS_INTEGER;
v_LobSegOwner	dba_lobs.owner%TYPE;
v_LobSegTablNAme	dba_lobs.table_name%TYPE;
v_LobSegColName		dba_lobs.column_name%TYPE;
v_LobSegName		dba_lobs.segment_name%TYPE;

CURSOR C_NoLoggingLobSegs IS SELECT owner, table_name, column_name, segment_name FROM DBA_LOBS WHERE OWNER IN('ELNPROD','NGSDMS60','NGSYSUSER') AND LOGGING = 'NO';

BEGIN
	SELECT COUNT(SEGMENT_NAME) INTO v_Count FROM DBA_LOBS WHERE OWNER IN('ELNPROD','NGSDMS60','NGSYSUSER') AND LOGGING = 'NO';
	IF v_Count > 0 THEN
		DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: lobsegments owned by the NuGenesis schemas in no logging mode have been identified!');
		OPEN C_NoLoggingLobSegs;
		LOOP
			FETCH C_NoLoggingLobSegs INTO v_LobSegOwner, v_LobSegTablName, v_LobSegColName, v_LobSegName;
			EXIT WHEN C_NoLoggingLobSegs%NOTFOUND;

			DBMS_OUTPUT.PUT_LINE('-- owner: '||v_LobSegOwner||'	table: '||v_LobSegTablName||'	column: '||v_LobSegColName||'	segment: '||v_LobSegName);
		END LOOP;
		CLOSE C_NoLoggingLobSegs;
	ELSE	DBMS_OUTPUT.PUT_LINE('All lobsegments owned by elnprod are in logging mode, no action is necessary.');
	END IF;
END;
/

COLUMN OBJECT_NAME FORMAT A25 HEADING "LOBSEGMENT"
COLUMN SECUREFILE FORMAT A10 HEADING "SECUREFILE"
COLUMN COMPRESSION FORMAT A8 HEADING  "COMPRESS"
COLUMN TABLESPACE_NAME FORMAT A15 HEADING  "TABLESPACE"
COLUMN table_name format a20
COLUMN RETENTION_TYPE FORMAT A15 HEADING  "RETENTION TYPE"
COLUMN DEDUPLICATION FORMAT A6 HEADING  "DEDUPE"
COLUMN IN_ROW FORMAT A6 HEADING  "IN ROW"
COLUMN INDEX_NAME FORMAT A25 HEADING "LOBINDEX"
COLUMN LOGGING FORMAT A10 HEADING "LOGGING"
COLUMN lob_name format a30
COLUMN partition_name format a20

PROMPT
PROMPT List of NuGenesis LOB segments:
SELECT owner, SEGMENT_NAME, TABLE_NAME "TABLE", TABLESPACE_NAME, IN_ROW, SECUREFILE, LOGGING, COMPRESSION, DEDUPLICATION, RETENTION, RETENTION_TYPE, RETENTION_VALUE FROM  DBA_LOBS WHERE  OWNER IN ('NGSDMS60','NGSYSUSER','ELNPROD');

PROMPT
PROMPT _________________________________________________________________________________________________________________________
PROMPT Checking for tables and LOBs in the NuGenesis schemas which use advanced compression . . .
PROMPT There are several compressed tables and lobs in the standard NuGenesis installation, but if the customer has a Linux DB
PROMPT and does not have a license for Advance Compression, then these objects should be changed to not use compression.
PROMPT
PROMPT NG tables which use advanced compression:
SELECT owner, table_name, compression, compress_for FROM dba_tables WHERE owner IN ('ELNPROD','NGSDMS60','NGSYSUSER','SPSV') AND compression = 'ENABLED' AND compress_for = 'ADVANCED' ORDER BY 1,2;

PROMPT
PROMPT NG LOBS which use compression (all types of LOB compression require a license for Advanced Compression):
SELECT owner, table_name, segment_name, compression FROM dba_lobs WHERE owner IN ('ELNPROD','NGSYSUSER','NGSDMS60','SPSV') AND compression != 'NO' ORDER BY 1;

PROMPT
PROMPT NG table partitions which use advanced compression:
SELECT table_owner, table_name, partition_name, compress_for FROM dba_tab_partitions WHERE table_owner IN ('ELNPROD','NGSYSUSER','NGSDMS60','SPSV') AND compression= 'ENABLED' AND compress_for = 'ADVANCED' ORDER BY 1,2;

PROMPT
PROMPT NG LOB partitions which use compression:
SELECT table_owner, table_name, lob_name, partition_name, compression FROM dba_lob_partitions WHERE table_owner IN ('ELNPROD','NGSYSUSER','NGSDMS60','SPSV') AND compression != 'NO' ORDER BY 1,2;

PROMPT
PROMPT ________________________________________________________________________________________________________
PROMPT Determining whether the NuGenesis accounts own the correct number of procedures, functions, and packages
PROMPT
DECLARE
v_Count			PLS_INTEGER := 0;
v_ExpectedNo		PLS_INTEGER := 2;
v_ObjName		dba_procedures.object_name%TYPE;
v_ObjType		dba_procedures.object_type%TYPE;
v_ObjStatus		dba_objects.status%TYPE;
v_SchemaName		VARCHAR2(100);

TYPE ObjList		IS TABLE OF VARCHAR2(500);
t_SchemaList		ObjList;
t_FunctionList		ObjList;
t_ProcedureList		ObjList;
t_PackageList		ObjList;
BEGIN
	t_SchemaList := ObjList('ELNPROD','NGSDMS60','NGSYSUSER');
	FOR indx2 IN 1 .. t_SchemaList.COUNT
	LOOP
		v_SchemaName := t_SchemaList(indx2);
		IF	(v_SchemaName = 'NGSDMS60')	THEN
			t_FunctionList  := ObjList(); -- No functions expected of ngsdms60.
			IF (:v_LMSSchemaVerAsNum < 9300)	THEN	t_ProcedureList := ObjList('CREATETEMPTBL');
			ELSE						t_ProcedureList := ObjList('CREATETEMPTBL','GETINDEXEDCOLUMNS'); -- New procedure for ngsdms60 added in v9.3
			END IF;
			t_PackageList   := ObjList('NGSDMS_CLOB_DEFINITIONS','NGSDMS_VERSION_DEFINITIONS');
		ELSIF	(v_SchemaName = 'NGSYSUSER')	THEN
			t_FunctionList  := ObjList(); -- No functions expected of ngsysuser.
			t_ProcedureList := ObjList('CHANGE_PSWD','NG_EMAIL_ADMIN','VP_DATA_LCN_CONFIG_LOAD','VP_DATA_LCN_CONFIG_REFRESH','VP_DATA_LCN_CONFIG_SAVE','VP_DATA_LCN_CONFIG_TEST','VP_ELN_CREATE_LGE_PROC','VP_ELN_DELETE_LGE_PROC','VP_ELN_GET_BUILD_INFO_PROC','VP_ELN_UPDATE_LGE_PROC','VP_ELN_UPDATE_USER_OTHER_P_P');
			t_PackageList   := ObjList('NGSDMS60_DEFINITIONS','NGSDMS60USERMGMT','NGSENDMAIL');
		ELSIF	(v_SchemaName = 'ELNPROD')	THEN
			IF	(:v_LMSSchemaVerAsNum >= 9000 AND :v_LMSSchemaVerAsNum < 9100)	THEN
				t_FunctionList := ObjList('CONVERTBLOBTOSTRING');
				IF	(:v_ConnTableCount > 0)	THEN	t_ProcedureList := ObjList('ELN_DELETE_LABGROUPEMPLOYEE','ELN_GET_BUILD_INFO','ELN_UPDATE_LABGROUPEMPLOYEE','REPORTCONFIGLIBRARY_CONCAT','SMMETHOD_CONCAT','TEST_CONCAT','SAMPLETEMPLATE_CONCAT','USERMESSAGE_CONCAT','PHYSICALSAMPLE_CONCAT','USERS_CONCAT','ELN_UPDATE_USER_OTHER_PROPS','MEASUREORDER_CONCAT','REPORTCONFIGURATION_CONCAT','SUBMISSIONTEMPL_CONCAT','UICONFIGURATION_CONCAT','EXTERNALPLUGIN_CONCAT','TESTREQUEST_CONCAT','TESTRESULT_CONCAT','ELN_CREATE_LABGROUPEMPLOYEE','LOCATION_CONCAT','SUBMISSION_CONCAT','TESTDEFINITION_CONCAT','SAMPLETEMPLATEUPDATEINDEX','ELN_UPDATE_USER','SPECIFICATION_CONCAT','PHYSICALSAMPLEUPDATEINDEX','ELN_SLIM_UPLOADUSER','CREATE_POPULATE_PENDING','ELN_CREATE_USER','ELN_DELETE_USER','PRODUCT_CONCAT','SUBMISSIONTEMPLUPDATEINDEX','USERSUPDATEINDEX','USERMESSAGEUPDATEINDEX','UICONFIGURATIONUPDATEINDEX','MEASUREORDERUPDATEINDEX','PRODUCTUPDATEINDEX','LOCATIONUPDATEINDEX','TESTDEFINITIONUPDATEINDEX','SMMETHODUPDATEINDEX','SPECIFICATIONUPDATEINDEX','TESTREQUESTUPDATEINDEX','TESTUPDATEINDEX','TESTRESULTUPDATEINDEX','SUBMISSIONUPDATEINDEX','REPORTCONFIGURATIONUPDATEINDEX','REPORTCONFIGLIBRARYUPDATEINDEX','EXTERNALPLUGINUPDATEINDEX','P_CONNECTORS_UPDATESETTINGS');
				ELSE					t_ProcedureList := ObjList('ELN_DELETE_LABGROUPEMPLOYEE','ELN_GET_BUILD_INFO','ELN_UPDATE_LABGROUPEMPLOYEE','REPORTCONFIGLIBRARY_CONCAT','SMMETHOD_CONCAT','TEST_CONCAT','SAMPLETEMPLATE_CONCAT','USERMESSAGE_CONCAT','PHYSICALSAMPLE_CONCAT','USERS_CONCAT','ELN_UPDATE_USER_OTHER_PROPS','MEASUREORDER_CONCAT','REPORTCONFIGURATION_CONCAT','SUBMISSIONTEMPL_CONCAT','UICONFIGURATION_CONCAT','EXTERNALPLUGIN_CONCAT','TESTREQUEST_CONCAT','TESTRESULT_CONCAT','ELN_CREATE_LABGROUPEMPLOYEE','LOCATION_CONCAT','SUBMISSION_CONCAT','TESTDEFINITION_CONCAT','SAMPLETEMPLATEUPDATEINDEX','ELN_UPDATE_USER','SPECIFICATION_CONCAT','PHYSICALSAMPLEUPDATEINDEX','ELN_SLIM_UPLOADUSER','CREATE_POPULATE_PENDING','ELN_CREATE_USER','ELN_DELETE_USER','PRODUCT_CONCAT','SUBMISSIONTEMPLUPDATEINDEX','USERSUPDATEINDEX','USERMESSAGEUPDATEINDEX','UICONFIGURATIONUPDATEINDEX','MEASUREORDERUPDATEINDEX','PRODUCTUPDATEINDEX','LOCATIONUPDATEINDEX','TESTDEFINITIONUPDATEINDEX','SMMETHODUPDATEINDEX','SPECIFICATIONUPDATEINDEX','TESTREQUESTUPDATEINDEX','TESTUPDATEINDEX','TESTRESULTUPDATEINDEX','SUBMISSIONUPDATEINDEX','REPORTCONFIGURATIONUPDATEINDEX','REPORTCONFIGLIBRARYUPDATEINDEX','EXTERNALPLUGINUPDATEINDEX');
				END IF;
			ELSIF	(:v_LMSSchemaVerAsNum >= 9100 AND :v_LMSSchemaVerAsNum < 9200)	THEN
				t_FunctionList := ObjList('CONVERTBLOBTOSTRING','FN_CONVERT_BLOB2CLOB');
				IF	(:v_ConnTableCount > 0)	THEN	t_ProcedureList := ObjList('ELN_DELETE_LABGROUPEMPLOYEE','ELN_GET_BUILD_INFO','ELN_UPDATE_LABGROUPEMPLOYEE','REPORTCONFIGLIBRARY_CONCAT','SMMETHOD_CONCAT','TEST_CONCAT','SAMPLETEMPLATE_CONCAT','USERMESSAGE_CONCAT','PHYSICALSAMPLE_CONCAT','USERS_CONCAT','ELN_UPDATE_USER_OTHER_PROPS','MEASUREORDER_CONCAT','REPORTCONFIGURATION_CONCAT','SUBMISSIONTEMPL_CONCAT','UICONFIGURATION_CONCAT','EXTERNALPLUGIN_CONCAT','TESTREQUEST_CONCAT','TESTRESULT_CONCAT','ELN_CREATE_LABGROUPEMPLOYEE','LOCATION_CONCAT','SUBMISSION_CONCAT','TESTDEFINITION_CONCAT','SAMPLETEMPLATEUPDATEINDEX','ELN_UPDATE_USER','SPECIFICATION_CONCAT','PHYSICALSAMPLEUPDATEINDEX','ELN_SLIM_UPLOADUSER','CREATE_POPULATE_PENDING','ELN_CREATE_USER','ELN_DELETE_USER','PRODUCT_CONCAT','SUBMISSIONTEMPLUPDATEINDEX','USERSUPDATEINDEX','USERMESSAGEUPDATEINDEX','UICONFIGURATIONUPDATEINDEX','MEASUREORDERUPDATEINDEX','PRODUCTUPDATEINDEX','LOCATIONUPDATEINDEX','TESTDEFINITIONUPDATEINDEX','SMMETHODUPDATEINDEX','SPECIFICATIONUPDATEINDEX','TESTREQUESTUPDATEINDEX','TESTUPDATEINDEX','TESTRESULTUPDATEINDEX','SUBMISSIONUPDATEINDEX','REPORTCONFIGURATIONUPDATEINDEX','REPORTCONFIGLIBRARYUPDATEINDEX','EXTERNALPLUGINUPDATEINDEX','P_CONNECTORS_UPDATESETTINGS','INV_CHEMICAL_CONCAT','INV_CHEMICALUPDATEINDEX','INV_INSTRUMENT_CONCAT','INV_INSTRUMENTUPDATEINDEX');
				ELSE					t_ProcedureList := ObjList('ELN_DELETE_LABGROUPEMPLOYEE','ELN_GET_BUILD_INFO','ELN_UPDATE_LABGROUPEMPLOYEE','REPORTCONFIGLIBRARY_CONCAT','SMMETHOD_CONCAT','TEST_CONCAT','SAMPLETEMPLATE_CONCAT','USERMESSAGE_CONCAT','PHYSICALSAMPLE_CONCAT','USERS_CONCAT','ELN_UPDATE_USER_OTHER_PROPS','MEASUREORDER_CONCAT','REPORTCONFIGURATION_CONCAT','SUBMISSIONTEMPL_CONCAT','UICONFIGURATION_CONCAT','EXTERNALPLUGIN_CONCAT','TESTREQUEST_CONCAT','TESTRESULT_CONCAT','ELN_CREATE_LABGROUPEMPLOYEE','LOCATION_CONCAT','SUBMISSION_CONCAT','TESTDEFINITION_CONCAT','SAMPLETEMPLATEUPDATEINDEX','ELN_UPDATE_USER','SPECIFICATION_CONCAT','PHYSICALSAMPLEUPDATEINDEX','ELN_SLIM_UPLOADUSER','CREATE_POPULATE_PENDING','ELN_CREATE_USER','ELN_DELETE_USER','PRODUCT_CONCAT','SUBMISSIONTEMPLUPDATEINDEX','USERSUPDATEINDEX','USERMESSAGEUPDATEINDEX','UICONFIGURATIONUPDATEINDEX','MEASUREORDERUPDATEINDEX','PRODUCTUPDATEINDEX','LOCATIONUPDATEINDEX','TESTDEFINITIONUPDATEINDEX','SMMETHODUPDATEINDEX','SPECIFICATIONUPDATEINDEX','TESTREQUESTUPDATEINDEX','TESTUPDATEINDEX','TESTRESULTUPDATEINDEX','SUBMISSIONUPDATEINDEX','REPORTCONFIGURATIONUPDATEINDEX','REPORTCONFIGLIBRARYUPDATEINDEX','EXTERNALPLUGINUPDATEINDEX','INV_CHEMICAL_CONCAT','INV_CHEMICALUPDATEINDEX','INV_INSTRUMENT_CONCAT','INV_INSTRUMENTUPDATEINDEX');
				END IF;
			ELSIF	(:v_LMSSchemaVerAsNum >= 9200 AND :v_LMSSchemaVerAsNum < 9300)	THEN
				t_FunctionList := ObjList('CONVERTBLOBTOSTRING','FN_CONVERT_BLOB2CLOB');
				IF	(:v_ConnTableCount > 0)	THEN	t_ProcedureList := ObjList('ELN_DELETE_LABGROUPEMPLOYEE','ELN_GET_BUILD_INFO','ELN_UPDATE_LABGROUPEMPLOYEE','REPORTCONFIGLIBRARY_CONCAT','SMMETHOD_CONCAT','TEST_CONCAT','SAMPLETEMPLATE_CONCAT','USERMESSAGE_CONCAT','PHYSICALSAMPLE_CONCAT','USERS_CONCAT','ELN_UPDATE_USER_OTHER_PROPS','MEASUREORDER_CONCAT','REPORTCONFIGURATION_CONCAT','SUBMISSIONTEMPL_CONCAT','UICONFIGURATION_CONCAT','EXTERNALPLUGIN_CONCAT','TESTREQUEST_CONCAT','TESTRESULT_CONCAT','ELN_CREATE_LABGROUPEMPLOYEE','LOCATION_CONCAT','SUBMISSION_CONCAT','TESTDEFINITION_CONCAT','SAMPLETEMPLATEUPDATEINDEX','ELN_UPDATE_USER','SPECIFICATION_CONCAT','PHYSICALSAMPLEUPDATEINDEX','ELN_SLIM_UPLOADUSER','CREATE_POPULATE_PENDING','ELN_CREATE_USER','ELN_DELETE_USER','PRODUCT_CONCAT','SUBMISSIONTEMPLUPDATEINDEX','USERSUPDATEINDEX','USERMESSAGEUPDATEINDEX','UICONFIGURATIONUPDATEINDEX','MEASUREORDERUPDATEINDEX','PRODUCTUPDATEINDEX','LOCATIONUPDATEINDEX','TESTDEFINITIONUPDATEINDEX','SMMETHODUPDATEINDEX','SPECIFICATIONUPDATEINDEX','TESTREQUESTUPDATEINDEX','TESTUPDATEINDEX','TESTRESULTUPDATEINDEX','SUBMISSIONUPDATEINDEX','REPORTCONFIGURATIONUPDATEINDEX','REPORTCONFIGLIBRARYUPDATEINDEX','EXTERNALPLUGINUPDATEINDEX','P_CONNECTORS_UPDATESETTINGS','INV_CHEMICAL_CONCAT','INV_CHEMICALUPDATEINDEX','INV_INSTRUMENT_CONCAT','INV_INSTRUMENTUPDATEINDEX');
				ELSE					t_ProcedureList := ObjList('ELN_DELETE_LABGROUPEMPLOYEE','ELN_GET_BUILD_INFO','ELN_UPDATE_LABGROUPEMPLOYEE','REPORTCONFIGLIBRARY_CONCAT','SMMETHOD_CONCAT','TEST_CONCAT','SAMPLETEMPLATE_CONCAT','USERMESSAGE_CONCAT','PHYSICALSAMPLE_CONCAT','USERS_CONCAT','ELN_UPDATE_USER_OTHER_PROPS','MEASUREORDER_CONCAT','REPORTCONFIGURATION_CONCAT','SUBMISSIONTEMPL_CONCAT','UICONFIGURATION_CONCAT','EXTERNALPLUGIN_CONCAT','TESTREQUEST_CONCAT','TESTRESULT_CONCAT','ELN_CREATE_LABGROUPEMPLOYEE','LOCATION_CONCAT','SUBMISSION_CONCAT','TESTDEFINITION_CONCAT','SAMPLETEMPLATEUPDATEINDEX','ELN_UPDATE_USER','SPECIFICATION_CONCAT','PHYSICALSAMPLEUPDATEINDEX','ELN_SLIM_UPLOADUSER','CREATE_POPULATE_PENDING','ELN_CREATE_USER','ELN_DELETE_USER','PRODUCT_CONCAT','SUBMISSIONTEMPLUPDATEINDEX','USERSUPDATEINDEX','USERMESSAGEUPDATEINDEX','UICONFIGURATIONUPDATEINDEX','MEASUREORDERUPDATEINDEX','PRODUCTUPDATEINDEX','LOCATIONUPDATEINDEX','TESTDEFINITIONUPDATEINDEX','SMMETHODUPDATEINDEX','SPECIFICATIONUPDATEINDEX','TESTREQUESTUPDATEINDEX','TESTUPDATEINDEX','TESTRESULTUPDATEINDEX','SUBMISSIONUPDATEINDEX','REPORTCONFIGURATIONUPDATEINDEX','REPORTCONFIGLIBRARYUPDATEINDEX','EXTERNALPLUGINUPDATEINDEX','INV_CHEMICAL_CONCAT','INV_CHEMICALUPDATEINDEX','INV_INSTRUMENT_CONCAT','INV_INSTRUMENTUPDATEINDEX');
				END IF;
			ELSIF	(:v_LMSSchemaVerAsNum >= 9300 AND :v_LMSSchemaVerAsNum < 9400)	THEN
				t_FunctionList := ObjList('CONVERTBLOBTOSTRING','FN_CONVERT_BLOB2CLOB','FN_CONVERT_CLOB2BLOB');
				IF	(:v_ConnTableCount > 0)	THEN	t_ProcedureList := ObjList('ELN_DELETE_LABGROUPEMPLOYEE','ELN_GET_BUILD_INFO','ELN_UPDATE_LABGROUPEMPLOYEE','REPORTCONFIGLIBRARY_CONCAT','SMMETHOD_CONCAT','TEST_CONCAT','SAMPLETEMPLATE_CONCAT','USERMESSAGE_CONCAT','PHYSICALSAMPLE_CONCAT','USERS_CONCAT','ELN_UPDATE_USER_OTHER_PROPS','MEASUREORDER_CONCAT','REPORTCONFIGURATION_CONCAT','SUBMISSIONTEMPL_CONCAT','UICONFIGURATION_CONCAT','EXTERNALPLUGIN_CONCAT','TESTREQUEST_CONCAT','TESTRESULT_CONCAT','ELN_CREATE_LABGROUPEMPLOYEE','LOCATION_CONCAT','SUBMISSION_CONCAT','TESTDEFINITION_CONCAT','SAMPLETEMPLATEUPDATEINDEX','ELN_UPDATE_USER','SPECIFICATION_CONCAT','PHYSICALSAMPLEUPDATEINDEX','ELN_SLIM_UPLOADUSER','CREATE_POPULATE_PENDING','ELN_CREATE_USER','ELN_DELETE_USER','PRODUCT_CONCAT','SUBMISSIONTEMPLUPDATEINDEX','USERSUPDATEINDEX','USERMESSAGEUPDATEINDEX','UICONFIGURATIONUPDATEINDEX','MEASUREORDERUPDATEINDEX','PRODUCTUPDATEINDEX','LOCATIONUPDATEINDEX','TESTDEFINITIONUPDATEINDEX','SMMETHODUPDATEINDEX','SPECIFICATIONUPDATEINDEX','TESTREQUESTUPDATEINDEX','TESTUPDATEINDEX','TESTRESULTUPDATEINDEX','SUBMISSIONUPDATEINDEX','REPORTCONFIGURATIONUPDATEINDEX','REPORTCONFIGLIBRARYUPDATEINDEX','EXTERNALPLUGINUPDATEINDEX','P_CONNECTORS_UPDATESETTINGS','INV_CHEMICAL_CONCAT','INV_CHEMICALUPDATEINDEX','INV_INSTRUMENT_CONCAT','INV_INSTRUMENTUPDATEINDEX');
				ELSE					t_ProcedureList := ObjList('ELN_DELETE_LABGROUPEMPLOYEE','ELN_GET_BUILD_INFO','ELN_UPDATE_LABGROUPEMPLOYEE','REPORTCONFIGLIBRARY_CONCAT','SMMETHOD_CONCAT','TEST_CONCAT','SAMPLETEMPLATE_CONCAT','USERMESSAGE_CONCAT','PHYSICALSAMPLE_CONCAT','USERS_CONCAT','ELN_UPDATE_USER_OTHER_PROPS','MEASUREORDER_CONCAT','REPORTCONFIGURATION_CONCAT','SUBMISSIONTEMPL_CONCAT','UICONFIGURATION_CONCAT','EXTERNALPLUGIN_CONCAT','TESTREQUEST_CONCAT','TESTRESULT_CONCAT','ELN_CREATE_LABGROUPEMPLOYEE','LOCATION_CONCAT','SUBMISSION_CONCAT','TESTDEFINITION_CONCAT','SAMPLETEMPLATEUPDATEINDEX','ELN_UPDATE_USER','SPECIFICATION_CONCAT','PHYSICALSAMPLEUPDATEINDEX','ELN_SLIM_UPLOADUSER','CREATE_POPULATE_PENDING','ELN_CREATE_USER','ELN_DELETE_USER','PRODUCT_CONCAT','SUBMISSIONTEMPLUPDATEINDEX','USERSUPDATEINDEX','USERMESSAGEUPDATEINDEX','UICONFIGURATIONUPDATEINDEX','MEASUREORDERUPDATEINDEX','PRODUCTUPDATEINDEX','LOCATIONUPDATEINDEX','TESTDEFINITIONUPDATEINDEX','SMMETHODUPDATEINDEX','SPECIFICATIONUPDATEINDEX','TESTREQUESTUPDATEINDEX','TESTUPDATEINDEX','TESTRESULTUPDATEINDEX','SUBMISSIONUPDATEINDEX','REPORTCONFIGURATIONUPDATEINDEX','REPORTCONFIGLIBRARYUPDATEINDEX','EXTERNALPLUGINUPDATEINDEX','INV_CHEMICAL_CONCAT','INV_CHEMICALUPDATEINDEX','INV_INSTRUMENT_CONCAT','INV_INSTRUMENTUPDATEINDEX');
				END IF;
			ELSE		
				t_FunctionList := ObjList(); -- Null out the table variables if the schema version does not match any of the above versions.
				t_ProcedureList := ObjList();
			END IF;
			t_PackageList   := ObjList(); -- No packages expected of elnprod.
		END IF;

		v_ExpectedNo   := t_FunctionList.COUNT;
		SELECT COUNT(*) INTO v_Count FROM dba_procedures WHERE owner = v_SchemaName AND object_type IN ('FUNCTION');
		IF (v_Count = v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE(v_SchemaName||' owns the expected number of functions ('||v_ExpectedNo||' expected, '||v_Count||' found)');
		ELSIF (v_Count < v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: '||v_SchemaName||' owns less than the expected number of functions ('||v_ExpectedNo||' expected, '||v_Count||' found)!');
		ELSIF (v_Count > v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('WARNING: '||v_SchemaName||' owns more than the expected number of functions ('||v_ExpectedNo||' expected, '||v_Count||' found)');
		END IF;

		FOR indx IN 1 .. t_FunctionList.COUNT
		LOOP
			v_ObjName := t_FunctionList(indx);
			SELECT COUNT(*) INTO v_Count FROM dba_procedures WHERE owner = v_SchemaName AND object_name = v_ObjName AND object_type = 'FUNCTION';
			IF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: function '||v_SchemaName||'.'||v_ObjName||' is not present!');
			ELSIF (v_Count = 1)	THEN
				DBMS_OUTPUT.PUT_LINE('-- function '||v_SchemaName||'.'||v_ObjName||' is present');
				SELECT status INTO v_ObjStatus FROM dba_objects WHERE owner = v_SchemaName AND object_name = v_ObjName;
				IF (v_ObjStatus != 'VALID')	THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: the function is not valid!');
				ELSE					DBMS_OUTPUT.PUT_LINE('-- the function is valid');
				END IF;
			END IF;
			DBMS_OUTPUT.PUT_LINE('.');
		END LOOP;

		v_ExpectedNo    := t_ProcedureList.COUNT;
		DBMS_OUTPUT.PUT_LINE('.');
		SELECT COUNT(*) INTO v_Count FROM dba_procedures WHERE owner = v_SchemaName AND object_type IN ('PROCEDURE');
		IF (v_Count = v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE(v_SchemaName||' owns the expected number of procedures ('||v_ExpectedNo||' expected, '||v_Count||' found)');
		ELSIF (v_Count < v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: '||v_SchemaName||' owns less than the expected number of procedures ('||v_ExpectedNo||' expected, '||v_Count||' found)!');
		ELSIF (v_Count > v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('WARNING: '||v_SchemaName||' owns more than the expected number of procedures ('||v_ExpectedNo||' expected, '||v_Count||' found)');
		END IF;

		FOR indx IN 1 .. t_ProcedureList.COUNT
		LOOP
			v_ObjName := t_ProcedureList(indx);
			SELECT COUNT(*) INTO v_Count FROM dba_procedures WHERE owner = v_SchemaName AND object_name = v_ObjName AND object_type = 'PROCEDURE';
			IF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: procedure '||v_SchemaName||'.'||v_ObjName||' is not present!');
			ELSIF (v_Count = 1)	THEN
				DBMS_OUTPUT.PUT_LINE('-- procedure '||v_SchemaName||'.'||v_ObjName||' is present');
				SELECT status INTO v_ObjStatus FROM dba_objects WHERE owner = v_SchemaName AND object_name = v_ObjName;
				IF (v_ObjStatus != 'VALID')	THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: the procedure is not valid!');
				ELSE					DBMS_OUTPUT.PUT_LINE('-- the procedure is valid');
				END IF;
			END IF;
			DBMS_OUTPUT.PUT_LINE('.');
		END LOOP;

		v_ExpectedNo  := t_PackageList.COUNT;
		DBMS_OUTPUT.PUT_LINE('.');
		SELECT COUNT(DISTINCT object_name) INTO v_Count FROM dba_procedures WHERE owner = v_SchemaName AND object_type IN ('PACKAGE');
		IF (v_Count = v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE(v_SchemaName||' owns the expected number of packages ('||v_ExpectedNo||' expected, '||v_Count||' found)');
		ELSIF (v_Count < v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: '||v_SchemaName||' owns less than the expected number of packages ('||v_ExpectedNo||' expected, '||v_Count||' found)');
		ELSIF (v_Count > v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('WARNING: '||v_SchemaName||' owns more than the expected number of packages ('||v_ExpectedNo||' expected, '||v_Count||' found)');
		END IF;

		FOR indx IN 1 .. t_PackageList.COUNT
		LOOP
			v_ObjName := t_PackageList(indx);
			SELECT COUNT(DISTINCT object_name) INTO v_Count FROM dba_procedures WHERE owner = v_SchemaName AND object_name = v_ObjName AND object_type = 'PACKAGE';
			IF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: package '||v_SchemaName||'.'||v_ObjName||' is not present!');
			ELSIF (v_Count = 1)	THEN
				DBMS_OUTPUT.PUT_LINE('-- package '||v_SchemaName||'.'||v_ObjName||' is present');
				SELECT status INTO v_ObjStatus FROM dba_objects WHERE owner = v_SchemaName AND object_name = v_ObjName AND object_type = 'PACKAGE';
				IF (v_ObjStatus != 'VALID')	THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: the package is not valid!');
				ELSE					DBMS_OUTPUT.PUT_LINE('-- the package is valid');
				END IF;

				SELECT status INTO v_ObjStatus FROM dba_objects WHERE owner = v_SchemaName AND object_name = v_ObjName AND object_type = 'PACKAGE BODY';
				IF (v_ObjStatus != 'VALID')	THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: the package body is not valid!');
				ELSE					DBMS_OUTPUT.PUT_LINE('-- the package body is valid');
				END IF;
			END IF;
			DBMS_OUTPUT.PUT_LINE('.');
		END LOOP;
		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('.');
	END LOOP;
END;
/

PROMPT
PROMPT ________________________________________________________________________________________________________
PROMPT Determining if the NuGenesis schemas own the expected triggers ...
PROMPT
DECLARE
v_Count			PLS_INTEGER := 0;
v_ExpectedNo		PLS_INTEGER;
v_SchemaName		VARCHAR2(100);

v_TriggerName		DBA_TRIGGERS.TRIGGER_NAME%TYPE;
v_TriggerStatus		dba_triggers.status%TYPE;
v_TableOwner		dba_triggers.table_owner%TYPE;
v_TriggerType		dba_triggers.trigger_type%TYPE;
v_triggerOwner		dba_triggers.owner%TYPE;
v_TriggerEvent		dba_triggers.triggering_event%TYPE;
v_TableName		dba_triggers.table_name%TYPE;

v_ExpectedStatus	dba_triggers.status %TYPE := 'ENABLED';
v_ExpectedTableName	dba_triggers.table_name%TYPE;
v_ExpectedTrigType	dba_triggers.trigger_type%TYPE;
v_ExpectedTrigEvent	dba_triggers.triggering_event%TYPE;

v_SQLQuery		VARCHAR2(4000 CHAR);
v_NameListForSQL	VARCHAR2(3000 CHAR);

TYPE DynCursor		IS REF CURSOR;
C_DynCursor		DynCursor;

TYPE ObjList		IS TABLE OF VARCHAR2(500);
TYPE NumList		IS TABLE OF NUMBER;
t_SchemaList		ObjList;
t_ExpectedNoList	NumList;
t_TriggerNameList	ObjList;
t_TriggerTypeList	ObjList;
t_TriggerEventList	ObjList;
t_TriggerTabNameList	ObjList;

BEGIN
	t_SchemaList     := ObjList('NGSYSUSER','ELNPROD','NGSDMS60');
	FOR indx IN 1 .. t_SchemaList.COUNT
	LOOP
		v_SchemaName := t_SchemaList(indx);
		IF	(v_SchemaName = 'NGSYSUSER')	THEN
			t_TriggerNameList    := ObjList('NGDELETENGGROUPSCLU_TRG','NGDELETENGUSERS_TRG','NGEMAILALERTS_TRG','SYNCELNUSERS',    'NGDELETENGUSERS_SYNC_TRG');
			t_TriggerTypeList    := ObjList('AFTER EACH ROW',         'AFTER EACH ROW',     'AFTER EACH ROW',   'AFTER EACH ROW',  'AFTER EACH ROW');
			t_TriggerTabNameList := ObjList('NGGROUPS',               'NGUSERS',            'NGEMAILALERTS',    'NGUSERSAUTHMODE', 'NGUSERS');
			t_TriggerEventList   := ObjList('DELETE',                 'DELETE',             'INSERT',           'INSERT OR UPDATE','DELETE');
		ELSIF	(v_SchemaName = 'NGSDMS60')	THEN
			t_TriggerNameList    := ObjList('NG_PROJECT_BACKUP_TRG_CLU','NGDELETENGPROJVIEWCLU_TRG','NGCONTENTMASTER_UPDATETRG','NGDELETETAG_TRG','NGDELETENGPROJTPL_TRG');
			t_TriggerTypeList    := ObjList('BEFORE EACH ROW',          'AFTER EACH ROW',           'AFTER EACH ROW',           'AFTER EACH ROW', 'AFTER EACH ROW');
			t_TriggerTabNameList := ObjList('NGPROJDEFS',               'NGPROJVIEW',               'NGCONTENTMASTER',          'NGTAGS',         'NGPROJTPL');
			t_TriggerEventList   := ObjList('DELETE',                   'DELETE',                   'UPDATE',                   'DELETE',         'DELETE');
		ELSIF	(v_SchemaName = 'ELNPROD')	THEN
			IF	(:v_LMSSchemaVerAsNum >= 9000 AND :v_LMSSchemaVerAsNum < 9100)	THEN
				t_TriggerNameList    := ObjList('PRODUCT_UPDATE','REPORTCONFIGURATION_UPDATE','SAMPLETEMPLTEST_INSERT','SAMPLETEMPLTEST_UPDATE','TRG_CHEMICAL_CREATE_DOCID','TRG_CHEMICALLOG_INSERT_UPDATE','MEASUREORDER_UPDATE','PHYSICALSAMPLE_UPDATE','SUBMISSIONSAMPLE_UPDATE','SUBMISSIONSAMPLE_INSERT','SMMETHODTEST_UPDATE','SMMETHODTEST_INSERT','UICONFIGURATION_UPDATE','SUBMISSIONTEMPLLIST_INSERT','SUBMISSIONTEMPLLIST_UPDATE','SMMETHOD_UPDATE','TESTRESULT_UPDATE','SUBMISSION_UPDATE','EXTERNALPLUGIN_UPDATE','TEST_UPDATE','MO_ORDERMETHGROUP_INSERT','TESTREQUEST_AFTER_UPDATE','TESTREQUEST_UPDATE','TESTDEFINITION_UPDATE','TESTSAMPLE_INSERT','SPECIFICATION_UPDATE','FORMULATION_INSERT','FORMULATION_UPDATE','SUBMISSIONTEST_UPDATE','SUBMISSIONTEST_INSERT','SPECSAMPLETEMPLATE_UPDATE','USERS_UPDATE','REQUESTSAMPLE_INSERT','SPECSAMPLETEMPLATE_INSERT','SPECIFICATIONTEST_UPDATE','SPECIFICATIONTEST_INSERT','SAMPLETEMPLATE_UPDATE','LOCATION_UPDATE','SUBMISSIONTEMPL_UPDATE','REPORTCONFIGLIBRARY_UPDATE');
				t_TriggerTypeList    := ObjList('BEFORE EACH ROW','BEFORE EACH ROW','AFTER EACH ROW','AFTER EACH ROW','AFTER EACH ROW','BEFORE EACH ROW','BEFORE EACH ROW','BEFORE EACH ROW','AFTER EACH ROW','AFTER EACH ROW','AFTER EACH ROW','AFTER EACH ROW','BEFORE EACH ROW','AFTER EACH ROW','AFTER EACH ROW','BEFORE EACH ROW','BEFORE EACH ROW','BEFORE EACH ROW','BEFORE EACH ROW','BEFORE EACH ROW','AFTER EACH ROW','AFTER EACH ROW','BEFORE EACH ROW','BEFORE EACH ROW','AFTER EACH ROW','BEFORE EACH ROW','AFTER EACH ROW','AFTER EACH ROW','AFTER EACH ROW','AFTER EACH ROW','AFTER EACH ROW','BEFORE EACH ROW','AFTER EACH ROW','AFTER EACH ROW','AFTER EACH ROW','AFTER EACH ROW','BEFORE EACH ROW','BEFORE EACH ROW','BEFORE EACH ROW','BEFORE EACH ROW');
				t_TriggerTabNameList := ObjList('PRODUCT','REPORTCONFIGURATION','SAMPLETEMPLTEST','SAMPLETEMPLTEST','INV_CHEMICALLOG','INV_CHEMICALLOG','MEASUREORDER','PHYSICALSAMPLE','SUBMISSIONSAMPLE','SUBMISSIONSAMPLE','SMMETHODTEST','SMMETHODTEST','UICONFIGURATION','SUBMISSIONTEMPLATELIST','SUBMISSIONTEMPLATELIST','SMMETHOD','TESTRESULT','SUBMISSION','EXTERNALPLUGIN','TEST','MO_ORDERMETHGROUP','TESTREQUEST','TESTREQUEST','TESTDEFINITION','TESTSAMPLE','SPECIFICATION','FORMULATION','FORMULATION','SUBMISSIONTEST','SUBMISSIONTEST','SPECIFICATIONSAMPLETEMPLATE','USERS','REQUESTSAMPLE','SPECIFICATIONSAMPLETEMPLATE','SPECIFICATIONTEST','SPECIFICATIONTEST','SAMPLETEMPLATE','LOCATION','SUBMISSIONTEMPLATE','REPORTCONFIGLIBRARY');
				t_TriggerEventList   := ObjList('UPDATE','UPDATE','INSERT','UPDATE','INSERT','INSERT OR UPDATE','UPDATE','UPDATE','UPDATE','INSERT','UPDATE','INSERT','UPDATE','INSERT','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','INSERT','UPDATE','UPDATE','UPDATE','INSERT','UPDATE','INSERT','UPDATE','UPDATE','INSERT','UPDATE','UPDATE','INSERT','INSERT','UPDATE','INSERT','UPDATE','UPDATE','UPDATE','UPDATE');
			ELSIF	(:v_LMSSchemaVerAsNum >= 9100 AND :v_LMSSchemaVerAsNum < 9200)	THEN
				t_TriggerNameList    := ObjList('PRODUCT_UPDATE','REPORTCONFIGURATION_UPDATE','SAMPLETEMPLTEST_INSERT','SAMPLETEMPLTEST_UPDATE','TRG_CHEMICAL_CREATE_DOCID','TRG_CHEMICALLOG_INSERT_UPDATE','MEASUREORDER_UPDATE','PHYSICALSAMPLE_UPDATE','SUBMISSIONSAMPLE_UPDATE','SUBMISSIONSAMPLE_INSERT','SMMETHODTEST_UPDATE','SMMETHODTEST_INSERT','UICONFIGURATION_UPDATE','SUBMISSIONTEMPLLIST_INSERT','SUBMISSIONTEMPLLIST_UPDATE','SMMETHOD_UPDATE','TESTRESULT_UPDATE','SUBMISSION_UPDATE','EXTERNALPLUGIN_UPDATE','TEST_UPDATE','MO_ORDERMETHGROUP_INSERT','TESTREQUEST_AFTER_UPDATE','TESTREQUEST_UPDATE','TESTDEFINITION_UPDATE','TESTSAMPLE_INSERT','SPECIFICATION_UPDATE','FORMULATION_INSERT','FORMULATION_UPDATE','SUBMISSIONTEST_UPDATE','SUBMISSIONTEST_INSERT','SPECSAMPLETEMPLATE_UPDATE','USERS_UPDATE','REQUESTSAMPLE_INSERT','SPECSAMPLETEMPLATE_INSERT','SPECIFICATIONTEST_UPDATE','SPECIFICATIONTEST_INSERT','SAMPLETEMPLATE_UPDATE','LOCATION_UPDATE','SUBMISSIONTEMPL_UPDATE','REPORTCONFIGLIBRARY_UPDATE','INV_INSTRUMENT_UPDATE','INV_CHEMICAL_UPDATE','DOMAIN_BEFORE_UPDATE','DOMAINVALUE_BEFORE_UPDATE');
				t_TriggerTypeList    := ObjList('BEFORE EACH ROW','BEFORE EACH ROW','AFTER EACH ROW','AFTER EACH ROW','AFTER EACH ROW','BEFORE EACH ROW','BEFORE EACH ROW','BEFORE EACH ROW','AFTER EACH ROW','AFTER EACH ROW','AFTER EACH ROW','AFTER EACH ROW','BEFORE EACH ROW','AFTER EACH ROW','AFTER EACH ROW','BEFORE EACH ROW','BEFORE EACH ROW','BEFORE EACH ROW','BEFORE EACH ROW','BEFORE EACH ROW','AFTER EACH ROW','AFTER EACH ROW','BEFORE EACH ROW','BEFORE EACH ROW','AFTER EACH ROW','BEFORE EACH ROW','AFTER EACH ROW','AFTER EACH ROW','AFTER EACH ROW','AFTER EACH ROW','AFTER EACH ROW','BEFORE EACH ROW','AFTER EACH ROW','AFTER EACH ROW','AFTER EACH ROW','AFTER EACH ROW','BEFORE EACH ROW','BEFORE EACH ROW','BEFORE EACH ROW','BEFORE EACH ROW','BEFORE EACH ROW','BEFORE EACH ROW','BEFORE EACH ROW','BEFORE EACH ROW');
				t_TriggerTabNameList := ObjList('PRODUCT','REPORTCONFIGURATION','SAMPLETEMPLTEST','SAMPLETEMPLTEST','INV_CHEMICALLOG','INV_CHEMICALLOG','MEASUREORDER','PHYSICALSAMPLE','SUBMISSIONSAMPLE','SUBMISSIONSAMPLE','SMMETHODTEST','SMMETHODTEST','UICONFIGURATION','SUBMISSIONTEMPLATELIST','SUBMISSIONTEMPLATELIST','SMMETHOD','TESTRESULT','SUBMISSION','EXTERNALPLUGIN','TEST','MO_ORDERMETHGROUP','TESTREQUEST','TESTREQUEST','TESTDEFINITION','TESTSAMPLE','SPECIFICATION','FORMULATION','FORMULATION','SUBMISSIONTEST','SUBMISSIONTEST','SPECIFICATIONSAMPLETEMPLATE','USERS','REQUESTSAMPLE','SPECIFICATIONSAMPLETEMPLATE','SPECIFICATIONTEST','SPECIFICATIONTEST','SAMPLETEMPLATE','LOCATION','SUBMISSIONTEMPLATE','REPORTCONFIGLIBRARY','INV_INSTRUMENT','INV_CHEMICAL','DOMAIN','DOMAINVALUE');
				t_TriggerEventList   := ObjList('UPDATE','UPDATE','INSERT','UPDATE','INSERT','INSERT OR UPDATE','UPDATE','UPDATE','UPDATE','INSERT','UPDATE','INSERT','UPDATE','INSERT','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','INSERT','UPDATE','UPDATE','UPDATE','INSERT','UPDATE','INSERT','UPDATE','UPDATE','INSERT','UPDATE','UPDATE','INSERT','INSERT','UPDATE','INSERT','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE');
			ELSIF	(:v_LMSSchemaVerAsNum >= 9200)					THEN
				t_TriggerNameList    := ObjList('PRODUCT_UPDATE','REPORTCONFIGURATION_UPDATE','SAMPLETEMPLTEST_INSERT','SAMPLETEMPLTEST_UPDATE','TRG_CHEMICAL_CREATE_DOCID','TRG_CHEMICALLOG_INSERT_UPDATE','MEASUREORDER_UPDATE','PHYSICALSAMPLE_UPDATE','SUBMISSIONSAMPLE_UPDATE','SUBMISSIONSAMPLE_INSERT','SMMETHODTEST_UPDATE','SMMETHODTEST_INSERT','UICONFIGURATION_UPDATE','SUBMISSIONTEMPLLIST_INSERT','SUBMISSIONTEMPLLIST_UPDATE','SMMETHOD_UPDATE','TESTRESULT_UPDATE','SUBMISSION_UPDATE','EXTERNALPLUGIN_UPDATE','TEST_UPDATE','MO_ORDERMETHGROUP_INSERT','TESTREQUEST_AFTER_UPDATE','TESTREQUEST_UPDATE','TESTDEFINITION_UPDATE','TESTSAMPLE_INSERT','SPECIFICATION_UPDATE','FORMULATION_INSERT','FORMULATION_UPDATE','SUBMISSIONTEST_UPDATE','SUBMISSIONTEST_INSERT','SPECSAMPLETEMPLATE_UPDATE','USERS_UPDATE','REQUESTSAMPLE_INSERT','SPECSAMPLETEMPLATE_INSERT','SPECIFICATIONTEST_UPDATE','SPECIFICATIONTEST_INSERT','SAMPLETEMPLATE_UPDATE','LOCATION_UPDATE','SUBMISSIONTEMPL_UPDATE','REPORTCONFIGLIBRARY_UPDATE','INV_INSTRUMENT_UPDATE','INV_CHEMICAL_UPDATE','DOMAIN_BEFORE_UPDATE','DOMAINVALUE_BEFORE_UPDATE');
				t_TriggerTypeList    := ObjList('BEFORE EACH ROW','BEFORE EACH ROW','AFTER EACH ROW','AFTER EACH ROW','AFTER EACH ROW','BEFORE EACH ROW','BEFORE EACH ROW','BEFORE EACH ROW','AFTER EACH ROW','AFTER EACH ROW','AFTER EACH ROW','AFTER EACH ROW','BEFORE EACH ROW','AFTER EACH ROW','AFTER EACH ROW','BEFORE EACH ROW','BEFORE EACH ROW','BEFORE EACH ROW','BEFORE EACH ROW','BEFORE EACH ROW','AFTER EACH ROW','AFTER EACH ROW','BEFORE EACH ROW','BEFORE EACH ROW','AFTER EACH ROW','BEFORE EACH ROW','AFTER EACH ROW','AFTER EACH ROW','AFTER EACH ROW','AFTER EACH ROW','AFTER EACH ROW','BEFORE EACH ROW','AFTER EACH ROW','AFTER EACH ROW','AFTER EACH ROW','AFTER EACH ROW','BEFORE EACH ROW','BEFORE EACH ROW','BEFORE EACH ROW','BEFORE EACH ROW','BEFORE EACH ROW','BEFORE EACH ROW','BEFORE EACH ROW','BEFORE EACH ROW');
				t_TriggerTabNameList := ObjList('PRODUCT','REPORTCONFIGURATION','SAMPLETEMPLTEST','SAMPLETEMPLTEST','INV_CHEMICALLOG','INV_CHEMICALLOG','MEASUREORDER','PHYSICALSAMPLE','SUBMISSIONSAMPLE','SUBMISSIONSAMPLE','SMMETHODTEST','SMMETHODTEST','UICONFIGURATION','SUBMISSIONTEMPLATELIST','SUBMISSIONTEMPLATELIST','SMMETHOD','TESTRESULT','SUBMISSION','EXTERNALPLUGIN','TEST','MO_ORDERMETHGROUP','TESTREQUEST','TESTREQUEST','TESTDEFINITION','TESTSAMPLE','SPECIFICATION','FORMULATION','FORMULATION','SUBMISSIONTEST','SUBMISSIONTEST','SPECIFICATIONSAMPLETEMPLATE','USERS','REQUESTSAMPLE','SPECIFICATIONSAMPLETEMPLATE','SPECIFICATIONTEST','SPECIFICATIONTEST','SAMPLETEMPLATE','LOCATION','SUBMISSIONTEMPLATE','REPORTCONFIGLIBRARY','INV_INSTRUMENT','INV_CHEMICAL','DOMAIN','DOMAINVALUE');
				t_TriggerEventList   := ObjList('UPDATE','UPDATE','INSERT','UPDATE','INSERT','INSERT OR UPDATE','UPDATE','UPDATE','UPDATE','INSERT','UPDATE','INSERT','UPDATE','INSERT','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','INSERT','UPDATE','UPDATE','UPDATE','INSERT','UPDATE','INSERT','UPDATE','UPDATE','INSERT','UPDATE','UPDATE','INSERT','INSERT','UPDATE','INSERT','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE','UPDATE');

			END IF;
		END IF;
		v_ExpectedNo := t_TriggerNameList.COUNT;
		v_NameListForSQL := NULL;

		SELECT COUNT(OBJECT_NAME) INTO v_Count FROM DBA_OBJECTS WHERE OBJECT_TYPE = 'TRIGGER' AND OWNER = v_SchemaName;
		IF	(v_Count = v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE (v_SchemaName||' owns the expected number of triggers ('||v_ExpectedNo||' expected, '||v_Count||' found).');
		ELSIF	(v_Count < v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE ('!!!!! ERROR: '||v_SchemaName||' owns less than the expected number of triggers ('||v_ExpectedNo||' expected, '||v_Count||' found)!');
		ELSIF	(v_Count > v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE (v_SchemaName||' owns more than the expected number of triggers ('||v_ExpectedNo||' expected, '||v_Count||' found).');
		END IF;

		FOR indx2 IN 1 .. t_TriggerNameList.COUNT
		LOOP
			v_TriggerName       := t_TriggerNameList(indx2);
			v_ExpectedTableName := t_TriggerTabNameList(indx2);
			v_ExpectedTrigType  := t_TriggerTypeList(indx2);
			v_ExpectedTrigEvent := t_TriggerEventList(indx2);

			-- Build a list of the trigger names as a varchar so that we can use the list in a dynamic SQL query.
			v_NameListForSQL := v_NameListForSQL || '''' || t_TriggerNameList(indx2) || '''';
			IF (indx2 < t_TriggerNameList.COUNT) THEN v_NameListForSQL := v_NameListForSQL || ',';
			END IF;

			SELECT COUNT(*) INTO v_Count FROM dba_triggers WHERE owner = v_SchemaName AND trigger_name = v_TriggerName;
			IF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: trigger: '||v_SchemaName||'.'||v_TriggerName||' is not present!');
			ELSIF (v_Count = 1)	THEN
				DBMS_OUTPUT.PUT_LINE('Trigger: '||v_SchemaName||'.'||v_TriggerName||' is present');
				SELECT status INTO v_TriggerStatus FROM dba_triggers WHERE owner = v_SchemaName AND trigger_name = v_TriggerName;
				IF (v_TriggerStatus != v_ExpectedStatus)	THEN	DBMS_OUTPUT.PUT_LINE('--!!!!! ERROR: the trigger is not '||v_ExpectedStatus||'!');
				ELSE							DBMS_OUTPUT.PUT_LINE('-- the trigger is '||v_ExpectedStatus);
				END IF;

				SELECT table_owner, table_name, trigger_type, triggering_event INTO v_TableOwner, v_TableName, v_TriggerType, v_TriggerEvent FROM dba_triggers WHERE owner = v_SchemaName AND trigger_name = v_TriggerName;
				IF(v_TableOwner != v_SchemaName OR v_TableName != v_ExpectedTableName)	THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: trigger '||v_TriggerName||' is not correctly defined!  It must point to the table '||v_SchemaName||'.'||v_ExpectedTableName||'!');	END IF;
				IF(v_TriggerType != v_ExpectedTrigType)					THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: trigger '||v_TriggerName||' is not correctly defined!  Trigger type must be '||v_ExpectedTrigType||'!');			END IF;
				IF(v_TriggerEvent != v_ExpectedTrigEvent)				THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: trigger '||v_TriggerName||' is not correctly defined!  Trigger event must be '||v_ExpectedTrigEvent||'!');		END IF;
			END IF;
			DBMS_OUTPUT.PUT_LINE ('.');
		END LOOP;

		-- Build a SQL query to find any unexpected triggers in the schemas.
		v_SQLQuery := 'SELECT COUNT(*) FROM dba_triggers WHERE owner IN ('''||v_SchemaName||''') AND trigger_name NOT IN ('||v_NameListForSQL||')';
		-- DBMS_OUTPUT.PUT_LINE ('-- DEBUG: v_SQLQuery='||v_SQLQuery);
		EXECUTE IMMEDIATE v_SQLQuery INTO v_Count;
		DBMS_OUTPUT.PUT_LINE ('Number of unexpected triggers owned by '||v_SchemaName||': '||v_Count);
		IF (v_Count > 0)	THEN
			v_SQLQuery := 'SELECT trigger_name FROM dba_triggers WHERE owner IN ('''||v_SchemaName||''') AND trigger_name NOT IN ('||v_NameListForSQL||')';
			OPEN C_DynCursor FOR v_SQLQuery;
			LOOP
				FETCH C_DynCursor INTO v_TriggerName;
				EXIT WHEN C_DynCursor%NOTFOUND;

				DBMS_OUTPUT.PUT_LINE('-- '||v_SchemaName||'.'||v_TriggerName);
			END LOOP;
			CLOSE C_DynCursor;
		END IF;
		DBMS_OUTPUT.PUT_LINE ('.');
		DBMS_OUTPUT.PUT_LINE ('.');
	END LOOP;

	v_TriggerName := 'WATERS_PREVENT_PW_CHANGE';
	DBMS_OUTPUT.PUT_LINE ('.');
	DBMS_OUTPUT.PUT_LINE ('Checking for the presence of the '||v_TriggerName||' trigger');
	SELECT COUNT(*) INTO v_Count FROM dba_triggers WHERE trigger_name = v_TriggerName and owner = 'SYS';
	IF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE ('!!!!! ERROR: The trigger sys.'||v_TriggerName||' is NOT present');
	ELSIF (v_Count > 1)	THEN	DBMS_OUTPUT.PUT_LINE ('More than one trigger '||v_TriggerName||' is present in this database');
	ELSIF (v_Count = 1)	THEN
		DBMS_OUTPUT.PUT_LINE ('The trigger sys.'||v_TriggerName||' is present');
		SELECT owner, status INTO v_triggerOwner, v_TriggerStatus FROM dba_triggers WHERE trigger_name = v_TriggerName;
		DBMS_OUTPUT.PUT_LINE('-- owner: '||v_triggerOwner);
		IF (v_TriggerStatus = 'ENABLED')	THEN	DBMS_OUTPUT.PUT_LINE('-- status: '||v_TriggerStatus);
		ELSE						DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: trigger status: '||v_TriggerStatus||'!');
		END IF;
	END IF;
END;
/
PROMPT
PROMPT ________________________________________________________________________________________________________
PROMPT

COLUMN trigger_name 	FORMAT A30
COLUMN TRIGGERING_EVENT FORMAT A20
col object_name format a30
PROMPT
PROMPT List of triggers owned by the NuGenesis schemas:
SELECT owner, trigger_name, trigger_type, triggering_event, table_name, status FROM dba_triggers WHERE owner IN ('NGSYSUSER', 'NGSDMS60', 'ELNPROD') AND trigger_name NOT LIKE 'BIN%' ORDER BY owner, trigger_name;

PROMPT
PROMPT List of packages, procedures, functions owned by the NuGenesis schemas:
SELECT owner, object_type, object_name, status FROM DBA_OBJECTS WHERE OBJECT_TYPE IN ('PACKAGE','PROCEDURE','FUNCTION') AND OWNER IN ('NGSYSUSER','NGSDMS60','ELNPROD') ORDER BY owner, object_type, object_name;

PROMPT
PROMPT
PROMPT ___________________________________________________________________________________________________________
PROMPT Determining whether the expected NuGenesis sequences are present...
PROMPT

DECLARE
v_Count			PLS_INTEGER := 0;
v_ExpectedNo		PLS_INTEGER;
v_ObjName		dba_sequences.sequence_name%TYPE;
v_ObjStatus		dba_objects.status%TYPE;
v_SchemaName		dba_sequences.sequence_owner%TYPE;
TYPE ObjList		IS TABLE OF VARCHAR2(500);
t_SequenceList		ObjList;
t_SequenceOwnerList	ObjList;

BEGIN
	IF	(:v_ConnTableCount > 0)	THEN
		t_SequenceList      := ObjList('NGAUDITSEQ','NGAUDITVIEWIDSEQ','NGC_LIMS_SEQ','NGC_MAPPING_SEQ'); -- Include the Connectors sequences if the NGC schema is present; omit if not present
		t_SequenceOwnerList := ObjList('NGSYSUSER', 'NGSYSUSER',       'ELNPROD',     'ELNPROD');
	ELSE
		t_SequenceList      := ObjList('NGAUDITSEQ','NGAUDITVIEWIDSEQ');
		t_SequenceOwnerList := ObjList('NGSYSUSER', 'NGSYSUSER');
	END IF;
	v_ExpectedNo   := t_SequenceList.COUNT;

	SELECT COUNT(*) INTO v_Count FROM dba_sequences WHERE sequence_owner IN ('NGSYSUSER', 'NGSDMS60', 'ELNPROD');
	IF (v_Count = v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('The expected number of sequences are present ('||v_ExpectedNo||' expected, '||v_Count||' found)');
	ELSIF (v_Count < v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: '||v_SchemaName||' owns less than the expected number of sequences ('||v_ExpectedNo||' expected, '||v_Count||' found)!');
	ELSIF (v_Count > v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('!!! WARNING: '||v_SchemaName||' owns more than the expected number of sequences ('||v_ExpectedNo||' expected, '||v_Count||' found)');
	END IF;

	FOR indx IN 1 .. t_SequenceList.COUNT
	LOOP
		v_ObjName    := t_SequenceList(indx);
		v_SchemaName := t_SequenceOwnerList(indx);
		SELECT COUNT(*) INTO v_Count FROM dba_sequences WHERE sequence_owner = v_SchemaName AND sequence_name = v_ObjName;
		IF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: sequence '||v_SchemaName||'.'||v_ObjName||' is not present!');
		ELSIF (v_Count = 1)	THEN
			DBMS_OUTPUT.PUT_LINE('Sequence '||v_SchemaName||'.'||v_ObjName||' is present');
			SELECT status INTO v_ObjStatus FROM dba_objects WHERE owner = v_SchemaName AND object_name = v_ObjName AND object_Type = 'SEQUENCE';
			IF (v_ObjStatus != 'VALID')	THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: the sequence is not valid!');
			ELSE					DBMS_OUTPUT.PUT_LINE('-- the sequence is valid');
			END IF;
		END IF;
		DBMS_OUTPUT.PUT_LINE('.');
	END LOOP;
END;
/

PROMPT
PROMPT
PROMPT ___________________________________________________________________________________________________________
PROMPT Checking for any DB links owned by NuGenesis schema accounts
PROMPT
PROMPT DB links are not expected in the default NuGenesis schemas.  Links may be added if the LMS Data location is set to a different server or if a Mailbox is created in the NuGenesis Connectors module.
PROMPT

DECLARE
v_Count			PLS_INTEGER := 0;
v_ExpectedNo		PLS_INTEGER;
v_DBLinkOwner		dba_db_links.owner%TYPE;
v_DBLinkName		dba_db_links.db_link%TYPE;
v_DBLinkUsername	dba_db_links.username%TYPE;
v_DBLinkHost		dba_db_links.host%TYPE;

CURSOR C_NGDBLinks IS	SELECT owner, db_link, username, host FROM dba_db_links WHERE owner IN ('ELNPROD','NGSYSUSER','NGSDMS60');
BEGIN
	SELECT COUNT(*) INTO v_Count FROM dba_db_links WHERE owner IN ('ELNPROD','NGSYSUSER','NGSDMS60');
	DBMS_OUTPUT.PUT_LINE('Number of db_links owned by NuGenesis schema accounts: '||v_Count);
	IF v_Count > 0		THEN
		OPEN C_NGDBLinks;
		LOOP
			FETCH C_NGDBLinks INTO v_DBLinkOwner, v_DBLinkName, v_DBLinkUsername, v_DBLinkHost;
			EXIT WHEN C_NGDBLinks%NOTFOUND;

			DBMS_OUTPUT.PUT_LINE('-- Owner: ' ||v_DBLinkOwner||'	Link name: '||v_DBLinkName||'	user: '||v_DBLinkUsername||'	host: '||v_DBLinkHost);
		END LOOP;
		CLOSE C_NGDBLinks;
	END IF;
END;
/

PROMPT
PROMPT
PROMPT ___________________________________________________________________________________________________________
PROMPT Verifying the NuGenesis clusters...
PROMPT

DECLARE
v_Count		PLS_INTEGER;
v_clustername	VARCHAR2(30);
v_clustertype	VARCHAR2(5);
v_tblspace	VARCHAR2(30);
v_own		VARCHAR2(30);
v_tabnm		VARCHAR2(30);
v_status	VARCHAR2(8);

TYPE ObjList	IS TABLE OF VARCHAR2(500);
t_ClusterNameList	ObjList;
t_ClusterTabNameList	ObjList;
t_ClusterOwnerList	ObjList;
t_ClusterTbsList	ObjList;
t_ClusterTypeList	ObjList;
t_ClusterIndexList	ObjList;

BEGIN
	t_ClusterNameList  := ObjList('SDMS70_GROUP_IND_CLU',    'SDMS70_IND_CLU',   'SDMS70_AUDIT_CLU');
	t_ClusterOwnerList := ObjList('NGSYSUSER',               'NGSDMS60',         'NGSYSUSER');
	t_CLusterTbsList   := ObjList('SYSUSERDATA',             'SDMS80DATA',       'SYSUSERDATA');
	t_ClusterTypeList  := ObjList('INDEX',                   'INDEX',            'INDEX');
	t_ClusterIndexList := ObjList('SDMS70_GROUP_IND_CLU_IDX','SDMS70_IND_CLU_IDX','SDMS70_AUDIT_CLU_IDX');
	FOR indx IN 1 .. t_ClusterNameList.COUNT
	LOOP
		v_ClusterName := t_ClusterNameList(indx);
		IF(v_ClusterName = 'SDMS70_GROUP_IND_CLU')	THEN	t_ClusterTabNameList := ObjList('NGGROUPS','NGGROUPMEMBERS');
		ELSIF(v_ClusterName = 'SDMS70_IND_CLU')		THEN	t_ClusterTabNameList := ObjList('NGPRIVILEGE');
		ELSIF(v_ClusterName = 'SDMS70_AUDIT_CLU')	THEN
			IF (:v_LMSSchemaVerAsNum < 9310)	THEN	t_ClusterTabNameList := ObjList('NGAUDITMASTER','NGAUDITDETAILS');
			ELSIF (:v_LMSSchemaVerAsNum >= 9310)	THEN	t_ClusterTabNameList := ObjList('NGAUDITDETAILS'); -- ngauditmaster removed from cluster SDMS70_AUDIT_CLU in v9.3.1
			END IF;
		END IF;

		SELECT COUNT(*) INTO v_Count FROM DBA_CLUSTERS WHERE CLUSTER_NAME = v_ClusterName;
		IF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: cluster '||v_ClusterName||' is not present!');
		ELSE
			DBMS_OUTPUT.PUT_LINE('Cluster '||v_ClusterName||' is present');

			SELECT COUNT(TABLE_NAME) INTO v_Count FROM DBA_TABLES WHERE CLUSTER_NAME = v_ClusterName;
			DBMS_OUTPUT.PUT_LINE('-- Number of tables in this cluster: '||v_Count);
			FOR indx2 IN 1 .. t_ClusterTabNameList.COUNT
			LOOP
				SELECT COUNT(*) INTO v_Count FROM dba_tables WHERE Cluster_name = v_ClusterName AND table_name = t_ClusterTabNameList(indx2);
				IF (v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('-- table: '||t_ClusterTabNameList(indx2)||' is in this cluster');
				ELSIF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: table: '||t_ClusterTabNameList(indx2)||' is NOT in this cluster!');
				END IF;
			END LOOP;

			SELECT  OWNER, CLUSTER_TYPE, TABLESPACE_NAME INTO v_own, v_clustertype, v_tblspace FROM DBA_CLUSTERS WHERE CLUSTER_NAME = v_ClusterName;
			IF (v_own = t_ClusterOwnerList(indx))		THEN	DBMS_OUTPUT.PUT_LINE('-- owner: '||v_own);
			ELSE							DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: owner: '||v_own||', expected '||t_ClusterOwnerList(indx));
			END IF;

			IF (v_clustertype = t_ClusterTypeList(indx))	THEN	DBMS_OUTPUT.PUT_LINE('-- type: '||v_clustertype);
			ELSE							DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: type: '||v_clustertype||', expected '||t_ClusterTypeList(indx));
			END IF;

			IF (v_tblspace = t_ClusterTbsList(indx))	THEN	DBMS_OUTPUT.PUT_LINE('-- tablespace: '||v_tblspace);
			ELSE							DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: tablespace: '||v_tblspace||', expected '||t_ClusterTbsList(indx));
			END IF;

			SELECT COUNT(*) INTO v_Count FROM DBA_INDEXES WHERE INDEX_NAME = t_ClusterIndexList(indx) AND INDEX_TYPE = 'CLUSTER' AND TABLE_NAME = v_ClusterName;
			IF (v_Count = 0)				THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: index '||t_ClusterIndexList(indx)||' is not present!');
			ELSE							DBMS_OUTPUT.PUT_LINE('-- index '||t_ClusterIndexList(indx)||' is present');
				SELECT STATUS INTO v_status FROM DBA_INDEXES WHERE INDEX_NAME = t_ClusterIndexList(indx) AND INDEX_TYPE = 'CLUSTER' AND TABLE_NAME = v_ClusterName;
				IF v_status = 'VALID' THEN			DBMS_OUTPUT.PUT_LINE('-- cluster index is '||v_status);
				ELSE						DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: cluster index is: '||v_status||'!');
				END IF;
			END IF;
		END IF;

		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('.');
	END LOOP;
END;
/

PROMPT
PROMPT NuGenesis cluster details:
SELECT CLUSTER_NAME, OWNER, CLUSTER_TYPE, TABLESPACE_NAME FROM DBA_CLUSTERS WHERE OWNER IN ('NGSDMS60', 'NGSYSUSER','ELNPROD');

PROMPT
PROMPT Tables in NuGenesis clusters:
SELECT cluster_name, table_name FROM DBA_TABLES WHERE CLUSTER_NAME LIKE 'SDMS%';

PROMPT
PROMPT NuGenesis cluster indexes:
SELECT INDEX_NAME, INDEX_TYPE, TABLE_NAME, STATUS FROM DBA_INDEXES WHERE  TABLE_NAME IN ('SDMS70_IND_CLU', 'SDMS70_GROUP_IND_CLU', 'SDMS70_AUDIT_CLU');

PROMPT
PROMPT NuGenesis cluster index details:
COLUMN COLUMN_NAME FORMAT A25
SELECT INDEX_NAME, TABLE_NAME, COLUMN_NAME, COLUMN_POSITION FROM DBA_IND_COLUMNS WHERE INDEX_NAME IN ('SDMS70_IND_CLU_IDX', 'SDMS70_GROUP_IND_CLU_IDX', 'SDMS70_AUDIT_CLU_IDX');

PROMPT
PROMPT
PROMPT ***************************************************************************************************************************************
PROMPT Verifying the Oracle Text configuration in this database instance...
PROMPT ***************************************************************************************************************************************
PROMPT
PROMPT

PROMPT
PROMPT ___________________________________________________________________________________________________________
PROMPT Determining whether the Oracle Text option is installed and configured for NuGenesis...
PROMPT
DECLARE 
v_Count		PLS_INTEGER := 0;
v_Count2	PLS_INTEGER := 0;
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
	IF v_Count > 0 THEN
		DBMS_OUTPUT.PUT_LINE('This database instance was created with the Oracle Text option.');

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

		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('Determining whether the Oracle Text preferences for NuGenesis are present...');
		t_PrefsList  := ObjList('EXTERNALPLUGIN_DATASTORE','LOCATION_DATASTORE','MEASUREORDER_DATASTORE','PHYSICALSAMPLE_DATASTORE','PRODUCT_DATASTORE','REPORTCONFIGLIBRARY_DATASTORE','REPORTCONFIGURATION_DATASTORE','SAMPLETEMPLATE_DATASTORE','SMMETHOD_DATASTORE','SPECIFICATION_DATASTORE','SUBMISSIONTEMPL_DATASTORE','SUBMISSION_DATASTORE','TESTDEFINITION_DATASTORE','TESTREQUEST_DATASTORE','TEST_DATASTORE','UICONFIGURATION_DATASTORE','USERMESSAGE_DATASTORE','USERS_DATASTORE','ELNLEX', 'CTX_BINARYDOCUMENT_WORDLIST','CTX_BINARYDOCUMENT_STORAGE','CTX_BINARYDOCUMENT_LEXER','CTX_BINARYDOCUMENT_FILTER','CTX_BINARYDOCUMENT_DATASTORE','ADVANCE_SEARCH_WORDLIST','ADVANCE_SEARCH_STORAGE','ADVANCE_SEARCH_LEXER','ADVANCE_SEARCH_FILTER','ADVANCE_SEARCH_DATASTORE');
		t_SchemaList := ObjList('ELNPROD',                 'ELNPROD',           'ELNPROD',               'ELNPROD',                 'ELNPROD',          'ELNPROD',                      'ELNPROD',                      'ELNPROD',                 'ELNPROD',           'ELNPROD',                'ELNPROD',                  'ELNPROD',             'ELNPROD',                 'ELNPROD',              'ELNPROD',       'ELNPROD',                  'ELNPROD',              'ELNPROD',        'ELNPROD','ELNPROD',                    'ELNPROD',                   'ELNPROD',                 'ELNPROD',                  'ELNPROD',                     'NGSDMS60',               'NGSDMS60',              'NGSDMS60',            'NGSDMS60',             'NGSDMS60');
		v_ExpectedNo := t_PrefsList.COUNT;

		FOR indx IN 1 .. t_PrefsList.COUNT
		LOOP
			v_SchemaName := t_SchemaList(indx);
			v_PrefName   := t_PrefsList(indx);
			SELECT COUNT(*) INTO v_Count FROM CTXSYS.CTX_PREFERENCES WHERE pre_owner = v_SchemaName AND pre_name = v_PrefName;
			IF (v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('-- Oracle Text preference '||v_SchemaName||'.'||v_PrefName||' has been created');
	 		ELSIF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: Oracle Text preference '||v_SchemaName||'.'||v_PrefName||' has NOT been created!');
		 	END IF;
		END LOOP;

		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('Determinining whether the NuGenesis schemas have been granted Execute on ctxsys.ctx_ddl or the ctxapp role...');
		t_SchemaList := ObjList('NGSDMS60','ELNPROD');
		FOR indx IN 1 .. t_SchemaList.COUNT
		LOOP
			SELECT COUNT(*) INTO v_Count FROM dba_tab_privs WHERE table_name = 'CTX_DDL' AND PRIVILEGE = 'EXECUTE' AND GRANTOR = 'CTXSYS' AND GRANTEE = t_SchemaList(indx);
			SELECT COUNT(*) INTO v_Count2 FROM dba_role_privs WHERE granted_role = 'CTXAPP' AND grantee = t_SchemaList(indx);
			IF	(v_Count = 1)			THEN	DBMS_OUTPUT.PUT_LINE('-- '||t_SchemaList(indx)||' has been granted EXECUTE on ctxsys.ctx_ddl.');	END IF;
			IF	(v_Count2 = 1)			THEN	DBMS_OUTPUT.PUT_LINE('-- '||t_SchemaList(indx)||' has been granted the role CTXAPP.');	END IF;
			IF	(v_Count = 0 AND v_Count2 = 0)	THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: '||t_SchemaList(indx)||' has NOT been granted execute on ctxsys.ctx_ddl nor the role ctxapp!');	END IF;
		END LOOP;
	ELSIF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: this database instance was created without the Oracle Text option!  Have the customer dba install this component, it is absolutely required for NuGenesis databases!!!!!');
	END IF;
END;
/

PROMPT
PROMPT ___________________________________________________________________________________________________________
PROMPT Determining whether the expected domain (Oracle Text) indexes are present for the NuGenesis schemas
PROMPT
DECLARE
TYPE CntCurTyp IS REF CURSOR;
cnt_cv			CntCurTyp;
v_Count			PLS_INTEGER := 0;
v_tab			CTXSYS.CTX_INDEXES.IDX_TABLE%TYPE;
v_stat			CTXSYS.CTX_INDEXES.IDX_STATUS%TYPE;
v_own			CTXSYS.CTX_INDEXES.IDX_OWNER%TYPE;
v_own2			CTXSYS.CTX_INDEXES.IDX_OWNER%TYPE;
v_domidx_status		DBA_INDEXES.DOMIDX_STATUS%TYPE;
v_domidx_opstatus	DBA_INDEXES.DOMIDX_OPSTATUS%TYPE;

v_ExpectedNo		PLS_INTEGER;

TYPE ObjList		IS TABLE OF VARCHAR2(500);
t_IndexNameList		ObjList;
t_IndexOwnerList	ObjList;

BEGIN
	IF (:v_LMSSchemaVerAsNum >= 9100)	THEN
		t_IndexOwnerList := ObjList('ELNPROD', 'ELNPROD', 'ELNPROD', 'ELNPROD', 'ELNPROD', 'ELNPROD', 'ELNPROD', 'ELNPROD', 'ELNPROD', 'ELNPROD', 'ELNPROD', 'ELNPROD', 'ELNPROD', 'ELNPROD', 'ELNPROD', 'ELNPROD', 'ELNPROD', 'ELNPROD', 'ELNPROD', 'ELNPROD', 'NGSDMS60','ELNPROD','ELNPROD');
		t_IndexNameList  := ObjList('CTX_BINARYDOCUMENT', 'TEXT_IDX_EXTERNALPLUGIN', 'TEXT_IDX_LOCATION', 'TEXT_IDX_MEASUREORDER', 'TEXT_IDX_PHYSICALSAMPLE', 'TEXT_IDX_PRODUCT', 'TEXT_IDX_REPORTCONFIG', 'TEXT_IDX_REPORTCONFIGLIB', 'TEXT_IDX_SAMPLETEMPLATE', 'TEXT_IDX_SMMETHOD', 'TEXT_IDX_SPECIFICATION', 'TEXT_IDX_SUBMISSION', 'TEXT_IDX_SUBMISSIONTEMPL', 'TEXT_IDX_TEST', 'TEXT_IDX_TESTDEFINITION', 'TEXT_IDX_TESTREQUEST', 'TEXT_IDX_TESTRESULT', 'TEXT_IDX_UICONFIGURATION', 'TEXT_IDX_USERMESSAGE', 'TEXT_IDX_USERS', 'ADVANCE_SEARCH','TEXT_IDX_INV_CHEMICAL','TEXT_IDX_INV_INSTRUMENT');
	ELSIF (:v_LMSSchemaVerAsNum >= 9000 AND :v_LMSSchemaVerAsNum < 9100)	THEN
		t_IndexOwnerList := ObjList('ELNPROD', 'ELNPROD', 'ELNPROD', 'ELNPROD', 'ELNPROD', 'ELNPROD', 'ELNPROD', 'ELNPROD', 'ELNPROD', 'ELNPROD', 'ELNPROD', 'ELNPROD', 'ELNPROD', 'ELNPROD', 'ELNPROD', 'ELNPROD', 'ELNPROD', 'ELNPROD', 'ELNPROD', 'ELNPROD', 'NGSDMS60');
		t_IndexNameList  := ObjList('CTX_BINARYDOCUMENT', 'TEXT_IDX_EXTERNALPLUGIN', 'TEXT_IDX_LOCATION', 'TEXT_IDX_MEASUREORDER', 'TEXT_IDX_PHYSICALSAMPLE', 'TEXT_IDX_PRODUCT', 'TEXT_IDX_REPORTCONFIG', 'TEXT_IDX_REPORTCONFIGLIB', 'TEXT_IDX_SAMPLETEMPLATE', 'TEXT_IDX_SMMETHOD', 'TEXT_IDX_SPECIFICATION', 'TEXT_IDX_SUBMISSION', 'TEXT_IDX_SUBMISSIONTEMPL', 'TEXT_IDX_TEST', 'TEXT_IDX_TESTDEFINITION', 'TEXT_IDX_TESTREQUEST', 'TEXT_IDX_TESTRESULT', 'TEXT_IDX_UICONFIGURATION', 'TEXT_IDX_USERMESSAGE', 'TEXT_IDX_USERS', 'ADVANCE_SEARCH');
	ELSE
		t_IndexOwnerList := ObjList();
		t_IndexNameList  := ObjList();
	END IF;
	v_ExpectedNo     := t_IndexNameList.COUNT;

	SELECT COUNT(*) INTO v_Count FROM ctxsys.ctx_indexes WHERE idx_owner IN ('ELNPROD','NGSDMS60','NGSYSUSER');
	IF (v_Count = v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('The NuGenesis schemas own the expected number of domain indexes ('||v_ExpectedNo||' expected, '||v_Count||' found)');
	ELSIF (v_Count < v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: The NuGenesis schemas own less than the expected number of domain indexes ('||v_ExpectedNo||' expected, '||v_Count||' found)!');
	ELSIF (v_Count > v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('The NuGenesis schemas own more than the expected number of domain indexes ('||v_ExpectedNo||' expected, '||v_Count||' found)');
	END IF;

	DBMS_OUTPUT.PUT_LINE('.');

	FOR indx IN 1.. t_IndexNameList.COUNT
	LOOP
		SELECT COUNT(*) INTO v_Count FROM CTXSYS.CTX_INDEXES WHERE IDX_NAME = t_IndexNameList(indx);
		IF (v_Count = 1)	THEN
			SELECT IDX_TABLE, IDX_OWNER, IDX_STATUS INTO v_tab,v_own,v_stat FROM CTXSYS.CTX_INDEXES WHERE IDX_NAME = t_IndexNameList(indx);
			DBMS_OUTPUT.PUT_LINE ('Index '||v_own||'.'||t_IndexNameList(indx)||' has been created for the '||v_tab||' table, and has an '||v_stat||' status');
			IF v_own != t_IndexOwnerList(indx)	THEN	DBMS_OUTPUT.PUT_LINE ('!!!!! ERROR: The '||t_IndexNameList(indx)||' index should be owned by '||t_IndexOwnerList(indx)||', but the owner is '||v_own||'!');
			END IF;

			SELECT DOMIDX_STATUS, DOMIDX_OPSTATUS INTO v_domidx_status, v_domidx_opstatus FROM DBA_INDEXES WHERE INDEX_NAME = t_IndexNameList(indx);
			IF (v_domidx_status = 'VALID')		THEN	DBMS_OUTPUT.PUT_LINE('-- The domidx_status of the index is '||v_domidx_status);
			ELSE						DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: The domidx_status of the index is '||v_domidx_opstatus);
			END IF;

			IF (v_domidx_opstatus = 'VALID')	THEN	DBMS_OUTPUT.PUT_LINE('-- The domidx_opstatus of the index is '||v_domidx_status);
			ELSE						DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: The domidx_opstatus of the index is '||v_domidx_status);
			END IF;
		ELSIF (v_Count = 0)	THEN				DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: The '||t_IndexNameList(indx)||' domain index has not been created!');
		ELSIF (v_Count > 1)	THEN
			DBMS_OUTPUT.PUT_LINE ('!!!!! ERROR: The '||t_IndexNameList(indx)||' domain index has been created in more than one schema!');
			OPEN cnt_cv FOR ('SELECT IDX_OWNER FROM CTXSYS.CTX_INDEXES WHERE IDX_NAME = '||CHR(39)||t_IndexNameList(indx)||CHR(39)||' ');
			LOOP
				FETCH cnt_cv INTO v_own2;
				EXIT WHEN cnt_cv%NOTFOUND;
				DBMS_OUTPUT.PUT_LINE ('The '||t_IndexNameList(indx)||' domain index has been created in the '||v_own2||' schema');
			END LOOP;
			CLOSE cnt_cv;
		END IF;

		DBMS_OUTPUT.PUT_LINE('.');
	END LOOP;
END;
/

COLUMN pre_owner FORMAT a20
COLUMN pre_name FORMAT a45
COLUMN pre_class FORMAT a20
COLUMN pre_object FORMAT a30
COLUMN prv_owner FORMAT a20
COLUMN prv_preference FORMAT a30
COLUMN prv_attribute FORMAT a30
COLUMN prv_value FORMAT a50

PROMPT
PROMPT ORACLE TEXT INFORMATION:
SELECT COMP_NAME, STATUS, version FROM DBA_REGISTRY WHERE COMP_ID = 'CONTEXT';

PROMPT
PROMPT Oracle Text preferences in this instance:
SELECT * FROM ctx_preferences where PRE_owner IN ('NGSDMS60','NGSYSUSER','ELNPROD','CTXSYS');

PROMPT
PROMPT NuGenesis oracle text preferences values in this instance:
SELECT * FROM ctx_preference_values where PRV_owner IN ('NGSDMS60','NGSYSUSER','ELNPROD') ORDER BY prv_owner, prv_preference, prv_attribute;

PROMPT
PROMPT ___________________________________________________________________________________________________________
PROMPT Determining whether the expected Oracle background jobs for NuGenesis are present and running
PROMPT

DECLARE
v_JobRunStatus	VARCHAR2(30);	
v_enable	VARCHAR2(5);
v_fail		NUMBER;
v_Count		PLS_INTEGER := 0;
v_JobOwner	dba_scheduler_jobs.owner%TYPE;
v_JobRunCount	dba_scheduler_jobs.run_count%TYPE;
v_JobMostRecentRunDate	TIMESTAMP(6);
TYPE ObjList		IS TABLE OF VARCHAR2(500);
t_JobNameList		ObjList;
t_JobOwnerList		ObjList;
v_ExpectedNo		PLS_INTEGER;
v_JobName		VARCHAR2(500);

CURSOR C_MultipleJobs IS	SELECT owner FROM dba_scheduler_jobs WHERE job_name = v_JobName;

BEGIN
	t_JobNameList  := ObjList('WATELNTEXTOPT','WATELNTEXTSYNC','WATTEXTASOPT','WATTEXTASSYNC','WATEMAILPURGE');
	t_JobOwnerList := ObjList('ELNPROD','ELNPROD','NGSDMS60','NGSDMS60','NGSDMS60');
	v_ExpectedNo   := t_JobNameList.COUNT;

	SELECT COUNT(*) INTO v_Count FROM dba_scheduler_jobs WHERE job_name IN ('WATELNTEXTOPT','WATELNTEXTSYNC','WATTEXTASOPT','WATTEXTASSYNC','WATEMAILPURGE');
	IF (v_Count = v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('The expected number of NuGenesis background jobs are present in Oracle ('||v_ExpectedNo||' expected, '||v_Count||' found)');
	ELSIF (v_Count < v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: less than the expected number of NuGenesis background jobs are present in Oracle ('||v_ExpectedNo||' expected, '||v_Count||' found)!');
	END IF;

	FOR indx IN 1 .. t_JobNameList.COUNT
	LOOP
		v_JobName := t_JobNameList(indx);
		SELECT COUNT(*) INTO v_Count FROM dba_scheduler_jobs WHERE job_name = v_JobName;
		IF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: job '||v_JobName||' is not present!');
		ELSIF (v_Count = 1)	THEN
			DBMS_OUTPUT.PUT_LINE('Job '||v_JobName||' is present');
			SELECT owner, enabled, run_count, failure_count INTO v_JobOwner, v_enable, v_JobRunCount, v_fail FROM dba_scheduler_jobs WHERE job_name = v_JobName;
			IF (v_JobOwner = t_JobOwnerList(indx))	THEN	DBMS_OUTPUT.PUT_LINE('-- job owner: '||v_JobOwner||' (expected: '||t_JobOwnerList(indx)||').');
			ELSE						DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: job owner: '||v_JobOwner||' (expected: '||t_JobOwnerList(indx)||')!');
			END IF;

			IF (v_enable = 'TRUE')			THEN	DBMS_OUTPUT.PUT_LINE('-- Enabled: '||v_enable||' (expected: TRUE).');
			ELSE						DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: Enabled: '||v_enable||' (expected: TRUE)!');
			END IF;

			DBMS_OUTPUT.PUT_LINE('-- Run count : '||v_JobRunCount);
			DBMS_OUTPUT.PUT_LINE('-- Fail count: '||v_fail);
			IF (v_JobRunCount > 0)	THEN
				SELECT COUNT(*) INTO v_Count FROM dba_scheduler_job_run_details WHERE job_name = v_JobName AND log_id = (SELECT MAX(log_id) FROM dba_scheduler_job_run_details WHERE job_name = t_JobNameList(indx));
				IF (v_Count != 1)	THEN	DBMS_OUTPUT.PUT_LINE('-- Unable to retrieve status and date of this job''s most recent run.');
				ELSE
					SELECT status, log_date INTO v_JobRunStatus, v_JobMostRecentRunDate FROM dba_scheduler_job_run_details WHERE job_name = v_JobName AND log_id = (SELECT MAX(log_id) FROM dba_scheduler_job_run_details WHERE job_name = t_JobNameList(indx));
					DBMS_OUTPUT.PUT_LINE('-- Most recent run date     : '||v_JobMostRecentRunDate);
					DBMS_OUTPUT.PUT_LINE('-- Status of most recent run: '||v_JobRunStatus);
				END IF;
			END IF;
		ELSIF (v_Count > 1)	THEN
			DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: job '||v_JobName||' is present for multiple owners!  There should be only one copy of this job and it should be owned by '||t_JobOwnerList(indx)||'!  Drop all instances of this job except for the one owned by the expected owner!');
			OPEN C_MultipleJobs;
			LOOP
				FETCH C_MultipleJobs INTO v_JobOwner;
				EXIT WHEN C_MultipleJobs%NOTFOUND;

				DBMS_OUTPUT.PUT_LINE('-- '||v_JobOwner);
			END LOOP;
			CLOSE C_MultipleJobs;
		END IF;
	END LOOP;
END;
/

COLUMN COMMENTS		FORMAT A65
COLUMN OWNER		FORMAT A12
COLUMN PROGRAM_NAME	FORMAT A25
COLUMN REPEAT_INTERVAL	FORMAT A45
COLUMN END_DATE		FORMAT A15
COLUMN START_DATE	FORMAT A35
COLUMN NEXT_RUN_DATE	FORMAT A35
COLUMN NEXT_RUN_DATE	FORMAT A35
COLUMN job_name		FORMAT a30
COLUMN job_class	FORMAT a20
column additional_info	FORMAT A50
column status		FORMAT A10
COLUMN LOG_DATE		FORMAT A40

PROMPT
PROMPT SDMS/ELN JOB PROGRAMS IN THIS DATABASE INSTANCE:
SELECT OWNER, ENABLED, PROGRAM_NAME, COMMENTS FROM DBA_SCHEDULER_PROGRAMS WHERE OWNER IN ('NGSDMS60', 'NGSYSUSER', 'ELNPROD');

PROMPT
PROMPT SDMS/ELN JOB SCHEDULING INFORMATION THIS DATABASE INSTANCE:
SELECT OWNER, SCHEDULE_NAME, START_DATE, REPEAT_INTERVAL, END_DATE, COMMENTS FROM DBA_SCHEDULER_SCHEDULES WHERE OWNER IN ('NGSDMS60', 'NGSYSUSER',  'ELNPROD');

PROMPT
PROMPT SDMS/ELN JOB CURRENTLY SCHEDULED FOR THIS DATABASE INSTANCE:
SELECT OWNER, JOB_NAME, JOB_CLASS, ENABLED, NEXT_RUN_DATE FROM DBA_SCHEDULER_JOBS WHERE OWNER IN ('NGSDMS60', 'NGSYSUSER', 'ELNPROD');

PROMPT
PROMPT NuGenesis job schedules in this instance:
SELECT OWNER, JOB_NAME, JOB_CLASS, ENABLED, state, run_count, max_runs, failure_count, max_failures, next_run_date FROM dba_scheduler_jobs WHERE owner IN ('NGSDMS60','NGSYSUSER','ELNPROD');

PROMPT
PROMPT Details of the most recent NuGenesis job executions:
SELECT OWNER, JOB_NAME, STATUS, LOG_DATE, ADDITIONAL_INFO FROM  dba_scheduler_job_run_details WHERE LOG_DATE IN (SELECT MAX(LOG_DATE) FROM dba_scheduler_job_run_details WHERE OWNER IN ('NGSDMS60','NGSYSUSER','ELNPROD') GROUP BY JOB_NAME) ORDER BY OWNER, JOB_NAME;

PROMPT
PROMPT SUMMARY OF JOB ERROR INFORMATION:
SELECT JOB_NAME, ENABLED, RUN_COUNT, MAX_RUNS, FAILURE_COUNT, MAX_FAILURES FROM DBA_SCHEDULER_JOBS WHERE OWNER IN ('NGSDMS60', 'NGSYSUSER', 'ELNPROD') ORDER BY OWNER, JOB_NAME;

PROMPT
PROMPT Failed job details:
PROMPT IF MOST RECENT EXECUTION OF JOB WAS SUCCESSFUL THIS SECTION CAN BE IGNORED!
select 	LOG_DATE, owner, job_name, status, additional_info FROM dba_scheduler_job_run_details WHERE owner IN('NGSDMS60','NGSYSUSER','ELNPROD') AND STATUS != 'SUCCEEDED';

PROMPT
PROMPT ****************************************************************************************************************
PROMPT Verifying the NuGenesis Connectors 2.0 schema.
PROMPT The connectors are an optional component and may not be present in all NuGenesis databases.
PROMPT ****************************************************************************************************************
PROMPT

DECLARE
v_Count			PLS_INTEGER := 0;
v_ExpectedNo		PLS_INTEGER;
v_SchemaName		VARCHAR2(500) := 'ELNPROD';
v_ObjStatus		VARCHAR2(500);
TYPE ObjList		IS TABLE OF VARCHAR2(500);
v_ConnTableList		ObjList;
v_ConnProcList		ObjList;
v_ConnSeqList		ObjList;
v_ConnIndxList		ObjList;
v_ConnIndxTblList	ObjList;
t_ConnLists		ObjList;
t_ConnListValues	ObjList;
v_DBLinkName		dba_db_links.db_link%TYPE;
v_DBLinkUsername	dba_db_links.username%TYPE;
v_DBLinkHost		dba_db_links.host%TYPE;

CURSOR C_ElnprodDBLinks IS	SELECT db_link, username, host FROM dba_db_links WHERE owner = 'ELNPROD';

BEGIN
	v_ConnTableList := ObjList('CONNECTORS_SETTINGS','CONNECTORS_TARGET','CONNECTORS_SDMS','CONNECTORS_MAPPING','CONNECTORS_LIMSRESTRICTED','CONNECTORS_LIMSUNRESTRICTED','CONNECTORS_SDMSDELLIST','CONNECTORS_SDMSEXCLLIST','CONNECTORS_CONFIGURATION','CONNECTORS_PLUGINS');
	v_ExpectedNo    := v_ConnTableList.COUNT;
	DBMS_OUTPUT.PUT_LINE('.');
	DBMS_OUTPUT.PUT_LINE('Number of Connectors tables in the elnprod schema: '||:v_ConnTableCount);
	DBMS_OUTPUT.PUT_LINE('.');
	IF (:v_ConnTableCount = 0)	THEN	DBMS_OUTPUT.PUT_LINE('NuGenesis Connectors are not installed.');
	ELSIF (:v_ConnTableCount > 0)	THEN
		DBMS_OUTPUT.PUT_LINE('NuGenesis Connectors appears to be installed.  Determining whether all of the expected tables are present...');
 
		FOR indx IN 1 .. v_ConnTableList.COUNT
		LOOP
			SELECT COUNT(*) INTO v_Count FROM DBA_TABLES WHERE OWNER = v_SchemaName AND TABLE_NAME = v_ConnTableList(indx);
			IF (v_Count > 0)	THEN	DBMS_OUTPUT.PUT_LINE('-- Table '||v_ConnTableList(indx)||' is present');
			ELSE				DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: Table '||v_ConnTableList(indx)||' is NOT present!');
			END IF;

			SELECT COUNT(*) INTO v_Count FROM DBA_TABLES WHERE OWNER = v_SchemaName AND TABLE_NAME = v_ConnTableList(indx) || 'A0';
			IF (v_Count > 0)	THEN	DBMS_OUTPUT.PUT_LINE('-- Table '||v_ConnTableList(indx)||'A0 is present');
			ELSE				DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: Table '||v_ConnTableList(indx)||'A0 is NOT present!');
			END IF;
			DBMS_OUTPUT.PUT_LINE('.');
		END LOOP;

		v_ConnProcList := ObjList('P_CONNECTORS_UPDATESETTINGS');
		v_ExpectedNo   := v_ConnProcList.COUNT;

		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('Determining whether all of the expected procedures are present...');

		FOR indx IN 1 .. v_ConnProcList.COUNT
		LOOP
			SELECT COUNT(*) INTO v_Count FROM DBA_OBJECTS WHERE OWNER = v_SchemaName AND OBJECT_NAME = v_ConnProcList(indx) AND OBJECT_TYPE = 'PROCEDURE';
			IF v_Count > 0 THEN
				DBMS_OUTPUT.PUT_LINE('-- Procedure '||v_ConnProcList(indx)||' is present');
				SELECT STATUS INTO v_ObjStatus FROM DBA_OBJECTS WHERE OWNER = v_SchemaName AND OBJECT_NAME = v_ConnProcList(indx);
				IF v_ObjStatus = 'VALID' THEN	DBMS_OUTPUT.PUT_LINE('-- Procedure '||v_ConnProcList(indx)||' has a status of valid');
				ELSE				DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: procedure '||v_ConnProcList(indx)||' has a status of:  '||v_ObjStatus);
				END IF;
			ELSE				 	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: procedure '||v_ConnProcList(indx) || ' is NOT present!');
			END IF;
		END LOOP;

		v_ConnSeqList := ObjList('NGC_MAPPING_SEQ','NGC_LIMS_SEQ');
		v_ExpectedNo  := v_ConnSeqList.COUNT;

		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('Determining whether all of the expected sequences are present...');

		FOR indx IN 1 .. v_ConnSeqList.COUNT
		LOOP
			SELECT COUNT(*) INTO v_Count FROM DBA_SEQUENCES WHERE SEQUENCE_OWNER = v_SchemaName AND SEQUENCE_NAME = v_ConnSeqList(indx);
			IF v_Count = 1		THEN	DBMS_OUTPUT.PUT_LINE('-- Sequence '||v_ConnSeqList(indx)||' is present');
			ELSIF v_Count = 0	THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: Sequence '||v_ConnSeqList(indx)||' is NOT present!');
			END IF;
		END LOOP;

		v_ConnIndxList    := ObjList('XPKCONNECTORS_SETTINGS','XPKCONNECTORS_TARGET','XPKCONNECTORS_SDMS','XPKCONNECTORS_LIMSRESTRICTED','XPKCONNECTORS_SDMSDELLIST','XPKCONNECTORS_CONFIGURATION','I_CONNECTORS_CONFIGURATION');
		v_ConnIndxTblList := ObjList('CONNECTORS_SETTINGS','CONNECTORS_TARGET','CONNECTORS_SDMS','CONNECTORS_LIMSRESTRICTED','CONNECTORS_SDMSDELLIST','CONNECTORS_CONFIGURATION','CONNECTORS_CONFIGURATION');
		v_ExpectedNo      := v_ConnIndxList.COUNT;

		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('Determining whether all of the expected indexes are present...');

		FOR indx IN 1 .. v_ConnIndxList.COUNT
		LOOP
			SELECT COUNT(*) INTO v_Count FROM DBA_indexes WHERE OWNER = v_SchemaName AND index_name = v_ConnIndxList(indx) AND table_name = v_ConnIndxTblList(indx);
			IF v_Count = 1		THEN	DBMS_OUTPUT.PUT_LINE('-- Index '||v_ConnIndxList(indx)||' on table '||v_SchemaName||'.'||v_ConnIndxTblList(indx)||' is present');
			ELSIF v_Count = 0	THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: Index '||v_ConnIndxList(indx)||' on table '||v_SchemaName||'.'||v_ConnIndxTblList(indx)||' is NOT present!');
			END IF;
		END LOOP;

		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('Verifying schema changes per NGConnectors_Schema_Addon.sql...');

		SELECT COUNT(*) INTO v_Count FROM DBA_TAB_COLUMNS WHERE OWNER = 'ELNPROD' AND TABLE_NAME = 'CONNECTORS_CONFIGURATION' AND COLUMN_NAME = 'EXTRACTION_TEMPLATE'; 
		IF v_Count > 0		THEN	DBMS_OUTPUT.PUT_LINE('Extraction_template column added to elnprod.connectors_configuration');
		ELSIF v_Count = 0	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: extraction_template column not added to  elnprod.connectors_configuration!');
		END IF;

		SELECT COUNT(*) INTO v_Count FROM DBA_TAB_COLUMNS WHERE OWNER = 'ELNPROD' AND TABLE_NAME = 'CONNECTORS_CONFIGURATIONA0' AND COLUMN_NAME = 'EXTRACTION_TEMPLATE'; 
		IF v_Count > 0		THEN	DBMS_OUTPUT.PUT_LINE('Extraction_template column added to elnprod.connectors_configurationa0');
		ELSIF v_Count = 0	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: extraction_template column not added to  elnprod.connectors_configurationa0!');
		END IF;

		DBMS_OUTPUT.PUT_LINE('.');

		SELECT COUNT(*) INTO v_Count FROM DBA_TAB_COLUMNS WHERE OWNER = 'ELNPROD' AND TABLE_NAME = 'CONNECTORS_CONFIGURATION' AND COLUMN_NAME = 'PROJECT';
		IF v_Count > 0		THEN	DBMS_OUTPUT.PUT_LINE('Project column added to elnprod.connectors_configuration');
		ELSIF v_Count = 0	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: project column not added to elnprod.connectors_configuration!');
		END IF;

		SELECT COUNT(*) INTO v_Count FROM DBA_TAB_COLUMNS WHERE OWNER = 'ELNPROD' AND TABLE_NAME = 'CONNECTORS_CONFIGURATIONA0' AND COLUMN_NAME = 'PROJECT';
		IF v_Count > 0		THEN	DBMS_OUTPUT.PUT_LINE('Project column added to elnprod.connectors_configurationa0');
		ELSIF v_Count = 0	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: project column not added to elnprod.connectors_configurationa0!');
		END IF;

		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('Verifying schema changes per NGConnectors_ELNActback.sql...');

		SELECT COUNT(ROWID) INTO v_Count FROM ELNPROD.JOBTYPES  WHERE JOBCATEGORY = 'CONNECTORS' AND JOBTYPE = 'PROCESS_INCOMING';
		IF v_Count > 0		THEN	DBMS_OUTPUT.PUT_LINE('Insert into jobtypes for jobcategory = connectors and jobtype = process_incoming made');
		ELSIF v_Count = 0	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: insert into jobtypes for jobcategory = connectors and jobtype = process_incoming not made');
		END IF;

		DBMS_OUTPUT.PUT_LINE('.');

		SELECT COUNT(ROWID) INTO v_Count FROM ELNPROD.JOBSCHEDULE  WHERE JOBCATEGORY = 'CONNECTORS' AND JOBTYPE = 'PROCESS_INCOMING';
		IF v_Count > 0		THEN	DBMS_OUTPUT.PUT_LINE('Insert into jobschedule for jobcategory = connectors and jobtype = process_incoming made');
		ELSIF v_Count = 0	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: insert into jobschedule for jobcategory = connectors and jobtype = process_incoming not made');
		END IF;

		DBMS_OUTPUT.PUT_LINE('.');

		SELECT COUNT(ROWID) INTO v_Count FROM ELNPROD.JOBTYPES  WHERE JOBCATEGORY = 'CONNECTORS' AND JOBTYPE = 'PROCESS_OUTGOING';
		IF v_Count > 0		THEN	DBMS_OUTPUT.PUT_LINE('Insert into jobtypes for jobcategory = connectors and jobtype = process_incoming made');
		ELSIF v_Count = 0	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: insert into jobtypes for jobcategory = connectors and jobtype = process_incoming not made');
		END IF;

		DBMS_OUTPUT.PUT_LINE('.');

		SELECT COUNT(ROWID) INTO v_Count FROM ELNPROD.JOBSCHEDULE  WHERE JOBCATEGORY = 'CONNECTORS' AND JOBTYPE = 'PROCESS_OUTGOING';
		IF v_Count > 0		THEN	DBMS_OUTPUT.PUT_LINE('Insert into jobschedule for jobcategory = connectors and jobtype = process_incoming made');
		ELSIF v_Count = 0	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: insert into jobschedule for jobcategory = connectors and jobtype = process_incoming not made');
		END IF;

		DBMS_OUTPUT.PUT_LINE('.');

		SELECT COUNT(ROWID) INTO v_Count FROM ELNPROD.JOBTYPES  WHERE JOBCATEGORY = 'CONNECTORS' AND JOBTYPE = 'CLEAN_UP_IH';
		IF v_Count > 0		THEN	DBMS_OUTPUT.PUT_LINE('Insert into jobtypes for jobcategory = connectors and jobtype = process_outgoing made');
		ELSIF v_Count = 0	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: insert into jobtypes for jobcategory = connectors and jobtype = process_outgoing not made');
		END IF;

		DBMS_OUTPUT.PUT_LINE('.');

		SELECT COUNT(ROWID) INTO v_Count FROM ELNPROD.JOBSCHEDULE  WHERE JOBCATEGORY = 'CONNECTORS' AND JOBTYPE = 'CLEAN_UP_IH';
		IF v_Count > 0		THEN	DBMS_OUTPUT.PUT_LINE('Insert into jobschedule for jobcategory = connectors and jobtype = clean_up_ih made');
		ELSIF v_Count = 0	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: insert into jobschedule for jobcategory = connectors and jobtype = clean_up_ih not made');
		END IF;

		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('Verifying schema changes per NGConnectors_Grants.sql...');

		SELECT COUNT(*) INTO v_Count FROM DBA_TAB_PRIVS WHERE GRANTEE = 'ELNPROD' AND OWNER = 'NGSYSUSER' AND TABLE_NAME = 'NGUSERS' AND PRIVILEGE = 'SELECT';
		IF v_Count > 0		THEN	DBMS_OUTPUT.PUT_LINE('Elnprod has been granted select on ngsysuser.ngusers');
		ELSE				DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: Elnprod has NOT been granted select on ngsysuser.ngusers!');
		END IF;

		SELECT COUNT(*) INTO v_Count FROM DBA_TAB_PRIVS WHERE GRANTEE = 'ELNPROD' AND OWNER = 'NGSYSUSER' AND TABLE_NAME = 'NGUSERSAUTHMODE' AND PRIVILEGE = 'SELECT';
		IF v_Count > 0		THEN	DBMS_OUTPUT.PUT_LINE('Elnprod has been granted select on ngsysuser.ngusersauthmode');
		ELSE				DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: Elnprod has NOT been granted select on ngsysuser.ngusersauthmode!');
		END IF;

		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('Determining whether ELNPROD owns any dblinks (1 or more expected for a congfigured Connectors install)...');
		SELECT COUNT(*) INTO v_Count FROM dba_db_links WHERE owner = 'ELNPROD';
		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('ELNPROD owns '||v_Count||' db link(s):');
		IF v_Count > 0		THEN
			OPEN C_ElnprodDBLinks;
			LOOP
				FETCH C_ElnprodDBLinks INTO v_DBLinkName, v_DBLinkUsername, v_DBLinkHost;
				EXIT WHEN C_ElnprodDBLinks%NOTFOUND;

				DBMS_OUTPUT.PUT_LINE('-- Link name: '||v_DBLinkName||'	user: '||v_DBLinkUsername||'	host: '||v_DBLinkHost);
			END LOOP;
			CLOSE C_ElnprodDBLinks;
		END IF;

		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('Determining whether the expected user account and department for Connectors are present in LMS...');
		SELECT COUNT(*) INTO v_Count FROM elnprod.labgroup WHERE labgrpshorttext = 'Connectors';
		IF	(v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('The department ''Connectors'' is present');
		ELSIF	(v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('!!! WARNING: the department ''Connectors'' is NOT present');
		END IF;

		SELECT COUNT(*) INTO v_Count FROM elnprod.employee WHERE empid = 'ConnectorsAdmin';
		IF	(v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('The user account ''ConnectorsAdmin'' is present');
		ELSIF	(v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('!!! WARNING: the user account ''ConnectorsAdmin'' is NOT present');
		END IF;

		SELECT COUNT(*) INTO v_Count FROM elnprod.labgroupemployee WHERE empid = 'ConnectorsAdmin' AND labgrpid = (SELECT labgrpid FROM elnprod.labgroup WHERE labgrpshorttext = 'Connectors');
		IF	(v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('The user account ''ConnectorsAdmin'' has been added to the ''Conectors'' department');
		ELSIF	(v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('!!! WARNING: the user account ''ConnectorsAdmin'' has NOT been added to the ''Connectors'' department');
		END IF;

		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('Determining whether the expected lists and list entries for Connectors are present in LMS...');
		t_ConnLists := ObjList('LIMS Category','LIMS Calculation','LIMS Component','LIMS Department','LIMS ResultList','LIMS ResultTypes','LIMS Trusted System','LIMS Units','LIMS Upload','LIMS User','CON_Worklist');
		FOR indx IN 1 .. t_ConnLists.COUNT
		LOOP
			SELECT COUNT(*) INTO v_Count FROM elnprod.domain WHERE domainid = t_ConnLists(indx);
			IF	(v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('The list '||t_ConnLists(indx)||' is present');
			ELSIF	(v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: the list '||t_ConnLists(indx)||' is NOT present');
			END IF;
		END LOOP;

		DBMS_OUTPUT.PUT_LINE('.');

		t_ConnLists      := ObjList('CON_Worklist',           'CON_Worklist',         'CON_Worklist',      'CON_Worklist',       'LIMS Calculation','LIMS Calculation','LIMS Calculation','LIMS Calculation','LIMS Calculation',   'LIMS Calculation','LIMS Calculation','LIMS Category','LIMS Component','LIMS Component',   'LIMS Component','LIMS Component',     'LIMS Department','LIMS ResultTypes','LIMS ResultTypes','LIMS ResultTypes','LIMS ResultTypes','LIMS ResultTypes','LIMS ResultTypes','LIMS ResultTypes','LIMS ResultTypes','LIMS Trusted System','LIMS Units','LIMS Upload','LIMS Upload','LIMS User');
		t_ConnListValues := ObjList('Automation Marker Field','Result Workflow Field','Solvent_Identifier','Standard_Identifier','Average',         'Count',           'Custom',          'Maximum',         'RelativeStandardDev','StandardDev',     'Sumary',          'DEFAULT',      'Aspirin',       'Aspirin Aspirin-1','Caffeine',      'Caffeine Caffeine-2','DEFAULT',        'D',               'FREETEXT',        'FREETEXTLIST',    'L',               'LIST',            'N',               'NUMERIC',         'T',               'LABWARE08',          'PERCENT',   'DEFAULT',    'QC',         'DEFAULT');
		FOR indx IN 1 .. t_ConnListValues.COUNT
		LOOP
			SELECT COUNT(*) INTO v_Count FROM elnprod.domainvalue WHERE domainid = t_ConnLists(indx) AND value = t_ConnListValues(indx);
			IF	(v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('The list value '||t_ConnLists(indx)||'.'||t_ConnListValues(indx)||' is present');
			ELSIF	(v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: the list value '||t_ConnLists(indx)||'.'||t_ConnListValues(indx)||' is NOT present');
			END IF;
		END LOOP;
	END IF;
END;
/

PROMPT
PROMPT ****************************************************************************************************************
PROMPT Verifying the NuGenesis LMS-SAP Interface 2.0.x schema.
PROMPT This interface is an optional component and may not be present in all NuGenesis databases.
PROMPT DB00001.sql, DB00002.sql
PROMPT ****************************************************************************************************************
PROMPT

DECLARE
v_Count			PLS_INTEGER := 0;
v_ExpectedNo		PLS_INTEGER;
v_SchemaName		VARCHAR2(500) := 'ELNPROD';
v_ObjStatus		VARCHAR2(500);
v_TableName		VARCHAR2(500);
v_IndexName		VARCHAR2(500);
v_JobType		elnprod.jobtypes.jobtype%TYPE;
v_JobCategory		elnprod.jobtypes.jobcategory%TYPE;
TYPE ObjList		IS TABLE OF VARCHAR2(500);
t_TableList		ObjList;
t_IndxList		ObjList;
t_IndxTblList		ObjList;
t_ViewList		ObjList;
t_JobTypeList		ObjList;
t_JobCategoryList	ObjList;

BEGIN
	t_TableList   := ObjList('IF_TESTRESULT','IF_TESTRESULTA0','IF_TESTRESULTATTRIBUTE','IF_TESTRESULTATTRIBUTEA0');
	t_IndxList    := ObjList('XPKIF_TESTRESULT','XPKIF_TESTRESULTATTRIBUTE','IF_TESTRESULTATTRIBUTE_IND1');
	t_IndxTblList := ObjList('IF_TESTRESULT',   'IF_TESTRESULTATTRIBUTE',   'IF_TESTRESULTATTRIBUTE');
	t_ViewList    := ObjList('ELN_TEMPLATE_DEFINITION');

	t_JobTypeList     := ObjList('VPRETRIEVAL',         'VPUPLOAD',          'RESULTPREPROCESSING');
	t_JobCategoryList := ObjList('SAPINTERFACEDOWNLOAD','SAPINTERFACEUPLOAD','SAPPREPROCESS');

	v_ExpectedNo    := t_TableList.COUNT;
	DBMS_OUTPUT.PUT_LINE('.');
	DBMS_OUTPUT.PUT_LINE('Number of LMS-SAP Interface tables in the elnprod schema: '||:v_SAPTableCount);
	DBMS_OUTPUT.PUT_LINE('.');
	IF (:v_SAPTableCount = 0)	THEN	DBMS_OUTPUT.PUT_LINE('The LMS-SAP Interface is not installed.');
	ELSIF (:v_SAPTableCount > 0)	THEN
		DBMS_OUTPUT.PUT_LINE('The SAP Interface appears to be installed.  Determining whether all of the expected tables are present...');
 
		FOR indx IN 1 .. t_TableList.COUNT
		LOOP
			v_TableName := t_TableList(indx);
			SELECT COUNT(*) INTO v_Count FROM DBA_TABLES WHERE OWNER = v_SchemaName AND table_name = v_TableName;
			IF (v_Count > 0)	THEN	DBMS_OUTPUT.PUT_LINE('-- Table '||v_TableName||' is present');
			ELSE				DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: table '||v_TableName||' is NOT present!');
			END IF;

			DBMS_OUTPUT.PUT_LINE('.');
		END LOOP;

		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('Determining whether all of the expected indexes are present...');

		v_ExpectedNo := t_IndxList.COUNT;
		SELECT COUNT(*) INTO v_Count FROM dba_indexes WHERE owner = v_SchemaName AND index_name LIKE '%IF_%';
		IF (v_Count = v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('The expected number of indexes are present ('||v_ExpectedNo||' expected, '||v_Count||' found)');
		ELSIF (v_Count < v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: less than the expected number of indexes are present ('||v_ExpectedNo||' expected, '||v_Count||' found)!');
		ELSIF (v_Count > v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('More than the expected number of indexes are present ('||v_ExpectedNo||' expected, '||v_Count||' found)');
		END IF;

		FOR indx IN 1 .. t_IndxList.COUNT
		LOOP
			v_IndexName := t_IndxList(indx);
			v_TableName := t_IndxTblList(indx);
			SELECT COUNT(*) INTO v_Count FROM DBA_indexes WHERE OWNER = v_SchemaName AND index_name = v_IndexName AND table_name = v_TableName;
			IF (v_Count = 1)		THEN	DBMS_OUTPUT.PUT_LINE('-- Index '||v_IndexName||' on table '||v_SchemaName||'.'||v_TableName||' is present');
			ELSIF v_Count = 0	THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: Index '||v_IndexName||' on table '||v_SchemaName||'.'||v_TableName||' is NOT present!');
			END IF;
		END LOOP;

		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('Determining whether all of the expected views are present...');

		v_ExpectedNo := t_ViewList.COUNT;
		SELECT COUNT(*) INTO v_Count FROM dba_views WHERE owner = v_SchemaName AND view_name = 'ELN_TEMPLATE_DEFINITION';
		IF (v_Count = v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('The expected number of views are present ('||v_ExpectedNo||' expected, '||v_Count||' found)');
		ELSIF (v_Count < v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: less than the expected number of views are present ('||v_ExpectedNo||' expected, '||v_Count||' found)!');
		ELSIF (v_Count > v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('More than the expected number of views are present ('||v_ExpectedNo||' expected, '||v_Count||' found)');
		END IF;

		FOR indx IN 1 .. t_ViewList.COUNT
		LOOP
			v_TableName := t_ViewList(indx);
			SELECT COUNT(*) INTO v_Count FROM DBA_views WHERE OWNER = v_SchemaName AND view_name = v_TableName;
			IF (v_Count = 1)		THEN	DBMS_OUTPUT.PUT_LINE('-- View '||v_SchemaName||'.'||v_TableName||' is present');
			ELSIF v_Count = 0	THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: View '||v_SchemaName||'.'||v_TableName||' is NOT present!');
			END IF;
		END LOOP;

		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('Determining whether all of the expected LMS background jobs are present...');

		v_ExpectedNo := t_JobTypeList.COUNT;
		SELECT COUNT(*) INTO v_Count FROM elnprod.jobtypes WHERE jobcategory like 'SAP%';
		IF (v_Count = v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('The expected number of LMS jobs are present ('||v_ExpectedNo||' expected, '||v_Count||' found)');
		ELSIF (v_Count < v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: less than the expected number of LMS jobs are present ('||v_ExpectedNo||' expected, '||v_Count||' found)!');
		ELSIF (v_Count > v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('More than the expected number of LMS jobs are present ('||v_ExpectedNo||' expected, '||v_Count||' found)');
		END IF;

		FOR indx IN 1 .. t_JobTypeList.COUNT
		LOOP
			v_JobType := t_JobTypeList(indx);
			v_JobCategory := t_JobCategoryList(indx);
			SELECT COUNT(*) INTO v_Count FROM elnprod.jobtypes WHERE jobcategory = v_JobCategory AND jobtype = v_JobType;
			IF (v_Count = 1)		THEN	DBMS_OUTPUT.PUT_LINE('-- Job '||v_JobCategory||'.'||v_JobType||' is present in elnprod.jobtypes');
			ELSIF v_Count = 0	THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: Job '||v_JobCategory||'.'||v_JobType||' is NOT present in elnprod.jobtypes!');
			END IF;

			SELECT COUNT(*) INTO v_Count FROM elnprod.jobschedule WHERE jobcategory = v_JobCategory AND jobtype = v_JobType;
			IF (v_Count = 1)		THEN	DBMS_OUTPUT.PUT_LINE('-- Job '||v_JobCategory||'.'||v_JobType||' is present in elnprod.jobschedule');
			ELSIF v_Count = 0	THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: Job '||v_JobCategory||'.'||v_JobType||' is NOT present in elnprod.jobschedule!');
			END IF;
		END LOOP;
	END IF;
END;
/

PROMPT
PROMPT ****************************************************************************************************************
PROMPT Verifying the NuGenesis application configurations...
PROMPT ****************************************************************************************************************
PROMPT

PROMPT
PROMPT
PROMPT ______________________________________________________________________________________
PROMPT Determining the authentication methods and LDAP parameters for the NuGenesis applications...
PROMPT
DECLARE
v_Count		PLS_INTEGER;
v_type	 	VARCHAR2(255);
v_host	 	VARCHAR2(255);
v_ssl		VARCHAR2(255);
v_attrib	VARCHAR2(255);
v_dn		VARCHAR2(255);
v_usr		VARCHAR2(255);
v_authld	VARCHAR2(255);
v_authdb	VARCHAR2(255);
v_LMSLDAPSwitch	INTEGER;
v_port		VARCHAR2(222);
CURSOR C_LDAPHOSTLIST IS SELECT DISTINCT(NGKEYVALUE) FROM NGSYSUSER.NGCONFIG WHERE NGSECTION = 'LDAPSERVERCFG' AND NGKEYID LIKE 'ldapHostName%';

BEGIN
	SELECT COUNT(*) INTO v_Count FROM ngsysuser.ngconfig WHERE ngsection = 'NGAUTHCFG';
	IF	(v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('SDMS LDAP authentication parameters are not present.');
	ELSE
		SELECT NGKEYVALUE INTO v_authld FROM NGSYSUSER.NGCONFIG WHERE NGSECTION = 'NGAUTHCFG' AND NGKEYID = 'authLDAP';
		IF v_authld = '0'	THEN	DBMS_OUTPUT.PUT_LINE('SDMS LDAP authentication is disabled.');
		ELSIF v_authld = '1'	THEN	DBMS_OUTPUT.PUT_LINE('SDMS LDAP authentication is enabled.');
		ELSE				DBMS_OUTPUT.PUT_LINE('Unknown value for SDMS LDAP authentication: '||v_authld);
		END IF;

		SELECT NGKEYVALUE INTO v_authdb FROM NGSYSUSER.NGCONFIG WHERE NGSECTION = 'NGAUTHCFG' AND NGKEYID = 'authDatabase';
		IF v_authdb = '0'	THEN	DBMS_OUTPUT.PUT_LINE('SDMS Oracle authentication is disabled.');
		ELSIF v_authdb = '1'	THEN	DBMS_OUTPUT.PUT_LINE('SDMS Oracle authentication is enabled.');
		ELSE				DBMS_OUTPUT.PUT_LINE('Unknown value for SDMS Oracle authentication: '||v_authdb);
		END IF;

		-- SDMS LDAP config

		IF v_authld = '1' THEN
			DBMS_OUTPUT.PUT_LINE('.');
			DBMS_OUTPUT.PUT_LINE('LDAP authentication is enabled in SDMS.  Checking whether LDAP has been correctly configured...');

			SELECT NGKEYVALUE INTO v_ssl FROM NGSYSUSER.NGCONFIG WHERE NGSECTION = 'LDAPSERVERCFG' AND NGKEYID = 'ldapUseSSL';
			IF v_ssl = '1'		THEN	DBMS_OUTPUT.PUT_LINE('-- LDAP session encryption is enabled');
			ELSIF v_ssl = '0'	THEN	DBMS_OUTPUT.PUT_LINE('-- LDAP session encryption is not enabled');
			END IF;
	
			SELECT NGKEYVALUE INTO v_type FROM NGSYSUSER.NGCONFIG WHERE NGSECTION = 'LDAPSERVERCFG' AND NGKEYID = 'ldapServerType';
			DBMS_OUTPUT.PUT_LINE('-- Server type: '||v_type);
			IF v_type IS NULL	THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: the ldap server type has not been specified in SDMS!');
			END IF;
	
			SELECT NGKEYVALUE INTO v_attrib FROM NGSYSUSER.NGCONFIG WHERE NGSECTION = 'LDAPSERVERCFG' AND NGKEYID = 'authAttribName';
			SELECT NGKEYVALUE INTO v_dn FROM NGSYSUSER.NGCONFIG WHERE NGSECTION = 'LDAPSERVERCFG' AND NGKEYID = 'authBaseDN';
			DBMS_OUTPUT.PUT_LINE('-- Naming attribute: '||v_attrib);
			DBMS_OUTPUT.PUT_LINE('-- Base DN: '||v_dn);
	
			SELECT NGKEYVALUE INTO v_usr FROM NGSYSUSER.NGCONFIG WHERE NGSECTION = 'LDAPSERVERCFG' AND NGKEYID = 'ldapSearchUser';
			DBMS_OUTPUT.PUT_LINE('-- Bind user: '||v_usr);
			IF v_usr IS NULL	THEN	DBMS_OUTPUT.PUT_LINE('!!! WARNING: there is no sdms ldap search user configured! this will cause sdms to use anonymous access to the ldap server!');
			END IF;
	
			SELECT COUNT(NGKEYVALUE) INTO v_Count FROM NGSYSUSER.NGCONFIG WHERE NGSECTION = 'LDAPSERVERCFG' AND NGKEYID LIKE 'ldapHostName%';
			IF v_Count = 0		THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: no LDAP hosts have been specified in SDMS!  Users will not be able to log in to SDMS With LDAP credentials until at least one LDAP host is specified!');
			ELSE
				DBMS_OUTPUT.PUT_LINE('LDAP host servers specified:');
				OPEN C_LDAPHOSTLIST;
				LOOP
					FETCH C_LDAPHOSTLIST INTO v_host;
					EXIT WHEN C_LDAPHOSTLIST%NOTFOUND;
	
					DBMS_OUTPUT.PUT_LINE('-- '||v_host);
				END LOOP;
				CLOSE C_LDAPHOSTLIST;
			END IF;
		END IF;
	END IF;

	DBMS_OUTPUT.PUT_LINE('.');
	DBMS_OUTPUT.PUT_LINE('.');

	SELECT intvalue INTO v_LMSLDAPSwitch FROM elnprod.systemvalues WHERE systemtypeid = 'SECURITY' AND valuecode = 'PWSECURITY';
	IF v_LMSLDAPSwitch = 1 THEN	DBMS_OUTPUT.PUT_LINE('LMS LDAP authentication is enabled.');
	ELSIF v_LMSLDAPSwitch = 0 THEN	DBMS_OUTPUT.PUT_LINE('LMS LDAP authentication is disabled.');
	ELSE				DBMS_OUTPUT.PUT_LINE('Unknown value for the LMS LDAP switch: '||v_LMSLDAPSwitch);
	END IF;

	-- LMS LDAP config

	IF v_LMSLDAPSwitch = 1 THEN
		SELECT longalphavalue INTO v_host FROM elnprod.systemvalues WHERE systemtypeid = 'LDAPSERVER' AND valuecode = 'SERVER';
		SELECT longalphavalue INTO v_Port FROM elnprod.systemvalues WHERE systemtypeid = 'LDAPSERVER' AND valuecode = 'PORT';
		DBMS_OUTPUT.PUT_LINE('-- LDAP Server URL and Port: '||v_host||':'||v_Port);
		IF v_host IS NULL	THEN	DBMS_OUTPUT.PUT_LINE('!!! WARNING: The LDAP Server URL has not been specified !');
		END IF;

		IF v_Port IS NULL	THEN	DBMS_OUTPUT.PUT_LINE('!!! WARNING: The LDAP Server Port has not been specified !');
		END IF;
	
		SELECT longalphavalue INTO v_dn FROM elnprod.systemvalues WHERE systemtypeid = 'LDAPSERVER' AND valuecode IN ('SEARCHDN','BASEDN'); -- BASEDN was renamed to SEARCHDN in v9.2.
		DBMS_OUTPUT.PUT_LINE('-- Base DN: '||v_dn);
		IF v_dn IS NULL		THEN	DBMS_OUTPUT.PUT_LINE('!!! WARNING: The LDAP Base DN has not been specified !');
		END IF;
	
		SELECT longalphavalue INTO v_usr FROM elnprod.systemvalues WHERE systemtypeid = 'LDAPSERVER' AND valuecode = 'BINDUSER';
		DBMS_OUTPUT.PUT_LINE('-- Bind user: '||v_usr);
		IF v_usr IS NULL 	THEN	DBMS_OUTPUT.PUT_LINE('!!! WARNING: there is no search user configured!  This will cause LMS to use anonymous access to the ldap server!');
		END IF;
	
		SELECT longalphavalue INTO v_Attrib FROM elnprod.systemvalues WHERE systemtypeid = 'LDAPSERVER' AND valuecode IN ('AUTHATTRIBUTE','LDAPFILTER'); -- LDAPFILTER was renamed to AUTHATTRIBUTE in v9.2.
		DBMS_OUTPUT.PUT_LINE('-- Naming Attribute: '||v_Attrib);
		IF v_Attrib IS NULL	THEN	DBMS_OUTPUT.PUT_LINE('!!! WARNING: The LDAP Naming Attribute has not been specified !');
		END IF;
	
		SELECT longalphavalue INTO v_host FROM elnprod.systemvalues WHERE systemtypeid = 'LDAPSERVER' AND valuecode = 'BKSERVER';
		SELECT longalphavalue INTO v_Port FROM elnprod.systemvalues WHERE systemtypeid = 'LDAPSERVER' AND valuecode = 'BKPORT';
		DBMS_OUTPUT.PUT_LINE('-- Backup Server URL: '||v_host||' ; Port: '||v_Port);
	END IF;
END;
/

PROMPT
PROMPT
PROMPT ______________________________________________________________________________________
PROMPT SDMS schema configuration information
PROMPT
DECLARE
v_ngkeyid	VARCHAR2(255);
v_ngkeyvalue 	VARCHAR2(255);
v_cnt		NUMBER;
v_value		VARCHAR2(120);
v_Count		PLS_INTEGER;
v_viewid	NUMBER;
v_ngidmx	NUMBER;
v_ngidlst	NUMBER;
v_DBLinkHost	dba_db_links.host%TYPE;

CURSOR C_NGCONFIG IS SELECT NGKEYID, NGKEYVALUE FROM NGSYSUSER.NGCONFIG;

BEGIN

	SELECT COUNT(*) INTO v_Count FROM NGSYSUSER.NGSCHEMAINSTALLEDINFO;
	DBMS_OUTPUT.PUT_LINE (v_count||' rows exist in the ngsysuser.ngschemainstalledinfo table');

	OPEN C_NGCONFIG;
	LOOP
		FETCH C_NGCONFIG INTO v_ngkeyid, v_ngkeyvalue;
		EXIT WHEN C_NGCONFIG%NOTFOUND;

		IF v_ngkeyid = 'NgZztrqW0O_19121001_lkjsdkiepwq' THEN
			IF v_ngkeyvalue != 'BcVt67@9oYTbVx_291210O1_zYuI<8>'	THEN	DBMS_OUTPUT.PUT_LINE('The electronic signatures option has NOT been installed.');
			ELSIF v_ngkeyvalue = 'BcVt67@9oYTbVx_291210O1_zYuI<8>'  THEN	DBMS_OUTPUT.PUT_LINE('The electronic signatures option has been installed.');
			END IF;
		ELSIF v_ngkeyid = '19121002' THEN
			IF v_ngkeyvalue = '92121002_SYG'				THEN	DBMS_OUTPUT.PUT_LINE('The audit trail option has NOT been installed.');
			ELSIF v_ngkeyvalue = '29121002_SYG'				THEN	DBMS_OUTPUT.PUT_LINE('The audit trail option has been installed.');
			ELSIF v_ngkeyvalue NOT IN ('29121002_SYG', '92121002_SYG')	THEN	DBMS_OUTPUT.PUT_LINE('!!! WARNING: the audit trail option has been improperly configured. The ngkeyvalue is: '||v_ngkeyvalue);
			END IF;
		ELSIF v_ngkeyid = '19121003' THEN
			IF v_ngkeyvalue = '92121003_AAD'				THEN	DBMS_OUTPUT.PUT_LINE('The reason for change option has NOT been installed.');
			ELSIF v_ngkeyvalue = '29121003_AAD'				THEN	DBMS_OUTPUT.PUT_LINE('The reason for change option has been installed.');
			ELSIF v_ngkeyvalue NOT IN ('29121003_AAD', '92121003_AAD')	THEN	DBMS_OUTPUT.PUT_LINE('!!! WARNING: the reason for change option has been improperly configured. The ngkeyvalue is: '||v_ngkeyvalue);
			END IF;
		ELSIF v_ngkeyid = '191210031' THEN
			IF v_ngkeyvalue IN ('29121003','2912100')				THEN	DBMS_OUTPUT.PUT_LINE('The secondary authentication option has NOT been installed.');
			ELSIF v_ngkeyvalue = '291210031_2ND_AAD'				THEN	DBMS_OUTPUT.PUT_LINE('The secondary authentication has been installed.');
			ELSIF v_ngkeyvalue NOT IN ('291210031_2ND_AAD','29121003','2912100')	THEN	DBMS_OUTPUT.PUT_LINE('!!! WARNING: the secondary authentication option has been improperly configured. The ngkeyvalue is: '||v_ngkeyvalue);
			END IF;
		ELSIF v_ngkeyid = '19121007' THEN
			DBMS_OUTPUT.PUT_LINE('The Time Zone Configured in SDMS is:  '||v_ngkeyvalue);
		ELSIF v_ngkeyid = '19121006' THEN
			DBMS_OUTPUT.PUT_LINE('THE GMT Offset Configured in SDMS is:  '||v_ngkeyvalue);
		ELSIF v_ngkeyid = '19121011' THEN
			IF v_ngkeyvalue = '20060825_1964_JP'					THEN	DBMS_OUTPUT.PUT_LINE('Audit report access is not enabled');
			ELSIF v_ngkeyvalue = '60200825_1964_JP'					THEN	DBMS_OUTPUT.PUT_LINE('Audit report access is enabled');
			END IF;
		ELSIF v_ngkeyid = '19121012' THEN
			IF v_ngkeyvalue = '02801119_2342_SD'					THEN	DBMS_OUTPUT.PUT_LINE('Audit report check box is not enabled');
			ELSE										DBMS_OUTPUT.PUT_LINE('Audit report check box is enabled');
			END IF;
		ELSIF v_ngkeyid = '19121013' THEN
			IF v_ngkeyvalue = '02900506_5474_SD'					THEN	DBMS_OUTPUT.PUT_LINE('User deletion is not enabled');
			ELSE										DBMS_OUTPUT.PUT_LINE('User deletion is enabled');
			END IF;
		END IF;
	END LOOP;
	CLOSE C_NGCONFIG;

	SELECT  COUNT(nglastkeyused) INTO v_Count FROM ngsdms60.ngobjnuminfo WHERE ngobjectid_key1 = 'ProjectViewUniqueID';
	IF (v_Count = 1)	THEN	SELECT nglastkeyused INTO v_viewid FROM ngsdms60.ngobjnuminfo WHERE ngobjectid_key1 = 'ProjectViewUniqueID';
	ELSE				v_viewid := 0;
	END IF;
	DBMS_OUTPUT.PUT_LINE('.');
	DBMS_OUTPUT.PUT_LINE('The SDMS ProjectViewUniqueID is: '||v_viewid);

	DBMS_OUTPUT.PUT_LINE('.');
	DBMS_OUTPUT.PUT_LINE('Determining whether the SDMS_Administration project is present and correctly configured...');
	SELECT COUNT(*) INTO v_Count FROM NGSDMS60.NGPROJDEFS WHERE NGPROJNAME = 'SDMS_Administration';
	IF	(v_Count = 1)	THEN
		DBMS_OUTPUT.PUT_LINE('-- The SDMS_Administration project has been created');

		SELECT NVL(MAX(NGID), 0) INTO v_ngidmx FROM NGSDMS60.NGTAGS WHERE NGPROJGUID = 'BB3AF0B8-3EE3-4e4a-9BC2-E2E50672B256';
		SELECT NVL(NGLASTID, 0) INTO v_ngidlst FROM NGSDMS60.NGPROJDEFS WHERE NGPROJGUID = 'BB3AF0B8-3EE3-4e4a-9BC2-E2E50672B256';
		IF	(v_ngidlst >= v_ngidmx)	THEN	DBMS_OUTPUT.PUT_LINE('-- The nglastid value ('||v_ngidlst||') for the SDMS_Administration project is greater than or equal to largest NGID recorded ('||v_ngidmx||') for this project.');
		ELSIF	(v_ngidlst < v_ngidmx)	THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: the nglastid value ('||v_ngidlst||') for the system administration project is less than the largest NGID recorded ('||v_ngidmx||') for this project! This condition will prevent SDMS from creating reports in the system activities project!');
		END IF;
	ELSIF v_Count = 0	THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: THE SDMS_Administration project has not been created!');
	END IF;

	DBMS_OUTPUT.PUT_LINE('.');
	DBMS_OUTPUT.PUT_LINE('Determining if Oracle user account creation through SDMS Administrator is enabled:');
	SELECT COUNT(PRIVILEGE) INTO v_count FROM DBA_TAB_PRIVS WHERE PRIVILEGE = 'EXECUTE' AND TABLE_NAME = 'NGSDMS60USERMGMT' AND GRANTEE = 'NGPROXY';
	IF	(v_count = 0)	THEN	DBMS_OUTPUT.PUT_LINE ('-- The ng_grant_user_internal.sql script must be run to enable oracle user creation using SDMS ADMINISTRATOR');
	ELSIF	(v_count = 1)	THEN	DBMS_OUTPUT.PUT_LINE ('-- The feature allowing Oracle user account creation by SDMS Administrator is enabled');
	END IF;

	DBMS_OUTPUT.PUT_LINE('.');
	DBMS_OUTPUT.PUT_LINE('Determining if the NGProjmgr account is present in all of the expected tables:');
	SELECT COUNT(*) INTO v_Count FROM dba_users WHERE username = 'NGPROJMGR';
	IF	(v_count = 0)	THEN	DBMS_OUTPUT.PUT_LINE ('-- !!! WARNING: NGProjmgr is NOT present as an Oracle account in dba_users.');
	ELSIF	(v_count = 1)	THEN	DBMS_OUTPUT.PUT_LINE ('-- NGProjmgr is present as an Oracle account in dba_users.');
	END IF;

	SELECT COUNT(*) INTO v_Count FROM ngsysuser.ngusers WHERE nguserguid = 'NGPROJMGR_GUID1';
	IF	(v_count = 0)	THEN	DBMS_OUTPUT.PUT_LINE ('-- !!! WARNING: NGProjmgr is NOT present in ngsysuser.ngusers!  NGProjmgr will not be able to log in to SDMS!  See article WKB49880 for a solution.');
	ELSIF	(v_count = 1)	THEN	DBMS_OUTPUT.PUT_LINE ('-- NGProjmgr is present in ngysuser.ngusers.');
	END IF;

	SELECT COUNT(*) INTO v_Count FROM ngsysuser.ngusersauthmode WHERE nguserguid = 'NGPROJMGR_GUID1';
	IF	(v_count = 0)	THEN	DBMS_OUTPUT.PUT_LINE ('-- !!! WARNING: NGProjmgr is NOT present ngsysuser.ngusersauthmode!  NGProjmgr will not be able to log in to SDMS!  See article WKB49880 for a solution.');
	ELSIF	(v_count = 1)	THEN	DBMS_OUTPUT.PUT_LINE ('-- NGProjmgr is present in ngsysuser.ngusersauthmode.');
	END IF;

	DBMS_OUTPUT.PUT_LINE('.');
	DBMS_OUTPUT.PUT_LINE('Determining if The LMS data location is in this database or in a remote database...');
	SELECT COUNT(*) INTO v_Count FROM dba_db_links WHERE db_link = 'vp'; -- Link name is vp if in SDMS a user has configured a different storage location for LMS
	IF	(v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('-- LMS data location is this database instance.');
	ELSIF	(v_Count = 1)	THEN
		SELECT host INTO v_DBLinkHost FROM dba_db_links WHERE db_link = 'vp';
		DBMS_OUTPUT.PUT_LINE('-- LMS data location is the remote database instance: '||v_DBLinkHost);
	END IF;
END;
/

PROMPT
PROMPT ______________________________________________________________________________________
PROMPT Determining the NuGenesis SDMS audit sequence number...
PROMPT
DECLARE 
v_seqnum	NUMBER;
v_Count		PLS_INTEGER := 0;
v_NGAuditIDMin	PLS_INTEGER;
v_NGAuditIDMax	PLS_INTEGER;

BEGIN
	SELECT COUNT(*) INTO v_Count FROM DBA_OBJECTS WHERE OBJECT_NAME = 'NGAUDITSEQ' AND OWNER = 'NGSYSUSER' AND OBJECT_TYPE = 'SEQUENCE';
	SELECT NVL(MAX(NGAUDITID),0) INTO v_NGAuditIDMax FROM NGSYSUSER.NGAUDITMASTER;
	SELECT NVL(MIN(NGAUDITID),0) INTO v_NGAuditIDMin FROM NGSYSUSER.NGAUDITMASTER;

	IF v_Count > 0 THEN
		SELECT ngsysuser.ngauditseq.nextVAL INTO v_seqnum FROM dual;
		SELECT count(rowid) INTO v_Count FROM ngsysuser.ngauditmaster;

		DBMS_OUTPUT.PUT_LINE('The audit sequence number is:  '||v_seqnum);
		DBMS_OUTPUT.PUT_LINE('There are '||v_count||' rows in the ngsysuser.ngauditmaster table');
		DBMS_OUTPUT.PUT_LINE('The maximum ngauditid recorded in the ngsysuser.ngauditmaster table is:  '||v_NGAuditIDMax);
		DBMS_OUTPUT.PUT_LINE('The minimum ngauditid recorded in the ngsysuser.ngauditmaster table is:  '||v_NGAuditIDMin);

		IF (v_seqnum < 2147483647)	THEN	DBMS_OUTPUT.PUT_LINE('If this database will be the target of a NuGenesis migration, the audit sequence value for this database must be modified prior to the first login attempt through any sdms 9 components.');
		ELSIF (v_seqnum >= 2147483647)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: the audit sequence number is greater than the maximum allowable number of 2147483647! SDMS will not function!');
		END IF;

		DBMS_OUTPUT.PUT_LINE('.');
				
		SELECT COUNT(*) INTO v_Count FROM DBA_TAB_PRIVS WHERE OWNER = 'NGSYSUSER' AND TABLE_NAME = 'NGAUDITSEQ' AND PRIVILEGE = 'SELECT' AND GRANTEE = 'NGSDMS70PROXYROLE';
		IF v_Count > 0 THEN	DBMS_OUTPUT.PUT_LINE('NGSDMS70PROXYROLE has been granted select on ngauditseq');
		ELSE			DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: NGSDMS70PROXYROLE has not been granted select on ngauditseq!');
		END IF;	

		SELECT COUNT(*) INTO v_Count FROM DBA_TAB_PRIVS WHERE OWNER = 'NGSYSUSER' AND TABLE_NAME = 'NGAUDITSEQ' AND PRIVILEGE = 'SELECT' AND GRANTEE = 'NGSDMS60';
		IF v_Count > 0 THEN	DBMS_OUTPUT.PUT_LINE('NGSDMS60 has been granted select on ngauditseq');
		ELSE			DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: NGSDMS60 has not been granted select on ngauditseq!');
		END IF;	

		SELECT COUNT(*) INTO v_Count FROM DBA_TAB_PRIVS WHERE OWNER = 'NGSYSUSER' AND TABLE_NAME = 'NGAUDITSEQ' AND PRIVILEGE = 'ALTER' AND GRANTEE = 'NGSDMS60';
		IF v_Count > 0 THEN	DBMS_OUTPUT.PUT_LINE('NGSDMS60 has been granted alter on ngauditseq');
		ELSE			DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: NGSDMS60 has not been granted alter on ngauditseq!');
		END IF;	
	ELSE			DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: the audit sequence ''ngsysuser.ngauditseq'' not present in this database!');
	END IF;
END;
/

PROMPT
PROMPT
PROMPT Contents of ngsysuser.ngconfig table:
COLUMN NGSECTION 	FORMAT A25
COLUMN NGKEYID  	FORMAT A50
COLUMN NGKEYVALUE 	FORMAT A50
SELECT * FROM NGSYSUSER.NGCONFIG;

PROMPT
PROMPT Contents of the ngsysuser.ngschemainstalledinfo table:
COLUMN NGVERSION FORMAT A20
COLUMN NGDESC1 FORMAT A50
COLUMN NGDESC2 FORMAT A50
SELECT * FROM NGSYSUSER.NGSCHEMAINSTALLEDINFO;

PROMPT
PROMPT ****************************************************************************************************************
PROMPT Check for Smart Procedure Database Updates
PROMPT Upload_LIST.wts, UploadDefaultReport.sql, on disc 667006137rev A, in dir \SPDatabaseScripts
PROMPT ****************************************************************************************************************
PROMPT

DECLARE
v_Count		PLS_INTEGER;
v_loblen	PLS_INTEGER;
v_defparam	VARCHAR2(20 CHAR);
v_ReportName	elnprod.reportconfiguration.reportname%TYPE;

TYPE ObjList	IS TABLE OF VARCHAR2(500);
v_ListNames	ObjList;
v_ListEntries	ObjList;
v_ReportNames	ObjList;

BEGIN
	SELECT COUNT(*) INTO v_Count FROM elnprod.drg_methgrp WHERE methodgroupid LIKE 'WAT-%'; -- The SP template names all have the prefix WAT.  The database updates below are important only if the SP templates are installed.
	IF	(v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('None of the LMS Smart Procedure document templates are present.  Skipping the check for the SP database updates.');
	ELSIF	(v_Count > 0)	THEN
		DBMS_OUTPUT.PUT_LINE('The LMS Smart Procedure document templates are present.  Checking for new list entries added by the Smart Procedures pack...');
		SELECT COUNT(ROWID) INTO v_Count FROM ELNPROD.DOMAIN WHERE DOMAINID = 'ELN_FORMEVENTS' AND DESCRIPTION = 'List of document events';
		IF v_Count = 1		THEN	DBMS_OUTPUT.PUT_LINE('List ''ELN_FORMEVENTS'' is present');
		ELSIF v_Count = 0	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: list ''ELN_FORMEVENTS'' is NOT present!');
		END IF;

		v_ListNames   := ObjList('ELN_FORMEVENTS','ELN_FORMEVENTS','ELN_FORMEVENTS','ELN_FORMEVENTS','ELN_FORMEVENTS','ELN_FORMEVENTS','ELN_FORMEVENTS','ELN_FORMEVENTS');
		v_ListEntries := ObjList('U_CHEM_REGISTER','U_CHEM_MULTIDISPOSE','U_INST_REGISTER','U_INST_DISPOSE','U_INST_VERIFICATION','U_INST_ATTRIBUTE','U_SAMPLE_RESULTS','MAINT_CALIB_RESULT');

		FOR indx IN 1 .. v_ListEntries.COUNT
		LOOP
			SELECT COUNT(ROWID) INTO v_Count FROM ELNPROD.DOMAINVALUE WHERE DOMAINID = v_ListNames(indx) AND VALUE = v_ListEntries(indx);
			IF v_Count > 0 THEN	DBMS_OUTPUT.PUT_LINE('List '||v_ListNames(indx)||' has the entry '||v_ListEntries(indx));
			ELSE			DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: list '||v_ListNames(indx)||' does NOT have the entry '||v_ListEntries(indx));
			END IF;
		END LOOP;

		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('Checking for new reports added by the Smart Procedures pack...');

		v_ReportNames := ObjList('PrintLabelsSubstance','PrintLabelsInstrumen');
		FOR indx IN 1 .. v_ReportNames.COUNT
		LOOP
			v_ReportName := v_ReportNames(indx);
			SELECT COUNT(DEFAULTREPORTREF) INTO v_Count FROM ELNPROD.REPORTCONFIGURATION WHERE REPORTNAME = v_ReportName;
			IF v_Count = 0	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: default report '||v_ReportName||' is NOT present!');
			ELSE
				SELECT DEFAULTREPORTREF INTO v_defParam FROM ELNPROD.REPORTCONFIGURATION WHERE REPORTNAME = v_ReportName;
				IF (v_defParam IS NULL)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: default report '||v_ReportName||' is in elnprod.reportconfiguration but defaultreportref is null!');
				ELSE
					-- REPORT INSERT IN REPORTCONFIGURATION CREATED, CHECK TO SEE IF REPORT UPLOADED IN BINARYOBJECT
					SELECT COUNT(ROWID) INTO v_Count FROM ELNPROD.BINARYOBJECT WHERE BINARYOBJID = v_defparam;
					IF v_Count = 0 THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: default report '||v_ReportName||' is in elnprod.reportconfiguration and defaultreportref is non-null, but the ref number was not found in elnprod.binaryobject!');
					ELSE
						SELECT DBMS_LOB.GETLENGTH(BINARYOBJDATA) INTO v_loblen FROM ELNPROD.BINARYOBJECT WHERE BINARYOBJID = v_defparam;
						IF v_loblen < 55	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: default report '||v_ReportName||' is in elnprod.reportconfiguration, defaultreportref is non-null, ref number was found in elnprod.binaryobject, but the LOB length is less than expected!  The Jasper templates for this report are likely corrupt or incomplete!');
						ELSE				DBMS_OUTPUT.PUT_LINE(v_ReportName||' REPORT HAS BEEN UPLOADED');
						END IF;
					END IF;
				END IF;
			END IF;
		END LOOP;
	END IF;
	DBMS_OUTPUT.PUT_LINE('.');
END;
/

PROMPT
PROMPT ****************************************************************************************************************
PROMPT Verifying NuGenesis 9.0.1 Database Updates
PROMPT GrantSYSTEMDbmsJava.sql, UpdateELNPRODCtxSearch.sql, UpdateSDMSSchemaVer.sql, 0512CMN.wts
PROMPT ****************************************************************************************************************
PROMPT

DECLARE
v_Count		PLS_INTEGER;
v_LoggingMode	dba_indexes.logging%TYPE;

TYPE objList	IS TABLE OF VARCHAR2(500);
t_IndexList	ObjList;

BEGIN	
	IF	(:V_LMSSchemaVerAsNum < 9010)	THEN	DBMS_OUTPUT.PUT_LINE('NuGenesis version is less than 9.0.1, skipping these checks.');
	ELSE	DBMS_OUTPUT.PUT_LINE('NuGenesis version is greater than or equal to 9.0.1, starting verification of the NuGenesis 9.0.1 schema modifications.');
	END IF;

	-- GrantSYSTEMDbmsJava.sql
	IF	(:V_LMSSchemaVerAsNum < 9100)	THEN
		SELECT COUNT(PRIVILEGE) INTO v_Count FROM DBA_TAB_PRIVS WHERE GRANTEE = 'ELNPROD' AND TABLE_NAME = 'DBMS_JAVA' AND PRIVILEGE = 'EXECUTE';
		IF v_Count = 1		THEN	DBMS_OUTPUT.PUT_LINE('Elnprod has been granted execute on dbms_java.');
		ELSIF v_Count = 0	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: elnprod has not been granted execute on dbms_java!');
		END IF;
	ELSIF	(:V_LMSSchemaVerAsNum >= 9100)	THEN
		DBMS_OUTPUT.PUT_LINE('In NuGenesis 9.1 and later, elnprod does not need Execute privilege on dbms_java.');
	END IF;
	DBMS_OUTPUT.PUT_LINE('.');

	-- UpdateELNPRODCtxSearch.sql
	SELECT COUNT(*) INTO v_Count FROM dba_triggers WHERE owner = 'ELNPROD' AND trigger_name = 'MO_ORDERMETHGROUP_INSERT';
	IF v_Count = 1		THEN	DBMS_OUTPUT.PUT_LINE('Trigger elnprod.mo_ordermethgroup_insert is present.');
	ELSIF v_Count = 0	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: trigger elnprod.mo_ordermethgroup_insert is NOT present!');
	END IF;
	DBMS_OUTPUT.PUT_LINE('.');

	-- UpdateSDMSSchemaVer.sql
	SELECT COUNT(*) INTO v_Count FROM NGSYSUSER.NGSCHEMAINSTALLEDINFO WHERE SCHEMAVER = '800' OR NGVERSION = 'SDMS80' OR  NGDESC1 = 'SDMS80 SERVER INSTALLED';
	IF v_Count > 0		THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: ngsysuser.ngschemainstalledinfo table has not been updated to 9.0!  Run ''updateSDMSschemaVer.sql'' on the LMS 9.0.1 media, part no. 667006022 rev A, to update the SDMS schema version.');
	ELSE				DBMS_OUTPUT.PUT_LINE('NGsysuser.ngschemainstalledinfo table has been updated to 9.0.');
	END IF;
	DBMS_OUTPUT.PUT_LINE('.');

	SELECT COUNT(ROWID) INTO v_Count FROM NGSYSUSER.NGSERVERPROJINFO WHERE SCHEMAVER = '800';
	IF v_Count > 0		THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: ngsysuser.ngserverprojinfo table has not been updated to 9.0!  Run ''updateSDMSschemaVer.sql'' on the LMS 9.0.1 media, part no. 667006022 rev A, to update the SDMS schema version.');
	ELSE				DBMS_OUTPUT.PUT_LINE('NGsysuser.ngserverprojinfo table has been updated to 9.0');
	END IF;
	DBMS_OUTPUT.PUT_LINE('.');

	SELECT COUNT(ROWID) INTO v_Count FROM NGSYSUSER.NGUSERS WHERE SCHEMAVER = '800';
	IF v_Count > 0		THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: ngsysuser.ngusers table has not been updated to 9.0!  Run ''updateSDMSschemaVer.sql'' on the LMS 9.0.1 media, part no. 667006022 rev A, to update the SDMS schema version.');
	ELSE				DBMS_OUTPUT.PUT_LINE('NGsysuser.ngusers table has been updated to 9.0');
	END IF;
	DBMS_OUTPUT.PUT_LINE('.');

	SELECT COUNT(ROWID) INTO v_Count FROM NGSYSUSER.NGUSERSAUTHMODE WHERE SCHEMAVER = '800';
	IF v_Count > 0		THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: ngsysuser.ngusersauthmode table has not been updated to 9.0!  Run ''updateSDMSschemaVer.sql'' on the LMS 9.0.1 media, part no. 667006022 rev A, to update the SDMS schema version.');
	ELSE				DBMS_OUTPUT.PUT_LINE('NGsysuser.ngusersauthmode table has been updated to 9.0');
	END IF;

	-- 0512CMN.wts
	DBMS_OUTPUT.PUT_LINE('.');
	t_IndexList := ObjList('XPKMO_SIGN','XPKLABGROUPEMPLOYEE','XPKMAILBOX_COMPONENTRETURN','XPKMAILBOX_MEASUREORDER','XPKMAILBOX_METHOD','XPKMAILBOX_ORDERATTRIBUTES','XPKDATAFIELDS','XPKMESSAGES','XPKMO_PARAMETERTAB','XPKEMPLOYEE','XPKMAILBOX_SAMPLE','XPKMAILBOX_STRUCTUREATTRIBUTES','XPKUSERLOG','XPIUSERMESSAGE2','XPKUSERPREFERENCES','XPKUSERS','XPKPROJECTUSER');
	FOR indx IN 1 .. t_IndexList.COUNT
	LOOP
		SELECT logging INTO v_LoggingMode FROM dba_indexes WHERE owner = 'ELNPROD' AND index_name = t_IndexList(indx);
		IF	(v_LoggingMode = 'YES')	THEN	DBMS_OUTPUT.PUT_LINE('Index ELNPROD.'||t_IndexList(indx)||' is in logging mode');
		ELSE					DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: index ELNPROD.'||t_IndexList(indx)||' is NOT in logging mode!');
		END IF;
	END LOOP;

	t_IndexList := ObjList('MLOG$_MEASUREORDER1','MLOG$_MO_ORDERATTRIBUTES1','MLOG$_MO_PARAMETERTAB1');
	FOR indx IN 1 .. t_IndexList.COUNT
	LOOP
		SELECT COUNT(*) INTO v_Count FROM dba_tables WHERE owner = 'ELNPROD' AND table_name = t_IndexList(indx);
		IF	(v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('Table ELNPROD.'||t_IndexList(indx)||' has been dropped.');
		ELSE				DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: table ELNPROD.'||t_IndexList(indx)||' has NOT been dropped!');
		END IF;
	END LOOP;
END;
/

PROMPT
PROMPT ****************************************************************************************************************
PROMPT Verifying NuGenesis 9.0.2 Database Updates
PROMPT 0513DRG.wts
PROMPT ****************************************************************************************************************
PROMPT

DECLARE
v_Count		PLS_INTEGER;
v_GUID		elnprod.labgroupnotifications.notificationguid%TYPE;

BEGIN
	DBMS_OUTPUT.PUT_LINE('NuGenesis LMS schema version: '||:v_LMSSchemaVer);
	IF	(:v_LMSSchemaVerAsNum < 9020)	THEN	DBMS_OUTPUT.PUT_LINE('NuGenesis version is less than 9.0.2, skipping these checks.');
	ELSE	DBMS_OUTPUT.PUT_LINE('NuGenesis version is greater than or equal to 9.0.2, starting verification of the NuGenesis 9.0.2 schema modifications.');
		SELECT COUNT(*) INTO v_Count FROM elnprod.labgroupnotifications WHERE notificationid = 'OLEPICTUREFORMATCHK';
		IF (v_Count = 1)	THEN
			DBMS_OUTPUT.PUT_LINE(' ''OLEPICTUREFORMATCHK'' has been added to elnprod.labgroupnotifications');
			SELECT notificationguid INTO v_GUID FROM elnprod.labgroupnotifications WHERE notificationid = 'OLEPICTUREFORMATCHK';
		ELSE
			DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: ''OLEPICTUREFORMATCHK'' was not added to elnprod.labgroupnotifications!');
		END IF;

		SELECT COUNT(*) INTO v_Count FROM elnprod.labgroupnotificationlist WHERE notificationguid = v_GUID AND empid = 'ADMIN';
		IF (v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('The ADMIN account is configured to receive ''OLEPICTUREFORMATCHK'' notifications');
		ELSE				DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: The ADMIN Account is NOT configured to receive ''OLEPICTUREFORMATCHK'' notifications!');
		END IF;
	END IF;
END;
/

PROMPT
PROMPT ****************************************************************************************************************
PROMPT Verifying NuGenesis 9.0.2 Hotfix 1 Database Updates
PROMPT 0514DRG.wts
PROMPT ****************************************************************************************************************
PROMPT

DECLARE
v_Count		PLS_INTEGER := 0;

BEGIN
	IF	(:v_LMSSchemaVerAsNum < 9020)	THEN	DBMS_OUTPUT.PUT_LINE('NuGenesis version is less than 9.0.2 HF1, skipping these checks.');
	ELSE	DBMS_OUTPUT.PUT_LINE('NuGenesis version is greater than or equal to 9.0.2 HF1, starting verification of the NuGenesis 9.0.2 HF1 schema modifications.');
		SELECT COUNT(*) INTO v_Count FROM elnprod.systemvalues WHERE systemtypeid = 'DRG_SYSTEM' AND valuecode = 'SEARCHOPTIONS';
		IF (v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('The ''SEARCHOPTIONS'' setting was added to elnprod.systemvalues.');
		ELSE				DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: the ''SEARCHOPTIONS'' setting is not present in elnprod.systemvalues!');
		END IF;

		SELECT COUNT(*) INTO v_Count FROM dba_views WHERE owner = 'ELNPROD' AND view_name = 'VW_TESTSEARCH_LOGSIGNER';
		IF (v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('The view ELNPROD.VW_TESTSEARCH_LOGSIGNER is present');
		ELSE				DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: the view ELNPROD.VW_TESTSEARCH_LOGSIGNER is NOT present!');
		END IF;
	END IF;
END;
/

PROMPT
PROMPT ****************************************************************************************************************
PROMPT Verifying NuGenesis 9.1 Database Updates
PROMPT ****************************************************************************************************************
PROMPT

BEGIN
	DBMS_OUTPUT.PUT_LINE('NuGenesis LMS schema version: '||:v_LMSSchemaVer);
	IF	(:v_LMSSchemaVerAsNum < 9100)	THEN	DBMS_OUTPUT.PUT_LINE('NuGenesis version is less than 9.1, skipping these checks.');
	ELSE	DBMS_OUTPUT.PUT_LINE('NuGenesis version is greater than or equal to 9.1, starting verification of the NuGenesis 9.1 schema modifications.');
	END IF;
END;
/

DECLARE
v_Count		PLS_INTEGER := 0;
v_SQLStatement	VARCHAR2(1000);
TYPE ObjList	IS TABLE OF VARCHAR2(500);
TYPE NumList	IS TABLE OF NUMBER;
t_CategoryGroupIDs	NumList;
t_CategoryGroupNames	ObjList;
t_Categories		NuMList;
t_StringCategories	NumList;
t_StringLangIds		ObjList;
t_StringIDs		NumList;

BEGIN
	IF (:v_LMSSchemaVerAsNum >= 9100)	THEN
		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('.'); 
		DBMS_OUTPUT.PUT_LINE('SDMS: nguserrefreshtokens.sql');
		DBMS_OUTPUT.PUT_LINE('.');


		SELECT COUNT(*) INTO v_Count FROM dba_tables WHERE owner = 'NGSYSUSER' AND table_name = 'NGUSERREFRESHTOKENS';
		IF (v_Count = 1)	THEN
			DBMS_OUTPUT.PUT_LINE('Table ngsysuser.nguserrefreshtokens is present');
			SELECT COUNT(*) INTO v_Count FROM dba_constraints WHERE constraint_name = 'NGTOKENGUID_PK';
			IF	(v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('-- Primary key constraint ngtokenguid_pk is present');
			ELSIF	(v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('-- !!! WARNING: Primary key constraint ngtokenguid_pk is NOT present!');
			END IF;
		ELSE	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: table ngsysuser.nguserrefreshtokens is NOT present!');
		END IF;

		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('.'); 
		DBMS_OUTPUT.PUT_LINE('SDMS: SDMS70SYSUSERAUDIT.sql');
		DBMS_OUTPUT.PUT_LINE('.');

		SELECT COUNT(*) INTO v_Count FROM dba_tables WHERE owner = 'NGSYSUSER' AND table_name = 'NGAUDITCATEGORYGROUPS';
		IF (v_Count = 1)	THEN
			DBMS_OUTPUT.PUT_LINE('Table ngsysuser.ngauditcategorygroups is present');
			SELECT COUNT(*) INTO v_Count FROM dba_constraints WHERE constraint_name = 'NGCATEGORYGROUP_PK';
			IF	(v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('-- Primary key constraint ngcategorygroup_pk is present');
			ELSIF	(v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('-- !!! WARNING: Primary key constraint ngcategorygroup_pk is NOT present!');
			END IF;
		ELSE	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: table ngsysuser.ngauditcategorygroups is NOT present!');
		END IF;

		DBMS_OUTPUT.PUT_LINE('.');

		SELECT COUNT(*) INTO v_Count FROM dba_tab_cols WHERE owner = 'NGSYSUSER' AND table_name = 'NGAUDITCATEGORIES' AND column_name = 'NGCATEGORYGROUP';
		IF	(v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('Column ngcategorygroup was added to table ngsysuser.ngauditcategories');
		ELSE				DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: column ngcategorygroup was NOT added to table ngsysuser.ngauditcategories!');
		END IF;

		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('.'); 
		DBMS_OUTPUT.PUT_LINE('SDMS: ngauditcategorygroup.sql');
		DBMS_OUTPUT.PUT_LINE('.');

		t_CategoryGroupIDs := NumList(1,2,3,4);
		t_CategoryGroupNames := ObjList('Security and Compliance','Projects and Project items','Captured Data','System Settings');

		FOR indx IN 1 .. t_CategoryGroupIDs.COUNT
		LOOP
			v_SQLStatement := 'SELECT COUNT(*) FROM ngsysuser.ngauditcategorygroups WHERE ngcategorygroup = '||t_CategoryGroupIDs(indx)||' AND ngname = '''||t_CategoryGroupNames(indx)||'''';
			EXECUTE IMMEDIATE v_SQLStatement INTO v_Count;
			IF	(v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('Audit category group ID '||t_CategoryGroupIDs(indx)||' and name '||t_CategoryGroupNames(indx)||' is present in ngsysuser.ngauditcategorygroups');
			ELSIF	(v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: Audit category group ID '||t_CategoryGroupIDs(indx)||' and name '||t_CategoryGroupNames(indx)||' is NOT present in ngsysuser.ngauditcategorygroups!');
			END IF;
		END LOOP;

		t_Categories :=       NumList(6,7,8,9,11,13,14,17,18,1,3,4,5,10,12,2,15,16,19);
		t_CategoryGroupIDs := NumList(1,1,1,1,1, 1, 1, 1, 1, 2,2,2,2, 2, 2,3, 4, 4, 4);

		FOR indx2 IN 1 .. t_Categories.COUNT
		LOOP
			v_SQLStatement := 'SELECT COUNT(*) FROM ngsysuser.ngauditcategories WHERE ngcategory = '||t_Categories(indx2)||' AND ngcategorygroup = '||t_CategoryGroupIDs(indx2);
			EXECUTE IMMEDIATE v_SQLStatement INTO v_Count;
			IF	(v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('NGauditcategory '||t_Categories(indx2)||' has been set to audit category group '||t_CategoryGroupIDs(indx2)||' in ngsysuser.ngauditcategories');
			ELSIF	(v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: NGauditcategory '||t_Categories(indx2)||' has NOT been set to audit category group '||t_CategoryGroupNames(indx2)||' in ngsysuser.ngauditcategories!');
			END IF;
		END LOOP;

		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('.'); 
		DBMS_OUTPUT.PUT_LINE('SDMS: ngstringlookup_delete.sql');
		DBMS_OUTPUT.PUT_LINE('.');

		SELECT COUNT(*) INTO v_Count FROM dba_tab_cols WHERE owner = 'NGSYSUSER' AND table_name = 'NGSTRINGLOOKUP' AND column_name = 'ISAUDITACTIVE';
		IF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: column ''isauditactive'' was NOT added to ngsysuser.ngstringlookup!');
		ELSE
			DBMS_OUTPUT.PUT_LINE('Column ''isauditactive'' was added to ngsysuser.ngstringlookup');
			v_SQLStatement := 'SELECT COUNT(*) FROM ngsysuser.ngstringlookup WHERE ngstrid = 6501 AND isauditactive = 0';
			EXECUTE IMMEDIATE v_SQLStatement INTO v_Count;
			IF (v_Count > 0)	THEN	DBMS_OUTPUT.PUT_LINE('-- IsAuditActive has been set to 0 for ngstrid 6501 in ngsysuser.ngstringlookup');
			ELSE				DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: IsAuditActive has NOT been set to 0 for ngstrid 6501 in ngsysuser.ngstringlookup!');
			END IF;
		END IF;

		t_StringCategories := NumList(18,  1,   14,  9,   12,  12);
		t_StringIDs        := NumList(5703,1003,3303,5501,3063,3062);
		t_StringLangIDs    := ObjList('en','en','en','en','en','en');

		FOR indx3 IN 1 .. t_StringIDs.COUNT
		LOOP
			SELECT COUNT(*) INTO v_Count FROM ngsysuser.ngstringlookup WHERE ngstrcategory = t_StringCategories(indx3) AND ngstrid = t_StringIDs(indx3) AND nglangid = t_StringLangIDs(indx3);
			IF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('NGstring ID '||t_StringIDs(indx3)||' category '||t_StringCategories(indx3)||' lang ID '|| t_StringLangIDs(indx3)||' was deleted from ngsysuser.ngstringlookup');
			ELSE				DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: NGstring ID '||t_StringIDs(indx3)||' category '||t_StringCategories(indx3)||' lang ID '|| t_StringLangIDs(indx3)||' was NOT deleted from ngsysuser.ngstringlookup!');
			END IF;
		END LOOP;

		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('.'); 
		DBMS_OUTPUT.PUT_LINE('SDMS: ngauditmaster.sql');
		DBMS_OUTPUT.PUT_LINE('.');

		SELECT COUNT(*) INTO v_Count FROM dba_indexes WHERE owner = 'NGSYSUSER' AND index_name = 'NGAUDITMASTERCLU_IDX1' AND table_owner = 'NGSYSUSER' AND table_name = 'NGAUDITMASTER';
		IF	(v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('Index ngsysuser.ngauditmasterclu_idx1 is present on ngsysuser.ngaudtmaster');
		ELSIF	(v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: Index ngsysuser.ngauditmasterclu_idx1 is NOT present on ngsysuser.ngaudtmaster!');
		END IF;

		SELECT COUNT(*) INTO v_Count FROM dba_indexes WHERE owner = 'NGSYSUSER' AND index_name = 'NGAUDITMASTERCLU_IDX2' AND table_owner = 'NGSYSUSER' AND table_name = 'NGAUDITMASTER';
		IF	(v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('Index ngsysuser.ngauditmasterclu_idx2 is present on ngsysuser.ngaudtmaster');
		ELSIF	(v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: Index ngsysuser.ngauditmasterclu_idx2 is NOT present on ngsysuser.ngaudtmaster!');
		END IF;

		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('.'); 
		DBMS_OUTPUT.PUT_LINE('SDMS: proxy_grants.sql');
		DBMS_OUTPUT.PUT_LINE('.');

		SELECT COUNT(*) INTO v_Count FROM dba_tab_privs WHERE owner = 'NGSYSUSER' AND table_name = 'NGUSERREFRESHTOKENS' AND grantee = 'NGSDMS70PROXYROLE' AND privilege IN ('SELECT','INSERT','UPDATE','DELETE');
		IF	(v_Count = 4)	THEN	DBMS_OUTPUT.PUT_LINE('NGsdms70proxyrole has been granted SELECT, INSERT, UPDATE, and DELETE on ngsysuser.nguserrefreshtokens');
		ELSIF	(v_Count < 4)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: ngsdms70proxyrole has NOT been granted SELECT, INSERT, UPDATE, and DELETE on ngsysuser.nguserrefreshtokens');
		END IF;

		SELECT COUNT(*) INTO v_Count FROM dba_tab_privs WHERE owner = 'NGSYSUSER' AND table_name = 'NGAUDITCATEGORYGROUPS' AND grantee = 'NGSDMS70PROXYROLE' AND privilege IN ('SELECT','INSERT','UPDATE','DELETE');
		IF	(v_Count = 4)	THEN	DBMS_OUTPUT.PUT_LINE('NGsdms70proxyrole has been granted SELECT, INSERT, UPDATE, and DELETE on ngsysuser.ngauditcategorygroups');
		ELSIF	(v_Count < 4)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: ngsdms70proxyrole has NOT been granted SELECT, INSERT, UPDATE, and DELETE on ngsysuser.ngauditcategorygroups');
		END IF;
	END IF;
END;
/

DECLARE
v_Count		PLS_INTEGER := 0;
TYPE ObjList	IS TABLE OF VARCHAR2(500);
t_TableList	ObjList;
t_ColumnList	ObjList;
v_TableName	dba_indexes.table_name%TYPE;
t_SystemTypeIDs	ObjList;
t_ValueCodes	ObjList;
t_ListEntries	ObjList;
v_BookInEvent	elnprod.systemvalues.longalphavalue%TYPE;
v_ReagentEventsList	elnprod.systemvalues.alphavalue%TYPE;
v_IntValue	PLS_INTEGER;
t_ViewNames	ObjList;

BEGIN
	IF (:v_LMSSchemaVerAsNum >= 9100)	THEN
		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('.'); 
		DBMS_OUTPUT.PUT_LINE('LMS: 0515DRG.wts');
		DBMS_OUTPUT.PUT_LINE('.');

		SELECT COUNT(*) INTO v_Count FROM elnprod.systemvalues WHERE systemtypeid = 'DRG_SYSTEM' AND valuecode = 'DRG_SUBMISS_DEPART';
		IF	(v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('DRG_SUBMIS_DEPART was added to elnprod.systemvalues');
		ELSIF	(v_Count < 1)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: DRG_SUBMIS_DEPART was NOT added to elnprod.systemvalues');
		END IF;

		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('.'); 
		DBMS_OUTPUT.PUT_LINE('LMS: 0516CMN.wts');
		DBMS_OUTPUT.PUT_LINE('.');
		SELECT COUNT(*) INTO v_Count FROM dba_tables WHERE owner = 'ELNPROD' AND table_name = 'INV_INSTRUMENTTEMP';
		IF	(v_Count = 1)	THEN
			DBMS_OUTPUT.PUT_LINE('Temp table elnprod.inv_instrumenttemp is present');
			SELECT COUNT(*) INTO v_Count FROM dba_tab_cols WHERE owner = 'ELNPROD' AND table_name = 'INV_INSTRUMENTTEMP' AND column_name = 'USEDDATE';
			IF	(v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('-- Column useddate is present in elnprod.inv_instrumenttemp');
			ELSIF	(v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: Column useddate is NOT present in elnprod.inv_instrumenttemp');
			END IF;
		ELSIF	(v_Count < 1)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: Temp table elnprod.inv_instrumenttemp is NOT present');
		END IF;

		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('.'); 
		DBMS_OUTPUT.PUT_LINE('LMS: 0517CMN.wts');
		DBMS_OUTPUT.PUT_LINE('.');
		t_TableList := ObjList('INV_INSTRUMENT','INV_INSTRUMENTA0');
		t_ColumnList := ObjList('GENERIC01','GENERIC02','GENERIC03','GENERIC04','GENERIC05','GENERIC06','GENERIC07','GENERIC08','GENERIC09','GENERIC10','GENERIC11','GENERIC12','GENERIC13','GENERIC14','GENERIC15','GENERIC16','GENERIC17','GENERIC18','GENERIC19','GENERIC20','GENERICNUM01','GENERICNUM02','GENERICNUM03','GENERICNUM04','GENERICNUM05','GENERICDATE01','GENERICDATE02','GENERICDATE03','GENERICDATE04','GENERICDATE05','CONFIGURATIONID','STATUS','USE','ASSETNUMBER','MODELNUMBER');
		FOR indx IN 1 .. t_TableList.COUNT
		LOOP
			FOR indx2 IN 1 .. t_ColumnList.COUNT
			LOOP
				SELECT COUNT(*) INTO v_Count FROM dba_tab_cols WHERE owner = 'ELNPROD' AND table_name = t_TableList(indx) AND column_name = t_ColumnList(indx2);
				IF	(v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('Column '||t_ColumnList(indx2) ||' was added to elnprod.'||t_TableList(indx));
				ELSIF	(v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: Column '||t_ColumnList(indx2) ||' was NOT added to elnprod.'||t_TableList(indx));
				END IF;
			END LOOP;
		END LOOP;

		t_TableList := ObjList('INV_INSTRUMENTLOG','INV_INSTRUMENTLOGA0');
		t_ColumnList := ObjList('APPROVEDBY','APPROVEDDATE','EVENTTIME');
		FOR indx IN 1 .. t_TableList.COUNT
		LOOP
			FOR indx2 IN 1 .. t_ColumnList.COUNT
			LOOP
				SELECT COUNT(*) INTO v_Count FROM dba_tab_cols WHERE owner = 'ELNPROD' AND table_name = t_TableList(indx) AND column_name = t_ColumnList(indx2);
				IF	(v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('Column '||t_ColumnList(indx2) ||' was added to elnprod.'||t_TableList(indx));
				ELSIF	(v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: Column '||t_ColumnList(indx2) ||' was NOT added to elnprod.'||t_TableList(indx));
				END IF;
			END LOOP;
		END LOOP;

		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('.'); 
		DBMS_OUTPUT.PUT_LINE('LMS: 0518CMN.wts');
		DBMS_OUTPUT.PUT_LINE('.');
		SELECT COUNT(*) INTO v_Count FROM dba_tab_cols WHERE owner = 'ELNPROD' AND table_name = 'INV_INSTRUMENT' AND column_name = 'CTXSEARCH';
		IF 	(v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('Column ''ctxsearch'' was added to elnprod.inv_instrument');
		ELSE				DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: Column ''ctxsearch'' was NOT added to elnprod.inv_instrument');
		END IF;
		SELECT COUNT(*) INTO v_Count FROM dba_tab_cols WHERE owner = 'ELNPROD' AND table_name = 'INV_INSTRUMENTA0' AND column_name = 'CTXSEARCH';
		IF 	(v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('Column ''ctxsearch'' was added to elnprod.inv_instrumenta0');
		ELSE				DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: Column ''ctxsearch'' was NOT added to elnprod.inv_instrumenta0');
		END IF;

		SELECT COUNT(*) INTO v_Count FROM dba_procedures WHERE owner = 'ELNPROD' AND object_name = 'INV_INSTRUMENT_CONCAT' AND object_type = 'PROCEDURE';
		IF	(v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('Procedure elnprod.inv_instrument_concat is present');
		ELSE				DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: Procedure elnprod.inv_instrument_concat is NOT present');
		END IF;

		SELECT COUNT(*) INTO v_Count FROM ctx_stoplists WHERE SPL_OWNER = 'ELNPROD'  AND SPL_NAME ='ELNSTOP';
		IF	(v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('Stop list ELNSTOP is present');
		ELSE				DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: stop list ELNSTOP is NOT present');
		END IF;

		SELECT COUNT(*) INTO v_Count FROM ctx_preferences WHERE pre_owner = 'ELNPROD' AND  PRE_NAME ='ELNLEX';
		IF	(v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('CTX preference ELNLEX is present');
		ELSE				DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: CTX preference ELNLEX is NOT present');
		END IF;

		SELECT COUNT(*) INTO v_Count FROM ctx_preferences WHERE pre_owner = 'ELNPROD' AND PRE_NAME ='INV_INSTRUMENT_DATASTORE';
		IF	(v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('CTX preference INV_INSTRUMENT_DATASTORE is present');
		ELSE				DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: CTX preference INV_INSTRUMENT_DATASTORE is NOT present');
		END IF;

		SELECT COUNT(*) INTO v_Count FROM ctx_preference_values WHERE prv_owner = 'ELNPROD' AND prv_preference ='ELNLEX' AND prv_attribute = 'PRINTJOINS';
		IF	(v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('CTX attribute elnprod.ELNLEX.printjoins is present');
		ELSE				DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: CTX attribute elnprod.ELNLEX.printjoins is NOT present');
		END IF;

		SELECT COUNT(*) INTO v_Count FROM ctx_preference_values WHERE prv_owner = 'ELNPROD' AND prv_preference ='INV_INSTRUMENT_DATASTORE' AND prv_attribute = 'PROCEDURE' AND prv_value = '"ELNPROD"."INV_INSTRUMENT_CONCAT"';
		IF	(v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('CTX attribute elnprod.INV_INSTRUMENT_DATASTORE.PROCEDURE is present and set to ''ELNPROD.INV_INSTRUMENT_CONCAT'' ');
		ELSE				DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: CTX attribute elnprod.INV_INSTRUMENT_DATASTORE.PROCEDURE is NOT present OR NOT set to ''ELNPROD.INV_INSTRUMENT_CONCAT'' ');
		END IF;

		SELECT COUNT(*) INTO v_Count FROM dba_indexes WHERE owner = 'ELNPROD' AND index_name = 'IDX_INV_INSTRUMENTLAST';
		IF	(v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: index elnprod.idx_inv_instrumentlast is NOT present');
		ELSE
			SELECT table_name INTO v_TableName FROM dba_indexes WHERE owner = 'ELNPROD' AND index_name = 'IDX_INV_INSTRUMENTLAST';
			IF	(v_TableName != 'INV_INSTRUMENT')	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: index elnprod.idx_inv_instrumentlast is present but on the wrong table ('||v_TableName||', expected: INV_INSTRUMENT)');
			ELSE							DBMS_OUTPUT.PUT_LINE('Index elnprod.idx_inv_instrumentlast is present and on the correct table, inv_instrument');
			END IF;
		END IF;

		SELECT COUNT(*) INTO v_Count FROM dba_indexes WHERE owner = 'ELNPROD' AND index_name = 'TEXT_IDX_INV_INSTRUMENT';
		IF	(v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: index elnprod.text_idx_inv_instrument is NOT present');
		ELSE
			SELECT table_name INTO v_TableName FROM dba_indexes WHERE owner = 'ELNPROD' AND index_name = 'TEXT_IDX_INV_INSTRUMENT';
			IF	(v_TableName != 'INV_INSTRUMENT')	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: index elnprod.text_idx_inv_instrument is present but on the wrong table ('||v_TableName||', expected: INV_INSTRUMENT)');
			ELSE							DBMS_OUTPUT.PUT_LINE('Index elnprod.text_idx_inv_instrument is present and on the correct table, inv_instrument');
			END IF;
		END IF;

		SELECT COUNT(*) INTO v_Count FROM dba_procedures WHERE owner = 'ELNPROD' AND object_name = 'INV_INSTRUMENTUPDATEINDEX' AND object_type = 'PROCEDURE';
		IF	(v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('Procedure elnprod.inv_instrumentupdateindex is present');
		ELSE				DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: Procedure elnprod.inv_instrumentupdateindex is NOT present');
		END IF;

		SELECT COUNT(*) INTO v_Count FROM dba_procedures WHERE owner = 'ELNPROD' AND object_name = 'INV_INSTRUMENT_UPDATE' AND object_type = 'TRIGGER';
		IF	(v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('Trigger elnprod.inv_instrument_update is present');
		ELSE				DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: Trigger elnprod.inv_instrument_update is NOT present');
		END IF;

		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('.'); 
		DBMS_OUTPUT.PUT_LINE('LMS: 0519CMN.wts');
		DBMS_OUTPUT.PUT_LINE('.');
		SELECT COUNT(*) INTO v_Count FROM dba_tables WHERE owner = 'ELNPROD' AND table_name = 'INV_CHEMICALTEMP';
		IF	(v_Count = 1)	THEN
			DBMS_OUTPUT.PUT_LINE('Temp table elnprod.inv_chemicaltemp is present');
			SELECT COUNT(*) INTO v_Count FROM dba_tab_cols WHERE owner = 'ELNPROD' AND table_name = 'INV_CHEMICALTEMP' AND column_name = 'USEDDATE';
			IF	(v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('-- Column useddate is present in elnprod.inv_instrumenttemp');
			ELSIF	(v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: Column useddate is NOT present in elnprod.inv_chemicaltemp');
			END IF;
		ELSIF	(v_Count < 1)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: Temp table elnprod.inv_chemicaltemp is NOT present');
		END IF;

		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('.'); 
		DBMS_OUTPUT.PUT_LINE('LMS: 0520CMN.wts');
		DBMS_OUTPUT.PUT_LINE('.');
		SELECT COUNT(*) INTO v_Count FROM dba_tab_cols WHERE owner = 'ELNPROD' AND table_name = 'INV_CHEMICAL' AND column_name = 'CTXSEARCH';
		IF 	(v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('Column ''ctxsearch'' was added to elnprod.inv_chemical');
		ELSE				DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: Column ''ctxsearch'' was NOT added to elnprod.inv_chemical');
		END IF;
		SELECT COUNT(*) INTO v_Count FROM dba_tab_cols WHERE owner = 'ELNPROD' AND table_name = 'INV_CHEMICALA0' AND column_name = 'CTXSEARCH';
		IF 	(v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('Column ''ctxsearch'' was added to elnprod.inv_chemicala0');
		ELSE				DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: Column ''ctxsearch'' was NOT added to elnprod.inv_chemicala0');
		END IF;

		SELECT COUNT(*) INTO v_Count FROM dba_procedures WHERE owner = 'ELNPROD' AND object_name = 'INV_INSTRUMENT_CONCAT' AND object_type = 'PROCEDURE';
		IF	(v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('Procedure elnprod.inv_instrument_concat is present');
		ELSE				DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: Procedure elnprod.inv_instrument_concat is NOT present');
		END IF;

		SELECT COUNT(*) INTO v_Count FROM ctx_stoplists WHERE SPL_OWNER = 'ELNPROD'  AND SPL_NAME ='ELNSTOP';
		IF	(v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('Stop list ELNSTOP is present');
		ELSE				DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: stop list ELNSTOP is NOT present');
		END IF;

		SELECT COUNT(*) INTO v_Count FROM ctx_preferences WHERE pre_owner = 'ELNPROD' AND  PRE_NAME ='ELNLEX';
		IF	(v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('CTX preference ELNLEX is present');
		ELSE				DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: CTX preference ELNLEX is NOT present');
		END IF;

		SELECT COUNT(*) INTO v_Count FROM ctx_preferences WHERE pre_owner = 'ELNPROD' AND PRE_NAME ='INV_CHEMICAL_DATASTORE';
		IF	(v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('CTX preference INV_CHEMICAL_DATASTORE is present');
		ELSE				DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: CTX preference INV_CHEMICAL_DATASTORE is NOT present');
		END IF;

		SELECT COUNT(*) INTO v_Count FROM ctx_preference_values WHERE prv_owner = 'ELNPROD' AND prv_preference ='INV_CHEMICAL_DATASTORE' AND prv_attribute = 'PROCEDURE' AND prv_value = '"ELNPROD"."INV_CHEMICAL_CONCAT"';
		IF	(v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('CTX attribute elnprod.INV_CHEMICAL_DATASTORE.PROCEDURE is present and set to ''ELNPROD.INV_CHEMICAL_CONCAT'' ');
		ELSE				DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: CTX attribute elnprod.INV_CHEMICAL_DATASTORE.PROCEDURE is NOT present OR NOT set to ''ELNPROD.INV_CHEMICAL_CONCAT'' ');
		END IF;

		SELECT COUNT(*) INTO v_Count FROM dba_indexes WHERE owner = 'ELNPROD' AND index_name = 'IDX_INV_CHEMICALLAST';
		IF	(v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: index elnprod.idx_inv_chemicallast is NOT present');
		ELSE
			SELECT table_name INTO v_TableName FROM dba_indexes WHERE owner = 'ELNPROD' AND index_name = 'IDX_INV_CHEMICALLAST';
			IF	(v_TableName != 'INV_CHEMICAL')	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: index elnprod.idx_inv_chemicallast is present but on the wrong table ('||v_TableName||', expected: INV_CHEMICAL)');
			ELSE						DBMS_OUTPUT.PUT_LINE('Index elnprod.idx_inv_chemicallast is present and on the correct table, inv_chemical');
			END IF;
		END IF;

		SELECT COUNT(*) INTO v_Count FROM dba_indexes WHERE owner = 'ELNPROD' AND index_name = 'TEXT_IDX_INV_CHEMICAL';
		IF	(v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: index elnprod.text_idx_inv_chemical is NOT present');
		ELSE
			SELECT table_name INTO v_TableName FROM dba_indexes WHERE owner = 'ELNPROD' AND index_name = 'TEXT_IDX_INV_CHEMICAL';
			IF	(v_TableName != 'INV_CHEMICAL')	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: index elnprod.text_idx_inv_chemical is present but on the wrong table ('||v_TableName||', expected: INV_CHEMICAL)');
			ELSE						DBMS_OUTPUT.PUT_LINE('Index elnprod.text_idx_inv_chemical is present and on the correct table, inv_chemical');
			END IF;
		END IF;

		SELECT COUNT(*) INTO v_Count FROM dba_procedures WHERE owner = 'ELNPROD' AND object_name = 'INV_CHEMICALUPDATEINDEX' AND object_type = 'PROCEDURE';
		IF	(v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('Procedure elnprod.inv_chemicalupdateindex is present');
		ELSE				DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: Procedure elnprod.inv_chemicalupdateindex is NOT present');
		END IF;

		SELECT COUNT(*) INTO v_Count FROM dba_procedures WHERE owner = 'ELNPROD' AND object_name = 'INV_CHEMICAL_UPDATE' AND object_type = 'TRIGGER';
		IF	(v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('Trigger elnprod.inv_chemical_update is present');
		ELSE				DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: Trigger elnprod.inv_chemical_update is NOT present');
		END IF;

		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('.'); 
		DBMS_OUTPUT.PUT_LINE('LMS: 0521CMN.wts');
		DBMS_OUTPUT.PUT_LINE('.');
		t_TableList := ObjList('INV_CHEMICAL','INV_CHEMICALA0');
		t_ColumnList := ObjList('GENERIC4','GENERIC5','GENERIC6','GENERIC7','GENERIC8','GENERIC9','GENERIC10','GENERIC11','GENERIC12','GENERIC13','GENERIC14','GENERIC15','GENERIC16','GENERIC17','GENERIC18','GENERIC19','GENERIC20','GENERICNUM4','GENERICNUM5','GENERICDATE4','GENERICDATE5','CONFIGURATIONID','STATUS','CONTAINERTOTAL','CONTAINERREST');
		FOR indx IN 1 .. t_TableList.COUNT
		LOOP
			FOR indx2 IN 1 .. t_ColumnList.COUNT
			LOOP
				SELECT COUNT(*) INTO v_Count FROM dba_tab_cols WHERE owner = 'ELNPROD' AND table_name = t_TableList(indx) AND column_name = t_ColumnList(indx2);
				IF	(v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('Column '||t_ColumnList(indx2) ||' was added to elnprod.'||t_TableList(indx));
				ELSIF	(v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: Column '||t_ColumnList(indx2) ||' was NOT added to elnprod.'||t_TableList(indx));
				END IF;
			END LOOP;
		END LOOP;

		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('.'); 
		DBMS_OUTPUT.PUT_LINE('LMS: 0522CMN.wts');
		DBMS_OUTPUT.PUT_LINE('.');
		SELECT COUNT(*) INTO v_Count FROM dba_tab_privs WHERE owner = 'NGSDMS60' AND table_name = 'NGTAGS' AND grantee = 'ELNPROD' AND privilege = 'SELECT';
		IF	(v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('Elnprod was granted Select on ngsdms60.ngtags');
		ELSE				DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: Elnprod was NOT granted Select on ngsdms60.ngtags');
		END IF;

		SELECT COUNT(*) INTO v_Count FROM dba_tab_privs WHERE owner = 'NGSDMS60' AND table_name = 'NGPROJDEFS' AND grantee = 'ELNPROD' AND privilege = 'SELECT';
		IF	(v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('Elnprod was granted Select on ngsdms60.ngprojdefs');
		ELSE				DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: Elnprod was NOT granted Select on ngsdms60.ngprojdefs');
		END IF;

		SELECT COUNT(*) INTO v_Count FROM dba_views WHERE owner = 'ELNPROD' AND view_name = 'VW_SDMSPROJECTINFO';
		IF	(v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('View elnprod.vw_sdmsprojectinfo is present');
		ELSE				DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: View elnprod.vw_sdmsprojectinfo is NOT present');
		END IF;

		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('.'); 
		DBMS_OUTPUT.PUT_LINE('LMS: 0523CMN.wts');
		DBMS_OUTPUT.PUT_LINE('.');
		SELECT COUNT(*) INTO v_Count FROM dba_procedures WHERE owner = 'ELNPROD' AND object_name = 'FN_CONVERT_BLOB2CLOB' AND object_type = 'FUNCTION';
		IF	(v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('Function elnprod.fn_convert_blob2clob is present');
		ELSE				DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: Function elnprod.fn_convert_blob2clob is NOT present');
		END IF;

		SELECT COUNT(*) INTO v_Count FROM dba_views WHERE owner = 'ELNPROD' AND view_name = 'VW_SYSTEMFIELDCONFIGURATIONS';
		IF	(v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('View elnprod.vw_systemfieldconfigurations is present');
		ELSE				DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: View elnprod.vw_systemfieldconfigurations is NOT present');
		END IF;

		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('.'); 
		DBMS_OUTPUT.PUT_LINE('LMS: 0524DRG.wts');
		DBMS_OUTPUT.PUT_LINE('.');
		t_SystemTypeIDs := ObjList('INVENTORYCOLS','INVENTORYCOLS');
		t_ValueCodes    := ObjList('INSTRUMENTS','REAGENTSANDSOLVENTS');

		FOR indx IN 1 .. t_SystemTypeIDs.COUNT
		LOOP
			SELECT COUNT(*) INTO v_Count FROM elnprod.systemvalues WHERE systemtypeid = t_SystemTypeIDs(indx) AND valuecode = t_ValueCodes(indx);
			IF	(v_Count = 1)	THEN
				DBMS_OUTPUT.PUT_LINE('Systemtypeid '||t_SystemTypeIDs(indx)||' and valuecode '||t_ValueCodes(indx)||' was added to elnprod.systemvalues');
				SELECT intvalue INTO v_IntValue FROM elnprod.systemvalues WHERE systemtypeid = t_SystemTypeIDs(indx) AND valuecode = t_ValueCodes(indx);
				IF v_IntValue IS NULL THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: '||t_SystemTypeIDs(indx)||'/'||t_ValueCodes(indx)||' was added to elnprod.systemalues but intvalue is Null');
				ELSE
					SELECT COUNT(*) INTO v_Count FROM elnprod.binaryobject WHERE binaryobjid = v_IntValue;
					IF	(v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE(t_SystemTypeIDs(indx)||'/'||t_ValueCodes(indx)||' was successfully added to elnprod.systemvalues');
					ELSE				DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: '||t_SystemTypeIDs(indx)||'/'||t_ValueCodes(indx)||' was added to elnprod.systemvalues but there is no matching entry in elnprod.binaryobject');
					END IF;
				END IF;
			ELSE	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: '||t_SystemTypeIDs(indx)||'/'||t_ValueCodes(indx)||' was NOT added to elnprod.systemvalues');
			END IF;
		END LOOP;

		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('.'); 
		DBMS_OUTPUT.PUT_LINE('LMS: 0525DRG.wts');
		DBMS_OUTPUT.PUT_LINE('.');
		SELECT COUNT(*) INTO v_Count FROM elnprod.systemvalues WHERE systemtypeid = 'DRG_SYSTEM' AND valuecode = 'INSTR_EVENTTYPE';
		IF	(v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('DRG_SYSTEM/INSTR_EVENTTYPE was added to elnprod.systemvalues');
		ELSE				DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: DRG_SYSTEM/INSTR_EVENTTYPE was NOT added to elnprod.systemvalues');
		END IF;

		SELECT COUNT(*) INTO v_Count FROM elnprod.domain WHERE domainid = 'Instrument Event Types';
		IF	(v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: List ''Instrument Event Types'' is NOT present');
		ELSE
			DBMS_OUTPUT.PUT_LINE('List ''Instrument Event Types'' is present');
			t_ListEntries := ObjList('CALIBRATION','MAINTENANCE','VERIFICATION','OTHER','MEASUREMENT','DEACTIVATION');
			FOR indx IN 1 .. t_ListEntries.COUNT
			LOOP
				SELECT COUNT(*) INTO v_Count FROM elnprod.domainvalue WHERE domainid = 'Instrument Event Types' AND value = t_ListEntries(indx);
				IF	(v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('-- value '||t_ListEntries(indx)||' is present');
				ELSE				DBMS_OUTPUT.PUT_LINE('-- !!! WARNING: value '||t_ListEntries(indx)||' is NOT present');
				END IF;
			END LOOP;
		END IF;

		SELECT COUNT(*) INTO v_Count FROM dba_procedures WHERE owner = 'ELNPROD' AND object_name = 'DOMAIN_BEFORE_UPDATE' AND object_type = 'TRIGGER';
		IF	(v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('Trigger elnprod.domain_before_update is present');
		ELSE				DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: Trigger elnprod.domain_before_update is NOT present');
		END IF;

		SELECT COUNT(*) INTO v_Count FROM dba_procedures WHERE owner = 'ELNPROD' AND object_name = 'DOMAINVALUE_BEFORE_UPDATE' AND object_type = 'TRIGGER';
		IF	(v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('Trigger elnprod.domainvalue_before_update is present');
		ELSE				DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: Trigger elnprod.domainvalue_before_update is NOT present');
		END IF;

		SELECT longalphavalue INTO v_BookInEvent FROM elnprod.systemvalues WHERE systemtypeid = 'DRG_SYSTEM' aND valuecode = 'CHEM_BOOKIN';
		DBMS_OUTPUT.PUT_LINE('Reagent ''Book in'' event:'||v_BookInEvent);

		SELECT alphavalue INTO v_ReagentEventsList FROM elnprod.systemvalues WHERE systemtypeid = 'DRG_SYSTEM' AND valuecode = 'CHEM_EVENTTYPE';
		DBMS_OUTPUT.PUT_LINE('List for reagent event types: '||v_ReagentEventsList);

		SELECT COUNT(*) INTO v_Count FROM elnprod.domainvalue WHERE domainid = v_ReagentEventsList AND value = v_BookInEvent;
		IF	(v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('The reagents book-in event is in the list');
		ELSE				DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: the reagents book-in event is NOT in the list');
		END IF;

		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('.'); 
		DBMS_OUTPUT.PUT_LINE('LMS: 0526DRG.wts');
		DBMS_OUTPUT.PUT_LINE('.');
		t_ViewNames := ObjList('VIEW_INSTRUMENTS','VIEW_CHEMICALS','VIEW_CHEMICALCOMPOUNDS');

		FOR indx IN 1 .. t_ViewNames.COUNT
		LOOP
			SELECT COUNT(*) INTO v_Count FROM dba_views WHERE owner = 'ELNPROD' AND view_name = t_ViewNames(indx) AND text_vc LIKE '%A.GENERIC20%';
			IF	(v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('View elnprod.'||t_ViewNames(indx)||' has been updated with the new generic fields');
			ELSIF	(v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: View elnprod.'||t_ViewNames(indx)||' has NOT been updated with the new generic fields');
			END IF;
		END LOOP;
	END IF;
END;
/

PROMPT
PROMPT ****************************************************************************************************************
PROMPT Verifying NuGenesis 9.1 Hotfix 2 Database Updates
PROMPT ****************************************************************************************************************
PROMPT

BEGIN
	DBMS_OUTPUT.PUT_LINE('NuGenesis LMS schema version: '||:v_LMSSchemaVer);
	IF	(:v_LMSSchemaVerAsNum < 9102)	THEN	DBMS_OUTPUT.PUT_LINE('NuGenesis version is less than 9.1 HF2, skipping these checks.');
	ELSE	DBMS_OUTPUT.PUT_LINE('NuGenesis version is greater than or equal to 9.1 HF2, starting verification of the NuGenesis 9.1 HF2 schema modifications.');
	END IF;
END;
/

DECLARE
v_Count		PLS_INTEGER := 0;

BEGIN
	IF (:v_LMSSchemaVerAsNum >= 9102)	THEN
		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('.'); 
		DBMS_OUTPUT.PUT_LINE('LMS: 0542DRG.wts');
		DBMS_OUTPUT.PUT_LINE('.');

		SELECT COUNT(*) INTO v_Count FROM elnprod.testresult WHERE resulttype IN ('NUMERIC','CALCULATED') AND numericalresulttext IS NOT NULL AND numericalresult != ROUND(numericalresultraw, precision);
		IF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('All Numeric and Calculated test results in LMS have the correct rounding as per their precision.');
		ELSIF (v_Count > 0)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: '||v_Count||' Numeric or Calculated test result(s) have incorrect rounding!');
		END IF;
	END IF;
END;
/

PROMPT
PROMPT ****************************************************************************************************************
PROMPT Verifying NuGenesis 9.2 Database Updates
PROMPT ****************************************************************************************************************
PROMPT

BEGIN
	DBMS_OUTPUT.PUT_LINE('NuGenesis LMS schema version: '||:v_LMSSchemaVer);
	IF	(:v_LMSSchemaVerAsNum < 9200)	THEN	DBMS_OUTPUT.PUT_LINE('NuGenesis version is less than 9.2, skipping these checks.');
	ELSE	DBMS_OUTPUT.PUT_LINE('NuGenesis version is greater than or equal to 9.2, starting verification of the NuGenesis 9.2 schema modifications.');
	END IF;
END;
/

DECLARE
TYPE CharList	IS TABLE OF VARCHAR2(500);
t_TableList	CharList;
v_Count		PLS_INTEGER := 0;
v_Count_920	PLS_INTEGER := 0;
v_Count_910	PLS_INTEGER := 0;
v_NGKeyValue	ngsysuser.ngconfig.ngkeyvalue%TYPE;
v_NGVersion	ngsysuser.ngschemainstalledinfo.ngversion%TYPE;
v_SDMSSchemaVer	ngsysuser.ngschemainstalledinfo.schemaver%TYPE;
v_NGDesc1	ngsysuser.ngschemainstalledinfo.ngdesc1%TYPE;

BEGIN
	IF (:v_LMSSchemaVerAsNum >= 9200 AND :v_LMSSchemaVerAsNum < 9300)	THEN -- Limit the checks in this section to v9.2.  It is likely that v9.3 will increment the version number to 930 which will render this code obsolete.
		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('.'); 
		DBMS_OUTPUT.PUT_LINE('SDMS: updateVersionSDMS.sql');
		DBMS_OUTPUT.PUT_LINE('.');

		t_TableList := CharList('NGUSERS','NGUSERSAUTHMODE','NGSERVERPROJINFO');
		FOR indx IN 1..t_TableList.COUNT
		LOOP
			EXECUTE IMMEDIATE ('SELECT COUNT(*) FROM ngsysuser.'||t_TableList(indx)) INTO v_Count;
			EXECUTE IMMEDIATE ('SELECT COUNT(*) FROM ngsysuser.'||t_TableList(indx)||' WHERE schemaver = 920') INTO v_Count_920;
			EXECUTE IMMEDIATE ('SELECT COUNT(*) FROM ngsysuser.'||t_TableList(indx)||' WHERE schemaver = 910') INTO v_Count_910;
			IF (v_Count_910 = 0)	THEN	DBMS_OUTPUT.PUT_LINE('-- No rows in ngsysuser.'||t_TableList(indx)||' have the schema version 910');
			ELSE				DBMS_OUTPUT.PUT_LINE('-- !!! WARNING: not all rows in ngsysuser.'||t_TableList(indx)||' have been updated to schema version 920!  No. rows: '||v_Count||'; no. rows with schemaver 920: '||v_Count_920||' no. rows with schemaver 910: '||v_Count_910);
			END IF;
		END LOOP;

		SELECT ngkeyvalue INTO v_NGKeyValue FROM ngsysuser.ngconfig WHERE ngsection = 'USERDBPARAMS' AND ngkeyid = 'SMTP_FROM';
		IF (v_NGKeyValue = 'NuGenesis_SDMS920')	THEN	DBMS_OUTPUT.PUT_LINE('-- The SMTP_FROM parameter has been updated to NuGenesis_SDMS920');
		ELSE						DBMS_OUTPUT.PUT_LINE('-- !!! WARNING: The SMTP_FROM parameter has not been updated to NuGenesis_SDMS920 (present value: '||v_NGKeyValue||')');
		END IF;

		SELECT ngkeyvalue INTO v_NGKeyValue FROM ngsysuser.ngconfig WHERE ngsection = 'MSLDBPARAMS' AND ngkeyid = 'BUILDNUMBER';
		IF (v_NGKeyValue = 'NG920')	THEN	DBMS_OUTPUT.PUT_LINE('-- The BUILDNUMBER parameter has been updated to NG920.');
		ELSE					DBMS_OUTPUT.PUT_LINE('-- !!! WARNING: the BULILDNUMBER parameter has not been updated to NG920 (present value: '||v_NGKeyValue||')');
		END IF;

		SELECT ngversion, schemaver, ngdesc1 INTO v_NGVersion, v_SDMSSchemaVer, v_NGDesc1 FROM ngsysuser.ngschemainstalledinfo;
		IF(v_NGVersion = 'SDMS920')	THEN	DBMS_OUTPUT.PUT_LINE('-- NGVersion in ngsysuser.ngschemainstalledinfo has been updated to SDMS920.');
		ELSE					DBMS_OUTPUT.PUT_LINE('-- !!! WARNING: the ngversion in ngsysuser.ngschemainstalledinfo has not been updated to SDMS920 (present info: '||v_NGVersion||')');
		END IF;

		IF(v_SDMSSchemaVer = 920)	THEN	DBMS_OUTPUT.PUT_LINE('-- Schemaver in ngsysuser.ngschemainstalledinfo has been updated to 920.');
		ELSE					DBMS_OUTPUT.PUT_LINE('-- !!! WARNING: schemaver in ngsysuser.ngschemainstalledinfo has not been updated to 920 (present info: '||v_SDMSSchemaVer||')');
		END IF;

		IF(v_NGVersion = 'SDMS920')	THEN	DBMS_OUTPUT.PUT_LINE('-- NGdesc1 in ngsysuser.ngschemainstalledinfo has been updated to ''SDMS920 SERVER INSTALLED''.');
		ELSE					DBMS_OUTPUT.PUT_LINE('-- !!! WARNING: the ngdesc1 in ngsysuser.ngschemainstalledinfo has not been updated to ''SDMS920 SERVER INSTALLED'' (present info: '||v_NGDesc1||')');
		END IF;
	ELSIF (:v_LMSSchemaVerAsNum >= 9300)	THEN	DBMS_OUTPUT.PUT_LINE('Installed schema version greater than 9.2, skipping this section.');
	END IF;
END;
/

DECLARE
v_Count		PLS_INTEGER := 0;
TYPE ObjList	IS TABLE OF VARCHAR2(500);
t_TableList	ObjList;
t_ColumnList	ObjList;
v_TableName	dba_indexes.table_name%TYPE;
v_IndexName	dba_indexes.index_name%TYPE;
v_ViewName	dba_views.view_name%TYPE;
t_SystemTypeIDs	ObjList;
t_ValueCodes	ObjList;
t_ListEntries	ObjList;
t_ProgramIDs	ObjList;
t_ProgramDescs	ObjList;
v_IntValue	PLS_INTEGER;
v_NumValue	NUMBER;
t_ViewNames	ObjList;
v_TempLong	LONG;
v_TempClob	CLOB;
v_TempBlob	BLOB;
BEGIN
	IF (:v_LMSSchemaVerAsNum >= 9200)	THEN
		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('.'); 
		DBMS_OUTPUT.PUT_LINE('LMS: 0528CMN.wts');
		DBMS_OUTPUT.PUT_LINE('.');

		v_TableName := 'INV_INSTRUMENTATTRIBUTE';
		v_IndexName := 'XPKINV_INSTRUMENTNATTRIBUTE'; -- Specify the index name here in full because an extra N in the name.
		SELECT COUNT(*) INTO v_Count FROM dba_tables WHERE owner = 'ELNPROD' AND table_name = v_TableName;
		IF(v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('-- table elnprod.'||v_TableName||' is present');
		ELSE			DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: table elnprod.'||v_TableName||' is NOT present!');
		END IF;

		v_TableName := v_TableName || 'A0';
		SELECT COUNT(*) INTO v_Count FROM dba_tables WHERE owner = 'ELNPROD' AND table_name = v_TableName;
		IF(v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('-- table elnprod.'||v_TableName||' is present');
		ELSE			DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: table elnprod.'||v_TableName||' is NOT present!');
		END IF;

		SELECT COUNT(*) INTO v_Count FROM dba_indexes WHERE owner = 'ELNPROD' AND index_name = v_IndexName;
		IF(v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('-- index elnprod.'||v_IndexName||' is present.');
		ELSE			DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: index elnprod.'||v_IndexName||' is NOT present!');
		END IF;

		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('.'); 
		DBMS_OUTPUT.PUT_LINE('LMS: 0529CMN.wts');
		DBMS_OUTPUT.PUT_LINE('.');
		v_TableName := 'INV_CHEMICALATTRIBUTE';
		v_IndexName := 'XPK' || v_TableName;
		SELECT COUNT(*) INTO v_Count FROM dba_tables WHERE owner = 'ELNPROD' AND table_name = v_TableName;
		IF(v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('-- table elnprod.'||v_TableName||' is present');
		ELSE			DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: table elnprod.'||v_TableName||' is NOT present!');
		END IF;

		v_TableName := v_TableName || 'A0';
		SELECT COUNT(*) INTO v_Count FROM dba_tables WHERE owner = 'ELNPROD' AND table_name = v_TableName;
		IF(v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('-- table elnprod.'||v_TableName||' is present');
		ELSE			DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: table elnprod.'||v_TableName||' is NOT present!');
		END IF;

		SELECT COUNT(*) INTO v_Count FROM dba_indexes WHERE owner = 'ELNPROD' AND index_name = v_IndexName;
		IF(v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('-- index elnprod.'||v_IndexName||' is present.');
		ELSE			DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: index elnprod.'||v_IndexName||' is NOT present!');
		END IF;

		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('.'); 
		DBMS_OUTPUT.PUT_LINE('LMS: 0530CMN.wts');
		DBMS_OUTPUT.PUT_LINE('.');
		v_TableName := 'INV_INSTRUMENT_SYSTEM';
		v_IndexName := 'XPK' || v_TableName;
		SELECT COUNT(*) INTO v_Count FROM dba_tables WHERE owner = 'ELNPROD' AND table_name = v_TableName;
		IF(v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('-- table elnprod.'||v_TableName||' is present');
		ELSE			DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: table elnprod.'||v_TableName||' is NOT present!');
		END IF;

		v_TableName := v_TableName || 'A0';
		SELECT COUNT(*) INTO v_Count FROM dba_tables WHERE owner = 'ELNPROD' AND table_name = v_TableName;
		IF(v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('-- table elnprod.'||v_TableName||' is present');
		ELSE			DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: table elnprod.'||v_TableName||' is NOT present!');
		END IF;

		SELECT COUNT(*) INTO v_Count FROM dba_indexes WHERE owner = 'ELNPROD' AND index_name = v_IndexName;
		IF(v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('-- index elnprod.'||v_IndexName||' is present.');
		ELSE			DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: index elnprod.'||v_IndexName||' is NOT present!');
		END IF;

		v_TableName := 'INV_INSTRUMENT_EXTENDED';
		v_IndexName := 'XPK' || v_TableName;
		SELECT COUNT(*) INTO v_Count FROM dba_tables WHERE owner = 'ELNPROD' AND table_name = v_TableName;
		IF(v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('-- table elnprod.'||v_TableName||' is present');
		ELSE			DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: table elnprod.'||v_TableName||' is NOT present!');
		END IF;

		v_TableName := v_TableName || 'A0';
		SELECT COUNT(*) INTO v_Count FROM dba_tables WHERE owner = 'ELNPROD' AND table_name = v_TableName;
		IF(v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('-- table elnprod.'||v_TableName||' is present');
		ELSE			DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: table elnprod.'||v_TableName||' is NOT present!');
		END IF;

		SELECT COUNT(*) INTO v_Count FROM dba_indexes WHERE owner = 'ELNPROD' AND index_name = v_IndexName;
		IF(v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('-- index elnprod.'||v_IndexName||' is present.');
		ELSE			DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: index elnprod.'||v_IndexName||' is NOT present!');
		END IF;

		v_ViewName := 'VIEW_INSTRUMENT_NODE';
		SELECT COUNT(*) INTO v_Count FROM dba_views WHERE owner = 'ELNPROD' AND view_name = v_ViewName;
		IF(v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('-- view elnprod.'||v_ViewName||' is present');
		ELSE			DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: view elnprod.'||v_ViewName||' is NOT present!');
		END IF;

		v_ViewName := 'VIEW_INSTRUMENT_SYSTEM';
		SELECT COUNT(*) INTO v_Count FROM dba_views WHERE owner = 'ELNPROD' AND view_name = v_ViewName;
		IF(v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('-- view elnprod.'||v_ViewName||' is present');
		ELSE			DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: view elnprod.'||v_ViewName||' is NOT present!');
		END IF;

		v_ViewName := 'VIEW_INSTRUMENTS'; -- In NuGenesis 9.2 view_instruments was modified to incorporate the new extended and system tables.
		SELECT COUNT(*) INTO v_Count FROM dba_views WHERE owner = 'ELNPROD' AND view_name = v_ViewName;
		IF(v_Count = 1)	THEN
			DBMS_OUTPUT.PUT_LINE('-- view elnprod.'||v_ViewName||' is present');
			SELECT text INTO v_TempLong FROM dba_views WHERE owner = 'ELNPROD' AND view_name = v_ViewName;

			v_TableName := 'INV_INSTRUMENT_EXTENDED';
			IF (INSTR(v_TempLong, v_TableName) > 0)	THEN	DBMS_OUTPUT.PUT_LINE('-- -- has been updated to include '||v_TableName);
			ELSE						DBMS_OUTPUT.PUT_LINE('-- -- !!!!! ERROR: has NOT been updated with '||v_TableName);
			END IF;

			v_TableName := 'VIEW_INSTRUMENT_SYSTEM';
			IF (INSTR(v_TempLong, v_TableName) > 0)	THEN	DBMS_OUTPUT.PUT_LINE('-- -- has been updated to include '||v_TableName);
			ELSE						DBMS_OUTPUT.PUT_LINE('-- -- !!!!! ERROR: has NOT been updated with '||v_TableName);
			END IF;

			v_TableName := 'INV_INSTRUMENT_SYSTEM';
			IF (INSTR(v_TempLong, v_TableName) > 0)	THEN	DBMS_OUTPUT.PUT_LINE('-- -- has been updated to include '||v_TableName);
			ELSE						DBMS_OUTPUT.PUT_LINE('-- -- !!!!! ERROR: has NOT been updated with '||v_TableName);
			END IF;
		ELSE							DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: view elnprod.'||v_ViewName||' is NOT present!');
		END IF;

		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('.'); 
		DBMS_OUTPUT.PUT_LINE('LMS: 0531DRG.wts');
		DBMS_OUTPUT.PUT_LINE('.');
		t_ColumnList := ObjList('COLINSTRUMENTNODENAME','COLINSTRUMENTNODETYPE','COLINSTRUMENTNODELOCATION','COLINSTRUMENTNODECOMMENTS','COLINSTRUMENTNODEISAVAILABLE','COLINSTRUMENTSYSTEMCOMMENT','COLINSTRUMENTSYSTEMLOCATION','COLINSTRUMENTSYSTEMSTATUS','COLINSTRUMENTSYSTEMFITFORUSE','COLINSTRUMENTSTATUS','COLINSTRUMENTSOURCE','COLINSTRUMENTLASTSYNCDATE','COLINSTRUMENTSYSTEMFITFORUSESTATUS','COLINSTRUMENTSYSTEMFITFORUSEDESCRIPTION','COLINSTRUMENTLASTSERVICEDATE','COLINSTRUMENTNEXTSERVICEDATE','COLINSTRUMENTFIRMWAREVERSION','COLINSTRUMENTSOFTWAREVERSION');
		SELECT COUNT(*) INTO v_Count FROM elnprod.systemvalues WHERE systemtypeid = 'INVENTORYCOLS' AND valuecode = 'INSTRUMENTS';
		IF (v_Count = 0) THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: the instrument column configurations are not present in the database!');
		ELSIF (v_Count = 1) THEN -- The data is in a BLOB column, so run the standard checks on BLOB data before examining the BLOB.
			SELECT intvalue INTO v_IntValue FROM elnprod.systemvalues WHERE systemtypeid = 'INVENTORYCOLS' AND valuecode = 'INSTRUMENTS';
			IF (v_IntValue IS NULL) THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: the instrument column config has a NULL binary object reference!');
			ELSE
				SELECT COUNT(*) INTO v_Count FROM elnprod.binaryobject WHERE binaryobjid = TO_CHAR(v_IntValue);
				IF (v_Count = 0) THEN	DBMS_OUTPUT.PUT_LINE('ERROR: the instrument column config contains an invalid reference to a BLOB!');
				ELSE
					SELECT binaryobjdata INTO v_TempBlob FROM elnprod.binaryobject WHERE binaryobjid = TO_CHAR(v_IntValue);
					IF (v_TempBlob IS NULL OR DBMS_LOB.GETLENGTH(v_TempBlob) = 0) THEN	DBMS_OUTPUT.PUT_LINE('* !!!!!! ERROR: the binary object for the instrument column config is NULL or is 0 bytes in length!');
					ELSE
						DBMS_LOB.CREATETEMPORARY(v_TempClob, TRUE);
						DBMS_LOB.CONVERTTOCLOB(v_TempClob, v_TempBlob, DBMS_LOB.GETLENGTH(v_TempBlob), :v_BlobConv_Offset, :v_BlobConv_Offset, :v_BlobConv_CSID, :v_BlobConv_Lang, :v_BlobConv_Warning);

						FOR indx IN 1..t_ColumnList.COUNT
						LOOP
							IF(INSTR(v_TempClob,t_ColumnList(indx)) > 0)	THEN	DBMS_OUTPUT.PUT_LINE('-- '||t_ColumnList(indx)||' has been added to the Instruments column config');
							ELSE							DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: '||t_ColumnList(indx)||' has NOT been added to the Instruments column config!');
							END IF;
						END LOOP;
					END IF;
				END IF;
			END IF;
		END IF;

		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('.'); 
		DBMS_OUTPUT.PUT_LINE('LMS: 0532DRG.wts');
		DBMS_OUTPUT.PUT_LINE('.');
		SELECT COUNT(*) INTO v_Count FROM elnprod.systemvalues WHERE systemtypeid = 'DRG_SYSTEM' AND valuecode = 'DASHBOARDSEARCHRECORDS';
		IF (v_Count = 1)	THEN
			DBMS_OUTPUT.PUT_LINE('''DASHBOARDSEARCHRECORDS'' has been added to elnprod.systemvalues');
			SELECT intvalue, numvalue INTO v_IntValue, v_NumValue FROM elnprod.systemvalues WHERE systemtypeid = 'DRG_SYSTEM' AND valuecode = 'DASHBOARDSEARCHRECORDS';
			DBMS_OUTPUT.PUT_LINE('-- numvalue='||v_NumValue||'; intvalue='||v_IntValue);
		ELSIF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: ''DASHBOARDSEARCHRECORDS'' has NOT been added to elnprod.systemvalues!');
		END IF;

		t_SystemTypeIDs := ObjList('DASHBOARD','DASHBOARD','DASHBOARD','DASHBOARD','DASHBOARD','DASHBOARD');
		t_ValueCodes    := ObjList('INSTRUMENTS','REAGENTSANDSOLVENTS','SAMPLES','REQUESTS','TESTS','SUBMISSIONS');
		FOR indx IN 1..t_SystemTypeIDs.COUNT
		LOOP
			SELECT COUNT(*) INTO v_Count FROM elnprod.systemvalues WHERE systemtypeid = t_SystemTypeIDs(indx) AND valuecode = t_ValueCodes(indx);
			IF (v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('-- system type ID '||t_SystemTypeIDs(indx)||' valuecode '||t_ValueCodes(indx)||' is present');
			ELSIF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: system type ID '||t_SystemTypeIDs(indx)||' valuecode '||t_ValueCodes(indx)||' is NOT present');
			END IF;
		END LOOP;

		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('.'); 
		DBMS_OUTPUT.PUT_LINE('LMS: 0533CMN.wts');
		DBMS_OUTPUT.PUT_LINE('.');
		v_TableName := 'MRULIST';
		v_IndexName := 'XUK' || v_TableName;
		SELECT COUNT(*) INTO v_Count FROM dba_tables WHERE owner = 'ELNPROD' AND table_name = v_TableName;
		IF(v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('-- table elnprod.'||v_TableName||' is present');
		ELSE			DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: table elnprod.'||v_TableName||' is NOT present!');
		END IF;

		v_TableName := v_TableName || 'A0';
		SELECT COUNT(*) INTO v_Count FROM dba_tables WHERE owner = 'ELNPROD' AND table_name = v_TableName;
		IF(v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('-- table elnprod.'||v_TableName||' is present');
		ELSE			DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: table elnprod.'||v_TableName||' is NOT present!');
		END IF;

		SELECT COUNT(*) INTO v_Count FROM dba_indexes WHERE owner = 'ELNPROD' AND index_name = v_IndexName;
		IF(v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('-- index elnprod.'||v_IndexName||' is present.');
		ELSE			DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: index elnprod.'||v_IndexName||' is NOT present!');
		END IF;
		
		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('.'); 
		DBMS_OUTPUT.PUT_LINE('LMS: 0534DRG.wts');
		DBMS_OUTPUT.PUT_LINE('.');
		t_ProgramIDs   := ObjList('DRG00280','DRG00284','DRG00282');
		t_ProgramDescs := ObjList('Empower Project Viewer','Empower Configuration Manager Viewer','Empower Review Viewer');

		FOR indx IN 1..t_ProgramIDs.COUNT
		LOOP
			SELECT COUNT(*) INTO v_Count FROM elnprod.screenprogram WHERE programid = t_ProgramIDs(indx) AND descriptionprogram = t_ProgramDescs(indx);
			IF (v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('-- Program ID '||t_ProgramIDs(indx)||', '||t_ProgramDescs(indx)||' is present in elnprod.screenprogram');
			ELSIF (v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: Program ID '||t_ProgramIDs(indx)||', '||t_ProgramDescs(indx)||' is NOT present in elnprod.screenprogram');
			END IF;

			SELECT COUNT(*) INTO v_Count FROM elnprod.groupprogram WHERE programid = t_ProgramIDs(indx);
			IF (v_Count> 0)		THEN	DBMS_OUTPUT.PUT_LINE('-- Program ID '||t_ProgramIDs(indx)||' is present in elnprod.groupprogram');
			ELSIF (v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: Program ID '||t_ProgramIDs(indx)||' is NOT present in elnprod.groupprogram');
			END IF;

			DBMS_OUTPUT.PUT_LINE('.');
		END LOOP;


		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('.'); 
		DBMS_OUTPUT.PUT_LINE('LMS: 0535DRG.wts');
		DBMS_OUTPUT.PUT_LINE('.');
		t_SystemTypeIDs := ObjList('EMPOWER_DBACCESS','EMPOWER_DBACCESS','EMPOWER_DBACCESS','EMPOWER_DBACCESS','EMPOWER_DBACCESS','EMPOWER_DBACCESS');
		t_ValueCodes    := ObjList('DEFAULTUSER','DBUSER','CLIENTINFO','LANG_CHARSET-J','LANG_CHARSET-C','LANG_CHARSET-K');
		FOR indx IN 1..t_SystemTypeIDs.COUNT
		LOOP
			SELECT COUNT(*) INTO v_Count FROM elnprod.systemvalues WHERE systemtypeid = t_SystemTypeIDs(indx) AND valuecode = t_ValueCodes(indx);
			IF (v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('-- system type ID '||t_SystemTypeIDs(indx)||' valuecode '||t_ValueCodes(indx)||' is present');
			ELSIF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: system type ID '||t_SystemTypeIDs(indx)||' valuecode '||t_ValueCodes(indx)||' is NOT present');
			END IF;
		END LOOP;
	END IF;
END;
/

DECLARE
v_Count		PLS_INTEGER := 0;
v_Count2	PLS_INTEGER := 0;
TYPE ObjList	IS TABLE OF VARCHAR2(500);
TYPE NumList	IS TABLE OF NUMBER;
t_TableList	ObjList;
t_ColumnList	ObjList;
v_TableName	dba_indexes.table_name%TYPE;
v_IndexName	dba_indexes.index_name%TYPE;
v_ViewName	dba_views.view_name%TYPE;
t_SystemTypeIDs	ObjList;
t_ValueCodes	ObjList;
t_ListEntries	ObjList;
t_ProgramIDs	ObjList;
t_ProgramDescs	ObjList;
t_ParamNums	NumList;
t_ParamNames	ObjList;
v_IntValue	PLS_INTEGER;
t_ViewNames	ObjList;
v_TempLong	LONG;
v_TempClob	CLOB;
v_TempBlob	BLOB;
v_ScheduleID	elnprod.jobschedule.scheduleid%TYPE;
v_JobName	elnprod.jobschedule.name%TYPE;
t_NotificationIDs	ObjList;
t_LabGrpIDs	ObjList;
BEGIN
	IF (:v_LMSSchemaVerAsNum >= 9200)	THEN
		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('.'); 
		DBMS_OUTPUT.PUT_LINE('LMS: 0536DRG.wts');
		DBMS_OUTPUT.PUT_LINE('.');
		SELECT COUNT(*) INTO v_Count FROM elnprod.systemvalues WHERE systemtypeid = 'LDAPSERVER' AND valuecode = 'SEARCHDN';
		SELECT COUNT(*) INTO v_Count2 FROM elnprod.systemvalues WHERE systemtypeid = 'LDAPSERVER' AND valuecode = 'BASEDN';
		IF (v_Count = 1 AND v_Count2 = 0)	THEN	DBMS_OUTPUT.PUT_LINE('-- Systemtypeid LDAPSERVER, valuecode BASEDN has been renamed to SEARCHDN');
		ELSE						DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: Systemtypeid LDAPSERVER, valuecode BASEDN was NOT renamed to SEARCHDN!');
		END IF;

		SELECT COUNT(*) INTO v_Count FROM elnprod.systemvalues WHERE systemtypeid = 'LDAPSERVER' AND valuecode = 'AUTHATTRIBUTE';
		SELECT COUNT(*) INTO v_Count2 FROM elnprod.systemvalues WHERE systemtypeid = 'LDAPSERVER' AND valuecode = 'LDAPFILTER';
		IF (v_Count = 1 AND v_Count2 = 0)	THEN	DBMS_OUTPUT.PUT_LINE('-- Systemtypeid LDAPSERVER, valuecode LDAPFILTER has been renamed to AUTHATTRIBUTE');
		ELSE						DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: Systemtypeid LDAPSERVER, valuecode LDAPFILTER was NOT renamed to AUTHATTRIBUTE!');
		END IF;

		SELECT COUNT(*) INTO v_Count FROM elnprod.systemvalues WHERE systemtypeid = 'LDAPSERVER' AND valuecode = 'AUTHTYPE';
		IF (v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('-- Systemtypeid LDAPSERVER, valuecode AUTHTYPE has been added to elnprod.systemvalues');
		ELSE						DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: Systemtypeid LDAPSERVER, valuecode AUTHTYPE was NOT added to elnprod.systemvalues!');
		END IF;

		t_SystemTypeIDs := ObjList('LDAPSERVER','LDAPSERVER','LDAPSERVER','LDAPSERVER','LDAPSERVER','LDAPSERVER','LDAPSERVER','LDAPSERVER');
		t_ValueCodes    := ObjList('SEARCHFILTER_FIXED_2','LDAPFACTORYCLASS','LDAPPACKAGE','LDAPVERSION','READTIMEOUT','SEARCHFILTER_DOMAIN','SEARCHFILTER_FIXED_1','SEARCHFILTER_FIXED_2','SECURITYAUTH','USERDN');
		FOR indx IN 1..t_SystemTypeIDs.COUNT
		LOOP
			SELECT COUNT(*) INTO v_Count FROM elnprod.systemvalues WHERE systemtypeid = t_SystemTypeIDs(indx) AND valuecode = t_ValueCodes(indx);
			IF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('-- system type ID '||t_SystemTypeIDs(indx)||' valuecode '||t_ValueCodes(indx)||' has been deleted');
			ELSIF (v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('-- !!! WARNING: system type ID '||t_SystemTypeIDs(indx)||' valuecode '||t_ValueCodes(indx)||' has NOT been deleted!');
			END IF;
		END LOOP;

		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('.'); 
		DBMS_OUTPUT.PUT_LINE('LMS: 0537DRG.wts');
		DBMS_OUTPUT.PUT_LINE('.');
		SELECT COUNT(*) INTO v_Count FROM elnprod.jobtypes WHERE jobcategory = 'EMPOWER' AND jobtype = 'GETINSTRUMENTS';
		IF (v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('-- The ''GETINSTRUMENTS'' jobtype has been added to elnprod.jobtypes');
		ELSIF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: The ''GETINSTRUMENTS'' jobtypes has NOT been added to elnprod.jobtypes');
		END IF;

		SELECT COUNT(*) INTO v_Count FROM elnprod.jobschedule WHERE jobcategory = 'EMPOWER' AND jobtype = 'GETINSTRUMENTS';
		IF (v_Count = 1)	THEN	
			DBMS_OUTPUT.PUT_LINE('-- The ''GETINSTRUMENTS'' job has been added to elnprod.jobschedule');
			SELECT scheduleid, name INTO v_ScheduleID, v_JobName FROM elnprod.jobschedule WHERE jobcategory = 'EMPOWER' AND jobtype = 'GETINSTRUMENTS';
			DBMS_OUTPUT.PUT_LINE('-- -- Schedule ID: '||v_ScheduleID);
			DBMS_OUTPUT.PUT_LINE('-- -- Job name   : '||v_JobName);
		ELSIF (v_Count = 0)	THEN
			DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: The ''GETINSTRUMENTS'' job has NOT been added to elnprod.jobschedule');
			v_ScheduleID := NULL;
		END IF;

		t_ParamNums := NumList (1,2,3);
		t_ParamNames := ObjList ('COLINSTRUMENTNAME','COLINSTRUMENTMANUFACTURER','COLINSTRUMENTCOMMENT');
		FOR indx IN 1..t_ParamNums.COUNT
		LOOP
			SELECT COUNT(*) INTO v_Count FROM elnprod.jobscheduleparams WHERE scheduleid = v_ScheduleID AND paramnr = t_ParamNums(indx) AND paramname = t_ParamNames(indx);
			IF (v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('-- -- Param '||t_ParamNums(indx)||' name is '||t_ParamNames(indx));
			ELSIF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('-- -- !!!!! ERROR: Param '||t_ParamNums(indx)||' name is NOT '||t_ParamNames(indx));
			END IF;
		END LOOP;

		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('.'); 
		DBMS_OUTPUT.PUT_LINE('LMS: 0538CMN.wts');
		DBMS_OUTPUT.PUT_LINE('.');
		SELECT COUNT(*) INTO v_Count FROM elnprod.jobtypes WHERE jobcategory = 'ELN' AND jobtype = 'CREATEINSTRUMENTS';
		IF (v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('-- The ''CREATEINSTRUMENTS'' jobtype has been added to elnprod.jobtypes');
		ELSIF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: The ''CREATEINSTRUMENTS'' jobtypes has NOT been added to elnprod.jobtypes');
		END IF;

		v_TableName := 'INV_INSTRUMENT_HUB';
		v_IndexName := 'XPK' || v_TableName;
		SELECT COUNT(*) INTO v_Count FROM dba_tables WHERE owner = 'ELNPROD' AND table_name = v_TableName;
		IF(v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('-- table elnprod.'||v_TableName||' is present');
		ELSE			DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: table elnprod.'||v_TableName||' is NOT present!');
		END IF;

		v_TableName := v_TableName || 'A0';
		IF (:v_LMSSchemaVerAsNum >= 9300)	THEN	DBMS_OUTPUT.PUT_LINE('-- table elnprod.'||v_TableName||' is not present.  This table was removed in NG 9.3.');
		ELSE
			SELECT COUNT(*) INTO v_Count FROM dba_tables WHERE owner = 'ELNPROD' AND table_name = v_TableName;
			IF(v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('-- table elnprod.'||v_TableName||' is present');
			ELSE			DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: table elnprod.'||v_TableName||' is NOT present!');
			END IF;
		END IF;

		SELECT COUNT(*) INTO v_Count FROM dba_indexes WHERE owner = 'ELNPROD' AND index_name = v_IndexName;
		IF(v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('-- index elnprod.'||v_IndexName||' is present.');
		ELSE			DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: index elnprod.'||v_IndexName||' is NOT present!');
		END IF;

		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('.'); 
		DBMS_OUTPUT.PUT_LINE('LMS: 0540DRG.wts');
		DBMS_OUTPUT.PUT_LINE('.');
		t_SystemTypeIDs := ObjList('INV_FITFORUSE','INV_FITFORUSE','INV_FITFORUSE');
		t_ValueCodes    := ObjList('ACCEPTABLE','WARNING','CRITICAL');
		FOR indx IN 1..t_SystemTypeIDs.COUNT
		LOOP
			SELECT COUNT(*) INTO v_Count FROM elnprod.systemvalues WHERE systemtypeid = t_SystemTypeIDs(indx) AND valuecode = t_ValueCodes(indx);
			IF (v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('-- system type ID '||t_SystemTypeIDs(indx)||' valuecode '||t_ValueCodes(indx)||' is present');
			ELSIF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('-- !!! WARNING: system type ID '||t_SystemTypeIDs(indx)||' valuecode '||t_ValueCodes(indx)||' is NOT present');
			END IF;
		END LOOP;

		SELECT COUNT(*) INTO v_Count FROM dba_views WHERE owner = 'ELNPROD' AND view_name = 'VIEW_INSTRUMENTSYSTEMFITFORUSELIST';
		IF (v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('-- View elnprod.view_instrumentsystemfitforuselist is present');
		ELSIF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: view elnprod.view_instrumentsystemfitforuselist is NOT present');
		END IF;

		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('.'); 
		DBMS_OUTPUT.PUT_LINE('LMS: 0541DRG.wts');
		DBMS_OUTPUT.PUT_LINE('.');
		t_NotificationIDs := ObjList('INVGETEMPINSTRERROR','INVCREATEINSTRERROR','INVGETEMPINSTROK','INVCREATEINSTROK','INVEMPSYSTEMDELETED','INVEMPINSTRDELETED');
		FOR indx IN 1..t_NotificationIDs.COUNT
		LOOP
			SELECT COUNT(*) INTO v_Count FROM elnprod.labgroupnotifications WHERE notificationid = t_NotificationIDs(indx) AND labgrpid IS NULL;
			IF (v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('-- Notification ID '||t_NotificationIDs(indx)||', labgrpid NULL has been added to elnprod.labgroupnotifications');
			ELSIF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: Notification ID '||t_NotificationIDs(indx)||', labgrpid NULL has NOT been added to elnprod.labgroupnotifications');
			END IF;
		END LOOP;

		-- 0542DRG is handled by the 9.1 Hotfix1 and 2 checks. 0543DRG.wts is handled in the next PLSQL block.

		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('.'); 
		DBMS_OUTPUT.PUT_LINE('LMS: 0544DRG.wts');
		DBMS_OUTPUT.PUT_LINE('.');
		SELECT COUNT(*) INTO v_Count FROM elnprod.jobtypes WHERE jobcategory = 'EMPOWER' AND jobtype = 'CHECKFITFORUSE';
		IF (v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('-- The ''CHECKFITFORUSE'' jobtype has been added to elnprod.jobtypes');
		ELSIF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: The ''CHECKFITFORUSE'' jobtypes has NOT been added to elnprod.jobtypes');
		END IF;

		SELECT COUNT(*) INTO v_Count FROM elnprod.jobschedule WHERE jobcategory = 'EMPOWER' AND jobtype = 'CHECKFITFORUSE';
		IF (v_Count = 1)	THEN	
			DBMS_OUTPUT.PUT_LINE('-- The ''CHECKFITFORUSE'' job has been added to elnprod.jobschedule');
			SELECT scheduleid, name INTO v_ScheduleID, v_JobName FROM elnprod.jobschedule WHERE jobcategory = 'EMPOWER' AND jobtype = 'CHECKFITFORUSE';
			DBMS_OUTPUT.PUT_LINE('-- -- Schedule ID: '||v_ScheduleID);
			DBMS_OUTPUT.PUT_LINE('-- -- Job name   : '||v_JobName);
		ELSIF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: The ''Empowr System Fit-for-Use check'' job has NOT been added to elnprod.jobschedule');
		END IF;

		t_ParamNums := NumList (1);
		t_ParamNames := ObjList ('FITFORUSEEVENTCOMMENT');
		FOR indx IN 1..t_ParamNums.COUNT
		LOOP
			SELECT COUNT(*) INTO v_Count FROM elnprod.jobscheduleparams WHERE scheduleid = v_ScheduleID AND paramnr = t_ParamNums(indx) AND paramname = t_ParamNames(indx);
			IF (v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('-- -- Param '||t_ParamNums(indx)||' name is '||t_ParamNames(indx));
			ELSIF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('-- -- !!!!! ERROR: Param '||t_ParamNums(indx)||' name is NOT '||t_ParamNames(indx));
			END IF;
		END LOOP;
	END IF;
END;
/

DECLARE
v_Count		PLS_INTEGER := 0;
TYPE ObjList	IS TABLE OF VARCHAR2(500);
TYPE RawList	IS TABLE OF RAW(2000);
t_TableList	ObjList;
t_ColumnList	ObjList;
t_ReportNames	ObjList;
t_ReportHashesE	RawList;
t_ReportHashesC	RawList;
t_ReportHashesJ	RawList;
t_ReportHashesK	RawList;
v_ReportHash	RAW(2000);
v_SQLQuery	VARCHAR2(4000 CHAR);
BEGIN
	IF (:v_LMSSchemaVerAsNum >= 9300)	THEN	DBMS_OUTPUT.PUT_LINE('LMS schema version is 9.3 or greater, skipping these checks.');
	ELSIF (:v_LMSSchemaVerAsNum >= 9200 AND :v_LMSSchemaVerAsNum < 9300)	THEN
		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('.'); 
		DBMS_OUTPUT.PUT_LINE('LMS: 0543DRG.wts');
		DBMS_OUTPUT.PUT_LINE('.');
		t_ReportNames   := ObjList('InstrumentAuditRep',                      'ChemistryAuditRep',                       'InstrumentsReport',                       'SubmissionReport',                        'Submission_Shipment');
		t_ReportHashesE := RawList('404AFAEB684E5CE3561AD0BC1E7E88E6959BF91D','29D13FF9B32938BCF07CF010495DA8BB5295B072','9089FCA4F84BA9F4D2D266BA478F0400EDA5A23C','E60312BE18FCEA43A893762216ACB588F716ADC3','A88A22F83C3D49785556E99E386584BEBDF07B8B');
		FOR indx IN 1..t_ReportNames.COUNT
		LOOP
			SELECT COUNT(*) INTO v_Count FROM elnprod.reportconfiguration WHERE reportname = t_ReportNames(indx);
			IF (v_Count = 1)	THEN
				DBMS_OUTPUT.PUT_LINE('-- Report '||t_ReportNames(indx)||' is present');
				v_SQLQuery := 'SELECT dbms_crypto.hash(binobj.binaryobjdata, 3) FROM elnprod.reportconfiguration rpt, elnprod.binaryobject binobj WHERE rpt.defaultreportref = binobj.binaryobjid AND rpt.reportname = '''||t_ReportNames(indx)||'''';
				EXECUTE IMMEDIATE v_SQLQuery INTO v_ReportHash;
				IF (v_ReportHash = t_ReportHashesE(indx))	THEN	DBMS_OUTPUT.PUT_LINE('-- -- The SHA1 hash for the default report template matches the known value for LMS 9.2');
				ELSE							DBMS_OUTPUT.PUT_LINE('-- -- WARNING: the SHA1 hash for the default report template does NOT match any of the known values for v9.2!');
				END IF;
			ELSIF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: Report '||t_ReportNames(indx)||' is NOT present');
			END IF;
		END LOOP;
	END IF;
EXCEPTION
	WHEN OTHERS THEN
		DBMS_OUTPUT.PUT_LINE(SQLCODE);
		DBMS_OUTPUT.PUT_LINE(SQLERRM);
		DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: Unable to verify the updated report templates from 0543DRG.wts');
END;
/

PROMPT
PROMPT ****************************************************************************************************************
PROMPT Verifying NuGenesis 9.2 Hotfix 1 Database Updates
PROMPT ****************************************************************************************************************
PROMPT

BEGIN
	DBMS_OUTPUT.PUT_LINE('NuGenesis LMS schema version: '||:v_LMSSchemaVer);
	IF	(:v_LMSSchemaVerAsNum < 9201)	THEN	DBMS_OUTPUT.PUT_LINE('NuGenesis version is less than 9.2 Hotfix 1, skipping these checks.');
	ELSE	DBMS_OUTPUT.PUT_LINE('NuGenesis version is greater than or equal to 9.2 Hotfix 1, starting verification of the NuGenesis 9.2 Hotfix 1 schema modifications.');
	END IF;
END;
/

DECLARE
v_Count		NUMBER;
v_TempLong	LONG;
v_TableName	VARCHAR2(200 CHAR);
TYPE ObjList	IS TABLE OF VARCHAR2(500);
t_ViewNames	ObjList;
v_SQLQuery	VARCHAR2(4000 CHAR);

BEGIN
	IF (:v_LMSSchemaVerAsNum >= 9201)	THEN
		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('.'); 
		DBMS_OUTPUT.PUT_LINE('LMS: 0545CMN.wts');
		DBMS_OUTPUT.PUT_LINE('.');
		SELECT COUNT(*) INTO v_Count FROM dba_tables WHERE owner = 'ELNPROD' AND table_name = 'INV_INSTRUMENT_HUBA0';
		IF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('-- Table elnprod.inv_instrument_huba0 has been dropped');
		ELSIF (v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: table elnprod.inv_instrument_huba0 ha NOT been dropped.');
		END IF;

		v_SQLQuery := 'SELECT COUNT(*) FROM elnprod.inv_instrument_hub WHERE consumerjobid IS NOT NULL AND consumerjobid NOT IN (SELECT jobid FROM elnprod.jobs)';
		EXECUTE IMMEDIATE v_SQLQuery INTO v_Count;
		IF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('-- Old jobs have been removed from elnprod.inv_insrtument_hub.');
		ELSIF (v_Count > 0)	THEN	DBMS_OUTPUT.PUT_LINE('-- !!! WARNING: '||v_Count||' old record(s) exist in elnprod.inv_instrument_hub.  These records do not sorrespond to a background job and may degrade the performance of the instrument hub.');
		END IF;

		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('.'); 
		DBMS_OUTPUT.PUT_LINE('LMS: 0546CMN.wts');
		DBMS_OUTPUT.PUT_LINE('.');
		SELECT COUNT(*) INTO v_Count FROM dba_tables WHERE owner = 'ELNPROD' AND table_name = 'INV_INSTRUMENT_SYNC';
		IF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: table elnprod.inv_instrument_sync is NOT present');
		ELSIF (v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('-- Table elnprod.inv_instrument_sync is present.');
		END IF;

		SELECT COUNT(*) INTO v_Count FROM dba_tab_cols WHERE owner = 'ELNPROD' AND table_name = 'INV_INSTRUMENT_SYSTEM' AND column_name = 'LASTSYNCDATE';
		IF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('-- Column ''LASTSYNCDATE'' has been dropped from elnprod.in_instrument_system');
		ELSIF (v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: column ''LASTSYNCDATE'' has NOT  been dropped from elnprod.inv_instrument_sysytem.');
		END IF;
		
		SELECT COUNT(*) INTO v_Count FROM dba_tab_cols WHERE owner = 'ELNPROD' AND table_name = 'INV_INSTRUMENT_SYSTEMA0' AND column_name = 'LASTSYNCDATE';
		IF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('-- Column ''LASTSYNCDATE'' has been dropped from elnprod.in_instrument_systema0');
		ELSIF (v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: column ''LASTSYNCDATE'' has NOT  been dropped from elnprod.inv_instrument_systema0.');
		END IF;

		SELECT COUNT(*) INTO v_Count FROM dba_tab_cols WHERE owner = 'ELNPROD' AND table_name = 'INV_INSTRUMENT_EXTENDED' AND column_name = 'LASTSYNCDATE';
		IF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('-- Column ''LASTSYNCDATE'' has been dropped from elnprod.in_instrument_extended');
		ELSIF (v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: column ''LASTSYNCDATE'' has NOT  been dropped from elnprod.inv_instrument_extended.');
		END IF;

		SELECT COUNT(*) INTO v_Count FROM dba_tab_cols WHERE owner = 'ELNPROD' AND table_name = 'INV_INSTRUMENT_EXTENDEDA0' AND column_name = 'LASTSYNCDATE';
		IF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('-- Column ''LASTSYNCDATE'' has been dropped from elnprod.in_instrument_extendeda0');
		ELSIF (v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: column ''LASTSYNCDATE'' has NOT  been dropped from elnprod.inv_instrument_extendeda0.');
		END IF;

		SELECT COUNT(*) INTO v_Count FROM dba_indexes WHERE owner = 'ELNPROD' AND table_name = 'INV_INSTRUMENT_SYNC' AND index_name = 'XUKINV_INSTRUMENT_SYNC';
		IF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: index elnprod.xukinv_instrument_sync is NOT present');
		ELSIF (v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('-- Index elnprod.xukinv_instrument_sync is present.');
		END IF;

		DBMS_OUTPUT.PUT_LINE('.');
		v_TableName := 'INV_INSTRUMENT_SYNC';
		t_ViewNames := ObjList('VIEW_INSTRUMENT_NODE','VIEW_INSTRUMENT_SYSTEM','VIEW_INSTRUMENTS');
		SELECT text INTO v_TempLong FROM dba_views WHERE owner = 'ELNPROD' AND view_name = 'VIEW_INSTRUMENT_NODE';
		FOR indx IN 1..t_ViewNames.COUNT
		LOOP
			IF (INSTR(v_TempLong, v_TableName) > 0)	THEN	DBMS_OUTPUT.PUT_LINE('-- View '|| t_ViewNames(indx)|| ' has been updated to include '||v_TableName);
			ELSE						DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: view '||t_ViewNames(indx)||' has NOT been updated with '||v_TableName);
			END IF;
		END LOOP;

	END IF;
END;
/

PROMPT
PROMPT ****************************************************************************************************************
PROMPT Verifying NuGenesis 9.3.0 Database Updates
PROMPT ****************************************************************************************************************
PROMPT

BEGIN
	DBMS_OUTPUT.PUT_LINE('NuGenesis LMS schema version: '||:v_LMSSchemaVer);
	IF	(:v_LMSSchemaVerAsNum < 9300)	THEN	DBMS_OUTPUT.PUT_LINE('NuGenesis version is less than 9.3, skipping these checks.');
	ELSE	DBMS_OUTPUT.PUT_LINE('NuGenesis version is greater than or equal to 9.3, starting verification of the NuGenesis 9.3 schema modifications.');
	END IF;
END;
/

DECLARE
v_Count		NUMBER;
v_TempLong	LONG;
v_TableName	VARCHAR2(200 CHAR);
v_IntValue	NUMBER;
TYPE CharList	IS TABLE OF VARCHAR2(500);
t_ViewNames	CharList;
t_ColumnList	CharList;
v_SystemValues	elnprod.systemvalues%ROWTYPE;
v_SystemTypes	elnprod.systemtype%ROWTYPE;
CURSOR		C_EmpowerDBMapEntries IS SELECT * FROM elnprod.systemvalues WHERE systemtypeid = 'EMPOWER_DBVERSIONMAP';
CURSOR		C_EmpowerDBListInLMS  IS SELECT * FROM elnprod.systemtype WHERE systemtypeid LIKE 'EMPOWER_DB%';
v_TempClob	CLOB;
v_TempBlob	BLOB;

BEGIN
	IF (:v_LMSSchemaVerAsNum >= 9300)	THEN
		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('LMS: 0547CMN.wts');
		DBMS_OUTPUT.PUT_LINE('.');

		SELECT COUNT(*) INTO v_Count FROM dba_sys_privs WHERE grantee = 'ELNPROD' AND privilege = 'CREATE ANY MATERIALIZED VIEW';
		IF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('-- System privilege CREATE ANY MATERIALIZED VIEW has been removed from elnprod.');
		ELSE				DBMS_OUTPUT.PUT_LINE('-- !!! WARNING: System privilege CREATE ANY MATERIALIZED VIEW has NOT been removed from elnprod.');
		END IF;

		SELECT COUNT(*) INTO v_Count FROM dba_sys_privs WHERE grantee = 'ELNPROD' AND privilege = 'ON COMMIT REFRESH';
		IF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('-- System privilege ON COMMIT REFRESH has been removed from elnprod.');
		ELSE				DBMS_OUTPUT.PUT_LINE('-- !!! WARNING: System privilege ON COMMIT REFRESH has NOT been removed from elnprod.');
		END IF;
		SELECT COUNT(*) INTO v_Count FROM dba_sys_privs WHERE grantee = 'ELNPROD' AND privilege = 'CREATE ANY VIEW';
		IF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('-- System privilege CREATE ANY VIEW has been removed from elnprod.');
		ELSE				DBMS_OUTPUT.PUT_LINE('-- !!! WARNING: System privilege CREATE ANY VIEW has NOT been removed from elnprod.');
		END IF;

		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('LMS: 0548CMN.wts');
		DBMS_OUTPUT.PUT_LINE('.');

		SELECT COUNT(*) INTO v_Count FROM elnprod.systemvalues WHERE systemtypeid = 'EMPOWER_DBVERSIONMAP';
		IF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: the Empower DB version map is NOT present in elnprod.systemvalues!');
		ELSE
			DBMS_OUTPUT.PUT_LINE('The Empower DB version map is present in elnprod.systemvalues.');
			OPEN C_EmpowerDBMapEntries;
			LOOP
				FETCH C_EmpowerDBMapEntries INTO v_SystemValues;
				EXIT WHEN C_EmpowerDBMapEntries%NOTFOUND;

				DBMS_OUTPUT.PUT_LINE('-- '||v_SystemValues.valuecode||' (DB version: '||v_SystemValues.alphavalue||'; intvalue: '||v_SystemValues.intvalue||'; numvalue: '||v_SystemValues.numvalue||'; service pack: '||v_SystemValues.longalphavalue||')');
			END LOOP;
			CLOSE C_EmpowerDBMapEntries;
		END IF;

		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('LMS: 0549CMN.wts');
		DBMS_OUTPUT.PUT_LINE('.');
		
		SELECT COUNT(*) INTO v_Count FROM elnprod.systemtype WHERE systemtypeid LIKE 'EMPOWER_DB%';
		IF (v_Count = 0)			THEN	DBMS_OUTPUT.PUT_LINE('There are no Empower systems defined in LMS.');
		ELSE
			DBMS_OUTPUT.PUT_LINE('Number of Empower systems defined in LMS: '||v_Count);
			OPEN C_EmpowerDBListInLMS;
			LOOP
				FETCH C_EmpowerDBListInLMS INTO v_SystemTypes;
				EXIT WHEN C_EmpowerDBListInLMS%NOTFOUND;

				SELECT COUNT(*) INTO v_Count FROM elnprod.systemvalues WHERE systemtypeid = v_SystemTypes.systemtypeid AND valuecode = 'INVENTORYSYNC';
				IF (v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('-- System value "INVENTORYSYNC" has been added to Empower database '||v_SystemTypes.systemtypedescription);
				ELSE				DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: system value "INVENTORYSYNC" has NOT been added to Empower database '||v_SystemTypes.systemtypedescription);
				END IF;
			END LOOP;
			CLOSE C_EmpowerDBListInLMS;
		END IF;

		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('.'); 
		DBMS_OUTPUT.PUT_LINE('LMS: 0550DRG.wts');
		DBMS_OUTPUT.PUT_LINE('.');
		t_ColumnList := charList('COLINSTRUMENTSYSTEMDATABASE');
		SELECT COUNT(*) INTO v_Count FROM elnprod.systemvalues WHERE systemtypeid = 'INVENTORYCOLS' AND valuecode = 'INSTRUMENTS';
		IF (v_Count = 0) THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: the instrument column configurations are not present in the database!');
		ELSIF (v_Count = 1) THEN -- The data is in a BLOB column, so run the standard checks on BLOB data before examining the BLOB.
			SELECT intvalue INTO v_IntValue FROM elnprod.systemvalues WHERE systemtypeid = 'INVENTORYCOLS' AND valuecode = 'INSTRUMENTS';
			IF (v_IntValue IS NULL) THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: the instrument column config has a NULL binary object reference!');
			ELSE
				SELECT COUNT(*) INTO v_Count FROM elnprod.binaryobject WHERE binaryobjid = TO_CHAR(v_IntValue);
				IF (v_Count = 0) THEN	DBMS_OUTPUT.PUT_LINE('ERROR: the instrument column config contains an invalid reference to a BLOB!');
				ELSE
					SELECT binaryobjdata INTO v_TempBlob FROM elnprod.binaryobject WHERE binaryobjid = TO_CHAR(v_IntValue);
					IF (v_TempBlob IS NULL OR DBMS_LOB.GETLENGTH(v_TempBlob) = 0) THEN	DBMS_OUTPUT.PUT_LINE('* !!!!!! ERROR: the binary object for the instrument column config is NULL or is 0 bytes in length!');
					ELSE
						DBMS_LOB.CREATETEMPORARY(v_TempClob, TRUE);
						:v_BlobConv_Offset := 1;
						DBMS_LOB.CONVERTTOCLOB(v_TempClob, v_TempBlob, DBMS_LOB.GETLENGTH(v_TempBlob), :v_BlobConv_Offset, :v_BlobConv_Offset, :v_BlobConv_CSID, :v_BlobConv_Lang, :v_BlobConv_Warning);

						FOR indx IN 1..t_ColumnList.COUNT
						LOOP
							IF(INSTR(v_TempClob,t_ColumnList(indx)) > 0)	THEN	DBMS_OUTPUT.PUT_LINE('-- '||t_ColumnList(indx)||' has been added to the Instruments column config');
							ELSE							DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: '||t_ColumnList(indx)||' has NOT been added to the Instruments column config!');
							END IF;
						END LOOP;
					END IF;
				END IF;
			END IF;
		END IF;

		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('.'); 
		DBMS_OUTPUT.PUT_LINE('LMS: InstallLMSViews.sql');
		DBMS_OUTPUT.PUT_LINE('.');

		v_TableName := 'INV_INSTRUMENT_SYNC'; -- In NuGenesis 9.3 three views were modified to incorporate the instrment sync tables.
		t_ViewNames := CharList('VIEW_INSTRUMENTS','VIEW_INSTRUMENT_SYSTEM','VIEW_INSTRUMENT_NODE');
		FOR indx IN 1..t_ViewNames.COUNT
		LOOP
			SELECT COUNT(*) INTO v_Count FROM dba_views WHERE owner = 'ELNPROD' AND view_name = t_ViewNames(indx);
			IF(v_Count = 1)	THEN
				DBMS_OUTPUT.PUT_LINE('-- view elnprod.'||t_ViewNames(indx)||' is present');
				SELECT text INTO v_TempLong FROM dba_views WHERE owner = 'ELNPROD' AND view_name = t_ViewNames(indx);

				IF (INSTR(v_TempLong, v_TableName) > 0)	THEN	DBMS_OUTPUT.PUT_LINE('-- -- has been updated to include '||v_TableName);
				ELSE						DBMS_OUTPUT.PUT_LINE('-- -- !!!!! ERROR: has NOT been updated with '||v_TableName);
				END IF;
			ELSE							DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: view elnprod.'||t_ViewNames(indx)||' is NOT present!');
			END IF;
		END LOOP;
	END IF;
END;
/

DECLARE
v_Count		NUMBER;
v_Count_910	NUMBER;
v_Count_930	NUMBER;
v_NGKeyValue	ngsysuser.ngconfig.ngkeyvalue%TYPE;
v_NGVersion	ngsysuser.ngschemainstalledinfo.ngversion%TYPE;
v_SDMSSchemaVer	ngsysuser.ngschemainstalledinfo.schemaver%TYPE;
v_NGDesc1	ngsysuser.ngschemainstalledinfo.ngdesc1%TYPE;
v_TempLong	LONG;
v_TableName	VARCHAR2(200 CHAR);
TYPE CharList	IS TABLE OF VARCHAR2(500);
t_ViewNames	CharList;
t_TableList	CharList;
v_SystemValues	elnprod.systemvalues%ROWTYPE;
v_SystemTypes	elnprod.systemtype%ROWTYPE;
v_TempClob	CLOB;
v_TempBlob	BLOB;

BEGIN
	IF (:v_LMSSchemaVerAsNum >= 9300)	THEN
		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('.'); 
		DBMS_OUTPUT.PUT_LINE('SDMS: ngauditmaster.sql');
		DBMS_OUTPUT.PUT_LINE('.');

		SELECT COUNT(*) INTO v_Count FROM dba_indexes WHERE owner = 'NGSYSUSER' AND index_name = 'NGAUDITMASTERCLU_IDX3';
		IF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: index ngsysuser.ngaudtmasterclu_idx3 does not exist!');
		ELSE
			DBMS_OUTPUT.PUT_LINE('Index ngsysuser.ngauditmasterclu_idx3 exists');
			SELECT table_name INTO v_TableName FROM dba_indexes WHERE owner = 'NGSYSUSER' AND index_name = 'NGAUDITMASTERCLU_IDX3';
			IF (v_TableName = 'NGAUDITMASTER')	THEN	DBMS_OUTPUT.PUT_LINE('-- is on the correct table (expected: ngauditmaster)');
			ELSE						DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: is on the wrong table: '||v_TableName||' (expected: ngauditmaster)');
			END IF;
		END IF;

		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('.'); 
		DBMS_OUTPUT.PUT_LINE('SDMS: nguserpreferences.sql');
		DBMS_OUTPUT.PUT_LINE('.');

		SELECT COUNT(*) INTO v_Count FROM dba_tables WHERE owner = 'NGSDMS60' AND table_name = 'NGUSERPREFERENCES';
		IF (v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('Table ngsdms60.nguserpreferences exists');
		ELSE				DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: table ngsdms60.nguserpreferences does NOT exist!');
		END IF;

		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('.'); 
		DBMS_OUTPUT.PUT_LINE('SDMS: getindexedcolumns.sql');
		DBMS_OUTPUT.PUT_LINE('.');

		SELECT COUNT(*) INTO v_Count FROM dba_procedures WHERE owner = 'NGSDMS60' AND object_name = 'GETINDEXEDCOLUMNS' AND object_type = 'PROCEDURE';
		IF (v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('Procedure ngsdms60.getindexedcolumns exists');
		ELSE				DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: procedure ngsdms60.getindexedcolumns does NOT exist!');
		END IF;

		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('.'); 
		DBMS_OUTPUT.PUT_LINE('SDMS: updateVersionSDMS.sql');
		DBMS_OUTPUT.PUT_LINE('.');

		IF (:v_LMSSchemaVerAsNum > 9300)	THEN	DBMS_OUTPUT.PUT_LINE('N/A: schema version greater than v9.3.0');
		ELSE
			t_TableList := CharList('NGUSERS','NGUSERSAUTHMODE','NGSERVERPROJINFO');
			FOR indx IN 1..t_TableList.COUNT
			LOOP
				EXECUTE IMMEDIATE ('SELECT COUNT(*) FROM ngsysuser.'||t_TableList(indx)) INTO v_Count;
				EXECUTE IMMEDIATE ('SELECT COUNT(*) FROM ngsysuser.'||t_TableList(indx)||' WHERE schemaver = 930') INTO v_Count_930;
				EXECUTE IMMEDIATE ('SELECT COUNT(*) FROM ngsysuser.'||t_TableList(indx)||' WHERE schemaver = 910') INTO v_Count_910;
				IF (v_Count_910 = 0)	THEN	DBMS_OUTPUT.PUT_LINE('-- No rows in ngsysuser.'||t_TableList(indx)||' have the schema version 910');
				ELSE				DBMS_OUTPUT.PUT_LINE('-- !!! WARNING: not all rows in ngsysuser.'||t_TableList(indx)||' have been updated to schema version 930!  No. rows: '||v_Count||'; no. rows with schemaver 930: '||v_Count_930||' no. rows with schemaver 910: '||v_Count_910);
				END IF;
			END LOOP;

			SELECT ngkeyvalue INTO v_NGKeyValue FROM ngsysuser.ngconfig WHERE ngsection = 'USERDBPARAMS' AND ngkeyid = 'SMTP_FROM';
			IF (v_NGKeyValue = 'NuGenesis_SDMS930' OR v_NGKeyValue NOT LIKE 'NuGenesis_SDMS%')	THEN	DBMS_OUTPUT.PUT_LINE('-- The SMTP_FROM parameter has been updated to NuGenesis_SDMS930 (present value: '||v_NGKeyValue||')');
			ELSE												DBMS_OUTPUT.PUT_LINE('-- !!! WARNING: The SMTP_FROM parameter has not been updated to NuGenesis_SDMS930 (present value: '||v_NGKeyValue||')');
			END IF;

			SELECT ngkeyvalue INTO v_NGKeyValue FROM ngsysuser.ngconfig WHERE ngsection = 'MSLDBPARAMS' AND ngkeyid = 'BUILDNUMBER';
			IF (v_NGKeyValue = 'NG930')	THEN	DBMS_OUTPUT.PUT_LINE('-- The BUILDNUMBER parameter has been updated to NG930.');
			ELSE					DBMS_OUTPUT.PUT_LINE('-- !!! WARNING: the BULILDNUMBER parameter has not been updated to NG930 (present value: '||v_NGKeyValue||')');
			END IF;

			SELECT ngversion, schemaver, ngdesc1 INTO v_NGVersion, v_SDMSSchemaVer, v_NGDesc1 FROM ngsysuser.ngschemainstalledinfo;
			IF(v_NGVersion = 'SDMS930')	THEN	DBMS_OUTPUT.PUT_LINE('-- NGVersion in ngsysuser.ngschemainstalledinfo has been updated to SDMS930.');
			ELSE					DBMS_OUTPUT.PUT_LINE('-- !!! WARNING: the ngversion in ngsysuser.ngschemainstalledinfo has not been updated to SDMS930 (present info: '||v_NGVersion||')');
			END IF;

			IF(v_SDMSSchemaVer = 930)	THEN	DBMS_OUTPUT.PUT_LINE('-- Schemaver in ngsysuser.ngschemainstalledinfo has been updated to 930.');
			ELSE					DBMS_OUTPUT.PUT_LINE('-- !!! WARNING: schemaver in ngsysuser.ngschemainstalledinfo has not been updated to 930 (present info: '||v_SDMSSchemaVer||')');
			END IF;

			IF(v_NGDesc1 = 'SDMS930 SERVER INSTALLED')	THEN	DBMS_OUTPUT.PUT_LINE('-- NGdesc1 in ngsysuser.ngschemainstalledinfo has been updated to ''SDMS930 SERVER INSTALLED''.');
			ELSE							DBMS_OUTPUT.PUT_LINE('-- !!! WARNING: the ngdesc1 in ngsysuser.ngschemainstalledinfo has not been updated to ''SDMS930 SERVER INSTALLED'' (present info: '||v_NGDesc1||')');
			END IF;
		END IF;
	END IF;
END;
/

PROMPT
PROMPT ****************************************************************************************************************
PROMPT Verifying NuGenesis 9.3.1 Database Updates
PROMPT ****************************************************************************************************************
PROMPT

BEGIN
	DBMS_OUTPUT.PUT_LINE('NuGenesis schema version: '||:v_LMSSchemaVerAsNum);
	IF	(:v_LMSSchemaVerAsNum < 9310)	THEN	DBMS_OUTPUT.PUT_LINE('NuGenesis version is less than 9.3.1, skipping these checks.');
	ELSE	DBMS_OUTPUT.PUT_LINE('NuGenesis version is greater than or equal to 9.3.1, starting verification of the NuGenesis 9.3.1 schema modifications.');
	END IF;
END;
/

DECLARE
v_Count		NUMBER;
v_TempLong	LONG;
v_TableName	VARCHAR2(200 CHAR);
v_IntValue	NUMBER;
v_Count_931	NUMBER;
v_Count_930	NUMBER;
v_NGKeyValue	ngsysuser.ngconfig.ngkeyvalue%TYPE;
v_NGVersion	ngsysuser.ngschemainstalledinfo.ngversion%TYPE;
v_SDMSSchemaVer	ngsysuser.ngschemainstalledinfo.schemaver%TYPE;
v_NGDesc1	ngsysuser.ngschemainstalledinfo.ngdesc1%TYPE;
TYPE CharList	IS TABLE OF VARCHAR2(500);
t_ViewNames	CharList;
t_TableList	CharList;
t_ColumnList	CharList;
v_SystemValues	elnprod.systemvalues%ROWTYPE;
v_SystemTypes	elnprod.systemtype%ROWTYPE;
v_TempClob	CLOB;
v_TempBlob	BLOB;

BEGIN
	IF (:v_LMSSchemaVerAsNum >= 9310)	THEN
		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('.'); 
		DBMS_OUTPUT.PUT_LINE('SDMS: ngauditmasterPartition.sql');
		DBMS_OUTPUT.PUT_LINE('.');

		IF (:v_Partitioning = 0)	THEN	DBMS_OUTPUT.PUT_LINE('N/A: partitioning not enabled in this database');
		ELSE
			SELECT COUNT(*) INTO v_Count FROM dba_tab_partitions WHERE table_owner = 'NGSYSUSER' AND table_name = 'NGAUDITMASTER';
			IF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: no partitions detected for table ngsysuser.ngauditmaster');
			ELSIF (v_Count > 0)	THEN	DBMS_OUTPUT.PUT_LINE('Table ngsysuser.ngauditmaster has been partitioned');
			END IF;

			SELECT COUNT(*) INTO v_Count FROM dba_tables WHERE owner = 'NGSYSUSER' AND table_name = 'NGAUDITMASTER1';
			IF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('Temporary table ngsysuser.ngauditmaster1 has been dropped');
			ELSIF (v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('!!! WARNING: temporary table ngsysuser.ngauditmaster has NOT been dropped!');
			END IF;
		END IF;

		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('.'); 
		DBMS_OUTPUT.PUT_LINE('SDMS: ngauditmasterIdx.sql');
		DBMS_OUTPUT.PUT_LINE('.');

		SELECT COUNT(*) INTO v_Count FROM dba_indexes WHERE owner = 'NGSYSUSER' AND index_name = 'NGAUDITMASTERCLU_IDX4';
		IF (v_Count = 1)		THEN	DBMS_OUTPUT.PUT_LINE('Index ngsysuser.ngaudtmasiterclu_idx4 is present');
		ELSIF (v_Count = 0)		THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: index ngsysuser.ngauditmasterclu_idx4 is NOT present');
		END IF;

		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('.'); 
		DBMS_OUTPUT.PUT_LINE('SDMS: updateVersionSDMS.sql');
		DBMS_OUTPUT.PUT_LINE('.');
		IF (:v_LMSSchemaVerAsNum > 9310)	THEN	DBMS_OUTPUT.PUT_LINE('N/A: schema version greater than v9.3.1');
		ELSE
			t_TableList := CharList('NGUSERS','NGUSERSAUTHMODE','NGSERVERPROJINFO');
			FOR indx IN 1..t_TableList.COUNT
			LOOP
				EXECUTE IMMEDIATE ('SELECT COUNT(*) FROM ngsysuser.'||t_TableList(indx)) INTO v_Count;
				EXECUTE IMMEDIATE ('SELECT COUNT(*) FROM ngsysuser.'||t_TableList(indx)||' WHERE schemaver = 930') INTO v_Count_930;
				EXECUTE IMMEDIATE ('SELECT COUNT(*) FROM ngsysuser.'||t_TableList(indx)||' WHERE schemaver = 931') INTO v_Count_931;
				IF (v_Count_930 = 0)	THEN	DBMS_OUTPUT.PUT_LINE('-- No rows in ngsysuser.'||t_TableList(indx)||' have the schema version 930');
				ELSE				DBMS_OUTPUT.PUT_LINE('-- !!! WARNING: not all rows in ngsysuser.'||t_TableList(indx)||' have been updated to schema version 931!  No. rows: '||v_Count||'; no. rows with schemaver 931: '||v_Count_931||' no. rows with schemaver 930: '||v_Count_930);
				END IF;
			END LOOP;

			SELECT ngkeyvalue INTO v_NGKeyValue FROM ngsysuser.ngconfig WHERE ngsection = 'USERDBPARAMS' AND ngkeyid = 'SMTP_FROM';
			IF (v_NGKeyValue = 'NuGenesis_SDMS931' OR v_NGKeyValue NOT LIKE 'NuGenesis_SDMS%')	THEN	DBMS_OUTPUT.PUT_LINE('-- The SMTP_FROM parameter has been updated to NuGenesis_SDMS931 (present value: '||v_NGKeyValue||')');
			ELSE												DBMS_OUTPUT.PUT_LINE('-- !!! WARNING: The SMTP_FROM parameter has not been updated to NuGenesis_SDMS931 (present value: '||v_NGKeyValue||')');
			END IF;

			SELECT ngkeyvalue INTO v_NGKeyValue FROM ngsysuser.ngconfig WHERE ngsection = 'MSLDBPARAMS' AND ngkeyid = 'BUILDNUMBER';
			IF (v_NGKeyValue = 'NG931')	THEN	DBMS_OUTPUT.PUT_LINE('-- The BUILDNUMBER parameter has been updated to NG931.');
			ELSE					DBMS_OUTPUT.PUT_LINE('-- !!! WARNING: the BULILDNUMBER parameter has not been updated to NG930 (present value: '||v_NGKeyValue||')');
			END IF;

			SELECT ngversion, schemaver, ngdesc1 INTO v_NGVersion, v_SDMSSchemaVer, v_NGDesc1 FROM ngsysuser.ngschemainstalledinfo;
			IF(v_NGVersion = 'SDMS931')	THEN	DBMS_OUTPUT.PUT_LINE('-- NGVersion in ngsysuser.ngschemainstalledinfo has been updated to SDMS931.');
			ELSE					DBMS_OUTPUT.PUT_LINE('-- !!! WARNING: the ngversion in ngsysuser.ngschemainstalledinfo has not been updated to SDMS931 (present info: '||v_NGVersion||')');
			END IF;

			IF(v_SDMSSchemaVer = 931)	THEN	DBMS_OUTPUT.PUT_LINE('-- Schemaver in ngsysuser.ngschemainstalledinfo has been updated to 931.');
			ELSE					DBMS_OUTPUT.PUT_LINE('-- !!! WARNING: schemaver in ngsysuser.ngschemainstalledinfo has not been updated to 931 (present info: '||v_SDMSSchemaVer||')');
			END IF;

			IF(v_NGDesc1 LIKE 'SDMS931%')	THEN	DBMS_OUTPUT.PUT_LINE('-- NGdesc1 in ngsysuser.ngschemainstalledinfo has been updated to '||v_NGDesc1||'.');
			ELSE							DBMS_OUTPUT.PUT_LINE('-- !!! WARNING: the ngdesc1 in ngsysuser.ngschemainstalledinfo has not been updated with ''SDMS931'' (present info: '||v_NGDesc1||')');
			END IF;
		END IF;
	END IF;
END;
/

PROMPT
PROMPT ________________________________________________________________________
PROMPT Checking the database for invalid oracle objects . . .
PROMPT 

DECLARE
v_Count		NUMBER;
v_objnm		SYS.DBA_OBJECTS.OBJECT_NAME%TYPE;
v_objtyp	SYS.DBA_OBJECTS.OBJECT_TYPE%TYPE;
v_objown	SYS.DBA_OBJECTS.OWNER%TYPE;

CURSOR C_INVALOBJ is SELECT OBJECT_NAME, OBJECT_TYPE, OWNER FROM DBA_OBJECTS WHERE STATUS != 'VALID' AND OBJECT_NAME NOT LIKE 'BIN%' ORDER BY 3, 1;

BEGIN
	SELECT COUNT(OBJECT_NAME) INTO v_Count FROM DBA_OBJECTS WHERE STATUS != 'VALID' AND OBJECT_NAME NOT LIKE 'BIN%' AND object_name NOT IN ('QUERYASM');
	IF (v_Count = 0) THEN	DBMS_OUTPUT.PUT_LINE('All objects in this database/PDB are valid.');
	ELSIF (v_Count > 0) THEN
		DBMS_OUTPUT.PUT_LINE('!!! WARNING: this database contains invalid objects!  Invalid objects which are not owned by the NuGenesis/SLIM schemas can be ignored.  Invalid objects can usually be repaired by running utlrp.sql');
		OPEN C_INVALOBJ;
		LOOP
			FETCH C_INVALOBJ INTO v_objnm, v_objtyp, v_objown;
			EXIT WHEN C_INVALOBJ%NOTFOUND;

			DBMS_OUTPUT.PUT_LINE('-- Owner: '||v_objown||'	Object: '||v_objnm||'	Type: '||v_objtyp);
		END LOOP;
		CLOSE C_INVALOBJ;
	END IF;
END;
/

PROMPT
PROMPT ________________________________________________________________________
PROMPT Checking for objects in NuGenesis tablespaces which are not owned by NuGenesis schema accounts . . .
PROMPT
DECLARE
v_Count		PLS_INTEGER := 0;
v_segnm		VARCHAR2(81);
v_segtyp	VARCHAR2(18);
v_tbs		VARCHAR2(30);
v_own		VARCHAR2(30);
v_tab		VARCHAR2(30);
v_lobcol	VARCHAR2(4000);

CURSOR C_OBJ IS		SELECT segment_name, segment_type, owner, tablespace_name FROM DBA_SEGMENTS WHERE owner NOT IN (SELECT username FROM dba_db_links WHERE owner = 'ELNPROD' UNION SELECT username FROM dba_users WHERE username IN ('ELNPROD','NGSYSUSER','NGSDMS60','WATERS')) AND (tablespace_name like 'SDMS%' OR tablespace_name like 'QDIS%');
CURSOR C_NonNGTables IS	SELECT owner, table_name, tablespace_name FROM dba_tables WHERE owner NOT IN ('NGSDMS60','NGSYSUSER','ELNPROD') AND (tablespace_name LIKE 'SDMS%' OR tablespace_name LIKE 'QDISR%');
BEGIN
	-- Change in rev 20: exclude objects which are owned by the users associated with db_links owned by elnprod.
	SELECT NVL(COUNT(SEGMENT_NAME),0) INTO v_Count FROM DBA_SEGMENTS WHERE owner NOT IN (SELECT username FROM dba_db_links WHERE owner = 'ELNPROD' UNION SELECT username FROM dba_users WHERE username IN ('ELNPROD','NGSYSUSER','NGSDMS60','WATERS')) AND (tablespace_name like 'SDMS%' OR tablespace_name like 'QDIS%');
	IF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('All segments in NuGenesis tablespaces are owned by NG schema accounts or by the username for an ELNPROD-owned DB link.');
	ELSIF (v_Count > 0)	THEN
		DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: objects which are not owned by the NuGenesis schema accounts are located in NuGenesis tablespaces!  The presence of these objects will cause the sdms upgrade to fail.  These objects must be moved or dropped prior to a migration.  The objects are listed below:');
		OPEN C_OBJ;
		LOOP
			FETCH C_OBJ INTO v_segnm, v_segtyp, v_own, v_tbs;
			EXIT WHEN C_OBJ%NOTFOUND;
			
			DBMS_OUTPUT.PUT_LINE(v_segtyp||': '||v_own||'.'||v_segnm||' in tablespace '||v_tbs);
			IF v_segtyp = 'INDEX' THEN
				SELECT TABLE_NAME INTO v_tab FROM dba_indexes WHERE index_name = v_segnm;
				DBMS_OUTPUT.PUT_LINE('-- indexed table:  '||v_tab);
			ELSIF v_segtyp = 'LOBSEGMENT' THEN
				SELECT TABLE_NAME, COLUMN_NAME INTO v_tab, v_lobcol FROM dba_lobs WHERE segment_name = v_segnm;
				DBMS_OUTPUT.PUT_LINE('-- LOB table and column:  '||v_tab||'.'||v_lobcol);
			ELSIF v_segtyp = 'LOBINDEX' THEN
				SELECT TABLE_NAME, COLUMN_NAME INTO v_tab, v_lobcol FROM dba_lobs WHERE index_name = v_segnm;
				DBMS_OUTPUT.PUT_LINE('-- LOB table and column:  '||v_tab||'.'||v_lobcol);
			END IF;
		END LOOP;
		CLOSE C_OBJ;
	END IF;
	-- change in rev 30: look for tables in NG tablespaces and not owned by an NG schema account
	-- rev 34: do not flag WATERS-owned tables in the NuGenesis schemas.
	DBMS_OUTPUT.PUT_LINE('.');
	DBMS_OUTPUT.PUT_LINE('Checking for tables in the NuGenesis tablespaces which have no rows.  Such tables would not have any segments and would not be identified by the previous query.');
	SELECT COUNT(*) INTO v_Count FROM dba_tables WHERE owner NOT IN ('NGSDMS60','NGSYSUSER','ELNPROD','WATERS') AND (tablespace_name LIKE 'SDMS%' OR tablespace_name LIKE 'QDISR%');
	IF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('All tables in NuGenesis tablespaces are owned by NG schema accounts.');
	ELSIF (v_Count > 0)	THEN
		OPEN C_NonNGTables;
		LOOP
			FETCH C_NonNGTables INTO v_own, v_tab, v_tbs;
			EXIT WHEN C_NonNGTables%NOTFOUND;

			DBMS_OUTPUT.PUT_LINE('Owner: '||v_own||'	Table: '||v_tab||'	Tablespace: '||v_tbs);
		END LOOP;
		CLOSE C_NonNGTables;
	END IF;
END;
/

PROMPT
PROMPT _________________________________________________________________________________
PROMPT Determining when the NuGenesis database schemas were last analyzed
PROMPT Statistics generated by analysis are used by Oracle to improve query performance
PROMPT
DECLARE
v_andate		DATE;
v_Count			PLS_INTEGER := 0;

BEGIN
	select MAX(LAST_ANALYZED) INTO v_andate FROM ALL_TAB_COL_STATISTICS WHERE owner = 'NGSDMS60';
	IF v_andate IS NULL THEN	DBMS_OUTPUT.PUT_LINE ('The ngsdms60 schema has never been subjected to analysis');
	ELSE				DBMS_OUTPUT.PUT_LINE ('The ngsdms60 schema was last analyzed on: '||v_andate);
	END IF;

	SELECT COUNT(ROWID) INTO v_Count FROM NGSDMS60.NGTAGS;
	DBMS_OUTPUT.PUT_LINE ('-- There are '||v_count||' rows in the ngsdms60.ngtags table');
	DBMS_OUTPUT.PUT_LINE ('.');

	select max(LAST_ANALYZED) INTO v_andate from ALL_TAB_COL_STATISTICS where owner = 'NGSYSUSER';
	IF v_andate IS NULL THEN	DBMS_OUTPUT.PUT_LINE ('The ngsysuser schema has never been subjected to analysis');
	ELSE				DBMS_OUTPUT.PUT_LINE ('The ngsysuser schema was last analyzed on: '||v_andate);
	END IF;

	DBMS_OUTPUT.PUT_LINE ('.');

	select max(LAST_ANALYZED) INTO v_andate from ALL_TAB_COL_STATISTICS where owner = 'ELNPROD';
	IF v_andate IS NULL THEN	DBMS_OUTPUT.PUT_LINE ('The elnprod schema has never been subjected to analysis');
	ELSE				DBMS_OUTPUT.PUT_LINE ('The elnprod schema was last analyzed on: '||v_andate);
	END IF;
END;
/

PROMPT BUFFER CACHE HIT RATIO:
SELECT 1 - (phy.value/(cur.value + con.value)) "HIT RATIO" from v$sysstat cur, v$sysstat con, v$sysstat phy WHERE cur.name = 'db block gets' and con.name = 'consistent gets' and phy.name = 'physical reads';

SPOOL OFF
