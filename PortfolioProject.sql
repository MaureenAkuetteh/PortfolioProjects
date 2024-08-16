/* 

Cleaning data in SQL Queries


*/


Select *
from PortfolioProject.dbo.NashvilleHousing


--Standardise Date Fomart

Select SaleDate, convert(date,saledate)
from PortfolioProject.dbo.NashvilleHousing

Alter table PortfolioProject..NashvilleHousing
add SaleDateConverted date;

Update PortfolioProject..NashvilleHousing
set SaleDateConverted = convert(date,saledate)

 
--Populate Property Address data

Select *
from PortfolioProject.dbo.NashvilleHousing
where PropertyAddress is null
order by ParcelID


select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, isnull(a.PropertyAddress,b.PropertyAddress)
from PortfolioProject.dbo.NashvilleHousing a
join PortfolioProject.dbo.NashvilleHousing b
on a.ParcelID = b.ParcelID
and a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is null	


update a
set PropertyAddress = isnull(a.PropertyAddress,b.PropertyAddress)
from PortfolioProject.dbo.NashvilleHousing a
join PortfolioProject.dbo.NashvilleHousing b
on a.ParcelID = b.ParcelID
and a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is null	



select PropertyAddress 
from PortfolioProject.dbo.NashvilleHousing

select * 
from PortfolioProject..CovidDeaths
where continent is not null
order by 3,4


--select * 
--from PortfolioProject..CovidVaccinations
--order by 3,4

--Select Data that we will be using 

Select location, date, total_cases, new_cases, total_deaths, population
from PortfolioProject..CovidDeaths
order by 1,2

--Looking at the Total Cases verses Total Deaths
-- shows the likelihood of dying if you contract Covid in your country
Select location, date, total_cases, total_deaths, (convert(float,total_deaths)/(convert(float,total_cases)))*100 as DeathPercentage
from PortfolioProject..CovidDeaths
where location = 'Ghana' and continent is not null
order by 1,2

-- Looking at Total Cases vs Population 
-- Shows what percentage of Population got Covid
Select location, date,  Population, total_cases, (convert(float,total_cases)/(convert(float,Population)))*100 as PercentPopulationInfected
from PortfolioProject..CovidDeaths
--where location = 'Ghana'
order by 1,2


-- Looking at countries with Highest Infection Rate compared to Population 
Select location, Population, Max(convert(float,total_cases)) as HighestInfectionCount, Max((convert(float,total_cases)/(convert(float,Population))))*100 as PercentPopulationInfected
from PortfolioProject..CovidDeaths
--where location = 'United States'
Group by Location , Population
order by PercentPopulationInfected desc
   
-- looking at countries with the highest death count

Select location, Max(cast(Total_deaths as int)) as TotalDeathCount
from PortfolioProject..CovidDeaths
--where location = 'United States'
where continent is not null
Group by Location
order by TotalDeathCount desc

 -- GROUP BY CONTINENT

 --Showing the continents with the highest death count per population 

Select continent, Max(cast(Total_deaths as int)) as TotalDeathCount
from PortfolioProject..CovidDeaths
--where location = 'United States'
where continent is not null
Group by continent
order by TotalDeathCount desc


-- GLOBAL NUMBERS

Select  sum(new_cases) as total_cases,sum(cast(new_deaths as int)) as total_deaths, sum(cast(new_deaths as int))/(sum(New_Cases))*100 as DeathPercentage
from PortfolioProject..CovidDeaths
--where location like '%states%'
where continent is not null 
--group by date
order by 1,2


-- Looking at Total Populations vs Vaccinations
--USE CTE

With PopvsVac(Continent, Location,Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as 

(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(convert(bigint, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
--,(RollingPeopleVaccinated/population)*100 
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
--order by 2,3
)

select * , (RollingPeopleVaccinated/Population)*100
from PopvsVac


-- TEMP TABLE
Drop table if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric, 
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(convert(bigint, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
--,(RollingPeopleVaccinated/population)*100 
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
--order by 2,3


select * , (RollingPeopleVaccinated/Population)*100
from #PercentPopulationVaccinated



--Creating view to store data for later visualisations


create view PercentagePopulationVaccinated as 
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(convert(bigint, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
--,(RollingPeopleVaccinated/population)*100 
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
--order by 2,3


select *
from PercentagePopulationVaccinated




