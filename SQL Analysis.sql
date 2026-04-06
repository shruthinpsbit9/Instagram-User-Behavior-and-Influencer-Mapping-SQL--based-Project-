USE ig_clone;

SELECT * 
FROM user_activity;

SELECT MIN(total_comments) AS min, MAX(total_comments) AS max
FROM user_activity;

SELECT user_id, total_posts, total_liked, total_comments,
(total_posts + total_liked + total_comments) AS user_activity_score,
CASE
 WHEN (total_posts + total_liked + total_comments) > 50 THEN "High"
 WHEN (total_posts + total_liked + total_comments) < 20 THEN "Low"
 ELSE "Medium" 
END AS user_activity_level 
FROM user_activity 
ORDER BY user_activity_score DESC;

SELECT COUNT(user_id) AS count_of_user_id 
FROM user_activity; 

WITH everything AS (
     SELECT p.id AS photo_id, COUNT(pt.tag_id) AS tags_per_posts
     FROM photos p 
     LEFT JOIN photo_tags pt ON p.id = pt.photo_id 
     GROUP BY p.id 
)
SELECT AVG(tags_per_posts) AS avg_tags_per_posts
FROM everything; 


SELECT user_id, total_comments, total_liked, 
RANK() OVER(ORDER BY total_comments DESC, total_liked DESC) AS rnk 
FROM user_activity; 


	 SELECT followee_id AS user_id, COUNT(follower_id) AS total_followers 
     FROM follows 
     GROUP BY followee_id 
     ORDER BY total_followers DESC 
     LIMIT 10; 

 SELECT user_id, total_liked 
 FROM user_activity 
 WHERE total_liked = 0;
 
WITH everything AS (
                     SELECT p.user_id, COUNT(p.id) AS photo_id, 
                     DATE(p.created_dat) AS date, 
                     FROM photos p 
                     ORDER BY user_id
                     )
SELECT *
FROM everything;                    
                                 
WITH everything AS (
                    SELECT p.user_id, t.tag_name, COUNT(pt.tag_id) AS frequency_of_tag,
					RANK() OVER(PARTITION BY user_id ORDER BY COUNT(*) DESC) AS rnk
                    FROM photos p
                    JOIN photo_tags pt ON p.id = pt.photo_id
                    JOIN tags t ON pt.tag_id = t.id
                    GROUP BY p.user_id, t.tag_name
)
SELECT user_id, tag_name, frequency_of_tag
FROM everything 
WHERE rnk =1;                    
					
SELECT user_id, total_posts, total_liked, total_comments,
(total_posts + total_liked + total_comments) AS user_activity_score,
RANK() OVER(ORDER BY (total_posts + total_liked + total_comments) DESC) AS rnk
FROM user_activity;
					
SELECT pt.tag_id, COUNT(c.id) AS frequency_of_comments, COUNT(l.user_id) AS frequency_of_likes,
(COUNT(c.id) + COUNT(l.user_id)) AS engagement_score
FROM photo_tags pt
LEFT JOIN comments c ON pt.photo_id = c.photo_id 
LEFT JOIN likes l ON c.photo_id = l.photo_id
GROUP BY pt.tag_id
ORDER BY engagement_score DESC;                     
 
WITH everything AS (
				   SELECT u.id AS user_id, u.username, COUNT( DISTINCT l.user_id) AS total_likes, 
                   COUNT(DISTINCT c.id) AS total_comments, COUNT(DISTINCT pt.photo_id) AS total_posts, 
                   COUNT(DISTINCT pt.tag_id) AS total_phototags
                   FROM users u 
                   LEFT JOIN likes l ON u.id = l.user_id 
                   LEFT JOIN comments c ON u.id = c.user_id 
                   LEFT JOIN photo_tags pt ON pt.photo_id = c.photo_id 
                   GROUP BY u.id, u.username 
                   )
SELECT username, total_likes, total_comments, total_phototags
FROM everything
ORDER BY total_likes DESC, total_comments DESC, total_phototags DESC;     

WITH likes_per_photo AS (
                         SELECT photo_id, COUNT(user_id) AS like_count
                         FROM likes 
                         GROUP BY photo_id
), 
tag_avg_likes AS (
				  SELECT pt.tag_id, t.tag_name, AVG(lp.like_count) AS avg_likes 
                  FROM photo_tags pt
                  LEFT JOIN likes_per_photo lp ON pt.photo_id = lp.photo_id 
                  LEFT JOIN tags t ON pt.tag_id = t.id 
                  GROUP BY pt.tag_id, t.tag_name
)
SELECT tag_id, tag_name, avg_likes 
FROM tag_avg_likes
ORDER BY avg_likes DESC;                
			
USE ig_clone;       
WITH likes_per_photo AS ( 
                         SELECT pt.photo_id, COUNT(l.user_id) AS total_likes 
                         FROM photo_tags pt 
                         LEFT JOIN likes l ON pt.photo_id = l.photo_id 
                         GROUP BY photo_id 
                         ORDER BY total_likes DESC
                         ),
highest_avg_likes AS (
                      SELECT photo_id, ROUND(AVG(total_likes),2) AS avg_likes
                      FROM likes_per_photo
                      GROUP BY photo_id 
                      ORDER BY avg_likes DESC
), 
tagss AS (                       
         SELECT ha.photo_id, ha.avg_likes, pt.tag_id 
		 FROM highest_avg_likes ha
         LEFT JOIN photo_tags pt ON ha.photo_id = pt.photo_id
         )
SELECT ts.photo_id, ts.avg_likes, t.tag_name AS Hashtags 
FROM tagss ts 
LEFT JOIN tags t ON ts.tag_id = t.id;         
                                       
SELECT f1.follower_id AS user_A, f1.followee_id AS user_B, f1.created_at AS A_followed_B_on,
f2.created_at AS B_followed_A_back_on
FROM follows f1
JOIN follows f2
    ON f1.followee_id = f2.follower_id
   AND f1.follower_id = f2.followee_id
   AND f2.created_at >= f1.created_at
ORDER BY f2.created_at;              

SELECT u.username, ua.total_posts, ua.total_liked, ua.total_comments,
(ua.total_posts + ua.total_liked + ua.total_comments) AS user_activity_score,
ROW_NUMBER() OVER (ORDER BY (total_posts + total_liked + total_comments) DESC) AS rnk
FROM user_activity ua 
JOIN users u ON ua.user_id = u.id;

WITH past_active AS (
    SELECT DISTINCT user_id
    FROM user_activity
    WHERE activity_date BETWEEN DATE_SUB(CURDATE(), INTERVAL 60 DAY)
                            AND DATE_SUB(CURDATE(), INTERVAL 30 DAY)
)
SELECT * 
FROM past_active; 

USE ig_clone;
SELECT username, COUNT(total_posts) AS frequency_of_posts 
FROM user_activity_ranked 
WHERE total_liked = 0 
AND total_comments =0
GROUP BY username;

WITH everything AS (
                    SELECT ua.user_id, ua.username, p.id AS photo_id, pt.tag_id, t.tag_name
					FROM user_activity_ranked ua
                    LEFT JOIN photos p ON ua.user_id = p.user_id
                    LEFT JOIN photo_tags pt ON p.id = pt.photo_id
                    LEFT JOIN tags t ON pt.tag_id = t.id
                    WHERE total_comments=0
                    AND total_liked=0
                    )
SELECT username, tag_name
FROM everything;                    

WITH everything AS (
                    SELECT pt.tag_id, COUNT(c.id) AS frequency_of_comments, 
                    COUNT(l.user_id) AS frequency_of_likes,
                    (COUNT(c.id) + COUNT(l.user_id)) AS engagement_score
					FROM photo_tags pt
					LEFT JOIN comments c ON pt.photo_id = c.photo_id 
                    LEFT JOIN likes l ON c.photo_id = l.photo_id
                    GROUP BY pt.tag_id
					ORDER BY engagement_score DESC
                    LIMIT 10
                    )
SELECT t.tag_name, e.frequency_of_comments, e.frequency_of_likes, e.engagement_score
FROM everything e 
JOIN tags t ON e.tag_id = t.id;                    

USE ig_clone; 
CREATE TABLE followers_list AS 
SELECT f1.follower_id AS user_A, f1.followee_id AS user_B, f1.created_at AS A_followed_B_on,
f2.created_at AS B_followed_A_back_on
FROM follows f1
JOIN follows f2
    ON f1.followee_id = f2.follower_id
   AND f1.follower_id = f2.followee_id
   AND f2.created_at >= f1.created_at
ORDER BY f2.created_at;

SELECT user_A AS user_id, COUNT(user_B) AS number_of_followers 
FROM followers_list 
GROUP BY user_id 
ORDER BY number_of_followers DESC; 

CREATE TABLE followers_list AS 
SELECT f.followee_id AS user_id, u.username, COUNT(f.follower_id) AS total_followers
FROM follows f
JOIN users u ON f.followee_id = u.id 
GROUP BY user_id, username
ORDER BY total_followers DESC;

DROP TABLE followers_list; 

CREATE TABLE engagement_rate AS 
SELECT u.username, ua.total_posts, ua.total_liked, ua.total_comments, 
(ua.total_posts + ua.total_liked +   ua.total_comments) AS engagement_rate,
ROW_NUMBER() OVER (ORDER BY (total_posts + total_liked + total_comments) DESC) AS user_rank
FROM user_activity ua 
JOIN users u ON ua.user_id = u.id;

USE ig_clone; 
SELECT f.username, f.total_followers, e.engagement_rate,
CASE 
	WHEN f.total_followers >= 75 AND e.engagement_rate >= 70 THEN 'Top Influencer'
	WHEN f.total_followers >= 75 AND e.engagement_rate < 20 THEN 'Awareness Influencer'
	WHEN f.total_followers < 75 AND e.engagement_rate >= 60 THEN 'Micro Influencer'
	ELSE 'General User'
	END AS influencer_category
FROM followers_list f
JOIN engagement_rate e 
    ON f.username = e.username
ORDER BY engagement_rate DESC;

CREATE TABLE engagement_timeline AS                       
SELECT EXTRACT(HOUR FROM activity_time) AS hour_of_day, COUNT(*) AS total_engagement
FROM (
    SELECT created_at AS activity_time FROM comments
    UNION ALL
    SELECT created_at AS activity_time FROM likes
) AS engagement
GROUP BY hour_of_day
ORDER BY total_engagement DESC; 

CREATE TABLE influencer_segement AS
SELECT f.user_id, f.username, f.total_followers, u.total_posts, u.total_liked, u.total_comments, 
COALESCE(u.total_posts + u.total_liked + u.total_comments/NULLIF (f.total_followers, 0),0) AS engagement_score, 
CASE 
  WHEN COALESCE(u.total_posts + u.total_liked + u.total_comments/NULLIF (f.total_followers, 0),0) >= 10 THEN 'Top-Influencer'
  WHEN COALESCE(u.total_posts + u.total_liked + u.total_comments/NULLIF (f.total_followers, 0),0) >= 7 THEN 'Strong-Influencer'
  WHEN COALESCE(u.total_posts + u.total_liked + u.total_comments/NULLIF (f.total_followers, 0),0) >= 4 THEN 'Growing-Influencer'
  WHEN COALESCE(u.total_posts + u.total_liked + u.total_comments/NULLIF (f.total_followers, 0),0) >= 2.5 THEN 'Emerging-Influencer'
  ELSE 'Low-Engagement User'
  END AS user_segment
FROM followers_list f 
JOIN user_activity_ranked u ON f.user_id = u.user_id 
ORDER BY engagement_score DESC;

SELECT user_segment, ROUND(AVG(engagement_score),2) AS average_engagement_score
FROM influencer_segement
GROUP BY user_segment;

SHOW DATABASES; 

USE ig_clone;
WITH ranges AS (
    SELECT '0-10' AS range_label, 0 AS min_val, 10 AS max_val UNION ALL
    SELECT '11-20', 11, 20 UNION ALL
    SELECT '21-30', 21, 30 UNION ALL
    SELECT '31-40', 31, 40 UNION ALL
    SELECT '41-50', 41, 50 UNION ALL
    SELECT '51-60', 51, 60 UNION ALL
    SELECT '61-70', 61, 70 UNION ALL
    SELECT '71-80', 71, 80 UNION ALL
    SELECT '81-90', 81, 90
)
SELECT 
    r.range_label AS engagement_score_range,
    COALESCE(COUNT(e.username), 0) AS profile_volume
FROM ranges r
LEFT JOIN engagement_rangee e
    ON e.engagement_rate BETWEEN r.min_val AND r.max_val
GROUP BY r.range_label, r.min_val
ORDER BY r.min_val;    

SELECT * 
FROM engagement_rangee; 

CREATE TABLE tag_effectiveness AS
WITH everything AS (
SELECT pt.tag_id, COUNT(c.id) AS frequency_of_comments, COUNT(l.user_id) AS frequency_of_likes,
(COUNT(c.id) + COUNT(l.user_id)) AS engagement_score
FROM photo_tags pt
LEFT JOIN comments c ON pt.photo_id = c.photo_id 
LEFT JOIN likes l ON c.photo_id = l.photo_id
GROUP BY pt.tag_id
ORDER BY engagement_score DESC
)
SELECT t.tag_name, e.frequency_of_comments, e.frequency_of_likes, e.engagement_score
FROM everything e 
JOIN tags t ON e.tag_id = t.id;

USE ig_clone;
WITH everything AS (
SELECT p.id AS photo_id, COUNT(pt.tag_id) AS tags_per_posts
FROM photos p 
LEFT JOIN photo_tags pt ON p.id = pt.photo_id 
GROUP BY p.id 
)
SELECT AVG (tags_per_posts) AS avg_tags_per_posts
FROM everything;

SELECT followee_id AS user_id, COUNT(follower_id) AS total_followers 
FROM follows 
GROUP BY followee_id 
ORDER BY total_followers DESC 
LIMIT 10;

SELECT pt.tag_id, COUNT(c.id) AS frequency_of_comments, COUNT(l.user_id) AS frequency_of_likes,
(COUNT(c.id) + COUNT(l.user_id)) AS effectiveness_score
FROM photo_tags pt
LEFT JOIN comments c ON pt.photo_id = c.photo_id 
LEFT JOIN likes l ON c.photo_id = l.photo_id
GROUP BY pt.tag_id
ORDER BY engagement_score DESC;

   USE ig_clone;
    WITH everything AS (
     SELECT p.user_id, p.id AS photo_id, p.created_dat AS photo_created_at, 
     l.created_at AS like_created_at, c.id AS comment_id 
     FROM photos p 
     LEFT JOIN likes l ON p.user_id = l.user_id 
     LEFT JOIN comments c ON l.user_id = c.user_id 
     )
     SELECT user_id, COUNT(DISTINCT photo_id) AS total_posts, COUNT(DISTINCT like_created_at) 
     AS total_liked, COUNT(DISTINCT comment_id) AS total_comments
     FROM everything 
     GROUP BY user_id
     ORDER BY total_posts DESC;

SELECT user_id, total_posts, total_liked, total_comments,
(total_posts + total_liked + total_comments) AS user_activity_score,
CASE
 WHEN (total_posts + total_liked + total_comments) > 50 THEN "High"
 WHEN (total_posts + total_liked + total_comments) < 20 THEN "Low"
 ELSE "Medium" 
END AS user_activity_level 
FROM user_activity 
ORDER BY user_activity_score DESC;

SELECT followee_id AS user_id, COUNT(follower_id) AS total_followers 
FROM follows 
GROUP BY followee_id 
ORDER BY total_followers DESC 
LIMIT 10;

WITH post_engagement AS (
    SELECT p.user_id, p.id AS photo_id,
           COUNT(DISTINCT l.user_id) AS likes_per_post,
           COUNT(DISTINCT c.id) AS comments_per_post
    FROM photos p
    LEFT JOIN likes l ON p.id = l.photo_id
    LEFT JOIN comments c ON p.id = c.photo_id
    GROUP BY p.id, p.user_id
),
user_engagement AS (
    SELECT user_id,
           SUM(likes_per_post) AS total_likes,
           SUM(comments_per_post) AS total_comments,
           COUNT(photo_id) AS total_posts
    FROM post_engagement
    GROUP BY user_id
)
SELECT user_id, total_posts, total_likes, total_comments,
       ROUND((total_likes + total_comments) * 1.0 / total_posts, 2) AS avg_engagement_per_post
FROM user_engagement
ORDER BY avg_engagement_per_post DESC;
WITH post_engagement AS (
    SELECT p.user_id, p.id AS photo_id,
           COUNT(DISTINCT l.user_id) AS likes_per_post,
           COUNT(DISTINCT c.id) AS comments_per_post
    FROM photos p
    LEFT JOIN likes l ON p.id = l.photo_id
    LEFT JOIN comments c ON p.id = c.photo_id
    GROUP BY p.id, p.user_id
),
user_engagement AS (
    SELECT user_id,
           SUM(likes_per_post) AS total_likes,
           SUM(comments_per_post) AS total_comments,
           COUNT(photo_id) AS total_posts
    FROM post_engagement
    GROUP BY user_id
)
SELECT user_id, total_posts, total_likes, total_comments,
       ROUND((total_likes + total_comments) * 1.0 / total_posts, 2) AS avg_engagement_per_post
FROM user_engagement
ORDER BY avg_engagement_per_post DESC;
  
  SELECT user_id, total_liked 
 FROM user_activity 
 WHERE total_liked = 0;

        WITH everything AS (
                                                      SELECT p.user_id, t.tag_name, COUNT(pt.tag_id) AS frequency_of_tag,
                                                                        RANK() OVER(PARTITION BY user_id ORDER BY COUNT(*) DESC) AS rnk
                                                      FROM photos p
                                                      JOIN photo_tags pt ON p.id = pt.photo_id
                                                      JOIN tags t ON pt.tag_id = t.id
                                                     GROUP BY p.user_id, t.tag_name
           )
          SELECT user_id, tag_name, frequency_of_tag
          FROM everything 
          WHERE rnk =1;  
WITH everything AS (
                     SELECT p.user_id, p.id AS photo_id, DATE(p.created_dat) AS date,
                     pt.tag_id, t.tag_name
                     FROM photos p 
                     LEFT JOIN photo_tags pt ON p.id = pt.photo_id 
                     LEFT JOIN tags t ON pt.tag_id = t.id
                     ORDER BY user_id
                     )
SELECT tag_name, COUNT(tag_id) AS number_of_tags
FROM everything
GROUP BY tag_name
ORDER BY tag_name ASC;   

CREATE TABLE tag_effectiveness AS


SELECT u.username, ua.total_posts, ua.total_liked, ua.total_comments,
(ua.total_posts + ua.total_liked + ua.total_comments) AS user_activity_score,
ROW_NUMBER() OVER (ORDER BY (total_posts + total_liked + total_comments) DESC) AS rnk
FROM user_activity ua 
JOIN users u ON ua.user_id = u.id;

SELECT pt.tag_id, COUNT(c.id) AS frequency_of_comments, COUNT(l.user_id) AS frequency_of_likes,
(COUNT(c.id) + COUNT(l.user_id)) AS effectiveness_score
FROM photo_tags pt
LEFT JOIN comments c ON pt.photo_id = c.photo_id 
LEFT JOIN likes l ON c.photo_id = l.photo_id
GROUP BY pt.tag_id
ORDER BY effectiveness_score DESC;

WITH everything AS (
                                           SELECT p.user_id, t.tag_name, COUNT(pt.tag_id) AS frequency_of_tag,
                                           RANK() OVER(PARTITION BY user_id ORDER BY COUNT(*) DESC) AS rnk
                                           FROM photos p
                                           JOIN photo_tags pt ON p.id = pt.photo_id
                                           JOIN tags t ON pt.tag_id = t.id
                                           GROUP BY p.user_id, t.tag_name
)
SELECT user_id, tag_name, frequency_of_tag
FROM everything 
WHERE rnk =1;   

SELECT u.username, ua.total_posts, ua.total_liked, ua.total_comments,
(ua.total_posts + ua.total_liked + ua.total_comments) AS user_activity_score,
ROW_NUMBER() OVER (ORDER BY (total_posts + total_liked + total_comments) DESC) AS rnk
FROM user_activity ua 
JOIN users u ON ua.user_id = u.id;

WITH everything AS (
		                                SELECT u.id AS user_id, u.username, COUNT( DISTINCT l.user_id) AS total_likes, 
                                                                    COUNT(DISTINCT c.id) AS total_comments, COUNT(DISTINCT pt.photo_id) AS  total_posts, 
                                                                    COUNT(DISTINCT pt.tag_id) AS total_phototags
                                                                    FROM users u 
                                                                    LEFT JOIN likes l ON u.id = l.user_id 
                                                                    LEFT JOIN comments c ON u.id = c.user_id 
                                                                    LEFT JOIN photo_tags pt ON pt.photo_id = c.photo_id 
                                                                    GROUP BY u.id, u.username 
                   )
                  SELECT username, total_likes, total_comments, total_phototags
                  FROM everything
                  ORDER BY total_likes DESC, total_comments DESC, total_phototags DESC;     

 WITH likes_per_photo AS ( 
                         SELECT pt.photo_id, COUNT(l.user_id) AS total_likes 
                         FROM photo_tags pt 
                         LEFT JOIN likes l ON pt.photo_id = l.photo_id 
                         GROUP BY photo_id 
                         ORDER BY total_likes DESC
                         ),
highest_avg_likes AS (
                      SELECT photo_id, ROUND(AVG(total_likes),2) AS avg_likes
                      FROM likes_per_photo
                      GROUP BY photo_id 
                      ORDER BY avg_likes DESC
), 
tagss AS (                       
         SELECT ha.photo_id, ha.avg_likes, pt.tag_id 
		 FROM highest_avg_likes ha
         LEFT JOIN photo_tags pt ON ha.photo_id = pt.photo_id
         )
SELECT ts.photo_id, ts.avg_likes, t.tag_name AS Hashtags 
FROM tagss ts 
LEFT JOIN tags t ON ts.tag_id = t.id;  
 
 
 SELECT f1.follower_id AS user_A, f1.followee_id AS user_B, f1.created_at AS A_followed_B_on,
f2.created_at AS B_followed_A_back_on
FROM follows f1
JOIN follows f2
    ON f1.followee_id = f2.follower_id
   AND f1.follower_id = f2.followee_id
   AND f2.created_at >= f1.created_at
ORDER BY f2.created_at;

    SELECT u.username, ua.total_posts, ua.total_liked, ua.total_comments, 
                 (ua.total_posts + ua.total_liked +   ua.total_comments) AS user_activity_score,
                 ROW_NUMBER() OVER (ORDER BY (total_posts + total_liked + total_comments) DESC) AS rnk
                 FROM user_activity ua 
                 JOIN users u ON ua.user_id = u.id;
SELECT username, COUNT(total_posts) AS frequency_of_posts 
FROM user_activity_ranked 
WHERE total_liked = 0 
AND total_comments =0
GROUP BY username;

WITH everything AS (
                    SELECT ua.user_id, ua.username, p.id AS photo_id, pt.tag_id, t.tag_name
					FROM user_activity_ranked ua
                    LEFT JOIN photos p ON ua.user_id = p.user_id
                    LEFT JOIN photo_tags pt ON p.id = pt.photo_id
                    LEFT JOIN tags t ON pt.tag_id = t.id
                    WHERE total_comments=0
                    AND total_liked=0
                    )
SELECT username, tag_name
FROM everything;   

WITH everything AS (
                                                         SELECT pt.tag_id, COUNT(c.id) AS frequency_of_comments, COUNT(l.user_id) AS frequency_of_likes,
                                                         (COUNT(c.id) + COUNT(l.user_id)) AS effectiveness_score
		                     FROM photo_tags pt
			   LEFT JOIN comments c ON pt.photo_id = c.photo_id 
                                                          LEFT JOIN likes l ON c.photo_id = l.photo_id
                                                          GROUP BY pt.tag_id
		                     ORDER BY engagement_score DESC
                                                          LIMIT 10
                    )
                   SELECT t.tag_name, e.frequency_of_comments, e.frequency_of_likes, e.effectiveness_score
                   FROM everything e 
                   JOIN tags t ON e.tag_id = t.id;   

WITH everything AS (
                                                         SELECT pt.tag_id, COUNT(c.id) AS frequency_of_comments, COUNT(l.user_id) AS frequency_of_likes,
                                                         (COUNT(c.id) + COUNT(l.user_id)) AS effectiveness_score
		                     FROM photo_tags pt
			   LEFT JOIN comments c ON pt.photo_id = c.photo_id 
                                                          LEFT JOIN likes l ON c.photo_id = l.photo_id
                                                          GROUP BY pt.tag_id
		                     ORDER BY effectiveness_score DESC
                                                          LIMIT 10
                    )
                   SELECT t.tag_name, e.frequency_of_comments, e.frequency_of_likes, e.effectiveness_score
                   FROM everything e 
                   JOIN tags t ON e.tag_id = t.id;   
                   
WITH everything AS (
                                                         SELECT pt.tag_id, COUNT(c.id) AS frequency_of_comments, COUNT(l.user_id) AS frequency_of_likes,
                                                         (COUNT(c.id) + COUNT(l.user_id)) AS effectiveness_score
		                     FROM photo_tags pt
			   LEFT JOIN comments c ON pt.photo_id = c.photo_id 
                                                          LEFT JOIN likes l ON c.photo_id = l.photo_id
                                                          GROUP BY pt.tag_id
		                     ORDER BY effectiveness_score DESC
                                                          LIMIT 10
                    )
                   SELECT t.tag_name, e.frequency_of_comments, e.frequency_of_likes, e.effectiveness_score
                   FROM everything e 
                   JOIN tags t ON e.tag_id = t.id;   
SELECT f.followee_id AS user_id, u.username, COUNT(f.follower_id) AS total_followers
FROM follows f
JOIN users u ON f.followee_id = u.id 
GROUP BY user_id, username
ORDER BY total_followers DESC;

     CREATE TABLE engagement_rate AS 
SELECT u.username, ua.total_posts, ua.total_liked, ua.total_comments, 
(ua.total_posts + ua.total_liked +   ua.total_comments) AS engagement_rate,
ROW_NUMBER() OVER (ORDER BY (total_posts + total_liked + total_comments) DESC) AS user_rank
FROM user_activity ua 
JOIN users u ON ua.user_id = u.id;

SELECT f.user_id, f.username, f.total_followers, e.engagement_rate,
CASE 
     WHEN f.total_followers >= 75 AND e.engagement_rate >= 70 THEN 'Top Influencer'
     WHEN f.total_followers >= 75 AND e.engagement_rate < 20 THEN 'Awareness Influencer'
	     WHEN f.total_followers < 75 AND e.engagement_rate >= 60 THEN 'Micro Influencer'
	     ELSE 'General User'
	END AS influencer_category
FROM followers_list f
JOIN engagement_rate e 
    ON f.username = e.username
    ORDER BY engagement_rate DESC;
    
    SELECT f.user_id, f.username, f.total_followers, e.engagement_rate,
CASE 
     WHEN f.total_followers >= 75 AND e.engagement_rate >= 70 THEN 'Top Influencer'
     WHEN f.total_followers >= 75 AND e.engagement_rate < 20 THEN 'Awareness Influencer'
	     WHEN f.total_followers < 75 AND e.engagement_rate >= 60 THEN 'Micro Influencer'
	     ELSE 'General User'
	END AS influencer_category
FROM followers_list f
JOIN engagement_rate e 
    ON f.username = e.username
    ORDER BY engagement_rate DESC;
    
    SELECT f.user_id, f.username, f.total_followers, u.total_posts, u.total_liked, u.total_comments, 
COALESCE(u.total_posts + u.total_liked + u.total_comments/NULLIF (f.total_followers, 0),0) AS engagement_score, 
CASE 
  WHEN COALESCE(u.total_posts + u.total_liked + u.total_comments/NULLIF (f.total_followers, 0),0) >= 10 THEN       'Top-Influencer'
  WHEN COALESCE(u.total_posts + u.total_liked + u.total_comments/NULLIF (f.total_followers, 0),0) >= 7 THEN 'Strong-Influencer'
  WHEN COALESCE(u.total_posts + u.total_liked + u.total_comments/NULLIF (f.total_followers, 0),0) >= 4 THEN 'Growing-Influencer'
  WHEN COALESCE(u.total_posts + u.total_liked + u.total_comments/NULLIF (f.total_followers, 0),0) >= 2.5 THEN 'Emerging-Influencer'
     ELSE 'Low-Engagement User'
     END AS user_segment
FROM followers_list f 
JOIN user_activity_ranked u ON f.user_id = u.user_id 
ORDER BY engagement_score DESC;

SELECT user_segment, ROUND(AVG(engagement_score),2) AS engagement_rate
FROM influencer_segement
GROUP BY user_segment;

USE ig_clone; 

SELECT * 
FROM tags;

USE ig_clone;

SELECT * 
FROM photos;

CREATE TABLE customers (
    customer_id BIGINT,
    customer_age INT,
    customer_gender VARCHAR(20)
);

CREATE DATABASE ecommerce_project;
USE ecommerce_project;
CREATE TABLE customers (
    customer_id BIGINT,
    customer_age INT,
    customer_gender VARCHAR(20)
);

SHOW VARIABLES LIKE 'secure_file_priv';

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/customers.csv'
INTO TABLE customers
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT COUNT(*) FROM customers;
