select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select channel
from user_db_lobster.analytics.session_summary
where channel is null



      
    ) dbt_internal_test