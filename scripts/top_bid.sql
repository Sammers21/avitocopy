SELECT
  max(amount),
  user_id
FROM bid
WHERE auction_id = 3
GROUP BY user_id
ORDER BY max(amount) DESC
LIMIT 1;