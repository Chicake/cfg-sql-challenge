USE formula1;

-- table with drivers info including their winning record
CREATE TABLE wondrivers AS
SELECT d.driverId, d.surname, d.dob, d.nationality, COUNT(d.driverId) as racetotal, COUNT(r.position=1) as wonamount
FROM drivers d
INNER JOIN results r ON r.driverId = d.driverId
GROUP BY d.driverId;

ALTER TABLE wondrivers
ADD COLUMN wonratio DEC(10,2);

UPDATE wondrivers w
SET w.wonratio = (wonamount/racetotal);

-- Drivers with average position
CREATE TABLE dmeanposition AS
SELECT d.nationality, d.surname, d.dob, AVG(r.position) AS meanposition
FROM drivers d
INNER JOIN results r ON d.driverId = r.driverId
WHERE r.position IS NOT NULL
GROUP BY d.driverId;

-- Drivers with total points
CREATE TABLE pointsdrivers AS
SELECT d.nationality, d.surname, d.dob, SUM(r.points) as totalpoints
FROM drivers d
INNER JOIN results r ON d.driverId = r.driverId
GROUP BY d.driverId;

-- comparing top 5 drivers on all the tables created above

-- absolute win
SELECT surname, wonamount, wonratio 
FROM wondrivers
ORDER BY wonamount desc
limit 5;

-- ratio win
SELECT surname, wonamount, wonratio  
FROM wondrivers
ORDER BY wonratio desc
limit 5;

-- mean position
SELECT surname, meanposition
FROM dmeanposition
ORDER BY meanposition
limit 5;

-- total points
SELECT surname, totalpoints
FROM pointsdrivers
ORDER BY totalpoints desc
limit 5;

-- table with constructors info including their winning record
CREATE TABLE wonconstructors AS
SELECT c.constructorId, c.name, c.nationality, COUNT(c.constructorId) as racetotal, COUNT(r.position=1) as wonamount
FROM constructors c
INNER JOIN results r ON c.constructorId = r.constructorId
GROUP BY c.constructorId;

ALTER TABLE wonconstructors
ADD COLUMN wonratio DEC(10,2);

UPDATE wonconstructors w
SET w.wonratio = (wonamount/racetotal);

-- Constructors with average position
CREATE TABLE cmeanposition AS
SELECT c.nationality, c.name, AVG(r.position) AS meanposition
FROM constructors c
INNER JOIN results r ON c.constructorId = r.constructorId
WHERE r.position IS NOT NULL
GROUP BY c.constructorId;

-- Drivers with total points
CREATE TABLE pointsconstructors AS
SELECT c.nationality, c.name, SUM(r.points) as totalpoints
FROM constructors c
INNER JOIN results r ON c.constructorId = r.constructorId
GROUP BY c.constructorId;

-- comparing top 5 constructors on all the tables created above

-- absolute win
SELECT name, wonamount, wonratio 
FROM wonconstructors
ORDER BY wonamount desc
limit 5;

-- ratio win
SELECT name, wonamount, wonratio  
FROM wonconstructors
ORDER BY wonratio desc
limit 5;

-- mean positon
SELECT name, meanposition
FROM cmeanposition
ORDER BY meanposition
limit 5;

-- total points
SELECT name, totalpoints
FROM pointsconstructors
ORDER BY totalpoints desc
limit 5;

-- reasons they cannot finish the race
SELECT s.statusId, s.status, COUNT(r.statusId) AS totalnumber
FROM status s
INNER JOIN results r ON s.statusId = r.statusId
GROUP BY r.statusId
ORDER BY totalnumber desc;

-- min, max and average time of qualifying time per circuit
CREATE TABLE circuitstest AS
SELECT c.name, c.location, c.country,((q.q1+q.q2+q.q3)/3) AS meanqduration, r.circuitid
FROM qualifying q
INNER JOIN races r 
ON q.raceId = r.raceId
INNER JOIN circuits c
ON r.circuitId = c.circuitId
WHERE q.q3 IS NOT NULL;

CREATE TABLE circuitsduration AS
SELECT c.name, c.location, c.country, c.circuitid, MAX(c.meanqduration) AS maxduration, MIN(c.meanqduration) AS minduration, c.meanqduration
FROM circuitstest c
GROUP BY c.circuitid;

DROP TABLE circuitstest;

-- one big table with all info for researcher
CREATE TABLE forresearcher AS
SELECT r.time AS timefinished, a.year, a.name AS racename, a.date, a.time, a.url, d.surname, d.dob, d.nationality AS drivernationality, c.name AS constructorname, c.nationality AS constructornationality, ci.name AS circuitname
FROM results r
INNER JOIN races a
ON r.raceId = a.raceId
INNER JOIN drivers d
ON d.driverId = r.driverId
INNER JOIN constructors c
ON r.constructorId = c.constructorId
INNER JOIN circuits ci
ON ci.circuitId = a.circuitId
WHERE r.position=1;

-- correlational analysis

-- if codes below does not work, try these
-- SHOW VARIABLES LIKE 'sql_mode';
-- set global sql_mode='';
-- set sql_mode='';

-- correlational analysis conducted by
-- 1. creating table for x and y variable
-- 2. assigning mean of x and y with standard deviation of x for faster calculation
-- 3. apply correlation coefficient equation

-- Does pitstops duration correlate with results (position)?
CREATE TABLE pitstopsVSresults AS
SELECT AVG(p.duration) AS meanduration, p.raceid, p.driverid, p.stopping, r.raceId AS raceid1, r.driverId AS driverid1, r.position
FROM pitstops p
INNER JOIN results r
ON p.raceid=r.raceId AND p.driverid=r.driverId
WHERE r.position IS NOT NULL
GROUP BY p.raceid, p.driverid;

SELECT @ax := avg(meanduration), 
       @ay := avg(position), 
       @div := (stddev_samp(meanduration) * stddev_samp(position))
FROM pitstopsVSresults;

SELECT SUM( (meanduration - @ax) * (position - @ay) ) / ((count(meanduration) -1) * @div) FROM pitstopsVSresults;
-- r = -0.05

-- Does qualifying duration correlate with results (position)?
CREATE TABLE qualifyingVSresults AS
SELECT ((q.q1+q.q2+q.q3)/3) AS meanqduration, q.raceId, q.driverId, r.raceId AS raceId1, r.driverId AS driverId1, r.position
FROM qualifying q
INNER JOIN results r
ON q.raceId=r.raceId AND q.driverId=r.driverId
WHERE r.position IS NOT NULL AND q.q3 IS NOT NULL;

SELECT @ax := avg(meanqduration), 
       @ay := avg(position), 
       @div := (stddev_samp(meanqduration) * stddev_samp(position))
FROM qualifyingVSresults;

SELECT SUM( (meanqduration - @ax) * (position - @ay) ) / ((count(meanqduration) -1) * @div) FROM qualifyingVSresults;
-- r = 0.03

-- Does sprint duration correlate with results (position)?
CREATE TABLE sprintVSresults AS
SELECT s.milliseconds, s.raceId, s.driverId, r.raceId AS raceId1, r.driverId AS driverId1, r.position
FROM sprintresults s
INNER JOIN results r
ON s.raceId=r.raceId AND s.driverId=r.driverId
WHERE r.position IS NOT NULL AND s.milliseconds IS NOT NULL;

SELECT @ax := avg(milliseconds), 
       @ay := avg(position), 
       @div := (stddev_samp(milliseconds) * stddev_samp(position))
FROM sprintVSresults;

SELECT SUM( (milliseconds - @ax) * (position - @ay) ) / ((count(milliseconds) -1) * @div) FROM sprintVSresults;
-- r = 0.17