--select * 
--from dbo.CovidDeaths$
--order by 3, 4;

--select * 
--from dbo.CovidVaccinations$
--order by 3, 4;

-- Select the data that we are going to be using

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM dbo.CovidDeaths$
ORDER BY 1, 2;

-- Total de muertos vs Total de casos de Covid
-- Procentaje que muestra que tan probable es que mueras si tienes covid
SELECT location, date, total_cases, total_deaths, ROUND((total_deaths/total_cases)*100.0, 2) as DeathPercentage
FROM dbo.CovidDeaths$
WHERE location like '%Chile%'
AND continent is NOT NULL
ORDER BY 1, 2;


-- Total de casos vs Population
-- Muestra el porcentaje de la población que tiene covid
SELECT location, date, total_cases, population, ROUND((total_cases/population)*100.0, 4) as CasesPercentage
FROM dbo.CovidDeaths$
WHERE location like '%Chile%'
AND continent is NOT NULL
ORDER BY 1, 2;

-- Qué países tiene un el ratio de infección más alto en comparación a la población?
SELECT location, population, MAX(total_cases) as HighestInfectionCount, ROUND(MAX(total_cases/population), 3)*100.0 as PercentPopulationInfected
FROM dbo.CovidDeaths$
--WHERE location like '%Chile%'
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC;

-- Paises con la cuenta de muertes más altas por población
SELECT location, MAX(CAST(total_deaths as INT)) as HighestDeathsCount
FROM dbo.CovidDeaths$
WHERE continent is NOT NULL
GROUP BY location
ORDER BY HighestDeathsCount DESC;

-- Veamos ahora el numero de muertos por continente
SELECT continent, MAX(CAST(total_deaths as INT)) as HighestDeathsCount
FROM dbo.CovidDeaths$
WHERE continent is NOT NULL
GROUP BY continent
ORDER BY HighestDeathsCount DESC;

-- Veamos ahora algunas métricas globales
SELECT SUM(new_cases) as TotalCases, SUM(CAST(new_deaths as INT)) as TotalDeaths, ROUND((SUM(CAST(new_deaths as INT))/SUM(new_cases))*100.0, 3) as DeathPercentage
FROM ProyectoPortfolio..CovidDeaths$
WHERE continent is NOT NULL
--GROUP BY date
ORDER BY 1;


-- Total de la población que ha sido vacunada
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CAST(new_vaccinations as INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as AcumuladoNuevasVacunas
FROM ProyectoPortfolio..CovidVaccinations$ as vac
JOIN ProyectoPortfolio..CovidDeaths$ as dea
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent is NOT NULL
ORDER BY 2,3;

-- CTE (Common Table Expressions) para calcular el ratio de población vacunada por continente, location y date.
with PopvsVac AS (
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CAST(new_vaccinations as INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as AcumuladoNuevasVacunas
	FROM ProyectoPortfolio..CovidVaccinations$ as vac
	JOIN ProyectoPortfolio..CovidDeaths$ as dea
	ON dea.location = vac.location
	AND dea.date = vac.date
	WHERE dea.continent is NOT NULL
	--ORDER BY 2,3
)

SELECT *, (AcumuladoNuevasVacunas/population) FROM PopvsVac


-- Otra forma de hacer lo mismo de arriba con una tabla temporal que creamos:
DROP TABLE IF EXISTS #PercentPopulationVaccinated

CREATE TABLE #PercentPopulationVaccinated (
	continent nvarchar(255),
	location nvarchar(255),
	date datetime,
	population numeric,
	new_vaccinations numeric,
	AcumuladoNuevasVacunas numeric
)

INSERT INTO #PercentPopulationVaccinated 
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CAST(new_vaccinations as INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as AcumuladoNuevasVacunas
	FROM ProyectoPortfolio..CovidVaccinations$ as vac
	JOIN ProyectoPortfolio..CovidDeaths$ as dea
	ON dea.location = vac.location
	AND dea.date = vac.date
	WHERE dea.continent is NOT NULL
	--ORDER BY 2,3
;

SELECT *, (AcumuladoNuevasVacunas/population) FROM #PercentPopulationVaccinated;

-- Creando una vista para guardar los datos para futuras visualizaciones

CREATE VIEW PercentPopulationVaccinated AS 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CAST(new_vaccinations as INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as AcumuladoNuevasVacunas
FROM ProyectoPortfolio..CovidVaccinations$ as vac
JOIN ProyectoPortfolio..CovidDeaths$ as dea
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent is NOT NULL
--ORDER BY 2,3

SELECT * FROM PercentPopulationVaccinated;

