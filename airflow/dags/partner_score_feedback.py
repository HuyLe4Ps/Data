from airflow import DAG
from airflow.utils.dates import days_ago
from airflow.providers.postgres.operators.postgres import PostgresOperator
from datetime import datetime

# Define the DAG
dag = DAG(
    'partner_score_feedback',
    default_args={'start_date': days_ago(1)},
    schedule_interval='0 21 * * *',
    catchup=False
)

# Define the PostgresOperator to run SQL script
load_table = PostgresOperator(
    task_id='load_partner_score_feedback',
    sql='./sqls/partner_feedback_score.sql',  # Adjust the path to your SQL script
    postgres_conn_id='feedback_db',  # Adjust to your PostgreSQL connection ID
    autocommit=True,  # Set autocommit to True if your script does not contain transactional commands
    dag=dag
)


# Set up the task dependencies
load_table 





