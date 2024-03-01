-- Question 1: What range of years for baseball games played does the provided database cover?

SELECT MIN(year), MAX(year)
FROM homegames

-- Question 2: Find the name and height of the shortest player in the database. How many games did he play in? What is the name of the team for which he played?

SELECT people.playerid, namefirst, namelast, height, name, SUM(g_all)
FROM people
INNER JOIN appearances
ON people.playerid = appearances.playerid
INNER JOIN teams
ON appearances.teamid = teams.teamid
WHERE height IS NOT NULL
GROUP BY people.playerid ,namefirst, namelast, name
ORDER BY height
LIMIT 1;

-- Name: Eddie Gaedel. Played in 1 game on the St. Louis Browns

-- Question 3: Find all players in the database who played at Vanderbilt University. Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues. Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?

WITH college_vandy AS

(
	SELECT DISTINCT playerid, schoolid
	FROM collegeplaying
	WHERE schoolid ILIKE 'vandy'
)

SELECT people.playerid, CONCAT(namefirst,' ', namelast) AS name, SUM(salary)::numeric::money AS total_salary
FROM college_vandy
INNER JOIN people
ON college_vandy.playerid = people.playerid
INNER JOIN salaries
ON people.playerid = salaries.playerid
GROUP BY people.playerid, name
ORDER BY total_salary DESC

-- Cy Young Winner, David Price

-- Question 4 Using the fielding table, group players into three groups based on their position: label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups in 2016.

SELECT SUM(PO) AS total_putouts,
CASE 
WHEN pos = 'OF' THEN 'Outfield'
WHEN pos IN ('SS', '1B', '2B', '3B') THEN 'Infield'
WHEN pos IN ('P', 'C') THEN 'Battery'
END AS positions
FROM fielding
WHERE yearID = '2016'
GROUP BY  positions
ORDER BY total_putouts DESC

-- Question 5 Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. Do the same for home runs per game. Do you see any trends?

WITH decade_start AS 
(
	SELECT generate_series (1920,2010,10)
	AS decade)


SELECT hr, so, ghome, decade
FROM teams
INNER JOIN decade_start
ON yearid BETWEEN decade AND decade +9
-- 

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

-- Question 6 Find the player who had the most success stealing bases in 2016, where success is measured as the percentage of stolen base attempts which are successful. (A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted at least 20 stolen bases.

SELECT CONCAT(namefirst,' ', namelast) AS name, (sb) AS stolen_base, (cs::numeric) AS caught_stealing, (sb+cs)::numeric AS attempted_sb, ROUND(sb/(cs::numeric+sb::numeric)*100,2) AS success
FROM batting
INNER JOIN people
ON batting.playerid = people.playerid
WHERE batting.yearid = 2016
AND COALESCE(sb+cs)>=20
ORDER BY success DESC

-- Question 7 From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? What is the smallest number of wins for a team that did win the world series? Doing this will probably result in an unusually small number of wins for a world series champion – determine why this is the case. Then redo your query, excluding the problem year. How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?

SELECT yearid, teamid, w
FROM teams
WHERE wswin = 'Y'
AND yearid > 1970
ORDER BY w 

SELECT yearid, teamid, w
FROM teams
WHERE wswin = 'N'
AND yearid > 1970
ORDER BY w DESC

SELECT *
FROM teams
WHERE wswin = 'Y'
ORDER BY w 

-- Answer: There was a baseball strike in 1981 during June/July

