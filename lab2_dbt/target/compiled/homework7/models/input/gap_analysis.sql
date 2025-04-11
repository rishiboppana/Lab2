select 
date,
symbol,
open - lag(close) over(partition by symbol order by date) as Gap,
from USER_DB_LOBSTER1.raw.market_price