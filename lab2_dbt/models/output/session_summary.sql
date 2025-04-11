SELECT ma.date,ma.symbol,ma.ma_10,gap.Gap,v.volatality,rv.rolling_volatality,rsi.rsi
FROM {{ ref("moving_average") }} ma
JOIN {{ ref("gap_analysis") }} gap on ma.date = gap.date and ma.symbol = gap.symbol
join {{ ref("volatility") }} v on v.date = ma.date and v.symbol = ma.symbol
join {{ ref("rolling_volatality")}} rv on rv.date = ma.date and rv.symbol = ma.symbol
join {{ ref("rsi")}} rsi on rsi.date = ma.date and rsi.symbol = ma.symbol