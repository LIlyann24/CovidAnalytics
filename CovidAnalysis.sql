use [Covid Database]
go

-- 1.Rolling People Vaccinated per Location and Date

SELECT dea.continent, dea.location, dea.date, dea.population
, MAX(CONVERT(bigint,vac.total_vaccinations)) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM CovidDeathNew dea
JOIN CovidVaccinationNew vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null 
GROUP BY dea.continent, dea.location, dea.date, dea.population
ORDER BY 5 DESC




-- 2. Global Numbers

SELECT SUM(new_cases) as total_cases,
		SUM(CAST(new_deaths as int)) as total_deaths,
		SUM(CAST(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
FROM CovidDeathNew
WHERE continent is not null 
ORDER BY 1,2


-- 3. Total Death per Continents

SELECT location,
SUM(CAST(new_deaths as int)) as TotalDeathCount,
SUM(new_cases) as total_cases
FROM CovidDeathNew
--WHERE location like '%states%'
WHERE continent is null 
and location not in ('World', 'European Union', 'International')
and location not like '%income%'
GROUP BY location
ORDER BY TotalDeathCount DESC



-- 4. Highest Infection Count vs Infected Rate per Location

SELECT Location, Population,
	MAX(total_cases) as HighestInfectionCount,
	MAX((total_cases/population))*100 as PercentPopulationInfected
FROM CovidDeathNew
WHERE continent is not null 
GROUP BY Location, Population
ORDER BY 4 DESC



-- 5. DeathRate per Location and Date
SELECT location, date,
	SUM(new_cases) as total_cases,
	SUM(CAST(new_deaths as int)) as total_deaths,
    CASE 
        WHEN SUM(new_cases) > 0 THEN (SUM(CAST(new_deaths as int)) / SUM(new_cases)) * 100
        ELSE 0
    END as DeathPercentage
FROM CovidDeathNew
WHERE continent is not null 
GROUP BY location, date
ORDER BY 5 DESC



-- 6. Vaccination per location/date
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
    SELECT 
        dea.continent, 
        dea.location, 
        dea.date, 
        dea.population, 
        vac.new_vaccinations,
        SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
    FROM 
        CovidDeathNew dea
    JOIN 
        CovidVaccinationNew vac ON dea.location = vac.location AND dea.date = vac.date
    WHERE 
        dea.continent IS NOT NULL
		and dea.location not like '%income%'
)
SELECT 
    *, (RollingPeopleVaccinated * 100.0 / Population) AS PercentPeopleVaccinated
FROM 
    PopvsVac;



-- 7. Infected Rate and highest infected count per location and date
SELECT Location,Population,date,
	MAX(total_cases) as HighestInfectionCount,
	MAX((total_cases/population))*100 as PercentPopulationInfected
FROM CovidDeathNew
WHERE location not like '%income%'
GROUP BY Location, Population, date
ORDER BY PercentPopulationInfected desc



-- Economic side
-- 8. Economic level(income level) infected rate vs death rate vs vaccination rate.
SELECT dea.location AS income_level, 
	dea.population,
	Max((dea.total_cases/dea.population))*100 as PercentPopulationInfected,
	Max((dea.total_deaths/dea.population))*100 as PercentPopulationDeaths,
    CASE 
        WHEN SUM(dea.new_cases) > 0 THEN (SUM(CAST(dea.new_deaths as bigint)) / SUM(dea.new_cases)) * 100
        ELSE 0
    END as DeathPercentage
FROM CovidDeathNew AS dea
JOIN CovidVaccinationNew AS vac
ON dea.location = vac.location
WHERE dea.location like '%income%'
GROUP BY dea.location, dea.population



--9 Major Cities' GDP vs age vs death
SELECT location,
	AVG(gdp_per_capita) AS gdp, 
	MAX(median_age) AS aged_median_composition,
	MAX(aged_65_older) AS aged_65_composition,
	MAX(aged_70_older) AS aged_70_composition,
	SUM(CAST(new_cases as int)) as TotalCases,
	SUM(CAST(new_deaths as int)) as TotalDeathCount,
    CASE 
        WHEN SUM(new_cases) > 0 THEN (SUM(CAST(new_deaths as int)) / SUM(new_cases)) * 100
        ELSE 0
    END as DeathPercentage
FROM CovidDeathNew
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY 1


-- 10 GDP VS vaccination rate
WITH PopvsVac (Location, population, GDP, TotalVaccinations, PercentPopulationVaccinated)
AS
(
    SELECT 
        dea.location, 
		dea.population,
        MAX(dea.gdp_per_capita) AS GDP,
        MAX(CAST(vac.people_vaccinated AS bigint)) AS TotalVaccinations,
        (MAX(CAST(vac.people_vaccinated AS bigint)) / MAX(dea.population)) * 100.0 AS PercentPopulationVaccinated
    FROM 
        CovidDeathNew dea
    JOIN 
        CovidVaccinationNew vac ON dea.location = vac.location AND dea.date = vac.date
    WHERE 
        dea.continent IS NOT NULL
    GROUP BY 
        dea.location, dea.population
)
SELECT 
    Location, 
	population,
    GDP, 
    TotalVaccinations, 
    PercentPopulationVaccinated
FROM 
    PopvsVac
ORDER BY 
    PercentPopulationVaccinated DESC;






-- 11 GDP VS hospitalization rate VS death rate
SELECT 
    location,
    MAX(gdp_per_capita) AS gdp,
	SUM(new_cases) as total_cases,
	SUM(CAST(hosp_patients as int)) AS HospitalizationCount,
	CASE 
		WHEN SUM(new_cases) > 0 THEN (SUM(CAST(hosp_patients as int)) / SUM(new_cases)) * 100
		ELSE 0
	END as HospitalizationPercentage,
    CASE 
        WHEN SUM(new_cases) > 0 THEN (SUM(CAST(new_deaths as int)) / SUM(new_cases)) * 100
        ELSE 0
    END as DeathPercentage
FROM CovidDeathNew
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY 1;


