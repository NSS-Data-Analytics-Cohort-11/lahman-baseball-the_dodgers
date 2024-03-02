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
--ANSWER: Chris Owings, 91.30%

--7.  A.From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? 
--teams table: wswins, 

SELECT teamid,
		yearid,
		w AS wins,
		wswin AS world_series_win
FROM teams
WHERE yearid >= 1970 AND wswin = 'N'
ORDER BY wins DESC
--ANSWER: SEA, with 116 wins.

-- 7. B.What is the smallest number of wins for a team that did win the world series? Doing this will probably result in an unusually small number of wins for a world series champion – determine why this is the case. 
SELECT teamid,
		yearid,
		w AS wins,
		wswin AS world_series_win
FROM teams
WHERE yearid >= 1970 AND wswin = 'Y'
ORDER BY wins
--ANSWER: LAN, with 63 wins in 1981

SELECT teamid, yearid, w -- problem year
FROM teams
WHERE yearid = 1981
ORDER BY w DESC

--7. C.Then redo your query, excluding the problem year. 
SELECT teamid,  --filtered out 1981
		yearid,
		w AS wins,
		wswin AS world_series_win
FROM teams
WHERE yearid >= 1970 
	AND yearid != 1981
	AND wswin = 'Y'
ORDER BY wins
--Answer: SLN, with 83 wins in 2006

--7. D.How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?

WITH maxwins AS (
	SELECT yearid,MAX(w) AS maxnumwins
	FROM teams
	WHERE yearid BETWEEN 1970 AND 2016
	GROUP BY yearid
	ORDER BY yearid ASC
), 
numseasons AS (
	SELECT COUNT(DISTINCT yearid) AS numgame
	FROM teams
	WHERE yearid BETWEEN 1970 AND 2016
), 
teamswswin AS (
	SELECT COUNT(*) AS twswin
	FROM teams
	INNER JOIN maxwins
	ON maxwins.yearid = teams.yearid AND maxwins.maxnumwins = teams.w
	WHERE wswin = 'Y'
)
SELECT CONCAT(ROUND((teamswswin.twswin)::NUMERIC/(numseasons.numgame)::NUMERIC * 100,2),'%')
FROM teamswswin, numseasons
--Answer: 25% of the time


--8. A. Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance per game in 2016 (where average attendance is defined as total attendance divided by number of games). Only consider parks where there were at least 10 games played. Report the park name, team name, and average attendance. Repeat for the lowest 5 average attendance.

(SELECT teams.name,
	park_name,
	homegames.attendance/games AS avg_attendance
FROM homegames
INNER JOIN parks
	USING (park)
INNER JOIN teams
	ON homegames.team = teams.teamid AND homegames.year = teams.yearid
WHERE year = 2016 
	AND games >= 10
ORDER BY avg_attendance DESC
LIMIT 5)
UNION ALL
(SELECT teams.name,
	park_name,
	homegames.attendance/games AS avg_attendance
FROM homegames
INNER JOIN parks
	USING (park)
INNER JOIN teams
	ON homegames.team = teams.teamid AND homegames.year = teams.yearid
WHERE year = 2016 
	AND games >= 10
ORDER BY avg_attendance
LIMIT 5)

--Answer: Above query, found top average attendance and bottom average attendance and unioned the limited results from each query. Joined on parks and teams to get park name and team name.

--9. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? Give their full name and the teams that they were managing when they won the award.
				 
WITH al_winners AS (SELECT * --list of managers who have won in AL
				FROM awardsmanagers
				INNER JOIN people
				USING (playerid)
				INNER JOIN managers
				USING (playerid, yearid, lgid)
				INNER JOIN teams
				USING (teamid, yearid)
				WHERE awardid iLIKE '%TSN%'
				AND awardsmanagers.lgid IN ('AL')
				 ),

nl_winners AS (SELECT * --list of managers who have won in AL
				FROM awardsmanagers
				INNER JOIN people
				USING (playerid)
				INNER JOIN managers
				USING (playerid, yearid, lgid)
				INNER JOIN teams
				USING (teamid, yearid)
				WHERE awardid iLIKE '%TSN%'
				AND awardsmanagers.lgid IN ('NL')
				 )

SELECT *
FROM al_winners
INNER JOIN nl_winners
USING(playerid)

--corect query
WITH allof AS (
			SELECT playerid,awardid,yearid,lgid
			FROM awardsmanagers
			WHERE awardid LIKE 'TSN%' AND lgid LIKE 'NL'
		UNION
			SELECT playerid,awardid,yearid,lgid
			FROM awardsmanagers
			WHERE awardid LIKE 'TSN%' AND lgid LIKE 'AL'
			),
nl AS (
		SELECT playerid,awardid,yearid,lgid
		FROM awardsmanagers
		WHERE awardid LIKE 'TSN%' AND lgid LIKE 'NL'
		), 
al AS (
		SELECT playerid,awardid,yearid,lgid
		FROM awardsmanagers
		WHERE awardid LIKE 'TSN%' AND lgid LIKE 'AL'
		), 
winners AS (
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

--10. Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. Report the players' first and last names and the number of home runs they hit in 2016.

/*SELECT p.namefirst,
		p.namelast,
		b.playerid,
		SUM(b.hr)
FROM batting AS b
INNER JOIN people AS p
USING (playerid)
WHERE b.yearid = 2016
	AND b.hr >= 1
GROUP BY p.namefirst,
		p.namelast,
		b.playerid
	
SELECT p
		finalgame::DATE-debut::DATE,
FROM batting
INNER JOIN people 
--first attempts, did not get to work on
*/

--Jessica's code from review:
SELECT
    p.namefirst || ' ' || p.namelast AS player_name,
    b.hr AS home_runs_2016
FROM batting AS b
INNER JOIN people AS p ON b.playerID = p.playerid
WHERE b.yearid = 2016
	AND hr > 0
	AND EXTRACT(YEAR FROM debut::date) <= 2016 - 9
    AND b.hr = (
        SELECT MAX(hr)
        FROM batting
        WHERE playerid = b.playerid)
ORDER BY home_runs_2016 DESC;

--Derek's code from review:
WITH highest_2016 AS
				/* return playerid and number of home runs if max was in 2016 */
			(SELECT  playerid,
						/* return hr when 2016 AND player hit their max hr */
						CASE WHEN hr = MAX(hr) OVER (PARTITION BY playerid) AND yearid = 2016 THEN hr
								END AS career_highest_2016
				FROM batting
				GROUP BY playerid, hr, yearid
				ORDER BY playerid)

SELECT  p.namefirst || ' ' || p.namelast AS name,
		h.career_highest_2016 AS num_hr
FROM highest_2016 AS h
LEFT JOIN people AS p
	ON h.playerid = p.playerid
WHERE h.career_highest_2016 IS NOT NULL
	AND h.career_highest_2016 > 0
	AND DATE_PART('year', p.debut::DATE) <= 2007
ORDER BY num_hr DESC;

 



	
