

-- 1. What range of years for baseball games played does the provided database cover?

SELECT
	MIN(Year),
	MAX(YEAR),
	MAX(year) - MIN(Year) AS year_range
FROM homegames

-- ANSWER: 1871 - 2016, 145 years

-- 2a. Find the name and height of the shortest player in the database. 
-- 2b. How many games did he play in?
-- 2c. What is the name of the team for which he played?

SELECT
	playerid,
	namefirst,
	namelast,
	height,
	teams.name,
	SUM(g_all) AS games_played
FROM people
INNER JOIN appearances
USING(playerid)
INNER JOIN teams
USING(yearid, teamid)
GROUP BY 
	playerid,
	namefirst,
	namelast,
	height,
	teams.name
ORDER BY height
LIMIT 5;

-- ANSWER: Eddie Gaedel, St. Loius Browns, 1 game

-- 3. Find all players in the database who played at Vanderbilt University. Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues. Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?

-- Using tables: people, collegeplaying, schools, salaries
WITH player_college AS
	(SELECT
		DISTINCT(p.playerid) AS id,
		p.namefirst AS first_name,
		p.namelast AS last_name,
		s.schoolname AS college
	FROM people AS p
	INNER JOIN collegeplaying AS c
	USING(playerid)
	INNER JOIN schools AS s
	USING(schoolid)
	WHERE schoolname LIKE '%Vander%')

SELECT
	first_name ||' '||last_name,
	SUM(salary::INTEGER::MONEY) AS total_salary
FROM player_college
INNER JOIN salaries
ON player_college.id = salaries.playerid
GROUP BY 
	first_name,
	last_name
ORDER BY total_salary DESC;

-- Answer: "David Price"	"$81,851,296.00"



-- 4. Using the fielding table, group players into three groups based on their position: label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups in 2016.


WITH groups AS
	(SELECT
		pos AS position,										--Creating a CTE with a
		CASE													--CASE statement to create
			WHEN pos = 'OF' THEN 'Outfield'						--pos_group field	
			WHEN pos IN ('SS','1B','2B','3B') THEN 'Infield'
			ELSE 'Battery' END AS pos_group,
	 	po AS putouts
	FROM fielding
	WHERE yearid = 2016)
SELECT
	DISTINCT pos_group,
	SUM(putouts) AS total_putouts
FROM groups
GROUP BY pos_group;

-- ANSWER:
-- "Battery"	41424
-- "Infield"	58934
-- "Outfield"	29560


-- 5. Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. Do the same for home runs per game. Do you see any trends?

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


-- 6. Find the player who had the most success stealing bases in 2016, where success is measured as the percentage of stolen base attempts which are successful. (A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted at least 20 stolen bases.


WITH attempts AS
		(SELECT
			playerid,
			sb AS stolen_bases,
			cs AS caught_stealing,
			sb+cs AS total_attempts
		FROM batting
		WHERE yearid = 2016
		ORDER BY total_attempts DESC)
SELECT
	namefirst||' '||namelast AS player_name,
	ROUND((stolen_bases::NUMERIC /total_attempts::NUMERIC) * 100,2) AS perc_success
FROM attempts
INNER JOIN people
USING (playerid)
WHERE total_attempts >= 20
ORDER BY perc_success DESC;

--ANSWER: "Chris Owings"	91.30

--     From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? What is the smallest number of wins for a team that did win the world series? Doing this will probably result in an unusually small number of wins for a world series champion – determine why this is the case. Then redo your query, excluding the problem year. How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?

SELECT
	teamid,
	MAX(w) AS wins
FROM teams
WHERE yearid >= 1970
	AND wswin = 'N'
GROUP BY teamid
ORDER BY wins DESC

SELECT
	teamid,
	MIN(w) AS wins
FROM teams
WHERE yearid >= 1970
	AND wswin = 'Y'
GROUP BY teamid
ORDER BY wins

SELECT *
FROM teams
WHERE teamid = 'LAN'
AND yearid >= 1970
ORDER BY w


--     Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance per game in 2016 (where average attendance is defined as total attendance divided by number of games). Only consider parks where there were at least 10 games played. Report the park name, team name, and average attendance. Repeat for the lowest 5 average attendance.

--     Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? Give their full name and the teams that they were managing when they won the award.

--     Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. Report the players' first and last names and the number of home runs they hit in 2016.
