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
ON appearances.teamid = teams.teamid
WHERE height IS NOT NULL
GROUP BY people.playerid ,namefirst, namelast, name
ORDER BY height
LIMIT 1;
--2.B-C: 52 appearances, and played for St. Louis Browns

--3. A. Find all players in the database who played at Vanderbilt University. 
--3. B.Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues. 
--3. C. Sort this list in descending order by the total salary earned. 
--3. D Which Vanderbilt player earned the most money in the majors?

	Select
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
	ORDER BY total_salary DESC
--Answer: Above query - possibly ~$80mil?

select *
from salaries
where playerid = priceda1

priceda1
	
