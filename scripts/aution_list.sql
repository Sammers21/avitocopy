-- Получить аукцины с самыми высокими ставками 
SELECT
  min(desription)                     AS description,
  max(amount) || ' ' || min(currency) AS price
FROM auction
  JOIN bid ON auction.id = bid.auction_id
GROUP BY auction_id;
