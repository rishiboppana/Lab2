with delta_close as(
select
date,
symbol,
close - lag(close) over(partition by symbol order by date) as delta
from USER_DB_LOBSTER1.raw.market_price
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