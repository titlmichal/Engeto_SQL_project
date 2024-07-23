USE engeto_2024_04_17;

/* ####################### TRANSFORMATION SCRIPT ####################### */

SELECT count(*) FROM czechia_payroll ;
SELECT DISTINCT count(*) FROM czechia_payroll cp ;
-- --> stejné počty --> nejsou duplicity v czechia_payroll

SELECT DISTINCT 
	cp.value_type_code,
	cpvt.name 
FROM czechia_payroll cp 
LEFT JOIN czechia_payroll_value_type cpvt 
	ON cp.value_type_code = cpvt.code 
-- --> 2 kódy: 316 = Průměrný počet zaměstnaných osob, 5958 = Průměrná hrubá mzda na zaměstnance
;
SELECT 
	value ,
	unit_code ,
	calculation_code ,
	industry_branch_code ,
	payroll_year ,
	payroll_quarter 
FROM czechia_payroll cp 
LEFT JOIN czechia_payroll_value_type cpvt 
	ON cp.value_type_code = cpvt.code 
WHERE cp.value_type_code = 316
-- --> průměrný počet zaměstnaných (value_type_coce = 316 )nebudu řešit, 
-- protože má mnoho missing a i když bych jím mohl vážit průměry, tak nelze posoudit reprezentativnost
;

SELECT * FROM czechia_payroll_unit;
-- unit_code 200 = Kč, 80403 = tisic osob
SELECT DISTINCT 
	unit_code,
	value_type_code 
FROM czechia_payroll cp ;
-- --> protože neřeším počet zaměstnaných a kód vždy souvisí s jedním typem --> budu řešit jen 200 (ale nemusel bych tam tu podmínku dávat)

SELECT * FROM czechia_payroll_calculation cpc ;
SELECT * FROM czechia_payroll cp
WHERE 
	cp.value_type_code = 5958
	AND cp.unit_code  = 200 
	AND cp.value IS NULL ;
SELECT count(*) 
FROM czechia_payroll cp 
WHERE calculation_code = 100;
SELECT count(*), payroll_year , payroll_quarter, industry_branch_code 
FROM czechia_payroll cp 
WHERE calculation_code = 100
GROUP BY payroll_year , payroll_quarter , industry_branch_code ;
SELECT count(*) FROM czechia_payroll cp ;
-- --> stejný počet přepočteného i fyzického, nejsou tam missing, není jasný způsob přepočtu --> použiju fyzický (kód 100)
-- poměr přepočtu mezi fyzickou a přepočtenou kalkulací je dost random (od 0,95 do 1,05), tak si vyberu fyzický
	-- mají stejný počet záznamů a přepočet není jasně dohledatelný
-- (1720 záznamů v posledním selectu, 20,5 roku --> 86 kvartálů --> 1720/86 = 19 (oborů) + 1 (null value obor))

SELECT * FROM czechia_payroll_industry_branch cpib ;
SELECT count(*), industry_branch_code 
FROM czechia_payroll cp
WHERE 
	cp.value_type_code = 5958
	AND cp.unit_code  = 200
	AND cp.calculation_code = 100
GROUP BY industry_branch_code ;
SELECT count(DISTINCT industry_branch_code) FROM czechia_payroll cp ;
SELECT DISTINCT industry_branch_code  FROM czechia_payroll cp ;
SELECT
	payroll_year ,
	payroll_quarter ,
	value ,
	industry_branch_code 
FROM czechia_payroll cp 
WHERE 
	cp.value_type_code = 5958
	AND cp.unit_code  = 200
	AND cp.calculation_code = 100
	AND cp.industry_branch_code IS NULL ;
SELECT
	cp.payroll_year ,
	cp.payroll_quarter ,
	round(sum(cp.value), 2) sum_value,
	round(avg(cp.value), 2) avg_value,
	addon.value,
	round(sum(cp.value/addon.value), 2) sum_value_divided_by_null_branch,
	round(avg(cp.value/addon.value), 2) avg_value_divided_by_null_branch
FROM czechia_payroll cp 
LEFT JOIN (
	SELECT
	payroll_year ,
	payroll_quarter ,
	value ,
	industry_branch_code 
FROM czechia_payroll cp 
WHERE 
	cp.value_type_code = 5958
	AND cp.unit_code  = 200
	AND cp.calculation_code = 100
	AND cp.industry_branch_code IS NULL 
) AS addon ON cp.payroll_year = addon.payroll_year AND cp.payroll_quarter = addon.payroll_quarter 
WHERE 
	cp.value_type_code = 5958
	AND cp.unit_code  = 200
	AND cp.calculation_code = 100
	AND cp.industry_branch_code IS NOT NULL 
GROUP BY cp.payroll_year, cp.payroll_quarter ;
-- je 19 odvětví + 1 null, přičemž všechny mají value a v rámci těch 19 existuje kategorie S jako ostatní činnosti,
-- přičemž NULL value u industry branch nepředstavuje (bez jasných informací o zastoupení odvětví v populaci) zřejmý přepočet z ostatních,
-- tudíž jej vyřazuji

SELECT * 
FROM czechia_payroll cp 
LEFT JOIN czechia_payroll_unit cpu
	ON cp.unit_code = cpu.code
LEFT JOIN czechia_payroll_value_type cpvt 
	ON cp.value_type_code = cpvt.code
LEFT JOIN czechia_payroll_calculation cpc 
	ON cp.calculation_code = cpc.code 
WHERE 
	cp.value_type_code = 5958
	AND cp.unit_code  = 200
	AND cp.calculation_code = 100
	AND cp.industry_branch_code IS NOT NULL
	AND cp.value IS NULL 
;
-- absence chybějících hodnot

-- TABULKA MEZD V ČR

CREATE TABLE IF NOT EXISTS mt_payroll AS
SELECT
	cp.id ,
	cp.value ,
	cp.value_type_code ,
	cpvt.name valuetype_name,
	cpu.code  payroll_unit_code,
	cpu.name payroll_unit_name,
	cpc.code calc_code,
	cpc.name calc_name,
	cpib.code branch_code,
	cpib.name branch_name,
	cp.payroll_year `year`,
	cp.payroll_quarter,
	e.GDP 
FROM czechia_payroll cp
LEFT JOIN czechia_payroll_calculation cpc 
	ON cp.calculation_code = cpc.code
LEFT JOIN czechia_payroll_industry_branch cpib
	ON cp.industry_branch_code = cpib.code 
LEFT JOIN czechia_payroll_unit cpu 
	ON cp.unit_code = cpu.code 
LEFT JOIN czechia_payroll_value_type cpvt 
	ON cp.value_type_code = cpvt.code
LEFT JOIN economies e 
	ON cp.payroll_year = e.year AND country = 'Czech Republic'
WHERE 
	cp.value_type_code = 5958
	AND cp.unit_code  = 200
	AND cp.calculation_code = 100
	AND cp.industry_branch_code IS NOT NULL
ORDER BY
	cp.payroll_year ,
	cp.payroll_quarter ,
	cp.industry_branch_code 
;
SELECT * FROM mt_payroll ;

-- TABULKA CEN POTRAVIN V ČR

SELECT count(*), category_code , region_code  
FROM czechia_price cp 
WHERE region_code IS NULL
GROUP BY category_code , region_code ;
SELECT count(*), category_code , region_code  
FROM czechia_price cp 
WHERE region_code IS NOT NULL
GROUP BY category_code , region_code ;
-- kategorie 212101 (jakostní víno) a 2000001 (kapr) mají nějaké malé počty záznamů

SELECT DISTINCT YEAR(date_from)  FROM czechia_price cp 
WHERE category_code IN (212101, 2000001)
ORDER BY YEAR(date_from) ;
SELECT DISTINCT YEAR(date_from)  FROM czechia_price cp 
WHERE category_code NOT IN (212101, 2000001)
ORDER BY YEAR(date_from) ;
-- záznamy ale mají pro každý rok, tak možná chybí u nějakých krajů?

SELECT category_code , count(DISTINCT region_code)
FROM czechia_price cp 
WHERE category_code NOT IN (212101, 2000001)
GROUP BY category_code ;
SELECT category_code , count(DISTINCT region_code)
FROM czechia_price cp 
WHERE category_code IN (212101, 2000001)
GROUP BY category_code ;
-- takže záznam mají pro každý kraj, tak možná množství měření v jednotlivých letech?

SELECT YEAR(date_from), category_code , count(DISTINCT date_from)
FROM czechia_price cp 
WHERE category_code NOT IN (212101, 2000001)
GROUP BY YEAR(date_from), category_code ;
SELECT YEAR(date_from), category_code , count(DISTINCT date_from)
FROM czechia_price cp 
WHERE category_code IN (212101, 2000001)
GROUP BY YEAR(date_from), category_code ;
SELECT YEAR(date_from), category_code , count(DISTINCT date_from)
FROM czechia_price cp 
WHERE category_code = 212101 
GROUP BY YEAR(date_from), category_code ;
SELECT DISTINCT month(date_from) FROM czechia_price cp WHERE category_code = 2000001
-- takže je to teda v jednotlivých letech, hlavně pro kapra dává smysl (sezónní potravina), takže ho vyřadím
-- víno nevyřadím, přestože je měřeno v méně letech než ostatní, ale množství měření má stejně jako ostatní pro dané roky
-- takže spíš na to budu myslet v případné interpretaci (!!!)

SELECT COUNT(*)
FROM czechia_price_category ;
SELECT DISTINCT COUNT(*)
FROM czechia_price_category ;
-- nejsou duplikáty

SELECT DISTINCT cpc.name, cp.category_code, cpc.price_value , cpc.price_unit 
FROM czechia_price cp LEFT JOIN czechia_price_category cpc ON cp.category_code = cpc.code ;
-- vše se zdá být měřeno vždy na stejné jednotky (v rámci dané kategorie potraviny)

SELECT DISTINCT datediff(date_from, date_to) FROM czechia_price cp ; 
-- vše měřeno po stejný počet dní
-- jako joinovací column použiju rok tak, že u cen určím rok skrze začátek měření a cenu za daný rok zprůměruju

SELECT
	cp.category_code,
	DATE(cp.date_from) date_start,
	round(avg(CASE WHEN cp.region_code IS NOT NULL THEN cp.value ELSE NULL END), 2) regions_avg,
	avg(CASE WHEN cp.region_code IS NULL THEN cp.value ELSE NULL END) nulls_avg,
	round(avg(CASE WHEN cp.region_code IS NOT NULL THEN cp.value ELSE NULL END), 2)-avg(CASE WHEN cp.region_code IS NULL THEN cp.value ELSE NULL END) value_compare
FROM czechia_price cp
LEFT JOIN czechia_price_category cpc 
	ON cp.category_code = cpc.code 
LEFT JOIN czechia_region cr 
	ON cp.region_code = cr.code
WHERE cp.category_code != 2000001
GROUP BY
	cp.category_code,
	DATE(cp.date_from)
ORDER BY 5 ASC  
;
SELECT count(*) FROM czechia_price cp WHERE region_code IS NULL ;
SELECT count(*) FROM czechia_region cr ;
SELECT count(*)/14 FROM czechia_price cp WHERE region_code IS NOT NULL ;
SELECT count(*) , DATE(date_from) 
FROM czechia_price cp 
WHERE region_code IS NULL 
GROUP BY DATE(date_from) ;
SELECT count(*)/14 , DATE(date_from) 
FROM czechia_price cp 
WHERE region_code IS NOT NULL 
GROUP BY DATE(date_from) ;
-- když je region_code null, tak to vypadá na průměr všech regionů
-- regiony v otázkách řešit nebudu, takže vezmu jen null region_codes (navíc počet měření se zdá být téměř stejný)

-- "předtabulka" pro první část tabulky ČR
CREATE TABLE IF NOT EXISTS mt_prices AS
SELECT
	cp.id,
	cp.value,
	cp.category_code,
	cpc.name category_name,
	cpc.price_value,
	cpc.price_unit,
	DATE(cp.date_from) date_start,
	DATE(cp.date_to) date_end
FROM czechia_price cp
LEFT JOIN czechia_price_category cpc 
	ON cp.category_code = cpc.code 
LEFT JOIN czechia_region cr 
	ON cp.region_code = cr.code
WHERE cp.category_code != 2000001 AND cp.region_code IS NULL
ORDER BY cpc.name DESC, cp.date_from ASC
;
SELECT * FROM mt_prices mp ;

SELECT YEAR(date_start) 
--	, category_name 
	, count(*)
FROM mt_prices mp 
GROUP BY 
	YEAR(date_start) 
--	, category_name;
-- počty měření jsou stejné --> průměrovat v rámci roku se zdá legitimní

-- první částa tabulky pro ČR
CREATE TABLE IF NOT EXISTS mt_prices2 AS
SELECT
	round(avg(value), 2) avg_price_per_year ,
	category_code ,
	category_name ,
	price_value ,
	price_unit ,
	YEAR(date_start) year
FROM mt_prices 
GROUP BY category_code , category_name , price_value , price_unit , YEAR(date_start);
SELECT * FROM mt_prices2;

SELECT
	category_name ,
	count(avg_price_per_year)
FROM mt_prices2 mp 
GROUP BY 1;


-- druhá část tabulky pro ČR
SELECT 
	`year` 
--	, branch_name 
	, count(*) 
FROM mt_payroll mp 
GROUP BY 
	`year` 
--	, branch_name 
;
-- počet záznamů odpovídá množství odvětví a měřených kvartálů --> průměrovat kvartály se zdá legitimní

-- druhá část tabulky pro ČR
CREATE TABLE IF NOT EXISTS mt_payroll2 AS
SELECT
	avg(value) avg_value,
	avg(GDP) avg_GDP,
	`year` ,
	calc_code ,
	calc_name ,
	branch_code,
	branch_name
FROM mt_payroll mp
GROUP BY 
	`year` ,
	calc_code ,
	calc_name ,
	branch_code,
	branch_name
;
SELECT * FROM mt_payroll2;

-- TABULKA MEZD A POTRAVIN V ČR (kombinace dvou výše)
SELECT count(*) FROM mt_prices2 mp 
LEFT JOIN mt_payroll2 mp2 
	ON mp.`year` = mp2.`year` ;
SELECT count(*) FROM mt_payroll2 mp 
LEFT JOIN mt_prices2 mp2 
	ON mp.`year` = mp2.`year` ;
SELECT min(`year`), max(`year`) FROM mt_payroll2 mp ;
SELECT min(`year`), max(`year`) FROM mt_prices2 mp ;
-- left join s připojení mezd dává o několik míň záznamů, protože ceny jsou jen od 2006 do 2018 (mzdy 2000-2021)
-- chci řešit porovnatelná období, takže bych mohl právě připojit mzdy na ceny nebo udělat inner join
-- takže až budu pracovat se samostnými mzdami, musím si hodit distinct, když budu volit jen mzdy (!!!)

CREATE TABLE IF NOT EXISTS t_Michal_Titl_project_SQL_primary_final AS
SELECT
	mp.avg_price_per_year ,
	mp.`year` ,
	mp.category_code ,
	mp.category_name ,
	mp.price_value ,
	mp.price_unit ,
	mp2.avg_value avg_pay,
	mp2.avg_GDP ,
	mp2.branch_code ,
	mp2.branch_name 
FROM mt_prices2 mp 
LEFT JOIN mt_payroll2 mp2 
	ON mp.`year` = mp2.`year` ;

SELECT * FROM t_Michal_Titl_project_SQL_primary_final;

-- TABULKA DODATEČNÝCH DAT PRO DALŠÍ EVROPSKÉ ZEMĚ VE STEJNÉM OBDOBÍ

CREATE TABLE IF NOT EXISTS t_Michal_Titl_project_SQL_secondary_final AS
SELECT *
FROM economies 
WHERE `year` BETWEEN 2006 AND 2018
	AND country IN ('Central Europe and the Baltics', 'Euro area', 'European Union')
UNION
SELECT *
FROM economies 
WHERE `year` BETWEEN 2006 AND 2018 
	AND country IN (
	'Albania', 'Andorra', 'Armenia', 'Austria',
    'Belarus', 'Belgium', 'Bosnia and Herzegovina', 'Bulgaria',
    'Croatia', 'Cyprus', 'Czech Republic', 'Denmark',
    'Estonia', 'Finland', 'France', 'Georgia',
    'Germany', 'Greece', 'Hungary', 'Iceland',
    'Ireland', 'Italy', 'Kosovo', 'Latvia',
    'Liechtenstein', 'Lithuania', 'Luxembourg', 'Malta',
    'Moldova', 'Monaco', 'Montenegro', 'Netherlands',
    'North Macedonia', 'Norway', 'Poland', 'Portugal',
    'Romania', 'San Marino', 'Serbia', 'Slovakia',
    'Slovenia', 'Spain', 'Sweden', 'Switzerland',
    'Ukraine', 'United Kingdom', 'Vatican City'
	)
UNION
SELECT
	'European countries (GPT generated)' country,
	`year`,
	round(sum(GDP), 2) GDP,
	round(sum(population), 2) population,
	round(avg(gini), 2) gini,
	round(avg(taxes), 2) taxes,
	round(avg(fertility), 2) fertility,
	round(avg(mortaliy_under5), 2) mortaliy_under5
FROM economies 
WHERE `year` BETWEEN 2006 AND 2018 
	AND country IN (
	'Albania', 'Andorra', 'Armenia', 'Austria',
    'Belarus', 'Belgium', 'Bosnia and Herzegovina', 'Bulgaria',
    'Croatia', 'Cyprus', 'Czech Republic', 'Denmark',
    'Estonia', 'Finland', 'France', 'Georgia',
    'Germany', 'Greece', 'Hungary', 'Iceland',
    'Ireland', 'Italy', 'Kosovo', 'Latvia',
    'Liechtenstein', 'Lithuania', 'Luxembourg', 'Malta',
    'Moldova', 'Monaco', 'Montenegro', 'Netherlands',
    'North Macedonia', 'Norway', 'Poland', 'Portugal',
    'Romania', 'San Marino', 'Serbia', 'Slovakia',
    'Slovenia', 'Spain', 'Sweden', 'Switzerland',
    'Ukraine', 'United Kingdom', 'Vatican City'
	)
GROUP BY `year` 
;

SELECT * FROM t_Michal_Titl_project_SQL_secondary_final
	WHERE gini IS NULL OR  taxes IS NULL OR fertility IS NULL OR mortaliy_under5 IS NULL 
;