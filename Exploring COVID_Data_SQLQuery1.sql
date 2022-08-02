--Using data from OWID to make views for Covid situation at a global level. 
--COVID 19 Pandemic - Cases, Deaths, & Vaccination by Country!

--Total Cases per Country
Select location, continent, Sum(new_cases_smoothed)/AVG(population)*100 as '%Population_Affected'
From PortfolioProject..['CovidDeaths$']
 WHERE continent is not null
 Group by location,continent
 ORDER by 1,2

--Total Deaths per Country
Select location,continent, date, total_deaths, population, ( total_deaths/population)*100 as '%_Deaths/Country'
From PortfolioProject..['CovidDeaths$']
WHERE continent is not null
ORDER by 1,2

--Total Vaccination per Country
Select dea.location,dea.continent, dea.date,people_fully_vaccinated,positive_rate,total_boosters,population,
( people_fully_vaccinated/population)*100 as '%_Vaccinated/Country'
From PortfolioProject..['CovidDeaths$'] as dea
Join PortfolioProject..['CovidVacc$'] as vac
     ON dea.location = vac.location
     AND dea.date = vac.date
 WHERE dea.continent is not null
 AND people_fully_vaccinated is not null
ORDER by 1,2

--Demographics in the period (Average)
Select continent , location, (population_density) as Population_Density,
median_age as Median_age,
gdp_per_capita as GDP_per_capita,
hospital_beds_per_thousand as Hospital_beds_per_thousand ,
life_expectancy as life_expectancy
FROM PortfolioProject..['CovidVacc$']
WHERE continent is not null
ORDER by 1,2

--Countries with highest impact from COVID
Select location,continent, 
MAX(cast(total_deaths  as int)) as CovidDeaths_Count,
MAX(cast(total_cases  as int)) as CovidCases_Count,
MAX(( total_cases/population))*100 as '%Covid_Cases/Population',
MAX(( total_deaths/population))*100 as '%Covid_Deaths/Population'
From PortfolioProject..['CovidDeaths$']
WHERE continent is not null
Group by location, continent
ORDER by CovidDeaths_Count DESC


--Global Covid Cases
Select continent, SUM(new_cases) as total_cases, 
SUM(cast(new_deaths as int)) as total_deaths,
SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as '%Death/Cases'

From PortfolioProject..['CovidDeaths$']
Where continent is not null
Group by continent


--Total Population vs Vaccination
SELECT dea.continent, dea.location, dea.date,
dea.population, vac.new_vaccinations
From PortfolioProject..['CovidDeaths$'] as dea
Join PortfolioProject..['CovidVacc$'] as vac
     ON dea.location = vac.location
     AND dea.date = vac.date
Where dea.continent is not null
AND new_vaccinations is not null
Order by 2,3,4

--Total Population vs Cummulative Vaccination

----Create a CTE that Permits me to make calculation with the created variable Cummulative_vacc
----(Note: Cannot include the order by clause in a CTE)

With Pop_Vacc(Continent, Location, Date, Population, 
New_vaccinations, Cummulative_vacc) 
as 
( 
SELECT dea.continent, dea.location, dea.date, 
dea.population, vac.new_vaccinations,
SUM(Cast(vac.new_vaccinations as bigint)) OVER 
(Partition by dea.location Order by dea.location,
dea.date) as Cummulative_vacc

From PortfolioProject..['CovidDeaths$'] dea
Join PortfolioProject..['CovidVacc$'] vac
     On dea.location = vac.location
     and dea.date = vac.date
Where dea.continent is not null
And new_vaccinations is not null

 )
	
Select * , (Cummulative_vacc/population)*100 as #Percent_Vacc_Pop
From Pop_Vacc

--Using a Temp_table (instead of a CTE) that Permits me to make calculation
--with the created variable Cummulative_vacc

DROP TABLE if Exists #PopVaccinated_percent
Create Table #PopVaccinated_percent
(
Continent nvarchar(255), 
Location nvarchar(255), 
Date datetime,
Population numeric,
New_vaccinations numeric,
Cummulative_vacc numeric
)
insert into #PopVaccinated_percent
SELECT dea.continent, dea.location, dea.date, dea.population,
vac.new_vaccinations, SUM(cast(vac.new_vaccinations as bigint))
OVER (Partition by dea.location Order by dea.location, dea.date) as Cummulative_vacc

From PortfolioProject..['CovidDeaths$'] as dea
Join PortfolioProject..['CovidVacc$'] as vac
     ON dea.location = vac.location
     AND dea.date = vac.date
Where dea.continent is not null
And new_vaccinations is not null
--order by 2,3,4
--Now I can use Cummulative_vacc for calculation
Select*, (Cummulative_vacc/population)*100 as #Per_Vacc_Pop
From #PopVaccinated_percent


--Creating views to visualization

Create View Pop_Vacc_percent as 
Select vac.continent,Population, vac.date, MAX(cast(people_fully_vaccinated as int)) as Fully_Vaccinated,
Max((cast(people_fully_vaccinated as int)/population))*100 as '%Population_Vaccinated'
From PortfolioProject..['CovidDeaths$'] as dea
Join PortfolioProject..['CovidVacc$'] as vac
ON dea.location = vac.location
     AND dea.date = vac.date
 Where vac.continent is not null
 Group by vac.date,vac.continent,Population
 --ORDER by 1,
 Go

Select *
From Pop_Vacc_percent 

--Total Cases per Continent
Alter View Tot_Cases_Cont as
Select continent,Population, date, MAX(total_cases) as MostInfect_Count,
Max((total_cases/population))*100 as '%Population_Infected'
From PortfolioProject..['CovidDeaths$']
 WHERE continent is not null
 Group by date,continent,Population
 --ORDER by 1,
 Go

 Select * 
From Tot_Cases_Cont


--Total Cases per country over time
Create View Covid_Cases as
Select location, date,sum(new_cases_smoothed) as Covid_Cases
From PortfolioProject..['CovidDeaths$'] as dea
 Group by location,date

--ORDER by 1,2
Select * 
From Covid_Cases

--Demographics in the period (Average)
Create View Demographics as
Select continent , location, AVG(population_density) as Population_km2,
AVG(median_age) as Median_age,
AVG(gdp_per_capita) as GDP_per_capita,
AVG(hospital_beds_per_thousand) as Hospital_beds_per_thousand ,
AVG(life_expectancy) as life_expectancy
FROM PortfolioProject..['CovidVacc$']
WHERE continent is not null
Group by location,continent
--ORDER by 1,2
Select * 
From Demographics

--Countries with highest impact from COVID
Create View Mostly_Impacted as
Select location,continent, 
MAX(cast(total_deaths  as int)) as CovidDeaths_Count,
MAX(cast(total_cases  as int)) as CovidCases_Count,
MAX(( total_cases/population))*100 as '%Covid_Cases/Population',
MAX(( total_deaths/population))*100 as '%Covid_Deaths/Population'
From PortfolioProject..['CovidDeaths$']
WHERE continent is not null
Group by location, continent
--ORDER by CovidDeaths_Count DESC
Select * 
From Mostly_Impacted


--Global Covid Cases
Create View Global_Cases as
Select continent, SUM(new_cases) as total_cases, 
SUM(cast(new_deaths as int)) as total_deaths,
SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as '%Death/Cases'

From PortfolioProject..['CovidDeaths$']
Where continent is not null
Group by continent

Select * 
From Global_Cases
