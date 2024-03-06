-- Is there any correlation between number of wins and team salary? Use data from 2000 and later to answer this question. As you do this analysis, keep in mind that salaries across the whole league tend to increase together, so you may want to look on a year-by-year basis.

------- Team Salaries and Wins by Year ---------------
WITH sw AS
		(SELECT
		 	s.yearid AS year,
			t.name AS team_name,
		 	t.w AS wins,
		 	divwin AS division_win,
		 	wcwin AS wildcard_win,
		 	lgwin AS league_champion,
		 	wswin AS World_Series_win,
			SUM(s.salary) AS team_salary,
			ROUND(AVG(w) OVER(PARTITION BY s.yearid),2) AS avg_wins
		FROM teams AS t
		INNER JOIN salaries AS s
		USING (teamid, yearid)
		WHERE s.yearid >= 2000
		GROUP BY t.name, s.yearid, t.w, divwin,
		 	wcwin,
		 	lgwin,
		 	wswin
		ORDER BY t.name , s.yearid),
--
ranked AS
		(SELECT
			t1.year AS year,
			t1.team_name AS team,
			t2.wins AS previous_wins,
			DENSE_RANK() OVER(PARTITION BY t2.year ORDER BY t2.wins DESC) AS win_rank,
			CASE
				WHEN t2.wins > t2.avg_wins THEN 'Above Average'
				WHEN t2.wins < t2.avg_wins THEN 'Below Average'
				ELSE 'Average' END AS average,
			t2.avg_wins AS previous_avg,
			t2.team_salary AS previous_salary,
			t1.team_salary AS current_salary,
			ROUND((t1.team_salary::NUMERIC - t2.team_salary::NUMERIC)/t2.team_salary::NUMERIC * 100,2) AS salary_change,
		 	t2.division_win,
		 	t2.wildcard_win,
		 	t2.league_champion,
		 	t2.World_Series_win
		FROM sw AS t1
		INNER JOIN sw AS t2
		ON t1.year-1 = t2.year AND t1.team_name = t2.team_name
		ORDER BY year, win_rank)

SELECT *
FROM ranked
WHERE team = 'Chicago White Sox'
ORDER BY year DESC
	


-- In this question, you will explore the connection between number of wins and attendance.
-- Does there appear to be any correlation between attendance at home games and number of wins?
-- Do teams that win the world series see a boost in attendance the following year? What about teams that made the playoffs? Making the playoffs means either being a division winner or a wild card winner.

WITH att AS
		(SELECT
			t.yearid AS year,
			t.name AS team,
			t.park AS ballpark,
			t.w AS wins,
			t.wswin AS World_Series,
			CASE
				WHEN t.divwin = 'Y' OR t.wcwin = 'y' THEN 'Yes'
				ELSE 'No' END AS Playoffs,
			t.attendance AS attendance
		FROM teams AS t
		WHERE yearid >= 2000)

SELECT
	
FROM att as t1
INNER JOIN att as t2
ON t1.year-1 = t2.year AND t1.team = t2.team

-- It is thought that since left-handed pitchers are more rare, causing batters to face them less often, that they are more effective.
-- Investigate this claim and present evidence to either support or dispute this claim.
		--First, determine just how rare left-handed pitchers are compared with right-handed pitchers.
		--Are left-handed pitchers more likely to win the Cy Young Award?
		--Are they more likely to make it into the hall of fame?
