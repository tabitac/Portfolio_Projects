/*
Covid 19 Data Exploration

Skills used in this project: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/


Select * 
From 
  [Portfolio ]..Covid_Deaths -- delclare that we are selecting Covid Deaths table
Where 
  continent is not null -- Removing null rows in continent
Order by 
  3, 
  4 
  
  -- Select Data that we are going to be starting with

Select 
  location, 
  date, 
  total_cases, 
  new_cases, 
  total_deaths, 
  population 
From 
  [Portfolio ]..Covid_Deaths 
Where 
  continent is not null 
Order by 
  1, 
  2 
  
  -- Analyzing Total Cases vs Total Deaths
  --Shows the likehood of dying if you contact covid in your country 
Select 
  location, 
  date, 
  total_cases, 
  total_deaths, 
  (total_deaths / total_cases)* 100 as Death_Percentage 
From 
  [Portfolio ]..Covid_Deaths 
Where 
  location like '%Canada%' 
  and continent is not null -- Removing null rows in continent
Order by 
  1, 
  2 
  
  --Analyzing Total cases vs Population
  --Shows what percentage of population infected by Covid 
Select 
  location, 
  date, 
  population, 
  total_cases, 
  (total_cases / population)* 100 as PercentagePopulationInfected 
From 
  [Portfolio ]..Covid_Deaths --Where location like '%Canada%'
Order by 
  1, 
  2 
  
--Shows Countries with Highest Infection Rate compared to Population 
Select 
  location, 
  population, 
  MAX(total_cases) as HighestInfectionCount, 
  MAX(
    (total_cases / population)
  )* 100 as PercentagePopulationInfected -- selecting selected columns looking at the highest total cases 
From 
  [Portfolio ]..Covid_Deaths --Where location like '%Canada%'
Where 
  continent is not null 
Group by 
  location, 
  population 
Order by 
  PercentagePopulationInfected desc
  
  --Shows Countries with the Highest Death Count per Population
  
Select 
  location, 
  MAX(
    cast(total_deaths as int)
  ) as TotalDeathCount -- Use cast function so it read as numeric
From 
  [Portfolio ]..Covid_Deaths 
Where 
  continent is not null 
Group by 
  location 
Order by 
  TotalDeathCount desc 
  
  -- Breakdown : Highest Death Count by Continent
  --Showing continents with the highest death count per population 
Select 
  continent, 
  MAX(
    cast(total_deaths as int)
  ) as TotalDeathCount -- Use cast function so it read as numeric
From 
  [Portfolio ]..Covid_Deaths 
Where 
  continent is not null 
Group by 
  continent 
Order by 
  TotalDeathCount desc 
  
  
  -- Global Numbers
Select 
  SUM(new_cases) as Total_Cases, 
  SUM(
    cast(new_deaths as int)
  ) as Total_Deaths, 
  SUM(
    cast(new_deaths as int)
  )/ SUM(new_cases)* 100 as DeathPercentage 
From 
  [Portfolio ]..Covid_Deaths 
Where 
  continent is not null --Group by date
Order by 
  1, 
  2 
  
  -- Joining Death and Vaccinations Table 

Select 
  dea.continent, 
  dea.location, 
  dea.date, 
  dea.population, 
  vac.new_vaccinations 
From 
  [Portfolio ]..Covid_Deaths dea 
  Join [Portfolio ]..Covid_Vaccinations vac  
  ON dea.location = vac.location 
  and dea.date = vac.date 
Where 
  dea.continent is not null 
Order by 
  2, 
  3 
  
    
  -- Total Population vs Vaccinations
  -- Shows Percentage of Population that has received at least first dose of Covid Vaccine
Select 
  dea.continent, 
  dea.location, 
  dea.date, 
  dea.population, 
  vac.new_vaccinations, 
  SUM(
    Convert(int, vac.new_vaccinations)
  ) Over(
    partition by dea.location 
    Order by 
      dea.location, 
      dea.date
  ) as RollingCount_PeopleVaccinated   --Breaking it  by location , example : query will run only through Canada when it gets through the next country it doen't keep going
From 
  [Portfolio ]..Covid_Deaths dea -- dea = key name for Covid_Deaths tables
  Join [Portfolio ]..Covid_Vaccinations vac -- vac = key name for Covid_Vaccinations 
  ON dea.location = vac.location 
  and dea.date = vac.date 
Where 
  dea.continent is not null 
Order by 
  2, 
  3 
  
  -- Using CTE to perform Calculation on Partition By in previous query
  
  With PopvsVac (
    continent, location, date, population, 
    new_vaccinations, RollingCount_PeopleVaccinated
  ) as (
    Select 
      dea.continent, 
      dea.location, 
      dea.date, 
      dea.population, 
      vac.new_vaccinations, 
      SUM(
        Convert(int, vac.new_vaccinations)
      ) Over(
        partition by dea.location 
        Order by 
          dea.location, 
          dea.date
      ) as RollingCount_PeopleVaccinated --breaking it up by location , example : query will run only through Canada when it gets through the next country it doen't keep going
    From 
      [Portfolio ]..Covid_Deaths dea -- dea = key name for Covid_Deaths tables
      Join [Portfolio ]..Covid_Vaccinations vac -- vac = key name for Covid_Vaccinations 
      ON dea.location = vac.location 
      and dea.date = vac.date 
    Where 
      dea.continent is not null
      --Order by 2,3 -- Order by clause can't be used , will cause error  - "commnent out"
      ) 
      
Select 
  *, 
  (
    RollingCount_PeopleVaccinated / population
  )* 100 as PercentageofRollingCount_PeopleVaccinated 
From 
  PopvsVac 
  
    
 -- Using Temp Table Version to perform Calculation on Partition by in previous query
Drop 
  Table if exists #PercentPopulationVaccinated
  Create Table #PercentPopulationVaccinated
  (
    continent nvarchar(255), 
    location nvarchar(255), 
    Date datetime, 
    Population numeric, 
    New_vaccination numeric, 
    RollingCount_PeopleVaccinated numeric
  ) 
Insert into #PercentPopulationVaccinated
Select 
  dea.continent, 
  dea.location, 
  dea.date, 
  dea.population, 
  vac.new_vaccinations, 
  SUM(
    Convert(int, vac.new_vaccinations)
  ) Over(
    partition by dea.location 
    Order by 
      dea.location, 
      dea.date
  ) as RollingCount_PeopleVaccinated --breaking it up by location , example : query will run only through Canada when it gets through the next country it doen't keep going
From 
  [Portfolio ]..Covid_Deaths dea 
  Join [Portfolio ]..Covid_Vaccinations vac 
  ON dea.location = vac.location 
  and dea.date = vac.date 
Where 
  dea.continent is not null 
  --Order by 2,3 
  Select 
  *, 
  (
    RollingCount_PeopleVaccinated / population
  )* 100 as PercentageofRollingCount_PeopleVaccinated 
From 
  #PercentPopulationVaccinated
  
   --Creating Views to store data for later visulizations 
   -- Percent Population Vaccinate View
  Use [Portfolio ] GO 
SET 
  Ansi_nulls on GO Create View PercentPopulationVaccinate as 
Select 
  dea.continent, 
  dea.location, 
  dea.date, 
  dea.population, 
  vac.new_vaccinations, 
  SUM(
    CONVERT(int, vac.new_vaccinations)
  ) OVER (
    Partition by dea.Location 
    Order by 
      dea.location, 
      dea.Date
  ) as RollingPeopleVaccinated --, (RollingPeopleVaccinated/population)*100
From 
  Portfolio..Covid_Deaths dea 
  Join Portfolio..Covid_Vaccinations vac On dea.location = vac.location 
  and dea.date = vac.date 
where 
  dea.continent is not null
) GO 
-- View of Total Population VS Vaccinations

Create View TotalPopvsVac as 
Select 
  dea.continent, 
  dea.location, 
  dea.date, 
  dea.population, 
  vac.new_vaccinations 
From 
  [Portfolio ]..Covid_Deaths dea -- dea = key name for Covid_Deaths tables
  Join [Portfolio ]..Covid_Vaccinations vac -- vac = key name for Covid_Vaccinations 
  ON dea.location = vac.location 
  and dea.date = vac.date 
Where 
  dea.continent is not null --Order by 2,3
  
  -- View of Global numbers
  Create View Globalno as 
Select 
  SUM(new_cases) as Total_Cases, 
  SUM(
    cast(new_deaths as int)
  ) as Total_Deaths, 
  SUM(
    cast(new_deaths as int)
  )/ SUM(new_cases)* 100 as DeathPercentage 
From 
  [Portfolio ]..Covid_Deaths 
Where 
  continent is not null -
  
  - View shows Countries with the Highest Death Count per Population
  Create View Highdeathcount_pop as 
Select 
  location, 
  MAX(
    cast(total_deaths as int)
  ) as TotalDeathCount -- Use cast function so it read as numeric
From 
  [Portfolio ]..Covid_Deaths 
Where 
  continent is not null 
Group by 
  location --Order by TotalDeathCount desc
  
  --View shows the likehood of dying if you contact covid in Canada
  Create View Canada_covid as 
Select 
  location, 
  date, 
  total_cases, 
  total_deaths, 
  (total_deaths / total_cases)* 100 as Death_Percentage 
From 
  [Portfolio ]..Covid_Deaths 
Where 
  location like '%Canada%' 
  and continent is not null -- Removing null rows in continent
  --Order by 1,2
