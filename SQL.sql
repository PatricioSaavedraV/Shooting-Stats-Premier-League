-- to take into consideration:
--Rk: Index of the player in the list.
--Player: Name of the player.
--Nation: Nationality of the player.
--Pos: Position of the player on the field. (GK = goalkeeper, DF = defender, MF= midfielder, FW = forwards)
--Squad: Team the player belongs to.
--Age: Age of the player at the time of Aug 1st 2023(season start).
--Born: Birth year of the player.
--90s: Number of 90-minute intervals the player participated in.
--Gls: Total goals scored by the player.
--Sh: Total shots taken by the player.
--SoT: Shots on target by the player.
--SoT%: Shot accuracy percentage.
--Sh/90: Shots per 90 minutes.
--SoT/90: Shots on target per 90 minutes.
--G/Sh: Goals per shot.
--G/SoT: Goals per shot on target.
--Dist: Average distance of shots taken by the player.
--FK: Free kicks taken by the player.
--PK: Penalty kicks made by the player.
--PKatt: Penalty kick attempts by the player.
--xG: Expected goals.
--npxG: Non-penalty expected goals.
--npxG/Sh: Non-penalty expected goals per shot.
--G-xG: Difference between actual goals and expected goals.
--np:G-xG: Difference between non-penalty actual goals and non-penalty expected goals.
--Matches: Link to matches played as a str.
--Birth Month: Month of birth of the player.

SELECT
	*
FROM
	player_shooting

--------------------------------------------------------------------------------------------------------
-- What information do we hope to obtain?

-- 1. Which team scored the most goals?
-- 2. Which team needed fewer shots to score goals?
-- 3. What is the position with the greatest probability of scoring goals?
-- 4. What is the average age per position?
-- 5. How many goals were scored by nationality of each player?
-- 6. Which nationality needed the fewest shots to score goals?
-- 7. How many penalties did each team have?
-- 8. Who were the players with the best chances of scoring a penalty goal?

--------------------------------------------------------------------------------------------------------

-- Cleaning data

-- Delete rows with no information
SELECT
	*
FROM
	player_shooting
WHERE
	Rk IS NULL

DELETE FROM player_shooting WHERE Rk IS NULL

-- There is not duplicate information
SELECT
	*
FROM
	player_shooting
WHERE
	Player in(
	SELECT 
		Player
	FROM 
		player_shooting
	GROUP BY 
		Player, 
		Nation,
		Squad
	HAVING 
		COUNT(*) > 1)

-- Looking Pos
SELECT
	Pos,
	CASE WHEN CHARINDEX(',',Pos) >=1 THEN SUBSTRING(Pos, 0, CHARINDEX(',',Pos)) ELSE Pos END,
	CASE WHEN LEN(Pos)>=3 THEN SUBSTRING(Pos, CHARINDEX(',',Pos)+1, LEN(Pos)) ELSE NULL END
FROM
	player_shooting

ALTER TABLE 
	player_shooting
ADD
	Pos1 Nvarchar(255),
	Pos2 Nvarchar(255)

UPDATE 
	player_shooting
SET
	Pos1 = CASE WHEN CHARINDEX(',',Pos) >=1 THEN SUBSTRING(Pos, 0, CHARINDEX(',',Pos)) ELSE Pos END, Pos2 = CASE WHEN LEN(Pos)>=3 THEN SUBSTRING(Pos, CHARINDEX(',',Pos)+1, LEN(Pos)) ELSE NULL END

SELECT
	Pos1,
	COUNT(Pos1)
FROM
	player_shooting
GROUP BY
	Pos1

SELECT
	Pos2,
	COUNT(Pos2)
FROM
	player_shooting
GROUP BY
	Pos2


-- Looking SoT%
SELECT
	*
FROM
	player_shooting as ps
WHERE
	ps.[SoT%] IS NULL
-- there are some null values, which is correct for players who had no shots
-- That also affects the other variables.
--------------------------------------------------------------------------------------------------------

-- Questions 

-- 1. Which team scored the most goals?
SELECT
	Squad,
	SUM(Gls) as total_goals
FROM
	player_shooting
GROUP BY
	Squad
ORDER BY
	total_goals DESC

-- 2. Which team needed fewer shots to score goals?
SELECT
	Squad,
	SUM(sh) as total_shots,
	SUM(Gls) as total_goals,
	ROUND(SUM(sh)/SUM(Gls),2) Shots_per_goal
FROM
	player_shooting
GROUP BY
	Squad
ORDER BY
	Shots_per_goal ASC

-- 3. What is the position with the greatest probability of scoring goals?
-- For the analysis, the first position indicated will be used
SELECT
	Pos1,
	SUM(sh) as total_shots,
	SUM(Gls) as total_goals,
	ROUND((SUM(Gls)/SUM(sh))*100,2) Shots_per_goal
FROM
	player_shooting
GROUP BY
	Pos1
ORDER BY
	Shots_per_goal DESC

-- 4. What is the average age per position?
SELECT
	Pos1,
	ROUND(AVG(Age),2) as age_avg
FROM
	player_shooting
GROUP BY
	Pos1
ORDER BY
	age_avg ASC

SELECT
	Squad,
	Pos1,
	ROUND(AVG(Age),2) as age_avg
FROM
	player_shooting
GROUP BY
	Squad,
	Pos1
ORDER BY
	Pos1 ASC,
	age_avg ASC

-- 5. How many goals were scored by nationality of each player?
SELECT
	Nation,
	SUM(Gls) as total_goals
FROM
	player_shooting
GROUP BY
	Nation
ORDER BY
	total_goals DESC

-- 6. Which nationality needed the fewest shots to score goals?
SELECT
	Nation,
	SUM(SH) as total_shots,
	SUM(Gls) as 'total_goals',
	ROUND(SUM(SH)/SUM(Gls),2) as shots_per_goal
FROM
	player_shooting
WHERE
	Gls <> 0
GROUP BY
	Nation
HAVING
	SUM(Gls) >= 5
ORDER BY
	shots_per_goal ASC

SELECT
	*
FROM
	player_shooting
WHERE
	Nation = 'NZL' -- KOR, EGY, CMR, SWE

-- 7. How many penalties did each team have?
SELECT
	Squad,
	SUM(PKatt) as total_penalties,
	SUM(PK) as total_penalties_made,
	ROUND(SUM(PK)/SUM(PKatt),2) as penalty_accuracy
FROM
	player_shooting
GROUP BY
	Squad
ORDER BY
	penalty_accuracy DESC

-- 8. Who were the players with the best chances of scoring a penalty goal?
SELECT
	Squad,
	Player,
	Age,
	PKatt as total_penalties,
	PK as total_penalties_made,
	ROUND(PK/PKatt,2) as penalty_accuracy
FROM
	player_shooting
WHERE
	PKatt >= 3
ORDER BY
	penalty_accuracy ASC
