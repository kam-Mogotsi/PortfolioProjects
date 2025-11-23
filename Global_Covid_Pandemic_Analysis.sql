USE [PortfolioProject]
SELECT *
FROM PortfolioProject..CovidDeaths
ORDER BY 3,4


--SELECT *
--FROM PortfolioProject..CovidVaccinations
--ORDER BY 3,4


--Select Data that is going to be used

SELECT location,date,total_cases,new_cases,total_deaths,population
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2

--Looking at TotalCases vs TotalDeaths 
--shows likelihood of dying fromcovid per country 
SELECT location,date,total_cases,total_deaths, (total_deaths/total_cases)*100 as death_rate
FROM PortfolioProject..CovidDeaths
where location like '%Botswana%'
ORDER BY 1,2

--Looking at TocalCases Vs Population
--shows % of population infected by covid 
SELECT location,date,population,total_cases,total_deaths, (total_cases/population)*100 as infection_rate
FROM PortfolioProject..CovidDeaths
WHERE location like '%Botswana%'
ORDER BY 1,2

--Show countries with highest infection rate
SELECT location,population,MAX(total_cases) as highestInfectionCount, MAX(total_cases/population)*100 as highest_infection_rate
FROM PortfolioProject..CovidDeaths
GROUP BY location,population
ORDER BY highest_infection_rate DESC

--Show countries with highest death rates per capita
SELECT location,population,MAX(cast(total_deaths as int)) as highestDeathCount, MAX((total_deaths/population))*100 as highest_death_rate
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY location,population
ORDER BY highest_death_rate DESC

--Show countries with highest death rate
SELECT location,MAX(cast(total_deaths as int)) as highestDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY location
ORDER BY highestDeathCount DESC


--Lets break things down by continent
SELECT continent,MAX(cast(total_deaths as int)) as highestDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY highestDeathCount DESC

--A view at the Global numbers
SELECT SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths,
		SUM(cast(new_deaths as int))/SUM(new_cases)*100 as death_rate
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
ORDER BY 1,2

--Looking at Total Population Vs Vaccination
SELECT dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
	SUM(cast(new_vaccinations as int)) OVER (PARTITION by dea.location ORDER BY dea.location,dea.date ) as rolling_Vaccinated_People
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
ON dea.location =vac.location and dea.date =vac.date
WHERE dea.continent is not NULL --and dea.location ='Albania'
ORDER BY 2,3

--USE OF A CTE
--so that you have access to a variable that you wouldnt access in a select statement e.g rolling vaccinations below
WITH PopvsVac(continent,location,date,population,new_vaccinations,rolling_vaccinated_people)
AS 
(
SELECT dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
	SUM(cast(new_vaccinations as int)) OVER (PARTITION by dea.location ORDER BY dea.location,dea.date ) as rolling_Vaccinated_People
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
ON dea.location =vac.location and dea.date =vac.date
WHERE dea.continent is not NULL 
)

SELECT * , (rolling_vaccinated_people/population)*100
FROM PopvsVac
WHERE location ='Albania'

--USING A TEMP TABLE
DROP TABLE if exists #PercentagePopulationVaccinated
CREATE TABLE #PercentagePopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_Vaccinated_People numeric
)
INSERT INTO #PercentagePopulationVaccinated
SELECT dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
	SUM(cast(new_vaccinations as int)) OVER (PARTITION by dea.location ORDER BY dea.location,dea.date ) as rolling_Vaccinated_People
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
ON dea.location =vac.location and dea.date =vac.date
WHERE dea.continent is not NULL 

SELECT * , (rolling_Vaccinated_People/population)*100
FROM #PercentagePopulationVaccinated

--CREATE VIEW TO STORE DATA FOR LATER VISUALIZATIONS
CREATE VIEW PercentagePopulationVaccinated AS
SELECT dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
	SUM(cast(new_vaccinations as int)) OVER (PARTITION by dea.location ORDER BY dea.location,dea.date ) as rolling_Vaccinated_People
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
ON dea.location =vac.location and dea.date =vac.date
WHERE dea.continent is not NULL 