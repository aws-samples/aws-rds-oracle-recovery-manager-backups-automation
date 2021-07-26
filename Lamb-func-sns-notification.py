### this Python code used in Lambda function 
### Get the SNS ARN details needed in below information

import boto3

s3 = boto3.client('s3')
sns = boto3.client('sns')
def lambda_handler(event, context):
    
    bucket = s3.get_object(Bucket='test-bucket-8343',Key='s3-file.txt') 
      
    lines = bucket['Body'].read().decode('utf-8')
    print('file status -->',lines)
    if 'success' in lines :
        # Publish a simple message to the specified SNS topic
	  # enter the SNS topic ARN below
        response = sns.publish(
                TopicArn='<topic ARN >',    
                Message='Rman backup completed and uploaded to S3',    
                )
    elif 'failed' in lines :
        response = sns.publish(
		   # enter the SNS topic ARN below
                TopicArn='<topic ARN >',    
                Message='Rman backup failed to uploaded S3',    
                )
