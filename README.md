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
The PL/SQL Code is to create a SP in RDS Oracle RMAN --> rds-rman-plsql-code.sql

The Lamdba Code here is used to invoke SNS notification --> Lamb-func-sns-notification.py

