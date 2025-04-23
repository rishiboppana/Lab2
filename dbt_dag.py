from pendulum import datetime
from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.hooks.base import BaseHook
from airflow.decorators import task
from airflow.providers.snowflake.hooks.snowflake import SnowflakeHook

DBT_PROJECT_DIR = "/opt/airflow/lab2_dbt"
conn = BaseHook.get_connection("snowflake_academia")

def connection() :
    hook = SnowflakeHook(snowflake_conn_id = 'snowflake_academia' )
    con =  hook.get_conn()

    return con.cursor()

@task
def idempotency():
    con = connection()
    con.execute("use database user_db_lobster1")
    con.execute("use schema analytics")
    con.execute("truncate table session_summary")

with DAG(
    "BuildELT_dbt",
    start_date=datetime(2025, 3, 19),
    description="A sample Airflow DAG to invoke dbt runs using a BashOperator",
    schedule=None,
    catchup=False,
    default_args={
        "env" : {
            "DBT_USER": conn.login,
            "DBT_PASSWORD": conn.password,
            "DBT_ACCOUNT": conn.extra_dejson.get("account"),
            "DBT_SCHEMA": conn.schema,
            "DBT_DATABASE": conn.extra_dejson.get("database"),
            "DBT_ROLE": conn.extra_dejson.get("role"),
            "DBT_WAREHOUSE": conn.extra_dejson.get("warehouse"),
            "DBT_TYPE": "snowflake"
    }
    },
) as dag:
    dbt_run = BashOperator(
        task_id="dbt_run",
        bash_command=f"/home/airflow/.local/bin/dbt run --profiles-dir {DBT_PROJECT_DIR} --project-dir {DBT_PROJECT_DIR}",
    )

    dbt_test = BashOperator(
        task_id="dbt_test",
        bash_command=f"/home/airflow/.local/bin/dbt test --profiles-dir {DBT_PROJECT_DIR} --project-dir {DBT_PROJECT_DIR}",
    )

    dbt_snapshot = BashOperator(
        task_id="dbt_snapshot",
        bash_command=f"/home/airflow/.local/bin/dbt snapshot --profiles-dir {DBT_PROJECT_DIR} --project-dir {DBT_PROJECT_DIR}",
    )

    fullrefresh = idempotency()
    fullrefresh>>dbt_run >> dbt_test >> dbt_snapshot
