<h1> SQL project doc </h1>
* vzhledem k povaze dat a účelu je text primárně psán v češtině

<h2> Transformační skript </h2>

Výsledkem transformace jsou 1 soubor: Transformation_script.sql, který vytváří 2 základní tabulky: t_Michal_Titl_project_SQL_primary_final a t_Michal_Titl_project_SQL_secondary_final. t_Michal_Titl_project_SQL_primary_final obsahuje informace o mzdách a cenách v ČR, t_Michal_Titl_project_SQL_secondary_final zase obecnější informace o ostatních zemích.

<h3> primary_final </h3>

Primary_final používá několik tabulek, které jsou níže rozebrány a komentovány, podobně jako v komentářích samotného skriptu. Tabulka czechia_payroll obsahuje hlavní informace o mzdách, které se zdají být unikátní. Měření bylo prováděno kvartálně, přičemž počty napříč obory (a zvolenými typy kalkulací apod. viz dále) jsou stejné (krom roku 2021, kde jsou měřeny pouze první 2 kvartály). Czechia_payroll_value_type mapuje informace k typu hodnot, přičemž jsou 2 typy: průměrný počet zaměstnaných osob a průměrná hrubá mzda. Vzhledem k chybějícím datům a absenci informací o reprezentativnosti není první typ využiván, jakkoliv by bylo vhodné těchto informací využití, pokud by to bylo možné, například k vážení ostatních hodnot. Tabulka czechia_payroll_unit úzce souvisí s tou předchozí, jelikož mají společný 1:1 vztah, tudíž jen kóduje jiným způsobem už známé. Zajímavá může být tabulka czechia_payroll_calculation, která označuje typ dále nespecifikované kalkulace, navíc přepočet se nezdá, že by sledoval jasnou souvislou linku, tudíž používám také jen jednu z nich (fyzickou). Co se ještě týká kalkulací, tak ty zřejmě též neobsahují chybějící hodnoty. Významnou tabulkou je pak czechia_payroll_industry_branch, která obsahuje 19 odvětví, přičemž v hlavní tabulce systematicky chybí u každého 20. řádku kód odvětví. Bez jasných informací o zastoupení oboru (pomocí dostupných informací o počtu zaměstnancýh osob) nelze potvrdit, že se jedná o vážený průměr a ani běžný průměr se neukazuje jako legitimní označení, tudíž tyto řádky jsou následy vyřazeny. Navíc "fallback" kategorie v datech je (S - Ostatní činnosti). Po zvolení vhodných napojení a ověření nepřítomnosti NULL values lze tímto přístupem vytvořit hrubou tabulku o mzdách v ČR, ke které je dále připojena informace o GDP pro daný rok.

Druhou části primární tabulky jsou pak informace o cenách potravin. Ta se skládá z tabulek czechia_price, czechia_price_category a czechia_region. V tabulce czechia_price nemá tolik hodnot jako ostatní kategorie potravin kapr (skrze sezónnost a je tak vyřazen) a částečně i víno. Dále je znát menší frekvence měření v průběhu roku (pro analytickou práci je použit běžný průměr) a užší výsek celkového dataset cen oproti mzdám. Tabulka, podobně jako zbývající 2, neobsahuje duplikáty. Každá potravina může mít jiné jednotky měření než jiná, ale v rámci kategorie se nemění jak jednotka tak ani její množství. Měření jsou vždy stejné dlouhá (6 dní), je jich stejné množství pro každou kategorii (krom vína a vyřazeného kapra) a další informace o vzniku daného záznamu (sběr dat, jejich zpracování apod.) dostupné nejsou, tudíž pro nadcházející spojení s tabulkou mezd je použit průměr cen dle roku, přičemž rok daného měření je určen pomocí počátečního data. Při spojení s tabulkou region_code lze namapovat jednotlivé kraje, přičemž chybějící kód regionů odpovídá průměrné hodnotě za regiony. S ohledem na VO jsou použity pouze tyto hodnoty bez regionů. Na základě těchto informací byla vytvoření částečně tabulka pro ceny.

Před vytvořením samotné první finální tabulky jsou ještě data agregována, jak je popsáno výše, a následně spojena s tím, že data pro ceny jsou užší (2006-2018, oproti mzdám 2000-2021), tudíž v transformaci jsou ceny primární tabulkou, na kterou jsou připojeny mzdy pomocí roků.

<h3> secondary_final </h3>

Druhá finální tabulka obsahuje dodatečné údaje o ostatních zemích a vychází z jedné tabulky economies. Vzhledem k tomu, že pojem evropské státy lze vykládat vícero způsoby a případný uživatel může mít zájem i o agregovaná data, skládá se druhá finální tabulka ze zemí Evropy, jak je to popsáno na Wikipedii/popisuje ChatGPT ke dni publikace, z kategorií Centrální Evropa a Baltské státe, Eurozóna a Evropská unie a agregací pro vytvořenou kategorii států. Pro Lichtenštejnsko chybí HDP, které je v agregaci sumarizováno, a další hodnoty pro GINI koeficient, daně nebo úmrtnost pod 5 let života. Ostatní metriky jsou primárně průměrovány, takže jen: relativně často chybí GINI koeficient a daně, porodnost nebo úmrtnost pro malé či rozvíjející se státy.

<h2> Analytický skript </h2>

Analytický skript si dává za cíl odpovědět na VO a ideálně poskytnou vhled navíc pro jasnější podložení odpovědi.

<h3> 1) Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají? </h3>

Ne, mezi lety 2008 a 2015 lze najít období a obory (24 případů), kdy mzdy meziročně klesaly a to v rozmezí -9 % až - 0,1 %, průměrně -1,83 % (pro zasažená odvětví). K výpočetu bylo použito srovnání tabulky se sebe samou, posunout o rok, a vybráním sloupců zaměřených pouze na unikátní hodnoty, jakkoliv vzhledem k použití průměrování a struktury tabulky by nepoužití DISTINCT vedlo především k většímu počtu záznamů ve výsledné tabulce, ale agregace by byly ekvivalentní.

<h3> 2) Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd? </h3>

Za celkovou průměrnou mzdu bylo možné v roce 2006 koupit 1261,93 kg chleba a 1408,75 l mléka, v roce 2018 to bylo 1319,32 kg chleba a 1613,53 l mléka. Celkové rozpětí kg/l za průměrnou mzdu v daném odvětví za sledované období bylo 688,94 kg až 2288,56 kg u chleba a 769,1 l až 2798,93 l mléka. Vzhledem k předdefinování sledovaných potravin a let nebylo nutné řešit unikátnost záznamů a k zodpovězení byly tak použity běžné agregace a spojení výsledků agregace všech odvětví s jednotlivými.

<h3> 3) Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)? </h3>

Záleží na přesném znění otázky. Pokud lze brát jako nejnižší nárůst i nárůst negativní, tak jsou to rajská jablka s negativním nárůstem -30,28 % mezi 2006 a 2007, u kterých mj. cena meziročně klesala několikrát. Pokud řešíme pouze pozitivní nárůsty, tak je to rostlinný tuk s téměř neznatelným růstem 0,01 % mezi lety 2008 a 2009. Zároveň se lze také dívat na agregace růstů/poklesů. V případě zahrnutí i negativních inkrementů, tak průměrně klesala cena nejvíce u krystalového cukru (- 1,92 %) a rajských jablek (- 0,74%), v případě pozitivních inkrementů jsou to pak banány (0,81 %). Při pohledu na sumu inkrementů (pozitivních i negativních) je pohled podobný, přičemž u cukru se jedná o - 23,03 %, u jablek o - 8,88 % a nejnižší pozitivní sumu inkrementů má jakostní víno (8,1 %), následované banány (9,69 %). Celkově lze tedy říci, že malé inkrementy sledujeme u jablek, cukru a banánů, ať už pohledem průměrů, sum nebo změny cen let z roku 2006 na rok 2018.

U této otázky je možné úvahy rozvíjet dále, například jak naznačuje výpočet směrodatné odchylky, lze rozebírat jak ceny jednotlivých kategorií fluktuují, což by mohlo odhalit kategorie, které sice v povrchním pohledu nezdražují, ale za to jejich cenové změny lze těžko předpokládat. Nehledě na to, výpočet byl proveden podobně jako u první otázky, tedy napojením tabulky na sebe samotnou a srovnáním agregací a výpočtů změn cen.

<h3> 4) Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %) </h3>

Záleží na operacionalizaci obecné cenové hladiny v datasetu, průměrné mzdy a samotného rozdílu. V případě, že bychom předpokládali, že lidé nakupují vždy 1 jednotku zboží z dat potravin a že průměrná mzda je bežným průměrem z dostupných dat o mzdách, tak:
	- v případě jednoduchého rozdílů procentuálních meziročních přírůstků ne, spíše naopak
	- v případě procentuálního srovnání samotných přírůstků mezi sebou lze říci, že v letech vůči předchozímu roku v letech 2011 až 2013 a 2017
	byl procentuální přírůstek cen potravin o více než 10 % vyšší (z výše přírůstku mezd)

Zde bylo použito dočasných tabulek pro snazší zpracování finálních dotazů. Pro srovnání růstů byly použity 2 přístupy: absolutní a relativní (viz odpověd výše).

<h3> 5) Má výška HDP vliv na změny ve mzdách a cenách potravin? Neboli, pokud HDP vzroste výrazněji v jednom roce, projeví se to na cenách potravin či mzdách ve stejném nebo násdujícím roce výraznějším růstem? </h3>

I zde je dobré si předem vyjasnit, co znamená výraznější růst. Pro jednoduchý pohled jsem zvolil arbitrární hranici růstu o 50 % vyšší vůči průměru. Pokud lze považovat četnosti jevů za průkazy vlivu HDP na mzdy/ceny, tak spíše jej lze pozorovat z růstu z aktuálního roku a to možná více u cen. Tuto úvahu lze částečně podpořit korelací růstů HDP s růsty mezd či růsty cen, jakkoliv v případě korelace je vhodnější říci, že lze pozorovat přibližně střední vztah mezi aktuálními (růsty) HDP a cenami a HDP a mzdami. Pro předešlý růst je vztah minimální, či spíš žádný. Výsledky do jisté míry dávají smysl a možná by bylo překvapivé, když by výpočet vztah aktuálních hodnot nepodpořil, protože HDP tvoří několik složek mezi než patří např. důchody domácností nebo zisky společností aj. Vztah růst cen/cenové hladiny a dalších metrik ekonomiky je ve své celé šíři daleko za mými kompetencemi, pro detailnější pohled doporučuji Trhy (Stroukal a Berka, 2024).

Podobně jako v předchozí VO bylo použito 2 přístupů, přičemž v prvním se volila arbitrání hladina významného rozdílu, v druhém bylo použito korelací, jejíchž předpoklady pro účel použití nebyly tolik zvažovány, resp. jeden z nich (linearita) byl do jisté míry v podstatě dané VO.
