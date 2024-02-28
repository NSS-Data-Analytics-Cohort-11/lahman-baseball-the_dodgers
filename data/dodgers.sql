-- 1. What range of years for baseball games played does the provided database cover?
SELECT MIN(year), MAX(year), MAX(year)-MIN(year)
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



-- 5. Find the average number of strikeouts per game by decade since 1920.
-- Round the numbers you report to 2 decimal places. Do the same for home runs per game.
-- Do you see any trends?