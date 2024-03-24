Select *
From CovidProject..coviddeaths$
order by 3,4

-- Let's select the data that we are going to be using:
Select Location, date, total_cases, new_cases, total_deaths, population
From CovidProject..coviddeaths$
order by 1,2

-- Look at the Total Cases vs Total Deaths:
Select Location, date, total_cases,total_deaths, (cast(total_deaths as float)/cast(total_cases as float))*100 as DeathPercentage
From CovidProject..coviddeaths$
order by 1,2

-- Not to get ".. data type nvarchar is invalid .. " error, use cast. And if you use int, you will get 0's as percentages.
-- Thus, use float.


-- To look at United States:
Select Location, date, total_cases,total_deaths, (cast(total_deaths as float)/cast(total_cases as float))*100 as DeathPercentage
From CovidProject..coviddeaths$
Where location like'%states%'
order by 1,2

-- Let's look at the total cases vs population:
-- And I am from Turkey, so let me look at Turkey:
Select Location, date, total_cases,population, (cast(total_cases as float)/population)*100 as InfectionPercentage
From CovidProject..coviddeaths$
Where location like'%turkey%'
order by 1,2


-- Looking at highest infection rate compared to population:
Select Location, MAX(cast(total_cases as float)) as HighestInfectionCount ,population, MAX((cast(total_cases as float)/population))*100 as MaxInfectionPercentage
From CovidProject..coviddeaths$
Group by location, population
order by 4 desc

-- What are the countries' death count per population?
Select Location, MAX(cast(total_deaths as float)) as HighestDeathCount ,population, MAX((cast(total_deaths as float)/population))*100 as MaxDeathPercentage
From CovidProject..coviddeaths$
Where continent is not null
Group by location, population
order by 2 desc
-- order by 2 and 4 to change the ordering to just total number or percentage of population.

-- Let's break things down by continents:
Select continent, MAX(cast(total_deaths as float)) as HighestDeathCount
From CovidProject..coviddeaths$
Where continent is not null
Group by continent
order by 2 desc

-- Continent death counts per population ?
Select continent, MAX(cast(total_deaths as float)) as HighestDeathCount, SUM(distinct population) as TotalPopulation, (MAX(cast(total_deaths as float))/SUM(distinct population))*100 as ContinentPercentage
From CovidProject..coviddeaths$
Where continent is not null
Group by continent
order by 2 desc

-- Global stat:
SELECT 
    SUM(new_cases) AS total_cases_global,
    SUM(CAST(new_deaths AS float)) AS deaths_global,
    CASE 
        WHEN SUM(new_cases) <> 0 THEN (SUM(CAST(new_deaths AS float)) / SUM(new_cases)) * 100
        ELSE NULL -- or any other appropriate value you prefer
    END AS DeathPercentageGlobal
FROM 
    CovidProject..coviddeaths$
WHERE 
    continent IS NOT NULL
ORDER BY 
    1, 2;


-- Let's join our two tables based on the same location and date values.
-- Then, let's look at total population vs vaccination: Rolling Count
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations as float)) OVER(PARTITION BY dea.location Order by dea.location, dea.date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as RollingPeopleVaccinated
From CovidProject..coviddeaths$ dea
Join CovidProject..covidvaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
Order by 2,3

-- the ORDER BY clause in the window function exceeds the maximum supported size for a RANGE window frame, which is 900 bytes.
-- That is why I added: ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW line. (The data is big.)




-- Let's use CTE (Common Table Expression) to be able to use RollingPeopleVaccinated as a variable:
With PopulvsVaccin (continent, location, date, population,new_vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations as float)) OVER(PARTITION BY dea.location Order by dea.location, dea.date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as RollingPeopleVaccinated
From CovidProject..coviddeaths$ dea
Join CovidProject..covidvaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null)
Select *, (RollingPeopleVaccinated/population)*100 as PercentagePopVac
From PopulvsVaccin

-- It exceeds 100% because people get vaccinated more than once.


-- I could also use TEMP Table to achieve this:
DROP Table if exists #PercentPopulationVaccinated
CREATE Table #PercentPopulationVaccinated
( continent nvarchar(255), location nvarchar(255), date datetime, population numeric, new_vaccinations numeric, RollingPeopleVaccinated numeric)
Insert into #PercentPopulationVaccinated

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations as float)) OVER(PARTITION BY dea.location Order by dea.location, dea.date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as RollingPeopleVaccinated
From CovidProject..coviddeaths$ dea
Join CovidProject..covidvaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
Select *, (RollingPeopleVaccinated/population)*100 as PercentagePopVac
From #PercentPopulationVaccinated


-- I want to create some views and store them for later visualizations:
Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations as float)) OVER(PARTITION BY dea.location Order by dea.location, dea.date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as RollingPeopleVaccinated
From CovidProject..coviddeaths$ dea
Join CovidProject..covidvaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null

-- This is permanent and we can query from this view as well.
