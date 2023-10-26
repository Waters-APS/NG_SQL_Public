----------------------------------------------------------------------------------------------------------------------------------------
--                      		Waters Corporation
--                    		   WDM_verify_schema_rX.sql
-- This script is to be used for verification of the Waters Database Manager 2 schema and some minor verification of the APEX Schemas.
-- Please use the "apex_verify.sql" script to verify the schemas in the APEX_ accounts.
-- For use with WDM 2.0 and later.  It may work with WDM 1.x but it may report irrelevant errors (missing objects/privileges, etc) on those versions.
--
--  EXPECTED INPUTS:
--  None.
--
--  EXPECTED OUTPUTS:
--  1. (console and file) a detailed report on the WDM schema
--
--  Recommended execution environment: command-line SQL*Plus client logged in as the Elnprod user.
--
--  MINIMUM PRIVILEGES TO RUN THIS SCRIPT:
--  SYSDBA
--
-- Change History:
-- PERSON 		REVISION	DATE			REASON
-- MMORRISON		1		2019-12-03		CREATION
-- MMORRISON		2		2019-12-11		Check for credentials only if dba_credentials exists.  WDM prior to v2.0 did not use credentials as this feature did not exist in Oracle 11g.
-- 								Display more parameters from the aem_config table.
-- MMORRISON		3		2019-12-11		Check for the WATERS workspace in APEX
-- MMORRISON		4		2019-12-12		Check for more objects in the WDM APEX application.  Display the SMTP host and port from the Apex config.
-- MMORRISON		5		2019-12-19		Report on the WDM backup jobs and the notification jobs.  Use table variables to consolidate repetitive code.
-- 								Set define off so that the ampersand is not used as a substution variable in this script.  Display WDM users, roles, and grants.
-- MMORRISON		6		2020-01-28		Report on WDM table constraints.
-- MMorrison		7		2020-11-01		Update to support WDM versions 2.0, 3.0, and 4.0.  Revise the section on Java permissions as they're not required in WDM 3 and 4.
-- MMorrison		8		2021-10-21		Check for the C##WATERS_WDMVIEWS user and related objects / privileges.
-- MMorrison		9		2022-08-08		Check for WDM schema accounts from a list vs. a query for accounts where the name is like APEX.
-- MMorrison		10		2023-01-23		Support for WDM 4.1 and 4.2.
-- MMorrison            11              2023-04-17              Add a table of expected account status to the schema-accounts check.
----------------------------------------------------------------------------------------------------------------------------------------
SET FEEDBACK OFF LINESIZE 500 PAGESIZE 200 TRIMSPOOL ON TIMING OFF ECHO OFF DOC OFF TRIM ON verify off SERVEROUTPUT ON SIZE 1000000 heading ON define ^
TTITLE OFF

COLUMN file NEW_VALUE file NOPRINT 
SELECT 'WDM_schema_verify_r11_'||to_char(sysdate,'yyyy-mm-dd_hh24-mi-ss')||'.log' "file" FROM DUAL;
SPOOL ^file 


prompt           ***********************************************
prompt           * WDM Schema Verification Report              *
prompt           ***********************************************
prompt 
prompt		  THIS SCRIPT MUST BE EXECUTED WITH SYSDBA PRIVILEGES!


PROMPT
PROMPT ___________________________________________________________________________________________________________
PROMPT Oracle and OS versions:

COLUMN BANNER FORMAT A85 HEADING "ORA_VERSION"
SELECT BANNER FROM V$VERSION;

COLUMN HOST_NAME FORMAT A35
SELECT INSTANCE_NAME, HOST_NAME, STATUS, DATABASE_STATUS FROM V$INSTANCE;

COLUMN DBID HEADING "DATABASE_ID"
COLUMN PLATFORM_NAME FORMAT A35 HEADING "OS"
SELECT DBID, OPEN_MODE, PLATFORM_NAME FROM V$DATABASE;

COLUMN parameter FORMAT a40
COLUMN VALUE FORMAT A40
SELECT * FROM NLS_DATABASE_PARAMETERS;

PROMPT ___________________________________________________________________________________________________________
PROMPT Installed Oracle components:

COLUMN COMP_NAME FORMAT	A40 HEADING "COMPONENT NAME"
COLUMN version FORMAT A12
COLUMN schema FORMAT A30
SELECT COMP_NAME, VERSION, STATUS, MODIFIED, SCHEMA FROM DBA_REGISTRY;

PROMPT
PROMPT
PROMPT ___________________________________________________________________________________________________________
PROMPT APEX version checks
PROMPT
VARIABLE	V_ApexVersion		VARCHAR2(500);
VARIABLE	V_ApexSchema		VARCHAR2(500);
VARIABLE	V_WDMVersion		VARCHAR2(500);
VARIABLE	V_WatersAcctPresent	NUMBER;
VARIABLE	V_WDMVersionsAsNum	NUMBER;
VARIABLE	V_WDMSchema		VARCHAR2(500);
VARIABLE	V_WDMAppID		VARCHAR2(100);

DECLARE
v_Count		PLS_INTEGER := 0;
v_ApexStatus	dba_registry.status%TYPE;

BEGIN
	DBMS_OUTPUT.PUT_LINE('Determining whether APEX is installed in this instance:');
	SELECT COUNT(*) INTO v_Count FROM dba_registry WHERE comp_name ='Oracle Application Express';
	IF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: APEX is not installed!  WDM will not be functional!  Please check the component list about for some variation of the name ''Application Express''.  If it is not installed then please re-installed WDM.');
	ELSIF (v_Count = 1)	THEN
		DBMS_OUTPUT.PUT_LINE('APEX is installed.');
		SELECT version, status, schema INTO :V_ApexVersion, v_ApexStatus, :V_ApexSchema FROM dba_registry WHERE comp_name = 'Oracle Application Express';
		IF (v_ApexStatus = 'VALID')	THEN	DBMS_OUTPUT.PUT_LINE ('APEX has a valid status.');
		ELSE					DBMS_OUTPUT.PUT_LINE ('!!!!! ERROR: APEX does NOT have a valid status!  WDM will not be functional!  Please re-install WDM in this DB instance!');
		END IF;

		 -- Gather the APEX version and schema here, but hold off on testing it until we know the Waters schema and WDM Version.  Just test for valid/invalid status for now.
		DBMS_OUTPUT.PUT_LINE('APEX version: '||:V_ApexVersion);
		DBMS_OUTPUT.PUT_LINE('APEX schema:  '||:V_ApexSchema);
	END IF;
END;
/

PROMPT
PROMPT
PROMPT ___________________________________________________________________________________________________________
PROMPT Check for WDM and APEX schema accounts
PROMPT

DECLARE
v_Count			PLS_INTEGER := 0;
v_ExpectedNo		PLS_INTEGER;
v_AcctProfile		dba_users.profile%TYPE;
v_AcctStatus		dba_users.account_status%TYPE;
v_AcctName		dba_users.username%TYPE;
v_AcctPwdTime		dba_profiles.limit%TYPE;

v_SQLQuery		VARCHAR2(4000 CHAR);
v_SchemaNames		VARCHAR2(200 CHAR);

TYPE CharList		IS TABLE OF VARCHAR2(500);
t_WDMAccounts		CharList;
t_AccountStatuses	CharList;
BEGIN
	:V_WatersAcctPresent := 0;
	IF (:v_ApexVersion LIKE '18.1%')	THEN
		t_WDMAccounts := CharList('WATERS','APEX_PUBLIC_USER','APEX_LISTENER','APEX_REST_PUBLIC_USER'); -- WDM 2.0
		v_SchemaNames := '''WATERS'',''APEX_PUBLIC_USER'',''APEX_LISTENER'',''APEX_REST_PUBLIC_USER''';
		t_AccountStatuses := CharList('OPEN','OPEN','OPEN','OPEN');
	ELSIF (:v_ApexVersion LIKE '18.2%')	THEN	
		t_WDMAccounts := CharList('WATERS','APEX_PUBLIC_USER','APEX_INSTANCE_ADMIN_USER','C##WATERS_WDMVIEWS'); -- WDM 4.0
		v_SchemaNames := '''WATERS'',''APEX_PUBLIC_USER'',''APEX_INSTANCE_ADMIN_USER'',''C##WATERS_WDMVIEWS''';
		t_AccountStatuses := CharList('OPEN','OPEN','LOCKED','OPEN');
	ELSE
		t_WDMAccounts := CharList(); -- Unknown versions of WDM/APEX
		v_SchemaNames := ' ';
	END IF;
	
	v_ExpectedNo := t_WDMAccounts.COUNT;
	v_SQLQuery := 'SELECT COUNT(*) FROM dba_users WHERE username IN ('||v_SchemaNames||')';
	EXECUTE IMMEDIATE v_SQLQuery INTO v_Count;
	IF (v_Count < v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: fewer than the expected WDM/APEX accounts are present in this DB instance ('||v_ExpectedNo||' expected, '||v_Count||' found)!');
	ELSIF (v_Count = v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('The expected number of WDM/APEX accounts are present in this DB instance ('||v_ExpectedNo||' expected, '||v_Count||' found).');
	ELSIF (v_Count > v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('!!! WARNING: more than expected number of WDM/APEX accounts are present in this DB instance ('||v_ExpectedNo||' expected, '||v_Count||' found)!');
	END IF;

	FOR indx IN 1 .. t_WDMAccounts.COUNT
	LOOP
		v_AcctName := t_WDMAccounts(indx);
		SELECT COUNT(*) INTO v_Count FROM dba_users WHERE username = v_AcctName;
		IF (v_Count = 1) 	THEN
			DBMS_OUTPUT.PUT_LINE('The '||v_AcctName||' account has been created.');
			IF (v_AcctName = 'WATERS')	THEN	:V_WatersAcctPresent := 1;	END IF; -- Flag the Waters account as present, for use later in the verify script.

			SELECT profile, account_status INTO v_AcctProfile, v_AcctStatus FROM dba_users WHERE username = v_AcctNAme;
			IF (v_AcctStatus = t_AccountStatuses(indx))	THEN 	DBMS_OUTPUT.PUT_LINE('-- This account is '||v_AcctStatus);
			ELSE            					DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: This account is '||v_AcctStatus||' (expected: ' || t_AccountStatuses(indx) || ')!');
			END IF;

			IF (v_AcctProfile NOT IN ('SDMSPROFILE','SLIMPROFILE','UNIFIPROFILE','EMPOWERDEFAULT','DEFAULT','C##WATERS_WDMVIEWS_PROFILE'))	THEN	DBMS_OUTPUT.PUT_LINE('-- !!! WARNING: the '||v_AcctName||' account has an unexpected profile ('||v_AcctProfile||')!  The account may be subject to password expiration rules!  Please set this account to the non-expiring profile.');
			ELSE																	DBMS_OUTPUT.PUT_LINE('-- This account has one of the expected profiles.');
			END IF;

			SELECT limit INTO v_AcctPwdTime FROM dba_profiles WHERE profile = v_AcctProfile AND resource_name = 'PASSWORD_LIFE_TIME';
			IF (v_AcctPwdTime = 'UNLIMITED')	THEN	DBMS_OUTPUT.PUT_LINE('-- This account has a non-expiring profile.');
			ELSE						DBMS_OUTPUT.PUT_LINE('-- !!! WARNING: this account has an expiring profile!  It''s password can expire, and if it does, then WDM will not be accessible!  Please change the profile to one with a non-expiring password.');
			END IF;
		ELSIF (v_Count = 0)	THEN
			DBMS_OUTPUT.PUT_LINE ('!!!!! ERROR: the '||v_AcctName||' account has not been created!');
		END IF;

		DBMS_OUTPUT.PUT_LINE ('.');
	END LOOP;
END;
/

PROMPT
PROMPT
PROMPT ___________________________________________________________________________________________________________
PROMPT WDM version checks
PROMPT

DECLARE
v_SQL		VARCHAR2(2000 CHAR);
v_Count		PLS_INTEGER := 0;

BEGIN
	IF (:V_WatersAcctPresent = 0)			THEN
		:V_WDMVersion := '0';
		:V_WDMVersionsAsNum := 0;
		DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: the Waters account is not present in this PDB, cannot check the WDM version!');
	ELSE
		SELECT COUNT(*) INTO v_Count FROM dba_tables WHERE owner = 'WATERS' AND table_name = 'AEM_CONFIGURATION_PARAMETERS';
		IF (v_Count = 0)			THEN
			:V_WDMVersion := '0';
			:V_WDMVersionsAsNum := 0;
			DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: the Waters account is present but the configuration table is NOT present; cannot check the WDM version!');
		ELSE
			v_SQL := 'SELECT value FROM waters.aem_configuration_parameters WHERE parameter = ''WDM Version''';
			EXECUTE IMMEDIATE v_SQL INTO :V_WDMVersion;
			DBMS_OUTPUT.PUT_LINE('WDM version: '||:v_WDMVersion||';	APEX version: '||:v_ApexVersion);
			IF (:v_WDMVersion = '2.0')			THEN
				:V_WDMVersionsAsNum := 2000;
				IF (:V_ApexVersion LIKE '18.1%')	THEN	DBMS_OUTPUT.PUT_LINE('The correct version of APEX ('||:V_ApexVersion||') is installed for WDM 2.0.');
				ELSE						DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: WDM 2.0 is not supported on APEX v'||:V_ApexVersion||'!  Please install APEX v18.1 in this database instance and re-install WDM!');
				END IF;
			ELSIF (:v_WDMVersion = '1.6')			THEN
				:V_WDMVersionsAsNum := 1600;
				IF (:V_ApexVersion LIKE '4.2%')		THEN	DBMS_OUTPUT.PUT_LINE('The correct version of APEX ('||:V_ApexVersion||') is installed for WDM 1.6.');
				ELSE						DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: WDM 1.6 is not supported on APEX v'||:V_ApexVersion||'!  Please install APEX v4.2 in this database instance and re-install WDM!');
				END IF;
			ELSIF (:v_WDMVersion = '4.0')			THEN
				:V_WDMVersionsAsNum := 4000;
				IF (:V_ApexVersion LIKE '18.2%')	THEN	DBMS_OUTPUT.PUT_LINE('The correct version of APEX ('||:V_ApexVersion||') is installed for WDM 4.0.');
				ELSE						DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: WDM 4.0 is not supported on APEX v'||:V_ApexVersion||'!  Please install APEX v18.2 in this database instance and re-install WDM!');
				END IF;
			ELSIF (:v_WDMVersion = '4.1')			THEN
				:V_WDMVersionsAsNum := 4100;
				IF (:V_ApexVersion LIKE '18.2%')	THEN	DBMS_OUTPUT.PUT_LINE('The correct version of APEX ('||:V_ApexVersion||') is installed for WDM 4.1.');
				ELSE						DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: WDM 4.1 is not supported on APEX v'||:V_ApexVersion||'!  Please install APEX v18.2 in this database instance and re-install WDM!');
				END IF;
			ELSIF (:v_WDMVersion = '4.2')			THEN
				:V_WDMVersionsAsNum := 4200;
				IF (:V_ApexVersion LIKE '18.2%')	THEN	DBMS_OUTPUT.PUT_LINE('The correct version of APEX ('||:V_ApexVersion||') is installed for WDM 4.2.');
				ELSE						DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: WDM 4.2 is not supported on APEX v'||:V_ApexVersion||'!  Please install APEX v18.2 in this database instance and re-install WDM!');
				END IF;
			ELSE
				:V_WDMVersionsAsNum := 0;
				DBMS_OUTPUT.PUT_LINE('!!! WARNING: unknown version of WDM.  The version number as retrieved from aem_configuration_parameters: '||:V_WDMVersion);
			END IF;
		END IF;
	END IF;
END;
/

PROMPT List of WDM and APEX accounts:
COLUMN profile FORMAT a20
COLUMN username FORMAT a30
SELECT username, profile, account_status FROM dba_users WHERE username IN ('WATERS') OR username LIKE 'APEX%' ORDER BY username;

PROMPT

BREAK ON profile
COLUMN profile FORMAT a30
COLUMN limit FORMAT a30
PROMPT List of profile limits for the WDM and APEX accounts:
SELECT profile, resource_name, limit FROM dba_profiles WHERE profile IN (SELECT DISTINCT profile FROM dba_users WHERE username IN ('WATERS','APEX_PUBLIC_USER','APEX_REST_PUBLIC_USER','APEX_LISTENER','APEX_INSTANCE_ADMIN','C##WATERS_WDMVIEWS')) ORDER BY profile, resource_name;
BREAK ON skjdfhg

PROMPT
PROMPT
PROMPT ___________________________________________________________________________________________________________
PROMPT WDM object checks
PROMPT

PROMPT Number of objects owned by WATERS:
SELECT COUNT(*) "ObjCount" FROM dba_objects WHERE owner = 'WATERS';
SELECT object_type, COUNT(*) "ObjCount" FROM dba_objects WHERE owner = 'WATERS' GROUP BY object_type ORDER BY object_type;

PROMPT

DECLARE
v_Count		PLS_INTEGER := 0;
v_ObjName	dba_objects.object_name%TYPE;
v_ObjType	dba_objects.object_type%TYPE;
v_ObjOwner	dba_objects.owner%TYPE;

CURSOR C_InvalidObjects IS SELECT object_name, object_type, owner FROM dba_objects WHERE status NOT IN ('VALID');

BEGIN
	SELECT COUNT(*) INTO v_Count FROM dba_objects WHERE owner = 'WATERS' AND status NOT IN ('VALID');
	IF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('The WATERS schema does not own any invalid objects.');
	ELSE
		DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: WATERS owns '||v_Count||' invalid objects!  Run utlrp.sql to repair the objects.  If the objects remain invalid after running utlrp.sql then re-install WDM, as the invalid objects likely depend on DB objects which do not exist in the schema.');
		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('List of invalid objects in this instance:');

		OPEN C_InvalidObjects;
		LOOP
			FETCH C_InvalidObjects INTO v_ObjName, v_ObjType, v_ObjOwner;
			EXIT WHEN C_InvalidObjects%NOTFOUND;

			DBMS_OUTPUT.PUT_LINE('Owner: '||v_ObjOwner||'	Name: '||v_ObjName||'	Type: '||v_ObjType);
		END LOOP;
		CLOSE C_InvalidObjects;
	END IF;
END;
/

PROMPT
PROMPT
PROMPT ___________________________________________________________________________________________________________
PROMPT WDM tables
PROMPT

DECLARE
v_Count			PLS_INTEGER := 0;
v_ExpectedNo		PLS_INTEGER;
v_TableName		dba_tables.table_name%TYPE;

TYPE CharList		IS TABLE OF VARCHAR2(500);
t_WDMTables		CharList;

BEGIN
	-- Load the table names list with entries appropriate for the installed version of WDM
	IF (:V_WDMVersionsAsNum <= 4000)					THEN	t_WDMTables  := CharList('AEM_ALERTS','AEM_ANY_RESULT','AEM_BACKUP_SCHEDULE','AEM_CONFIGURATION_PARAMETERS','AEM_CONFIG_PARAMETERS_AUDIT','AEM_DATAPUMP_JOBS','AEM_DIRECTORIES','AEM_ORA','AEM_REPORTS','AEM_REPORT_COLUMN_LABELS','HTMLDB_PLAN_TABLE','SEC_ROLES','SEC_ROLES_GRANTED','SEC_USERS');
	ELSIF (:V_WDMVersionsAsNum > 4000 AND :V_WDMVersionsAsNum <= 4100)	THEN	t_WDMTables  := CharList('AEM_ALERTS','AEM_ANY_RESULT','AEM_BACKUP_SCHEDULE','AEM_CONFIGURATION_PARAMETERS','AEM_CONFIG_PARAMETERS_AUDIT','AEM_DIRECTORIES','AEM_ORA','AEM_REPORTS','AEM_REPORT_COLUMN_LABELS','HTMLDB_PLAN_TABLE','SEC_ROLES','SEC_ROLES_GRANTED','SEC_USERS');
	ELSIF (:V_WDMVersionsAsNum >= 4200)					THEN	t_WDMTables  := CharList('AEM_ALERTS','AEM_TS_ALERTS','AEM_ANY_RESULT','AEM_BACKUP_SCHEDULE','AEM_CONFIGURATION_PARAMETERS','AEM_CONFIG_PARAMETERS_AUDIT','AEM_DIRECTORIES','AEM_ORA','AEM_REPORTS','AEM_REPORT_COLUMN_LABELS','HTMLDB_PLAN_TABLE','SEC_ROLES','SEC_ROLES_GRANTED','SEC_USERS','AEM_DISK_USAGE','AEM_DISK_USAGE_EXT');
	END IF;
	v_ExpectedNo := t_WDMTables.COUNT;

	SELECT COUNT(*) INTO v_Count FROM dba_tables WHERE owner = 'WATERS';
	IF (v_Count < v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: fewer than expected tables are in the WATERS schema ('||v_ExpectedNo||' expected, '||v_Count||' found)!');
	ELSIF (v_Count = v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('The expected number of tables are in the WATERS schema ('||v_ExpectedNo||' expected, '||v_Count||' found).');
	ELSIF (v_Count > v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('!!! WARNING: more than expected tables are in the WATERS schema ('||v_ExpectedNo||' expected, '||v_Count||' found)!');
	END IF;

	FOR indx IN 1 .. t_WDMTables.COUNT
	LOOP
		v_TableName := t_WDMTables(indx);
		SELECT COUNT(*) INTO v_Count FROM dba_tables WHERE owner = 'WATERS' AND table_name = v_TableName;
		IF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: Table waters.'||v_TableName||' is NOT present!');
		ELSIF (v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('-- Table waters.'||v_TableName||' is present');
		END IF;
	END LOOP;
END;
/

PROMPT

COLUMN table_name FORMAT a30
COLUMN owner FORMAT a30
PROMPT List of WDM tables
SELECT owner, table_name, status from dba_tables WHERE owner = 'WATERS' ORDER BY 1;

PROMPT
PROMPT ___________________________________________________________________________________________________________
PROMPT Verifying WDM parameters and the WDM APEX application
PROMPT

DECLARE
v_Count			PLS_INTEGER := 0;
v_ExpectedNo		PLS_INTEGER;
v_WDMConfigValue	VARCHAR2(1000);
v_ApexConfigValue	VARCHAR2(1000);
v_ApexQuery		VARCHAR2(4000);

v_AppWorkspaceName	VARCHAR2(1000);
v_ApplicationID		VARCHAR2(1000);
v_AppPublicUser		VARCHAR2(1000);

BEGIN
	DBMS_OUTPUT.PUT_LINE('.');
	v_ExpectedNo := 1;
	SELECT value INTO v_WDMConfigValue FROM waters.aem_configuration_parameters WHERE parameter = 'APEX_WORKSPACE_NAME';
	v_ApexQuery := 'SELECT COUNT(*) FROM '||:V_ApexSchema||'.apex_workspaces WHERE workspace = '''||v_WDMConfigValue||'''';
	EXECUTE IMMEDIATE v_ApexQuery INTO v_Count;
	IF (v_Count = v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('The WDM workspace '||v_WDMConfigValue||' exists in APEX.');
	ELSIF (v_Count < v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: the WDM workspace '||v_WDMConfigValue||' does NOT exist in APEX!  WDM will not be functional without this workspace!');
	ELSIF (v_Count > v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('!!! WARNING: more than one WDM workspace '||v_WDMConfigValue||' exists in APEX!');
	END IF;

	DBMS_OUTPUT.PUT_LINE('.');
	v_ApexQuery := 'SELECT COUNT(*) FROM '||:V_ApexSchema||'.apex_applications WHERE application_name = ''Waters Database Manager''';
	EXECUTE IMMEDIATE v_ApexQuery INTO v_Count;
	IF (v_Count = v_ExpectedNo)	THEN
		DBMS_OUTPUT.PUT_LINE('The application ''Waters Database Manager'' exists in APEX.');
		v_ApexQuery := 'SELECT workspace, application_id, public_user FROM '||:V_ApexSchema||'.apex_applications WHERE application_name = ''Waters Database Manager''';
		EXECUTE IMMEDIATE v_ApexQuery INTO v_AppWorkspaceName, v_ApplicationID, v_AppPublicUser;

		:V_WDMAppID := v_ApplicationID;
		DBMS_OUTPUT.PUT_LINE('	Workspace     : '||v_AppWorkspaceName);
		IF (v_AppWorkspaceName != v_WDMConfigValue)	THEN	DBMS_OUTPUT.PUT_LINE('	!!!!! ERROR: The WDM application''s workspace is not set to '''||v_WDMConfigValue||'''!');
		ELSE							DBMS_OUTPUT.PUT_LINE('	The WDM application''s workspace matches the WDM config parameters.');
		END IF;
		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('	Application ID: '||:V_WDMAppID);
		DBMS_OUTPUT.PUT_LINE('	User account  : '||v_AppPublicUser);
	ELSIF (v_Count < v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: the application ''Waters Database Manager'' does NOT exist in APEX!  WDM will not be functional without this application!');
	ELSIF (v_Count > v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('!!! WARNING: more than one application ''Waters Database Manager'' exists in APEX!');
	END IF;

	-- Check the email server settings in Apex
	v_ApexQuery := 'SELECT value FROM '||:V_ApexSchema||'.apex_instance_parameters WHERE name = ''SMTP_HOST_ADDRESS''';
	EXECUTE IMMEDIATE v_ApexQuery INTO v_ApexConfigValue;
	DBMS_OUTPUT.PUT_LINE('.');
	DBMS_OUTPUT.PUT_LINE('SMTP host: '||v_ApexConfigValue);

	v_ApexQuery := 'SELECT value FROM '||:V_ApexSchema||'.apex_instance_parameters WHERE name = ''SMTP_HOST_PORT''';
	EXECUTE IMMEDIATE v_ApexQuery INTO v_ApexConfigValue;
	DBMS_OUTPUT.PUT_LINE('SMTP port: '||v_ApexConfigValue);
END;
/

DECLARE
v_Count			PLS_INTEGER := 0;
v_ExpectedNo		PLS_INTEGER;
v_ApexQuery		VARCHAR2(4000);

v_AppWorkspaceName	VARCHAR2(1000);
v_AppTabName		VARCHAR2(1000);
v_ApplicationID		VARCHAR2(1000);
v_AppPublicUser		VARCHAR2(1000);

TYPE CharList		IS TABLE OF VARCHAR2(500);
t_WDMAppPages		CharList;
t_WDMTabsList		CharList;
t_WDMProcesses		CharList;
t_WDMLists		CharList;
t_WDMAuthSchemes	CharList;
t_WDMApexPlugins	CharList;

BEGIN
	IF (:V_WDMVersionsAsNum < 4100)		THEN
		t_WDMTabsList    := CharList('T_DASHBOARD','Backups','Server','Schema','Import/Export','Software and Support','Manage ASM','T_ADMINISTRATION');
		t_WDMAppPages    := CharList('Global Page - Desktop','Availability','Home','Server','Schema','Data Movement','Configuration','ASM Home','ASM Disk Group','View Backup Settings','Backup Disk Configuration','Schedule Backup','Manage Current Backups','Control Files','Administration Menu','Email Server Configuration','Stamp Disc','Backup Jobs','Scheduled Tasks','Job Run Details','ASM Disk Groups','Backup Run Details','View Backup Log File','Backup Sets','Backup Set Configuration','Backup Policy Configuration','Export Type','Export Options','Export Confirm','Datapump Job History','View Datapump Log File','Datapump Import Start','Jobs','Datapump Import Options','Datapump Confirm Import','Tablespaces','Temporary Tablespace Groups','Datafiles','Rollback Segments','Redo Log Groups','Archived Logs','Automatic Undo Man','Initialization parameters','Database Feature Usage','Database Users','Database Roles','Manage Database User','Get Support','Alert History','Profiles','Alert Log Contents','Schedules','Programs','Help','Tables','Indexes','View Source','Synonyms','Views','Database Links','Sequences','Directories','Database Role Privileges','Configure Notifications','Manage Datafiles','Configure Datafile','Manage ORA-Error Exclusion List','Packages','Package Bodies','Procedures','Functions','Triggers','Materialized Views','Materialized View Logs','XML Type Views','XML Indexes','Text Indexes','Login','Application Users','Application User','Application Privileges','Set Password','Application Configuration','Configuration Parameter','Application Configuration Audit');
		t_WDMProcesses   := CharList('Check for ASM use','SET_ITEMS','get db name','Get Waters product name');
		t_WDMLists       := CharList('Backup and Recovery Conf','Metro Menu','Administration NavList','Favourites','Tabs - ASM','Backup and Recovery Manage','Notifications','Import Export','Storage Nav List','Database Conf NavList','Oracle Scheduler NavList','Oracle User Management','Schema NavList','Tabs - Backup Settings','Tabs - Software & Support','Database Alert Log','Scheduled Tasks');
		t_WDMAuthSchemes := CharList('SUPPORT','SYSADMIN','ADMIN','READONLY');
		t_WDMApexPlugins := CharList('BE.CTB.ALERTIFY','COM_SKILLBUILDERS_MODAL_PAGE','MULEDEV.SERVER_REGION_REFRESH');
	ELSIF (:V_WDMVersionsAsNum >= 4100 AND :V_WDMVersionsAsNum < 4200)	THEN
		t_WDMTabsList    := CharList('T_DASHBOARD','Backups','Server','Schema','Software and Support','Manage ASM','T_ADMINISTRATION');
		t_WDMAppPages    := CharList('Administration Menu','Alert History','Alert Log Contents','Application Configuration','Application Configuration Audit','Application Privileges','Application User','Application Users','Archived Logs','ASM Disk Group','ASM Disk Groups','ASM Home','Automatic Undo Man','Availability','Backup Disk Configuration','Backup Jobs','Backup Policy Configuration','Backup Run Details','Backup Set Configuration','Backup Sets','Configuration','Configuration Parameter','Configure Datafile','Configure Notifications','Control Files','Database Feature Usage','Database Links','Database Role Privileges','Database Roles','Database Users','Datafiles','Directories','Email Server Configuration','Functions','Get Support','Global Page - Desktop','Help','Home','Indexes','Initialization parameters','Job Run Details','Jobs','Login','Manage Current Backups','Manage Database User','Manage Datafiles','Manage ORA-Error Exclusion List','Materialized View Logs','Materialized Views','Package Bodies','Packages','Procedures','Profiles','Programs','Redo Log Groups','Rollback Segments','Schedule Backup','Scheduled Tasks','Schedules','Schema','Sequences','Server','Set Password','Stamp Disc','Synonyms','Tables','Tablespaces','Temporary Tablespace Groups','Text Indexes','Triggers','View Backup Log File','View Backup Settings','View Source','Views','XML Indexes','XML Type Views');
		t_WDMProcesses   := CharList('Check for ASM use','SET_ITEMS','get db name','Get Waters product name');
		t_WDMLists       := CharList('Backup and Recovery Conf','Metro Menu','Administration NavList','Favourites','Tabs - ASM','Backup and Recovery Manage','Notifications','Storage Nav List','Database Conf NavList','Oracle Scheduler NavList','Oracle User Management','Schema NavList','Tabs - Backup Settings','Tabs - Software & Support','Database Alert Log','Scheduled Tasks');
		t_WDMAuthSchemes := CharList('SUPPORT','SYSADMIN','ADMIN','READONLY');
		t_WDMApexPlugins := CharList('BE.CTB.ALERTIFY','COM_SKILLBUILDERS_MODAL_PAGE','MULEDEV.SERVER_REGION_REFRESH');
	ELSIF (:V_WDMVersionsAsNum >= 4200)	THEN
		t_WDMTabsList    := CharList('T_DASHBOARD','Backups','Server','Schema','Software and Support','Manage ASM','T_ADMINISTRATION');
		t_WDMAppPages    := CharList('Administration Menu','Alert History','Alert Log Contents','Application Configuration','Application Configuration Audit','Application Privileges','Application User','Application Users','Archived Logs','ASM Disk Group','ASM Disk Groups','ASM Home','Automatic Undo Man','Availability','Backup Disk Configuration','Backup Jobs','Backup Policy Configuration','Backup Run Details','Backup Set Configuration','Backup Sets','Configuration','Configuration Parameter','Configure Datafile','Configure Notifications','Control Files','Database Feature Usage','Database Links','Database Role Privileges','Database Roles','Database Users','Datafiles','Directories','Email Log','Email Queue','Email Server Configuration','Functions','Get Support','Global Page - Desktop','Help','Home','Indexes','Initialization parameters','Job Run Details','Jobs','Login','Manage Current Backups','Manage Database User','Manage Datafiles','Manage ORA-Error Exclusion List','Materialized View Logs','Materialized Views','Package Bodies','Packages','Procedures','Profiles','Programs','Redo Log Groups','Rollback Segments','Schedule Backup','Scheduled Tasks','Schedules','Schema','Sequences','Server','Set Password','Stamp Disc','Synonyms','Tables','Tablespaces','Temporary Tablespace Groups','Text Indexes','Triggers','View Backup Log File','View Backup Settings','View Source','Views','XML Indexes','XML Type Views');
		t_WDMProcesses   := CharList('Check for ASM use','SET_ITEMS','get db name','Get Waters product name');
		t_WDMLists       := CharList('Backup and Recovery Conf','Metro Menu','Administration NavList','Favourites','Tabs - ASM','Backup and Recovery Manage','Notifications','Storage Nav List','Database Conf NavList','Oracle Scheduler NavList','Oracle User Management','Schema NavList','Tabs - Backup Settings','Tabs - Software & Support','Database Alert Log','Scheduled Tasks');
		t_WDMAuthSchemes := CharList('SUPPORT','SYSADMIN','ADMIN','READONLY');
		t_WDMApexPlugins := CharList('BE.CTB.ALERTIFY','COM_SKILLBUILDERS_MODAL_PAGE','MULEDEV.SERVER_REGION_REFRESH');
	END IF;
	DBMS_OUTPUT.PUT_LINE('.');
	DBMS_OUTPUT.PUT_LINE('.');
	DBMS_OUTPUT.PUT_LINE('Determining whether any of the expected APEX objects for WDM are missing; missing objects, if any, will be flagged below:');

	DBMS_OUTPUT.PUT_LINE('.');
	v_ExpectedNo := t_WDMAppPages.COUNT;
	v_ApexQuery  := 'SELECT COUNT(*) FROM '||:V_ApexSchema||'.apex_application_pages WHERE application_id = '||:V_WDMAppID;
	EXECUTE IMMEDIATE v_ApexQuery INTO v_Count;
	IF (v_Count = v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('The WDM application has the correct number of pages ('||v_ExpectedNo||' expected, '||v_Count||' found).');
	ELSIF (v_Count < v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: the WDM application has less than the expected number of pages ('||v_ExpectedNo||' expected, '||v_Count||' found).');
	ELSIF (v_Count > v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('!!! WARNING: the WDM application has more than the expected number of pages ('||v_ExpectedNo||' expected, '||v_Count||' found).');
	END IF;

	FOR indx IN 1 .. t_WDMAppPages.COUNT
	LOOP
		v_AppTabName := t_WDMAppPages(indx);
		v_ApexQuery := 'SELECT COUNT(*) FROM '||:V_ApexSchema||'.apex_application_pages WHERE application_id = '||:V_WDMAppID||' AND page_name = '''||v_AppTabName||'''';
		EXECUTE IMMEDIATE v_ApexQuery INTO v_Count;
		IF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: WDM page '||v_AppTabName||' is not installed!');	END IF;
	END LOOP;
	


	DBMS_OUTPUT.PUT_LINE('.');
	v_ExpectedNo := t_WDMTabsList.COUNT;
	v_ApexQuery  := 'SELECT COUNT(*) FROM '||:V_ApexSchema||'.apex_application_tabs WHERE application_id = '||:V_WDMAppID;
	EXECUTE IMMEDIATE v_ApexQuery INTO v_Count;
	IF (v_Count = v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('The WDM application has the correct number of tabs ('||v_ExpectedNo||' expected, '||v_Count||' found).');
	ELSIF (v_Count < v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: the WDM application has less than the expected number of tabs ('||v_ExpectedNo||' expected, '||v_Count||' found).');
	ELSIF (v_Count > v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('!!! WARNING: the WDM application has more than the expected number of tabs ('||v_ExpectedNo||' expected, '||v_Count||' found).');
	END IF;

	FOR indx IN 1 .. t_WDMTabsList.COUNT
	LOOP
		v_AppTabName := t_WDMTabsList(indx);
		v_ApexQuery := 'SELECT COUNT(*) FROM '||:V_ApexSchema||'.apex_application_tabs WHERE application_id = '||:V_WDMAppID||' AND tab_name = '''||v_AppTabName||'''';
		EXECUTE IMMEDIATE v_ApexQuery INTO v_Count;
		IF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: Apex tab set '||v_AppTabName||' is not installed!');	END IF;
	END LOOP;



	DBMS_OUTPUT.PUT_LINE('.');
	v_ExpectedNo := t_WDMProcesses.COUNT;
	v_ApexQuery  := 'SELECT COUNT(*) FROM '||:V_ApexSchema||'.apex_application_processes WHERE application_id = '||:V_WDMAppID;
	EXECUTE IMMEDIATE v_ApexQuery INTO v_Count;
	IF (v_Count = v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('The WDM application has the correct number of processes ('||v_ExpectedNo||' expected, '||v_Count||' found).');
	ELSIF (v_Count < v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: the WDM application has less than the expected number of processes ('||v_ExpectedNo||' expected, '||v_Count||' found).');
	ELSIF (v_Count > v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('!!! WARNING: the WDM application has more than the expected number of processes ('||v_ExpectedNo||' expected, '||v_Count||' found).');
	END IF;

	FOR indx IN 1 .. t_WDMProcesses.COUNT
	LOOP
		v_AppTabName := t_WDMProcesses(indx);
		v_ApexQuery := 'SELECT COUNT(*) FROM '||:V_ApexSchema||'.apex_application_processes WHERE application_id = '||:V_WDMAppID||' AND process_name = '''||v_AppTabName||'''';
		EXECUTE IMMEDIATE v_ApexQuery INTO v_Count;
		IF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: WDM process '||v_AppTabName||' is not installed!');	END IF;
	END LOOP;



	DBMS_OUTPUT.PUT_LINE('.');
	v_ExpectedNo := t_WDMLists.COUNT;
	v_ApexQuery  := 'SELECT COUNT(*) FROM '||:V_ApexSchema||'.apex_application_lists WHERE application_id = '||:V_WDMAppID;
	EXECUTE IMMEDIATE v_ApexQuery INTO v_Count;
	IF (v_Count = v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('The WDM application has the correct number of lists ('||v_ExpectedNo||' expected, '||v_Count||' found).');
	ELSIF (v_Count < v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: the WDM application has less than the expected number of lists ('||v_ExpectedNo||' expected, '||v_Count||' found).');
	ELSIF (v_Count > v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('!!! WARNING: the WDM application has more than the expected number of lists ('||v_ExpectedNo||' expected, '||v_Count||' found).');
	END IF;

	FOR indx IN 1 .. t_WDMLists.COUNT
	LOOP
		v_AppTabName := t_WDMLists(indx);
		v_ApexQuery := 'SELECT COUNT(*) FROM '||:V_ApexSchema||'.apex_application_lists WHERE application_id = '||:V_WDMAppID||' AND list_name = '''||v_AppTabName||'''';
		EXECUTE IMMEDIATE v_ApexQuery INTO v_Count;
		IF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: WDM list '||v_AppTabName||' is not installed!');	END IF;
	END LOOP;



	DBMS_OUTPUT.PUT_LINE('.');
	v_ExpectedNo := 1;
	v_ApexQuery := 'SELECT COUNT(*) FROM '||:V_ApexSchema||'.apex_appl_user_interfaces WHERE application_id = '||:V_WDMAppID;
	EXECUTE IMMEDIATE v_ApexQuery INTO v_Count;
	IF (v_Count = v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('The WDM application has the correct number of user interfaces ('||v_ExpectedNo||' expected, '||v_Count||' found).');
	ELSIF (v_Count < v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: the WDM application has less than the expected number of user interfaces ('||v_ExpectedNo||' expected, '||v_Count||' found).');
	ELSIF (v_Count > v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('!!! WARNING: the WDM application has more than the expected number of user interfaces ('||v_ExpectedNo||' expected, '||v_Count||' found).');
	END IF;



	DBMS_OUTPUT.PUT_LINE('.');
	v_ExpectedNo := t_WDMAuthSchemes.COUNT;
	v_ApexQuery  := 'SELECT COUNT(*) FROM '||:V_ApexSchema||'.apex_application_authorization WHERE application_id = '||:V_WDMAppID;
	EXECUTE IMMEDIATE v_ApexQuery INTO v_Count;
	IF (v_Count = v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('The WDM application has the correct number of authorization schemes ('||v_ExpectedNo||' expected, '||v_Count||' found).');
	ELSIF (v_Count < v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: the WDM application has less than the expected number of authorization schemes ('||v_ExpectedNo||' expected, '||v_Count||' found).');
	ELSIF (v_Count > v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('!!! WARNING: the WDM application has more than the expected number of authorization schemes ('||v_ExpectedNo||' expected, '||v_Count||' found).');
	END IF;

	FOR indx IN 1 .. t_WDMAuthSchemes.COUNT
	LOOP
		v_AppTabName := t_WDMAuthSchemes(indx);
		v_ApexQuery := 'SELECT COUNT(*) FROM '||:V_ApexSchema||'.apex_application_authorization WHERE application_id = '||:V_WDMAppID||' AND authorization_scheme_name = '''||v_AppTabName||'''';
		EXECUTE IMMEDIATE v_ApexQuery INTO v_Count;
		IF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: Apex authorization scheme '||v_AppTabName||' is not installed!');	END IF;
	END LOOP;



	DBMS_OUTPUT.PUT_LINE('.');
	v_ExpectedNo := t_WDMApexPlugins.COUNT;
	v_ApexQuery  := 'SELECT COUNT(*) FROM '||:V_ApexSchema||'.apex_appl_plugins WHERE application_id = '||:V_WDMAppID;
	EXECUTE IMMEDIATE v_ApexQuery INTO v_Count;
	IF (v_Count = v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('The WDM application has the correct number of plugins ('||v_ExpectedNo||' expected, '||v_Count||' found).');
	ELSIF (v_Count < v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: the WDM application has less than the expected number of plugins ('||v_ExpectedNo||' expected, '||v_Count||' found).');
	ELSIF (v_Count > v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('!!! WARNING: the WDM application has more than the expected number of plugins ('||v_ExpectedNo||' expected, '||v_Count||' found).');
	END IF;

	FOR indx IN 1 .. t_WDMApexPlugins.COUNT
	LOOP
		v_AppTabName := t_WDMApexPlugins(indx);
		v_ApexQuery := 'SELECT COUNT(*) FROM '||:V_ApexSchema||'.apex_appl_plugins WHERE application_id = '||:V_WDMAppID||' AND name = '''||v_AppTabName||'''';
		EXECUTE IMMEDIATE v_ApexQuery INTO v_Count;
		IF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: Apex plugin '||v_AppTabName||' is not installed!');	END IF;
	END LOOP;
END;
/

COLUMN parameter FORMAT a30
COLUMN value FORMAT a50
PROMPT
PROMPT WDM parameters:
SELECT parameter, value FROM waters.aem_configuration_parameters WHERE parameter NOT LIKE '%PASSWORD%' ORDER BY 1;


PROMPT
PROMPT ___________________________________________________________________________________________________________
PROMPT WDM primary key constraints
PROMPT

DECLARE
v_Count		PLS_INTEGER;
v_ConsName	SYS.DBA_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
v_ConsIndxName	SYS.DBA_CONSTRAINTS.INDEX_NAME%TYPE;
v_ConsTablName	SYS.DBA_CONSTRAINTS.TABLE_NAME%TYPE;
v_ExpectedNo	PLS_INTEGER;
v_SchemaName	VARCHAR2(500);

TYPE CharList	IS TABLE OF VARCHAR2(500);
t_SchemaList	CharList;
t_ConsNameList	CharList;
t_ConsIndxList	CharList;
t_ConsTablList	CharList;

BEGIN
	v_SchemaName := 'WATERS';

	IF (:V_WDMVersionsAsNum < 4100)		THEN
		t_ConsNameList := CharList('AEM_ALERT_PK','AEM_BACKUP_SCHEDULE_PK','AEM_CPA_PK','AEM_DATAPUMP_JOBS_PK','AEM_DRY_PK','AEM_ORA_PK','AEM_RPT_PK','AEM_RCL_PK','SEC_RLE_PK','SEC_USR_PK','SEC_RGD_PK');
		t_ConsIndxList := CharList('AEM_ALERT_PK','AEM_BACKUP_SCHEDULE_PK','AEM_CPA_PK','AEM_DATAPUMP_JOBS_PK','AEM_DRY_PK','AEM_ORA_PK','AEM_RPT_PK','AEM_RCL_PK','SEC_RLE_PK','SEC_USR_PK','SEC_RGD_PK');
		t_ConsTablList := CharList('AEM_ALERTS','AEM_BACKUP_SCHEDULE','AEM_CONFIG_PARAMETERS_AUDIT','AEM_DATAPUMP_JOBS','AEM_DIRECTORIES','AEM_ORA','AEM_REPORTS','AEM_REPORT_COLUMN_LABELS','SEC_ROLES','SEC_USERS','SEC_ROLES_GRANTED');
	ELSIF (:V_WDMVersionsAsNum >= 4100 AND :V_WDMVersionsAsNum < 4200)	THEN
		t_ConsNameList := CharList('AEM_ALERT_PK','AEM_BACKUP_SCHEDULE_PK','AEM_CPA_PK','AEM_DRY_PK','AEM_ORA_PK','AEM_RPT_PK','AEM_RCL_PK','SEC_RLE_PK','SEC_USR_PK','SEC_RGD_PK');
		t_ConsIndxList := CharList('AEM_ALERT_PK','AEM_BACKUP_SCHEDULE_PK','AEM_CPA_PK','AEM_DRY_PK','AEM_ORA_PK','AEM_RPT_PK','AEM_RCL_PK','SEC_RLE_PK','SEC_USR_PK','SEC_RGD_PK');
		t_ConsTablList := CharList('AEM_ALERTS','AEM_BACKUP_SCHEDULE','AEM_CONFIG_PARAMETERS_AUDIT','AEM_DIRECTORIES','AEM_ORA','AEM_REPORTS','AEM_REPORT_COLUMN_LABELS','SEC_ROLES','SEC_USERS','SEC_ROLES_GRANTED');
	ELSIF (:V_WDMVersionsAsNum >= 4200)	THEN
		t_ConsNameList := CharList('AEM_ALERT_PK','AEM_BACKUP_SCHEDULE_PK','AEM_CPA_PK','AEM_DRY_PK','AEM_ORA_PK','AEM_RPT_PK','AEM_RCL_PK','SEC_RLE_PK','SEC_USR_PK','SEC_RGD_PK','AEM_TS_ALERT_PK');
		t_ConsIndxList := CharList('AEM_ALERT_PK','AEM_BACKUP_SCHEDULE_PK','AEM_CPA_PK','AEM_DRY_PK','AEM_ORA_PK','AEM_RPT_PK','AEM_RCL_PK','SEC_RLE_PK','SEC_USR_PK','SEC_RGD_PK','AEM_TS_ALERT_PK');
		t_ConsTablList := CharList('AEM_ALERTS','AEM_BACKUP_SCHEDULE','AEM_CONFIG_PARAMETERS_AUDIT','AEM_DIRECTORIES','AEM_ORA','AEM_REPORTS','AEM_REPORT_COLUMN_LABELS','SEC_ROLES','SEC_USERS','SEC_ROLES_GRANTED','AEM_TS_ALERTS');
	END IF;
	v_ExpectedNo   := t_ConsNameList.COUNT;

	SELECT COUNT(constraint_name) INTO v_Count from dba_constraints where owner = v_SchemaName AND CONSTRAINT_TYPE = 'P' AND TABLE_NAME NOT LIKE 'DR%' AND TABLE_NAME NOT LIKE 'BIN$%';
	IF (v_Count = v_ExpectedNo) THEN	DBMS_OUTPUT.PUT_LINE('The '||v_SchemaName||' schema owns the correct number of primary key constraints ('||v_ExpectedNo||' expected, '||v_Count||' found)');
	ELSE					DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: The '||v_schemaName||' schema does NOT own the correct number of primary key constraints ('||v_ExpectedNo||' expected, '||v_Count||' found)!');
	END IF;

	FOR indx IN 1 .. t_ConsNameList.COUNT
	LOOP
		v_ConsName := t_ConsNameList(indx);
		SELECT COUNT(*) INTO v_Count FROM dba_constraints WHERE owner = v_SchemaName AND constraint_name = v_ConsName;
		IF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: Primary key constraint: '||v_SchemaName||'.'||v_ConsName||' is not present!');
		ELSE
			DBMS_OUTPUT.PUT_LINE('Primary key constraint: '||v_SchemaName||'.'||v_ConsName||' is present');
			SELECT index_name, table_name INTO v_ConsIndxName, v_ConsTablName FROM dba_constraints WHERE owner = v_SchemaName AND constraint_name = v_ConsName;
			IF (v_ConsTablName = t_ConsTablList(indx))	THEN	DBMS_OUTPUT.PUT_LINE('-- on table: '||v_ConsTablName||' is correct (expected '||t_ConsTablList(indx)||')');
			ELSE							DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: on table: '||v_ConsTablName||' is NOT correct (expected '||t_ConsTablList(indx)||')!');
			END IF;

			IF (v_ConsIndxName = t_ConsIndxList(indx))	THEN	DBMS_OUTPUT.PUT_LINE('-- with index: '||v_ConsIndxName||' is correct (expected '||t_ConsIndxList(indx)||')');
			ELSE							DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: on table: '||v_ConsIndxName||' is NOT correct (expected '||t_ConsIndxList(indx)||')!');
			END IF;
		END IF;
	END LOOP;
END;
/

PROMPT
PROMPT ___________________________________________________________________________________________________________
PROMPT WDM non-primary key constraints
PROMPT

DECLARE
v_constab	SYS.DBA_CONSTRAINTS.TABLE_NAME%TYPE;
v_constat	SYS.DBA_CONSTRAINTS.STATUS%TYPE;
v_Count		PLS_INTEGER := 0;
v_ConsName	SYS.DBA_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
v_ExpectedNo	PLS_INTEGER := 0;
v_SchemaName	VARCHAR2(500);

CURSOR C_CONSTAT IS SELECT CONSTRAINT_NAME, TABLE_NAME, STATUS from dba_constraints where owner = v_SchemaName AND TABLE_NAME NOT LIKE 'BIN%' AND TABLE_NAME NOT LIKE '%BAK' AND STATUS != 'ENABLED';

BEGIN
	IF (:V_WDMVersionsAsNum < 4100)						THEN	v_ExpectedNo := 84;
	ELSIF (:V_WDMVersionsAsNum >= 4100 AND :V_WDMVersionsAsNum < 4200)	THEN	v_ExpectedNo := 83;
	ELSIF (:V_WDMVersionsAsNum >= 4200)					THEN	v_ExpectedNo := 84;
	END IF;
	v_SchemaName := 'WATERS';
	SELECT COUNT(constraint_name) INTO v_Count from dba_constraints where owner = v_SchemaName AND TABLE_NAME NOT LIKE 'BIN%' AND TABLE_NAME NOT LIKE 'DR%' AND TABLE_NAME NOT LIKE '%BAK';
	IF (v_Count >= v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('The '||v_SchemaName||' schema owns the expected number of constraints (at least '||v_ExpectedNo||' expected, '||v_Count||' found)');
	ELSE					DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: the '||v_SchemaName||' schema owns less than the expected number of constraints (at least '||v_ExpectedNo||' expected, '||v_Count||' found)!');
	END IF;

	DBMS_OUTPUT.PUT_LINE('.');

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
END;
/

PROMPT
PROMPT ___________________________________________________________________________________________________________
PROMPT WDM privilege checks

PROMPT
PROMPT Object privileges granted to WDM schemas:
PROMPT

DECLARE
v_Count			PLS_INTEGER := 0;
v_ExpectedNo		PLS_INTEGER;
v_PrivName		dba_tab_privs.privilege%TYPE;
v_PrivObjOwner		dba_tab_privs.owner%TYPE;
v_PrivObjName		dba_tab_privs.table_name%TYPE;

TYPE CharList		IS TABLE OF VARCHAR2(500);
t_SchemaNames		CharList;
t_WDMPrivNames		CharList;
t_WDMPrivObjOwners	CharList;
t_WDMPrivObjNames	charList;

BEGIN
	IF (:V_WDMVersionsAsNum < 4100)		THEN
		t_WDMPrivNames     := CharList('SELECT',   'SELECT',       'SELECT',               'SELECT',         'SELECT',           'SELECT',            'SELECT',               'SELECT',                       'SELECT',     'SELECT',          'EXECUTE',    'EXECUTE','EXECUTE',            'READ',       'READ',    'WRITE',      'WRITE',   'EXECUTE',                'SELECT',                 'EXECUTE');
		t_WDMPrivObjOwners := CharList('SYS',      'SYS',          'SYS',                  'SYS',            'SYS',              'SYS',               'SYS',                  'SYS',                          'SYS',        'SYS',             'SYS',        'SYS',    'SYS',                'SYS',        'SYS',     'SYS',        'SYS',     :V_ApexSchema,            :V_ApexSchema,            :V_ApexSchema);
		t_WDMPrivObjNames  := CharList('V_$OSSTAT','V_$TABLESPACE','V_$RMAN_CONFIGURATION','DBA_TABLESPACES','V_$DIAG_ALERT_EXT','DBA_SCHEDULER_JOBS','DBA_SCHEDULER_JOB_LOG','DBA_SCHEDULER_JOB_RUN_DETAILS','V_X$KRBMSFT','V_DIAG_ALERT_EXT','DBMS_CRYPTO','DBMS_AQ','DBMS_BACKUP_RESTORE','AEM_SCRIPTS','AEM_LOGS','AEM_SCRIPTS','AEM_LOGS','WWV_FLOW_INSTANCE_ADMIN','WWV_FLOW_PLATFORM_PREFS','WWV_FLOW_PLATFORM');
	ELSIF (:V_WDMVersionsAsNum >= 4100)	THEN
		t_WDMPrivNames     := CharList('SELECT',   'SELECT',       'SELECT',               'SELECT',         'SELECT',           'SELECT',            'SELECT',               'SELECT',                       'SELECT',          'EXECUTE',    'EXECUTE','EXECUTE',            'READ',       'READ',    'WRITE',      'WRITE',   'EXECUTE',                'SELECT',                 'EXECUTE');
		t_WDMPrivObjOwners := CharList('SYS',      'SYS',          'SYS',                  'SYS',            'SYS',              'SYS',               'SYS',                  'SYS',                          'SYS',             'SYS',        'SYS',    'SYS',                'SYS',        'SYS',     'SYS',        'SYS',     :V_ApexSchema,            :V_ApexSchema,            :V_ApexSchema);
		t_WDMPrivObjNames  := CharList('V_$OSSTAT','V_$TABLESPACE','V_$RMAN_CONFIGURATION','DBA_TABLESPACES','V_$DIAG_ALERT_EXT','DBA_SCHEDULER_JOBS','DBA_SCHEDULER_JOB_LOG','DBA_SCHEDULER_JOB_RUN_DETAILS','V_DIAG_ALERT_EXT','DBMS_CRYPTO','DBMS_AQ','DBMS_BACKUP_RESTORE','AEM_SCRIPTS','AEM_LOGS','AEM_SCRIPTS','AEM_LOGS','WWV_FLOW_INSTANCE_ADMIN','WWV_FLOW_PLATFORM_PREFS','WWV_FLOW_PLATFORM');
	END IF;
	v_ExpectedNo := t_WDMPrivNames.COUNT;

	SELECT COUNT(*) INTO v_Count FROM dba_tab_privs WHERE grantee = 'WATERS';
	IF (v_Count = v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('The WATERS schema has the correct number of object privileges ('||v_ExpectedNo||' expected, '||v_Count||' found).');
	ELSIF (v_Count < v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: the WATERS schema has fewer than the expected number of object privileges ('||v_ExpectedNo||' expected, '||v_Count||' found)!');
	ELSIF (v_Count > v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('!!! WARNING: the WATERS schema has more than the expected number of object privileges ('||v_ExpectedNo||' expected, '||v_Count||' found)!');
	END IF;

	FOR indx IN 1 .. t_WDMPrivNames.COUNT
	LOOP
		v_PrivName     := t_WDMPrivNames(indx);
		v_PrivObjOwner := t_WDMPrivObjOwners(indx);
		v_PrivObjName  := t_WDMPrivObjNames(indx);
		SELECT COUNT(*) INTO v_Count FROM dba_tab_privs WHERE grantee = 'WATERS' AND privilege = v_PrivName AND owner = v_PrivObjOwner AND table_name = v_PrivObjName;
		IF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: WATERS was not granted '||v_PrivName||' on '||v_PrivObjOwner||'.'||v_PrivObjName);
		ELSIF (v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('-- WATERS was granted '||v_PrivName||' on '||v_PrivObjOwner||'.'||v_PrivObjName);
		END IF;
	END LOOP;
END;
/

COLUMN privilege FORMAT a30
COLUMN object_owner FORMAT a30
COLUM object_name FORMAT a30
COLUMN grantee FORMAT a30
SELECT grantee, privilege, owner "object_owner", table_name "object_name" FROM dba_tab_privs WHERE grantee = 'WATERS' ORDER BY 2, 3;

PROMPT

PROMPT
PROMPT System privileges granted to WDM schemas:
PROMPT

DECLARE
v_Count			PLS_INTEGER := 0;
v_ExpectedNo		PLS_INTEGER;
v_PrivName		dba_sys_privs.privilege%TYPE;

TYPE CharList		IS TABLE OF VARCHAR2(500);
t_SchemaNames		CharList;
t_PrivNames		CharList;

BEGIN
	IF (:V_WDMVersionsAsNum < 4100)		THEN
		t_SchemaNames := CharList('C##WATERS_WDMVIEWS','WATERS','WATERS','WATERS','WATERS','WATERS','WATERS','WATERS','WATERS','WATERS','WATERS','WATERS','WATERS','WATERS','WATERS','WATERS','WATERS','WATERS','WATERS','WATERS','WATERS','WATERS','WATERS','WATERS','WATERS','WATERS','WATERS','WATERS','WATERS','WATERS','WATERS','WATERS','WATERS','WATERS','WATERS','WATERS','WATERS');
		t_PrivNames   := CharList('CREATE SESSION','ALTER ANY INDEX','ALTER ANY PROCEDURE','ALTER ANY TABLE','ALTER ANY TRIGGER','ALTER DATABASE','ALTER SESSION','ALTER SYSTEM','ALTER TABLESPACE','ALTER USER','CREATE ANY DIRECTORY','CREATE ANY INDEX','CREATE ANY TABLE','CREATE ANY TYPE','CREATE CLUSTER','CREATE CREDENTIAL','CREATE DATABASE LINK','CREATE DIMENSION','CREATE EXTERNAL JOB','CREATE INDEXTYPE','CREATE JOB','CREATE MATERIALIZED VIEW','CREATE OPERATOR','CREATE PROCEDURE','CREATE PUBLIC SYNONYM','CREATE SEQUENCE','CREATE SESSION','CREATE SYNONYM','CREATE TABLE','CREATE TRIGGER','CREATE TYPE','CREATE VIEW','DROP ANY DIRECTORY','DROP PUBLIC SYNONYM','GLOBAL QUERY REWRITE','LOCK ANY TABLE','SELECT ANY DICTIONARY');
	ELSIF (:V_WDMVersionsAsNum >= 4100)	THEN
		t_SchemaNames := CharList('WATERS','WATERS','WATERS','WATERS','WATERS','WATERS','WATERS','WATERS','WATERS','WATERS','WATERS','WATERS','WATERS','WATERS','WATERS','WATERS','WATERS','WATERS','WATERS','WATERS','WATERS','WATERS','WATERS','WATERS','WATERS','WATERS','WATERS','WATERS','WATERS','WATERS','WATERS','WATERS','WATERS','WATERS','WATERS','WATERS');
		t_PrivNames   := CharList('ALTER ANY INDEX','ALTER ANY PROCEDURE','ALTER ANY TABLE','ALTER ANY TRIGGER','ALTER DATABASE','ALTER SESSION','ALTER SYSTEM','ALTER TABLESPACE','ALTER USER','CREATE ANY DIRECTORY','CREATE ANY INDEX','CREATE ANY TABLE','CREATE ANY TYPE','CREATE CLUSTER','CREATE CREDENTIAL','CREATE DATABASE LINK','CREATE DIMENSION','CREATE EXTERNAL JOB','CREATE INDEXTYPE','CREATE JOB','CREATE MATERIALIZED VIEW','CREATE OPERATOR','CREATE PROCEDURE','CREATE PUBLIC SYNONYM','CREATE SEQUENCE','CREATE SESSION','CREATE SYNONYM','CREATE TABLE','CREATE TRIGGER','CREATE TYPE','CREATE VIEW','DROP ANY DIRECTORY','DROP PUBLIC SYNONYM','GLOBAL QUERY REWRITE','LOCK ANY TABLE','SELECT ANY DICTIONARY');
	END IF;
	v_ExpectedNo := t_PrivNames.COUNT;

	SELECT COUNT(*) INTO v_Count FROM dba_sys_privs WHERE grantee IN('WATERS','C##WATERS_WDMVIEWS');
	IF (v_Count = v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('The WDM schemas have the correct number of system privileges ('||v_ExpectedNo||' expected, '||v_Count||' found).');
	ELSIF (v_Count < v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: the WDM schemas have fewer than the expected number of system privileges ('||v_ExpectedNo||' expected, '||v_Count||' found)!');
	ELSIF (v_Count > v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('!!! WARNING: the WDM schemas have more than the expected number of system privileges ('||v_ExpectedNo||' expected, '||v_Count||' found)!');
	END IF;

	FOR indx IN 1 .. t_PrivNames.COUNT
	LOOP
		v_PrivName := t_PrivNames(indx);
		SELECT COUNT(*) INTO v_Count FROM dba_sys_privs WHERE grantee = t_SchemaNames(indx) AND privilege = v_PrivName;
		IF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: '||t_SchemaNames(indx)||' was not granted the sys privilege: '||v_PrivName);
		ELSIF (v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('-- '||t_SchemaNames(indx)||' was granted the sys privilege: '||v_PrivName);
		END IF;
	END LOOP;
END;
/

COLUMN grantee FORMAT a30
SELECT grantee, privilege FROM dba_sys_privs WHERE grantee = 'WATERS' ORDER BY 1,2;

PROMPT
PROMPT
PROMPT Roles granted to WATERS:
PROMPT

DECLARE
v_Count			PLS_INTEGER := 0;
v_ExpectedNo		PLS_INTEGER;
v_RoleName		dba_role_privs.granted_role%TYPE;

TYPE CharList		IS TABLE OF VARCHAR2(500);
t_WDMRoles		CharList;

BEGIN
	IF (:V_WDMVersionsAsNum < 4100)		THEN	t_WDMRoles   := CharList('APEX_ADMINISTRATOR_ROLE','DATAPUMP_EXP_FULL_DATABASE','DATAPUMP_IMP_FULL_DATABASE','EXP_FULL_DATABASE','IMP_FULL_DATABASE','OEM_MONITOR','SCHEDULER_ADMIN');
	ELSIF (:V_WDMVersionsAsNum >= 4100)	THEN	t_WDMRoles   := CharList('APEX_ADMINISTRATOR_ROLE','OEM_MONITOR','SCHEDULER_ADMIN');
	END IF;
	v_ExpectedNo := t_WDMRoles.COUNT;

	SELECT COUNT(*) INTO v_Count FROM dba_role_privs WHERE grantee = 'WATERS';
	IF (v_Count = v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('The WATERS schema has the correct number of roles ('||v_ExpectedNo||' expected, '||v_Count||' found).');
	ELSIF (v_Count < v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: the WATERS schema has fewer than the expected number of roles ('||v_ExpectedNo||' expected, '||v_Count||' found)!');
	ELSIF (v_Count > v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('!!! WARNING: the WATERS schema has more than the expected number of roles ('||v_ExpectedNo||' expected, '||v_Count||' found)!');
	END IF;

	DBMS_OUTPUT.PUT_LINE('.');

	FOR indx IN 1 .. t_WDMRoles.COUNT
	LOOP
		v_RoleName := t_WDMRoles(indx);
		SELECT COUNT(*) INTO v_Count FROM dba_role_privs WHERE grantee = 'WATERS' AND granted_role = v_RoleName;
		IF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: WATERS was not granted the role: '||v_RoleName);
		ELSIF (v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('-- WATERS was granted the role: '||v_RoleName);
		END IF;
	END LOOP;
END;
/

COLUMN grantee FORMAT a30
COLUMN granted_role FORMAT a30
SELECT grantee, granted_role FROM dba_role_privs WHERE grantee IN ('WATERS') ORDER BY grantee, granted_role;

PROMPT
PROMPT ___________________________________________________________________________________________________________
PROMPT Java Permissions granted to WATERS:
PROMPT

DECLARE
v_Count			PLS_INTEGER := 0;
v_ExpectedNo		PLS_INTEGER := 7;
v_HostName		VARCHAR2(4000 CHAR);
v_SQL			VARCHAR2(4000 CHAR);

BEGIN
	IF	(:V_WDMVersionsAsNum > 3000)	THEN	DBMS_OUTPUT.PUT_LINE('-- N/A for WDM v3.0 and later.');
	ELSE
		v_SQL := 'SELECT COUNT(*) FROM dba_users usrs, sys.java$policy$ javpol WHERE usrs.user_id = javpol.grantee# and usrs.username = ''WATERS''';
		EXECUTE IMMEDIATE v_SQL INTO v_Count;
		IF (v_Count = v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('The WATERS schema has the correct number of Java permissions ('||v_ExpectedNo||' expected, '||v_Count||' found)');
		ELSIF (v_Count < v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: fewer than the expected number of Java permissions were granted to the WATERS schema ('||v_ExpectedNo||' expected, '||v_Count||' found)!  WDM may not be able to connect to the database.  Run DMBjavaGrants.sql as SYS to resolve this issue.');
		ELSIF (v_Count > v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('!!! WARNING: more than the expected number of Java permissions were granted to the WATERS schema ('||v_ExpectedNo||' expected, '||v_Count||' found)!');
		END IF;
	END IF;
END;
/

PROMPT
PROMPT ___________________________________________________________________________________________________________
PROMPT Oracle credentials for WDM
PROMPT

DECLARE
v_Count		PLS_INTEGER := 0;
v_ExpectedNo	PLS_INTEGER := 1;
v_CredName	VARCHAR2(1000);
v_CredUsername	VARCHAR2(1000);
v_CredEnabled	VARCHAR2(1000);

v_ExpectedCredName	VARCHAR2(1000);
v_ExpectedCredStatus	VARCHAR2(1000);

BEGIN
	SELECT COUNT(*) INTO v_Count FROM dba_objects WHERE object_name = 'DBA_CREDENTIALS'; -- Rev 2: check for the dba_credentials view, and skip these checks if it's not found.
	IF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('dba_credentials does not exist in this database; skipping the check for WDM credentials.  This is acceptable for WDM versions prior to 2.0 and Oracle Database versions prior to 12c.');
	ELSE

		SELECT COUNT(*) INTO v_Count FROM dba_credentials WHERE owner = 'WATERS';
		IF (v_Count < v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: the WATERS user owns less than the expected number of credentials ('||v_ExpectedNo||' expected, '||v_Count||' found)!  Any OS jobs which users queue through the web interface will not run!');
		ELSIF (v_Count > v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('!!! WARNING: the WATERS user owns more than the expected number of credentials ('||v_ExpectedNo||' expected, '||v_Count||' found).  Check the list below to ensure that WATERS has the expected credential and that it is enabled.');
		ELSIf (v_Count = v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('The WATERS user owns the expected number of crendentials ('||v_ExpectedNo||' expected, '||v_Count||' found)');
		END IF;

		v_ExpectedCredName := 'AEMCRED';
		v_ExpectedCredStatus := 'TRUE';
		SELECT COUNT(*) INTO v_Count FROM dba_credentials WHERE owner = 'WATERS' AND credential_name = v_ExpectedCredName;
		IF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: the WATERS user does not have the credential '||v_expectedCredName||' stored in Oracle!  Any OS jobs which users queue through the web interface will not run!');
		ELSE
			DBMS_OUTPUT.PUT_LINE('	The WATERS user owns the '||v_ExpectedCredName||' credential.');
			SELECT username, enabled INTO v_CredUsername, v_CredEnabled FROM dba_credentials WHERE owner = 'WATERS' AND credential_name = v_ExpectedCredName;
			DBMS_OUTPUT.PUT_LINE('		Username: '||v_CredUsername);
			IF (v_CredEnabled = v_ExpectedCredStatus)	THEN	DBMS_OUTPUT.PUT_LINE('		Enabled: '||v_CredEnabled);
			ELSE							DBMS_OUTPUT.PUT_LINE('		!!!!! ERROR: The credential '||v_ExpectedCredName||' is disabled!');
			END IF;
		END IF;
	END IF;
END;
/

PROMPT
PROMPT ___________________________________________________________________________________________________________
PROMPT WDM table views
PROMPT

DECLARE
v_Count			PLS_INTEGER := 0;
v_ExpectedNo		PLS_INTEGER;
v_ViewName		dba_views.view_name%TYPE;

TYPE CharList		IS TABLE OF VARCHAR2(500);
t_WDMViews		CharList;

BEGIN
	t_WDMViews   := CharList('V_DISK_BACKUP_SETTINGS');
	v_ExpectedNo := t_WDMViews.COUNT;

	SELECT COUNT(*) INTO v_Count FROM dba_views WHERE owner = 'WATERS';
	IF (v_Count = v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('WATERS owns the expected number of views ('||v_ExpectedNo||' expected, '||v_Count||' found)');
	ELSIF (v_Count < v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: WATERS does NOT own the expected number of views ('||v_ExpectedNo||' expected, '||v_Count||' found)');
	ELSIF (v_Count > v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('!!! WARNING: WATERS owns more than the expected number of views ('||v_ExpectedNo||' expected, '||v_Count||' found)');
	END IF;

	FOR indx IN 1 .. t_WDMViews.COUNT
	LOOP
		v_ViewName := t_WDMViews(indx);
		SELECT COUNT(*) INTO v_Count FROM dba_views WHERE owner = 'WATERS' AND view_name = v_ViewName;
		IF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: View waters.'||v_ViewName||' is NOT present');
		ELSIF (v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('View waters.'||v_ViewName||' is present');
		END IF;
		DBMS_OUTPUT.PUT_LINE('.');
	END LOOP;
END;
/

COLUMN owner FORMAT a20
COLUMN view_name FORMAT a40
PROMPT
PROMPT Views owned by WATERS:
SELECT owner, view_name FROM dba_views WHERE owner = 'WATERS';

PROMPT
PROMPT ___________________________________________________________________________________________________________
PROMPT WDM functions, packages, and procedures
PROMPT

DECLARE
v_Count			PLS_INTEGER := 0;
v_ExpectedNo		PLS_INTEGER := 2;
v_ObjName		dba_procedures.object_name%TYPE;
v_ObjType		dba_procedures.object_type%TYPE;
v_ObjStatus		dba_objects.status%TYPE;

TYPE CharList		IS TABLE OF VARCHAR2(500);
v_WDMFunctions		CharList;
v_WDMProcedures		CharList;
v_WDMPackages		CharList;
BEGIN
	IF	(:V_WDMVersionsAsNum <= 2000)	THEN
		v_WDMFunctions := CharList('NTH_STR','GET_CONFIG_VALUE');
		v_WDMProcedures := CharList('AEM_DEQUEUE_SCHEDULER_EVENT','AEM_TEST_DEQUEUE','CHANGE_SMTP','P1');
		v_WDMPackages := CharList('AEM_SERVER','AEM_UTIL','RMAN_ADMIN','AEM_CONFIGURATION','AEM_SCHEMA','AEM_BACKUP','AEM_CRYPTO','AEM_DATAPUMP','AEM_NOTIFICATION','SEC_UTIL');
	ELSIF	(:V_WDMVersionsAsNum >= 3000 AND :V_WDMVersionsAsNum < 4100)	THEN
		v_WDMFunctions := CharList('NTH_STR','GET_CONFIG_VALUE','GETPDBNAME');
		v_WDMProcedures := CharList('AEM_DEQUEUE_SCHEDULER_EVENT','AEM_TEST_DEQUEUE','CHANGE_SMTP','P1');
		v_WDMPackages := CharList('AEM_SERVER','AEM_UTIL','RMAN_ADMIN','AEM_CONFIGURATION','AEM_SCHEMA','AEM_BACKUP','AEM_CRYPTO','AEM_DATAPUMP','AEM_NOTIFICATION','SEC_UTIL');
	ELSIF (:V_WDMVersionsAsNum >= 4100)	THEN
		v_WDMFunctions := CharList('NTH_STR','GET_CONFIG_VALUE','GETPDBNAME');
		v_WDMProcedures := CharList('AEM_DEQUEUE_SCHEDULER_EVENT','AEM_TEST_DEQUEUE','CHANGE_SMTP','P1');
		v_WDMPackages := CharList('AEM_SERVER','AEM_UTIL','RMAN_ADMIN','AEM_CONFIGURATION','AEM_SCHEMA','AEM_BACKUP','AEM_CRYPTO','AEM_NOTIFICATION','SEC_UTIL');
	ELSE
		v_WDMFunctions := CharList();
		v_WDMProcedures := CharList();
		v_WDMProcedures := CharList();
	END IF;

	DBMS_OUTPUT.PUT_LINE('Determining whether the WATERS account has the expected functions, procedures, and packages; missing objects, if any, will be listed below:');

	-- Functions
	v_ExpectedNo   := v_WDMFunctions.COUNT;
	SELECT COUNT(*) INTO v_Count FROM dba_procedures WHERE owner = 'WATERS' AND object_type IN ('FUNCTION');
	IF (v_Count = v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('WATERS owns the expected number of functions ('||v_ExpectedNo||' expected, '||v_Count||' found)');
	ELSIF (v_Count < v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: WATERS owns less than the expected number of functions ('||v_ExpectedNo||' expected, '||v_Count||' found)');
	ELSIF (v_Count > v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('!!! WARNING: WATERS owns more than the expected number of functions ('||v_ExpectedNo||' expected, '||v_Count||' found)');
	END IF;

	DBMS_OUTPUT.PUT_LINE('.');

	FOR indx IN 1 .. v_WDMFunctions.COUNT
	LOOP
		v_ObjName := v_WDMFunctions(indx);
		SELECT COUNT(*) INTO v_Count FROM dba_procedures WHERE owner = 'WATERS' AND object_name = v_ObjName AND object_type = 'FUNCTION';
		IF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: Function waters.'||v_ObjName||' is NOT present');
		ELSIF (v_Count = 1)	THEN
			DBMS_OUTPUT.PUT_LINE('Function: waters.'||v_ObjName||' is present');
			SELECT status INTO v_ObjStatus FROM dba_objects WHERE owner = 'WATERS' AND object_name = v_ObjName;
			IF (v_ObjStatus != 'VALID')	THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: the function '||v_ObjName||' is not valid!');
			ELSIF (v_ObjStatus = 'VALID')	THEN	DBMS_OUTPUT.PUT_LINE('-- The function '||v_ObjName||' is valid');
			END IF;
		END IF;
		DBMS_OUTPUT.PUT_LINE('.');
	END LOOP;

	-- Procedures
	v_ExpectedNo    := v_WDMProcedures.COUNT;
	DBMS_OUTPUT.PUT_LINE('.');
	SELECT COUNT(*) INTO v_Count FROM dba_procedures WHERE owner = 'WATERS' AND object_type IN ('PROCEDURE');
	IF (v_Count = v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('WATERS owns the expected number of procedures ('||v_ExpectedNo||' expected, '||v_Count||' found)');
	ELSIF (v_Count < v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: WATERS owns less than the expected number of procedures ('||v_ExpectedNo||' expected, '||v_Count||' found)');
	ELSIF (v_Count > v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('!!! WARNING: WATERS owns more than the expected number of procedures ('||v_ExpectedNo||' expected, '||v_Count||' found)');
	END IF;

	FOR indx IN 1 .. v_WDMProcedures.COUNT
	LOOP
		v_ObjName := v_WDMProcedures(indx);
		SELECT COUNT(*) INTO v_Count FROM dba_procedures WHERE owner = 'WATERS' AND object_name = v_ObjName AND object_type = 'PROCEDURE';
		IF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: procedure waters'||v_ObjName||' is NOT present');
		ELSIF (v_Count = 1)	THEN
			DBMS_OUTPUT.PUT_LINE('Procedure waters.'||v_ObjName||' is present');
			SELECT status INTO v_ObjStatus FROM dba_objects WHERE owner = 'WATERS' AND object_name = v_ObjName;
			IF (v_ObjStatus != 'VALID')	THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: the procedure '||v_ObjName||' is NOT valid');
			ELSIF (v_ObjStatus = 'VALID')	THEN	DBMS_OUTPUT.PUT_LINE('-- Procedure '||v_ObjName||' is valid');
			END IF;
		END IF;
		DBMS_OUTPUT.PUT_LINE('.');
	END LOOP;

	-- Packages
	v_ExpectedNo  := v_WDMPackages.COUNT;
	DBMS_OUTPUT.PUT_LINE('.');
	SELECT COUNT(DISTINCT object_name) INTO v_Count FROM dba_procedures WHERE owner = 'WATERS' AND object_type IN ('PACKAGE');
	IF (v_Count = v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('WATERS owns the expected number of packages ('||v_ExpectedNo||' expected, '||v_Count||' found)');
	ELSIF (v_Count < v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR WATERS owns less than the expected number of packages ('||v_ExpectedNo||' expected, '||v_Count||' found)');
	ELSIF (v_Count > v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('!!! WARNING WATERS owns more than the expected number of packages ('||v_ExpectedNo||' expected, '||v_Count||' found)');
	END IF;

	FOR indx IN 1 .. v_WDMPackages.COUNT
	LOOP
		v_ObjName := v_WDMPackages(indx);
		SELECT COUNT(DISTINCT object_name) INTO v_Count FROM dba_procedures WHERE owner = 'WATERS' AND object_name = v_ObjName AND object_type = 'PACKAGE';
		IF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: package waters.'||v_ObjName||'is NOT present');
		ELSIF (v_Count = 1)	THEN
			DBMS_OUTPUT.PUT_LINE('Package waters.'||v_ObjName||' is present');
			SELECT status INTO v_ObjStatus FROM dba_objects WHERE owner = 'WATERS' AND object_name = v_ObjName AND object_type = 'PACKAGE';
			IF (v_ObjStatus != 'VALID')	THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: the package definition '||v_ObjName||' is NOT valid');
			ELSIF (v_ObjStatus = 'VALID')	THEN	DBMS_OUTPUT.PUT_LINE('-- The package definition '||v_ObjName||' is valid');
			END IF;

			SELECT status INTO v_ObjStatus FROM dba_objects WHERE owner = 'WATERS' AND object_name = v_ObjName AND object_type = 'PACKAGE BODY';
			IF (v_ObjStatus != 'VALID')	THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: the package body '||v_ObjName||' is NOT valid');
			ELSIF (v_ObjStatus = 'VALID')	THEN	DBMS_OUTPUT.PUT_LINE('-- The package body '||v_ObjName||' is valid');
			END IF;
		END IF;
		DBMS_OUTPUT.PUT_LINE('.');
	END LOOP;
END;
/

COLUMN owner FORMAT a20
COLUMN object_name FORMAT a30
COLUMN procedure_name FORMAT a30
PROMPT
PROMPT List of WDM stored procedures/functions/packages:
SELECT owner, object_type, object_name, procedure_name FROM dba_procedures WHERE owner = 'WATERS' AND object_type IN ('FUNCTION','PROCEDURE','PACKAGE BODY','PACKAGE') ORDER BY owner, object_type, object_name;


PROMPT
PROMPT ___________________________________________________________________________________________________________
PROMPT WDM sequences
PROMPT

DECLARE
v_Count			PLS_INTEGER := 0;
v_ExpectedNo		PLS_INTEGER;
v_ObjName		dba_sequences.sequence_name%TYPE;
v_ObjStatus		dba_objects.status%TYPE;

TYPE CharList		IS TABLE OF VARCHAR2(500);
t_WDMSequences		CharList;

BEGIN
	IF (:V_WDMVersionsAsNum < 4100)		THEN	t_WDMSequences := CharList('ACA_SCHEDULER_JOB_SEQ','AEM_ALERTS_SEQ','AEM_BSL_SEQ','AEM_CPA_PK_SEQ','AEM_DPJ_SEQ','AEM_DRY_PK_SEQ','AEM_RCL_PK_SEQ','AEM_RPT_PK_SEQ','SEC_RGD_PK_SEQ','SEC_RLE_PK_SEQ','SEC_USR_PK_SEQ');
	ELSIF (:V_WDMVersionsAsNum >= 4100)	THEN	t_WDMSequences := CharList('ACA_SCHEDULER_JOB_SEQ','AEM_ALERTS_SEQ','AEM_BSL_SEQ','AEM_CPA_PK_SEQ','AEM_DRY_PK_SEQ','AEM_RCL_PK_SEQ','AEM_RPT_PK_SEQ','SEC_RGD_PK_SEQ','SEC_RLE_PK_SEQ','SEC_USR_PK_SEQ');
	END IF;
	v_ExpectedNo   := t_WDMSequences.COUNT;

	SELECT COUNT(*) INTO v_Count FROM dba_sequences WHERE sequence_owner = 'WATERS';
	IF (v_Count = v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('WATERS owns the expected number of sequences ('||v_ExpectedNo||' expected, '||v_Count||' found)');
	ELSIF (v_Count < v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: WATERS owns less than the expected number of sequences ('||v_ExpectedNo||' expected, '||v_Count||' found)!');
	ELSIF (v_Count > v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('!!! WARNING: WATERS owns more than the expected number of sequences ('||v_ExpectedNo||' expected, '||v_Count||' found)');
	END IF;

	FOR indx IN 1 .. t_WDMSequences.COUNT
	LOOP
		v_ObjName := t_WDMSequences(indx);
		SELECT COUNT(*) INTO v_Count FROM dba_sequences WHERE sequence_owner = 'WATERS' AND sequence_name = v_ObjName;
		IF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: Sequence WATERS.'||v_ObjName||' is NOT present');
		ELSIF (v_Count = 1)	THEN
			DBMS_OUTPUT.PUT_LINE('Sequence: WATERS.'||v_ObjName||' is present');
			SELECT status INTO v_ObjStatus FROM dba_objects WHERE owner = 'WATERS' AND object_name = v_ObjName AND object_Type = 'SEQUENCE';
			IF (v_ObjStatus != 'VALID')	THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: the sequence '||v_ObjName||' is not valid');
			ELSIF (v_ObjStatus = 'VALID')	THEN	DBMS_OUTPUT.PUT_LINE('-- The sequence '||v_ObjName||' is valid');
			END IF;
		END IF;
		DBMS_OUTPUT.PUT_LINE('.');
	END LOOP;
END;
/

COLUMN sequence_name format a30
COLUMN sequence_owner FORMAT a30
PROMPT
PROMPT Sequences owned by WATERS:
SELECT sequence_owner, sequence_name, min_value, max_value, increment_by FROM dba_sequences WHERE sequence_owner = 'WATERS' ORDER BY 2;

PROMPT
PROMPT ___________________________________________________________________________________________________________
PROMPT WDM synonyms
PROMPT

PROMPT

DECLARE
v_Count			PLS_INTEGER := 0;
v_ExpectedNo		PLS_INTEGER;
v_ObjName		dba_synonyms.synonym_name%TYPE;
v_ObjStatus		dba_objects.status%TYPE;
v_SynTableOwner		dba_synonyms.table_owner%TYPE;
v_SynTableName		dba_synonyms.table_name%TYPE;

TYPE CharList		IS TABLE OF VARCHAR2(500);
v_WDMSynonyms		CharList;
v_WDMSynTabOwners	CharList;
v_WDMSynTabNames	CharList;

BEGIN
	v_WDMSynonyms     := CharList('COR_DBPASSWORDWRITE','V_$RMAN_CONFIGURATION');
	v_WDMSynTabOwners := CharList('WATERS',             'SYS');
	v_WDMSynTabNames  := CharList('AEM_SCHEMA',         'V_$RMAN_CONFIGURATION');
	v_ExpectedNo      := v_WDMSynonyms.COUNT;

	SELECT COUNT(*) INTO v_Count FROM dba_synonyms WHERE owner = 'WATERS';
	IF (v_Count = v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('WATERS owns the expected number of synonyms ('||v_ExpectedNo||' expected, '||v_Count||' found)');
	ELSIF (v_Count < v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: WATERS owns less than the expected number of synonyms ('||v_ExpectedNo||' expected, '||v_Count||' found)');
	ELSIF (v_Count > v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('!!! WARNING: WATERS owns more than the expected number of synonyms ('||v_ExpectedNo||' expected, '||v_Count||' found)');
	END IF;

	FOR indx IN 1 .. v_WDMSynonyms.COUNT
	LOOP
		v_ObjName := v_WDMSynonyms(indx);
		SELECT COUNT(*) INTO v_Count FROM dba_synonyms WHERE owner = 'WATERS' AND synonym_name = v_ObjName;
		IF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: WATERS schema does not have the synonym: '||v_ObjName);
		ELSIF (v_Count = 1)	THEN
			DBMS_OUTPUT.PUT_LINE('The WATERS schema has the synonym: '||v_ObjName);
			SELECT status INTO v_ObjStatus FROM dba_objects WHERE owner = 'WATERS' AND object_name = v_ObjName AND object_Type = 'SYNONYM';
			IF (v_ObjStatus != 'VALID')	THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: the synonym '||v_ObjName||' is not valid');
			ELSIF (v_ObjStatus = 'VALID')	THEN	DBMS_OUTPUT.PUT_LINE('-- The synonym '||v_ObjName||' is valid');
			END IF;

			SELECT table_owner, table_name INTO v_SynTableOwner, v_SynTableName FROM dba_synonyms WHERE owner = 'WATERS' AND synonym_name = v_ObjName;
			IF(v_SynTableOwner != v_WDMSynTabOwners(indx) OR v_SynTableName != v_WDMSynTabNames(indx))	THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: synonym '||v_ObjName||' is not correctly defined!  It must point to the table '||v_WDMSynTabOwners(indx)||'.'||v_WDMSynTabNames(indx));
			ELSIF(v_SynTableOwner = v_WDMSynTabOwners(indx) AND v_SynTableName = v_WDMSynTabNames(indx))	THEN	DBMS_OUTPUT.PUT_LINE('-- Synonym '||v_ObjName||' is correctly defined. It points to the table '||v_WDMSynTabOwners(indx)||'.'||v_WDMSynTabNames(indx));
			END IF;
		END IF;
		DBMS_OUTPUT.PUT_LINE('.');
	END LOOP;
END;
/

col owner format a20
col synonym_name format a30
col table_owner format a20
col table_name format a30
SELECT owner, synonym_name, table_owner, table_name FROM dba_synonyms WHERE owner = 'WATERS' ORDER BY 2;

PROMPT
PROMPT ___________________________________________________________________________________________________________
PROMPT WDM triggers
PROMPT

DECLARE
v_Count		PLS_INTEGER := 0;
v_ExpectedNo	PLS_INTEGER;
v_ObjName	dba_triggers.trigger_name%TYPE;
v_ObjStatus	dba_triggers.status%TYPE;
v_TableOwner	dba_triggers.table_owner%TYPE;
v_TableName	dba_triggers.table_name%TYPE;
v_TriggerType	dba_triggers.trigger_type%TYPE;
v_TriggerEvent	dba_triggers.triggering_event%TYPE;

v_ExpectedStatus	dba_triggers.status %TYPE := 'ENABLED';
v_ExpectedTableName	dba_triggers.table_name%TYPE;
v_ExpectedTrigType	dba_triggers.trigger_type%TYPE;
v_ExpectedTrigEvent	dba_triggers.triggering_event%TYPE;

TYPE CharList		IS TABLE OF VARCHAR2(500);
t_WDMTriggerNames	CharList;
t_WDMTriggerTabNames	CharList;
t_WDMTriggerTypes	CharList;
t_WDMTriggerEvents	CharList;

BEGIN
	IF (:V_WDMVersionsAsNum < 4100)		THEN
		t_WDMTriggerNames    := CharList('AEM_ALERTS_TRG', 'AEM_CPA_BIU_TRG',            'AEM_CPR_AUDIT_TRG',           'AEM_DRY_BIU_TRG', 'AEM_ORA_BIU_TRG', 'AEM_RCL_BIU_TRG',         'AEM_RPT_BIU_TRG', 'BIU_AEM_BACKUP_SCHEDULE','BI_AEM_BACKUP_SCHEDULE','BI_AEM_DATAPUMP_JOBS','SEC_RGD_BIU_TRG',  'SEC_RLE_BIU_TRG', 'SEC_USR_BIU_TRG');
		t_WDMTriggerTabNames := CharList('AEM_ALERTS',     'AEM_CONFIG_PARAMETERS_AUDIT','AEM_CONFIGURATION_PARAMETERS','AEM_DIRECTORIES', 'AEM_ORA',         'AEM_REPORT_COLUMN_LABELS','AEM_REPORTS',     'AEM_BACKUP_SCHEDULE',    'AEM_BACKUP_SCHEDULE',   'AEM_DATAPUMP_JOBS',   'SEC_ROLES_GRANTED','SEC_ROLES',       'SEC_USERS');
		t_WDMTriggerTypes    := CharList('BEFORE EACH ROW','BEFORE EACH ROW',            'AFTER EACH ROW',              'BEFORE EACH ROW', 'BEFORE EACH ROW', 'BEFORE EACH ROW',         'BEFORE EACH ROW', 'BEFORE EACH ROW',        'BEFORE EACH ROW',       'BEFORE EACH ROW',     'BEFORE EACH ROW',  'BEFORE EACH ROW', 'BEFORE EACH ROW');
		t_WDMTriggerEvents   := CharList('INSERT',         'INSERT OR UPDATE',           'UPDATE',                      'INSERT OR UPDATE','INSERT OR UPDATE','INSERT OR UPDATE',        'INSERT OR UPDATE','INSERT OR UPDATE',       'INSERT',                'INSERT',              'INSERT OR UPDATE', 'INSERT OR UPDATE','INSERT OR UPDATE');
	ELSIF (:V_WDMVersionsAsNum >= 4100)	THEN
		t_WDMTriggerNames    := CharList('AEM_ALERTS_TRG', 'AEM_CPA_BIU_TRG',            'AEM_CPR_AUDIT_TRG',           'AEM_DRY_BIU_TRG', 'AEM_ORA_BIU_TRG', 'AEM_RCL_BIU_TRG',         'AEM_RPT_BIU_TRG', 'BIU_AEM_BACKUP_SCHEDULE','BI_AEM_BACKUP_SCHEDULE','SEC_RGD_BIU_TRG',  'SEC_RLE_BIU_TRG', 'SEC_USR_BIU_TRG');
		t_WDMTriggerTabNames := CharList('AEM_ALERTS',     'AEM_CONFIG_PARAMETERS_AUDIT','AEM_CONFIGURATION_PARAMETERS','AEM_DIRECTORIES', 'AEM_ORA',         'AEM_REPORT_COLUMN_LABELS','AEM_REPORTS',     'AEM_BACKUP_SCHEDULE',    'AEM_BACKUP_SCHEDULE',   'SEC_ROLES_GRANTED','SEC_ROLES',       'SEC_USERS');
		t_WDMTriggerTypes    := CharList('BEFORE EACH ROW','BEFORE EACH ROW',            'AFTER EACH ROW',              'BEFORE EACH ROW', 'BEFORE EACH ROW', 'BEFORE EACH ROW',         'BEFORE EACH ROW', 'BEFORE EACH ROW',        'BEFORE EACH ROW',       'BEFORE EACH ROW',  'BEFORE EACH ROW', 'BEFORE EACH ROW');
		t_WDMTriggerEvents   := CharList('INSERT',         'INSERT OR UPDATE',           'UPDATE',                      'INSERT OR UPDATE','INSERT OR UPDATE','INSERT OR UPDATE',        'INSERT OR UPDATE','INSERT OR UPDATE',       'INSERT',                'INSERT OR UPDATE', 'INSERT OR UPDATE','INSERT OR UPDATE');
	END IF;
	v_ExpectedNo := t_WDMTriggerNames.COUNT;
	SELECT COUNT(*) INTO v_Count FROM dba_triggers WHERE owner = 'WATERS';
	IF (v_Count = v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('WATERS owns the expected number of triggers ('||v_ExpectedNo||' expected, '||v_Count||' found)');
	ELSIF (v_Count < v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: WATERS owns less than the expected number of triggers ('||v_ExpectedNo||' expected, '||v_Count||' found)');
	ELSIF (v_Count > v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('!!! WARNING: WATERS owns more than the expected number of triggers ('||v_ExpectedNo||' expected, '||v_Count||' found)');
	END IF;

	FOR indx IN 1 .. t_WDMTriggerNames.COUNT
	LOOP
		v_ObjName           := t_WDMTriggerNames(indx);
		v_ExpectedTableName := t_WDMTriggerTabNames(indx);
		v_ExpectedTrigType  := t_WDMTriggerTypes(indx);
		v_ExpectedTrigEvent := t_WDMTriggerEvents(indx);
		SELECT COUNT(*) INTO v_Count FROM dba_triggers WHERE owner = 'WATERS' AND trigger_name = v_ObjName;
		IF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: WATERS schema does not have the trigger: '||v_ObjName);
		ELSIF (v_Count = 1)	THEN
			DBMS_OUTPUT.PUT_LINE('Trigger waters.'||v_ObjName||' is present');
			SELECT status INTO v_ObjStatus FROM dba_triggers WHERE owner = 'WATERS' AND trigger_name = v_ObjName;
			IF (v_ObjStatus != v_ExpectedStatus)	THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: the trigger '||v_ObjName||' is not '||v_ExpectedStatus||'!');	END IF;
	
			SELECT table_owner, table_name, trigger_type, triggering_event INTO v_TableOwner, v_TableName, v_TriggerType, v_TriggerEvent FROM dba_triggers WHERE owner = 'WATERS' AND trigger_name = v_ObjName;
			IF(v_TableOwner != 'WATERS' OR v_TableName != v_ExpectedTableName)	THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: trigger '||v_ObjName||' is not correctly defined!  It must point to the table WATERS.'||v_ExpectedTableName||'!');	END IF;
			IF(v_TriggerType != v_ExpectedTrigType)					THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: trigger '||v_ObjName||' is not correctly defined!  Trigger type must be '||v_ExpectedTrigType||'!');			END IF;
			IF(v_TriggerEvent != v_ExpectedTrigEvent)				THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: trigger '||v_ObjName||' is not correctly defined!  Trigger event must be '||v_ExpectedTrigEvent||'!');		END IF;
		END IF;
		DBMS_OUTPUT.PUT_LINE('.');
	END LOOP;
END;
/

col owner format a20
col trigger_name format a30
col trigger_type format a30
col triggering_event format a30
col table_owner format a30
col table_name format a30
PROMPT
PROMPT Triggers owned by WATERS:
SELECT owner, trigger_name, trigger_type, triggering_event, table_owner, table_name, status FROM dba_triggers WHERE owner = 'WATERS' ORDER BY 2;

PROMPT
PROMPT ___________________________________________________________________________________________________________
PROMPT WDM indexes
PROMPT

DECLARE
v_Count			PLS_INTEGER := 0;
v_ExpectedNo		PLS_INTEGER;
v_ObjName		dba_indexes.index_name%TYPE;
v_ObjStatus		dba_indexes.status%TYPE;
v_TableOwner		dba_indexes.table_owner%TYPE;
v_TableName		dba_indexes.table_name%TYPE;
v_ObjType		dba_indexes.index_type%TYPE;

v_ExpectedStatus	dba_indexes.status%TYPE := 'VALID';
v_ExpectedTableName	dba_indexes.table_name%TYPE;
v_ExpectedIndexType	dba_indexes.index_type%TYPE := 'NORMAL';

TYPE CharList		IS TABLE OF VARCHAR2(500);
t_WDMIndexes		CharList;
t_WDMIndexTabNames	CharList;

BEGIN
	IF (:V_WDMVersionsAsNum < 4100)		THEN
		t_WDMIndexes       := CharList('AEM_ALERT_PK','AEM_BACKUP_SCHEDULE_NAME_UK','AEM_BACKUP_SCHEDULE_PK','AEM_CONFIG_PARAM_UC',         'AEM_CPA_PK',                 'AEM_DATAPUMP_JOBS_PK','AEM_DRY_NAME_UK','AEM_DRY_PK',     'AEM_ORA_PK','AEM_RCL_IFM_RPT_FK_IDX',  'AEM_RCL_LABEL_UK',        'AEM_RCL_PK',              'AEM_RPT_NAME_UK','AEM_RPT_PK', 'SEC_RGD_PK',       'SEC_RGD_SEC_RLE_FK_IDX','SEC_RGD_SEC_USR_FK_IDX','SEC_RGD_UK',       'SEC_RLE_NAME_UK','SEC_RLE_PK','SEC_USR_PK','SEC_USR_USERNAME_UK');
		t_WDMIndexTabNames := CharList('AEM_ALERTS',  'AEM_BACKUP_SCHEDULE',        'AEM_BACKUP_SCHEDULE',   'AEM_CONFIGURATION_PARAMETERS','AEM_CONFIG_PARAMETERS_AUDIT','AEM_DATAPUMP_JOBS',   'AEM_DIRECTORIES','AEM_DIRECTORIES','AEM_ORA',   'AEM_REPORT_COLUMN_LABELS','AEM_REPORT_COLUMN_LABELS','AEM_REPORT_COLUMN_LABELS','AEM_REPORTS',    'AEM_REPORTS','SEC_ROLES_GRANTED','SEC_ROLES_GRANTED',     'SEC_ROLES_GRANTED',     'SEC_ROLES_GRANTED','SEC_ROLES',      'SEC_ROLES', 'SEC_USERS', 'SEC_USERS');
	ELSIF (:V_WDMVersionsAsNum >= 4100 AND :V_WDMVersionsAsNum < 4200)	THEN
		t_WDMIndexes       := CharList('AEM_ALERT_PK','AEM_BACKUP_SCHEDULE_NAME_UK','AEM_BACKUP_SCHEDULE_PK','AEM_CONFIG_PARAM_UC',         'AEM_CPA_PK',                 'AEM_DRY_NAME_UK','AEM_DRY_PK',     'AEM_ORA_PK','AEM_RCL_IFM_RPT_FK_IDX',  'AEM_RCL_LABEL_UK',        'AEM_RCL_PK',              'AEM_RPT_NAME_UK','AEM_RPT_PK', 'SEC_RGD_PK',       'SEC_RGD_SEC_RLE_FK_IDX','SEC_RGD_SEC_USR_FK_IDX','SEC_RGD_UK',       'SEC_RLE_NAME_UK','SEC_RLE_PK','SEC_USR_PK','SEC_USR_USERNAME_UK');
		t_WDMIndexTabNames := CharList('AEM_ALERTS',  'AEM_BACKUP_SCHEDULE',        'AEM_BACKUP_SCHEDULE',   'AEM_CONFIGURATION_PARAMETERS','AEM_CONFIG_PARAMETERS_AUDIT','AEM_DIRECTORIES','AEM_DIRECTORIES','AEM_ORA',   'AEM_REPORT_COLUMN_LABELS','AEM_REPORT_COLUMN_LABELS','AEM_REPORT_COLUMN_LABELS','AEM_REPORTS',    'AEM_REPORTS','SEC_ROLES_GRANTED','SEC_ROLES_GRANTED',     'SEC_ROLES_GRANTED',     'SEC_ROLES_GRANTED','SEC_ROLES',      'SEC_ROLES', 'SEC_USERS', 'SEC_USERS');
	ELSIF (:V_WDMVersionsAsNum >= 4200)	THEN
		t_WDMIndexes       := CharList('AEM_ALERT_PK','AEM_BACKUP_SCHEDULE_NAME_UK','AEM_BACKUP_SCHEDULE_PK','AEM_CONFIG_PARAM_UC',         'AEM_CPA_PK',                 'AEM_DRY_NAME_UK','AEM_DRY_PK',     'AEM_ORA_PK','AEM_RCL_IFM_RPT_FK_IDX',  'AEM_RCL_LABEL_UK',        'AEM_RCL_PK',              'AEM_RPT_NAME_UK','AEM_RPT_PK', 'SEC_RGD_PK',       'SEC_RGD_SEC_RLE_FK_IDX','SEC_RGD_SEC_USR_FK_IDX','SEC_RGD_UK',       'SEC_RLE_NAME_UK','SEC_RLE_PK','SEC_USR_PK','SEC_USR_USERNAME_UK','AEM_TS_ALERT_PK');
		t_WDMIndexTabNames := CharList('AEM_ALERTS',  'AEM_BACKUP_SCHEDULE',        'AEM_BACKUP_SCHEDULE',   'AEM_CONFIGURATION_PARAMETERS','AEM_CONFIG_PARAMETERS_AUDIT','AEM_DIRECTORIES','AEM_DIRECTORIES','AEM_ORA',   'AEM_REPORT_COLUMN_LABELS','AEM_REPORT_COLUMN_LABELS','AEM_REPORT_COLUMN_LABELS','AEM_REPORTS',    'AEM_REPORTS','SEC_ROLES_GRANTED','SEC_ROLES_GRANTED',     'SEC_ROLES_GRANTED',     'SEC_ROLES_GRANTED','SEC_ROLES',      'SEC_ROLES', 'SEC_USERS', 'SEC_USERS',          'AEM_TS_ALERTS');
	END IF;
	v_ExpectedNo := t_WDMIndexes.COUNT;

	SELECT COUNT(*) INTO v_Count FROM dba_indexes WHERE owner = 'WATERS';
	IF (v_Count = v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('WATERS owns the expected number of indexes ('||v_ExpectedNo||' expected, '||v_Count||' found)');
	ELSIF (v_Count < v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: WATERS owns less than the expected number of indexes ('||v_ExpectedNo||' expected, '||v_Count||' found)');
	ELSIF (v_Count > v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('!!! WARNING: WATERS owns more than the expected number of indexes ('||v_ExpectedNo||' expected, '||v_Count||' found)');
	END IF;

	FOR indx IN 1 .. t_WDMIndexes.COUNT
	LOOP
		v_ObjName           := t_WDMIndexes(indx);
		v_ExpectedTableName := t_WDMIndexTabNames(indx);
		SELECT COUNT(*) INTO v_Count FROM dba_indexes WHERE owner = 'WATERS' AND index_name = v_ObjName;
		IF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: Index waters.'||v_ObjName||' is NOT present');
		ELSIF (v_Count = 1)	THEN
			DBMS_OUTPUT.PUT_LINE('Index: waters.'||v_ObjName||' is present');
			SELECT status INTO v_ObjStatus FROM dba_indexes WHERE owner = 'WATERS' AND index_name = v_ObjName;
			IF (v_ObjStatus != v_ExpectedStatus)	THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: the index status is not '||v_ExpectedStatus);
			ELSIF (v_ObjStatus = v_ExpectedStatus)	THEN	DBMS_OUTPUT.PUT_LINE('-- Index status is '||v_ExpectedStatus);
			END IF;
	
			SELECT table_owner, table_name, index_type INTO v_TableOwner, v_TableName, v_ObjType FROM dba_indexes WHERE owner = 'WATERS' AND index_name = v_ObjName;
			IF(v_TableOwner != 'WATERS' OR v_TableName != v_ExpectedTableName)	THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: index '||v_ObjName||' does NOT point to the table waters.'||v_ExpectedTableName);
			ELSIF(v_TableOwner = 'WATERS' AND v_TableName = v_ExpectedTableName)	THEN	DBMS_OUTPUT.PUT_LINE('-- Index '||v_ObjName||' points to the table waters.'||v_ExpectedTableName);
			END IF;

			IF(v_ObjType != v_ExpectedIndexType)					THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: index type is NOT '||v_ExpectedIndexType);
			ELSIF(v_ObjType = v_ExpectedIndexType)					THEN	DBMS_OUTPUT.PUT_LINE('-- Index type is '||v_ExpectedIndexType);
			END IF;
		END IF;
		DBMS_OUTPUT.PUT_LINE('.');
	END LOOP;
END;
/

col owner format a20
col index_name format a30
col table_owner format a30
col table_name format a30
PROMPT
PROMPT Indexes owned by WATERS:
SELECT owner, index_name, index_type, table_owner, table_name, status FROM dba_indexes WHERE owner = 'WATERS' ORDER BY 2;

PROMPT
PROMPT
PROMPT ___________________________________________________________________________________________________________
PROMPT WDM DB links
PROMPT

DECLARE
v_Count			PLS_INTEGER := 0;
v_ExpectedNo		PLS_INTEGER;
v_DBLinkOwner		dba_db_links.owner%TYPE;
v_DBLinkName		dba_db_links.db_link%TYPE;
v_DBLinkUsername	dba_db_links.username%TYPE;
v_DBLinkHost		dba_db_links.host%TYPE;

CURSOR C_DBLinks IS	SELECT owner, db_link, username, host FROM dba_db_links ORDER BY 1,2;
BEGIN
	SELECT COUNT(*) INTO v_Count FROM dba_db_links WHERE owner IN ('WATERS');
	DBMS_OUTPUT.PUT_LINE('Number of db_links owned by WDM: '||v_Count);
	IF v_Count > 0		THEN
		SELECT COUNT(*) INTO v_Count FROM dba_db_links WHERE owner = 'WATERS' AND db_link = 'CDB_VIEWS';
		IF (v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('-- The db_link CDB_VIEWS, owned by WATERS, is present.');
		ELSIF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: the db_link CDB_VIEWS, owned by WATERS, is either not present or owned by another user.');
		END IF;

		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('All dblinks in the dba_db_links view:');
		OPEN C_DBLinks;
		LOOP
			FETCH C_DBLinks INTO v_DBLinkOwner, v_DBLinkName, v_DBLinkUsername, v_DBLinkHost;
			EXIT WHEN C_DBLinks%NOTFOUND;

			DBMS_OUTPUT.PUT_LINE('-- Owner: ' ||v_DBLinkOwner||'	Link name: '||v_DBLinkName||'	user: '||v_DBLinkUsername||'	host: '||v_DBLinkHost);
		END LOOP;
		CLOSE C_DBLinks;
	ELSIF (v_Count = 0)	THEN		DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: 1 DB link is expected in WDM v4.x!');
	END IF;
END;
/

PROMPT
PROMPT ___________________________________________________________________________________________________________
PROMPT WDM tablespaces
PROMPT

PROMPT Properties of the default and temp tablespaces for the WDM schema:
SELECT tablespace_name, block_size, min_extents, max_extents, max_size, status, contents, logging, extent_management FROM dba_tablespaces WHERE tablespace_name IN (SELECT default_tablespace FROM dba_users WHERE username IN ('WATERS') UNION SELECT temporary_tablespace FROM dba_users WHERE username IN ('WATERS'));

COLUMN username FORMAT a20
COLUMN tablespace_quota FORMAT A20
PROMPT
SELECT REPLACE(max_bytes, '-1', 'UNLIMITED') "TABLESPACE_QUOTA", USERNAME, TABLESPACE_NAME FROM dba_ts_quotas WHERE username IN ('WATERS') ORDER BY username;

PROMPT
PROMPT
PROMPT ___________________________________________________________________________________________________________
PROMPT WDM users and roles
PROMPT

COLUMN "ReceiveAlerts?" FORMAT a20
COLUMN description FORMAT a40
COLUMN Enabled FORMAT a10
PROMPT List of user accounts in WDM:
SELECT username, enabled, email, alerts "ReceiveAlerts?" FROM waters.sec_users ORDER by id;

PROMPT
PROMPT List of user roles:
SELECT name, description, enabled FROM waters.sec_roles ORDER BY id;

PROMPT
PROMPT List of roles granted to each user:
SELECT usr.username "Username", rls.name "RoleName", rlgrnts.enabled "Enabled" FROM waters.sec_users usr, waters.sec_roles rls, waters.sec_roles_granted rlgrnts WHERE rlgrnts.user_id = usr.id AND rlgrnts.role_id = rls.id ORDER BY usr.username;

PROMPT
PROMPT
PROMPT ___________________________________________________________________________________________________________
PROMPT WDM scheduled backups and Oracle jobs
PROMPT

DECLARE
v_Count		PLS_INTEGER := 0;

v_SchName	waters.aem_backup_schedule.name%TYPE;
v_SchDatafile	waters.aem_backup_schedule.datafile%TYPE;
v_SchIncrLevel	waters.aem_backup_schedule.df_incremental%TYPE;
v_SchArchLog	waters.aem_backup_schedule.archive_log%TYPE;
v_SchArchLogDel	waters.aem_backup_schedule.al_delete%TYPE;
v_SchCntrlFile	waters.aem_backup_schedule.controlfile%TYPE;
v_SchDelExpBkup	waters.aem_backup_schedule.del_expired_backup%TYPE;
v_SchDelObsBkup	waters.aem_backup_schedule.del_obsolete_backup%TYPE;
v_SchType	waters.aem_backup_schedule.sch_how%TYPE;
v_SchStartTime	waters.aem_backup_schedule.sch_time%TYPE;
v_SchIntervalType	waters.aem_backup_schedule.sch_Interval%TYPE;
v_SchIntervalTime	waters.aem_backup_schedule.sch_every%TYPE;

v_JobRunCount	dba_scheduler_jobs.run_count%TYPE;
v_JobFailCount	dba_scheduler_jobs.failure_count%TYPE;
CURSOR		C_WDMActiveBackupSch	IS SELECT name, datafile, df_incremental, archive_log, al_delete, controlfile, del_expired_backup, del_obsolete_backup, sch_how, sch_time, DECODE(sch_interval, 'DD', 'Day', 'WE', 'Week', 'MO', 'Month', 'YY','Year', sch_interval), sch_every FROM waters.aem_backup_schedule WHERE name IN (SELECT job_name FROM dba_scheduler_jobs WHERE enabled = 'TRUE');

BEGIN
	SELECT COUNT(*) INTO v_Count FROM waters.aem_backup_schedule;
	DBMS_OUTPUT.PUT_LINE('Number of backup schedules in WDM: '||v_Count);

	IF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('!!! WARNING: no database backups are currently defined in WDM!');
	ELSE
		SELECT COUNT(*) INTO v_Count FROM dba_scheduler_jobs WHERE enabled = 'TRUE' AND job_name IN (SELECT name FROM waters.aem_backup_schedule);
		IF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('!!! WARNING: none of the backup schedules in WDM are currently enabled!');
		ELSE
			DBMS_OUTPUT.PUT_LINE('.');
			DBMS_OUTPUT.PUT_LINE('Details of the active backup schedules in WDM:');
			OPEN C_WDMActiveBackupSch;
			LOOP
				FETCH C_WDMActiveBackupSch INTO v_SchName, v_SchDatafile, v_SchIncrLevel, v_SchArchLog, v_SchArchLogDel, v_SchCntrlFile, v_SchDelExpBkup, v_SchDelObsBkup, v_SchType, v_SchStartTime, v_SchIntervalType, v_SchIntervalTime;
				EXIT WHEN C_WDMActiveBackupSch%NOTFOUND;

				DBMS_OUTPUT.PUT_LINE('Job name: '||v_SchName);
				DBMS_OUTPUT.PUT_LINE('	Backup datafiles: '||v_SchDatafile);
				DBMS_OUTPUT.PUT_LINE('	Backup control files: '||v_SchCntrlFile);
				DBMS_OUTPUT.PUT_LINE('	Backup archive logs : '||v_SchArchLog);
				DBMS_OUTPUT.PUT_LINE('	Delete archive logs : '||v_SchArchLogDel);
				DBMS_OUTPUT.PUT_LINE('	Incremental level   : '||v_SchIncrLevel);
				DBMS_OUTPUT.PUT_LINE('	Delete expired backups : '||v_SchDelExpBkup);
				DBMS_OUTPUT.PUT_LINE('	Delete obsolete backups: '||v_SchDelObsBkup);
				IF (v_SchType = 'O')	THEN	DBMS_OUTPUT.PUT_LINE('	Frequency: once');
				ELSIF (v_SchType = 'I')	THEN	DBMS_OUTPUT.PUT_LINE('	Frequency: interval, every '|| v_SchIntervalTime ||' '||v_SchIntervalType||'(s), starting on '||v_SchStartTime);
				ELSIF (v_SchType = 'I')	THEN	DBMS_OUTPUT.PUT_LINE('	Frequency: now/immediate');
				ELSIF (v_SchType = 'D')	THEN	DBMS_OUTPUT.PUT_LINE('	Frequency: days of the week: '||v_SchIntervalTime);
				ELSE				DBMS_OUTPUT.PUT_LINE('	Frequency: unknown value ('||v_SchType||')');
				END IF;

				SELECT run_count, failure_count INTO v_JobRunCount, v_JobFailCount FROM dba_scheduler_jobs WHERE job_name = v_SchName;
				DBMS_OUTPUT.PUT_LINE('	Runs: '||v_JobRunCount||';	Failures: '||v_JobFailCount);
			END LOOP;
			CLOSE C_WDMActiveBackupSch;
		END IF;
	END IF;
END;
/

DECLARE
v_Count			PLS_INTEGER := 0;
v_ExpectedNo		PLS_INTEGER;
v_ObjName		VARCHAR2(500);
v_JobState		dba_scheduler_jobs.enabled%TYPE;

TYPE CharList		IS TABLE OF VARCHAR2(500);
v_WDMAlertJobs		CharList;

BEGIN
	v_WDMAlertJobs := CharList('ALERT_LOG_SIZE','ALERT_ORA_MESSAGES','ALERT_TABLESPACE_CHECK');
	v_ExpectedNo   := v_WDMAlertJobs.COUNT;

	DBMS_OUTPUT.PUT_LINE('.');
	DBMS_OUTPUT.PUT_LINE('.');

	SELECT COUNT(*) INTO v_Count FROM dba_scheduler_jobs WHERE owner = 'WATERS' AND job_name IN ('ALERT_LOG_SIZE', 'ALERT_ORA_MESSAGES', 'ALERT_TABLESPACE_CHECK');
	IF (v_Count = v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('WATERS owns the expected number of alert jobs ('||v_ExpectedNo||' expected, '||v_Count||' found)');
	ELSIF (v_Count < v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('!!! WARNING: WATERS owns less than the expected number of alert jobs ('||v_ExpectedNo||' expected, '||v_Count||' found)');
	ELSIF (v_Count > v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('WATERS owns more than the expected number of alert jobs ('||v_ExpectedNo||' expected, '||v_Count||' found)');
	END IF;

	DBMS_OUTPUT.PUT_LINE('.');
	FOR indx IN 1 .. v_WDMAlertJobs.COUNT
	LOOP
		v_ObjName := v_WDMAlertJobs(indx);
		SELECT COUNT(*) INTO v_Count FROM dba_scheduler_jobs WHERE job_name = v_ObjName;
		IF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('!!! WARNING: job '||v_ObjName||' is not present.  Configure this job through the WDM user interface, Server \ Configure Notifications.');
		ELSE
			SELECT enabled INTO v_JobState FROM dba_scheduler_jobs WHERE job_name = v_ObjName;
			IF (v_JobState = 'TRUE')	THEN	DBMS_OUTPUT.PUT_LINE('Job '||v_ObjName||' is present and enabled.');
			ELSE					DBMS_OUTPUT.PUT_LINE('Job '||v_ObjName||' is present and disabled.');
			END IF;
		END IF;
	END LOOP;
END;
/


COLUMN NEXT_RUN_DATE FORMAT A35
COLUMN job_name FORMAT a30
COLUMN job_class FORMAT a20
PROMPT
PROMPT
PROMPT WDM job schedules in this instance:
SELECT OWNER, JOB_NAME, JOB_CLASS, ENABLED, state, run_count, max_runs, failure_count, max_failures, next_run_date FROM dba_scheduler_jobs WHERE owner = 'WATERS';

PROMPT
PROMPT Details of the most recent job executions:
column additional_info FORMAT A50
column job_name FORMAT A20
column owner FORMAT A10
column status FORMAT A10
SET LINESIZE 1000
SELECT OWNER, JOB_NAME, STATUS, LOG_DATE, ADDITIONAL_INFO FROM  dba_scheduler_job_run_details WHERE LOG_DATE IN (SELECT MAX(LOG_DATE) FROM dba_scheduler_job_run_details WHERE OWNER = 'WATERS' GROUP BY JOB_NAME) ORDER BY OWNER, JOB_NAME;

DECLARE
v_job		VARCHAR2(30);
v_failcnt	NUMBER;
v_faildate	TIMESTAMP(6);
v_now		TIMESTAMP(6);
CURSOR C_FAIL IS SELECT job_name, failure_count FROM dba_scheduler_jobs WHERE owner = 'WATERS' ORDER BY owner, job_name;

BEGIN
	OPEN C_FAIL;
	LOOP
		FETCH C_FAIL INTO v_job, v_failcnt;
		EXIT WHEN C_FAIL%NOTFOUND;

		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('Job: '||v_job||' has failed a total of '||v_failcnt||' times');
		IF v_failcnt > 0 THEN
			SELECT MAX(LOG_DATE) INTO v_faildate FROM dba_scheduler_job_run_details WHERE job_name = v_job AND STATUS = 'FAILED';
			IF v_faildate IS NOT NULL THEN
				DBMS_OUTPUT.PUT_LINE('	The most recent failure date for this job: '||v_faildate);
				SELECT SYSDATE INTO v_now FROM DUAL;
				DBMS_OUTPUT.PUT_LINE('	The current system time is: '||v_now);
				IF v_now > v_faildate AND v_failcnt < 600 THEN
					DBMS_OUTPUT.PUT_LINE('	The most recent failure of this job occurred in the past and may not be relevant.');
					DBMS_OUTPUT.PUT_LINE('	If the most recent execution was successful (see above) then no action is required.');
				END IF;
			END IF;
		END IF;
	END LOOP;
	CLOSE C_FAIL;
END;
/

PROMPT
PROMPT ___________________________________________________________________________________________________________
PROMPT WDM performance analysis
PROMPT

DECLARE
v_AnalysisDate			DATE;

BEGIN
	SELECT MAX(last_analyzed) INTO v_AnalysisDate FROM ALL_TAB_COL_STATISTICS WHERE owner = 'WATERS';

	IF v_AnalysisDate IS NULL	THEN	DBMS_OUTPUT.PUT_LINE ('The WDM schema has never been subjected to analysis.');
	ELSE					DBMS_OUTPUT.PUT_LINE ('The WDM schema was last analyzed on: '||v_AnalysisDate);
	END IF;
END;
/

DECLARE
v_BufferPoolHitRatio	NUMBER(10,4) := 0;

BEGIN
	SELECT 1 - (phy.value/(cur.value + con.value)) INTO v_BufferPoolHitRatio FROM v$sysstat cur, v$sysstat con, v$sysstat phy WHERE cur.name = 'db block gets' AND con.name = 'consistent gets' AND phy.name = 'physical reads';
	DBMS_OUTPUT.PUT_LINE ('Buffer pool hit ratio: '||v_BufferPoolHitRatio);
	IF (v_BufferPoolHitRatio < 0.85)	THEN	DBMS_OUTPUT.PUT_LINE ('!!! WARNING: the buffer pool hit ratio is less than 85%!  Application performance may be slower than expected!');
	END IF;
END;
/

PROMPT
PROMPT WDM VERIFICATION SCRIPT COMPLETE

SPOOL OFF
