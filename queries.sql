-- MYSQL : DBMS.

USE baseball;

-- Query1
-- LA Dodgers - List the first name and last name of every player that has played at any time in their career for the Los Angeles Dodgers. List each player only once

select nameFirst as FirstName,nameLast as LastName from master where masterID in
(
	select distinct masterID from appearances where teamID in 
		(
			select distinct teamID from teams where name='los angeles dodgers'
		)
)
order by nameLast;


-- Query2
-- Brooklyn AND LA Dodgers Only - List the first name and last name of every player that has played only for the Los Angeles AND Brooklyn Dodgers


create or replace view los1 as
select distinct masterID 
from appearances 
where teamID in 
(
select distinct teamID from teams where name='los angeles dodgers'
)
and 
masterID not in
(
select distinct masterID 
from appearances 
where teamID in 
(
select distinct teamID from teams 
where teamID not in
(
select distinct teamID from teams 
where name='brooklyn dodgers' or name='los angeles dodgers'
)
)
)
;

create or replace view los2 as
select distinct masterID from appearances where teamID in 
(
select distinct teamID from teams where name='brooklyn dodgers'
)
and masterID not in
(
select distinct masterID from appearances where teamID in 
(
select distinct teamID from teams where teamID not in
(
select distinct teamID from teams 
where name='brooklyn dodgers' or name='los angeles dodgers'
)
)
)
;

select nameFirst as FirstName,nameLast as LastName from los1,master 
where los1.masterID=master.masterID and los1.masterID in
	(select masterID from los2)
order by nameLast,nameFirst;


-- Query 3
-- Gold Glove Dodgers - For each Los Angeles Dodger that has won a "Gold Glove" award, list their first name, last name, position (this is the 'notes' field in the 'awardsplayers' table), and year in which the award was won

create or replace view x as
select distinct masterID,yearID from appearances where teamID in 
	(
    select distinct teamID from teams where name='los angeles dodgers'
    );

select distinct nameFirst as FirstName,nameLast as LastName,awardsplayers.yearID as Year,notes as Position 
from awardsplayers,master,x 
where awardsplayers.masterID=master.masterID and awardID = 'Gold Glove' and master.masterID=x.masterID and x.yearID=awardsplayers.yearID 
order by awardsplayers.yearID,nameLast;


-- Query4
-- World Series Winners - List the name of each team that has won the world series and number of world series that it has won

select name as TeamName,count(name) as WorldSeriesWon from teams where WSWin='y' 
group by name
order by count(name),name;


-- Query5
-- USU batters - List the first name, last name, year played, and batting average (h/ab) of every player from the school named "Utah State University"

select H/AB as Average,H as Hits,AB as AtBats,nameFirst as FirstName,nameLast as LastName,batting.yearID as Year from batting,master 
where master.masterID=batting.masterID and batting.masterID in
	(
		select masterID from schools,schoolsplayers where schools.schoolID=schoolsplayers.schoolID and schoolName='Utah State University'
	)
group by batting.masterID,H/AB
order by batting.yearID,nameFirst;


-- Query6
-- Bumper Salary Teams - List the total salary for two consecutive years, team name, and year for every team that had a total salary which was 1.5 times as much as for the previous year.


create or replace view teamsalaries as
select teamID,lgID,yearID,sum(salary) as salary from salaries 
group by teamID,lgID,yearID; 

create or replace view help6 as
select x.teamID,x.lgID,x.yearID as previous_year,x.salary as previous_salary,y.yearID,y.salary,floor((y.salary/x.salary)*100) as Percent_Increase
from teamsalaries x,teamsalaries y 
where x.teamID=y.teamID and x.lgID=y.lgID 
		and y.yearID=x.yearID+1 and y.salary>=x.salary*1.5 ;
        
select distinct name as TeamName,help6.lgID as League,previous_year,previous_salary,help6.yearID as Year,salary,Percent_Increase 
from help6,teams where teams.teamID=help6.teamID
group by previous_year,previous_salary
order by help6.yearID,name;


-- Query 7
-- Red Sox Four - List the first name and last name of every player that has batted for the Boston Red Sox in at least four consecutive years

create or replace view boston as
select distinct masterID,yearID from batting where teamID in 
	(select teamID from teams where name='Boston Red Sox');
    
create or replace view boston1 as    
select x.masterID,x.yearID from boston x,boston y where x.masterID=y.masterID and y.yearID=x.yearID+1;

create or replace view boston2 as    
select x.masterID,x.yearID from boston1 x,boston1 y where x.masterID=y.masterID and y.yearID=x.yearID+1;

create or replace view boston3 as    
select distinct x.masterID from boston2 x,boston2 y where x.masterID=y.masterID and y.yearID=x.yearID+1;

select nameFirst as FirstName,nameLast as LastName from master,boston3 where master.masterID=boston3.masterID
order by nameLast,nameFirst;


-- Query8
-- Home Run Kings - List the first name, last name, year, and number of HRs of every player that has hit the most home runs in a single season


create or replace view hits as
select yearID,max(HR) as maximum from batting group by yearID;

create or replace view maximum as
select masterID,batting.yearID,HR from batting,hits where batting.yearID=hits.yearID and HR=maximum;

select yearID as Year,nameFirst as FirstName,nameLast as LastName,HR as HomeRuns 
from master,maximum where master.masterID=maximum.masterID 
order by yearID,HR,nameLast,nameFirst;


-- Query9
-- Third best home runs each year - List the first name, last name, year, and number of HRs of every player that hit the third most home runs for that year

create or replace view hits9 as
select yearID,max(HR) as maximum1 from batting group by yearID;

create or replace view pre as
select batting.yearID,max(HR) as maximum2 from batting,hits9 where batting.yearID=hits9.yearID and HR != maximum1 group by batting.yearID;

create or replace view final as
select batting.yearID,max(HR) as maximum3 from batting,pre,hits9 where batting.yearID=hits9.yearID and batting.yearID=pre.yearID and HR != maximum2 and HR!=maximum1 group by batting.yearID;

create or replace view Thirdmax as
select masterID,batting.yearID,HR from batting,final where batting.yearID=final.yearID and HR=maximum3;

select nameFirst as FirstName,nameLast as LastName,yearID as Year,HR from master,Thirdmax 
where master.masterID=Thirdmax.masterID order by yearID,nameLast;


-- Query10
-- Triple happy team mates - List the team name, year, players' names, the number of triples hit (column '3B' in the batting table), in which two or more players on the same team hit 10 or more triples each


create or replace view triples as 
select yearID,teamID from batting where 3B>=10 
group by yearID,teamID
having count(*)>=2;

create or replace view triples1 as
select batting.masterid,batting.yearID,batting.teamID,3B  as Triples
from batting,triples
where batting.yearID=triples.yearID and batting.teamID=triples.teamID and 3B>=10
order by yearID,teamID;
 
drop table if exists triples2;
create table triples2 (
row_num int(20),
masterID varchar(250),
yearID int(20),
teamID varchar(250),
Triples int(20)
);

set @row_num=0;
insert into triples2
	SELECT @row_num := @row_num+1
		as row_num,masterID,yearID,teamID,Triples
        from triples1;
        
create or replace view TeamTriples as
select x.yearID as Year,x.teamID as Teamname,x.masterID,x.Triples as Triples,y.masterID as Teammate_masterID,y.Triples as Teammate_Triples
from triples2 x,triples2 y
where x.yearID=y.yearID and x.teamID=y.teamID and x.masterid!=y.masterID and y.row_num>x.row_num
group by x.yearID,x.teamID,x.masterid,y.masterid;

create or replace view help1 as
select t.Year,t.Teamname,nameFirst as Firstname,nameLast as Lastname,t.Triples,t.Teammate_masterID,t.Teammate_Triples from TeamTriples t,master where master.masterID=t.masterID;

select distinct p.Year,name as Team_Name,Firstname,Lastname,p.Triples,nameFirst as Teammate_FirstName,nameLast as Teammate_Last_Name,p.Teammate_Triples
from help1 p,master,teams where p.Teammate_masterID=master.masterID and teams.teamID = p.Teamname
group by p.Year,Firstname,Lastname,p.Triples,nameFirst,nameLast,p.Teammate_Triples
order by p.Year,p.Triples,Teammate_Triples;


-- Query11
-- Ranking the teams - Rank each team in terms of the winning percentage (wins divided by (wins + losses)) over its entire history

create or replace view winview1 as
select name,sum(W) as Wins,sum(L) as Losses,sum(W)/(sum(L)+sum(W)) as Win_Percentage 
from teams 
group by name order by Win_Percentage desc;

select name as TeamName,@cur := @cur+1 as Rank,Win_Percentage,Wins as TotalWins,Losses as TotalLosses 
from winview1,(SELECT @cur := 0) r;


-- Query12
-- Casey Stengel's Pitchers - List the year, first name, and last name of each pitcher who was a on a team managed by Casey Stengel 

create or replace view Caseyteams as
select distinct managers.masterID,nameFirst,nameLast,managers.yearID,managers.teamID from master,managers where managers.masterID=master.masterID and nameFirst='Casey' and nameLast='Stengel';

create or replace view Pitchers as
select pitching.masterID,pitching.yearID,pitching.teamID,nameFirst as Manager_First_Name,nameLast as Manager_Last_Name from pitching,Caseyteams 
	where pitching.teamID=Caseyteams.teamID and pitching.yearID=Caseyteams.yearID;
    
select name as TeamName,pitchers.yearID as Year,nameFirst as Pitcher_First_Name,nameLast as Pitcher_Last_Name,Manager_First_Name,Manager_Last_Name 
from pitchers,master,teams where master.masterID=pitchers.masterID and teams.teamID=pitchers.teamID and teams.yearID=pitchers.yearID
order by pitchers.yearID,Pitcher_Last_Name;


-- Query13
-- Two degrees from Yogi Berra - List the name of each player who appeared on a team with a player that was at one time was a teamate of Yogi Berra


create or replace view Yogi as
select distinct masterID,teamID,yearID from appearances where masterID in
(
select masterID from master where nameFirst='Yogi' and nameLast='Berra'
);

create or replace view Yogi1 as
select distinct appearances.masterID,appearances.teamID,appearances.yearID 
from appearances,Yogi
where appearances.teamID=Yogi.teamID and appearances.yearID=Yogi.yearID and appearances.masterID!=Yogi.masterID;

create or replace view Yogi3 as
select distinct masterID,teamID,yearID from appearances where masterID in
(
select distinct masterID from Yogi1
);

create or replace view Yogi2 as
select distinct appearances.masterID,appearances.teamID,appearances.yearID 
from appearances,Yogi3
where appearances.teamID=Yogi3.teamID and appearances.yearID=Yogi3.yearID;

select distinct nameFirst as FirstName,nameLast as LastName from Yogi2,master where master.masterID=Yogi2.masterID
order by nameLast,nameFirst;


-- Query14
-- Rickey's travels - List all of the teams for which Rickey Henderson did not play


create or replace view Rickey as
select distinct teamID from teams where yearID in
(
select yearID from appearances where masterID in
(
select masterID from master where nameFirst='Rickey' and nameLast='Henderson'
)
)
and teamID not in
(
select distinct teamID from appearances where masterID in
(
select masterID from master where nameFirst='Rickey' and nameLast='Henderson'
)
);

create or replace view Rickey1 as
select distinct teams.teamID,name from teams,Rickey where teams.teamID=Rickey.teamID group by teams.teamID;

select distinct name as TeamName from Rickey1 order by name;