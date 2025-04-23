select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select close
from user_db_lobster1.raw.market_price
where close is null



      
    ) dbt_internal_test