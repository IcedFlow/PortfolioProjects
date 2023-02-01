-- Covid-19 data exploration, data extracted 01/30/2023

-- Skills used: Temp tables, views, data type conversion, aggregate functions, calculated fields

SELECT * 
FROM dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3, 4

-- Select data that we will start with

SELECT location, date, total_cases, total_deaths, new_cases, population
FROM dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2

-- Let's look at Total Cases vs. Total Deaths to evaluate lethality
-- Filter by country

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM CovidProject..CovidDeaths 
WHERE location LIKE '%state%'
AND continent IS NOT NULL
ORDER BY 1, 2

-- Now for infection rate (Total Cases vs. Population) 

SELECT location, date, population, total_cases, (total_cases/population)*100 AS PopulationInfected
FROM CovidProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2

-- Countries with highest infection

SELECT location, MAX(total_cases) AS HighestInfection
FROM CovidProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY HighestInfection desc

-- Countries w/ highest death count per population

SELECT location, Max(total_deaths) as DeathCount
FROM CovidProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY DeathCount desc

-- Filtering by continent

-- Continents with highest deaths per population

SELECT continent, MAX(total_deaths) AS TotalDeath
From CovidProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeath desc

-- Global numbers

SELECT date, SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS int)) AS total_deaths, 
SUM(CAST(new_deaths AS int))/SUM(new_cases)*100 AS DeathPercentage
FROM CovidProject..CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY date
ORDER BY 1, 2

-- Total Population vs. Vaccinations

SELECT dea.continent, dea.date, dea.population, vac.new_vaccinations,
SUM(Convert(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location,
dea.date) AS CumulativeVaccination
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3

-- Use CTE

With PopvsVaccs (Continent, Location, Date, Population, New_Vaccination, CumulativeVaccination)
AS 
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(Convert(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location,
dea.date) AS CumulativeVaccination
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2, 3
)
SELECT *, (CumulativeVaccination/Population)*100
FROM PopvsVaccs

-- Temporary Table

CREATE TABLE #PercentOfPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
CumulativeVaccination numeric
)

INSERT INTO #PercentOfPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(Convert(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location,
dea.date) AS CumulativeVaccination
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2, 3

SELECT *, (CumulativeVaccination/Population)*100
FROM #PercentOfPopulationVaccinated

-- Creating view for later visualizations

Create view #PercentOfPopulationVaccinated 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(Convert(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location,
dea.date) AS CumulativeVaccination
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2, 3

SELECT * 
FROM #PercentOfPopulationVaccinated