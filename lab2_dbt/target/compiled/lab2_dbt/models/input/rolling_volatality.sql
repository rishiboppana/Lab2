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