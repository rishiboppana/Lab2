from airflow import DAG
from airflow.models import Variable
from airflow.decorators import task
import os
from datetime import timedelta
from datetime import datetime
from airflow.providers.snowflake.hooks.snowflake import SnowflakeHook
from airflow.operators.trigger_dagrun import TriggerDagRunOperator
import yfinance as yf



def connection() :
    hook = SnowflakeHook(snowflake_conn_id = 'snowflake_academia' )
    con =  hook.get_conn()

    return con.cursor()

@task
def initialising():
    con = connection()
    con.execute("Create database if not exists user_db_lobster1")
    con.execute("use database user_db_lobster1")
    schema ="raw"
    con.execute(f"""Create schema if not exists {schema}""")
    con.execute("use schema raw ")


    table = "market_price"

    con.execute(f"""CREATE TABLE if not exists {table} (
        date DATE,
        close FLOAT,
        high FLOAT,
        low FLOAT,
        open FLOAT,
        volume FLOAT,
        symbol VARCHAR
    )""")

@task
def extract(tickers) :

    # if os.path.exists("market_price.csv") :
    #     os.remove("market_price.csv")

    i = 0
    list_tickers = tickers.split(",")
    for ticker in list_tickers :
        stock = yf.Ticker(ticker)

        price = stock.history(period="180d")
        try :
            price  = price.drop(columns=['Dividends','Stock Splits'])
        except Exception as e :
            print("Exception Happened")
        price["symbol"] = ticker
        mode = 'w' if i == 0 else 'a'
        header = i == 0 
        price.to_csv("market_price.csv", mode=mode, header=header)
        i+=1

    filepath  = "market_price.csv"
    return filepath


@task
def transfer(filepath):
    print("Starting of transfer")
    con  = connection()
    con.execute("use database user_db_lobster1")
    con.execute("use schema raw")
    try :
        con.execute(f"CREATE OR REPLACE STAGE temp_stage_market")
        snowflake_file_path = f"file://{filepath}"
        con.execute(f"PUT {snowflake_file_path} @temp_stage_market AUTO_COMPRESS = FALSE")  
    except Exception as e :
        print(e)
        raise(e)


@task
def load():


    con = connection()
    con.execute("use database user_db_lobster1")
    con.execute("use schema raw")
    table = "market_price"
    try :
        copy_query = f"""
            COPY INTO {table}  
            FROM @temp_stage_market
            
            FILE_FORMAT = (
                    TYPE = 'CSV'
                    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
                    SKIP_HEADER = 1
            )
            on_error = 'continue'
            """
        
        con.execute("Begin")
        con.execute("truncate table market_price")
        con.execute(copy_query)
        con.execute("commit")
    
    except Exception as e :
        con.execute("rollback")
        print(e)
        raise(e)


with DAG(
    dag_id='Lab2_ETL',  
    start_date=datetime(2024, 3, 1),  
    catchup=False,  
    tags=['ETL'],  
    schedule_interval='0 8 * * *'  
) as dag:
    con = connection() 
    tickers = Variable.get("tickers")
    # i = initialising()
    file = extract(tickers)
    transfer_task = transfer(file)
    load_task = load()

    trigger_dag2 = TriggerDagRunOperator(
    task_id="trigger_lab2_dbt",
    trigger_dag_id="BuildELT_dbt",  
    wait_for_completion=True,  
    poke_interval=60,
    retries=1
)
    
    # trigger_forecast = TriggerDagRunOperator(
    #     task_id = 'Trigger_Task',
    #     trigger_dag_id = 'Forecast'
    # )

    file >>transfer_task >>load_task>>trigger_dag2
    
    
