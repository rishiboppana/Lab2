select 
date,
symbol,
avg(close) over(partition by symbol order by date rows between 9 preceding and current row) as ma_10
from USER_DB_LOBSTER1.raw.market_price