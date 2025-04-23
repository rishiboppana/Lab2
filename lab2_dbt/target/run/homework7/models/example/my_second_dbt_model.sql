
  create or replace   view user_db_lobster.analytics.my_second_dbt_model
  
   as (
    -- Use the `ref` function to select from other models

select *
from user_db_lobster.analytics.my_first_dbt_model
where id = 1
  );

