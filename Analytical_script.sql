USE engeto_2024_04_17;

SELECT * FROM t_michal_titl_project_sql_primary_final tmtpspf ;
SELECT * FROM t_michal_titl_project_sql_secondary_final tmtpssf ;

/* ####################### ANALYTICAL SCRIPT ####################### */

/*
1) Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?
Odpověď: Ne, mezi lety 2008 a 2015 lze najít období a obory (24 případů), 
kdy mzdy meziročně klesaly a to v rozmezí -9 % až - 0,1 %, průměrně -1,83 % (pro zasažená odvětví).
*/				

-- srovnání poklesů/růstů mezd od nejnížší
SELECT DISTINCT 
	primary1.`year` ,
	primary1.branch_name ,
	primary1.avg_pay ,
	primary2.avg_pay avg_pay_next_year ,
	round((primary2.avg_pay/primary1.avg_pay-1)*100, 2) pay_diff_in_perc
FROM t_Michal_Titl_project_SQL_primary_final primary1
JOIN t_Michal_Titl_project_SQL_primary_final primary2
	ON primary1.`year` = primary2.`year` - 1
	AND primary1.branch_code = primary2.branch_code
ORDER BY 5, primary1.`year`, primary2.`year`, primary1.branch_code, primary2.branch_code ;

-- dodatečné údaje o změnách mezd
SELECT
	min(`year`),
	max(`year`),
	min(pay_diff_in_perc),
	max(pay_diff_in_perc),
	avg(pay_diff_in_perc)
FROM 
(
SELECT DISTINCT 
	primary1.`year` ,
	primary1.branch_code ,
	primary1.branch_name ,
	primary1.avg_pay ,
	primary2.avg_pay avg_pay_next_year ,
	round((primary2.avg_pay/primary1.avg_pay-1)*100, 2) pay_diff_in_perc
FROM t_Michal_Titl_project_SQL_primary_final primary1
JOIN t_Michal_Titl_project_SQL_primary_final primary2
	ON primary1.`year` = primary2.`year` - 1
	AND primary1.branch_code = primary2.branch_code
ORDER BY 6, primary1.`year`, primary2.`year`, primary1.branch_code, primary2.branch_code
) AS base
WHERE pay_diff_in_perc < 0;

/*
2) Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?
Odpověď: Za celkovou průměrnou mzdu bylo možné v roce 2006 koupit 1261,93 kg chleba a 1408,75 l mléka,
v roce 2018 to bylo 1319,32 kg chleba a 1613,53 l mléka. Celkové rozpětí kg/l za průměrnou mzdu v daném odvětví za sledované období bylo
688,94 kg až 2288,56 kg u chleba a 769,1 l až 2798,93 l mléka.
*/				

SELECT
	`year` ,
	category_name ,
	branch_name ,
	avg_pay ,
	avg_price_per_year 
FROM t_michal_titl_project_sql_primary_final base 
WHERE YEAR IN (2006, 2018) AND base.category_name IN ('Mléko polotučné pasterované', 'Chléb konzumní kmínový')
ORDER BY 3, 2 , 1
;
-- srovnání množství mléka a chleba za průměrnou mdzu pro všechna sledovaná období a obory vč. celkového pohledu
-- pro průměrný pohled (druhý select) beru průměr množství všech oborů
SELECT
	`year` ,
	category_name ,
	branch_name ,
	CASE
		WHEN `year` = 2006 THEN ROUND(avg_pay/avg_price_per_year, 2) 
		ELSE NULL
	END milk_or_bread_2006,
	CASE
		WHEN `year` = 2018 THEN ROUND(avg_pay/avg_price_per_year, 2) 
		ELSE NULL
	END milk_or_bread_2018
FROM t_Michal_Titl_project_SQL_primary_final base
WHERE YEAR IN (2006, 2018) AND base.category_name IN ('Mléko polotučné pasterované', 'Chléb konzumní kmínový')
-- ORDER BY branch_name;
UNION
SELECT
	`year` ,
	category_name ,
	'#All branches' branch_name,
	ROUND(avg(CASE
		WHEN `year` = 2006 THEN avg_pay/avg_price_per_year 
		ELSE NULL
	END), 2) milk_or_bread_2006,
	ROUND(avg(CASE
		WHEN `year` = 2018 THEN avg_pay/avg_price_per_year 
		ELSE NULL
	END), 2) milk_or_bread_2018
FROM t_Michal_Titl_project_SQL_primary_final base
WHERE YEAR IN (2006, 2018) AND base.category_name IN ('Mléko polotučné pasterované', 'Chléb konzumní kmínový')
GROUP BY `year` , category_name
ORDER BY branch_name
;

-- srovnání krajních hodnot
SELECT
	`year`,
	category_name ,
	min(milk_or_bread_2006),
	max(milk_or_bread_2018)
FROM (
SELECT
	`year` ,
	category_name ,
	branch_name ,
	CASE
		WHEN `year` = 2006 THEN ROUND(avg_pay/avg_price_per_year, 2) 
		ELSE NULL
	END milk_or_bread_2006,
	CASE
		WHEN `year` = 2018 THEN ROUND(avg_pay/avg_price_per_year, 2) 
		ELSE NULL
	END milk_or_bread_2018
FROM t_Michal_Titl_project_SQL_primary_final base
WHERE YEAR IN (2006, 2018) AND base.category_name IN ('Mléko polotučné pasterované', 'Chléb konzumní kmínový')
-- ORDER BY branch_name;
UNION
SELECT
	`year` ,
	category_name ,
	'All branches' branch_name,
	ROUND(avg(CASE
		WHEN `year` = 2006 THEN avg_pay/avg_price_per_year 
		ELSE NULL
	END), 2) milk_or_bread_2006,
	ROUND(avg(CASE
		WHEN `year` = 2018 THEN avg_pay/avg_price_per_year 
		ELSE NULL
	END), 2) milk_or_bread_2018
FROM t_Michal_Titl_project_SQL_primary_final base
WHERE YEAR IN (2006, 2018) AND base.category_name IN ('Mléko polotučné pasterované', 'Chléb konzumní kmínový')
GROUP BY `year` , category_name
ORDER BY branch_name
) AS base
GROUP BY 1,2;

/*
3) Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)?
Odpověď: Záleží na přesném znění otázky. Pokud lze brát jako nejnižší nárůst i nárůst negativní, tak jsou to rajská jablka s negativním nárůstem
		-30,28 % mezi 2006 a 2007, u kterých mj. cena meziročně klesala několikrát. Pokud řešíme pouze pozitivní nárůsty, tak je to rostlinný tuk
		s téměř neznatelným růstem 0,01 % mezi lety 2008 a 2009. Zároveň se lze také dívat na agregace růstů/poklesů. V případě zahrnutí i negativních
		inkrementů, tak průměrně klesala cena nejvíce u krystalového cukru (- 1,92 %) a rajských jablek (- 0,74%), v případě pozitivních inkrementů jsou
		to pak banány (0,81 %). Při pohledu na sumu inkrementů (pozitivních i negativních) je pohled podobný, přičemž u cukru se jedná o - 23,03 %, u
		jablek o - 8,88 % a nejnižší pozitivní sumu inkrementů má jakostní víno (8,1 %), následované banány (9,69 %). Celkově lze tedy říci, že malé
		inkrementy sledujeme u jablek, cukru a banánů, ať už pohledem průměrů, sum nebo změny cen let z roku 2006 na rok 2018.
*/ 

-- hledání nejnižšího/nejvyššího cenového nárůstu
SELECT DISTINCT 
	primary1.avg_price_per_year price1,
	primary2.avg_price_per_year price_plus_1_year,
	primary1.`year` ,
	primary2.`year` next_year,
	round((primary2.avg_price_per_year/primary1.avg_price_per_year - 1)*100, 2) yearly_perc_increment,
	primary1.category_name 
FROM t_Michal_Titl_project_SQL_primary_final primary1
 LEFT JOIN t_Michal_Titl_project_SQL_primary_final primary2
	ON primary1.`year` = primary2.`year` - 1
	AND primary1.category_code = primary2.category_code
WHERE primary2.`year` IS NOT NULL 
ORDER BY round((primary2.avg_price_per_year/primary1.avg_price_per_year - 1)*100, 2) ASC 
;

-- suma a průměr inkrementů
SELECT
	category_name,
	sum(yearly_perc_increment) sum_of_increments,
	avg(yearly_perc_increment) avg_increment
FROM 
(
SELECT DISTINCT 
	primary1.avg_price_per_year price1,
	primary2.avg_price_per_year price_plus_1_year,
	primary1.`year` ,
	primary2.`year` next_year,
	round((primary2.avg_price_per_year/primary1.avg_price_per_year - 1)*100, 2) yearly_perc_increment,
	primary1.category_name 
FROM t_Michal_Titl_project_SQL_primary_final primary1
 LEFT JOIN t_Michal_Titl_project_SQL_primary_final primary2
	ON primary1.`year` = primary2.`year` - 1
	AND primary1.category_code = primary2.category_code
WHERE primary2.`year` IS NOT NULL 
ORDER BY 5 ASC
) AS base
GROUP BY 1
ORDER BY 2 ASC
;

-- výpočet směrodatné odchylky
CREATE TEMPORARY TABLE st_devs
WITH st_dev AS (
SELECT
	category_name,
	avg(yearly_perc_increment) avg_increment
FROM (
SELECT DISTINCT 
	primary1.category_name , 
	round((primary2.avg_price_per_year/primary1.avg_price_per_year - 1)*100, 2) yearly_perc_increment 
FROM t_Michal_Titl_project_SQL_primary_final primary1
 LEFT JOIN t_Michal_Titl_project_SQL_primary_final primary2
	ON primary1.`year` = primary2.`year` - 1
	AND primary1.category_code = primary2.category_code
WHERE primary2.`year` IS NOT NULL 
ORDER BY category_name, primary1.`year` 
) AS base 
GROUP BY category_name
)
SELECT 
	primary1.category_name,
	round(SQRT(SUM(POW((primary2.avg_price_per_year/primary1.avg_price_per_year - 1)*100, 2) - st_dev.avg_increment)
	/(COUNT(*) - 1)), 2) std_dev
FROM t_Michal_Titl_project_SQL_primary_final primary1
 LEFT JOIN t_Michal_Titl_project_SQL_primary_final primary2
	ON primary1.`year` = primary2.`year` - 1
	AND primary1.category_code = primary2.category_code
 LEFT JOIN st_dev
 	ON primary1.category_name = st_dev.category_name
WHERE primary2.`year` IS NOT NULL 
GROUP BY primary1.category_name
ORDER BY 2 DESC 
;

-- srovnání 2006 X 2018
SELECT DISTINCT 
	primary1.avg_price_per_year price1_2006,
	primary2.avg_price_per_year price_2018,
	round((primary2.avg_price_per_year/primary1.avg_price_per_year - 1)*100, 2) perc_increment,
	primary1.category_name 
FROM t_Michal_Titl_project_SQL_primary_final primary1
 LEFT JOIN t_Michal_Titl_project_SQL_primary_final primary2
	ON primary1.`year` = primary2.`year` - 12
	AND primary1.category_code = primary2.category_code
WHERE primary2.`year` IS NOT NULL AND primary1.`year` = 2006
ORDER BY round((primary2.avg_price_per_year/primary1.avg_price_per_year - 1)*100, 2) ASC
;

/*
4) Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)? 
Odpověď: Záleží na operacionalizaci obecné cenové hladiny v datasetu, průměrné mzdy a samotného rozdílu. V případě, že bychom předpokládali, 
že lidé nakupují vždy 1 jednotku zboží z dat potravin a že průměrná mzda je bežným průměrem z dostupných dat o mzdách, tak:
	- v případě jednoduchého rozdílů procentuálních meziročních přírůstků ne, spíše naopak
	- v případě procentuálního srovnání samotných přírůstků mezi sebou lze říci, že v letech vůči předchozímu roku v letech 2011 až 2013 a 2017
	byl procentuální přírůstek cen potravin o více než 10 % vyšší (z výše přírůstku mezd)
*/

-- růst cen potravin jako rozdíl sum --> potřeba zvalidovat a checknout, jestli jsou tam stejné počty a obecně předpoklady splněny

-- tvorba menších tabulek pro snazší zpracování
CREATE TEMPORARY TABLE base_table_1
SELECT DISTINCT 
	sum(primary1.avg_price_per_year) price1,
	sum(primary2.avg_price_per_year) price_plus_1_year,
	round((sum(primary2.avg_price_per_year)/sum(primary1.avg_price_per_year) - 1) * 100, 2) yearly_perc_increment,
	primary1.`year` ,
	primary2.`year` next_year
FROM t_Michal_Titl_project_SQL_primary_final primary1
 LEFT JOIN t_Michal_Titl_project_SQL_primary_final primary2
	ON primary1.`year` = primary2.`year` - 1
	AND primary1.category_code = primary2.category_code
WHERE primary2.`year` IS NOT NULL
GROUP BY primary1.`year` , primary2.`year` 
;

SELECT DISTINCT 
	sum(primary1.avg_price_per_year) price1,
	sum(primary2.avg_price_per_year) price_plus_1_year,
--	count(primary1.avg_price_per_year) ct_price1,
--	count(primary2.avg_price_per_year) ct_price_2,
	round((sum(primary2.avg_price_per_year)/sum(primary1.avg_price_per_year) - 1) * 100, 2) yearly_perc_increment,
	primary1.`year` ,
	primary2.`year` next_year
FROM t_Michal_Titl_project_SQL_primary_final primary1
 LEFT JOIN t_Michal_Titl_project_SQL_primary_final primary2
	ON primary1.`year` = primary2.`year` - 1
	AND primary1.category_code = primary2.category_code
WHERE primary2.`year` IS NOT NULL
GROUP BY primary1.`year` , primary2.`year` 
;

-- tvorba menších tabulek pro snazší zpracování
CREATE TEMPORARY TABLE base_table_2
SELECT DISTINCT 
	primary1.`year` ,
	primary2.`year` year_plus_one,
	round(primary1.avg_pay) avg_of_avg_pay,
	round(primary2.avg_pay) avg_of_avg_pay_plus_1yr,
	round((primary2.avg_pay/primary1.avg_pay - 1) * 100, 2) perc_increment,
	round(avg(primary1.avg_GDP), 2) avg_GDP,
	round(avg(primary2.avg_GDP), 2) avg_GDP_plus_1yr,	-- 1 hodnota pro celý rok, takže jen kdyby to bylo v jiné DB, kteerá by hodila error kvůli chybající agregaci 
	round((primary2.avg_GDP/primary1.avg_GDP - 1) * 100, 2) gdp_perc_increment
FROM t_michal_titl_project_sql_primary_final primary1
	LEFT JOIN t_michal_titl_project_sql_primary_final primary2
	ON primary1.`year` = primary2.`year` - 1
	AND primary1.branch_code = primary2.branch_code
WHERE primary2.`year` IS NOT NULL
GROUP BY 
	primary1.`year` ,
	primary2.`year`
;

-- samotné srovnání růstů mezd a cen včetně
SELECT
	base_table_1.`year`,
	base_table_1.next_year,
	yearly_perc_increment prices_increment,
	perc_increment pay_increment,
	yearly_perc_increment - perc_increment basic_diff,
	CASE
		WHEN (yearly_perc_increment - perc_increment) > 10 THEN '!!!'
		ELSE '...'
	END basic_flag,
	round((yearly_perc_increment/perc_increment - 1) * 100, 2) relative_diff_of_perc,
	CASE
		WHEN ((yearly_perc_increment/perc_increment - 1) * 100) >= 10 THEN '!!!'
		WHEN ((yearly_perc_increment/perc_increment - 1) * 100) < 0 AND perc_increment < 0 THEN '!!!'
		ELSE '...'
	END relative_flag
FROM base_table_1
	LEFT JOIN base_table_2
	ON base_table_1.`year` = base_table_2.`year`
	AND base_table_1.next_year = base_table_2.year_plus_one
;


/*
5) Má výška HDP vliv na změny ve mzdách a cenách potravin? Neboli, pokud HDP vzroste výrazněji v jednom roce, 
projeví se to na cenách potravin či mzdách ve stejném nebo násdujícím roce výraznějším růstem?
Odpověď: I zde je dobré si předem vyjasnit, co znamená výraznější růst. Pro jednoduchý pohled jsem zvolil arbitrární hranici růstu o 50 % vyšší
		vůči průměru. Pokud lze považovat četnosti jevů za průkazy vlivu HDP na mzdy/ceny, tak spíše jej lze pozorovat z růstu z aktuálního roku a
		to možná více u cen. Tuto úvahu lze částečně podpořit korelací růstů HDP s růsty mezd či růsty cen, jakkoliv v případě korelace je vhodnější
		říci, že lze pozorovat přibližně střední vztah mezi aktuálními (růsty) HDP a cenami a HDP a mzdami. Pro předešlý růst je vztah minimální, či
		spíš žádný. Výsledky do jisté míry dávají smysl a možná by bylo překvapivé, když by výpočet vztah aktuálních hodnot nepodpořil, protože HDP
		tvoří několik složek mezi než patří např. důchody domácností nebo zisky společností aj. Vztah růst cen/cenové hladiny a dalších metrik
		ekonomiky je ve své celé šíři daleko za mými kompetencemi, pro detailnější pohled doporučuji Trhy (Stroukal a Berka, 2024).
*/

-- zjišťování průměrů
SELECT
	avg(gdp_perc_increment) avg_gdp_growth, -- průměrný růst HDP je 2,12 %
	avg(perc_increment) avg_pay_growth -- průměrný růst mezd je 4,24 %
FROM base_table_2; 

SELECT avg(yearly_perc_increment) -- průměrný růst cen je 2,67 %
FROM base_table_1;

-- kategorické srovnání
SELECT
	bt1.`year`,
	bt1.next_year,
	bt1.yearly_perc_increment prices_increment,
	bt2.perc_increment pay_increment,
	bt2.gdp_perc_increment,
	bt22.gdp_perc_increment gdp_previous_change,
	CASE 
		WHEN (bt2.gdp_perc_increment > 2.12*1.5 AND bt1.yearly_perc_increment > 2.67*1.5)
		OR (bt2.gdp_perc_increment < 2.12*1.5*(-1) AND bt1.yearly_perc_increment < 2.67*1.5*(-1))
		THEN '!' ELSE NULL END current_gdp_high_prices,
	CASE 
		WHEN bt22.gdp_perc_increment > 2.12*1.5 AND bt1.yearly_perc_increment > 2.67*1.5
		OR (bt22.gdp_perc_increment < 2.12*1.5*(-1) AND bt1.yearly_perc_increment < 2.67*1.5*(-1))
		THEN '!' ELSE NULL END previous_gdp_high_prices,
	CASE 
		WHEN bt2.gdp_perc_increment > 2.12*1.5 AND bt2.perc_increment > 4.24*1.5
		OR (bt2.gdp_perc_increment < 2.12*1.5*(-1) AND bt2.perc_increment < 2.67*1.5*(-1))
		THEN '!' ELSE NULL END current_gdp_high_pays,
	CASE 
		WHEN bt22.gdp_perc_increment > 2.12*1.5 AND bt2.perc_increment > 4.24*1.5 
		OR (bt22.gdp_perc_increment < 2.12*1.5*(-1) AND bt2.perc_increment < 2.67*1.5*(-1))
		THEN '!' ELSE NULL END previous_gdp_high_pays
FROM base_table_1 bt1
	LEFT JOIN base_table_2 bt2
		ON bt1.`year` = bt2.`year`
		AND bt1.next_year = bt2.year_plus_one
	LEFT JOIN base_table_2 bt22
		ON bt1.`year` = bt22.`year` + 1	-- tímhle dělám TO, že přidávám DATA z předchozího období (otázka se ptá na vliv gdp na stejný nebo následující rok)
ORDER BY bt1.`year`;

-- výpočet korelací
SELECT
	(COUNT(*) * SUM(bt1.yearly_perc_increment * bt2.gdp_perc_increment) - SUM(bt1.yearly_perc_increment) * SUM(bt2.gdp_perc_increment))/
	(SQRT(COUNT(*) * SUM(bt1.yearly_perc_increment * bt1.yearly_perc_increment) - SUM(bt1.yearly_perc_increment) * SUM(bt1.yearly_perc_increment))
	* SQRT(COUNT(*) * SUM(bt2.gdp_perc_increment * bt2.gdp_perc_increment) - SUM(bt2.gdp_perc_increment) * SUM(bt2.gdp_perc_increment)))
	AS current_gdp_prices_r,
	(COUNT(*) * SUM(bt1.yearly_perc_increment * bt22.gdp_perc_increment) - SUM(bt1.yearly_perc_increment) * SUM(bt22.gdp_perc_increment))/
	(SQRT(COUNT(*) * SUM(bt1.yearly_perc_increment * bt1.yearly_perc_increment) - SUM(bt1.yearly_perc_increment) * SUM(bt1.yearly_perc_increment))
	* SQRT(COUNT(*) * SUM(bt22.gdp_perc_increment * bt22.gdp_perc_increment) - SUM(bt22.gdp_perc_increment) * SUM(bt22.gdp_perc_increment)))
	AS previous_gdp_prices_r,
	(COUNT(*) * SUM(bt2.perc_increment * bt2.gdp_perc_increment) - SUM(bt2.perc_increment) * SUM(bt2.gdp_perc_increment))/
	(SQRT(COUNT(*) * SUM(bt2.perc_increment * bt2.perc_increment) - SUM(bt2.perc_increment) * SUM(bt2.perc_increment))
	* SQRT(COUNT(*) * SUM(bt2.gdp_perc_increment * bt2.gdp_perc_increment) - SUM(bt2.gdp_perc_increment) * SUM(bt2.gdp_perc_increment)))
	AS current_gdp_pays_r,
	(COUNT(*) * SUM(bt2.perc_increment * bt22.gdp_perc_increment) - SUM(bt2.perc_increment) * SUM(bt22.gdp_perc_increment))/
	(SQRT(COUNT(*) * SUM(bt2.perc_increment * bt2.perc_increment) - SUM(bt2.perc_increment) * SUM(bt2.perc_increment))
	* SQRT(COUNT(*) * SUM(bt22.gdp_perc_increment * bt22.gdp_perc_increment) - SUM(bt22.gdp_perc_increment) * SUM(bt22.gdp_perc_increment)))
	AS previous_gdp_pays_r
FROM base_table_1 bt1
	LEFT JOIN base_table_2 bt2
		ON bt1.`year` = bt2.`year`
		AND bt1.next_year = bt2.year_plus_one
	LEFT JOIN base_table_2 bt22
		ON bt1.`year` = bt22.`year` + 1
ORDER BY bt1.`year`;
