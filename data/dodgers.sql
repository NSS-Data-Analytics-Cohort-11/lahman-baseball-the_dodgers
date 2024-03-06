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
-- Tables: homegames

WITH highavg AS (
	SELECT parks.park_name,teams.name, homegames.attendance/homegames.games AS avgattend
	FROM homegames
	INNER JOIN parks
	USING (park)
	INNER JOIN teams
	ON homegames.team = teams.teamid AND homegames.year = teams.yearid
	WHERE year = 2016 AND games >= 10
	ORDER BY avgattend DESC
	LIMIT 5)
, lowavg AS (
SELECT parks.park_name,teams.name, homegames.attendance/homegames.games AS avgattend
	FROM homegames
	INNER JOIN parks
	USING (park)
	INNER JOIN teams
	ON homegames.team = teams.teamid AND homegames.year = teams.yearid
	WHERE year = 2016 AND games >= 10
	ORDER BY avgattend DESC
	LIMIT 5)
SELECT *
FROM highavg
UNION ALL
SELECT *
FROM lowavg

-- 9a. Which managers have won the TSN Manager of the Year award
-- in both the National League (NL) and the American League (AL)?
-- Give their full name and the teams that they were managing when they won the award.
-- Tables: 

WITH allof AS (
SELECT playerid,awardid,yearid,lgid
FROM awardsmanagers
WHERE awardid LIKE 'TSN%' AND lgid LIKE 'NL'
UNION
SELECT playerid,awardid,yearid,lgid
FROM awardsmanagers
WHERE awardid LIKE 'TSN%' AND lgid LIKE 'AL'
), nl AS(
SELECT playerid,awardid,yearid,lgid
FROM awardsmanagers
WHERE awardid LIKE 'TSN%' AND lgid LIKE 'NL'
), al AS (
SELECT playerid,awardid,yearid,lgid
FROM awardsmanagers
WHERE awardid LIKE 'TSN%' AND lgid LIKE 'AL'
), winners AS (
SELECT nl.playerid AS playid,nl.awardid,nl.yearid
FROM nl
INNER JOIN al
USING (playerid)
)
SELECT people.namefirst,people.namelast,allof.playerid,
allof.awardid,allof.yearid,allof.lgid,managers.teamid,teams.name
FROM allof
INNER JOIN people
USING (playerid)
INNER JOIN managers
USING (playerid, yearid)
INNER JOIN teams
USING (teamid,yearid)
WHERE playerid IN (SELECT winners.playid FROM winners)
ORDER BY allof.yearid

-- 10. Find all players who hit their career highest number of home runs in 2016.
-- Consider only players who have played in the league for at least 10 years,
-- and who hit at least one home run in 2016. Report the players' first and last
-- names and the number of home runs they hit in 2016.
-- Tables: people,

-- Players with at least one hr in 2016, who played at least 10 years
SELECT yearid, playerid, namefirst, namelast,
	(finalgame::DATE-debut::DATE)/365 AS years_played
FROM people
INNER JOIN batting 
USING (playerid)
WHERE (finalgame::DATE-debut::DATE)/365 >= 10 AND yearid = 2016 AND hr >= 1

--Players with a career high in 2016
SELECT yearid,playerid,sum(hr) AS sumhr
FROM batting
GROUP BY yearid,playerid,hr
HAVING yearid = 2016
ORDER BY sumhr DESC

--

--JACKIE ROBINSON AWARDS--
WITH jackie AS (
SELECT playerid AS jacks
FROM people
WHERE namefirst = 'Jackie' AND namelast = 'Robinson'
)
SELECT playerid,awardid, yearid
FROM awardsplayers, jackie
WHERE playerid LIKE jackie.jacks
ORDER BY awardsplayers.yearid ASC;

--JACKIE ROBINSON Hall of Fame--
WITH jackie AS (
SELECT playerid AS jacks
FROM people
WHERE namefirst = 'Jackie' AND namelast = 'Robinson'
)
SELECT playerid,yearid,votes,inducted,category
FROM halloffame, jackie
WHERE playerid LIKE jackie.jacks
ORDER BY halloffame.yearid ASC;


-- Jackie Robinson Career Length -- [9 years]
WITH jackie AS (
SELECT playerid AS jacks
FROM people
WHERE namefirst = 'Jackie' AND namelast = 'Robinson'
)
SELECT playerid,debut,finalgame,(finalgame::DATE-debut::DATE)/365
FROM people, jackie
WHERE playerid LIKE jackie.jacks

-- Brooklyn Dodgers Team ID
SELECT DISTINCT teamid
FROM teams
WHERE name LIKE 'Brooklyn Dodgers'

-- How long was Jackie Robinson on the Brooklyn Dodgers?
-- Was on the BRO for 9 years, his entire career [from 1947 to 1948]
WITH jackie AS (
SELECT playerid AS jacks
FROM people
WHERE namefirst = 'Jackie' AND namelast = 'Robinson'
)
SELECT 
FROM appearances, jackie
WHERE playerid LIKE jackie.jacks

-- BRO Attendance throughout 1947 to 1956 --
SELECT year, team, SUM(attendance) AS totalattendance
FROM homegames
GROUP BY year, team
HAVING year BETWEEN 1947 AND 1956 AND team LIKE 'BRO'
ORDER BY year ASC

-- BRO Attendance throughout 1936 to 1946 --
SELECT year, team, SUM(attendance) AS totalattendance
FROM homegames
GROUP BY year, team
HAVING year BETWEEN 1936 AND 1946 AND team LIKE 'BRO'
ORDER BY year ASC

-- BRO Attendance throughout 1936 to 1956 --
SELECT year, team, SUM(attendance) AS totalattendance
FROM homegames
GROUP BY year, team
HAVING year BETWEEN 1936 AND 1956 AND team LIKE 'BRO'
ORDER BY year ASC

-- When was BRO in the World Series? --
SELECT *
FROM seriespost
WHERE (teamidwinner LIKE 'BRO' OR teamidloser LIKE 'BRO') AND (yearid BETWEEN 1936 AND 1956)
ORDER BY yearid

-- Overall homegame attandance by team in 1947 --


-- homegame attendance in the 40s --

-- WW2 ended on Sep 2, 1945

-- Background --
-- Appeared on Brooklyn Dodgers April 15, 1947
-- Whether fans supported or opposed it,
-- Robinson's presence on the field was a boon to attendance;
-- more than one million people went to games involving Robinson in 1946
-- an astounding figure by International League standards
-- He won major-league baseball’s first official Rookie of the Year
-- award and was the first baseball player, black or white,
-- to be featured on a United States postage stamp.


-- When Robinson was called up to the Dodgers, he did not disappoint,
-- leading the National League in 1947 with 29 stolen bases while posting a solid .297 batting average.
--The Brooklyn first baseman earned Rookie of the Year honors, winning the award over New York Giants pitcher
-- Larry Jansen and Yankees hurler Spec Shea.

-- In his 1949 MVP season, Robinson led all National League batters with a .342 batting average.
--His 37 stolen bases led every player in the majors (as did the 16 times he was caught stealing


-- On April 15, Robinson made his major league debut at the relatively advanced age of 28 at Ebbets Field before a crowd of 26,623 spectators,
-- more than 14,000 of whom were black.[123] Although he failed to get a base hit, he walked and scored a run in the Dodgers' 
-- 5–3 victory.[124] Robinson became the first player since 1884 to openly break the major league baseball color line.
-- Black fans began flocking to see the Dodgers when they came to town, abandoning their Negro league teams.

-- series 
-- batting