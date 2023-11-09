# Overview
This is the public repository for database SQL scripts related to the NuGenesis Oracle Database.

These fall under a few categories:
- Schema Verify scripts
- DB Monitor scripts
- Pre-Migration scripts

## Details
The following is a brief description of each of the sripts and their purpose:
|Script|Stage|Use|
|---:|---|:---|
|NuGenesis8_90x_to91_PreMigCheck|Pre-Sales/Pre-Service|Script to get premigration values along with table sizes and other migration critical information|
|Slim_schema_verify.sql|Deployment|Script to verify the installation of the Stability Module|
|WDM_verify_schema.sql|Deployment|Script to verify the installation of Waters Database Manager|
|WSM_verify_schema.sql|Deployment|Script to verify the installation of Waters System Monitor|
|nugenesis9_schema_verify.sql|Deployment/Support|Script to verify the installation of the SDMS and LMS Schemas|
|nugenesis9_PreInstall_checklist.sql|Pre-Sales/Pre-Service|To be used with Linux databases to see if the deployed database meets the core requrirements|
|nugenesis9_db_monitor.sql|Support|Script to check the various DB parameters to troubleshoot possible issues with tablespace|

