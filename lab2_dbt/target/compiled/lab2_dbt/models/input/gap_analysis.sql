select 
date,
symbol,
open - lag(close) over(partition by symbol order by date) as Gap,
from user_db_lobster1.raw.market_price