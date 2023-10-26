--------------------------------------------------------------------------------------------------------------------------------------------------------
--                                          WATERS CORP.
--
--				               nugenesis9_db_monitor_r5.sql
--
--  This script is for monitoring the nugenesis 9 and  Oracle 12/19 Database
-- 
--  PERSON			REVISION		DATE		REASON		 
--  DBREIDING			1			08-09-18	CREATION
--  DBREIDING			2			02-13-19	Update db_audit setting message
--  MMORRISON			3			2020-01-02	Delete some obsolete object checks.  Reported on installed patches.  Condense the Oracle Text checks (copied from r20 of the schema verify script).
-- 									Copy the background job checks from the schema_verify r20 script.
--  MMorrison			4			2020-10-15	Copy the SDMS and LMS schema version info code from the schema_verify r35 script.  Do not query for the version column when checking for patches.
--  MMorrison			5			2022-03-23	Report on the Oracle audit trail options and policies.  Report the NG container ID.  Switch to the cdbroot for the undo reporting.  Report on the
-- 									compatibility level of the CDB.  Report ADR parameters. Report the plsql_code_type init param. Correct the calculations of spaceallocations and
--									free space for data files and tablespaces.
--  MMorrison			6			2022-10-27	List the tablespace quotas.
--  MMorrison			7			2023-01-05	Move the TS checks to the end of the script, which results in only one container switch in the script.
--  MMorrison			8			2023-02-08	Report on dba_jobs owned by the NuGenesis schemas.
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

ALTER SESSION SET NLS_DATE_FORMAT = "MM/DD/YYYY";
COLUMN file NEW_VALUE file NOPRINT 
SELECT 'NuGenesis_9_db_monitor_r8_'||to_char(sysdate,'yyyy-mm-dd-hh24miss')||'.log' "file" FROM DUAL;
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
prompt           *      NuGenesis 9  Database Monitor Report          *
prompt           ******************************************************
prompt
prompt		  THIS SCRIPT MUST BE EXECUTED WITH DBA PRIVILEGES IN THE SDMS CONTAINER!
PROMPT
COLUMN CurrentUserName		FORMAT A50
SELECT SYS_CONTEXT('USERENV','CURRENT_USER') "CurrentUsername" FROM dual;
PROMPT
PROMPT ___________________________________________________________________________________________________________
PROMPT Oracle database and instance version info
PROMPT

SELECT BANNER FROM V$VERSION;
SELECT instance_name, host_name, status, archiver, database_status FROM v$instance;

PROMPT
PROMPT List of installed Oracle patches:
SELECT patch_id, status FROM sys.registry$sqlpatch;

COLUMN DBID HEADING "DATABASE ID"
COLUMN PLATFORM_NAME FORMAT A35 HEADING "OS"
COLUMN PLATFORM_ID HEADING "OS ID"
COLUMN CDB FORMAT A35 HEADING "CONTAINER DB"

PROMPT
SELECT cdb, con_id, open_mode, con_dbid, dbid, platform_name, platform_id, created, resetlogs_time FROM v$database;

PROMPT
PROMPT ___________________________________________________________________________________________________________
PROMPT SDMS and LMS schema version info
PROMPT

DECLARE
v_rel			VARCHAR2(64);
v_SDMSSchemaVer     	NGSYSUSER.NGCONFIG.NGKEYVALUE%TYPE;
v_LMSSchemaDate		ELNPROD.SYSTEMVALUES.ALPHAVALUE%TYPE;
v_valcodedesc		ELNPROD.SYSTEMVALUES.VALUECODEDESCRIPTION%TYPE;
v_SQLQuery		VARCHAR2(4000);

BEGIN
	SELECT NGKEYVALUE INTO v_SDMSSchemaVer FROM NGSYSUSER.NGCONFIG WHERE NGKEYID = 'BUILDNUMBER';
	SELECT SUBSTR(VERSION, 1, 4) INTO v_rel FROM PRODUCT_COMPONENT_VERSION WHERE PRODUCT LIKE 'Oracle%';
	SELECT TRIM(longalphavalue), VALUECODEDESCRIPTION, ALPHAVALUE INTO  :v_LMSSchemaVer, v_valcodedesc, v_LMSSchemaDate FROM ELNPROD.SYSTEMVALUES WHERE SYSTEMTYPEID = 'DRG_SYSTEM' AND VALUECODE = 'DB_BUILDINFO';

	DBMS_OUTPUT.PUT_LINE('SDMS schema version: '||v_SDMSSchemaVer);
	DBMS_OUTPUT.PUT_LINE('LMS schema version : '||:v_LMSSchemaVer||' / '||v_LMSSchemaDate|| ' / '||v_valcodedesc);

	DBMS_OUTPUT.PUT_LINE('.');

	DBMS_OUTPUT.PUT_LINE('Determining whether the optional NuGenesis modules are present in this database...');
	SELECT COUNT(TABLE_NAME) INTO :v_ConnTableCount FROM DBA_TABLES WHERE OWNER = 'ELNPROD'	AND TABLE_NAME LIKE 'CONNECTORS_%';
	IF (:v_ConnTableCount > 0)	THEN		DBMS_OUTPUT.PUT_LINE('-- The NuGenesis Connectors are installed.  Verification of the Connectors schema will be handled later in this script.');
	ELSE						DBMS_OUTPUT.PUT_LINE('-- The NuGenesis Connectors are NOT installed.');
	END IF;

	SELECT COUNT(*) INTO :v_SlimSchemaPresent FROM dba_users WHERE username = 'SLIM';
	IF (:v_SlimSchemaPresent = 1)	THEN		DBMS_OUTPUT.PUT_LINE('-- The NuGenesis Stability module is installed.  Verification of the Stability schema is in a separate script.');
	ELSE						DBMS_OUTPUT.PUT_LINE('-- The NuGenesis Stability module is NOT installed.');
	END IF;

	SELECT COUNT(*) INTO :v_WDMSchemaPresent FROM dba_users WHERE username = 'WATERS';
	IF (:v_WDMSchemaPresent = 1)	THEN		DBMS_OUTPUT.PUT_LINE('-- The Waters Database Manager is installed.  Verification of the WDM schema is in a separate script.');
	ELSE						DBMS_OUTPUT.PUT_LINE('-- The Waters Database Manager is NOT installed.');
	END IF;

	SELECT COUNT(*) INTO :v_SAPTableCount FROM dba_tables WHERE owner = 'ELNPROD' AND table_name LIKE 'IF_%';
	IF (:v_SAPTableCount > 0)	THEN		DBMS_OUTPUT.PUT_LINE('-- The LMS-SAP Interface is installed.  Verification of the SAP Interface schema will be handled later in this script.');
	ELSE						DBMS_OUTPUT.PUT_LINE('-- The LMS-SAP Interface is NOT installed.');
	END IF;

	DBMS_OUTPUT.PUT_LINE('.');

	-- Oracle 19c hides the full version number in the version_full column rather than in the version column.  Query the version_full colun as only 19.6 is supported.
	-- Use an execute statement here so that this check doesn't fail on Oracle 12 systems.
	v_SQLQuery := 'SELECT SUBSTR(version_full, 1, 4) FROM PRODUCT_COMPONENT_VERSION WHERE PRODUCT LIKE ''Oracle%'' ';
	IF (v_rel LIKE'19.0%')	THEN	EXECUTE IMMEDIATE v_SqlQuery INTO v_rel;
	END IF;

	IF	(v_SDMSSchemaVer LIKE 'NG90%')	THEN
		IF	(v_rel LIKE '12.2%' OR v_rel LIKE '19.6%')	THEN	DBMS_OUTPUT.PUT_LINE('This is an Oracle '||v_rel||' database.  This is a tested and certified version of Oracle Database for NuGenesis 9.0.');
		ELSE								DBMS_OUTPUT.PUT_LINE('!!! WARNING: NuGenesis 9.0 has not been tested or certified on version '||v_rel||'!');
		END IF;
	ELSIF	(v_SDMSSchemaVer LIKE 'NG91%')	THEN
		IF	(v_rel LIKE '19.6%')	THEN				DBMS_OUTPUT.PUT_LINE('This is an Oracle '||v_rel||' database.  This is a tested and certified version of Oracle Database for NuGenesis 9.1.');
		ELSE								DBMS_OUTPUT.PUT_LINE('!!! WARNING: NuGenesis 9.1 has not been tested or certified on version '||v_rel||'!');
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
	IF (v_ParamValue = 'PREFERRED')		THEN	DBMS_OUTPUT.PUT_LINE('db_securefile='||v_ParamValue||' in this database.  NuGenesis 9 expects db_securefile to be set to "PREFERRED".');
	ELSE						DBMS_OUTPUT.PUT_LINE('!!! WARNING: db_securefile='||v_ParamValue||' in this database.  NuGenesis 9 expects db_securefile to be set to "PREFERRED".');
	END IF;

	SELECT value INTO v_ParamValue FROM v$parameter WHERE name = 'db_block_size';
	IF v_ParamValue < 8192			THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: db_block size='||v_ParamValue||' in this database!  NuGenesis expects a block size of at least 8192.');
	ELSE						DBMS_OUTPUT.PUT_LINE('db_block size='||v_ParamValue||' in this database.  No action is necessary.');
	END IF;

	SELECT value INTO v_ParamValue FROM v$parameter WHERE name = 'plsql_code_type';
							DBMS_OUTPUT.PUT_LINE('plsql_code_type='||v_ParamValue||' in this database.');
	
	SELECT value INTO v_ParamValue FROM v$parameter WHERE name = 'sec_case_sensitive_logon';
	IF 	(v_ParamValue = 'FALSE')	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: sec_case_sensitive_logon='||v_ParamValue||' in this database!  NuGenesis 9 expects sec_case_sensitive_logon=TRUE!');
	ELSIF	(v_ParamValue = 'TRUE')		THEN	DBMS_OUTPUT.PUT_LINE('sec_case_sensitive_logon='||v_ParamValue||' in this database.  This is the expected setting for NuGenesis 9.');
	ELSE						DBMS_OUTPUT.PUT_LINE('Unknown value for sec_case_sensitive_logon='||v_ParamValue);
	END IF;

	SELECT TO_NUMBER(VALUE) INTO v_val FROM V$PARAMETER WHERE NAME = 'job_queue_processes';
	IF (v_val >= 1000)			THEN	DBMS_OUTPUT.PUT_LINE('job_queue_processes='||v_val||' in this database.  No action is necessary.');
	ELSE						DBMS_OUTPUT.PUT_LINE('!!! WARNING: job_queue_processes='||v_val||' in this database!  This must be set to at least 1000 for NuGenesis databases.');
	END IF;

	SELECT VALUE INTO v_ParamValue FROM NLS_DATABASE_PARAMETERS WHERE PARAMETER = 'NLS_CHARACTERSET';
	IF v_Paramvalue = 'AL32UTF8'		THEN	DBMS_OUTPUT.PUT_LINE ('nls_characterset='||v_ParamValue||' in this database. This is the correct characterset for NuGenesis.');
	ELSIF v_Paramvalue != 'AL32UTF8'	THEN	DBMS_OUTPUT.PUT_LINE ('!!!!! ERROR: INCOMPATIBLE NLS_CHARACTERSET! THE NLS_CHARACTERSET FOR THIS DATABASE IS: '||v_Paramvalue||'! NuGenesis 9 REQUIRES THE AL32UTF8 CHARACTERSET');
	END IF;

	SELECT value INTO v_ParamValue FROM v$parameter WHERE name = 'compatible';
	IF 	(v_ParamValue LIKE '12.1%')					THEN	DBMS_OUTPUT.PUT_LINE('!!! WARNING: compatible='||v_ParamValue||' in this CDB!  A compatibility level of 12.2.0 or higher is recommended for NuGenesis 9 databases.');
	ELSIF	(v_ParamValue LIKE '12.2%' OR v_ParamValue LIKE '19.0%')	THEN	DBMS_OUTPUT.PUT_LINE('compatible='||v_ParamValue||' in this CDB.  This is the recommended setting for NuGenesis 9.');
	ELSE										DBMS_OUTPUT.PUT_LINE('Unknown value for compatible='||v_ParamValue);
	END IF;
END;
/

PROMPT
PROMPT List of the database configuration parameters:
SELECT name, value FROM v$parameter WHERE name IN ('cpu_count','shared_pool_size','db_cache_size','db_block_size','db_file_multiblock_read_count','parallel_automatic_tuning','text_enable','optimizer_percent_parallel','sql_version','optimizer_mode','open_cursors','db_name','sort_area_size','sort_area_retained_size','instance_name','db_files') ORDER BY name;

col property_name format a30
col property_value format a60
PROMPT
PROMPT ______________________________________________________________________________________
PROMPT Checking the database properites in this PDB
PROMPT
SELECT property_name, property_value FROM database_properties ORDER BY 1;

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

COLUMN value FORMAT A70;
PROMPT
PROMPT ______________________________________________________________________________________
PROMPT Oracle Automated Diagnostic Reporting (ADR) parameters
PROMPT
SELECT * from v$diag_info;

PROMPT
PROMPT ______________________________________________________________________________________
PROMPT Determining whether this script is running in a containerized database...
PROMPT
DECLARE
v_cnt		PLS_INTEGER;
v_cnt1		PLS_INTEGER;
v_Count		PLS_INTEGER;
v_cdb		VARCHAR2(3);
v_ContainerID	NUMBER;
v_ContainerName	VARCHAR2(500 CHAR);
BEGIN
	:V_NGContainerName := 'CDB$ROOT'; -- Set the default value here for later in the script.  Will be set to the NG container name if there is only one PDB with NuGenesis.
	SELECT cdb INTO v_cdb FROM V$DATABASE;	-- determine if this is container database
	IF v_cdb = 'YES' THEN
		DBMS_OUTPUT.PUT_LINE('This is a containerized database.');
		-- DETERMINE IF THIS IS THE NuGenesis 9 CONTAINER
		SELECT COUNT(USERNAME) INTO v_cnt FROM DBA_USERS WHERE USERNAME = 'NGSDMS60';
		SELECT COUNT(CON_ID) INTO v_cnt1 FROM V$PDBS;
		IF	(v_cnt = 0 OR v_cnt1 > 0)	THEN
			SELECT COUNT(CON_ID) INTO v_Count FROM CDB_USERS WHERE USERNAME IN ('NGSDMS60');
			IF	(v_Count > 1)	THEN	DBMS_OUTPUT.PUT_LINE('More than one PDB has NuGenesis schema users.  For this script to execute correctly, you must login to one of the containers in which the NuGenesis 9 schema has been created.  The nugenesis schema has been created in: '||v_Count ||' containters');
			ELSIF	(v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('This is a container database, but the NuGenesis 9 Schema is not present in any CDB.');
			ELSIF	(v_Count = 1)	THEN
				SELECT con_id INTO v_ContainerID FROM cdb_users WHERE username IN ('NGSDMS60');
				SELECT name INTO :V_NGContainerName FROM v$PDBs WHERE con_id = v_ContainerID;
				DBMS_OUTPUT.PUT_LINE('The NuGenesis schemas are in container ID: '||v_ContainerID||', name: '||:V_NGContainerName);
			END IF;
		END IF;
	ELSIF v_cdb = 'NO'	THEN	DBMS_OUTPUT.PUT_LINE('This is not a container database.');
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
PROMPT ______________________________________________________________________________________
PROMPT Checking the Oracle audit trail options and policies
PROMPT
DECLARE
v_ObjOwner	VARCHAR2(500 CHAR);
v_ObjName	VARCHAR2(1000 CHAR);
v_ParamValue	v$parameter.value%TYPE;
v_OptionsValue	v$option.value%TYPE;
v_Count		PLS_INTEGER := 0;
v_PolicyName	audit_unified_enabled_policies.policy_name%TYPE;
v_FGAPolicyName	dba_audit_policies.policy_name%TYPE;

CURSOR C_NGObjsWithAuditing	IS SELECT owner, object_name FROM dba_obj_audit_opts WHERE owner IN ('NGSDMS60','NGSYSUSER','ELNPROD','SLIM','WATERS');
CURSOR C_EnabledFGAPolicies	IS SELECT policy_name FROM dba_audit_policies WHERE enabled = 'YES';
CURSOR C_EnabledUnifiedPolicies IS SELECT DISTINCT policy_name FROM audit_unified_enabled_policies;
CURSOR C_AllUnifiedPolicies	IS SELECT DISTINCT policy_name FROM audit_unified_policies;
BEGIN
	DBMS_OUTPUT.PUT_LINE('Standard auditing');
	SELECT NVL(value, ' ') INTO v_ParamValue FROM v$parameter WHERE name = 'audit_trail';
	DBMS_OUTPUT.PUT_LINE('audit_trail: '||v_ParamValue);

	SELECT COUNT(*) INTO v_Count FROM v$parameter WHERE name = 'audit_trail_dest';
	IF	(v_Count = 1)	THEN	SELECT NVL(value, ' ') INTO v_ParamValue FROM v$parameter WHERE name = 'audit_trail_dest';
	ELSE				v_ParamValue := ' ';
	END IF;
	DBMS_OUTPUT.PUT_LINE('-- Audit trail destination: '||v_ParamValue);

	SELECT COUNT(*) INTO v_Count FROM v$parameter WHERE name = 'audit_sys_operations';
	IF	(v_Count = 1)	THEN	SELECT NVL(value, ' ') INTO v_ParamValue FROM v$parameter WHERE name = 'audit_sys_operations';
	ELSE				v_ParamValue := ' ';
	END IF;
	DBMS_OUTPUT.PUT_LINE('-- Audit sys operations: '||v_ParamValue);

	DBMS_OUTPUT.PUT_LINE('.');
	DBMS_OUTPUT.PUT_LINE('NuGenesis objects with standard auditing enabled, if any, will be listed below:');
	OPEN C_NGObjsWithAuditing;
	LOOP
		FETCH C_NGObjsWithAuditing INTO v_ObjOwner, v_ObjName;
		EXIT WHEN C_NGObjsWithAuditing%NOTFOUND;

		DBMS_OUTPUT.PUT_LINE('-- '||v_ObjOwner||'.'||v_ObjName);
	END LOOP;
	CLOSE C_NGObjsWithAuditing;

	DBMS_OUTPUT.PUT_LINE('.');
	DBMS_OUTPUT.PUT_LINE('.');
	DBMS_OUTPUT.PUT_LINE('Fine-grained auditing');
	SELECT COUNT(*) INTO v_Count FROM dba_audit_policies;
	DBMS_OUTPUT.PUT_LINE('Number of FGA policies: '||v_Count);
	IF	(v_Count > 0)	THEN
		SELECT COUNT(*) INTO v_Count FROM dba_audit_policies WHERE enabled = 'YES';
		DBMS_OUTPUT.PUT_LINE('-- Number of enabled policies: '||v_Count);
		IF	(v_Count > 0)	THEN
			DBMS_OUTPUT.PUT_LINE('-- Enabled policies:');
			OPEN C_EnabledFGAPolicies;
			LOOP
				FETCH C_EnabledFGAPolicies INTO v_FGAPolicyName;
				EXIT WHEN C_EnabledFGAPolicies%NOTFOUND;

				DBMS_OUTPUT.PUT_LINE('-- -- '||v_FGAPolicyName);
			END LOOP;
			CLOSE C_EnabledUnifiedPolicies;
		END IF;
	END IF;

	DBMS_OUTPUT.PUT_LINE('.');
	DBMS_OUTPUT.PUT_LINE('.');
	DBMS_OUTPUT.PUT_LINE('Unified auditing');
	SELECT value INTO v_OptionsValue FROM v$option WHERE parameter = 'Unified Auditing';
	IF	(v_OptionsValue = 'FALSE')	THEN	DBMS_OUTPUT.PUT_LINE('Unified audit trail: mixed-mode enabled');
	ELSIF	(v_OptionsValue = 'TRUE')	THEN	DBMS_OUTPUT.PUT_LINE('Unified audit trail: enabled, standard and fine-grained auditing disabled');
	ELSE						DBMS_OUTPUT.PUT_LINE('Unified audit trail: unknown value, '||v_OptionsValue);
	END IF;

	SELECT COUNT (DISTINCT policy_name) INTO v_Count FROM audit_unified_policies;
	DBMS_OUTPUT.PUT_LINE('.');
	DBMS_OUTPUT.PUT_LINE('Number of unified audit trail policies: '||v_Count);
	IF	(v_Count > 0)	THEN
		DBMS_OUTPUT.PUT_LINE('-- All policies:');
		OPEN C_AllUnifiedPolicies;
		LOOP
			FETCH C_AllUnifiedPolicies INTO v_PolicyName;
			EXIT WHEN C_AllUnifiedPolicies%NOTFOUND;

			DBMS_OUTPUT.PUT_LINE('-- -- '||v_PolicyName);
		END LOOP;
		CLOSE C_AllUnifiedPolicies;

		SELECT COUNT (DISTINCT policy_name) INTO v_Count FROM audit_unified_enabled_policies;
		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('-- Number of enabled policies: '||v_Count);
		IF	(v_Count > 0)	THEN

			DBMS_OUTPUT.PUT_LINE('-- Enabled policies:');
			OPEN C_EnabledUnifiedPolicies;
			LOOP
				FETCH C_EnabledUnifiedPolicies INTO v_PolicyName;
				EXIT WHEN C_EnabledUnifiedPolicies%NOTFOUND;

				DBMS_OUTPUT.PUT_LINE('-- -- '||v_PolicyName);
			END LOOP;
			CLOSE C_EnabledUnifiedPolicies;
		END IF;
	END IF;

END;
/

PROMPT
PROMPT _____________________________________________________________________________________________');
PROMPT Checking for read-only or encrypted tablespaces in this database...
PROMPT

DECLARE
v_Count				PLS_INTEGER := 0;
v_TablespaceName		dba_tablespaces.tablespace_name%TYPE;
v_TablespaceStatus		dba_Tablespaces.status%TYPE;
v_TablespaceType		dba_tablespaces.contents%TYPE;

CURSOR C_ROTablespaces IS	SELECT tablespace_name, status, contents FROM dba_tablespaces WHERE status = 'READONLY';
CURSOR C_EncTablespaces IS	SELECT tablespace_name, status, contents FROM dba_tablespaces WHERE encrypted = 'YES';
BEGIN
	SELECT COUNT(*) INTO v_Count FROM dba_tablespaces WHERE status = 'READONLY';
	DBMS_OUTPUT.PUT_LINE('Number of read-only tablespaces: '||v_Count);
	IF(v_Count > 0)	THEN
		DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: at least one read-only tablespace was found in this database!  There should be no read-only tablespaces in a NuGenesis database under normal (non-migration) circumstances.');
		OPEN C_ROTablespaces;
		LOOP
			FETCH C_ROTablespaces INTO v_TablespaceName, v_TablespaceStatus, v_TablespaceType;
			EXIT WHEN C_ROTablespaces%NOTFOUND;

			DBMS_OUTPUT.PUT_LINE('-- Tablespace: '||v_TablespaceName||'	contents: '||v_TablespaceType||'	status: '||v_TablespaceStatus);
		END LOOP;
		CLOSE C_ROTablespaces;
	END IF;

	DBMS_OUTPUT.PUT_LINE('.');

	SELECT COUNT(*) INTO v_Count FROM dba_tablespaces WHERE encrypted = 'YES';
	DBMS_OUTPUT.PUT_LINE('Number of encrypted tablespaces: '||v_Count);
	IF(v_Count > 0)	THEN
		DBMS_OUTPUT.PUT_LINE('!!! WARNING: at least one encrypted tablespace was found in this database!  There should be no encrypted tablespaces in a NuGenesis database under normal (non-migration) circumstances.');
		OPEN C_ROTablespaces;
		LOOP
			FETCH C_ROTablespaces INTO v_TablespaceName, v_TablespaceStatus, v_TablespaceType;
			EXIT WHEN C_ROTablespaces%NOTFOUND;

			DBMS_OUTPUT.PUT_LINE('-- Tablespace: '||v_TablespaceName||'	contents: '||v_TablespaceType||'	status: '||v_TablespaceStatus);
		END LOOP;
		CLOSE C_ROTablespaces;
	END IF;
END;
/

PROMPT
PROMPT _____________________________________________________________________________________________');
PROMPT Checking for tablespace quotas...
PROMPT

DECLARE
v_Count				PLS_INTEGER := 0;
v_TablespaceName		dba_tablespaces.tablespace_name%TYPE;
v_username			dba_ts_quotas.username%TYPE;
v_Quota_MaxBytes		dba_ts_quotas.max_bytes%TYPE;
v_Quota_MaxBlocks		dba_ts_quotas.max_blocks%TYPE;

CURSOR C_TSQuotas IS		SELECT tablespace_name, username, max_bytes, max_blocks FROM dba_ts_quotas 
BEGIN
	SELECT COUNT(*) INTO v_Count FROM dba_ts_quotas WHERE max_bytes != -1 OR max_blocks != -1;
	DBMS_OUTPUT.PUT_LINE('Number of tablespace quotas with limits: '||v_Count);
	IF(v_Count > 0 )	THEN


PROMPT
PROMPT List of tablsepaces in this database:
SELECT tablespace_name, status, contents, logging, encrypted, bigfile FROM dba_tablespaces;

PROMPT
PROMPT List of tablsepace quotas in this database:
SELECT tablespace_name, username, bytes, DECODE(max_bytes, -1, 'UNLIMITED', max_bytes) "quota_in_bytes", blocks, DECODE(max_blocks, -1, 'UNLIMITED', max_blocks) "quota_in_blocks" FROM dba_ts_quotas ORDER BY tablespace_name, username;

PROMPT
PROMPT _____________________________________________________________________________________________');
PROMPT Checking datafile status...
PROMPT
DECLARE 
v_Count		PLS_INTEGER := 0;
v_tbs		VARCHAR2(30);
v_filnm		VARCHAR2(513);
v_stat		VARCHAR2(9);

CURSOR C_FIL IS SELECT TABLESPACE_NAME, FILE_NAME, STATUS FROM DBA_DATA_FILES WHERE STATUS != 'AVAILABLE' ORDER BY TABLESPACE_NAME;

BEGIN
	SELECT COUNT(*) INTO v_Count FROM DBA_DATA_FILES WHERE STATUS != 'AVAILABLE';
	IF v_Count = 0	THEN	DBMS_OUTPUT.PUT_LINE('-- All datafiles have a status of available.');
	ELSE
		DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: some datafiles are not available!  If this database will be the target of a migration, do not proceed with the migration until all datafiles are available!');
		OPEN C_FIL;
		LOOP
			FETCH C_FIL INTO v_tbs,v_filnm,v_stat;
			EXIT WHEN C_FIL%NOTFOUND;

			DBMS_OUTPUT.PUT_LINE('-- -- file: '||v_filnm||'	status: '||v_stat||'	tablespace: '||v_tbs);
		END LOOP;
		CLOSE C_FIL;
	END IF;

	SELECT COUNT(*) INTO v_Count FROM V$RECOVER_FILE;
	IF v_Count = 0	THEN	DBMS_OUTPUT.PUT_LINE('-- There are no datafiles requiring recovery.');
	ELSE			DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: '||v_Count||' datafile(s) require recovery!  If this database will be the target of a migration, do not proceed with the migration until all datafiles are recovered!');
	END IF;

	SELECT COUNT(*) INTO v_Count FROM V$DATABASE_BLOCK_CORRUPTION;
	IF v_Count = 0	THEN	DBMS_OUTPUT.PUT_LINE('-- Physical block corruption not found.');
	ELSE			DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: Physical block corruption found!');
	END IF;
END;
/

PROMPT
PROMPT All entries in v$recover_file:
SELECT * FROM V$RECOVER_FILE;

PROMPT
PROMPT All entries in v$database_block_corruption:
SELECT * FROM V$DATABASE_BLOCK_CORRUPTION;

PROMPT
PROMPT _____________________________________________________________________________________________
PROMPT Database storage utilization per tablespace:
PROMPT

DECLARE
v_tabname	VARCHAR2(30);
v_bgfile	VARCHAR2(3);
v_autoglobal	VARCHAR2(3);
v_filenm	VARCHAR2(513);
v_autoextensible		VARCHAR2(3);
v_dfbytes	NUMBER;
v_fsbytes	NUMBER;
v_mxbytes	NUMBER;
v_fileid	NUMBER;
v_total		NUMBER;
v_allocated	NUMBER := 0;
v_used		NUMBER := 0;
v_free		NUMBER := 0;
v_tstamp	VARCHAR2(513);
v_TablespaceUsedPct	NUMBER := 0;

CURSOR C_Tablespaces IS	SELECT TABLESPACE_NAME, BIGFILE FROM DBA_TABLESPACES WHERE TABLESPACE_NAME NOT LIKE 'TEMP%' AND CONTENTS != 'TEMPORARY' ORDER BY 1;
CURSOR C_Datafiles IS	SELECT file_id FROM dba_data_files WHERE tablespace_name = v_tabname;

BEGIN
	OPEN C_TABLESPACEs;
	LOOP
		FETCH C_TABLESPACEs INTO v_tabname, v_bgfile;
		EXIT WHEN C_TABLESPACEs%NOTFOUND;

		OPEN C_Datafiles;
		LOOP
			FETCH C_Datafiles INTO v_fileid;
			EXIT WHEN C_Datafiles%NOTFOUND;

			SELECT AUTOEXTENSIBLE,	BYTES/1048675, MAXBYTES/1048675 INTO v_autoextensible, v_dfbytes, v_mxbytes FROM dba_data_files WHERE file_id = v_fileid;
			SELECT nvl((SUM(BYTES)/1048675),0) INTO v_fsbytes FROM dba_free_space WHERE file_id = v_fileid;
			IF v_autoextensible = 'NO'	THEN
				v_allocated := v_allocated + v_dfbytes;
				v_free := v_free +  v_fsbytes;
			ELSIF v_autoextensible = 'YES'	THEN
				v_allocated := v_allocated + v_mxbytes;
				IF v_mxbytes != v_dfbytes	THEN	v_free := v_free + (v_mxbytes - (v_dfbytes - v_fsbytes));
				ELSIF v_mxbytes = v_dfbytes	THEN	v_free := v_free +  v_fsbytes;
				END IF;
			END IF;
		END LOOP;
		CLOSE C_Datafiles;

		-- Calculate the percentage of use space in this tablespace.  Display increasingly dire warning messages depending on the percent of free space left in the tablespace.
		v_TablespaceUsedPct := ((v_allocated - v_free)/v_allocated * 100);

		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('Tablespace: '||v_tabname);
		DBMS_OUTPUT.PUT_LINE('-- Bigfile tablespace   : '||v_bgfile);
		DBMS_OUTPUT.PUT_LINE('-- total space allocated: '||ROUND(v_allocated, 2)||' MB');
		DBMS_OUTPUT.PUT_LINE('-- total space used     : '||ROUND((v_allocated - v_free) , 2)||' MB');
		DBMS_OUTPUT.PUT_LINE('-- total space used %   : '||ROUND(v_TablespaceUsedPct, 2));

		IF	v_TablespaceUsedPct > 80 AND v_TablespaceUsedPct < 90	THEN	DBMS_OUTPUT.PUT_LINE('-- !!! WARNING: Tablespace '||v_tabname||' is more than 80% full!  Extend this tablespace now to prevent future application crashes !!!!');
		ELSIF	v_TablespaceUsedPct > 90 AND v_TablespaceUsedPct < 95	THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: Tablespace '||v_tabname||' is more than 90% FULL!  IMMEDIATE ACTION IS REQUIRED!  Extend this tablespace now to prevent future application crashes !!!!');
		ELSIF	v_TablespaceUsedPct > 95 AND v_TablespaceUsedPct < 99	THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: Tablespace '||v_tabname||' is more than 95% FULL!  IMMEDIATE ACTION IS REQUIRED!  The applications are at risk of crashing!!  Extend this tablespace soon to prevent application outages !!!!');
		ELSIF	v_TablespaceUsedPct > 99				THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: Tablespace '||v_tabname||' is more than 99% FULL!  IMMEDIATE ACTION IS REQUIRED!  The applications will crash shortly!!!  Extend this tablespace soon to prevent application outages !!!!');
		END IF;
		
		DBMS_OUTPUT.PUT_LINE ('.');
		v_allocated := 0;
		v_free := 0;
	END LOOP;
	CLOSE C_TABLESPACEs;
END;	
/

PROMPT
PROMPT _____________________________________________________________________________________________
PROMPT Database storage utilization per tablespace and data file:
PROMPT
DECLARE
v_tabname	VARCHAR2(30);
v_bgfile	VARCHAR2(3);
V_filenm	VARCHAR2(513);
V_auto		VARCHAR2(3);
v_dfbytes	NUMBER;
v_fsbytes	NUMBER;
v_mxbytes	NUMBER;
v_fileid	NUMBER;
v_fid		NUMBER;
v_allocated	NUMBER := 0;
v_used		NUMBER := 0;
v_free		NUMBER := 0;

CURSOR C_TABLESPACE IS	SELECT TABLESPACE_NAME, BIGFILE FROM DBA_TABLESPACES WHERE TABLESPACE_NAME NOT IN ('RBS', 'TEMP') ORDER BY 1;
CURSOR C_FileIDs IS	SELECT B.FILE_ID FROM DBA_TABLESPACES A, DBA_DATA_FILES B WHERE A.TABLESPACE_NAME = v_tabname AND A.TABLESPACE_NAME = B.TABLESPACE_NAME;

BEGIN
	OPEN C_TABLESPACE;
	LOOP
		FETCH C_TABLESPACE INTO v_tabname, v_bgfile;
		EXIT WHEN C_TABLESPACE%NOTFOUND;
	
		DBMS_OUTPUT.PUT_LINE ('.');
		DBMS_OUTPUT.PUT_LINE ('Tablespace: '||v_tabname);

		OPEN C_FileIDs;
		LOOP
			FETCH C_FileIDs INTO v_fileid;
			EXIT WHEN C_FileIDs%NOTFOUND;

			SELECT AUTOEXTENSIBLE,	BYTES/1048675, MAXBYTES/1048675, file_id INTO v_auto, v_dfbytes, v_mxbytes, v_fid FROM dba_data_files WHERE file_id = v_fileid;
			SELECT NVL((SUM(bytes)/1048675),0) INTO v_fsbytes FROM DBA_FREE_SPACE WHERE FILE_ID = v_fid;
			IF v_auto = 'NO' THEN
				v_allocated := v_allocated + v_dfbytes;
				v_free := v_free +  v_fsbytes;
			ELSIF v_auto = 'YES' and v_mxbytes != v_dfbytes THEN
				v_allocated := v_allocated + v_mxbytes;
				v_free := v_free + (v_mxbytes - (v_dfbytes - v_fsbytes));
			ELSIF v_auto = 'YES' and v_mxbytes = v_dfbytes THEN
				v_allocated := v_allocated + v_mxbytes;
				v_free := v_free +  v_fsbytes;
			END IF;
			DBMS_OUTPUT.PUT_LINE ('-- Datafile ID: '||v_fid||'	Allocated MB: '||round(v_allocated,2)||'	Used MB: '||round((v_allocated - v_free),2));
			v_allocated := 0;
			v_free := 0;
		END LOOP;
		CLOSE C_FileIDs;
	END LOOP;
	CLOSE C_TABLESPACE;
END;	
/

col Tablespace_Name format a15
col AUTOEXTENSIBLE format a14
col File_Name format a80
col Remaining heading 'UNALLOCATED MB|(UNUSED SPACE)' format 9,999,999
col Total_Space heading 'MAX SIZE MB|' format 9,999,999
col EXTENT_MANAGEMENT FORMAT A18
col SIZE FORMAT 9 HEADING "SIZE MB"
col MAXSIZE HEADING "MAXSIZE MB"

PROMPT
PROMPT
PROMPT
PROMPT AUTOEXTENSIBLE DATAFILES BY TABLESPACE:
break on report on Tablespace_Name skip 3 on Tablespace_Name skip 1 on File_Name on Total_Space

select FS.Tablespace_Name, DF.File_Name,	CASE DF.AUTOEXTENSIBLE	WHEN 'YES' THEN SUM(FS.Bytes/1048576) + (DF.MAXBYTES/1048576 - DF.BYTES/1048576) END Remaining,	CASE DF.AUTOEXTENSIBLE 	WHEN 'YES' THEN TRUNC(DF.MAXBYTES/(1024*1024), 2) END Total_Space	FROM dba_free_space fs, dba_data_files df WHERE FS.File_Id = DF.File_Id AND DF.AUTOEXTENSIBLE = 'YES' GROUP BY FS.Tablespace_Name, DF.File_Name, DF.BYTES, DF.MAXBYTES, DF.AUTOEXTENSIBLE ORDER BY FS.Tablespace_Name, DF.File_Name;
clear breaks

PROMPT
PROMPT Fixed size datafiles by tablespace:
break on report on Tablespace_Name skip 3 on Tablespace_Name skip 1 on File_Name on Total_Space
SELECT FS.Tablespace_Name, DF.File_Name, CASE DF.AUTOEXTENSIBLE 	WHEN 'NO'  THEN SUM(FS.Bytes/1048576)	END Remaining, CASE DF.AUTOEXTENSIBLE 	WHEN 'NO'  THEN TRUNC(DF.BYTES/(1024*1024), 2)	END Total_Space
FROM dba_free_space fs, dba_data_files df WHERE FS.File_Id = DF.File_Id AND DF.AUTOEXTENSIBLE = 'NO' GROUP BY FS.Tablespace_Name, DF.File_Name, DF.BYTES, DF.MAXBYTES, DF.AUTOEXTENSIBLE ORDER BY FS.Tablespace_Name, DF.File_Name;

PROMPT
PROMPT Database unallocated space by tablespace:
break on report on Tablespace_Name skip 3 on Tablespace_Name skip 1 on File_Name on Total_Space
clear computes
compute sum of Remaining on Tablespace_Name
compute sum of Remaining on report
compute sum of Total_Space on Tablespace_Name
compute sum of Total_Space on report

select FS.Tablespace_Name, DF.File_Name, DF.AUTOEXTENSIBLE,	CASE DF.AUTOEXTENSIBLE 	WHEN 'NO'  THEN NVL((SUM(FS.Bytes/1048576)),0)	WHEN 'YES' THEN NVL((SUM(FS.Bytes/1048576)),0) + (DF.MAXBYTES/1048576 - DF.BYTES/1048576) END Remaining,	CASE DF.AUTOEXTENSIBLE 	WHEN 'NO'  THEN TRUNC(DF.BYTES/(1024*1024), 2)	WHEN 'YES' THEN TRUNC(DF.MAXBYTES/(1024*1024), 2) END Total_Space	FROM dba_free_space fs, dba_data_files df WHERE FS.File_Id(+) = DF.File_Id GROUP BY FS.Tablespace_Name, DF.File_Name, DF.BYTES, DF.MAXBYTES, DF.AUTOEXTENSIBLE ORDER BY FS.Tablespace_Name, DF.File_Name;
clear computes
clear breaks

PROMPT
PROMPT TEMPORARY TABLESPACE INFORMATION:
BREAK ON TABLESPACE_NAME SKIP 2
SELECT A.TABLESPACE_NAME, A.EXTENT_MANAGEMENT, B.AUTOEXTENSIBLE, B.FILE_NAME FROM DBA_TABLESPACES A, DBA_TEMP_FILES B WHERE A.CONTENTS = 'TEMPORARY' AND A.TABLESPACE_NAME = B.TABLESPACE_NAME;

compute sum of "SPACE ALLOCATED MB" on Tablespace_Name
compute sum of "SPACE ALLOCATED MB" on report
PROMPT
select A.Tablespace_Name, A.File_Name, A.AUTOEXTENSIBLE, CASE A.AUTOEXTENSIBLE 	WHEN 'NO'  THEN TRUNC(B.Bytes/(1024*1024), 2)	WHEN 'YES'  THEN TRUNC(B.MAXBYTES/(1024*1024), 2) END "SPACE ALLOCATED MB"	FROM dba_temp_files a, dba_temp_files b WHERE a.file_name = b.file_name;

PROMPT
SELECT bytes/1073741824 "CURRENT SIZE GB", maxbytes/1073741824 "MAX SIZE GB", tablespace_name, file_name FROM dba_temp_files;

clear computes

DECLARE
TOTAL_BLOCKS 			number; 
TOTAL_BYTES 			number; 
UNUSED_BLOCKS 			number; 
UNUSED_BYTES 			number; 
LAST_USED_EXTENT_FILE_ID 	number; 
LAST_USED_EXTENT_BLOCK_ID 	number; 
LAST_USED_BLOCK 		number; 
v_own				VARCHAR2(500);
v_seg				VARCHAR2(30);
v_tab				VARCHAR2(30);
v_blksz				NUMBER;
v_tbs				VARCHAR2(30);
v_col				VARCHAR2(4000);
v_cnt				number; 
v_SchemaName			VARCHAR2(500);
TYPE ObjList			IS TABLE OF VARCHAR2(500);
t_SchemaList			ObjList;
CURSOR C_SEG IS SELECT SEGMENT_NAME, TABLE_NAME, COLUMN_NAME, TABLESPACE_NAME FROM DBA_LOBS WHERE OWNER = v_own AND partitioned = 'NO' ORDER BY TABLE_NAME, SEGMENT_NAME;

BEGIN
	t_SchemaList := ObjList('NGSDMS60','ELNPROD','NGSYSUSER');
	dbms_output.put_line('.');
	DBMS_OUTPUT.PUT_LINE('___________________________________________________________________________________________________');
	dbms_output.put_line('Space utilization for NuGenesis lob segments . . .');
	dbms_output.put_line('.');
	FOR indx IN 1 .. t_SchemaList.COUNT
	LOOP
		v_own := t_SchemaList(indx);
		OPEN C_SEG;
		LOOP
			FETCH C_SEG INTO v_seg, v_tab, v_col, v_tbs;
			EXIT WHEN C_SEG%NOTFOUND;

			dbms_space.unused_space(v_own,v_seg,'LOB', TOTAL_BLOCKS, TOTAL_BYTES, UNUSED_BLOCKS, UNUSED_BYTES, LAST_USED_EXTENT_FILE_ID, LAST_USED_EXTENT_BLOCK_ID, LAST_USED_BLOCK);

			SELECT BLOCK_SIZE INTO v_blksz FROM DBA_TABLESPACES WHERE TABLESPACE_NAME = v_tbs;

			dbms_output.put_line('.');
			dbms_output.put_line('Lob segment: '||v_own||'.'||v_seg);
	        	dbms_output.put_line('-- on table.column = '||v_tab||'.'||v_col);
			dbms_output.put_line('-- lob segment tablespace = '||v_tbs); 
			dbms_output.put_line('-- tablespace block size = '||v_blksz);
			dbms_output.put_line('-- total_blocks = '||total_blocks); 
			-- dbms_output.put_line('total_bytes = '||total_bytes); 
			dbms_output.put_line('-- unused_blocks = '||unused_blocks);
			-- dbms_output.put_line('unused_bytes = '||unused_bytes);
			dbms_output.put_line('.');
		END LOOP;
		CLOSE C_SEG;
	END LOOP;
END;
/

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
	DBMS_OUTPUT.PUT_LINE('.');
	DBMS_OUTPUT.PUT_LINE('___________________________________________________________________________________________________________');
	DBMS_OUTPUT.PUT_LINE('Determining whether the Oracle Text option is installed and configured for NuGenesis...');
	DBMS_OUTPUT.PUT_LINE('.');

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
		DBMS_OUTPUT.PUT_LINE('Determinining whether the NuGenesis schemas have been granted Execute on CTX_DDL...');
		t_SchemaList := ObjList('NGSDMS60','ELNPROD');
		t_PrivsList  := ObjList('EXECUTE', 'EXECUTE');
		FOR indx IN 1 .. t_SchemaList.COUNT
		LOOP
			SELECT COUNT(*) INTO v_Count FROM dba_tab_privs WHERE table_name = 'CTX_DDL' AND PRIVILEGE = t_PrivsList(indx) AND GRANTOR = 'CTXSYS' AND GRANTEE = t_SchemaList(indx);
			IF v_Count = 1 THEN	DBMS_OUTPUT.PUT_LINE('-- '||t_SchemaList(indx)||' has been granted '||t_PRivsList(indx)||' on ctx_ddl.');
			ELSIF v_Count = 0 THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: '||t_SchemaList(indx)||' has NOT been granted '||t_PrivsList(indx)||' on ctx_ddl!  The Oracle jobs to synchronize the text indexes will not function until this grant is made!!  Grant execute on ctx_ddl to '||t_SchemaList(indx)||', and rebuild the advance search index.');
			END IF;
		END LOOP;
	ELSIF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: this database instance was created without the oracle text option!  Have the customer dba install this oracle component, it is absolutely required for NuGenesis databases!!!!!');
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
	t_IndexOwnerList := ObjList('ELNPROD', 'ELNPROD', 'ELNPROD', 'ELNPROD', 'ELNPROD', 'ELNPROD', 'ELNPROD', 'ELNPROD', 'ELNPROD', 'ELNPROD', 'ELNPROD', 'ELNPROD', 'ELNPROD', 'ELNPROD', 'ELNPROD', 'ELNPROD', 'ELNPROD', 'ELNPROD', 'ELNPROD', 'ELNPROD', 'NGSDMS60');
	t_IndexNameList  := ObjList('CTX_BINARYDOCUMENT', 'TEXT_IDX_EXTERNALPLUGIN', 'TEXT_IDX_LOCATION', 'TEXT_IDX_MEASUREORDER', 'TEXT_IDX_PHYSICALSAMPLE', 'TEXT_IDX_PRODUCT', 'TEXT_IDX_REPORTCONFIG', 'TEXT_IDX_REPORTCONFIGLIB', 'TEXT_IDX_SAMPLETEMPLATE', 'TEXT_IDX_SMMETHOD', 'TEXT_IDX_SPECIFICATION', 'TEXT_IDX_SUBMISSION', 'TEXT_IDX_SUBMISSIONTEMPL', 'TEXT_IDX_TEST', 'TEXT_IDX_TESTDEFINITION', 'TEXT_IDX_TESTREQUEST', 'TEXT_IDX_TESTRESULT', 'TEXT_IDX_UICONFIGURATION', 'TEXT_IDX_USERMESSAGE', 'TEXT_IDX_USERS', 'ADVANCE_SEARCH');
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

COLUMN COMMENTS FORMAT A65
COLUMN OWNER FORMAT A12
COLUMN PROGRAM_NAME FORMAT A25
COLUMN REPEAT_INTERVAL FORMAT A45
COLUMN  END_DATE FORMAT A15
COLUMN START_DATE FORMAT A35
COLUMN NEXT_RUN_DATE FORMAT A35

PROMPT SDMS/ELN JOB PROGRAMS IN THIS DATABASE INSTANCE:
SELECT OWNER, ENABLED, PROGRAM_NAME, COMMENTS FROM DBA_SCHEDULER_PROGRAMS WHERE OWNER IN ('NGSDMS60', 'NGSYSUSER', 'ELNPROD');

PROMPT SDMS/ELN JOB SCHEDULING INFORMATION THIS DATABASE INSTANCE:
SELECT OWNER, SCHEDULE_NAME, START_DATE, REPEAT_INTERVAL, END_DATE, COMMENTS FROM DBA_SCHEDULER_SCHEDULES WHERE OWNER IN ('NGSDMS60', 'NGSYSUSER',  'ELNPROD');

PROMPT SDMS/ELN JOB CURRENTLY SCHEDULED FOR THIS DATABASE INSTANCE:
SELECT OWNER, JOB_NAME, JOB_CLASS, ENABLED, NEXT_RUN_DATE FROM DBA_SCHEDULER_JOBS WHERE OWNER IN ('NGSDMS60', 'NGSYSUSER', 'ELNPROD');

PROMPT
PROMPT __________________________________________________________________________________________
PROMPT Determining whether the expected Oracle background jobs for NuGenesis are present and running
PROMPT
DECLARE
v_status	VARCHAR2(30);	
v_enable	VARCHAR2(5);
v_fail		NUMBER;
v_Count		PLS_INTEGER := 0;
v_JobOwner	dba_scheduler_jobs.owner%TYPE;
v_JobRunCount	dba_scheduler_jobs.run_count%TYPE;
v_mostRecentRunDate	TIMESTAMP(6);
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
				SELECT  STATUS, log_date INTO v_status, v_MostRecentRunDate FROM dba_scheduler_job_run_details WHERE job_name = v_JobName AND log_id = (SELECT MAX(LOG_ID) FROM dba_scheduler_job_run_details WHERE JOB_NAME = t_JobNameList(indx));
				DBMS_OUTPUT.PUT_LINE('-- Most recent run date     : '||v_MostRecentRunDate);
				DBMS_OUTPUT.PUT_LINE('-- Status of most recent run: '||v_status);
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

COLUMN NEXT_RUN_DATE FORMAT A35
COLUMN job_name FORMAT a30
COLUMN job_class FORMAT a20
column additional_info FORMAT A50
column owner FORMAT A10
column status FORMAT A10
COLUMN LOG_DATE FORMAT A40
PROMPT
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
PROMPT
PROMPT Checking for jobs in dba_jobs owned by the NuGenesis schemas:
col what format a50
col log_user format a30
col priv_user format a30
col schema_user format a30
SELECT job, log_user, priv_user, schema_user, broken, failures, what FROM dba_jobs WHERE log_user IN ('NGSDMS60','NGSYSUSER','ELNPROD') OR priv_user IN ('NGSDMS60','NGSYSUSER','ELNPROD') OR schema_user IN ('NGSDMS60','NGSYSUSER','ELNPROD') ORDER BY job;

PROMPT.
PROMPT.
PROMPT.
col value format 99999999999
prompt REDO CONTENTION STATISTICS:  
prompt  
prompt The following shows how often user processes had to wait for space in the redo log buffer:  
SELECT name, value FROM v$sysstat WHERE name IN('redo log space requests','redo log space wait time');

PROMPT
SELECT COUNT(*) "ReDo Switches Previous 24 hrs" FROM V$LOG_HISTORY WHERE TRUNC(FIRST_TIME) = TRUNC(SYSDATE -1);

PROMPT
SELECT GROUP#||' ' "# REDO LOG GROUPS", MEMBERS||'  ' "# MEMBERS PER GROUP" FROM V$LOG;

PROMPT
PROMPT REDO_LOG_FILES_AND_STATUS:
COLUMN STATUS 		FORMAT A10
COLUMN FILE 		FORMAT A50
SELECT B.GROUP# "GROUP", A.STATUS, ROUND(A.BYTES/1048657, 2) "SIZE IN MB", A.MEMBERS "MEMBER", B.MEMBER "FILE" FROM V$LOG A, V$LOGFILE B WHERE A.GROUP# = B.GROUP# ORDER BY B.GROUP#, B.MEMBER;

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

col resource_name format a30
col initial_allocation format a25
col limit_value format a20
col owner format a15
col segment_name format a30
col segment_type format a15
col mb format 999,999,999
PROMPT
PROMPT Database resource utilization:
SELECT * FROM v$resource_limit;

PROMPT
PROMPT Largest segments in the system tablespace:
SELECT owner, segment_name, segment_type, mb FROM (SELECT owner, segment_name, segment_type, bytes / 1024 / 1024 "MB" FROM dba_segments WHERE tablespace_name='SYSTEM' ORDER BY bytes desc) WHERE rownum < 11;

PROMPT
PROMPT V$SPPARAMETER settings:
COLUMN NAME 		FORMAT a40 
COLUMN VALUE		FORMAT a50 
COLUMN ISDEFAULT	FORMAT a10 
SELECT NAME, VALUE FROM V$SPPARAMETER WHERE VALUE IS NOT NULL ORDER BY 1;

PROMPT
PROMPT V$PARAMETER settings:
SELECT NAME, ISDEFAULT, VALUE FROM V$PARAMETER ORDER BY 1;

PROMPT
PROMPT V$PARAMETER2 settings:
SELECT NAME, ISDEFAULT, VALUE FROM V$PARAMETER2 ORDER BY 1;

PROMPT
PROMPT BUFFER POOL HIT RATIO:
SELECT 1 - (phy.value/(cur.value + con.value)) "HIT RATIO" from v$sysstat cur, v$sysstat con, v$sysstat phy WHERE cur.name = 'db block gets' AND con.name = 'consistent gets' AND phy.name = 'physical reads';

PROMPT
PROMPT _________________________________________________________________________________________________________
PROMPT START ADDM ADVISOR REPORT FOR THIS DATABASE INSTANCE

DECLARE
TYPE CntCurTyp	IS REF CURSOR;
cnt_cv1		CntCurTyp;
cnt_cv2		CntCurTyp;
v_task		NUMBER;
v_impact  	NUMBER;
v_command 	VARCHAR2(64);
v_message	VARCHAR2(4000);
v_param		VARCHAR2(4000);
v_cur		VARCHAR2(4000);
v_rec		VARCHAR2(4000);
v_rationale	VARCHAR2(4000);
v_Count		PLS_INTEGER := 0;

CURSOR C_FIND IS SELECT DISTINCT(TASK_ID) FROM DBA_ADVISOR_FINDINGS WHERE TASK_ID IN (SELECT MAX(TASK_ID) FROM DBA_ADVISOR_FINDINGS) AND MESSAGE != 'There was no significant database activity to run the ADDM.' AND IMPACT > 0;
BEGIN
	SELECT COUNT(*) INTO v_Count FROM dba_advisor_findings;
	DBMS_OUTPUT.PUT_LINE('Number of ADDM records: '||v_Count);

	SELECT COUNT(*) INTO v_Count FROM dba_advisor_findings WHERE type = 'ERROR';
	DBMS_OUTPUT.PUT_LINE('-- Number of ERROR findings: '||v_Count);

	SELECT COUNT(*) INTO v_Count FROM dba_advisor_findings WHERE type = 'PROBLEM';
	DBMS_OUTPUT.PUT_LINE('-- Number of PROBLEM findings: '||v_Count);

	SELECT COUNT(*) INTO v_Count FROM dba_advisor_findings WHERE type = 'SYMPTOM';
	DBMS_OUTPUT.PUT_LINE('-- Number of SYMPTOM findings: '||v_Count);

	DBMS_OUTPUT.PUT_LINE('.');
	OPEN C_FIND;
	LOOP
		FETCH C_FIND INTO v_task;
		EXIT WHEN C_FIND%NOTFOUND;
		DBMS_OUTPUT.PUT_LINE('__________________________________________________________________________________');
		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('ID: '||v_task);
		SELECT MAX(IMPACT) INTO v_impact FROM DBA_ADVISOR_FINDINGS WHERE TASK_ID = v_task;
		SELECT MESSAGE INTO v_message FROM DBA_ADVISOR_FINDINGS WHERE TASK_ID = v_task AND IMPACT = v_impact;
		DBMS_OUTPUT.PUT_LINE('Message: '||v_message);
		OPEN cnt_cv1 FOR 'SELECT TRIM(ATTR1), TRIM(ATTR2), TRIM(ATTR3), COMMAND FROM DBA_ADVISOR_ACTIONS WHERE TASK_ID = '||v_task||'AND ATTR1 IS NOT NULL';
		LOOP
			FETCH cnt_cv1 INTO v_param, v_cur, v_rec, v_command;
			EXIT WHEN cnt_cv1%NOTFOUND;
					
			DBMS_OUTPUT.PUT_LINE('Parameter: '||v_param);
			DBMS_OUTPUT.PUT_LINE('Action: '||v_command);
			DBMS_OUTPUT.PUT_LINE('Current Value: '||v_cur);
			DBMS_OUTPUT.PUT_LINE('Recommended Value: '||v_rec);
			DBMS_OUTPUT.PUT_LINE('Reason: ');
			OPEN cnt_cv2 FOR 'SELECT DISTINCT(MESSAGE) FROM DBA_ADVISOR_RATIONALE WHERE TASK_ID = '||v_task||' ';
				LOOP
					FETCH cnt_cv2 INTO v_rationale;
					EXIT WHEN cnt_cv2%NOTFOUND;
					DBMS_OUTPUT.PUT_LINE(v_rationale);
				END LOOP;
			CLOSE cnt_cv2;
		END LOOP;
		CLOSE cnt_cv1;
	END LOOP;
	CLOSE C_FIND;
END;
/

PROMPT END ADDM ADVISOR REPORT FOR THIS DATABASE INSTANCE
PROMPT _________________________________________________________________________________________________________

PROMPT
PROMPT
PROMPT
PROMPT Attempting to change containers to CDBROOT ...
PROMPT This operation will fail with ORA-65090 on non-CDB systems.  This error can be ignored.
-- Switch to the root container for the UNDO section
ALTER SESSION SET container = CDB$ROOT;
SELECT SYS_CONTEXT('USERENV','CON_ID') "CurrentContainerID", SYS_CONTEXT('USERENV','CON_NAME') "CurrentContainerName" FROM dual;

PROMPT
PROMPT _____________________________________________________________________________________________________________');
PROMPT Determining if this database instance employs an undo tablespace or rollback segments
PROMPT

DECLARE
v_rbtyp		INTEGER;
v_ParamValue	VARCHAR2(10);
v_incr		INTEGER := 0;
v_tsname	VARCHAR2(30);
v_Param_UndoTablespace	v$parameter.value%TYPE;
v_Param_UndoRetention	v$parameter.value%TYPE;
v_Param_UndoManagement	v$parameter.value%TYPE;
v_Param_LocalUndo	database_properties.property_value%TYPE;
v_rbseg		VARCHAR2(30);
v_rbown		VARCHAR2(6);
v_rbstat	VARCHAR2(16);
v_rbtab		VARCHAR2(30);
v_tab		VARCHAR2(30);
v_datsize	NUMBER := 0;
v_sum		NUMBER := 0;
v_cursorid	INTEGER;
v_dummy		INTEGER;
v_select	VARCHAR2(2000);
v_segnam	VARCHAR2(30);
v_segmax	NUMBER;
v_segcur	NUMBER;
v_xtnt		NUMBER;
v_Count		PLS_INTEGER := 0;
CURSOR C_UNDTBS IS SELECT TABLESPACE_NAME FROM DBA_TABLESPACES WHERE CONTENTS = 'UNDO';
CURSOR C_RBS1 IS SELECT A.SEGMENT_NAME, A.OWNER, A.STATUS, A.TABLESPACE_NAME FROM DBA_ROLLBACK_SEGS A, DBA_TABLESPACES B WHERE A.TABLESPACE_NAME = B.TABLESPACE_NAME AND B.CONTENTS != 'UNDO';
Cursor C_SEGCHAR IS SELECT SEGMENT_NAME, (ROUND(((DRS.INITIAL_EXTENT * DRS.MIN_EXTENTS) + ((DRS.MAX_EXTENTS - DRS.MIN_EXTENTS) * DRS.NEXT_EXTENT))/1048576, 0)),ROUND((RS.RSSIZE + (DRS.INITIAL_EXTENT * DRS.MIN_EXTENTS))/1048576,2) FROM V$ROLLSTAT RS, DBA_ROLLBACK_SEGS DRS WHERE RS.USN = DRS.FILE_ID;
CURSOR C_EXTNT IS SELECT SEGMENT_NAME, ROUND(NEXT_EXTENT/1048576, 4) FROM DBA_ROLLBACK_SEGS WHERE OWNER = 'PUBLIC';
CURSOR C_EXTNTNO IS SELECT RN.NAME, RS.EXTENTS, DRS.MAX_EXTENTS FROM V$ROLLNAME RN, V$ROLLSTAT RS, DBA_ROLLBACK_SEGS DRS WHERE RN.USN=RS.USN AND RN.NAME = DRS.SEGMENT_NAME AND DRS.OWNER = 'PUBLIC';
CURSOR C_RBTAB IS SELECT DISTINCT(TABLESPACE_NAME) FROM DBA_ROLLBACK_SEGS WHERE OWNER = 'PUBLIC';

BEGIN
	SELECT COUNT(*) INTO v_Count FROM v$parameter WHERE name = 'undo_management';
	IF (v_Count = 1)	THEN	SELECT VALUE INTO v_Param_UndoManagement FROM v$parameter WHERE name = 'undo_management';
	ELSE				v_Param_UndoManagement := ' ';
	END IF;

	SELECT COUNT(*) INTO v_Count FROM v$parameter WHERE name = 'undo_retention';
	IF (v_Count = 1)	THEN	SELECT VALUE INTO v_Param_UndoRetention FROM v$parameter WHERE name = 'undo_retention';
	ELSE				v_Param_UndoRetention := ' ';
	END IF;

	SELECT COUNT(*) INTO v_Count FROM v$parameter WHERE name = 'undo_tablespace';
	IF (v_Count = 1)	THEN	SELECT VALUE INTO v_Param_UndoTablespace FROM v$parameter WHERE name = 'undo_tablespace';
	ELSE				v_Param_UndoTablespace := ' ';
	END IF;

	SELECT COUNT(*) INTO v_Count FROM database_properties WHERE property_name = 'LOCAL_UNDO_ENABLED';
	IF (v_Count = 1)	THEN	SELECT property_value INTO v_Param_LocalUndo FROM database_properties WHERE property_name = 'LOCAL_UNDO_ENABLED';
	ELSE				v_Param_LocalUndo := ' ';
	END IF;

	DBMS_OUTPUT.PUT_LINE('Undo-related database parameters:');
	DBMS_OUTPUT.PUT_LINE('-- undo_management: '||v_Param_UndoManagement);
	DBMS_OUTPUT.PUT_LINE('-- undo_retention:  '||v_Param_UndoRetention);
	DBMS_OUTPUT.PUT_LINE('-- undo_tablespace: '||v_Param_UndoTablespace);
	DBMS_OUTPUT.PUT_LINE('-- local_undo_enabled: '||v_Param_LocalUndo);
	DBMS_OUTPUT.PUT_LINE('.');

	-- Need to be connected to CDBroot container here for this query to work in NG91 on Oracle 19c as we use shared undo mode, and those tablespaces can be queried only through the root container.
	SELECT COUNT(*) INTO v_Count FROM DBA_TABLESPACES WHERE contents = 'UNDO';
	IF v_Count > 0 THEN
		DBMS_OUTPUT.PUT_LINE('This database instance contains an undo tablespace.  Determining if initialzation parameters related undo tablespace are properly configured:');
		DBMS_OUTPUT.PUT_LINE('.');

		-- Check for automatic management of the undo tablespace.  Should be AUTO as per the default NG install.
		IF v_Param_UndoManagement = 'AUTO'	THEN	DBMS_OUTPUT.PUT_LINE('-- The undo_management initialzation parameter is correctly configured: '||v_Param_UndoManagement);
		ELSE						DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: The undo_management initialzation parameter is not correctly configured!  It is set to '||v_Param_UndoManagement||', should be AUTO!');
		END IF;

		-- Look for an UNDO tablespace with a name matching the undo_tablespace parameter.  Use a cursor as a system can have more than 1 undo tablespace.
		DBMS_OUTPUT.PUT_LINE('Checking whether undo_tablespace matches an UNDO tablespace name');
		DBMS_OUTPUT.PUT_LINE('-- All UNDO tablespaces:');
		OPEN C_UNDTBS;
		LOOP
			FETCH C_UNDTBS INTO v_tsname;
			EXIT WHEN C_UNDTBS%NOTFOUND;
			DBMS_OUTPUT.PUT_LINE('-- -- '||v_tsname);
			IF (v_tsname = v_Param_UndoTablespace)	THEN	v_incr := v_incr + 1;	END IF;
		END LOOP;
		CLOSE C_UNDTBS;

		IF	(v_incr = 0)	THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: none of the UNDO Tablespaces match the value of the undo_tablespace parameter!');
		ELSIF	(v_incr = 1)	THEN	DBMS_OUTPUT.PUT_LINE('-- One of the UNDO tablespaces matches the undo_tablespace parameter.');
		END IF;

	ELSE -- no UNDO tablespaces are present, therefore the DB must use rollback segments
		DBMS_OUTPUT.PUT_LINE('No UNDO Tablespaces are present in the database instance.  Transactions are managed by rollback segments.');
		DBMS_OUTPUT.PUT_LINE('.');
		OPEN C_RBS1;
		LOOP
			FETCH C_RBS1 INTO v_rbseg, v_rbown, v_rbstat, v_rbtab;
			EXIT WHEN C_RBS1%NOTFOUND;
			DBMS_OUTPUT.PUT_LINE ('name: '||v_rbseg||'	owner: '||v_rbown||'	type: '||v_rbstat||'	tablespace: '||v_rbtab);
		END LOOP;
		CLOSE C_RBS1;

		OPEN C_RBTAB;
		LOOP
			FETCH C_RBTAB INTO v_tab;
			EXIT WHEN C_RBTAB%NOTFOUND;

			SELECT SUM(MAXBYTES/(1024*1024)) INTO v_datsize FROM DBA_DATA_FILES WHERE TABLESPACE_NAME = v_tab;
			v_sum := v_sum + v_datsize;
		END LOOP;
		CLOSE C_RBTAB;
		DBMS_OUTPUT.PUT_LINE('Total amount of tablespace availabe for rollback segments: '||v_sum||' MB');

		DBMS_OUTPUT.PUT_LINE('.');
		SELECT  SUM(ROUND(((DRS.INITIAL_EXTENT * DRS.MIN_EXTENTS) + ((DRS.MAX_EXTENTS - DRS.MIN_EXTENTS) * DRS.NEXT_EXTENT))/1048576, 0)) INTO v_segmax FROM V$ROLLSTAT RS, DBA_ROLLBACK_SEGS DRS WHERE RS.USN = DRS.FILE_ID AND DRS.OWNER = 'PUBLIC';
		DBMS_OUTPUT.PUT_LINE('Maximum aggregate size of public rollback segments: '||v_segmax||' MB');

		DBMS_OUTPUT.PUT_LINE('.');
		SELECT SUM(ROUND(RS.RSSIZE/1048576,2)) INTO v_segcur FROM V$ROLLSTAT RS, DBA_ROLLBACK_SEGS DRS WHERE RS.USN = DRS.FILE_ID AND DRS.OWNER = 'PUBLIC';
		DBMS_OUTPUT.PUT_LINE('Current aggregate size of public rollback segments: '||v_segcur||' MB');
		OPEN C_SEGCHAR;
		LOOP
			FETCH C_SEGCHAR INTO v_segnam, v_segmax,v_segcur;
			EXIT WHEN C_SEGCHAR%NOTFOUND;
			DBMS_OUTPUT.PUT_LINE('name: '||v_segnam||'	max size MB: '||v_segmax||'	current size MB: '||v_segcur);
		END LOOP;
		CLOSE C_SEGCHAR;

		DBMS_OUTPUT.PUT_LINE('.');

		OPEN C_EXTNT; -- query for rollback segments and extent sizes
		LOOP
			FETCH C_EXTNT INTO v_segnam, v_xtnt;
			EXIT WHEN C_EXTNT%NOTFOUND;
			DBMS_OUTPUT.PUT_LINE('name: '||v_segnam||'	size next extent MB: '||v_xtnt);
		END LOOP;
		CLOSE C_EXTNT;

		OPEN C_EXTNTNO;
		LOOP
			FETCH C_EXTNTNO INTO v_segnam, v_segcur, v_segmax;
			EXIT WHEN C_EXTNTNO%NOTFOUND; 
			DBMS_OUTPUT.PUT_LINE('name: '||v_segnam||'	current # extents: '||v_segcur||'	max # extents: '||v_segmax);
		END LOOP;
		CLOSE C_EXTNTNO;
	END IF;
END;
/

PROMPT
PROMPT
PROMPT
PROMPT ___________________________________________________________________________________________________
PROMPT BASIC UNDO TUNING DATA:
SELECT 	TO_CHAR(MIN(Begin_Time), 'DD-MON-YYYY HH24:MI:SS') "Begin Time",
	TO_CHAR(MAX(Begin_Time), 'DD-MON-YYYY HH24:MI:SS') "End Time",
	SUM(UNDOBLKS) 		"Total Undo Blocks Used",
	SUM(TXNCOUNT)		"Total Num Trans Exec",
	SUM(MAXQUERYLEN) 	"Longest Query (seconds)",
	SUM(MAXCONCURRENCY)	"Highest Concrrent Trans Cnt",
	SUM(SSOLDERRCNT)	"# Times Ora_01555",
	SUM(NOSPACEERRCNT)	"# Times No Free Space"
  FROM V$UNDOSTAT;

---------------------------------------------------------------------------------------------------
-- V$UNDOSTAT COLUMN DEFITIONIONS.  
--  NON ZERO VALUE FOR THESE COLUMNS INDICATE
-- When the columns UNXPSTEALCNT, UNXPBLKREUCNT. EXPBLKREUCNT, EXPSTEALCNT, AND EXPBLKRELCNT hold non-zero values, it is an indication of space pressure. 

-- UNXPBLKRELCNT  - The number of unexpired blocks removed from undo segments to be used by other transactions
-- UNXPBLKREUCNT  - The number of unexpired undo blocks reused by transactions
-- EXPSTEALCNT    - The number of attempts when expired extents were stolen from other undo segments to satisfy a space requests
-- EXPBLKRELCNT   - The number of expired extents stolen from other undo segments to satisfy a space request
---------------------------------------------------------------------------------------------------
PROMPT
PROMPT NON ZERO VALUES FOR THESE V$UNDOSTAT COLUMNS ARE INDICATION OF UNDO SPACE PRESSURE:
SELECT SUM(UNXPBLKRELCNT) "UNXPBLKRELCNT", SUM(UNXPBLKREUCNT) "UNXPBLKREUCNT", SUM(EXPSTEALCNT)   "EXPSTEALCNT", SUM(EXPBLKRELCNT)  "EXPBLKRELCNT" FROM V$UNDOSTAT;

-- SSOLDERRCNT    - The number of ORA-1555 errors that occurred during the interval
PROMPT
PROMPT IF THE COLUMN  SSOLDERRCNT IS NON ZERO, THEN UNDO_RETENTION IS NOT PROPERLY SET:
SELECT SUM(SSOLDERRCNT) "SSOLDERRCNT" FROM V$UNDOSTAT;

-- NOSPACEERRCNT  - The number of Out-of-Space errors
PROMPT
PROMPT IF THE COLUMN  NOSPACEERRCNT IS NON ZERO, UNDO TABLESPACE IS UNDERSIZED:
SELECT SUM(NOSPACEERRCNT) "NOSPACEERRCNT" FROM V$UNDOSTAT;

-- ESTIMATE MINIMUM REQUIRED SIZE FOR UNDO TABLESPACE
PROMPT
PROMPT MINIMUM SIZE RECOMMENDATIONS FOR UNDO TABLESPACE:
SELECT (UR * (UPS * DBS)) + (DBS * 24) AS "Bytes" FROM (SELECT value AS UR FROM v$parameter WHERE name = 'undo_retention'), (SELECT (SUM(undoblks)/SUM(((end_time - begin_time)*86400))) AS UPS FROM v$undostat), (select block_size as DBS from dba_tablespaces where tablespace_name= (select value from v$parameter where name = 'undo_tablespace'));

PROMPT
PROMPT
PROMPT ___________________________________________________________________________________________________
PROMPT Determining if a flash recovery area has been enabled for this database instance . . .
PROMPT
DECLARE
v_value		 VARCHAR2(255);
v_sid		 VARCHAR2(16);
v_logmode	 VARCHAR2(12);
v_reclimit	 NUMBER;
v_len		 NUMBER;
v_report	 VARCHAR2(100);
v_usage		 NUMBER;

BEGIN
	SELECT LOG_MODE INTO v_logmode FROM V$DATABASE;
	DBMS_OUTPUT.PUT_LINE('.');
	DBMS_OUTPUT.PUT_LINE('The database is in: '||v_logmode||' mode.');
	DBMS_OUTPUT.PUT_LINE('.');

	SELECT VALUE INTO v_value FROM V$PARAMETER WHERE NAME = 'db_recovery_file_dest';
	IF v_value IS NULL THEN	DBMS_OUTPUT.PUT_LINE('The flash_recovery_area feature has not been enabled');
	ELSE
		DBMS_OUTPUT.PUT_LINE('The flash_recovery_area feature is enabled; location: '||v_value);

		SELECT INSTANCE_NAME INTO v_sid FROM V$INSTANCE;
		DBMS_OUTPUT.PUT_LINE('.');
		IF	(v_logmode = 'ARCHIVELOG')	THEN	DBMS_OUTPUT.PUT_LINE('ARCHIVELOGS WILL BE CREATED IN: '||v_value||'\ '||v_sid||'\ARCHIVELOG');
		END IF;

		DBMS_OUTPUT.PUT_LINE('.');
		SELECT TO_NUMBER(VALUE) INTO v_reclimit FROM V$PARAMETER WHERE NAME = 'db_recovery_file_dest_size';
		SELECT LENGTH(VALUE) INTO v_len FROM V$PARAMETER WHERE NAME = 'db_recovery_file_dest_size';
		IF	(v_len >= 9)			THEN	v_report := TRUNC(v_reclimit/1073741824,2) ||' GB';
		ELSIF	(v_len < 9 AND v_len > 6)	THEN	v_report := TRUNC(v_reclimit/1048576,2) || ' MB';
		ELSIF	(v_len < 6 AND v_len > 3)	THEN	v_report := TRUNC(v_reclimit/1073741824,2) || 'KB';
		ELSIF	(v_len < 3)			THEN	v_report := TRUNC(v_reclimit,2) || 'BYTES';
		END IF;
		DBMS_OUTPUT.PUT_LINE('The current size limit for the flash recovery area is:  '||v_report);

		SELECT SUM(PERCENT_SPACE_USED) INTO v_usage FROM V$FLASH_RECOVERY_AREA_USAGE;
		DBMS_OUTPUT.PUT_LINE('The flash recovery area is currently '||v_usage||'% used');
		IF	(v_usage > 90)			THEN	DBMS_OUTPUT.PUT_LINE('!!! WARNING: the flash recovery area is nearly full!  Take appropriate actions to free up space!');
		END IF;
	END IF;
END;
/

PROMPT
PROMPT Flash recovery area space utilization statistics:
SELECT SPACE_LIMIT/(1024*1024*1024) "FRA SPACE LIMIT GB", TRUNC(SPACE_USED/(1024*1024*1024),4) "FRA SPACE USED GB", TRUNC((SPACE_LIMIT - SPACE_USED)/(1024*1024*1024),4) "FRA FREE SPACE GB", TRUNC((SPACE_USED/SPACE_LIMIT)*100,2) "% FRA USED" FROM V$RECOVERY_FILE_DEST;

PROMPT
PROMPT Flash recovery area space utilization:
COLUMN PERCENT_SPACE_USED HEADING "% USAGE"
SELECT * FROM V$FLASH_RECOVERY_AREA_USAGE;

PROMPT
PROMPT
PROMPT _____________________________________________________________________________________________
PROMPT Reporting on the RMAN configuration for this instance..
COLUMN VALUE FORMAT A75
COLUMN NAME FORMAT A40
SELECT * FROM V$RMAN_CONFIGURATION;

PROMPT
PROMPT
PROMPT THE FOLLOWING QUERY MAY TAKE SOME TIME TO EXECUTE, BE PATIENT THE SCRIPT IS NOT HUNG
PROMPT
PROMPT RMAN BACKUPS SUMMARY FOR THE PAST 7 DAYS:
-- DON'T RUN QUERY IF VERY LARGE NUMBER OF ROW,  BECAUSE THIS MAY CAUSE SCRIPT EXECUTION TO HANG
COLUMN STATUS FORMAT A25
SELECT SID, OPERATION, STATUS, START_TIME, END_TIME FROM V$RMAN_STATUS WHERE START_TIME > SYSDATE - 7 AND OPERATION LIKE '%BACK%' AND (SELECT COUNT(SID) FROM V$RMAN_STATUS)  < 100000 ORDER BY START_TIME;

spool off
