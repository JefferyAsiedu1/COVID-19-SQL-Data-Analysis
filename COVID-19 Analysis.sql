--COVID-19 DATA ANALYSIS

--TEST QUERIES TO CHECK IF EXCEL DATA UPLOADED CORRECTLY
SELECT *
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4

SELECT *
FROM CovidVaccinations
WHERE continent IS NOT NULL

--CHANGE DATA TYPE TO INTEGER AND CHECK IF IT WORKED
ALTER TABLE dbo.CovidDeaths
ALTER COLUMN total_cases int

EXEC sp_help CovidDeaths

-- SELECT DATA WE ARE GOING TO START WITH
SELECT Location, 
date, 
total_cases, 
new_cases, 
total_deaths, 
population
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country
SELECT Location, 
date,
total_deaths, 
total_cases,
(total_deaths/total_cases)*100 AS Percentage_Death
FROM CovidDeaths
WHERE location LIKE '%states%' AND continent IS NOT NULL
ORDER BY 1,2

-- Total Cases vs Population
-- Shows what percentage of population infected with Covid
SELECT Location, 
date, 
Population, 
total_cases,  
(total_cases/population)*100 AS PercentPopulationInfected
FROM CovidDeaths
ORDER BY 1,2

-- Countries with Highest Infection Rate compared to Population
SELECT Location, 
Population, 
MAX(total_cases) as HighestInfectionCount,  
Max((total_cases/population))*100 AS PercentPopulationInfected
From CovidDeaths
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC

-- Countries with Highest Death Count per Population
SELECT Location, 
MAX(cast(Total_deaths as int)) AS TotalDeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY Location
ORDER BY TotalDeathCount DESC

-- ANALYSIS BY CONTINENT
-- Contintents with the highest death count per population
SELECT continent, 
MAX(cast(Total_deaths as int)) AS TotalDeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- GLOBAL NUMBERS
SELECT SUM(cast(new_cases as int)) AS total_cases, 
SUM(cast(new_deaths as int)) AS total_deaths, 
SUM(cast(new_deaths as int))/SUM(New_Cases)*100 AS DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine
SELECT dea.continent, 
dea.location, 
dea.date, 
dea.population, 
vac.new_vaccinations, 
SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM CovidDeaths dea
INNER JOIN CovidVaccinations vac
	ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

-- Using CTE to perform Calculation on Partition By in previous query
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
SELECT 
dea.continent, 
dea.location, 
dea.date, 
dea.population, 
vac.new_vaccinations, 
SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM CovidDeaths dea
INNER JOIN CovidVaccinations vac
	On dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
)
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PopvsVac

-- Using Temp Table to perform Calculation on Partition By in previous query
DROP TABLE IF EXISTS #PercentPopulationVaccinated
Create TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, 
dea.location, 
dea.date, 
dea.population, 
vac.new_vaccinations, 
SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location ORDER BY dea.location, dea.Date) as RollingPeopleVaccinated
FROM CovidDeaths dea
INNER JOIN CovidVaccinations vac
	ON dea.location = vac.location AND dea.date = vac.date

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated

-- Creating View to store data for later visualizations
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, 
dea.location, 
dea.date, 
dea.population, vac.new_vaccinations, 
SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL