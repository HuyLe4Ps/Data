from datetime import datetime, timedelta

from airflow import DAG
from airflow.operators.bash import BashOperator

default_args = {
    'owner': 'airflow',
    'retries': 1,
    'retry_delay': timedelta(seconds=5),
    'email': ['hai.vo@pizza4ps.com'],
    'email_on_failure': True,
    'eamil_on_retry': True
}

with DAG(
    dag_id="dag_email_notification",
    start_date=datetime(2023, 12, 11),
    schedule_interval='@daily',
    default_args=default_args,
    catchup= False
) as dag:
    task1 = BashOperator(
        task_id='simple_failed_bash_task',
        bash_command="cd non_exist_folder"
    )