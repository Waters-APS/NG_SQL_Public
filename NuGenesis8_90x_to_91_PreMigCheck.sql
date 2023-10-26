----------------------------------------------------------------------------------------------------------------
--                                 WATERS CORPORATION
--
--             NuGenesis 8 Pre Migration Assessment Script
--
--
--  This script is intended to collect and report the information required for a NuGenesis 9.1 Migration Assessment
--  This script should be executed against a NuGenesis 8 SR2 or 9.0.x System
--

--
--  PERSON 		RELEASE		DATE		REASON
--  NPierson	1			2022-01-25 	Initial Creation
--  KAdamczyk   1.2         2022-09-01  Added query to pull 5 year audit entry history
--  KAdamczyk   1.3         2023-03-17  Added simple check for SLIM objects.
--  KAdamczyk   1.4			2023-05-16	Added section to display database configuration parameters from schema verify
--	NPierson	1.5			2023-05-23	Modified db size calculations
--	NPierson	1.6			2023-09-08	Addded query for year-based sdms archival totals (records, size)

-- set sqlplus output
SET FEEDBACK OFF LINESIZE 500 PAGESIZE 200 TRIMSPOOL ON TIMING OFF ECHO OFF DOC OFF TRIM ON verify off SERVEROUTPUT ON SIZE 1000000 heading ON define ON

COLUMN file NEW_VALUE file NOPRINT 

ALTER SESSION SET NLS_DATE_FORMAT = "MM/DD/YYYY";
SELECT 'NuGenesis8_90x_to_91_PreMigCheck_r1.6_'||to_char(sysdate,'yyyy-mm-dd_hh24-mi-ss')||'.log' "file" FROM DUAL;
SPOOL &file 
SET  define OFF

PROMPT
PROMPT                      **************************************        
PROMPT						* NUGENESIS PRE MIGRATION ASSESSMENT *
PROMPT						**************************************
PROMPT
PROMPT
PROMPT
PROMPT ___________________________________________________________________________________________________________________
PROMPT Oracle database and instance version info
PROMPT

COLUMN BANNER FORMAT A85 HEADING "VERSION"
SELECT BANNER FROM V$VERSION;

COLUMN HOST_NAME FORMAT A35
SELECT INSTANCE_NAME, HOST_NAME, STATUS, ARCHIVER, DATABASE_STATUS FROM V$INSTANCE;
PROMPT
PROMPT
PROMPT

COLUMN DBID HEADING "DATABASE ID"
COLUMN PLATFORM_NAME FORMAT A35 HEADING "OS"
COLUMN PLATFORM_ID HEADING "OS ID"
COLUMN CDB FORMAT A20 HEADING "CONTAINER DB"
PROMPT "Collecting container and DBID information.  This query may fail on non-CDB databases with ORA-00904; this is OK"
SELECT CDB, CON_ID, OPEN_MODE, CON_DBID, DBID, PLATFORM_NAME, PLATFORM_ID FROM V$DATABASE;

PROMPT.
PROMPT "Collecting DBID information for non-CDB databases:"
SELECT open_mode, dbid, platform_name, platform_id FROM v$database;
PROMPT
PROMPT
PROMPT
VARIABLE	v_SDMSSchemaVer		CHAR(20);
VARIABLE	v_LMSSchemaVerAsNum	NUMBER;
VARIABLE	v_LMSSchemaVer		CHAR(10);
VARIABLE    v_SLIMProdCount     NUMBER;

BEGIN
	SELECT NGKEYVALUE INTO :V_SDMSSchemaVer FROM NGSYSUSER.NGCONFIG WHERE NGKEYID = 'BUILDNUMBER';
	DBMS_OUTPUT.PUT_LINE('SDMS schema version: '||:V_SDMSSchemaVer);
END;
/
PROMPT
PROMPT
PROMPT
DECLARE
v_LMSSchemaDate		VARCHAR2(8000 CHAR);
v_valcodedesc		VARCHAR2(8000 CHAR);

BEGIN
	SELECT TRIM(longalphavalue), VALUECODEDESCRIPTION, ALPHAVALUE INTO  :v_LMSSchemaVer, v_valcodedesc, v_LMSSchemaDate FROM ELNPROD.SYSTEMVALUES WHERE SYSTEMTYPEID = 'DRG_SYSTEM' AND VALUECODE = 'DB_BUILDINFO';
	DBMS_OUTPUT.PUT_LINE('LMS schema version : '||:v_LMSSchemaVer||' / '||v_LMSSchemaDate|| ' / '||v_valcodedesc);
	IF	(:v_LMSSchemaVer LIKE '8.0 SR1%')	THEN	:v_LMSSchemaVerAsNum := 801;
	ELSIF	(:v_LMSSchemaVer LIKE '8.0 FR1%')	THEN	:v_LMSSchemaVerAsNum := 802;
	ELSIF	(:v_LMSSchemaVer LIKE '8.0 SR2%')	THEN	:v_LMSSchemaVerAsNum := 803;
	ELSIF  (:v_LMSSchemaVer LIKE '9.0 %')	THEN	:v_LMSSchemaVerAsNum := 9000;
	ELSIF  (:v_LMSSchemaVer LIKE '9.0.1%')	THEN	:v_LMSSchemaVerAsNum := 9010;
	ELSIF  (:v_LMSSchemaVer LIKE '9.0.2%')	THEN	:v_LMSSchemaVerAsNum := 9020;
	ELSIF	(:v_LMSSchemaVer LIKE '9.1%')	THEN	
		IF (:v_LMSSchemaVer LIKE '%HF2%')	THEN	:v_LMSSchemaVerAsNum := 9102;
		ELSE						:v_LMSSchemaVerAsNum := 9100;
		END IF;
	ELSIF	(:v_LMSSchemaVer LIKE '9.2%')	THEN	:v_LMSSchemaVerAsNum := 9200;
	ELSE						:v_LMSSchemaVerAsNum := TO_NUMBER(SUBSTR(:v_LMSSchemaVer, 1) || SUBSTR(:v_LMSSchemaVer, 3) || SUBSTR(:v_LMSSchemaVer, 5));
	END IF;
END;
/

BEGIN
    SELECT COUNT(SLIMOBJECTID) INTO :v_SLIMProdCount FROM ELNPROD.PRODUCT WHERE SLIMOBJECTID>0;
    dbms_output.put('SLIM Objects ');
    IF (:v_SLIMProdCount > 0) THEN
        dbms_output.put('ARE PRESENT ');
    ELSE
        dbms_output.put('are NOT present ');
    END IF;
    dbms_output.put_line('in the LMS database');
END;
/


PROMPT
PROMPT
PROMPT _________________________________________________________________________________________________________________
PROMPT
PROMPT
PROMPT   Determining DB_BLOCK_SIZE
PROMPT _________________________________________________________________________________________________________________
PROMPT
DECLARE
v_bsize		NUMBER;

BEGIN	
select TO_NUMBER(value) INTO v_bsize from v$parameter where name = 'db_block_size';

IF v_bsize < 8192 THEN
	DBMS_OUTPUT.PUT_LINE('.');
	DBMS_OUTPUT.PUT_LINE('!!!!!!!!!!!!!!!!!!!!!!!!! ERROR !!!!!!!!!!!!!!!!!!!!!!!!!');
	DBMS_OUTPUT.PUT_LINE('! THE DATBASE BLOCK SIZE MUST BE 8192 OR GREATER !');
	DBMS_OUTPUT.PUT_LINE('! THE DATABASE BLOCK SIZE FOR THIS INSTANCE IS: '||v_bsize||' !');
	DBMS_OUTPUT.PUT_LINE('!!!!!!!!!!!!!!!!!!!!!!!!! ERROR !!!!!!!!!!!!!!!!!!!!!!!!!');
	DBMS_OUTPUT.PUT_LINE('.');
ELSIF v_bsize > 8192 THEN
DBMS_OUTPUT.PUT_LINE('.');
	DBMS_OUTPUT.PUT_LINE('!!!!!!!!!  Non-Standard Block Size Found!!!!!!!!!!!!!! !');
	DBMS_OUTPUT.PUT_LINE('!!!!!!!!!  Database Block Size for this Instance is: '||v_bsize||' !');
	DBMS_OUTPUT.PUT_LINE('.');
ELSIF v_bsize = 8192 THEN
	DBMS_OUTPUT.PUT_LINE('Block size is ' || v_bsize);
END IF;
END;
/
PROMPT
PROMPT
PROMPT _________________________________________________________________________________________________________________
PROMPT

-----------------Determine if SDMS is in use by querying for non default project names and ELN by querying the number of documents -----------------

PROMPT Determining if ELN and/or SDMS are in use
PROMPT _________________________________________________________________________________________________________________
PROMPT
DECLARE
	v_sdms_count NUMBER;
	v_tags_count NUMBER;
BEGIN
	select count(ngprojname) into v_sdms_count from ngsdms60.ngprojdefs where ngprojguid NOT IN ('A9C668FE-A3E0-4f2f-B76E-1205E9042C40', 'BB3AF0B8-3EE3-4e4a-9BC2-E2E50672B256');
	select count(ROWID) into v_tags_count from ngsdms60.ngtags;
	IF v_sdms_count>0
	THEN
		DBMS_OUTPUT.PUT_LINE('NuGenesis SDMS is used');
		DBMS_OUTPUT.PUT_LINE('');
		DBMS_OUTPUT.PUT_LINE(v_sdms_count || ' Projects exist in SDMS');
		DBMS_OUTPUT.PUT_LINE('');
		DBMS_OUTPUT.PUT_LINE(v_tags_count || ' Records exist in NTGAGS');
		DBMS_OUTPUT.PUT_LINE('');
		DBMS_OUTPUT.PUT_LINE('SDMS Archival Volume by Year');
		DBMS_OUTPUT.PUT_LINE('Year' || '          '|| 'Total Size (GB)' || '     ' || 'Total Records');
		DBMS_OUTPUT.PUT_LINE('-------------------------------------------------------------------');
		for i in  (SELECT TO_CHAR(TRUNC(t.ngprtdatetime,'YYYY'),'YYYY') ARCHIVE_YEAR, COUNT(*) ARCHIVE_RECORDS, ROUND(SUM(t.ngreportsize)/1024/1024,0) ARCHIVE_SIZE FROM ngsdms60.ngtags t JOIN ngsdms60.ngprojdefs p ON t.ngprojguid = p.ngprojguid WHERE p.ngprojtype = 2 GROUP BY TRUNC(t.ngprtdatetime,'YYYY') ORDER BY TRUNC(t.ngprtdatetime,'YYYY')) 
	LOOP
        DBMS_OUTPUT.PUT_LINE(i.ARCHIVE_YEAR ||'        '||i.ARCHIVE_SIZE|| '                       '|| i.ARCHIVE_RECORDS);
	END LOOP;
	ELSE	
		DBMS_OUTPUT.PUT_LINE('NuGenesis SDMS is NOT used or no Projects have been created');
	END IF;
END;
/

PROMPT
PROMPT _________________________________________________________________________________________________________________
PROMPT
PROMPT


DECLARE
	v_eln_count NUMBER;
BEGIN
	select count(orderid) into v_eln_count from elnprod.measureorder;
	IF v_eln_count>0
	THEN
		DBMS_OUTPUT.PUT_LINE('NuGenesis LMS is used');
		DBMS_OUTPUT.PUT_LINE('');
		DBMS_OUTPUT.PUT_LINE(v_eln_count || ' Total Documents in the Database');
	ELSE	
		DBMS_OUTPUT.PUT_LINE('NuGenesis LMS is NOT used');
	END IF;
END;
/

PROMPT
PROMPT _________________________________________________________________________________________________________________
PROMPT
PROMPT
PROMPT

------- Simple Calculation to determine the size of database for both SDMS and LMS ---------------------------
PROMPT Determining Database Sizing

DECLARE
	v_sdms_size NUMBER(9,2);
BEGIN
	SELECT sum(bytes)/1024/1024/1024 into v_sdms_size from dba_data_files where tablespace_name LIKE '%SDMS%' OR
    tablespace_name LIKE '%SYSUSER%' OR
    tablespace_name LIKE '%SYSUSER%' OR
    tablespace_name LIKE '%WATERSMON';
	DBMS_OUTPUT.PUT_LINE('Estimated DB size (SDMS): ' || v_sdms_size || ' GB'); 
END;
/
PROMPT
PROMPT
PROMPT
PROMPT
DECLARE
	v_eln_size NUMBER(9,2);
BEGIN
	SELECT sum(bytes)/1024/1024/1024 into v_eln_size from dba_data_files where tablespace_name LIKE '%QDISR%';
	DBMS_OUTPUT.PUT_LINE('Estimated DB size (LMS): ' || v_eln_size || ' GB'); 
END;
/
PROMPT
PROMPT
PROMPT _________________________________________________________________________________________________________________
PROMPT


-----------------Determine Prevalidation Adjustments that will be required in target Instance -----------------
PROMPT PreValidationAdjustment Data
PROMPT ________________________________________________________________________________________________________________
PROMPT
col Value format a10;
col "Project Name" format a23;
select ngsysuser.ngauditseq.nextVAL "next sequence value" from dual;
PROMPT
PROMPT
 SELECT NGPROJNAME "Project Name", nglastid "Starting ID"
  FROM ngsdms60.ngprojdefs
 WHERE ngprojguid = 'BB3AF0B8-3EE3-4e4a-9BC2-E2E50672B256';
 PROMPT
 PROMPT
SELECT NGPROJNAME "Project Name", nglastid "Starting ID"
  FROM ngsdms60.ngprojdefs
 WHERE ngprojguid = 'A9C668FE-A3E0-4f2f-B76E-1205E9042C40';
 PROMPT
 PROMPT
 DECLARE
v_cnt 		NUMBER;
v_viewid	NUMBER;

CURSOR C_VIEWID IS SELECT  nglastkeyused FROM ngsdms60.ngobjnuminfo WHERE ngobjectid_key1 = 'ProjectViewUniqueID';

BEGIN

DBMS_OUTPUT.PUT_LINE('.');
DBMS_OUTPUT.PUT_LINE('______________________________________________________________________________________');
DBMS_OUTPUT.PUT_LINE('DETERMINING THE ProjectViewUniqueID VALUE  . . . ');

SELECT  count(nglastkeyused) INTO v_cnt FROM ngsdms60.ngobjnuminfo WHERE ngobjectid_key1 = 'ProjectViewUniqueID';

IF v_cnt > 0 THEN
	OPEN C_VIEWID;
	LOOP
	FETCH C_VIEWID INTO v_viewid;
	EXIT WHEN C_VIEWID%NOTFOUND;
		DBMS_OUTPUT.PUT_LINE('.');
		DBMS_OUTPUT.PUT_LINE('THE VALUE FOR ProjectViewUniqueID  IS: '||v_viewid);
	END LOOP;
	CLOSE C_VIEWID;
END IF;

IF v_cnt = 0 THEN
	DBMS_OUTPUT.PUT_LINE('.');
	DBMS_OUTPUT.PUT_LINE('The VALUE FOR ProjectViewUniqueID IS: 0');
END IF;

DBMS_OUTPUT.PUT_LINE('.');
DBMS_OUTPUT.PUT_LINE('______________________________________________________________________________________');

END;
/



-------------------------------- Block to report db parameters. --------------------------------
SET FEEDBACK OFF LINESIZE 500 PAGESIZE 200 TRIMSPOOL ON TIMING OFF ECHO OFF DOC OFF TRIM ON verify off SERVEROUTPUT ON SIZE 1000000 heading ON define ON
TTITLE OFF
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
v_rptAccess	CHAR;
v_reasonFC	CHAR;
v_secAuth	CHAR;
v_allowDel	CHAR;

CURSOR C_NGCONFIG IS SELECT NGKEYID, NGKEYVALUE FROM NGSYSUSER.NGCONFIG;
BEGIN

	OPEN C_NGCONFIG;
	LOOP
		FETCH C_NGCONFIG INTO v_ngkeyid, v_ngkeyvalue;
		EXIT WHEN C_NGCONFIG%NOTFOUND;

		IF v_ngkeyid = '19121003' THEN
			IF v_ngkeyvalue = '92121003_AAD'				THEN	v_reasonFC := 'N';
			ELSIF v_ngkeyvalue = '29121003_AAD'				THEN	v_reasonFC := 'Y';
			ELSIF v_ngkeyvalue NOT IN ('29121003_AAD', '92121003_AAD')	THEN	DBMS_OUTPUT.PUT_LINE('!!! WARNING: the reason for change option has been improperly configured. The ngkeyvalue is: '||v_ngkeyvalue);
			END IF;
		ELSIF v_ngkeyid = '191210031' THEN
			IF v_ngkeyvalue IN ('29121003','2912100')				THEN	v_secAuth := 'N';
			ELSIF v_ngkeyvalue = '291210031_2ND_AAD'				THEN	v_secAuth := 'Y';
			ELSIF v_ngkeyvalue NOT IN ('291210031_2ND_AAD','29121003','2912100')	THEN	DBMS_OUTPUT.PUT_LINE('!!! WARNING: the secondary authentication option has been improperly configured. The ngkeyvalue is: '||v_ngkeyvalue);
			END IF;
		ELSIF v_ngkeyid = '19121011' THEN
			IF v_ngkeyvalue = '20060825_1964_JP'					THEN	v_rptAccess := 'N';
			ELSIF v_ngkeyvalue = '60200825_1964_JP'					THEN	v_rptAccess := 'Y';
			END IF;
		ELSIF v_ngkeyid = '19121012' THEN
			IF v_ngkeyvalue = '02801119_2342_SD'					THEN	DBMS_OUTPUT.PUT_LINE('Legacy Audit report check box is not enabled');
			ELSE										DBMS_OUTPUT.PUT_LINE('Legacy Audit report check box is enabled');
			END IF;
		ELSIF v_ngkeyid = '19121013' THEN
			IF v_ngkeyvalue = '02900506_5474_SD'					THEN	DBMS_OUTPUT.PUT_LINE('Legacy User Deletion: N');
			ELSE										DBMS_OUTPUT.PUT_LINE('Legacy User Deletion: Y');
			END IF;
		END IF;
	END LOOP;
	CLOSE C_NGCONFIG;
	
	SELECT COUNT(PRIVILEGE) INTO v_count FROM DBA_TAB_PRIVS WHERE PRIVILEGE = 'EXECUTE' AND TABLE_NAME = 'NGSDMS60USERMGMT' AND GRANTEE = 'NGPROXY';
	IF	(v_count = 0)	THEN	v_allowDel := 'N';
	ELSIF	(v_count = 1)	THEN	v_allowDel := 'Y';
	END IF;
	
	DBMS_OUTPUT.PUT_LINE('Audit Report Access: '||v_rptAccess);
	DBMS_OUTPUT.PUT_LINE('Reason for Change: '||v_reasonFC);
	DBMS_OUTPUT.PUT_LINE('Secondary Authorization: '||v_secAuth);
	DBMS_OUTPUT.PUT_LINE('User Deletion: '||v_allowDel);
END;
/




PROMPT
PROMPT
PROMPT ______________________________________________________________________________________
PROMPT Summarizing number of audit entries by year.
PROMPT ______________________________________________________________________________________
col YEAR format 9999
col NUMREC format 9999999999

SELECT EXTRACT(YEAR FROM NGSERVERUTCDATETIME) YEAR, COUNT(NGSERVERUTCDATETIME) NUMREC FROM NGSYSUSER.NGAUDITMASTER WHERE EXTRACT(YEAR FROM NGSERVERUTCDATETIME)>EXTRACT(YEAR FROM SYSDATE)-5 GROUP BY EXTRACT(YEAR FROM NGSERVERUTCDATETIME) ORDER BY YEAR;

PROMPT
PROMPT
PROMPT
PROMPT


-----------------Determine if DB is using basic file system or ASM-----------------

PROMPT Determining if ASM is in use
PROMPT _________________________________________________________________________________________________________________
PROMPT
DECLARE
	v_asm_count NUMBER;
BEGIN
	select count(*) into v_asm_count from dba_data_files where file_name LIKE '+%';
	IF v_asm_count>0
	THEN
		DBMS_OUTPUT.PUT_LINE('!!!!!!!!!!!!!NuGenesis Database DOES utilize ASM Storage!!!!!!!!!!!!!!!!!');
	ELSE	
		DBMS_OUTPUT.PUT_LINE('NuGenesis Database does NOT utilize ASM Storage');
	END IF;
END;
/

PROMPT
PROMPT _________________________________________________________________________________________________________________
PROMPT
PROMPT

-----------------Check for any use of Oracle Advanced Compression in Tables -----------------

PROMPT
PROMPT      NG Tables using compression 
PROMPT _________________________________________________________________________________________________________________
PROMPT

col owner format a30
col table_name format a30
select OWNER,TABLE_NAME,BLOCKS,PARTITIONED, COMPRESSION,COMPRESS_FOR from dba_tables where compression='ENABLED' order by 1,2;


----Check for any use of Oracle Advanced Compression Partitions - Compress OLTP or Advanced indicates it is in use-------

PROMPT
PROMPT      NG Partitions using compression
PROMPT _________________________________________________________________________________________________________________
PROMPT
PROMPT

col table_owner format a15
col partition_name format a30
col blocks format 9999999
col compression format a15
col compress_for format a15  
select table_owner, table_name, partition_name, blocks, compression, compress_for from dba_tab_partitions 
where table_owner in ('NGSDMS60','NGSYSUSER','ELNPROD') and compression='ENABLED' order by 1,2,3;


----Check for any use of Oracle Advanced Compression LOB Partitions - anything other than BASIC is Advanced Compression -------

PROMPT
PROMPT      NG LOB Partitions using compression
PROMPT _________________________________________________________________________________________________________________
PROMPT
PROMPT

col partition_name format a30
col LOB_NAME format a25
col securefile  format a15  
select table_owner, table_name, partition_name, LOB_NAME, compression, securefile from dba_lob_partitions 
where table_owner in ('NGSDMS60','NGSYSUSER','ELNPROD') and compression != 'NO' order by 1,2,3;


----Check for any use of Oracle Advanced Compression LOBS - anything other than BASIC is Advanced Compression -------
PROMPT
PROMPT      NG LOBS using compression
PROMPT _________________________________________________________________________________________________________________
PROMPT
PROMPT

col owner format a30
col segment_name format a40
col table_name format a35
col compression format a30
select owner, table_name, segment_name, COMPRESSION from dba_lobs where owner in ('NGSDMS60','NGSYSUSER','ELNPROD') and compression != 'NO' order by 1,2,3;


PROMPT
PROMPT      Determining whether Partitioning is in use
PROMPT _________________________________________________________________________________________________________________
PROMPT
PROMPT

DECLARE
	v_part VARCHAR2(3);
BEGIN
	select decode(count(*), 0, 'No', 'Yes') into v_part from (select 1 from dba_part_tables
	where owner in ('NGSDMS60','NGSYSUSER','ELNPROD'));
	IF v_part='Yes'
	THEN
		DBMS_OUTPUT.PUT_LINE('Oracle Partitioning IS in use');
	ELSE	
		DBMS_OUTPUT.PUT_LINE('Oracle Partitioning is NOT in use');
	END IF;
END;
/

PROMPT
PROMPT _________________________________________________________________________________________________________________
PROMPT


----Check for any use of SDMS Managed Storage and Offline Storage -------

PROMPT
PROMPT      NG Managed Storage Summary 
PROMPT _________________________________________________________________________________________________________________
PROMPT
PROMPT

DECLARE
	v_ms_count NUMBER;
BEGIN
	select count(NGSTOREGUID) into v_ms_count from NGSDMS60.NGSERVERSTORES;
	IF v_ms_count>0
	THEN
		DBMS_OUTPUT.PUT_LINE('NuGenesis Managed Storage IS used');
		DBMS_OUTPUT.PUT_LINE('MANAGED STORAGE DEVICE SUMMARY');
		DBMS_OUTPUT.PUT_LINE('__________________________________________________________________');
		For ms IN (SELECT * FROM ngsdms60.ngserverstores)
		LOOP
			DBMS_OUTPUT.PUT_LINE('Device Name: ' || ms.NGSTORENAME || '          Device URL: ' || ms.NGSTOREACCESSURL);
		END LOOP;
	ELSE	
		DBMS_OUTPUT.PUT_LINE('NuGenesis Managed Storage is NOT used');
	END IF;
END;
/

PROMPT
PROMPT _________________________________________________________________________________________________________________
PROMPT
PROMPT


PROMPT
PROMPT      NG OSM Storage Summary 
PROMPT _________________________________________________________________________________________________________________
PROMPT
PROMPT

DECLARE
	v_osm_count NUMBER;
BEGIN
	select count(NGDEVICENAME) into v_osm_count from NGSDMS60.NGARCHIVEDEVICES;
	IF v_osm_count>0
	THEN
		DBMS_OUTPUT.PUT_LINE('NuGenesis OSM is used');
		DBMS_OUTPUT.PUT_LINE('OSM DEVICE SUMMARY');
		DBMS_OUTPUT.PUT_LINE('__________________________________________________________________');
		For osm IN (SELECT * FROM NGSDMS60.NGARCHIVEDEVICES)
		LOOP
			DBMS_OUTPUT.PUT_LINE('Device Name: ' || osm.NGDEVICENAME || '   Device Path: ' || osm.NGDEVICEPATH);
		END LOOP;
	ELSE	
		DBMS_OUTPUT.PUT_LINE('NuGenesis OSM is NOT used');
	END IF;
END;
/


PROMPT
PROMPT _________________________________________________________________________________________________________________
PROMPT
PROMPT



----Determine whether Instrument Agents are in use due to requirement for ELNPROD migration for SDMS Only Scenarios -------
PROMPT
PROMPT      Determining whether Instrument Agents are in use
PROMPT _________________________________________________________________________________________________________________
PROMPT
PROMPT

DECLARE
	v_iagent_count NUMBER;
BEGIN
	select count(*) into v_iagent_count from ELNPROD.INSTRUMENT where instrumentID NOT LIKE 'WELN%' and to_date(dateapproved,'YYYYMMDD') > to_date('02-NOV-2004','DD-MON-YYYY');
	IF v_iagent_count>0
	THEN
		DBMS_OUTPUT.PUT_LINE('!!!!!!!!!!!!!!!!!!!!!NuGenesis Instrument Agents ARE in use!!!!!!!!!!!!!!!!!!!!!!!!');
	ELSE	
		DBMS_OUTPUT.PUT_LINE('NuGenesis Instrument Agents are NOT in use');
	END IF;
END;
/


PROMPT
PROMPT _________________________________________________________________________________________________________________
PROMPT





SPOOL OFF;

