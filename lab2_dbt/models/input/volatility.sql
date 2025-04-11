select
date,
symbol,
high - low as volatality
from {{source('raw','market_price')}}