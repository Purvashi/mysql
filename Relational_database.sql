/* Assignment has got two tables :  'scirt_job' & 'chch_street_address'. In order to reduce redundancy and to have 
associative tables, we will use a range of methds. 
One method is table docompositon where we only fetch useful attributes/ columns of one or more table(s) and form a 
single table to avoid redundancy. For instance: In this worksheet, 'chch_street_address' table is used to form 
'locality_m' and 'route_m'tables. Wherever needed "Joins" have been used in this assignment to achieve table decomposition.
 
Another method is to link the decomposed tables in order to form a relational database. The tables are linked using 
foreign keys.

Four associative tables present in the final model are 'delivery_team_m', 'route_m', 'locality_m' & `scirt_job_m`
Three Foreign keys to link these tables are 
1) locality_id (foreign key constraint is fk_locality_id) : links 'route_m' and 'locality_m' tables
2) delivery_team_id (foreign key constraint is fk_delivery_id) : links `delivery_team_m` and 'script_job_m' tables 
3) route_id (foreign key constraint is fk_route_id) : links 'route_m' and 'script_job_m' tables
*/
CREATE DATABASE  IF NOT EXISTS `assignment_2`; -- create new schema to store new tables
USE `assignment_2`; /* this statement allows us to use 'assignment_2' schema throughout the script. If schema name is
					not mentioned before the table name, 'assignment_2' is selected by default */
                    
/* **********Create Delivery_team table using scirt_job table********* */

DROP TABLE IF EXISTS `delivery_team_m`;
create table delivery_team_m as
(select distinct delivery_team from scirt_jobs_bound.scirt_job order by delivery_team);
-- Primary key is generated to assign ids to all the distinct delivery teams in Christchurch and auto incremented
ALTER TABLE delivery_team_m ADD delivery_team_id INT PRIMARY KEY AUTO_INCREMENT;


/* **********Create locality table using chch_street_address table********* */
DROP TABLE IF EXISTS `locality_m`;
create table locality_m as
(select distinct suburb_locality as locality from scirt_jobs_bound.chch_street_address 
where NOT(suburb_locality <=> "") -- Filter out rows containing blank suburb_locality
order by locality);
-- Primary key is generated to assign ids to all the localities in Christchurch and auto incremented
ALTER TABLE locality_m ADD locality_id INT PRIMARY KEY AUTO_INCREMENT;



/* **********Create route_m table - Import locality_id from 'locality_m' table using joins so locality_id 
could be used as a foreign key to link 'route_m' and 'locality_m' tables********* */
DROP TABLE IF EXISTS `route_m`;
create table route_m as
(select road_name as route, loc.locality_id from scirt_jobs_bound.chch_street_address ch
left join locality_m loc on loc.locality=ch.suburb_locality
where NOT(road_name <=> "") -- Filter out rows containing blank road_name/ route
group by road_name, suburb_locality -- to have distinct rows
order by road_name);

/* route_id is a primary key assigned to unique combinations of route/ road_name and locality_id (locality). route or
road name without locality is useless as more than one locality may have road names with the same names*/
ALTER TABLE route_m ADD route_id INT PRIMARY KEY AUTO_INCREMENT;

-- Add foreign key contraint to link 'route_m' and 'locality_m' tables

ALTER TABLE route_m ADD CONSTRAINT fk_locality_id FOREIGN KEY (locality_id) REFERENCES locality_m(locality_id);




-- Call split_column();  --spit_column procedure is called in 'scirt_jobs_bound_dump' script using this statement. This stored procedure splits 'routes' column of 'scirt_job' table and inserts them into a new table 'temp_table

/* **********Create scirt_job_m table - Import delivery_team_id and route_id from delivery_team_m and route_m
tables respectively so delivery_team_id and route_id could be used as foreign keys ********* */

/* There is no primary key in particular for scirt_job_m like the above three tables. We can use job_id and
route_id as a composite primary key to identify records of `scirt_job_m` table*/

DROP TABLE IF EXISTS `scirt_job_m`;
create table scirt_job_m as
(select tt.job_id as job_id, sj.description as description, sj.start_date as start_date, sj.end_date as end_date, 
r.route_id as route_id, del.delivery_team_id as delivery_team_id -- description, start_date and end_date were imported from scirt_job table by applying a join
from scirt_jobs_bound.temp_table tt
left join scirt_jobs_bound.scirt_job sj on tt.job_id = sj.job_id
left join locality_m loc on loc.locality=sj.locality
inner join delivery_team_m del on del.delivery_team=sj.delivery_team
inner join route_m r on r.route = tt.route 
where r.locality_id= loc.locality_id -- although no column from 'locality_m' table was imported, location_id was used to map appropriate locations with their routes (road names) as two or more routes with the same names may be present in more than one location
group by job_id, route_id -- to have distinct rows
order by job_id);

-- Add foreign key to link 'scirt_job_m' and 'delivery_team_m' tables 
ALTER TABLE scirt_job_m ADD CONSTRAINT fk_delivery_id FOREIGN KEY (delivery_team_id) REFERENCES delivery_team_m(delivery_team_id);

-- Add foreign key to link 'scirt_job_m' and 'route_m' tables 
ALTER TABLE scirt_job_m ADD CONSTRAINT fk_route_id FOREIGN KEY (route_id) REFERENCES route_m(route_id);