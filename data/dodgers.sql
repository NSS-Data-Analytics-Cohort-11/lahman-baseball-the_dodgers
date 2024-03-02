-- 1. What range of years for baseball games played does the provided database cover?
SELECT MIN(year), MAX(year), MAX(year)-MIN(year) AS range
FROM homegames

-- 2a. Find the name and height of the shortest player in the database (Eddie Gaedel)
-- 2b. How many games did he play in?
-- 2c. What is the name of the team for which he played?

SELECT p.namefirst, p.namelast, p.playerid, p.height,t.name, SUM(a.g_all)
FROM people AS p
INNER JOIN appearances AS a
	USING (playerid)
INNER JOIN teams AS t
	USING (teamid, yearid)
GROUP BY p.namefirst, p.namelast, p.playerid, p.height,t.name
ORDER BY height
LIMIT 1;

-- 3a. Find all players in the database who played at Vanderbilt University.
-- 3b. Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues.
-- 3c. Sort this list in descending order by the total salary earned.
-- 3d. Which Vanderbilt player earned the most money in the majors?

--Tables: people, collegeplaying, salary

WITH vandy_alum AS
		(
		SELECT DISTINCT playerid, schoolid
		FROM collegeplaying
		WHERE schoolid= 'vandy'
		)
, salaries AS
		(
		SELECT playerid, SUM(salary) as sumsal
		FROM salaries
		GROUP BY playerid
		)
SELECT p.namefirst, p.namelast, s.schoolname, sal.sumsal
FROM people AS p
	INNER JOIN vandy_alum AS v
USING (playerid)
	INNER JOIN schools AS s
USING (schoolid)
	INNER JOIN salaries AS sal
USING (playerid)
ORDER BY sal.sumsal DESC

-- 4. Using the fielding table, group players into three groups based on their position:
-- label players with position OF as "Outfield", those with position "SS", "1B", "2B",
-- and "3B" as "Infield", and those with position "P" or "C" as "Battery".
-- Determine the number of putouts made by each of these three groups in 2016.
-- Tables: fielding

WITH groups AS(
	SELECT
		pos AS position,
		CASE
			WHEN pos = 'OF'THEN 'Outfield'
			WHEN pos IN ('SS','1B','2B','3B') THEN 'Infield'
			ELSE 'Battery' END AS pos_group,
		po AS putouts
	FROM fielding
	WHERE yearid = 2016)
SELECT
	DISTINCT pos_group,
	SUM(putouts) AS total_putouts
FROM groups
GROUP BY pos_group
	
-- 5. Find the average number of strikeouts per game by decade since 1920.
-- Round the numbers you report to 2 decimal places.
-- Do the same for home runs per game.
-- Do you see any trends?

-- Tables: Pitching, Batting, People, Homegames
-- avg strikeouts/game per decade, avg homeruns/game per decade

-- WITH decades AS (
-- 	SELECT
-- 	generate_series(1920, 2010, 10) AS decade_start
-- )
-- SELECT 
-- 	decade_start::text || 's' AS decade,
-- 	ROUND(SUM(so) * 1.0 / SUM(g),2) AS so_per_game,
-- 	ROUND(SUM(hr) * 1.0 / SUM(g),2) AS hr_per_game
-- FROM teams
-- INNER JOIN decades
-- ON yearid BETWEEN decade_start AND decade_start + 9
-- GROUP BY decade
-- ORDER BY decade;

WITH strike_outs AS(
	SELECT LEFT(yearid::varchar,3) || '0s' AS decade,
		SUM(pit.hr) AS sumouts
		FROM pitching AS pit
		WHERE yearid >= 1920
		GROUP BY decade
		ORDER BY decade ASC
), home_runs AS (
	SELECT LEFT(yearid::varchar,3) || '0s' AS decade,
	SUM(bat.hr) AS sumruns
	FROM batting AS bat
	WHERE yearid >= 1920
	GROUP BY decade
	ORDER BY decade ASC
), games AS (
	SELECT LEFT(year::varchar,3) || '0s' AS decade, SUM(home.games) AS sumgames
	FROM homegames AS home
	WHERE year >= 1920
	GROUP BY decade
	ORDER BY decade ASC
)
SELECT home.decade, ROUND(strike.sumouts::NUMERIC/game.sumgames::NUMERIC, 2), ROUND(home.sumruns::NUMERIC/game.sumgames::NUMERIC, 2), game.sumgames
FROM home_runs AS home
	INNER JOIN strike_outs AS strike
	USING (decade)
	INNER JOIN games AS game
	USING (decade)

-- 6. Find the player who had the most success stealing bases in 2016,
-- where success is measured as the percentage of stolen base attempts which are successful.
-- (A stolen base attempt results either in a stolen base or being caught stealing.)
-- Consider only players who attempted at least 20 stolen bases.
-- Tables: batting, people

WITH attempts AS (
	SELECT playerid, yearid, sb, cs
	FROM batting
	WHERE yearid = 2016 AND sb+cs >= 20
)
SELECT s.playerid, p.namefirst, p.namelast, s.sb, s.cs, ROUND((s.sb::NUMERIC/(s.sb::NUMERIC+s.cs::NUMERIC))*100,2) AS success, s.yearid
FROM attempts AS s
INNER JOIN people AS p
USING (playerid)
ORDER BY success DESC

--7a. From 1970 – 2016, what is the largest number of wins for a team that did not win the world series?

SELECT w
FROM teams
WHERE yearid BETWEEN 1970 AND 2016 AND wswin LIKE 'N'
ORDER BY w DESC
LIMIT 1;

--7b. What is the smallest number of wins for a team that did win the world series?
SELECT w
FROM teams
WHERE yearid BETWEEN 1970 AND 2016 AND wswin LIKE 'Y'
ORDER BY w ASC
LIMIT 1;
-- [There were strikes in 1981]

-- 7c. Doing this will probably result in an unusually small number of wins for a world series champion – determine why this is the case.
-- 7c. Then redo your query, excluding the problem year.
SELECT *
FROM teams
WHERE (yearid BETWEEN 1970 AND 1980 OR yearid BETWEEN 1982 AND 2016) AND wswin LIKE 'Y'
ORDER BY w ASC
LIMIT 1;

-- 7d. How often from 1970 – 2016 (yearid BETWEEN 1970 AND 2016)
-- was it the case that a team with the most wins (teams with max # of wins for each year)
-- also won the world series? (wswin LIKE 'Y')
-- What percentage of the time? (count of wswin LIKE 'Y'/all years)

-- Tables: teams

WITH maxwins AS (
	SELECT yearid,MAX(w) AS maxnumwins
	FROM teams
	WHERE yearid BETWEEN 1970 AND 2016
	GROUP BY yearid
	ORDER BY yearid ASC
), numseasons AS (
	SELECT COUNT(DISTINCT yearid) AS numgame
	FROM teams
	WHERE yearid BETWEEN 1970 AND 2016 
), teamswswin AS (
	SELECT COUNT(*) AS twswin
	FROM teams
	INNER JOIN maxwins
	ON maxwins.yearid = teams.yearid AND maxwins.maxnumwins = teams.w
	WHERE wswin = 'Y'
)
SELECT CONCAT(ROUND((teamswswin.twswin)::NUMERIC/(numseasons.numgame)::NUMERIC*100,2),'%')
FROM teamswswin, numseasons


-- 8a. Using the attendance figures from the homegames table,
-- find the teams and parks which had the top 5 average attendance per game in 2016
-- (where average attendance is defined as total attendance divided by number of games).
-- Only consider parks where there were at least 10 games played.
-- Report the park name, team name, and average attendance.
-- Repeat for the lowest 5 average attendance.







-