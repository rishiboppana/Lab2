select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select sessionId
from user_db_lobster.analytics.session_summary
where sessionId is null



      
    ) dbt_internal_test