select 
date,
symbol,
open - lag(close) over(partition by symbol order by date) as Gap,
from {{ source('raw', 'market_price') }}