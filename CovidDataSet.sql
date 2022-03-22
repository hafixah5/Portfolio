
--Let's take a glance of the data
SELECT *
From PortfolioProject..CovidDeaths --The data has repetitive dates for each day

--Filtering to get rid of one date for each day and null values in total_cases 
SELECT DISTINCT date, location,total_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
--WHERE location NOT LIKE ('lower','world') --These are none country records that have been detected 
WHERE total_cases IS NOT NULL
Order by location asc


-- Total cases vs Total Deaths
-- Likelihood of dying if one cobtracted covid in certain country
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where continent is not null
order by 1,2


--Total cases vs Population
SELECT location, date, total_cases, total_deaths, population, (total_cases/population)*100 as CasesPercentage
From PortfolioProject..CovidDeaths
Where location like '%Malaysia%'
order by 1,2


--Countries with highest infection rate compraed to population
SELECT location,population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PercentagePopulationInfection
From PortfolioProject..CovidDeaths
--Where location like '%Malaysia%'
Group by location, population
Order by PercentagePopulationInfection desc


-- Countries with highest death count per population
SELECT location, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
--Where location like '%Malaysia%'
Where continent is not null
Group by location
order by TotalDeathCount desc


--Highest Death count by continent
SELECT continent, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent is not null
Group by continent
order by TotalDeathCount desc


--Global Numbers
SELECT SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_death,SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where continent is not null
--Group by date
order by 1,2
--As of 22nd Feb 2022, Death Percentage is 1.38%, total death (5879383), total cases (426416105)


-- Join tables on location & date
Select*
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date

--Total population vs vaccinations
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, (vac.new_vaccinations/dea.population)*100 as vacc_percentage
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null --and dea.location like '%Malaysia%'
order by 1,2,3
-- As of 22nd Feb 2022,in Malaysia total vacc(147742) with population (32776195), vacc_percentage(0.45%)

-- new vaccinations per day
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int, vac.new_vaccinations)) OVER 
 (Partition by dea.location Order by dea.location, dea.date) as RollingVaccination
--, (RollingVaccination/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3


--Use CTE

With PopvsVac (continent, location, date, population,new_vaccinations, RollingVaccination)
as 
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingVaccination
-- (RollingVaccination/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
)
Select *, (RollingVaccination/Population)*100
From PopvsVac


--Temp Table

Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS bigint)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingVaccination
-- (RollingVaccination/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null

Select *
From #PercentPopulationVaccinated


--Create view to store data for visualisations

Create View PercentPopulationVaccinated AS 
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS bigint)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingVaccination
-- (RollingVaccination/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null

Select *
From PercentPopulationVaccinated