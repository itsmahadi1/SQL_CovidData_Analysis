/*
Project: COVID-19 Data Exploration (SQL Server)

Description:
    This script explores global COVID-19 data, focusing on:
    - Death percentages
    - Infection rates
    - Vaccination progress
    - Rolling totals using window functions

Dataset:
    Our World in Data - COVID-19 Dataset
*/



--To show all unique continent values, but exclude NULLs and empty/blank ones
SELECT DISTINCT continent
FROM dbo.CovidDeaths
WHERE NULLIF(LTRIM(RTRIM(continent)), '') IS NOT NULL;

--To show the possibility of dying if you contract covid in a country
SELECT location, date, total_cases, total_deaths, (CAST(total_deaths AS float) /CAST(total_cases AS float))*100 as DeathPercentage
FROM dbo.CovidDeaths
WHERE location like '%united kingdom%'
and continent IS NOT NULL
ORDER BY 1,2;

--To show what percentage of the population is infected with COVID19 in a country at a particular time.
SELECT location, date, total_cases, population, (CAST(total_deaths AS float) /CAST(population AS float))*100 as Percentage_of_Population_Infected
FROM dbo.CovidDeaths
WHERE location like '%united kingdom%'
and continent IS NOT NULL
ORDER BY 1,2;

--To show the countries with highest number of infection rate in descending order
SELECT location, population, MAX(total_cases) as HighestInfectionCount, MAX(total_cases/population)*100 as PercentPopulationInfected
FROM dbo.CovidDeaths
GROUP BY location, population
ORDER BY PercentPopulationInfected desc;

--To show the countries with highest number of death rate in descending order
SELECT location, MAX(CAST(total_deaths as int)) as TotalDeathCount
FROM dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount desc;

--To show the continents with highest number of death rate in descending order
SELECT continent, MAX(CAST(total_deaths as int)) as TotalDeathCount
FROM dbo.CovidDeaths
WHERE NULLIF(LTRIM(RTRIM(continent)), ' ')  IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount desc;


--To show total COVID cases around the world, total death and Death Percentage
SELECT sum(new_cases) as TotalCases, sum(new_deaths) as TotalDeaths, (sum(new_deaths)/sum(new_cases))*100 as DeathPercentage
FROM dbo.CovidDeaths
WHERE NULLIF(LTRIM(RTRIM(continent)), ' ')  IS NOT NULL
ORDER BY 1,2;

--To show how many people around the world have received at least one vaccine
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, SUM(CONVERT(BIGINT, CAST(cv.new_vaccinations as float))) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) as RollingPeopleVaccinated
FROM CovidData..CovidDeaths cd
JOIN CovidData..CovidVaccinations cv
	on cd.location = cv.location
	and cd.date = cv.date
WHERE CD.continent IS NOT NULL	
order by 2,3

-- Creating Temporary table
DROP TABLE IF EXISTS #Percent_population_Vaccinated
CREATE TABLE #Percent_population_Vaccinated
(
	continent nvarchar(255),
	location nvarchar(255),
	date datetime,
	population numeric,
	new_vaccinations numeric,
	RollingPeopleVaccinated numeric

)
INSERT INTO #Percent_population_Vaccinated
SELECT
    cd.continent,
    cd.location,
    cd.date,
    TRY_CAST(cd.population AS bigint) AS population,
    TRY_CAST(cv.new_vaccinations AS bigint) AS new_vaccinations,
    SUM(
        TRY_CAST(cv.new_vaccinations AS bigint)
    ) OVER (
        PARTITION BY cd.location
        ORDER BY cd.location, cd.date
    ) AS RollingPeopleVaccinated
FROM CovidData..CovidDeaths cd
JOIN CovidData..CovidVaccinations cv
    ON cd.location = cv.location
   AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
ORDER BY 2, 3;

SELECT *, (RollingPeopleVaccinated/population)*100 as Percentage_Vaccinated
FROM #Percent_population_Vaccinated


--To show all the details (data type, length, etc.) of the dataset.
EXEC sp_help CovidDeaths;