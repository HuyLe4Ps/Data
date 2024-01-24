from airflow import DAG
from airflow.providers.postgres.operators.postgres import PostgresOperator
from airflow.operators.email import EmailOperator
from airflow.utils.dates import days_ago
from datetime import datetime,timedelta

# Calculate the next day's date
#next_day = datetime.now() + timedelta(days=1)
#start_date = datetime(next_day.year, next_day.month, next_day.day, 7, 0, 0)  # Set the desired start time (7 AM in this case)

# Define the DAG
dag = DAG(
    'sales_transform',
    default_args={'start_date': datetime(2023, 12, 11)},
    schedule_interval='0 7 * * *',
    catchup= False  # Run at 7 AM daily
)


# Define the PostgresOperator to run SQL script
load_table = PostgresOperator(
    task_id='load_data',
    sql='./sqls/sales_transform.sql',  # Adjust the path to your SQL script
    postgres_conn_id='pos_dwh',  # Adjust to your PostgreSQL connection ID
    autocommit=True,  # Set autocommit to True if your script does not contain transactional commands
    dag=dag
)

# Set task dependencies
load_table 