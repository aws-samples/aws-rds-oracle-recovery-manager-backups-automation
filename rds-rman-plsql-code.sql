/* grants needed for admin user -- can be given specific grants at object level aswell */

grant create any procedure to admin;
grant select any dictionary to admin;

/* Procedure creation continued - if the compilation fails especially on Oracle SE try removing the '/' from last line and re-compile */

/* Import Note: The Procedure will run in loop if any other non relevant files are in the backups S3 bucket. Recommended to use Only a dedicated s3 bucket */

/* Execute instructions post creation of below procedure - execute by passing the bucket name in single quotes --> exec rman_s3 ('<bucket_name>'); */


CREATE OR REPLACE PROCEDURE rman_s3(rman_bucket in varchar2) as
n_rec_cnt    PLS_INTEGER :=0;
p_backup_cur_status    VARCHAR2(30);
v_task_id VARCHAR2(30);

sql_stmt_1 VARCHAR2(200);
sql_stmt_2 VARCHAR2(300);
sql_stmt_3 VARCHAR2(300);
sql_strg_1 varchar2(30);
sql_strg_2 varchar2(30);
v_par  number(1);
v_cnt_num NUMBER(4):=0;
v_task_status VARCHAR2(30);
v_bkp_files_tot NUMBER;
v_task_rman_bkp varchar2(30);
status_bucket varchar2(200):=rman_bucket||'/Status';
v_mtime number(1);

ltype utl_file.file_type;
ldir  varchar2(100) := 'BKP_DIR_STS';
lfile  varchar2(100) := 'job_status.txt';

/* To run the Rman backup procedure on RDS Instance, create following directories 

exec rdsadmin.rdsadmin_util.create_directory(p_directory_name => 'BKP_DIR_STS');

If archived log retention is not enabled, enable it

exec  rdsadmin.rdsadmin_util.set_configuration( name  => 'archivelog retention hours', value => '48');

*/

BEGIN 
dbms_output.put_line(status_bucket );
		/* Checking for old rman backup on directory and cleaning */
		
		select count(1) into v_mtime from (
				 SELECT case when trunc(sysdate) > mtime then 1 else 2 end   from
				 table(RDSADMIN.RDS_FILE_UTIL.LISTDIR('DATA_PUMP_DIR')) where type='file'
				 union all
				  select 1 from dual) x
				 where rownum = 1;
		

		IF v_mtime = 1
		then
			for i in (select filename from 
			table(RDSADMIN.RDS_FILE_UTIL.LISTDIR('DATA_PUMP_DIR')) where type='file' and filename like '%')
			loop
				UTL_FILE.FREMOVE ('DATA_PUMP_DIR', i.filename);
			end loop;
		
		/* Checking for Enterprise or Standard Edition Oracle */
		
		SELECT decode(substr(banner,21,4),'Ente',4,1) into v_par
		FROM v$version 
		WHERE banner like 'Oracle%';
	
		/*	Running RMAN Backup */	
		rdsadmin.rdsadmin_rman_util.backup_database_full(
        p_owner               => 'SYS', 
        p_directory_name      => 'DATA_PUMP_DIR',
        p_parallel            => v_par,  
        p_section_size_mb     => 100,
        p_rman_to_dbms_output => FALSE); 
		
		END IF;
        
		/* Checking the User Status Table */
       SELECT status INTO p_backup_cur_status FROM 
		(SELECT status
			FROM v$rman_backup_job_details
			WHERE start_time > = sysdate-1
			ORDER BY end_time)
            WHERE ROWNUM  = 1;

        /* Record found in user maintained table, Checking the System Table */
        IF p_backup_cur_status IN ('COMPLETED')
        THEN

            SELECT COUNT(1) INTO n_rec_cnt
            FROM v$rman_backup_job_details
            WHERE start_time > = sysdate-1;

			/* Getting total number Rman Backup piece created on dump directory */
			
			SELECT COUNT(1) into v_bkp_files_Tot
			FROM table(rdsadmin.rds_file_util.listdir('DATA_PUMP_DIR')) 
			WHERE filename like 'BACKUP%';

            IF n_rec_cnt = 0
            THEN
            /* When Count for Completed is 0 wihtin last 24 hours then exception is raised */

                RAISE_APPLICATION_ERROR(-20003,'RMAN procedure, Err Point : FAILED' || SQLERRM);

            ELSIF (n_rec_cnt != 0 AND p_backup_cur_status='COMPLETED')
            THEN 
			
			/* Dynamic Queries Sql stataments Uploading Files to S3 */
			sql_stmt_1:='SELECT rdsadmin.rdsadmin_s3_tasks.upload_to_s3(p_bucket_name'||'=>'''||rman_bucket||''',p_prefix =>'||''''''||',p_s3_prefix =>'||''''''||',p_directory_name=>'||'''DATA_PUMP_DIR'''||') AS TASK_ID FROM DUAL';
		
			dbms_output.put_line(sql_stmt_1);

			/* Upload S3 */
			EXECUTE IMMEDIATE sql_stmt_1 INTO v_task_id;
dbms_output.put_line(v_task_id);
			/* Getting count on log files in BDUMP directory */
			sql_stmt_2 := 'SELECT count(1)  FROM table(rdsadmin.rds_file_util.read_text_file('||'''BDUMP'''||','||'''dbtask-'||v_task_id||'.'||'log'''||'))';
		
dbms_output.put_line(v_bkp_files_Tot);

			WHILE  ( V_CNT_NUM < (((v_bkp_files_tot)*2 +1 ) ))
				LOOP
					dbms_lock.sleep(1);
				dbms_output.put_line(V_CNT_NUM);
				/* to check number of files uploading in progress */
				EXECUTE IMMEDIATE sql_stmt_2 INTO V_CNT_NUM;
   
				END LOOP; 

				/* Generating a success files status replace with utl_mail
				 EXECUTE UTL_MAIL.SEND(SENDER=>'hxxxxxx',RECIPIENTS=>'yyyyyyyyy', MESSAGE=>'File loaded to s3 success''); */
				
				ltype := utl_file.fopen(ldir,lfile,'w');
				utl_file.putf(ltype,'File loaded to s3 success');
				utl_file.fclose(ltype);
				
				/* Uploading status file to status Bucket */
				sql_stmt_3 := 'SELECT rdsadmin.rdsadmin_s3_tasks.upload_to_s3(p_bucket_name'||'=>'''||status_bucket||''',p_prefix =>'||'''job_status.txt'''||',p_s3_prefix =>'||''''''||',p_directory_name=>'||'''BKP_DIR_STS'''||') AS TASK_ID FROM DUAL';

				/* uploading status file */
		EXECUTE IMMEDIATE sql_stmt_3 into v_task_status; 
 dbms_output.put_line('TEST BREAk');

            END IF;

        END IF;
	EXCEPTION
			WHEN OTHERS THEN
			
			/* Generating a failed status */
				UTL_FILE.FREMOVE ('BKP_DIR_STS',lfile  );
				ltype := utl_file.fopen(ldir,lfile,'w');
				utl_file.putf(ltype,'Rman Backup failed');
				utl_file.fclose(ltype);
				
				/* Uploading status file to status Bucket */
				sql_stmt_3 := 'SELECT rdsadmin.rdsadmin_s3_tasks.upload_to_s3(p_bucket_name'||'=>'''||status_bucket||''',p_prefix =>'||'''job_status.txt'''||',p_s3_prefix =>'||''''''||',p_directory_name=>'||'''BKP_DIR_STS'''||') AS TASK_ID FROM DUAL';

				
				/* uploading status file */
				EXECUTE IMMEDIATE sql_stmt_3 into v_task_status;
				
				RAISE_APPLICATION_ERROR(-20003,' procedure, Err Point : FAILED' || SQLERRM);
				
		
END;
/
