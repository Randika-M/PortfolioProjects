SELECT *
FROM 
 PortfolioProject..CovidDeaths$
WHERE
 continent is not null
ORDER BY 3,4

--SELECT *
--FROM PortfolioProject..CovidVaccinations$
--ORDER BY 3,4

-- Select data that we are going to be using.


SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths$


-- Looking at Total cases vs total deaths
-- Show the liklihood of dying if you contract Covid in your country 
SELECT 
 location, 
 date, 
 total_cases, 
 new_cases, 
 total_deaths, 
CASE 
  WHEN TRY_CONVERT(decimal(18, 2), total_cases) = 0 THEN NULL -- Handle division by zero
  ELSE TRY_CONVERT(decimal(18, 2), total_deaths) * 100 / TRY_CONVERT(decimal(18, 2), total_cases)
  END AS death_percentage
FROM PortfolioProject..CovidDeaths$
WHERE LOCATION like '%Australia%'
ORDER BY 1,2


-- Looking at total cases vs population
SELECT 
 location, 
 date, 
 total_cases, 
 population, 
CASE 
  WHEN TRY_CONVERT(decimal(18, 2), total_cases) = 0 THEN NULL -- Handle division by zero
  ELSE TRY_CONVERT(decimal(18, 2), total_cases) * 100 / TRY_CONVERT(decimal(18, 2), population)
  END AS Cases_vs_location
FROM PortfolioProject..CovidDeaths$
--WHERE LOCATION like '%Australia%'
ORDER BY 1,2

-- Looking at countries with higest infection rate compared to population
SELECT 
 location, 
 MAX(total_cases) as HighestInfectionCount, 
 population, 
 Max(CASE 
  WHEN TRY_CONVERT(decimal(18, 2), total_cases) = 0 THEN NULL -- Handle division by zero
  ELSE TRY_CONVERT(decimal(18, 2), total_cases) * 100 / TRY_CONVERT(decimal(18, 2), population)
  END) AS PercentpopulationInfected
FROM PortfolioProject..CovidDeaths$
--WHERE LOCATION like '%Australia%'
GROUP BY 
  location, 
  population
ORDER BY 
  PercentpopulationInfected desc

-- Showing the countries with highest death count per population.
SELECT 
 location, 
 MAX(cast(total_deaths as int)) AS TotalDeathcount
FROM PortfolioProject..CovidDeaths$
--WHERE LOCATION like '%Australia%'
WHERE
 continent is not null
GROUP BY 
 location 
ORDER BY 
 TotalDeathcount desc 

-- Let's break things down by continent 
 -- Showing the continets with the higest death count per population. 
SELECT 
 location, 
 MAX(cast(total_deaths as int)) AS TotalDeathcount
FROM PortfolioProject..CovidDeaths$
--WHERE LOCATION like '%Australia%'
WHERE
 continent is null
 AND location NOT IN ('High income', 'Upper middle income', 'Low income','Lower middle income')
GROUP BY 
 location
ORDER BY 
 TotalDeathcount desc 

 --Alternative code 
 SELECT 
 continent, 
 MAX(cast(total_deaths as int)) AS TotalDeathcount
FROM PortfolioProject..CovidDeaths$
--WHERE LOCATION like '%Australia%'
WHERE
 continent is not null
GROUP BY 
 continent
ORDER BY 
 TotalDeathcount desc 

 --GLOBAL NUMBERS

SELECT 
 SUM(new_cases) AS total_cases, 
 SUM(cast(new_deaths as int)) AS total_deaths, 
 SUM(cast(new_deaths as int))/SUM(new_cases)*100 AS deathpercentage
FROM PortfolioProject..CovidDeaths$
--WHERE LOCATION like '%Australia%'
WHERE
 continent is not null
--GROUP BY date
ORDER BY 1,2


--Looking at Total Population vs Vaccinations
SELECT 
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM 
    PortfolioProject..CovidDeaths$ dea
JOIN 
    PortfolioProject..CovidVaccinations$ vac ON dea.location = vac.location AND dea.date = vac.date
WHERE 
    dea.continent IS NOT NULL 
ORDER BY
    2, 3


-- USE CTE
WITH 
 PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS
 (
SELECT 
 dea.continent,
 dea.location,
 dea.date,
 dea.population,
 vac.new_vaccinations,
 SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.location order by dea.location, dea.date) AS RollingPeopleVaccinated
FROM 
 PortfolioProject..CovidDeaths$ dea
 JOIN 
 PortfolioProject..CovidVaccinations$ vac
ON
 dea.location = vac.location
 and dea.date = vac.date
WHERE 
 dea.continent IS NOT NULL
--ORDER BY
 --2,3
 ) 
SELECT * 
 , (RollingPeopleVaccinated/population)*100
FROM
 PopvsVac
ORDER BY 
 location,date


 -- TEMP TABLE

 -- Drop the existing temporary table if it exists
DROP TABLE IF EXISTS #PercentPopulationVaccinated
 Create Table #PercentPopulationVaccinated
 (
 continent nvarchar(255),
 location nvarchar(255),
 date datetime, 
 population numeric,
 new_vaccinations numeric, 
 RollingPeopleVaccinated numeric
 )
 Insert into #PercentPopulationVaccinated
 SELECT 
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM 
    PortfolioProject..CovidDeaths$ dea
JOIN 
    PortfolioProject..CovidVaccinations$ vac ON dea.location = vac.location AND dea.date = vac.date
WHERE 
    dea.continent IS NOT NULL 
--ORDER BY
   -- 2, 3
SELECT * 
 , (RollingPeopleVaccinated/population)*100
FROM
 #PercentPopulationVaccinated
ORDER BY 
 location,date


 --CREATE A VIEW
 DROP VIEW IF EXISTS PercentPopulationVaccinated
 GO

 CREATE VIEW PercentPopulationVaccinated AS
 SELECT 
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM 
    PortfolioProject..CovidDeaths$ dea
JOIN 
    PortfolioProject..CovidVaccinations$ vac ON dea.location = vac.location AND dea.date = vac.date
WHERE 
    dea.continent IS NOT NULL 
--ORDER BY
    --2, 3


-- Using view for further analysis. You can use the new table for queries. 
SELECT * 
FROM 
 PercentPopulationVaccinated
