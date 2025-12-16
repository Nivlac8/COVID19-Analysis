/*
Covid 19 Data Exploration 
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

-- 1. Select Data that we are going to be using
-- This grabs the essential columns and sorts them by country and date
SELECT 
    location, 
    date, 
    total_cases, 
    new_cases, 
    total_deaths, 
    population
FROM 
    covid_data
ORDER BY 
    1, 2;


-- 2. Looking at Total Cases vs Total Deaths
-- Shows the likelihood of dying if you contract covid in your country
-- We are filtering for India here, but you can replace '%India%' with any country name
SELECT 
    location, 
    date, 
    total_cases, 
    total_deaths, 
    (total_deaths / total_cases) * 100 as DeathPercentage
FROM 
    covid_data
WHERE 
    location like '%India%'
ORDER BY 
    1, 2;
    -- 3. Looking at Total Cases vs Population
-- Shows what percentage of the population got Covid
SELECT 
    location, 
    date, 
    population, 
    total_cases, 
    (total_cases / population) * 100 as PercentPopulationInfected
FROM 
    covid_data
WHERE 
    location like '%India%'
ORDER BY 
    1, 2;
    -- 4. Looking at Countries with Highest Infection Rate compared to Population
-- Identifies which countries have the highest percentage of their population infected
SELECT 
    location, 
    population, 
    MAX(total_cases) as HighestInfectionCount,  
    MAX((total_cases / population)) * 100 as PercentPopulationInfected
FROM 
    covid_data
GROUP BY 
    location, population
ORDER BY 
    PercentPopulationInfected DESC;
    -- 5. Showing Countries with Highest Death Count per Population
-- We filter out rows where the continent is null because those rows represent whole continents/regions
-- We use CAST() to ensure 'total_deaths' is treated as a number, not text
SELECT 
    location, 
    MAX(CAST(total_deaths AS SIGNED)) as TotalDeathCount
FROM 
    covid_data
WHERE 
    continent IS NOT NULL
GROUP BY 
    location
ORDER BY 
    TotalDeathCount DESC;
    DESCRIBE covid_data;
    -- 5. Showing Countries with Highest Death Count per Population
-- (Modified: Removing continent filter as column is missing)
SELECT 
    location, 
    MAX(total_deaths) as TotalDeathCount
FROM 
    covid_data
GROUP BY 
    location
ORDER BY 
    TotalDeathCount DESC;
    -- 6. Global Numbers
-- We sum up new_cases and new_deaths from all countries to get global stats per day
-- We exclude 'World' to prevent double-counting
SELECT 
    date, 
    SUM(new_cases) as total_cases, 
    SUM(new_deaths) as total_deaths, 
    (SUM(new_deaths)/SUM(new_cases))*100 as DeathPercentage
FROM 
    covid_data
WHERE 
    location != 'World'
GROUP BY 
    date
ORDER BY 
    1, 2;
    -- 7. Task 1: Running Totals using Window Functions
-- We use SUM() OVER() to calculate a rolling count of cases
-- PARTITION BY location: recycles the counter when the country changes
-- ORDER BY date: ensures the sum accumulates chronologically
SELECT 
    location, 
    date, 
    new_cases, 
    SUM(new_cases) OVER (PARTITION BY location ORDER BY date) as RollingPeopleInfected
FROM 
    covid_data
WHERE 
    location != 'World'
ORDER BY 
    1, 2;
    -- 8. Task 2: Ranking Countries by Death Rate in 2021
-- We use a CTE named 'Stats2021' to get the final cumulative numbers for the year
-- Then we use DENSE_RANK() to assign a rank based on the calculated Death Rate

WITH Stats2021 AS (
    SELECT 
        location,
        MAX(total_cases) as YearEndCases,
        MAX(total_deaths) as YearEndDeaths
    FROM 
        covid_data
    WHERE 
        YEAR(date) = 2021 
        AND location != 'World'
    GROUP BY 
        location
)
SELECT 
    location,
    YearEndCases,
    YearEndDeaths,
    (YearEndDeaths / YearEndCases) * 100 as DeathRate,
    DENSE_RANK() OVER (ORDER BY (YearEndDeaths / YearEndCases) * 100 DESC) as Rank_2021
FROM 
    Stats2021
ORDER BY 
    Rank_2021;
    -- 9. Task 3: Compare Today vs Yesterday (LAG)
-- We use LAG(new_cases) to fetch the previous day's value into the current row
-- This allows us to see if cases are increasing or decreasing day-over-day
SELECT 
    location, 
    date, 
    new_cases as Today_Cases,
    LAG(new_cases) OVER (PARTITION BY location ORDER BY date) as Previous_Day_Cases,
    (new_cases - LAG(new_cases) OVER (PARTITION BY location ORDER BY date)) as Daily_Change
FROM 
    covid_data
WHERE 
    location != 'World'
ORDER BY 
    1, 2;
    -- 9 (Fixed). Task 3: Compare Today vs Yesterday (LAG) - Optimized
SELECT 
    location, 
    date, 
    new_cases as Today_Cases,
    LAG(new_cases) OVER (PARTITION BY location ORDER BY date) as Previous_Day_Cases,
    (new_cases - LAG(new_cases) OVER (PARTITION BY location ORDER BY date)) as Daily_Change
FROM 
    covid_data
WHERE 
    location = 'India'  -- Filtering to reduce load
ORDER BY 
    date;
    -- 10. Creating a View to store data for later visualizations
-- A View is a virtual table based on the result-set of an SQL statement.
CREATE VIEW PercentPopulationInfectedView AS
SELECT 
    location, 
    date, 
    population, 
    total_cases, 
    (total_cases / population) * 100 as PercentPopulationInfected
FROM 
    covid_data
WHERE 
    location != 'World';
    