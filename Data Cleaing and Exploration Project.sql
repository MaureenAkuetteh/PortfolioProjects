
-- Data Cleaning  --
SELECT * 
FROM layoffs; 

-- 1. Remove Duplicates --
-- 2. Standardize the Data --
-- 3. Null values or blank Values --
-- 4. Remove Any Columns --

-- Create a duplicate databse with all the data in layoffs --
CREATE TABLE layoffs_staging 
LIKE layoffs;

INSERT layoffs_staging
SELECT * 
FROM layoffs;

SELECT * 
FROM layoffs_staging; 

-- 1.Removing Duplicates --

WITH duplicate_cte AS ( 
SELECT *,
ROW_NUMBER() OVER (
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off,`date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging
)
SELECT * 
FROM duplicate_cte
WHERE row_num > 1;

-- Checking if the query for identifying duplicates is working
SELECT *
FROM layoffs_staging
WHERE company = 'Casper';

-- CTE's cannot be modified so we need to create another table with our row_num column --

-- Creating a duplicate table --
CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- inserting values into out duplicate table --

INSERT INTO layoffs_staging2 
SELECT *,
ROW_NUMBER() OVER (
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off,`date`, stage, country, funds_raised_millions) 
AS row_num
FROM layoffs_staging;

SELECT *
FROM layoffs_staging2;

-- deleting the duplicate columns --

SELECT *
FROM layoffs_staging2
WHERE row_num > 1;

DELETE
FROM layoffs_staging2
WHERE row_num > 1;


-- 2.Standardizing Data --

UPDATE layoffs_staging2
SET company = trim(company);

-- checking industry for format issues --

SELECT distinct Industry
FROM layoffs_staging2
order by 1;

Update layoffs_staging2
SET Industry = 'Crypto'
WHERE Industry Like 'Crypto%';


-- checking for other errors --

SELECT distinct Country
FROM layoffs_staging2
order by 1;

UPDATE layoffs_staging2
SET Country = 'United States'
Where Country LIKE 'United States%';

-- or we can use trailing --

UPDATE layoffs_staging2
SET Country = Trim(Trailing '.' FROM Country)
WHERE Country = 'United States%';

-- Converting the date from a string to an int
UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`,'%m/%d/%Y');

-- The data type is still a string after refereshing, so I'll alter the table
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

-- 3. Null values or blank Values --
-- if we look at industry it looks like we have some null and empty rows, let's take a look at these
SELECT *
FROM layoffs_staging2
WHERE industry IS NULL 
OR industry = ''
ORDER BY industry;

UPDATE layoffs_staging2
SET Industry = NULL 
WHERE Industry = '';

SELECT *
FROM layoffs_staging2
WHERE company = 'Airbnb'; 

SELECT t1.industry, t2.industry
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;

UPDATE layoffs_staging2 t1
Join layoffs_staging2 t2
ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry is NULL
AND t2.industry is NOT NULL;


-- Bally's is the only company that did not have multiple rows for us to draw populations for null rows for Industry --
SELECT *
FROM layoffs_staging2
WHERE company LIKE 'Bally%'; 

SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- Delete Useless data we can't really use
DELETE FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

ALTER TABLE layoffs_staging2
DROP COLUMN row_num;


-- EXPLORATORY DATA ANALYSIS

SELECT * 
FROM layoffs_staging2;

SELECT MAX(total_laid_off), MAX(percentage_laid_off)
FROM layoffs_staging2;

SELECT * 
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY total_laid_off desc;

SELECT *
FROM layoffs_staging2
WHERE  percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;

SELECT company, MAX(total_laid_off)
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC;

SELECT MIN(`date`), MAX(`date`)
FROM layoffs_staging2;

-- which industry had the most layoffs -- 
SELECT industry, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY industry
ORDER BY 2 DESC;

-- which country had the most layoffs -- 
SELECT country, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY country
ORDER BY 2 DESC;

SELECT YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY YEAR(`date`)
ORDER BY 1 DESC;

-- The progression of layoffs -- 


SELECT *
FROM layoffs_staging2;

SELECT SUBSTRING(`date`,1,7) AS `MONTH`, SUM(total_laid_off)
FROM layoffs_staging2
WHERE SUBSTRING(`date`,1,7) IS NOT NULL
GROUP BY `MONTH`
ORDER BY 1 ASC;


WITH Rolling_Total AS 
(
SELECT SUBSTRING(`date`,1,7) AS `MONTH`, SUM(total_laid_off) AS total_off
FROM layoffs_staging2
WHERE SUBSTRING(`date`,1,7) IS NOT NULL
GROUP BY `MONTH`
ORDER BY 1 ASC
)
 SELECT `MONTH`, total_off, SUM(total_off) OVER(ORDER BY `MONTH`) AS rolling_total
 FROM Rolling_Total; 
 
SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
ORDER BY 3 DESC;

-- top 5 companies with the most laid of people per year.
WITH Company_Year (company, years, total_laid_off) AS 
(
SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
),
Company_Year_Rank AS
(
SELECT *, 
DENSE_RANK() OVER (PARTITION BY years ORDER BY total_laid_off DESC) as Ranking
FROM Company_Year
WHERE years IS NOT NULL
)
SELECT *
FROM Company_Year_Rank
WHERE Ranking <= 5;