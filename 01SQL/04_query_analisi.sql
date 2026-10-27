-- =====================================================================
--  03_query_analisi.sql – Come guadagna Apple 🍏
--  Database: apple_ricavi.db (SQLite)
--  Valori in MILIONI di dollari: diviso 1000 = miliardi.
--  Anno = anno fiscale di Apple (finisce a fine settembre).
-- =====================================================================


-- =====================================================================
--  0️⃣ CONTROLLI SUI DATI
-- =====================================================================

-- Q0.1 📋 Quante righe ha ogni tabella e quali anni copre
SELECT 'anni' AS tabella, COUNT(*) AS righe, MIN(anno) AS dal, MAX(anno) AS al FROM anni
UNION ALL SELECT 'ricavi_prodotti', COUNT(*), MIN(anno), MAX(anno) FROM ricavi_prodotti
UNION ALL SELECT 'ricavi_zone', COUNT(*), MIN(anno), MAX(anno) FROM ricavi_zone
UNION ALL SELECT 'prodotti_servizi', COUNT(*), MIN(anno), MAX(anno) FROM prodotti_servizi;

-- Q0.2 🔍 La somma dei prodotti e la somma delle zone danno i ricavi totali?
SELECT a.anno,
       a.ricavi                               AS ricavi_totali,
       a.ricavi - p.somma_prodotti            AS differenza_prodotti,
       a.ricavi - z.somma_zone                AS differenza_zone
FROM anni a
JOIN (SELECT anno, SUM(ricavi) AS somma_prodotti FROM ricavi_prodotti GROUP BY anno) p ON p.anno = a.anno
JOIN (SELECT anno, SUM(ricavi) AS somma_zone FROM ricavi_zone GROUP BY anno) z ON z.anno = a.anno
ORDER BY a.anno;

-- Q0.3 🧮 I conti tornano? ricavi - costi = margine, margine - spese = utile operativo
SELECT anno,
       ricavi - costo_vendite - margine_lordo                                 AS errore_margine,
       margine_lordo - ricerca_sviluppo - spese_vendita_generali - utile_operativo AS errore_utile
FROM anni
WHERE ricavi - costo_vendite - margine_lordo <> 0
   OR margine_lordo - ricerca_sviluppo - spese_vendita_generali - utile_operativo <> 0;
-- nessuna riga = tutto torna ✅


-- =====================================================================
--  1️⃣ QUANTO È CRESCIUTA APPLE DAL 2010 A OGGI?
-- =====================================================================

-- Q1.1 📈 Ricavi e utile netto anno per anno, con la crescita rispetto all'anno prima
SELECT anno,
       ROUND(ricavi / 1000.0, 1)                                                   AS ricavi_mld,
       ROUND(utile_netto / 1000.0, 1)                                              AS utile_netto_mld,
       ROUND(100.0 * (ricavi - LAG(ricavi) OVER (ORDER BY anno)) / LAG(ricavi) OVER (ORDER BY anno), 1) AS crescita_ricavi_pct
FROM anni
ORDER BY anno;

-- Q1.2 📉 Gli anni in cui i ricavi sono scesi
WITH c AS (
    SELECT anno, ricavi, LAG(ricavi) OVER (ORDER BY anno) AS anno_prima FROM anni
)
SELECT anno, ROUND((ricavi - anno_prima) / 1000.0, 1) AS differenza_mld,
       ROUND(100.0 * (ricavi - anno_prima) / anno_prima, 1) AS differenza_pct
FROM c
WHERE ricavi < anno_prima
ORDER BY anno;

-- Q1.3 🚀 Quante volte sono cresciuti i ricavi dal 2010 al 2025 (e la crescita media all'anno)
SELECT ROUND(1.0 * f.ricavi / i.ricavi, 1)                                      AS volte,
       ROUND(100.0 * (POWER(1.0 * f.ricavi / i.ricavi, 1.0 / (f.anno - i.anno)) - 1), 1) AS crescita_media_annua_pct
FROM anni i, anni f
WHERE i.anno = 2010 AND f.anno = 2025;
-- POWER c'è in SQLite dalla versione 3.35 (DB Browser for SQLite recente ✅)


-- =====================================================================
--  2️⃣ APPLE DIPENDE ANCORA DALL'IPHONE?
-- =====================================================================

-- Q2.1 📱 La quota di ogni prodotto sui ricavi, nel 2013 e nel 2025
SELECT p.prodotto,
       ROUND(100.0 * SUM(CASE WHEN r.anno = 2013 THEN r.ricavi END)
             / (SELECT SUM(ricavi) FROM ricavi_prodotti WHERE anno = 2013), 1) AS quota_2013_pct,
       ROUND(100.0 * SUM(CASE WHEN r.anno = 2025 THEN r.ricavi END)
             / (SELECT SUM(ricavi) FROM ricavi_prodotti WHERE anno = 2025), 1) AS quota_2025_pct
FROM ricavi_prodotti r
JOIN prodotti p ON p.id_prodotto = r.id_prodotto
GROUP BY p.prodotto
ORDER BY quota_2025_pct DESC;

-- Q2.2 🏆 L'anno record di ogni prodotto
WITH c AS (
    SELECT p.prodotto, r.anno, r.ricavi,
           RANK() OVER (PARTITION BY p.prodotto ORDER BY r.ricavi DESC) AS posizione
    FROM ricavi_prodotti r JOIN prodotti p ON p.id_prodotto = r.id_prodotto
)
SELECT prodotto, anno AS anno_record, ROUND(ricavi / 1000.0, 1) AS ricavi_mld
FROM c
WHERE posizione = 1
ORDER BY ricavi DESC;

-- Q2.3 📊 La quota dell'iPhone anno per anno
SELECT r.anno,
       ROUND(r.ricavi / 1000.0, 1)                AS iphone_mld,
       ROUND(100.0 * r.ricavi / a.ricavi, 1)      AS quota_iphone_pct
FROM ricavi_prodotti r
JOIN prodotti p ON p.id_prodotto = r.id_prodotto
JOIN anni a ON a.anno = r.anno
WHERE p.prodotto = 'iPhone'
ORDER BY r.anno;


-- =====================================================================
--  3️⃣ I SERVIZI STANNO CRESCENDO?
-- =====================================================================

-- Q3.1 ☁️ Ricavi dei Servizi: quante volte sono cresciuti dal 2013
SELECT ROUND(MAX(CASE WHEN r.anno = 2013 THEN r.ricavi END) / 1000.0, 1) AS servizi_2013_mld,
       ROUND(MAX(CASE WHEN r.anno = 2025 THEN r.ricavi END) / 1000.0, 1) AS servizi_2025_mld,
       ROUND(1.0 * MAX(CASE WHEN r.anno = 2025 THEN r.ricavi END)
                 / MAX(CASE WHEN r.anno = 2013 THEN r.ricavi END), 1)     AS volte
FROM ricavi_prodotti r
JOIN prodotti p ON p.id_prodotto = r.id_prodotto
WHERE p.prodotto = 'Servizi';

-- Q3.2 💎 Su 100 $ di ricavi, quanti restano come margine lordo: Prodotti o Servizi?
SELECT anno, tipo,
       ROUND(ricavi / 1000.0, 1)                       AS ricavi_mld,
       ROUND(100.0 * margine_lordo / ricavi, 1)        AS margine_pct
FROM prodotti_servizi
ORDER BY anno, tipo;

-- Q3.3 ⚖️ Quota dei Servizi: sui ricavi e sul margine lordo
SELECT anno,
       ROUND(100.0 * SUM(CASE WHEN tipo = 'Servizi' THEN ricavi END) / SUM(ricavi), 1)               AS servizi_sui_ricavi_pct,
       ROUND(100.0 * SUM(CASE WHEN tipo = 'Servizi' THEN margine_lordo END) / SUM(margine_lordo), 1) AS servizi_sul_margine_pct
FROM prodotti_servizi
GROUP BY anno
ORDER BY anno;


-- =====================================================================
--  4️⃣ IN QUALI ZONE DEL MONDO VENDE?
-- =====================================================================

-- Q4.1 🌍 Ricavi e quota di ogni zona nel 2025
SELECT z.zona,
       ROUND(r.ricavi / 1000.0, 1)                                                     AS ricavi_mld,
       ROUND(100.0 * r.ricavi / SUM(r.ricavi) OVER (), 1)                              AS quota_pct,
       ROUND(100.0 * r.utile_operativo / r.ricavi, 1)                                  AS utile_su_100_dollari
FROM ricavi_zone r
JOIN zone z ON z.id_zona = r.id_zona
WHERE r.anno = 2025
ORDER BY r.ricavi DESC;

-- Q4.2 🇨🇳 La Grande Cina anno per anno: ricavi e quota
SELECT r.anno,
       ROUND(r.ricavi / 1000.0, 1)              AS ricavi_mld,
       ROUND(100.0 * r.ricavi / a.ricavi, 1)    AS quota_pct
FROM ricavi_zone r
JOIN zone z ON z.id_zona = r.id_zona
JOIN anni a ON a.anno = r.anno
WHERE z.zona = 'Grande Cina'
ORDER BY r.anno;

-- Q4.3 📈 Quale zona è cresciuta di più dal 2013 al 2025
SELECT z.zona,
       ROUND(SUM(CASE WHEN r.anno = 2013 THEN r.ricavi END) / 1000.0, 1) AS ricavi_2013_mld,
       ROUND(SUM(CASE WHEN r.anno = 2025 THEN r.ricavi END) / 1000.0, 1) AS ricavi_2025_mld,
       ROUND(100.0 * (SUM(CASE WHEN r.anno = 2025 THEN r.ricavi END) - SUM(CASE WHEN r.anno = 2013 THEN r.ricavi END))
             / SUM(CASE WHEN r.anno = 2013 THEN r.ricavi END), 0)        AS crescita_pct
FROM ricavi_zone r
JOIN zone z ON z.id_zona = r.id_zona
GROUP BY z.zona
ORDER BY crescita_pct DESC;


-- =====================================================================
--  5️⃣ SU 100 DOLLARI, QUANTO RESTA AD APPLE?
-- =====================================================================

-- Q5.1 💵 Dove vanno 100 $ di ricavi (2025)
SELECT ROUND(100.0 * costo_vendite / ricavi, 1)            AS costo_vendite,
       ROUND(100.0 * ricerca_sviluppo / ricavi, 1)         AS ricerca_sviluppo,
       ROUND(100.0 * spese_vendita_generali / ricavi, 1)   AS spese_vendita_generali,
       ROUND(100.0 * tasse / ricavi, 1)                    AS tasse,
       ROUND(100.0 * utile_netto / ricavi, 1)              AS utile_netto
FROM anni
WHERE anno = 2025;
-- la piccola differenza fino a 100 sono altri proventi e spese (interessi, ecc.)

-- Q5.2 🔬 La spesa in ricerca e sviluppo: quanto pesa sui ricavi
SELECT anno,
       ROUND(ricerca_sviluppo / 1000.0, 1)              AS ricerca_mld,
       ROUND(100.0 * ricerca_sviluppo / ricavi, 1)      AS su_100_dollari
FROM anni
ORDER BY anno;

-- Q5.3 🥇 I 3 anni con l'utile netto più alto su 100 $ di ricavi
SELECT anno,
       ROUND(utile_netto / 1000.0, 1)              AS utile_netto_mld,
       ROUND(100.0 * utile_netto / ricavi, 1)      AS utile_su_100_dollari
FROM anni
ORDER BY 1.0 * utile_netto / ricavi DESC
LIMIT 3;
