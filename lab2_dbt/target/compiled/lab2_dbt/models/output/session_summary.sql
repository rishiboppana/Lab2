with __dbt__cte__moving_average as (
select 
date,
symbol,
avg(close) over(partition by symbol order by date rows between 9 preceding and current row) as ma_10
from user_db_lobster1.raw.market_price
),  __dbt__cte__gap_analysis as (
select 
date,
symbol,
open - lag(close) over(partition by symbol order by date) as Gap,
from user_db_lobster1.raw.market_price
),  __dbt__cte__volatility as (
select
date,
symbol,
high - low as volatality
from user_db_lobster1.raw.market_price
),  __dbt__cte__rolling_volatality as (
with deviation as (
select
date,
symbol,
(close/lag(close) over(partition by symbol order by date) - 1) as deviation
from user_db_lobster1.raw.market_price
)
select
date,
symbol,
stddev(deviation) over(partition by symbol order by date  rows between 13 preceding and current row) as rolling_volatality 
from deviation
),  __dbt__cte__rsi as (
with delta_close as(
select
date,
symbol,
close - lag(close) over(partition by symbol order by date) as delta
from user_db_lobster1.raw.market_price
),
gain_and_loss as (
select 
date,
symbol,
case when delta > 0  then delta else 0 end as gain,
case when delta < 0 then abs(delta) else 0 end as lose 
from delta_close
),
rs as (
select 
date,
symbol,
avg(gain) over(partition by symbol order by date rows between 13 preceding and current row) as avg_gain,
avg(lose) over(partition by symbol order by date rows between 13 preceding and current row) as avg_loss
from gain_and_loss
)
select
date,
symbol,
round(100 - 100/(1 + (avg_gain/nullif(avg_loss,0)))) as rsi
from rs
) SELECT ma.date,ma.symbol,ma.ma_10,gap.Gap,v.volatality,rv.rolling_volatality,rsi.rsi
FROM __dbt__cte__moving_average ma
JOIN __dbt__cte__gap_analysis gap on ma.date = gap.date and ma.symbol = gap.symbol
join __dbt__cte__volatility v on v.date = ma.date and v.symbol = ma.symbol
join __dbt__cte__rolling_volatality rv on rv.date = ma.date and rv.symbol = ma.symbol
join __dbt__cte__rsi rsi on rsi.date = ma.date and rsi.symbol = ma.symbol