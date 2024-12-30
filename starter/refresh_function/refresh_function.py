#TODO: Add the necessary Cloud SDK imports 
import json
import boto3 
import datetime
import os 

#### Instead of watching a local directory to find a new data file,
#### we will use S3 object upload as the trigger for the lambda function
#### 
#### That will simplify much the code, as the trigger is happening outside the code
#### and function is triggered whenever it happens, without having to write the
#### code the watch new entries.
####
#### Though it is a bit unclear in the original code, how we loop over files in the
#### location and load into into a unified frame, while it looks every run the files
#### are archived, and the trigger and the watching is only for a new file as old process..
#### files are not used in future runs, since they are archived
#### 
#### So the process of uploading new files to S3, has to be through a separate process
#### where a ready to be deployed dataset is being uploaded to S3 location which from
#### its part will trigger this lambda function, and trigger the glue function to train
#### the model from the new data. As uploading multiple files will lead to trigger the 
#### function multiple times and hence triggering the glue ETL job multiple times.


#TODO: Initiate the appopriate Cloud SDK Clients
glue=boto3.client('glue')
s3=boto3.client('s3')

# TODO: modify the function initiate based on the event in the cloud storage account
## Event is S3 object upload trigger

def lambda_handler(event, context):
    bucket=event['Records'][0]['s3']['bucket']['name']
    key=event['Records'][0]['s3']['object']['key']
    filename=os.path.splitext(os.path.basename(key))[0]
    path=f"s3://{bucket}/{key}"
    print(f"A new file {key} has been uploaded to S3 bucket {bucket}")
    print(f"New source is {path}")

    # TODO: modify the function to kick off the AWS Service Job
    response=glue.start_job_run(
        JobName='udacity-glue-abraam',
        Arguments={
            '--SOURCE_PATH': path
        }

    )

    # TODO: modify the function to move the processed file to an archive directory in the cloud storage location
    current_date = datetime.datetime.now().strftime("%Y%m%d")
    archive_key=f"archive/{filename}_retrain_{current_date}.csv"
    copy_source = {'Bucket': bucket, 'Key': key}
    s3.copy_object(CopySource=copy_source, Bucket=bucket, Key=archive_key)
    return {
        'statusCode': 200,
        'body': json.dumps('S3 trigger done. Triggering glue job to retrain model..')
    }
