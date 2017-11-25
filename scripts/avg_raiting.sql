-- Для каждого пользователя средний рейтинг отзывов
SELECT
  min(avitouser.email) as name,
  avg(feedback.score)
FROM avitouser
  JOIN feedback ON avitouser.id = feedback.reviewee_id
GROUP BY avitouser.id;