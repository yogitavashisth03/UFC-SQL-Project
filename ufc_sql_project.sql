--List all fights that were title fights along with the winner and event location--

SELECT event_name,fight_id, event_location, winner
FROM ufc
WHERE title_fight=1



--Find the total number of fights that took place in each city--

SELECT event_location AS city, COUNT(ight_id) AS number_of_fights
FROM ufc 
GROUP BY city
ORDER BY number_of_fights DESC



--Identify the number of fights each fighter has participated in--

SELECT fighter_name, COUNT(fight_id) AS number_of_fights
FROM
(SELECT fight_id, r_name AS fighter_name
FROM ufc
UNION ALL
SELECT fight_id, b_name AS fighter_name
FROM ufc) AS t
GROUP BY fighter_name
ORDER BY number_of_fights DESC



--Which fighter has the most number of wins overall--

SELECT fighter_name
FROM (
      SELECT fight_id, r_name AS fighter_name
	  FROM ufc
	  UNION ALL 
	  SELECT fight_id, b_name AS fighter_name
	  FROM ufc
) AS t
GROUP BY fighter_name
ORDER BY COUNT(fight_id) DESC
LIMIT 1



--Find the average fight duration per division--

SELECT division,ROUND(AVG(match_time_sec)) AS average_fight_duration
FROM ufc
GROUP BY division



--List fighters who have never lost a match--

WITH t1 AS (
            SELECT fighter_name, COUNT(fight_id) AS number_of_fights
            FROM ( 
			       SELECT fight_id, r_name AS fighter_name
				   FROM ufc
				   UNION ALL
				   SELECT fight_id, b_name AS fighter_name
				   FROM ufc
				  ) AS t
			GROUP BY fighter_name
	),
	t2 AS (
	       SELECT fighter_name, COUNT(fight_id) AS number_of_fights_won
	       FROM (
                 SELECT fight_id, r_name AS fighter_name
				 FROM ufc
				 WHERE winner=r_name
				 UNION ALL
				 SELECT fight_id, b_name AS fighter_name
				 FROM ufc
				 WHERE winner=b_name
		   ) AS t
		   GROUP BY fighter_name
    )
SELECT t1.fighter_name AS fighter_who_never_lost
FROM t1
LEFT JOIN t2
ON t1.fighter_name=t2.fighter_name
WHERE number_of_fights=number_of_fights_won



--Get the top 5 fighters with the most knockout (KO/TKO) wins--

SELECT fighter_name
FROM (
      SELECT r_name AS fighter_name, fight_id 
	  FROM ufc
	  WHERE r_name=winner
	  AND fight_method='KO/TKO'
	  
	  UNION ALL
	  SELECT b_name AS fighter_name, fight_id
	  FROM ufc
	  WHERE b_name=winner
	  AND fight_method='KO/TKO'
	  
  ) AS t
GROUP BY fighter_name
ORDER BY COUNT(fight_id) DESC
LIMIT 5



--Identify events with more than 10 fights--

SELECT event_name
FROM ufc
GROUP BY event_name
HAVING COUNT(fight_id)>=10



--Rank fighters based on total strikes landed in all their fights--

SELECT fighter_name, RANK() OVER (ORDER BY ttl_str_lan DESC) AS f_rank
FROM
(SELECT fighter_name, SUM(total_strikes_landed) AS ttl_str_lan
FROM (
      SELECT r_name AS fighter_name, r_total_str_landed AS total_strikes_landed
      FROM ufc
	  WHERE r_total_str_landed IS NOT NULL
      UNION ALL
      SELECT b_name AS fighter_name, b_total_str_landed AS total_strikes_landed
	  FROM ufc
	  WHERE b_total_str_landed IS NOT NULL
) AS t 
GROUP BY fighter_name
) AS t1
ORDER BY f_rank



--Find fighters with the highest takedown accuracy (min. 10 attempts)--

SELECT fighter_name, ROUND((SUM(td_landed)/SUM(td_attempted))*100,2) AS takedown_accuracy
FROM (
      SELECT r_name AS fighter_name, r_td_attempted AS td_attempted, r_td_landed AS td_landed
      FROM ufc
      WHERE r_td_attempted>=10
      UNION ALL 
      SELECT b_name AS fighter_name, b_td_attempted AS td_attempted, b_td_landed AS td_landed
      FROM ufc
      WHERE b_td_attempted>=10
) AS t
GROUP BY fighter_name 
ORDER BY takedown_accuracy DESC
LIMIT 10



--Find the fighter who has fought the most different opponents--

SELECT fighter_name, COUNT(DISTINCT opponent_name) AS number_of_unique_opponents
FROM(
    SELECT r_name AS fighter_name, b_name AS opponent_name 
    FROM ufc
    UNION ALL
    SELECT b_name AS fighter_name, r_name AS opponent_name 
    FROM ufc
) AS t
GROUP BY fighter_name
ORDER BY number_of_unique_opponents DESC
LIMIT 1



--For each fighter, calculate win percentage (only for those with at least 5 fights)--

WITH num_fights AS(
    SELECT fighter_name, COUNT(fight_id) AS number_of_fights
    FROM(
        SELECT r_name AS fighter_name, fight_id
        FROM ufc
        UNION ALL
        SELECT b_name AS fighter_name, fight_id
        FROM ufc
    ) AS t1
    GROUP BY fighter_name
),
win_fights AS (
    SELECT fighter_name, COUNT(fight_id) AS won_fights
	FROM(
	    SELECT r_name AS fighter_name, fight_id
        FROM ufc
		WHERE r_name=winner
        UNION ALL
        SELECT b_name AS fighter_name, fight_id
        FROM ufc
		WHERE b_name=winner
	) AS t2
	GROUP BY fighter_name
)


SELECT n.fighter_name, ROUND((COALESCE(won_fights,0)*1.0/number_of_fights)*100,2) AS win_percentage 
FROM num_fights n
LEFT JOIN win_fights w
ON n.fighter_name=w.fighter_name
WHERE number_of_fights>=5
ORDER BY win_percentage DESC



--Which weight division has the highest average finish rate (non-decision outcomes)--

SELECT division, ROUND(((COUNT(CASE 
                          WHEN fight_method NOT LIKE 'Decision%'
						  THEN fight_id END)*1.0/COUNT(fight_id))*100),2) AS finish_rate
FROM ufc
GROUP BY division
ORDER BY finish_rate DESC
LIMIT 1



--Identify the most common method of victory per weight division--

SELECT division, fight_method
FROM(
    SELECT division, fight_method, COUNT(fight_id) AS num_of_fights, 
	RANK() OVER (PARTITION BY division
	             ORDER BY COUNT(fight_id)) AS rnk
    FROM ufc
    GROUP BY division, fight_method
) AS t
WHERE rnk=1



--List all fighters who have won a title fight and lost a non-title fight--

WITH won_title_fight AS (
    SELECT r_id AS fighter_id, r_name AS fighter_name
    FROM ufc
    WHERE r_id=winner_id
    AND title_fight=1
    UNION ALL
    SELECT b_id AS fighter_id, b_name AS fighter_name
    FROM ufc
    WHERE b_id=winner_id
    AND title_fight=1
),
lost_non_title_fight AS(
    SELECT r_name AS fighter_name, r_id AS fighter_id
    FROM ufc
    WHERE r_id!=winner_id
    AND title_fight=0
    UNION ALL
    SELECT b_name AS fighter_name, b_id AS fighter_id
    FROM ufc
    WHERE b_id!=winner_id
    AND title_fight=0
)

SELECT DISTINCT w.fighter_name 
FROM won_title_fight w
JOIN lost_non_title_fight l
ON w.fighter_id=l.fighter_id



--Determine the fighter with the highest average strike accuracy in winning fights--

SELECT fighter_name, ROuND(AVG(fighter_strike_accuracy),2) FROM (
SELECT r_id AS fighter_id, r_name AS fighter_name, r_str_acc AS fighter_strike_accuracy
FROM ufc 
WHERE r_id=winner_id
UNION ALL 
SELECT b_id AS fighter_id, b_name AS fighter_name, b_str_acc AS fighter_strike_accuracy
FROM ufc 
WHERE b_id=winner_id
) AS t
GROUP BY fighter_name
ORDER BY AVG(fighter_strike_accuracy) DESC
LIMIT 1



--For each event, calculate the proportion of fights ending by submission--

SELECT event_id, event_name, ROUND((COUNT(CASE                                                                 
                                     WHEN fight_method='Submission' 
									 THEN fight_id END)*1.0/COUNT(fight_id)), 2) 
FROM ufc 
GROUP BY event_id, event_name
ORDER BY event_id



--Identify fighters who have defeated more than one opponent who has held a title--

WITH fight AS (
               SELECT r_name AS fighter_name, b_name AS opponent_name, title_fight
			   FROM ufc
			   WHERE r_id=winner_id
			   UNION ALL 
			   SELECT b_name AS fighter_name, r_name AS opponent_name, title_fight
			   FROM ufc
			   WHERE b_id=winner_id
)

SELECT DISTINCT f1.fighter_name, COUNT(DISTINCT f2.fighter_name) AS number_of_title_holders_defeated
FROM fight f1
JOIN fight f2
ON f1.opponent_name=f2.fighter_name
WHERE f2.title_fight=1
GROUP BY f1.fighter_name
HAVING COUNT(DISTINCT f2.fighter_name)>1



--List the top 5 fighters who have won the most fights in under 2 minutes--

SELECT fighter_name, COUNT(*) AS number_of_fights_won_under_2_mins
FROM(
    SELECT r_name AS fighter_name 
    FROM ufc 
    WHERE match_time_sec<120
    AND r_id=winner_id
    UNION ALL
    SELECT b_name AS fighter_name 
    FROM ufc 
    WHERE match_time_sec<120
    AND b_id=winner_id
) AS t
GROUP BY fighter_name
ORDER BY number_of_fights_won_under_2_mins DESC
LIMIT 5



--Find pairs of fighters who have fought each other more than once and show their win/loss record--

WITH fights AS (
    SELECT 
	    LEAST(r_id, b_id) AS fighter_1,
		GREATEST(r_id, b_id) AS fighter_2,
		winner_id
    FROM ufc
),
fight_pairs AS (
    SELECT
	    fighter_1,
		fighter_2,
		COUNT(*) AS total_fights,
		COUNT(CASE WHEN winner_id=fighter_1 THEN 1 END) AS fighter_1_wins,
		COUNT(CASE WHEN winner_id=fighter_2 THEN 1 END) AS fighter_2_wins
		FROM fights
		GROUP BY fighter_1, fighter_2
		HAVING COUNT(*)>1
)

SELECT f1.fighter_name, f2.fighter_name, total_fights, fighter_1_wins, fighter_2_wins
FROM fight_pairs fp
JOIN fighter_table f1
ON fp.fighter_1= f1.fighter_id
JOIN fighter_table f2
ON fp.fighter_2= f2.fighter_id