from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator
import requests
import json
from tabulate import tabulate
import pandas as pd

default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'start_date': datetime(2024, 1, 1),
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}


dag = DAG(
    'my_bipo_dag',
    default_args=default_args,
    description='BIPO API DAG',
    schedule_interval='@daily',  # Adjust as needed
)

def get_access_token(**kwargs):
    url = "https://ap6.bipocloud.com/4PS/oauth2/WebAPI/Token"
    headers = {
        "Content-Type": "application/x-www-form-urlencoded",
        "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6MSwic3RvcmVjb2RlIjoiMDAxMDA4IiwiaWF0IjoxNjU2OTA0NjcxfQ.AIG_BJA1q989NwrAKGCMy2_jwg0PqlUV96ojcbk-5ao",
        "Cookie": "ASP.NET_SessionId=pn0assbkozonac1t2o14oih5"
    }
    data = {
        "UserName": "4PSAPI",
        "Password": "4ps@1212",
        "grant_type": "password",
        "client_id": "D01241AD-BAAC-4B9C-8052-CC019C6864AB",
        "client_secret": "30F741A6-DBAD-422A-8092-280BCED58349"
    }

    response = requests.post(url, headers=headers, data=data)
    response_data = response.json()
    access_token = response_data['access_token']
    return access_token

def call_api_and_process(**kwargs):
    access_token = kwargs['ti'].xcom_pull(task_ids='get_access_token')

    api_url = "https://ap6.bipocloud.com/4PS/api2/BIPOExport/GetListItem"
    headers = {
        "Authorization": f"Bearer {access_token}",
        "Content-Type": "application/json"
    }
    body = {
        "InterfaceCode": "BIPO-EMP-EM"
    }

    response = requests.post(api_url, headers=headers, json=body)
    if response.status_code == 200:
        response_data = response.json()
        return response_data
    else:
        print("Request failed with status code:", response.status_code)

def transform_response(**kwargs):
    response_data = kwargs['ti'].xcom_pull(task_ids='call_api_and_process')

    # Your provided transformation code
    split_names = []
    for item in response_data:
        if item['AltLangName'] is not None:
            name_parts = item['AltLangName'].split(' ')
            if len(name_parts) >= 2:
                item['LastName'] = name_parts[0]
                item['FirstName'] = name_parts[-1]
            elif len(name_parts) == 1:
                item['LastName'] = name_parts[0]
                item['FirstName'] = ''
            else:
                item['LastName'] = ''
                item['FirstName'] = ''
        else:
            item['LastName'] = ''
            item['FirstName'] = ''
        split_names.append(item)

    df = pd.DataFrame(split_names)

    current_date = pd.to_datetime('now')
    df['DateResign'] = pd.to_datetime(df['DateResign'])
    df['Active'] = df['DateResign'].apply(lambda x: 'No' if x <= current_date else 'Yes')

    selected_columns = df[['EmployeeCode', 'AltLangName', 'FirstName', 'LastName', 'CreateOn', 'UpdateOn', 'AddressLine1',
                           'Age', 'BirthDate', 'BirthPlace', 'DateJoin', 'DateResign', 'DepartmentCode', 'DesignationCode',
                           'Email', 'NationalityCode', 'TelephoneNo', 'Gender', 'OFR10', 'Active']]
    print(selected_columns)

# Tasks
get_token_task = PythonOperator(
    task_id='get_access_token',
    python_callable=get_access_token,
    provide_context=True,
    dag=dag,
)

call_api_task = PythonOperator(
    task_id='call_api_and_process',
    python_callable=call_api_and_process,
    provide_context=True,
    dag=dag,
)

transform_task = PythonOperator(
    task_id='transform_response',
    python_callable=transform_response,
    provide_context=True,
    dag=dag,
)

# Set up task dependencies
get_token_task >> call_api_task >> transform_task

# Set up your Airflow environment by placing this file in your DAGs folder and starting the Airflow scheduler.
