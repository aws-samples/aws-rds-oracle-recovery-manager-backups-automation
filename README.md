## My Project
" aws-rds-oracle-recovery-manager-backups-automation"

This is project to automate the RDS Oracle RMAN backups to S3 using an Stored Procedure 
and using Lambda to trigger a notification

TODO: Fill this README out!

Be sure to:

* Change the title in this README
* Edit your repository description on GitHub

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This library is licensed under the MIT-0 License. See the LICENSE file.

#####################

**rds-rman-plsql-code.sql**

The PL/SQL Code is to create a SP in RDS Oracle RMAN --> rds-rman-plsql-code.sql

## Import Note: Use a Dedicated S3 bucket and avoid any other irrelevant files in it - if other files are found the backup procedure will run in endless loop

## Second import note while executing the procedure

if command -- exec rman_s3 (<bucket_name>); fails then run the bucket name with single quotes as follows

exec rman_s3 ('<bucket_name>');

## * The RDS constructs and syntax change can update time to time, please follow and update the code as is. This code is open source for public to modify as needed

## Important Step: to execute the procedure you need to grant the following privilege

grant create any procedure to <oracle_user>;

grant select any dictionary to <oracle_user>;

**example**:
  grant create any procedure to admin;
  
  grant select any dictionary to admin;

  and then execute the procedure PL/SQL code to compile and this will compile the procedure with no errors.
  
 * the above steps are needed when following error is seen*
 
    Procedure RMAN_S3 compiled
    LINE/COL ERROR
    ——— ————————————————————-
    33/3 PL/SQL: SQL Statement ignored
    35/21 PL/SQL: ORA-01031: insufficient privileges
    43/14 PL/SQL: SQL Statement ignored
    44/19 PL/SQL: ORA-01031: insufficient privileges
    46/5 PL/SQL: Statement ignored
    46/38 PLS-00364: loop index variable ‘I’ use is invalid
    56/3 PL/SQL: Statement ignored
    56/12 PLS-00904: insufficient privilege to access object RDSADMIN.RDSADMIN_RMAN_UTIL
    66/8 PL/SQL: SQL Statement ignored
    68/9 PL/SQL: ORA-00942: table or view does not exist
    77/13 PL/SQL: SQL Statement ignored
    78/18 PL/SQL: ORA-00942: table or view does not exist
    83/4 PL/SQL: SQL Statement ignored
    84/24 PL/SQL: ORA-01031: insufficient privileges
    Errors: check compiler log

###################

The Lamdba Code here is used to invoke SNS notification --> Lamb-func-sns-notification.py

