CREATE EXTENSION postgis;

-- Creación de campos de enlace espacial por departamentos, municipios y ecoregiones

ALTER TABLE arecaceae ADD COLUMN depto varchar(80);
ALTER TABLE arecaceae ADD COLUMN municipio varchar(70);
ALTER TABLE arecaceae ADD COLUMN ecoregion varchar(80);
ALTER TABLE arecaceae ADD COLUMN parquenac varchar(80);

-- Aplicación de funciones de enlace espacial

-- Segmentación de registros y especies de palmas por departamento
UPDATE arecaceae SET depto = dpto_cnmbr
FROM departamentos
WHERE ST_Intersects(arecaceae.geom, departamentos.geom);

-- Segmentación de registros y especies por municipio
UPDATE arecaceae SET municipio = mpio_cnmbr
FROM municipios
WHERE ST_Intersects(arecaceae.geom, municipios.geom);

--Segmentación de registros y especies por ecorregión de WWF
UPDATE arecaceae SET ecoregion = eco_name
FROM ecoregiones
WHERE ST_Intersects(arecaceae.geom, ecoregiones.geom);

-- Segmentación geografica por area protegida (presencia o ausencia)
UPDATE arecaceae SET parquenac = nombre
FROM parquenacional
WHERE ST_Intersects(arecaceae.geom, parquenacional.geom);
