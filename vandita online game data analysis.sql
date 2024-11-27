
--- Vandita Data analysis Assignment.

--- Information about the Data
--- We have :
--- User Data : In this user_data table gives information like user_id,games_played and datetime.
 -- Columns:
 -- User_Id: unique id for every user.
 -- Games_Played: number of games played by user at that time.
 -- Datetime: Timestamp			
 SELECT * FROM user_data

 -----------------------------------------------------------------------------------------------------------------

 --- deposit Data : In this table the data is about the amount which are deposit by user.
 -- Columns:
 -- User_Id: unique id for every use.
 -- amount: Amount deposit by user.
 -- Datetime: Timestamp.
 SELECT * FROM deposit_data

 -----------------------------------------------------------------------------------------------------------------
 
 --- Withdrawal Data : In this table the data is about the amount which are deposit by user.
 -- Columns:
 -- User_Id: unique id for every use.
 -- amount: Amount withdrawal		 by user.
 -- Datetime: Timestamp.
 SELECT * FROM withdrawal_data

 -----------------------------------------------------------------------------------------------------------------

 --- Exploring the data 
SELECT 
*
FROM user_data

 SELECT 
 COUNT(*) AS total_records        --> looking for total records
 FROM user_data
 ---> There are 355266 records present in user_data.


SELECT 
*
FROM deposit_data

 SELECT 
 COUNT(*) AS total_records        --> looking for total records
 FROM deposit_data
 ---> There are 17438 records present in deposit_data.


SELECT 
*
FROM withdrawal_data

 SELECT 
 COUNT(*) AS total_records        --> looking for total records
 FROM withdrawal_data
 ---> There are 3566 records present in withdrawal_data.

 --> Data Cleaning :
 -- First we need to lowecase the column names for easier writing the names of the columns.
 -- I will do it by using the "sp_name" stored procedure which are already in the My SQL Server.

EXEC sp_rename 'user_data.User_ID', 'user_id', 'COLUMN';
EXEC sp_rename 'user_data.Games_Played', 'games_played', 'COLUMN';
EXEC sp_rename 'user_data.Datetime', 'datetime', 'COLUMN';
SELECT * FROM user_data


EXEC sp_rename 'deposit_data.User_ID', 'user_id', 'COLUMN';
EXEC sp_rename 'deposit_data.Datetime', 'datetime', 'COLUMN';
EXEC sp_rename 'deposit_data.amount', 'dip_amount', 'COLUMN';
SELECT * FROM deposit_data

EXEC sp_rename 'withdrawal_data.User_ID', 'user_id', 'COLUMN';
EXEC sp_rename 'withdrawal_data.Datetime', 'datetime', 'COLUMN';
EXEC sp_rename 'withdrawal_data.Amount', 'wid_amount', 'COLUMN';
SELECT * FROM withdrawal_data

---> Theres no NULL values in the whole data.

 -----------------------------------------------------------------------------------------------------------------

 ---> Finding the Answers of the Questions.

---> Part A - Calculating loyalty points
--On each day, there are 2 slots for each of which the loyalty points are to be calculated:
--S1 from 12am to 12pm 
--S2 from 12pm to 12am				
--Based on the above information and the data provided answer the following questions:

-- 1. Find Playerwise Loyalty points earned by Players in the following slots:-
--    a. 2nd October Slot S1
--    b. 16th October Slot S2
--    b. 18th October Slot S1
--    b. 26th October Slot S2

--- SOLUTION --->
-- For this i first need to gather the the data like creating slots and computing  
-- Aggregates like, total deposit, total wthdrawal , total no. of wthdrawal etc....


--- i wll create independent cte's for easier reading and debugging

--- slots cte i'm using user_data table for this
WITH slots_cte
AS(
SELECT 
	user_id,
	SUM(games_played) AS total_played_games,
	CASE 
	   WHEN CONVERT(TIME, datetime) BETWEEN '00:00:00' AND '11:59:00' THEN 'slot 1'    --- getting only time in hours and minutes from datetime column
	   ELSE 'slot 2' 
	END AS slots,   --- Creating slots
	(CAST(SUM(games_played) AS FLOAT) * 0.2) AS total_played_games_points
FROM user_data
GROUP BY 
user_id,
CASE 
   WHEN CONVERT(TIME, datetime) BETWEEN '00:00:00' AND '11:59:00' THEN 'slot 1'   
   ELSE 'slot 2' 
END
)
--- creating the temporary table to avoid executing cte everytime.and inserting all the data into
--- temporary table
SELECT *                 
INTO #slots
FROM slots_cte


--- depo-cte its used deposit data for this
WITH depo_cte AS
 (SELECT 
	user_id,
	SUM(dip_amount) AS total_diposit_per_user,
	(CAST(SUM(dip_amount) AS FLOAT) * 0.01) AS deposit_points,
	COUNT(*) AS no_of_deposits
FROM deposit_data
GROUP BY
user_id
)
--- Creating and inserting data at same time
SELECT *
INTO #deposit_points
FROM depo_cte

 --- withdhrawal_cte used withdrawal data for this 
 WITH withdrawal_cte AS (
    SELECT 
        user_id,
       CASE 
            WHEN CONVERT(TIME, datetime) BETWEEN '00:00:00' AND '11:59:59' THEN 'S1'
            ELSE 'S2'
        END AS slots,
        SUM(wid_amount) AS total_withdrawal,
		(CAST(SUM(wid_amount) AS FLOAT) * 0.01) AS withdrawal_points,
        COUNT(*) AS num_withdrawals
    FROM withdrawal_data
    GROUP BY user_id,
            CASE 
               WHEN CONVERT(TIME, datetime) BETWEEN '00:00:00' AND '11:59:59' THEN 'S1'
               ELSE 'S2'
             END
)
--- Creating and inserting data at same time
SELECT *
INTO #withdrawal_points
FROM withdrawal_cte

--- Checking all the tables.

SELECT * FROM #slots
SELECT * FROM #deposit_points
SELECT * FROM #withdrawal_points

--- Calculating all the points and required columns
--- In this query i have joined all the temporary tables 
WITH loyalty_points AS
(SELECT 
s.user_id,
s.slots,
dep.datetime,
COALESCE(d.total_diposit_per_user, 0) AS total_diposit,
COALESCE(w.total_withdrawal, 0) AS total_withdrawal,
COALESCE(d.no_of_deposits, 0) AS no_diposits,
COALESCE(w.num_withdrawals, 0) AS num_withdrawals,
COALESCE(s.total_played_games, 0) AS total_games,
(0.01 * COALESCE(d.total_diposit_per_user, 0)) +
(0.005 * COALESCE(w.total_withdrawal, 0)) +
(0.001 * GREATEST(COALESCE(d.no_of_deposits, 0) - COALESCE(w.total_withdrawal, 0), 0)) +
(0.2 * COALESCE(s.total_played_games, 0)) AS total_loyalty_points
FROM #slots AS s
FULL OUTER JOIN #deposit_points AS d
ON s.user_id = d.user_id
FULL OUTER JOIN #withdrawal_points AS w
ON d.user_id = w.user_id
FULL OUTER JOIN deposit_data AS dep
ON w.user_id = dep.user_id
)
--- Result of this cte is stored in another temporary table
SELECT *
INTO #loyalty_points
FROM loyalty_points


--- Getting the final result
SELECT 
user_id,
total_loyalty_points,
datetime,
slots
FROM #loyalty_points
WHERE slots = 'slot 1' AND CONVERT(DATE, datetime) IN('2022-10-02','2022-10-10')
  OR  slots = 'slot 2' AND CONVERT(DATE, datetime) IN('2022-10-16','2022-10-26')
ORDER BY total_loyalty_points DESC



-- 2. Calculate overall loyalty points earned and rank players on the basis of loyalty points in the month of October. 
--    In case of tie, number of games played should be taken as the next criteria for ranking.
--- SOLUTION --->

SELECT 
user_id,
datetime,
total_games,
total_loyalty_points,
rankings
FROM
-- created subquery to gather data
(SELECT  *,
DENSE_RANK() OVER(ORDER BY total_loyalty_points DESC, total_games DESC ) AS rankings
FROM #loyalty_points
WHERE CONVERT(DATE,datetime) BETWEEN '2022-10-01' AND '2022-10-31'
) AS t1
WHERE user_id IS NOT NULL 
AND   slots IS NOT NULL
ORDER BY rankings ASC


 
-- 3. What is the average deposit amount?
--- SOLUTION --->

SELECT 
user_id,
SUM(dip_amount) / COUNT(DISTINCT user_id) avg_diposit_amount
FROM deposit_data
GROUP BY user_id
ORDER BY avg_diposit_amount DESC



-- 4. What is the average deposit amount per user in a month?
--- SOLUTION --->

SELECT 
user_id,
SUM(dip_amount) / COUNT(DISTINCT user_id) avg_diposit_amount,
DATEPART(MONTH,datetime) AS months
FROM deposit_data
GROUP BY 
user_id,
DATEPART(MONTH,datetime)
ORDER BY avg_diposit_amount DESC



-- 5. What is the average number of games played per user? 
--- SOLUTION --->

SELECT 
user_id,
SUM(games_played) / COUNT(DISTINCT user_id) AS avg_played_games
FROM user_data
GROUP BY 
user_id
ORDER BY avg_played_games DESC


-- Part B - How much bonus should be allocated to leaderboard players?
--- SOLUTION --->

-- My Suggestion is that we should allocate this Bonus amount on the basis of Loyalty points
-- As we calculate loyalty points on the basis of deposits, withdrawals and number of games played,
-- As it covers all the aspects.
-- First we can calculate total loyalty points then we calculate loyalty points per user.
-- After this we calculate loyalty point percentage of the users
-- On the basis of loyalty point percentage we can give bonus to the users.

--- I allready calulated loyalty points of the user and created separate temporary table 
--> #loyalty_points
-- i will select top 50 users from #loyalty_points according yo highest loyalty points.

-- Beacuse of the slots and datetime the loyalty points data has many dulicates so
-- first i will remove all the duplicates and remaninig top 50 playres i will rank them 

SELECT * 
INTO #top_players
FROM
(
SELECT 
user_id,
total_loyalty_points,
ROW_NUMBER() OVER(PARTITION BY user_id  ORDER BY total_loyalty_points DESC) AS rankings
FROM #loyalty_points
WHERE user_id IS NOT NULL
   AND user_id > 0
) AS t1
WHERE rankings = 1

--- this is our leaderboard
--- I will save this into another temporary table #leaderboard.

SELECT TOP 50 
user_id,
total_loyalty_points,
player_ranking
INTO #leaderboard
FROM 
(SELECT *,
DENSE_RANK() OVER(ORDER BY total_loyalty_points DESC) AS player_ranking
FROM #top_players
) AS t2


---> final Results
 SELECT 
    user_id,
    total_loyalty_points,
    ROUND(CAST(total_loyalty_points AS FLOAT) / (SELECT SUM(total_loyalty_points) FROM #leaderboard ) * 50000,2) AS bonus
FROM #leaderboard


-- Part C
--Q.Would you say the loyalty point formula is fair or unfair ?
--- SOLUTION --->

--1.First of all The fairness of the loyalty point formula depends on the company's goals and how well it incentivizes desired player behaviors.
-- but from the analysis i have observed that the users who has deposit lot of times are getting
-- more weightage while calculating loyalty points. 
-- Players who spend more are rewarded more, but this might disproportionately benefit high spenders over more consistent, active players.

--2.From the top 50 players the users with highest loyalty points are the users who made lot of 
-- deposit transaction and they played games very little.
-- MEANS Players with high deposits will likely dominate the leaderboard, even if their engagement (games played) is low.



--Q. Can you suggest any way to make the loyalty point formula more robust?		
--- SOLUTION --->
-- I will suggest to do some changes in loyalty point formula 
--There is some changes needs to done in weightage to give all the players same advantage.
-- Like Decrease the weight of deposit points and Increase the weight of games played in the
-- loyalty point calculation to better reward consistent engagement.