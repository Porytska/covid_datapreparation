SELECT location, date, total_cases , new_cases, total_deaths, population 
FROM PorfolioProject.dbo.CovidDeaths cd 
ORDER BY 1,2

-- looking at total cases vs total deaths
-- Shows likelihood of dying if you contract covid in your country

SELECT location, date, total_cases, total_deaths, (total_deaths*1.0/total_cases)*100 DeathPercentage
FROM PorfolioProject.dbo.CovidDeaths cd 
WHERE location LIKE '%states%' AND continent is not NULL
ORDER BY 1,2

-- Looking at total caes vs population
-- Shows what % of population got covid

SELECT location, date, population, total_cases, (total_cases*1.0/population)*100 PercentageWithCovid
FROM PorfolioProject.dbo.CovidDeaths cd 
WHERE location LIKE '%states%' AND continent is not NULL 
ORDER BY 1,2

-- Looking at countries with highest infection rate compared to population

SELECT  Location, Population, MAX(total_cases) HighestInfectionCount,  MAX((total_cases*1.0/population))*100 PercentPopulationInfected
FROM PorfolioProject.dbo.CovidDeaths cd 
WHERE continent is not NULL
--Where location like '%states%'
GROUP BY Location, Population
ORDER BY  PercentPopulationInfected desc


-- Showing countries with highest daeth count per population

SELECT Location, MAX(CAST(Total_deaths AS int)) AS TotalDeathCount
FROM PorfolioProject.dbo.CovidDeaths cd 
--Where location like '%states%'
WHERE continent is not NULL
GROUP BY Location
ORDER BY TotalDeathCount DESC

-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population

SELECT continent, MAX(cast(Total_deaths AS int)) AS TotalDeathCount
FROM PorfolioProject.dbo.CovidDeaths cd 
--Where location like '%states%'
WHERE continent is not NULL 
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- Global numbers

SELECT SUM(new_cases) total_cases, SUM(new_deaths) total_deaths, SUM(new_deaths)*1.0/SUM(new_cases)*100 DeathPercentage
FROM PorfolioProject.dbo.CovidDeaths cd 
WHERE continent is not NULL 
--GROUP BY date 
ORDER BY 1,2


-- Use CTE


WITH PopVsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS 
(
-- Looking at total population vs vaccination

SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations
, SUM(CONVERT(int,cv.new_vaccinations)) OVER (PARTITION BY y cd.Location ORDER BY cd.location, cd.Date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM PorfolioProject.dbo.CovidDeaths cd
JOIN PorfolioProject.dbo.CovidVaccinations cv
	ON cd.location = cv.location
	AND cd.date = cv.date
WHERE cd.continent is not null 
--order by 2,3
)

SELECT *, (RollingPeopleVaccinated*1.0/population)*100
FROM PopVsVac

-- temp table

-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations varchar(255),
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations as int)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM PorfolioProject.dbo.CovidDeaths dea
JOIN PorfolioProject.dbo.CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
--WHERE dea.continent is not null 
--ORDER by 2,3

SELECT  *, (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated


-- Creating view to store data for later visualizations


CREATE VIEW VacPercPeople as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM PorfolioProject.dbo.CovidDeaths dea
JOIN PorfolioProject.dbo.CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null 

