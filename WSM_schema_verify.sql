----------------------------------------------------------------------------------------------------------------------------------------
--                      		Waters Corporation
--                    		   WSM schema verification script
-- This script is to be used for verification of the Waters System Monitor database schema.
----------------------------------------------------------------------------------------------------------------------------------------
-- PERSON 		REVISION		DATE			REASON
-- MMorrison		1			2021-02-25		CREATION
-- MMorrison		2			2023-02-17		Chek for roles granted to the watersmon schema.
----------------------------------------------------------------------------------------------------------------------------------------

SET FEEDBACK OFF LINESIZE 500 PAGESIZE 100 TRIMSPOOL ON TIMING OFF ECHO OFF DOC OFF TRIM ON verify off SERVEROUTPUT ON SIZE 1000000 heading ON define ON
TTITLE OFF

COLUMN file NEW_VALUE file NOPRINT 
COLUMN BYTES 			FORMAT 999,999,999,999 heading 'Size'
COLUMN TODAY 			FORMAT a30 heading "Todays Date"
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
col parameter format a30

ALTER SESSION SET NLS_DATE_FORMAT = "MM/DD/YYYY";
COLUMN file NEW_VALUE file NOPRINT 
SELECT 'WSM_schema_verify_r2_'||to_char(sysdate,'yyyy-mm-dd_hh24-mi')||'.log' "file" FROM DUAL;

SPOOL &file 

prompt           ***********************************************************
prompt           * Waters System Monitor SCHEMA VERIFICATION REPORT *
prompt           ***********************************************************
prompt   .
prompt		  THIS SCRIPT MUST BE EXECUTED WITH DBA PRIVILEGES!
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
COLUMN CDB FORMAT A35 HEADING "CONTAINER DB"
SELECT CDB, CON_ID, OPEN_MODE, CON_DBID, DBID, PLATFORM_NAME, PLATFORM_ID, log_mode FROM V$DATABASE;

COLUMN COMP_NAME FORMAT	A40 HEADING "COMPONENT NAME"
COLUMN VERSION FORMAT A12
PROMPT ORACLE COMPONENT INFORMATION FOR THIS DATABASE INSTANCE:
SELECT COMP_NAME, VERSION, STATUS, MODIFIED FROM DBA_REGISTRY;

PROMPT DATABASE CONFIGURATION PARAMETERS:
SELECT substr(name,1,30) Name, substr(value,1,25) Value FROM v$parameter WHERE name IN ('cpu_count','shared_pool_size','db_cache_size','db_block_size','db_file_multiblock_read_count','parallel_automatic_tuning','text_enable','optimizer_percent_parallel','sql_version','optimizer_mode','open_cursors','db_name','sort_area_size','sort_area_retained_size','instance_name','db_files');

PROMPT DATABASE LANGUAGE SETTINGS:
COLUMN VALUE	FORMAT A40
SELECT * FROM NLS_DATABASE_PARAMETERS;

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
PROMPT
PROMPT ___________________________________________________________________________________________________________
PROMPT Determining whether the NuGenesis Stability schema accounts are present...
PROMPT

DECLARE
v_Count			PLS_INTEGER := 0;
v_ExpectedNo		PLS_INTEGER;
v_AcctProfile		dba_users.profile%TYPE;
v_AcctStatus		dba_users.account_status%TYPE;
v_AcctName		dba_users.username%TYPE;
v_AcctPwdTime		dba_profiles.limit%TYPE;

TYPE ObjList		IS TABLE OF VARCHAR2(500);
t_SchemaAccounts	ObjList;

BEGIN
	t_SchemaAccounts := ObjList('WATERSMON');
	v_ExpectedNo     := t_SchemaAccounts.COUNT;

	SELECT COUNT(*) INTO v_Count FROM dba_users WHERE username IN ('WATERSMON');
	IF (v_Count < v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: fewer than the expected number of WSM accounts are present in this DB instance ('||v_ExpectedNo||' expected, '||v_Count||' found)!');
	ELSIF (v_Count = v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('The expected number of WSM accounts are present in this DB instance ('||v_ExpectedNo||' expected, '||v_Count||' found).');
	ELSIF (v_Count > v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('!!! WARNING: more than expected number of WSM accounts are present in this DB instance ('||v_ExpectedNo||' expected, '||v_Count||' found)!');
	END IF;

	FOR indx IN 1 .. t_SchemaAccounts.COUNT
	LOOP
		v_AcctName := t_SchemaAccounts(indx);
		SELECT COUNT(*) INTO v_Count FROM dba_users WHERE username = v_AcctName;
		IF (v_Count = 1) 	THEN	DBMS_OUTPUT.PUT_LINE('The '||v_AcctName||' account has been created.');
		ELSIF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: the '||v_AcctName||' account has not been created!');
		END IF;

		DBMS_OUTPUT.PUT_LINE ('.');
	END LOOP;
END;
/

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
	t_AccountProfiles := ObjList('WATERSMONPROFILE');

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
PROMPT Determining whether the expected tablespaces and quotas are present for the WSM schemas
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

BEGIN
	t_TblspcList := ObjList('WATERSMON_DATA','WATERSMON_IDX');

	DBMS_OUTPUT.PUT_LINE ('.');
	DBMS_OUTPUT.PUT_LINE ('Checking the other NuGenesis tablespaces by name:');
	FOR indx IN 1 .. t_TblspcList.COUNT
	LOOP
		v_TblspcName := t_TblspcList(indx);
		IF (v_TblspcName = 'WATERSMON_DATA')	THEN
			t_SchemaList := ObjList('WATERSMON');
			t_QuotaList  := NumList(-1);
		ELSIF (v_TblspcName = 'WATERSMON_IDX')	THEN
			t_SchemaList := ObjList('WATERSMON');
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

COLUMN USERNAME FORMAT A17
COLUMN QUOTA FORMAT A16
PROMPT
PROMPT
SELECT REPLACE(max_bytes, '-1', 'UNLIMITED') "QUOTA", USERNAME, TABLESPACE_NAME FROM dba_ts_quotas where username IN ('WATERSMON') order by username;

PROMPT
PROMPT _________________________________________________________________________________________________
PROMPT Determining whether the WSM schemas have the expected system privileges and roles...
PROMPT

DECLARE
v_Count			PLS_INTEGER := 0;
v_ExpectedNo		PLS_INTEGER;
v_PrivName		dba_sys_privs.privilege%TYPE;
v_SchemaName		VARCHAR2(100);

TYPE CharList		IS TABLE OF VARCHAR2(500);
t_SchemaList		CharList;
t_SystemPrivs		CharList;
t_RoleList		CharList;

BEGIN
	t_SchemaList  := CharList('WATERSMON');
	FOR indx2 IN 1 .. t_SchemaList.COUNT
	LOOP
		v_SchemaName  := t_SchemaList(indx2);
		IF(v_SchemaName = 'WATERSMON')		THEN
			t_SystemPrivs := CharList('CREATE VIEW','CREATE SESSION');
			t_RoleList    := CharList('CONNECT','RESOURCE');
		END IF;

		-- System privileges
		v_ExpectedNo := t_SystemPrivs.COUNT;
		SELECT COUNT(*) INTO v_Count FROM dba_sys_privs WHERE grantee = v_SchemaName;
		IF (v_Count = v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('The '||v_SchemaName||' schema has the correct number of system privileges ('||v_ExpectedNo||' expected, '||v_Count||' found).');
		ELSIF (v_Count < v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: the '||v_SchemaName||' schema has fewer than the expected number of system privileges ('||v_ExpectedNo||' expected, '||v_Count||' found)!');
		ELSIF (v_Count > v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('The '||v_SchemaName||' schema has more than the expected number of system privileges ('||v_ExpectedNo||' expected, '||v_Count||' found)!');
		END IF;

		FOR indx IN 1 .. t_SystemPrivs.COUNT
		LOOP
			v_PrivName := t_SystemPrivs(indx);
			SELECT COUNT(*) INTO v_Count FROM dba_sys_privs WHERE grantee = v_SchemaName AND privilege = v_PrivName;
			IF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: '||v_SchemaName||' was not granted the sys privilege: '||v_PrivName);
			ELSE				DBMS_OUTPUT.PUT_LINE('-- '||v_SchemaName||' was granted the sys privilege: '||v_PrivName);
			END IF;
		END LOOP;
		DBMS_OUTPUT.PUT_LINE('.');

		-- Roles
		v_ExpectedNo := t_RoleList.COUNT;
		SELECT COUNT(*) INTO v_Count FROM dba_role_privs WHERE grantee = v_SchemaName;
		IF (v_Count = v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('The '||v_SchemaName||' schema has the correct number of roles ('||v_ExpectedNo||' expected, '||v_Count||' found).');
		ELSIF (v_Count < v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: the '||v_SchemaName||' schema has fewer than the expected number of roles ('||v_ExpectedNo||' expected, '||v_Count||' found)!');
		ELSIF (v_Count > v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('The '||v_SchemaName||' schema has more than the expected number of roles ('||v_ExpectedNo||' expected, '||v_Count||' found)!');
		END IF;

		FOR indx IN 1 .. t_RoleList.COUNT
		LOOP
			SELECT COUNT(*) INTO v_Count FROM dba_role_privs WHERE grantee = v_SchemaName AND granted_role = t_RoleList(indx);
			IF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: '||v_SchemaName||' was not granted the role: '||t_RoleList(indx));
			ELSE				DBMS_OUTPUT.PUT_LINE('-- '||v_SchemaName||' was granted the role: '||t_RoleList(indx));
			END IF;
		END LOOP;
	END LOOP;
END;
/

COLUMN GRANTEE 		FORMAT	A18
COLUMN PRIVILEGE 	FORMAT	A30
COLUMN ADMIN_OPTION	FORMAT	A12
BREAK ON GRANTEE SKIP 1
PROMPT
SELECT grantee, privilege, admin_option FROM dba_sys_privs WHERE grantee IN ('WATERSMON') ORDER BY grantee;

COLUMN granted_role format a30
SELECT grantee, granted_role FROM dba_role_privs WHERE grantee IN ('WATERSMON') ORDER BY 1,2;

PROMPT
PROMPT _________________________________________________________________________________________________
PROMPT Determining if the expected object privileges have been granted to the WSM schema...
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
	t_SchemaList  := ObjList('WATERSMON');

	FOR indx IN 1 .. t_SchemaList.COUNT
	LOOP
		v_SchemaName := t_SchemaList(indx);
		IF (v_SchemaName = 'WATERSMON')			THEN
			t_PrivNameList     := ObjList('SELECT','SELECT');
			t_PrivObjOwnerList := ObjList('NGSDMS60','NGSDMS60');
			t_PrivObjNameList  := ObjList('NGPROJDEFS','NGPROJTPL');
		END IF;

		v_ExpectedNo := t_PrivNameList.COUNT;
		SELECT COUNT(PRIVILEGE) INTO v_Count FROM DBA_TAB_PRIVS WHERE GRANTEE = v_SchemaName;
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
PROMPT _________________________________________________________________________________________________
PROMPT Determining the number of objects owned by the WSM schemas
PROMPT
PROMPT Number of objects owned by the NuGenesis Stability schemas:
SELECT owner, COUNT(*) "ObjCount" FROM dba_objects WHERE owner IN ('WATERSMON') AND object_name NOT LIKE 'BIN$' GROUP BY owner ORDER BY owner;

PROMPT
PROMPT
PROMPT Number of objects owned by the NuGenesis schemas broken down by object type:
SELECT owner, object_type, COUNT(*) "ObjCount" FROM dba_objects WHERE owner IN ('WATERSMON') AND object_name NOT LIKE 'BIN$' GROUP BY owner, object_type ORDER BY owner, object_type;


PROMPT
PROMPT _________________________________________________________________________________________________
PROMPT Determining whether the expected tables are present in the WSM schema...
PROMPT
DECLARE
v_Count		PLS_INTEGER := 0;
v_tab		SYS.DBA_TABLES.TABLE_NAME%TYPE;
v_ExpectedNo	PLS_INTEGER;
v_SchemaName	VARCHAR2(500) := 'WATERSMON';

TYPE ObjList	IS TABLE OF VARCHAR2(10000);
t_TableList	ObjList;

BEGIN
	t_TableList := ObjList('AUDITTRAIL','NODEEVENTS','NODES','NOTIFICATIONS','STATUSKEYWORDS','STATUSTYPES','SYSTEMCONFIG','SYSTEMEVENTS','SYSTEMLOGFILE','SYSTEMTYPES');
	v_ExpectedNo := t_TableList.COUNT;

	SELECT COUNT(*) INTO v_Count FROM DBA_OBJECTS WHERE OWNER = v_SchemaName AND OBJECT_TYPE = 'TABLE' AND OBJECT_NAME NOT LIKE '%_BAK' AND object_name NOT LIKE 'BIN%';
	IF (v_Count = v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE(v_SchemaName||' owns the expected number of tables ('||v_ExpectedNo||' expected, '||v_Count||' found)');
	ELSIF (v_Count < v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: '||v_SchemaName||' owns less than the expected number of tables ('||v_ExpectedNo||' expected, '||v_Count||' found)!');
	ELSIF (v_Count > v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE(v_SchemaName||' owns more than the expected number of tables ('||v_ExpectedNo||' expected, '||v_Count||' found)!');
	END IF;

	FOR indx IN 1 .. t_TableList.COUNT
	LOOP
		v_tab := t_TableList(indx);
		SELECT COUNT(*) INTO v_Count FROM dba_tables WHERE owner = v_SchemaName AND table_name = v_tab;
		IF (v_Count = 1)	THEN	DBMS_OUTPUT.PUT_LINE('-- table '||v_SchemaName||'.'||v_tab||' is present');
		ELSE				DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: table '||v_SchemaName||'.'||v_tab||' is NOT present!');
		END IF;
	END LOOP;
END;
/

PROMPT
PROMPT __________________________________________________________________________________________
PROMPT Checking indexes in the WSM schema...
PROMPT
DECLARE
v_IndexName	dba_indexes.index_name%TYPE;
v_IndexOwner	dba_indexes.owner%TYPE;
v_IndexType	dba_indexes.index_type%TYPE;
v_IndexStatus	dba_indexes.status%TYPE;
v_IndexTabName	dba_indexes.table_name%TYPE;
v_IndexLogging	dba_indexes.logging%TYPE;
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

CURSOR C_IndexesNoLogging IS	SELECT INDEX_NAME, owner FROM DBA_INDEXES WHERE owner IN ('WATERSMON') AND LOGGING = 'NO';

BEGIN
	SELECT COUNT(*) INTO v_Count FROM DBA_INDEXES DI WHERE owner IN('WATERSMON') AND LOGGING = 'NO';
	IF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('All indexes in the WSM schemas are logging');
	ELSE
		DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: '||v_Count||' indexes in the WSM schemas have the nologging attribute!  The presence of nologging indexes can result in unrecoverable backups!  These indexes are listed below:');
		OPEN C_IndexesNoLogging;
		LOOP
			FETCH C_IndexesNoLogging INTO v_IndexName, v_IndexOwner;
			EXIT WHEN C_IndexesNoLogging%NOTFOUND;

			DBMS_OUTPUT.PUT_LINE('-- '||v_IndexOwner||'.'||v_IndexName);
		END LOOP;
		CLOSE C_IndexesNoLogging;
	END IF;

	t_SchemaList     := ObjList('WATERSMON');
	t_IndexTypeList  := ObjList('DOMAIN','NORMAL','CLUSTER','LOB','IOT - TOP','FUNCTION-BASED NORMAL');
	FOR indx2 IN 1 .. T_SchemaList.COUNT
	LOOP
		v_SchemaName := t_SchemaList(indx2); -- Load the table variables appropriately for the schema and product version
		IF	(v_SchemaName = 'WATERSMON')	THEN
			t_ExpectedNoList := NumList(0, 5, 0, 0, 0, 0); -- number of expected indexes for this schema per index type
			t_IndexNameList  := ObjList('IDX_NODE_1','IDX_NODEEVENTS_1','IDX_SYSTEMEVENTS_1','IDX_SYSTEMEVENTS_2','IDX_SYSTEMLOGFILE_1');
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
			IF (v_Count = v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('-- '||v_SchemaName||' owns the expected number of '||v_IndexType||' indexes ('||v_ExpectedNo||' expected, '||v_Count||' found)');
			ELSIF (v_Count < v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: '||v_SchemaName||' owns less than the expected number of '||v_IndexType||' indexes ('||v_ExpectedNo||' expected, '||v_Count||' found)!');
			ELSIF (v_Count > v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('-- '||v_SchemaName||' owns more than the expected number of '||v_IndexType||' indexes ('||v_ExpectedNo||' expected, '||v_Count||' found)');
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
				SELECT logging, status INTO v_IndexLogging, v_IndexStatus FROM dba_indexes WHERE index_name  = t_IndexNameList(indx) AND owner = v_SchemaName;

				IF (v_IndexStatus = 'VALID')			THEN	DBMS_OUTPUT.PUT_LINE('-- index is '||v_IndexStatus);
				ELSE							DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: index status '||v_IndexStatus||' is incorrect; it should be VALID!');
				END IF;

				IF (v_IndexLogging = 'YES')			THEN	DBMS_OUTPUT.PUT_LINE('-- index is in LOGGING mode');
				ELSE							DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: index logging status '||v_IndexLogging||' is incorrect; it should be in logging mode!');
				END IF;
			END IF;
		END LOOP;
		DBMS_OUTPUT.PUT_LINE ('.');
		DBMS_OUTPUT.PUT_LINE ('.');
	END LOOP;
END;
/

PROMPT
SELECT owner, index_name, index_type, status, table_name FROM dba_indexes WHERE owner = 'WATERSMON' ORDER BY 3, 2;



PROMPT
PROMPT _________________________________________________________________________________________________
PROMPT Checking for tiggers in the WSM schema...
PROMPT
DECLARE
v_Count			PLS_INTEGER := 0;
v_ExpectedNo		PLS_INTEGER;
v_SchemaName		VARCHAR2(100);

v_TriggerName		DBA_TRIGGERS.TRIGGER_NAME%TYPE;
v_TriggerStatus		dba_triggers.status%TYPE;
v_TableOwner		dba_triggers.table_owner%TYPE;
v_TriggerType		dba_triggers.trigger_type%TYPE;
v_TriggerEvent		dba_triggers.triggering_event%TYPE;
v_TableName		dba_triggers.table_name%TYPE;

v_ExpectedStatus	dba_triggers.status %TYPE := 'ENABLED';
v_ExpectedTableName	dba_triggers.table_name%TYPE;
v_ExpectedTrigType	dba_triggers.trigger_type%TYPE;
v_ExpectedTrigEvent	dba_triggers.triggering_event%TYPE;

TYPE ObjList		IS TABLE OF VARCHAR2(500);
TYPE NumList		IS TABLE OF NUMBER;
t_SchemaList		ObjList;
t_ExpectedNoList	NumList;
t_TriggerNameList	ObjList;
t_TriggerTypeList	ObjList;
t_TriggerEventList	ObjList;
t_TriggerTabNameList	ObjList;

BEGIN
	t_SchemaList     := ObjList('WATERSMON');

	FOR indx IN 1 .. t_SchemaList.COUNT
	LOOP
		v_SchemaName := t_SchemaList(indx);
		IF	(v_SchemaName = 'WATERSMON')	THEN
			t_TriggerNameList    := ObjList();
			t_TriggerTypeList    := ObjList();
			t_TriggerTabNameList := ObjList();
			t_TriggerEventList   := ObjList();
		END IF;
		v_ExpectedNo := t_TriggerNameList.COUNT;

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
		DBMS_OUTPUT.PUT_LINE ('.');
	END LOOP;
END;
/

PROMPT
PROMPT ___________________________________________________________________________________________________________
PROMPT Determining if the WSM schema accounts own the correct number of sequences
PROMPT
PROMPT
DECLARE
v_Count			PLS_INTEGER := 0;
v_ExpectedNo		PLS_INTEGER;
v_ObjName		dba_sequences.sequence_name%TYPE;
v_ObjStatus		dba_objects.status%TYPE;
v_SchemaName		VARCHAR2(100) := 'WATERSMON';

TYPE ObjList		IS TABLE OF VARCHAR2(500);
t_SequenceList		ObjList;

BEGIN
	t_SequenceList := ObjList('NODE_ID_SEQ','NODEEVENTS_EVENTID_SEQ','SYSTEMEVENTS_EVENTID_SEQ','NOTIFICATIONS_ID_SEQ','AUDITTRAIL_AUDITID_SEQ');
	v_ExpectedNo   := t_SequenceList.COUNT;

	SELECT COUNT(*) INTO v_Count FROM dba_sequences WHERE sequence_owner = v_SchemaName;
	IF (v_Count = v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE(v_SchemaName||' owns the expected number of sequences ('||v_ExpectedNo||' expected, '||v_Count||' found)');
	ELSIF (v_Count < v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('!!!!! ERROR: '||v_SchemaName||' owns less than the expected number of sequences ('||v_ExpectedNo||' expected, '||v_Count||' found)!');
	ELSIF (v_Count > v_ExpectedNo)	THEN	DBMS_OUTPUT.PUT_LINE('WARNING: '||v_SchemaName||' owns more than the expected number of sequences ('||v_ExpectedNo||' expected, '||v_Count||' found)');
	END IF;

	FOR indx IN 1 .. t_SequenceList.COUNT
	LOOP
		v_ObjName := t_SequenceList(indx);
		SELECT COUNT(*) INTO v_Count FROM dba_sequences WHERE sequence_owner = v_SchemaName AND sequence_name = v_ObjName;
		IF (v_Count = 0)	THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: '||v_SchemaName||' does not own the sequence: '||v_ObjName);
		ELSIF (v_Count = 1)	THEN
			DBMS_OUTPUT.PUT_LINE('-- '||v_SchemaName||' owns the sequence: '||v_ObjName);
			SELECT status INTO v_ObjStatus FROM dba_objects WHERE owner = v_SchemaName AND object_name = v_ObjName AND object_Type = 'SEQUENCE';
			IF (v_ObjStatus != 'VALID')	THEN	DBMS_OUTPUT.PUT_LINE('-- !!!!! ERROR: the sequence '||v_ObjName||' is not valid!');
			ELSE					DBMS_OUTPUT.PUT_LINE('-- the sequence '||v_ObjName||' is valid');
			END IF;
		END IF;
	END LOOP;
END;
/

PROMPT
PROMPT ___________________________________________________________________________________________________________
PROMPT Determining if the WSM schema accounts own the correct number of views
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
	v_Schemas	:= ObjList('WATERSMON');
	FOR ind IN 1 .. v_Schemas.COUNT
	LOOP
		v_SchemaName := v_Schemas(ind); -- Select a schema from the list
		IF (v_SchemaName = 'WATERSMON')		THEN -- Load the table variables with lists appropriate for the schema
			v_Views      := ObjList('VW_SYSTEMSTATUS','VW_CURRENTNODESTATUS','VW_EMAILNOTIFICATIONS');
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
PROMPT _________________________________________________________________________________
PROMPT Determining when the NuGenesis database schemas were last analyzed
PROMPT Statistics generated by analysis are used by Oracle to improve query performance
PROMPT
DECLARE
v_andate		DATE;
v_Count			PLS_INTEGER := 0;

BEGIN
	select max(LAST_ANALYZED) INTO v_andate from ALL_TAB_COL_STATISTICS where owner = 'WATERSMON';
	IF v_andate IS NULL THEN	DBMS_OUTPUT.PUT_LINE ('The watersmon schema has never been subjected to analysis');
	ELSE				DBMS_OUTPUT.PUT_LINE ('The watersmon schema was last analyzed on: '||v_andate);
	END IF;
END;
/

PROMPT BUFFER POOL HIT RATIO:
SELECT 1 - (phy.value/(cur.value + con.value)) "HIT RATIO" from v$sysstat cur, v$sysstat con, v$sysstat phy WHERE cur.name = 'db block gets' AND con.name = 'consistent gets' AND phy.name = 'physical reads';

PROMPT
PROMPT WSM VERIFICATION SCRIPT COMPLETE
PROMPT

SPOOL OFF
