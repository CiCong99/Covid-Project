------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------PHÂN TÍCH CÁ NHÂN-COVID-------------------------------------------------------------------
-- 1. Truy vấn liên quan đến CovidDeaths 
-- * Dữ liệu từ 01/01/2020 - 30/08/2023
			/* Tổng quan : 
			1.1 Tổng số ca mắc và tử vong theo từng quốc gia.											
			1.2 Tổng số ca mắc và tử vong theo từng khu vực trên thế giới .						
			1.3 Tỷ lệ tử vong trên toàn cầu.																							
			1.4 Quốc gia có số người chết cao nhất .
			1.5 Quốc gia có số người chết cao nhất tính theo tỉ lệ phần trăm dân số.
			1.6 Quốc gia có tỷ lệ nhiễm cao nhất so với dân số.
			1.7 Tỷ lệ tử vong nếu mắc Covid tại nước Mỹ.
			1.8 Số lượng ca nhiễm và ca tử vong trong các tháng theo quốc gia.
			1.9 TOP 10 quốc gia có tỷ lệ tử vong cao nhất.
			*/
--1.1 Tổng số ca mắc và tử vong theo từng quốc gia 
SELECT location
	,SUM(new_cases) AS total_cases
	, SUM(new_deaths) AS total_deaths
FROM dbo.CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY location
ORDER BY total_cases DESC



--1.2 Tổng số ca mắc và tử vong theo từng khu vực trên thế giới 
SELECT continent
	,SUM(new_cases) AS Total_Cases
	--, CAST(total_cases AS bigint) AS total_cases
	, MAX(total_deaths) AS Total_Deaths
FROM dbo.CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY continent
ORDER BY Total_Deaths DESC



--1.3 Tỷ lệ tử vong trên toàn cầu
SELECT
	SUM(new_cases) AS Total_cases
	,SUM(new_deaths) AS Total_deaths
	,SUM(new_deaths)*1.0 / SUM(new_cases)*100 AS DeathPercentage 
FROM dbo.CovidDeaths
WHERE continent IS NOT NULL 
ORDER BY  1,2



--1.4 Quốc gia có số người chết cao nhất 
SELECT location
	,MAX(total_deaths) AS TotalDeathCount
FROM dbo.CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY location
ORDER BY  TotalDeathCount DESC



--1.5 Quốc gia có số người chết cao nhất tính theo tỉ lệ phần trăm dân số
WITH DeathsAndPopulation AS (
    SELECT location, population, MAX(total_deaths) AS HighestDeathCount,
        MAX(total_deaths) * 1.0 / population * 100 AS PercentPopulationDeath
    FROM dbo.CovidDeaths
    GROUP BY location, population
)
SELECT location, population, HighestDeathCount, PercentPopulationDeath
FROM DeathsAndPopulation
ORDER BY PercentPopulationDeath DESC


--1.6  Quốc gia có tỷ lệ nhiễm cao nhất so với dân số
SELECT location
	,population
	,MAX(total_cases) AS HighestInfectionCount
	,MAX((total_cases*1.0/population))*100 AS PercentPopulationInfected
FROM dbo.CovidDeaths
GROUP BY location,population
ORDER BY PercentPopulationInfected DESC



--1.7  Tỷ lệ tử vong nếu mắc Covid tại nước Mỹ 
SELECT location
	,date
	,total_cases
	,total_deaths
	,(total_deaths*1.0/total_cases)*100 AS DeathPercentage
FROM dbo.CovidDeaths
WHERE location LIKE '%State%'
AND continent is not null
ORDER BY 1,2


--1.8 Số lượng ca nhiễm và ca tử vong trong các tháng theo quốc gia
SELECT location
	, continent
	, MONTH(date) AS month
	, SUM(total_cases) AS total_cases, SUM(total_deaths) AS total_deaths
FROM dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, continent, MONTH(date)
ORDER BY location, month


--1.9 TOP 10 quốc gia có tỷ lệ tử vong cao nhất.
WITH HotspotCalculation AS (
    SELECT
        d.location,
        SUM(d.total_deaths) * 1.0 / SUM(d.total_cases) AS death_rate
    FROM CovidDeaths d
    GROUP BY d.location
)
SELECT TOP 10
    location,
    death_rate
FROM HotspotCalculation
ORDER BY death_rate DESC




--2. Truy vấn liên quan đến CovidVaccin:
			/* Tổng quan : 
			2.1 Top 5 quốc gia có số lượt tiêm chủng nhiều nhất.
			2.2 Tổng số lượt tiêm chủng và tỷ lệ tiêm chủng trên tổng dân số theo quốc gia và khu vực.
			2.3 Tỉ lệ tiêm vaccine cao nhất và thấp nhất theo khu vực và quốc gia.
			*/
--2.1 Top 5 quốc gia có số lượt tiêm chủng nhiều nhất
SELECT TOP 5 location
	, MAX(people_vaccinated) AS max_people_vaccinated
FROM dbo.CovidVaccinations
WHERE continent IS NOT NULL AND people_vaccinated IS NOT NULL
GROUP BY location
ORDER BY max_people_vaccinated DESC


--2.2 Tổng số lượt tiêm chủng và tỷ lệ tiêm chủng trên tổng dân số theo quốc gia và khu vực
SELECT cv.location
	, cv.continent
	, MAX(cv.total_vaccinations) AS total_vaccinations
	, MAX(dea.population) AS population
    ,  CAST(MAX(cv.total_vaccinations) AS FLOAT) / MAX(dea.population) * 100 AS vaccination_rate
FROM dbo.CovidVaccinations  cv
JOIN dbo.CovidDeaths dea
ON dea.location = cv.location 
	AND dea.date = cv.date 
WHERE cv.continent IS NOT NULL AND cv.total_vaccinations IS NOT NULL AND dea.population IS NOT NULL
GROUP BY cv.location, cv.continent
ORDER BY vaccination_rate DESC



--2.3 Tỉ lệ tiêm vaccine cao nhất và thấp nhất theo khu vực và quốc gia.
WITH VaccinationRates AS (
    SELECT
        v.location,
        v.continent,
        v.date,
        MAX(v.total_vaccinations) * 1.0 / d.population AS vaccination_rate
    FROM CovidVaccinations v
    JOIN CovidDeaths d ON v.location = d.location AND v.date = d.date
    GROUP BY v.location, v.continent, v.date, d.population
)

-- Tỉ lệ tiêm vaccine cao nhất và thấp nhất theo quốc gia
SELECT
    location,
    MAX(vaccination_rate) AS max_vaccination_rate,
    MIN(vaccination_rate) AS min_vaccination_rate
FROM VaccinationRates
GROUP BY location

UNION

-- Tỉ lệ tiêm vaccine cao nhất và thấp nhất theo khu vực
SELECT
    continent AS location,
    MAX(vaccination_rate) AS max_vaccination_rate,
    MIN(vaccination_rate) AS min_vaccination_rate
FROM VaccinationRates
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY location





--3. Các truy vấn dữ liệu chuyên sâu và ý nghĩa của nó.
			/* Tổng quan : 
						3.1 Độ lệch chuẩn của số ca tử vong và số liều vaccine đã tiêm.
						3.2 Số ca tử vong trước và sau khi bắt đầu tiêm chủng.
						3.3 Có sự khác biệt như thế nào giữa các quốc gia có dân số lớn so với quốc gia có dân số nhỏ về tỷ lệ tiêm chủng.  
						3.4 Có quốc gia nào đã tiêm chủng cho hơn 70% dân số và hiện không có ca mắc mới.
			*/
--3.1 Độ lệch chuẩn của số ca tử vong và số liều vaccine đã tiêm.
WITH DeathStats AS (
    SELECT 
        AVG(total_deaths) AS average_deaths, 
        STDEV(total_deaths) AS std_dev_deaths 
    FROM CovidDeaths
),
VaccinationStats AS (
    SELECT 
        AVG(total_vaccinations) AS average_vaccinations, 
        STDEV(total_vaccinations) AS std_dev_vaccinations 
    FROM CovidVaccinations
)
SELECT 
    d.average_deaths, 
    d.std_dev_deaths, 
    v.average_vaccinations, 
    v.std_dev_vaccinations 
FROM DeathStats d, VaccinationStats v
/* Độ lệch chuẩn gấp 4-5 lần giá trị trung bình. Điều này cho thấy có sự biến động lớn về số ca tử vong giữa các quốc gia. Một số quốc gia có thể có số ca tử vong rất cao, trong khi một số quốc gia khác có số ca tử vong thấp.
Một số quốc gia có dân số lớn và tài nguyên tốt có thể đã tiêm một số lượng vaccine rất lớn, trong khi một số quốc gia nhỏ và ít tài nguyên hơn có thể chỉ tiêm một số lượng vaccine nhỏ. */



--3.2 Số ca tử vong trước và sau khi bắt đầu tiêm chủng.
WITH VaccinationStartDate AS (
    SELECT 
        location,
        MIN(date) AS start_vaccination_date
    FROM CovidVaccinations
    WHERE total_vaccinations > 0
    GROUP BY location
)
SELECT
    v.location AS country,
    v.start_vaccination_date,
    SUM(CASE WHEN d.date < v.start_vaccination_date THEN new_deaths ELSE 0 END) AS deaths_before_vaccination,
    SUM(CASE WHEN d.date >= v.start_vaccination_date THEN new_deaths ELSE 0 END) AS deaths_after_vaccination
FROM VaccinationStartDate v
JOIN CovidDeaths d ON v.location = d.location
GROUP BY v.location, v.start_vaccination_date
/* Kết quả truy vấn có thể cho thấy tác động tích cực của việc tiêm chủng lên số ca tử vong tại mỗi quốc gia. 
Đối với các quốc gia mà số ca tử vong sau khi tiêm chủng vẫn cao hoặc tăng lên, điều này có thể cho thấy rằng việc tiêm chủng chưa đạt hiệu quả mong muốn hoặc các biến thể mới của virus đã xuất hiện và gây ra tác động. */



--3.3 Có sự khác biệt như thế nào giữa các quốc gia có dân số lớn so với quốc gia có dân số nhỏ về tỷ lệ tiêm chủng.  
WITH VaccinationRateByCountry AS (
    SELECT
        v.location,
        d.population,
        CASE
            WHEN d.population >= 50000000 THEN 'Large Population' -- Đất nước có dân số lớn hơn 50tr người là nước có dân số lớn 
            ELSE 'Small Population'
        END AS population_category,
        MAX(v.total_vaccinations) * 100.0 / d.population AS vaccination_rate_percentage
    FROM CovidVaccinations v
    JOIN CovidDeaths d ON v.location = d.location
    GROUP BY v.location, d.population
)
SELECT
    population_category,
    AVG(vaccination_rate_percentage) AS avg_vaccination_rate_percentage,
    MAX(vaccination_rate_percentage) AS max_vaccination_rate_percentage,
    MIN(vaccination_rate_percentage) AS min_vaccination_rate_percentage
FROM VaccinationRateByCountry
GROUP BY population_category
/* - Dân số nhỏ (Small Population):
	+ Tỉ lệ tiêm chủng trung bình: 150.17%. Điều này có nghĩa là, trung bình, trong các quốc gia có dân số nhỏ, mỗi người đã tiêm được khoảng 1.5 liều vaccine.
	+ Tỉ lệ tiêm chủng cao nhất: 406.76%. Có một quốc gia (hoặc nhiều quốc gia) có dân số nhỏ mà mỗi người đã tiêm được khoảng 4 liều vaccine.
	+ Tỉ lệ tiêm chủng thấp nhất: 0.32%. Có một quốc gia (hoặc nhiều quốc gia) có dân số nhỏ mà mỗi người chỉ tiêm được 0.32% của một liều vaccine.
- Dân số lớn (Large Population):
	+Tỉ lệ tiêm chủng trung bình: 170.47%. Điều này có nghĩa là, trung bình, trong các quốc gia có dân số lớn, mỗi người đã tiêm được khoảng 1.7 liều vaccine.
	+Tỉ lệ tiêm chủng cao nhất: 309.59%. Có một quốc gia (hoặc nhiều quốc gia) có dân số lớn mà mỗi người đã tiêm được khoảng 3 liều vaccine.
	+Tỉ lệ tiêm chủng thấp nhất: 18.997%. Có một quốc gia (hoặc nhiều quốc gia) có dân số lớn mà mỗi người chỉ tiêm được khoảng 19% của một liều vaccine.
-Phân tích:
	+Cả hai nhóm quốc gia (dân số lớn và dân số nhỏ) đều có tiến triển tốt trong việc tiêm chủng, với tỷ lệ tiêm chủng trung bình trên 1 liều vaccine cho mỗi người.
	+Một số quốc gia đã tiến gần tới mục tiêu của 4 liều vaccine cho mỗi người.
	+Tuy nhiên, vẫn còn một số quốc gia có tỷ lệ tiêm chủng thấp, điều này cho thấy có nhu cầu cần tăng cường việc tiêm chủng ở những nơi này. */



--3.4 Có quốc gia nào đã tiêm chủng cho hơn 70% dân số và hiện không có ca mắc mới.
/* Các bước 
B1.Xác định các quốc gia đã tiêm chủng cho hơn 70% dân số:  Tính tỷ lệ tiêm chủng cho mỗi quốc gia và lọc ra những quốc gia có tỷ lệ tiêm chủng trên 70%.
B2.Kiểm tra các quốc gia không có ca mắc mới: Dựa trên dữ liệu mới nhất (ngày gần nhất) */
WITH HighVaccinationRate AS (
    SELECT
        v.location,
        (MAX(v.total_vaccinations) * 1.0 / d.population) * 100 AS vaccination_rate_percentage
    FROM CovidVaccinations v
    JOIN CovidDeaths d ON v.location = d.location
    GROUP BY v.location, d.population
    HAVING (MAX(v.total_vaccinations) * 1.0 / d.population) * 100 > 70
)

, LatestData AS (
    SELECT
        location,
        MAX(date) AS latest_date
    FROM CovidDeaths
    GROUP BY location
)

SELECT 
    hvr.location,
    hvr.vaccination_rate_percentage
FROM HighVaccinationRate hvr
JOIN LatestData ld ON hvr.location = ld.location
JOIN CovidDeaths d ON d.location = ld.location AND d.date = ld.latest_date
WHERE d.new_cases = 0
ORDER BY hvr.vaccination_rate_percentage DESC

/* Đánh giá 
1. Hiệu suất của chiến dịch tiêm chủng: Những quốc gia đã tiêm chủng cho hơn 70% dân số cho thấy họ đã thực hiện một chiến dịch tiêm chủng rất hiệu quả. Tỉ lệ tiêm chủng cao thường liên quan đến việc giảm sự lây lan của vi rút.
2. Tình hình kiểm soát dịch bệnh: Không có ca mắc mới trong những quốc gia này cho thấy họ không chỉ tiêm chủng hiệu quả mà còn thực hiện tốt các biện pháp kiểm soát dịch bệnh khác.
3. Mô hình để học hỏi: Những quốc gia này có thể được xem xét như những mô hình cho các quốc gia khác. Cách họ triển khai chiến dịch tiêm chủng và các biện pháp kiểm soát dịch bệnh có thể cung cấp những bài học quý giá cho các nước khác đang cố gắng kiểm soát dịch bệnh và tăng tỷ lệ tiêm chủng.
4. Đánh giá tác động của vaccine: Đây cũng là một cách để đánh giá tác động thực tế của việc tiêm chủng trong cộng đồng. Một tỷ lệ tiêm chủng cao kết hợp với việc không có ca mắc mới là một dấu hiệu tích cực cho thấy vaccine đang hoạt động hiệu quả. */


