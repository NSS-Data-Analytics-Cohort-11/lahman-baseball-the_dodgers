--1. What range of years for baseball games played does the provided database cover? 

select min(year), max(year)
from homegames
--Answer: 1871 to 2016

--2. A.Find the name and height of the shortest player in the database. 
--2. B.How many games did he play in? 
--2. C.What is the name of the team for which he played?

--appearance, people, teams
select namefirst, namelast, height
from people
Where height IS NOT NULL
order by height
limit 1
--2.A. Answer: Eddie Gaedel


SELECT people.playerid, namefirst, namelast, height, name, SUM(g_all)
FROM people
INNER JOIN appearances
ON people.playerid = appearances.playerid
INNER JOIN teams
ON appearances.teamid = teams.teamid AND appearances.yearid = teams.yearid
WHERE height IS NOT NULL
GROUP BY people.playerid ,namefirst, namelast, name
ORDER BY height
LIMIT 1;
--2.B-C: 1 game played, and played for St. Louis Browns

--3. A. Find all players in the database who played at Vanderbilt University. 
--3. B.Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues. 
--3. C. Sort this list in descending order by the total salary earned. 
--3. D Which Vanderbilt player earned the most money in the majors?

/*	Select  -- First query had duplicate player id for David Price
		p.namefirst || ' ' ||
		p.namelast,
		s.schoolname,
		SUM(sa.salary) AS total_salary
	FROM people as p
	INNER JOIN collegeplaying AS c
		USING (playerid)
	INNER JOIN schools AS s
		USING (schoolid)
	INNER JOIN salaries AS sa
		USING (playerid)
	WHERE s.schoolname ILIKE '%Vanderbilt%'
	GROUP BY p.namefirst, p.namelast, s.schoolname
	ORDER BY total_salary DESC */
	
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
	
--Answer: David Price - $81,851,296.00


--4. Using the fielding table, group players into three groups based on their position: label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups in 2016.
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

/*--Answer:
"Battery"	41424
"Infield"	58934
"Outfield"	29560 */

--5. Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. Do the same for home runs per game. Do you see any trends?

--Pitching Table - Strikeouts "SO" per game by decade since 1920.
--Batting Table - Homeruns "HR" per game by decade since 1920.
--select decade, strikeouts, homeruns
SELECT *
FROM pitching

SELECT *
FROM batting
--Quick table reference

--Query for total strikeouts by decade
SELECT 
	LEFT(yearid::varchar,3) || '0s' AS decade,
	SUM(p.so)
FROM pitching AS p
WHERE yearid >= 1920
GROUP BY decade
ORDER BY decade ASC

--Query for total homeruns by decade
SELECT 
	LEFT(yearid::varchar,3) || '0s' AS decade,
	SUM(b.hr)
FROM batting AS b
WHERE yearid >= 1920
GROUP BY decade
ORDER BY decade ASC

--CTE?
SELECT 
	LEFT(yearid::varchar,3) || '0s' AS decade,
	AVG(g)
FROM teams AS t
WHERE yearid >= 1920
GROUP BY decade
ORDER BY decade ASC

SELECT*
FROM teams
WHERE yearid >= 1920

--Join Queries SO and HR
SELECT 
	LEFT(yearid::varchar,3) || '0s' AS decade,
	SUM(p.so) as total_strikeouts,
	SUM(b.hr) as total_homeruns
FROM pitching AS p
INNER JOIN batting AS b
USING (yearid)
WHERE yearid >= 1920
GROUP BY decade
ORDER BY decade ASC

--Generate Decades list
SELECT
generate_series(1920,2020,10) AS decade_start
FROM teams

--Final Query
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


--6. Find the player who had the most success stealing bases in 2016, where __success__ is measured as the percentage of stolen base attempts which are successful. (A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted _at least_ 20 stolen bases.
--batting table, sb = stolen bases, cs = caught stealing
-- percentage = stolen bases/ stolen + caught *100
--join on people table to get player name
WITH stolen AS (
	SELECT b.playerid,
		yearid,
		sb,
		cs  
	FROM batting as b
	WHERE yearid = 2016 AND sb+cs >= 20
	)
SELECT s.playerid,p.namefirst, p.namelast, s.sb, s.cs, ROUND((s.sb::NUMERIC/(s.sb::NUMERIC+s.cs::NUMERIC))*100,2) AS success, s.yearid
FROM stolen AS s
INNER JOIN people AS p
USING (playerid)
ORDER BY success DESC

--7.  From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? What is the smallest number of wins for a team that did win the world series? Doing this will probably result in an unusually small number of wins for a world series champion – determine why this is the case. Then redo your query, excluding the problem year. How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?
--teams table: wswins, 

SELECT teamid,
		yearid,
		w AS wins,
		wswin AS world_series_win
FROM teams
WHERE yearid >= 1970 AND wswin = 'N'
ORDER BY wins DESC
--ANSWER: SEA, with 116 wins.

SELECT teamid,
		yearid,
		w AS wins,
		wswin AS world_series_win
FROM teams
WHERE yearid >= 1970 AND wswin = 'Y'
ORDER BY wins
--ANSWER: LAN, with 63 wins.

SELECT teamid, yearid, w
FROM teams
WHERE yearid = 1981
ORDER BY w DESC






	
