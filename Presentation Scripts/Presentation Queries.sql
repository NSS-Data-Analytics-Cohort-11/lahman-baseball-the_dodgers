--How many distinct people in hall of fame?
SELECT COUNT(DISTINCT(playerid))
FROM halloffame
WHERE inducted = 'Y'
--ANSWER: 317

--What country where most hall of famers born in?
SELECT ROUND(100 * COUNT(playerid)/SUM(COUNT(playerid)) over (),2) AS percentage, birthcountry 
FROM people
WHERE playerid IN (SELECT playerid
				  	FROM halloffame
				  WHERE inducted = 'Y')
GROUP BY birthcountry
ORDER BY COUNT(playerid) DESC
--ANSWER: by Percentage
/*
94.32	"USA"
1.26	"Cuba"
1.26	"P.R."
0.95	"United Kingdom"
0.63	"D.R."
0.32	"Germany"
0.32	"Netherlands"
0.32	"CAN"
0.32	"Venezuela"
0.32	"Panama"
*/

--In the USA, what state were most hall of famers born in?
SELECT birthstate,
COUNT(playerid),
ROUND(100 * COUNT(playerid)/SUM(COUNT(playerid)) over (),2) AS percentage,
SUM(COUNT(playerid)) over () AS total_players
FROM people
WHERE playerid IN (SELECT playerid
				  	FROM halloffame
				  	WHERE inducted = 'Y')
AND birthcountry iLIKE 'USA'
GROUP BY birthstate
ORDER BY COUNT(playerid) DESC
--Answer: by count and percentage and totalplayers
/*
"NY"	31	10.37	299
"CA"	24	8.03	299
"PA"	24	8.03	299
"IL"	22	7.36	299
"OH"	19	6.35	299
"TX"	17	5.69	299
"MA"	15	5.02	299
"AL"	12	4.01	299
"MD"	10	3.34	299
"IN"	10	3.34	299
"MO"	10	3.34	299
"IA"	7	2.34	299
"NC"	7	2.34	299
"FL"	7	2.34	299
"OK"	7	2.34	299
"MI"	6	2.01	299
"NE"	6	2.01	299
"GA"	6	2.01	299
"AR"	6	2.01	299
"VA"	5	1.67	299
"WI"	5	1.67	299
"CT"	5	1.67	299
"LA"	4	1.34	299
"KY"	4	1.34	299
"NJ"	3	1.00	299
"WV"	3	1.00	299
"MN"	3	1.00	299
"RI"	3	1.00	299
"WA"	3	1.00	299
"SC"	3	1.00	299
"KS"	2	0.67	299
"TN"	2	0.67	299
"SD"	1	0.33	299
"CO"	1	0.33	299
"MS"	1	0.33	299
"NH"	1	0.33	299
"DE"	1	0.33	299
"ID"	1	0.33	299
"VT"	1	0.33	299
"NM"	1	0.33	299
*/

--What colleges did the hall of famers go to?					
WITH collegeinfo AS (SELECT *
					FROM collegeplaying
					INNER JOIN schools
					USING (schoolid))
SELECT c.schoolname, 
		c.schoolstate,
		COUNT(p.playerid)
FROM people AS p
INNER JOIN collegeinfo AS c
ON p.playerid = c.playerid
WHERE p.playerid IN (SELECT playerid
				  	FROM halloffame
					WHERE inducted = 'Y')
--AND c.schoolstate = 'TN' "to see how many went to school in TN"
GROUP BY c.schoolname, c.schoolstate
ORDER BY COUNT(p.playerid) DESC
--ANSWER:
/*
"St. Bonaventure University"	"NY"	7
"University of Michigan"	"MI"	6
"University of Minnesota"	"MN"	6
"University of Southern California"	"CA"	6
"San Diego State University"	"CA"	5
"University of Alabama"	"AL"	4
"Creighton University"	"NE"	4
"Columbia University"	"NY"	4
"California Polytechnic State University, San Luis Obispo"	"CA"	4
"Baylor University"	"TX"	4
"Eastern Kentucky University"	"KY"	4
"Ohio University"	"OH"	3
"Southern University and A&M College"	"LA"	3
"Seton Hall University"	"NJ"	3
"Concordia Theological Seminary"	"IN"	3
"Florida Agricultural and Mechanical University"	"FL"	3
"Niagara University"	"NY"	3
"Guilford College"	"NC"	3
"Miami University of Ohio"	"OH"	3
"Auburn University"	"AL"	3
"University of Hartford"	"CT"	3
"Miami-Dade College, North Campus"	"FL"	2
"University of Oregon"	"OR"	2
"Michigan State University"	"MI"	2
"Carlisle Indian Industrial School"	"PA"	2
"Dean College"	"MA"	2
"University of Cincinnati"	"OH"	2
"Gettysburg College"	"PA"	2
"Boston University"	"MA"	2
"University of Virginia"	"VA"	2
"Pasadena City College"	"CA"	1
"Triton College"	"IL"	1
"Duquesne University"	"PA"	1
"Loras College"	"IA"	1
"Arizona State University"	"AZ"	1
"University of California, Los Angeles"	"CA"	1
"Bradley University"	"IL"	1
"St. Mary's College of California"	"CA"	1
"Fresno City College"	"CA"	1
"Mansfield University of Pennsylvania"	"PA"	1
"Illinois State University"	"IL"	1
"East Central University"	"OK"	1
"Gulf Coast Community College"	"FL"	1
"University of Delaware"	"DE"	1
"University of Illinois at Urbana-Champaign"	"IL"	1
"Ohio Wesleyan University"	"OH"	1
"Bucknell University"	"PA"	1
"Texas Wesleyan University"	"TX"	1
"Merritt College"	"CA"	1
"Los Angeles Valley College"	"CA"	1
"Dickinson College"	"PA"	1
"University of Miami"	"FL"	1
"Sacred Heart College"	"WI"	1
"Volant College"	"PA"	1
"Pennsylvania State University"	"PA"	1
"Fordham University"	"NY"	1
"Transylvania University"	"KY"	1
"University of New Hampshire"	"NH"	1
*/


--What is the average height and weight of a hall of famer?
SELECT ROUND(AVG(weight),2) AS avg_weight,
	ROUND(AVG(height::INTEGER),2) AS avg_height
FROM people
WHERE playerid IN (SELECT playerid
				  	FROM halloffame
				  WHERE inducted = 'Y')
--ANSWER: 182.20 lbs and 71.46 inches (5.95ft)

--Which side do they bat and/or throw?
WITH right_batters AS (SELECT COUNT(bats) AS rightbat
						FROM people
						WHERE playerid IN (SELECT playerid
				  		FROM halloffame
						WHERE inducted = 'Y')
						AND bats = 'R'),
left_batters AS (SELECT COUNT(bats) AS leftbat
						FROM people
						WHERE playerid IN (SELECT playerid
				  		FROM halloffame
						WHERE inducted = 'Y')
						AND bats = 'L'),
throw_right AS (SELECT COUNT(throws) AS throwright
						FROM people
						WHERE playerid IN (SELECT playerid
				  		FROM halloffame
						WHERE inducted = 'Y')
						AND throws = 'R'),
throw_left AS (SELECT COUNT(throws) AS throwleft
						FROM people
						WHERE playerid IN (SELECT playerid
				  		FROM halloffame
						WHERE inducted = 'Y')
						AND throws = 'L')
			  			

SELECT right_batters.rightbat,
		left_batters.leftbat,
		throw_right.throwright,
		throw_left.throwleft
FROM right_batters
UNION 
SELECT *
FROM left_batters
UNION
SELECT *
FROM throw_right
UNION
SELECT *
FROM throw_left


--SELECT COUNT(rb.bats),
		COUNT(lb.bats),
		COUNT(tr.throws),
		COUNT(tl.throws)
FROM right_batters AS rb
INNER JOIN left_batters AS lb
USING (playerid)
INNER JOIN throw_right AS tr
USING (playerid)
INNER JOIN throw_left AS tl
USING (playerid)



SELECT COUNT(*)
FROM people
WHERE playerid IN (SELECT playerid
				  	FROM halloffame)
AND WHERE bats = 'R'