-- 1. What range of years for baseball games played does the provided database cover?

SELECT
	MIN(year) as earliest_year,
	MAX(year) as latest_year,
	MAX(year) - MIN(year) as range_of_years
FROM homegames

--Answer: From 1971 to 2016, a span of 145 years.

-- 2. Find the name and height of the shortest player in the database. How many games did he play in? What is the name of the team for which he played?

SELECT
	namefirst,
	namelast,
	height,
	SUM(a.g_all) as number_of_games,
	t.name as team_name
from people as p
INNER JOIN appearances as a
	USING (playerid)
INNER JOIN teams as t
	ON (a.teamid = t.teamid) AND (a.yearid = t.yearid)
GROUP BY p.namefirst, p.namelast, p.height, t.name
ORDER BY height ASC
LIMIT 1

--Answer: Eddie Gaedel, 43 inches tall, played one game for the St. Louis Browns.

-- 3. Find all players in the database who played at Vanderbilt University. Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues. Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?

--people > collegeplaying > schools WHERE school = Vanderbilt
--people > salaries

WITH vanderbilt_alum AS (
	SELECT
		DISTINCT (p.playerid),
		p.namefirst,
		p.namelast,
		s.schoolname
	FROM people as p
	INNER JOIN collegeplaying as c
		USING (playerid)
	INNER JOIN schools as s
		USING (schoolid)
	WHERE s.schoolname ILIKE '%Vanderbilt%') 
	
SELECT
	v.namefirst || ' ' || v.namelast as name,
	SUM(s.salary :: INTEGER :: MONEY) as total_earnings
FROM salaries as s
INNER JOIN vanderbilt_alum as v
	USING (playerid)
GROUP BY name
ORDER BY SUM(s.salary) DESC

-- RESULT CHECK: David Price $81,851,296.00
-- SELECT (salary) FROM 
-- salaries
-- WHERE playerid = 'priceda01'

--ANSWER: David Price earned $81,851,296.00

-- 4. Using the fielding table, group players into three groups based on their position: label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups in 2016.

--EXPLORE:
-- SELECT * 
-- FROM fielding
-- LIMIT 5

WITH positions AS(
	SELECT pos as pos_code,
	CASE WHEN
		pos = 'OF' THEN 'Outfield'
		WHEN pos IN ('SS', '1B', '2B', '3B') THEN 'Infield'
		ELSE 'Battery' END AS grouping,
	po as putouts
	FROM fielding
	WHERE yearid = 2016)
	
SELECT 
	grouping as position,
	SUM(putouts) as total_putouts
	FROM positions
	GROUP BY grouping
		
--Answer
-- "Battery"	41,424
-- "Infield"	58,934
-- "Outfield"   29,560
   
-- 5. Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. Do the same for home runs per game. Do you see any trends?

--Pitching, Batting, People, Homegames
-- avg strikeouts/game per decade, avg homeruns/game per year

WITH strike_outs AS
		(SELECT
			LEFT(yearid::VARCHAR(4), 3)||'0s' AS decade,
			SUM(so) AS total_strike_outs
		FROM pitching
		WHERE yearid >= 1920
		GROUP BY decade),

home_runs AS
		(SELECT
			LEFT(yearid::VARCHAR(4), 3)||'0s' AS decade,
			SUM(hr) AS total_home_runs
		FROM batting
		WHERE yearid >= 1920
		GROUP BY decade),

games AS
		(SELECT
			LEFT(year::VARCHAR(4), 3)||'0s' AS decade,
			SUM(games) AS total_games
		FROM homegames
		WHERE year >= 1920
		GROUP BY decade)
		
SELECT
	games.decade,
	total_games,
	total_strike_outs,
	ROUND(total_strike_outs::NUMERIC/total_games::NUMERIC,2) AS average_strike_outs,
	total_home_runs,
	ROUND(total_home_runs::NUMERIC/total_games::NUMERIC,2) AS average_home_runs
FROM strike_outs
INNER JOIN home_runs
USING (decade)
INNER JOIN games
USING (decade);


-- 6. Find the player who had the most success stealing bases in 2016, where __success__ is measured as the percentage of stolen base attempts which are successful. (A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted _at least_ 20 stolen bases.

--batting, people

SELECT 
	t2.namefirst || ' ' || t2.namelast as name,
--	(cs:: NUMERIC + sb:: NUMERIC) as steal_attempts,
--	sb:: NUMERIC as stolen_bases,
--	cs:: NUMERIC as caught_stealing,
	ROUND((sb :: NUMERIC / (cs:: NUMERIC+sb:: NUMERIC)*100),2) as percentage_stolen,
	ROUND((cs:: NUMERIC / (cs:: NUMERIC+sb:: NUMERIC)*100),2) as percentage_caught

FROM batting as t1
INNER JOIN people as t2
on t1.playerid = t2.playerid
WHERE t1.yearid = 2016 AND (cs + sb) > 20
ORDER BY percentage_stolen DESC
LIMIT 1;

--ANSWER: In 2016 Chris Owings was successful in 91.3% of his 23 steal attempts.

-- 7.  From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? What is the smallest number of wins for a team that did win the world series? Doing this will probably result in an unusually small number of wins for a world series champion – determine why this is the case. Then redo your query, excluding the problem year. How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?

-- largest number of wins for a team that did not win the world series --

SELECT  
	yearid,
	teamid,
	MAX(W) as wins
FROM teams
WHERE yearid BETWEEN 1970 AND 2016 
 	AND yearid != 1981
	AND teamid NOT IN
	(SELECT
		teamid
	from teams
	WHERE (yearid BETWEEN 1970 AND 2016) AND wswin = 'Y')
GROUP BY teamid, yearid
ORDER BY wins DESC
	 
--ANSWER: Seattle in 2001 with 116 wins

-- smallest number of wins for a team that won the world series --
	
SELECT  
	yearid,
	teamid,
	MIN(W) as wins
FROM teams
WHERE yearid BETWEEN 1970 AND 2016 
 	AND yearid != 1981
	AND teamid IN
	(SELECT
		teamid
	from teams
	WHERE (yearid BETWEEN 1970 AND 2016) AND wswin = 'Y')
GROUP BY teamid, yearid
ORDER BY wins ASC

--ANSWER: TOR in 1981 with 37 games
--        Problem year: 1981 player's strike


-- 8. Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance per game in 2016 (where average attendance is defined as total attendance divided by number of games). Only consider parks where there were at least 10 games played. Report the park name, team name, and average attendance. Repeat for the lowest 5 average attendance.


-- 9. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? Give their full name and the teams that they were managing when they won the award.

-- 10. Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. Report the players' first and last names and the number of home runs they hit in 2016.