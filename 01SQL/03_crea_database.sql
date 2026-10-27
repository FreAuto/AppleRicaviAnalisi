-- =====================================================================
--  01_crea_database.sql – Come guadagna Apple 🍏
--  Crea le tabelle del database (SQLite) con i bilanci annuali 10-K.
--  Valori in MILIONI di dollari. Anno = anno fiscale (finisce a fine settembre).
--  Lo usa 02_carica_dati.py: non serve lanciarlo a mano.
-- =====================================================================

DROP TABLE IF EXISTS prodotti_servizi;
DROP TABLE IF EXISTS ricavi_zone;
DROP TABLE IF EXISTS ricavi_prodotti;
DROP TABLE IF EXISTS anni;
DROP TABLE IF EXISTS zone;
DROP TABLE IF EXISTS prodotti;
DROP TABLE IF EXISTS tipi;

-- 🧩 i 2 tipi di ricavo: Prodotti (cose che si toccano) e Servizi
CREATE TABLE tipi (
    tipo        TEXT PRIMARY KEY               -- 'Prodotti', 'Servizi'
);

-- 📱 i 5 gruppi di prodotti come li divide Apple nel bilancio
CREATE TABLE prodotti (
    id_prodotto     INTEGER PRIMARY KEY,
    prodotto        TEXT NOT NULL UNIQUE,      -- 'iPhone', 'Mac', 'iPad', 'Accessori', 'Servizi'
    tipo            TEXT NOT NULL REFERENCES tipi (tipo),
    cosa_comprende  TEXT
);

-- 🌍 le 5 zone del mondo (i "segmenti" del bilancio)
CREATE TABLE zone (
    id_zona         INTEGER PRIMARY KEY,
    zona            TEXT NOT NULL UNIQUE,
    cosa_comprende  TEXT
);

-- 📅 il conto economico, un anno per riga (2010-2025)
CREATE TABLE anni (
    anno                    INTEGER PRIMARY KEY,
    ricavi                  INTEGER NOT NULL,   -- tutto quello che Apple incassa vendendo
    costo_vendite           INTEGER NOT NULL,   -- quanto costa fare prodotti e servizi
    margine_lordo           INTEGER NOT NULL,   -- ricavi - costo delle vendite
    ricerca_sviluppo        INTEGER NOT NULL,   -- spese per inventare prodotti nuovi
    spese_vendita_generali  INTEGER NOT NULL,   -- negozi, pubblicità, uffici
    utile_operativo         INTEGER NOT NULL,   -- margine lordo - spese
    tasse                   INTEGER NOT NULL,
    utile_netto             INTEGER NOT NULL,   -- quello che resta alla fine
    CHECK (ricavi > 0)
);

-- 💰 ricavi per prodotto e anno (2013-2025)
CREATE TABLE ricavi_prodotti (
    anno         INTEGER NOT NULL REFERENCES anni (anno),
    id_prodotto  INTEGER NOT NULL REFERENCES prodotti (id_prodotto),
    ricavi       INTEGER NOT NULL,
    PRIMARY KEY (anno, id_prodotto)
);

-- 🌍 ricavi e utile operativo per zona e anno (2013-2025)
CREATE TABLE ricavi_zone (
    anno             INTEGER NOT NULL REFERENCES anni (anno),
    id_zona          INTEGER NOT NULL REFERENCES zone (id_zona),
    ricavi           INTEGER NOT NULL,
    utile_operativo  INTEGER NOT NULL,          -- senza ricerca e spese centrali
    PRIMARY KEY (anno, id_zona)
);

-- ⚖️ Prodotti e Servizi: ricavi, costi e margine (2017-2025)
CREATE TABLE prodotti_servizi (
    anno           INTEGER NOT NULL REFERENCES anni (anno),
    tipo           TEXT NOT NULL REFERENCES tipi (tipo),
    ricavi         INTEGER NOT NULL,
    costo_vendite  INTEGER NOT NULL,
    margine_lordo  INTEGER NOT NULL,
    PRIMARY KEY (anno, tipo)
);
