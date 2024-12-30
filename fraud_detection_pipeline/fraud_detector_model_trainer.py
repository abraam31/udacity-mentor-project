import sys
import os
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame
from pyspark.sql.functions import col, hour, when
from pyspark.sql import SparkSession

from pyspark.ml.feature import VectorAssembler, StandardScaler, Bucketizer, StringIndexer
from pyspark.ml.classification import RandomForestClassifier
from pyspark.ml import Pipeline
from pyspark.sql.types import DoubleType

## @params: [JOB_NAME]
args = getResolvedOptions(sys.argv, ['JOB_NAME', 'SOURCE_PATH'])

sc = SparkContext()
glueContext = GlueContext(sc)
logger = glueContext.get_logger()
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

def MyTransform(dynamic_frame):
    try: 
        # TODO: Convert DynamicFrameCollection to DataFrame for Glue
        logger.info("Started Transform Job..")
        df = dynamic_frame.toDF()
        print(df.show())
        # Convert all columns except 'Class' to DoubleType
        numeric_columns = [col for col in df.columns if col != 'Class']
        for column in numeric_columns:
            df = df.withColumn(column, col(column).cast(DoubleType()))
        print(df.show())
        # Normalize numeric features
        assembler = VectorAssembler(inputCols=numeric_columns, outputCol="numericFeatures")
        scaler = StandardScaler(inputCol="numericFeatures", outputCol="scaledFeatures", withStd=True, withMean=True)
        logger.info("Done normalizing numeric features.")
        
        # Combine scaled numeric features
        finalAssembler = VectorAssembler(inputCols=["scaledFeatures"], outputCol="features")
        
        # Handle class imbalance by adjusting class weights
        class_counts = df.groupBy("Class").count().collect()
        total_count = sum([row['count'] for row in class_counts])
        weight_dict = {row['Class']: total_count / row['count'] for row in class_counts}
        print(weight_dict)
        # Add class weights to the DataFrame
        df = df.withColumn("weight", when(col("Class") == 0, weight_dict['0']).otherwise(weight_dict['1']))
        # Convert Class to numeric and create class weights
        indexer = StringIndexer(inputCol="Class", outputCol="label")
        # Define the RandomForestClassifier with class weights
        rf = RandomForestClassifier(labelCol="label", featuresCol="features", numTrees=100, 
                                    maxDepth=10, weightCol="weight")

        # Create a pipeline
        pipeline = Pipeline(stages=[assembler, scaler, finalAssembler, indexer, rf])
        # Fit the model
        model = pipeline.fit(df)
        model_path = 's3://uda-abraam-model/model'
        model.write().overwrite().save(model_path)
        logger.info("Model trained and saved to S3")
        
        # TODO: Convert DataFrame back to DynamicFrame and return DynamicFrameCollection for Glue
        transformed_dynamic_frame = DynamicFrame.fromDF(df, glueContext, "transformed_dynamic_frame")
        return transformed_dynamic_frame  # TODO: Modify return value for Glue
        
    except Exception as e:
        logger.warn(e)

# Load your data from S3
source_path = args.get('SOURCE_PATH', 's3://uda-abraam-data/dataset/creditcard.csv')
dynamic_frame = glueContext.create_dynamic_frame.from_options( connection_type="s3", connection_options={"paths": [source_path]}, format="csv", format_options={"withHeader": True} ) 
# Run the transformation 
transformed_dynamic_frame = MyTransform(dynamic_frame)
logger.info("Pipeline finished. Exiting..")
job.commit()