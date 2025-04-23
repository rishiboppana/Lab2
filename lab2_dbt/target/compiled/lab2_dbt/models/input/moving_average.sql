select 
date,
symbol,
avg(close) over(partition by symbol order by date rows between 9 preceding and current row) as ma_10
from user_db_lobster1.raw.market_price