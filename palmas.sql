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

-- Consultas espaciales básicas
-- Consulta de número de especies de palmas por departamento

CREATE TABLE bio_depto(depto varchar(60), numespecies integer);
INSERT INTO bio_depto(depto, numespecies)
SELECT depto as departamento, COUNT(DISTINCT species) as numespecies
FROM arecaceae
GROUP BY depto ORDER BY numespecies DESC;

-- Consulta de riqueza de especies registradas en municipios de Antioquia

CREATE TABLE bio_muni(municipio varchar(80), riqespecies integer);
INSERT INTO bio_muni(municipio, riqespecies)
SELECT municipio, COUNT(DISTINCT species) as riqespecies
FROM arecaceae
-- WHERE depto = 'ANTIOQUIA'
GROUP BY municipio, depto ORDER BY riqespecies DESC;

-- Consulta de riqueza de especies por ecoregión WWF
CREATE TABLE bio_ecoregion(ecoregion varchar(90), riqespecies integer);
INSERT INTO bio_ecoregion(ecoregion, riqespecies)
SELECT ecoregion, COUNT(DISTINCT species) as riqespecies
FROM arecaceae
GROUP BY ecoregion ORDER BY riqespecies DESC;

-- Consulta de riqueza de especies de palmas por parque nacional
CREATE TABLE bio_parquenac(parquenac varchar(80), riqespecies integer);
INSERT INTO bio_parquenac(parquenac, riqespecies)
SELECT parquenac, COUNT(DISTINCT species) as riqespecies
FROM arecaceae
GROUP BY parquenac ORDER BY riqespecies DESC;

-- Generación de campo de riqueza de especies de palmas para cada cobertura incluida
--Riqueza de especies de palmas para capa de departamentos
ALTER TABLE departamentos ADD COLUMN riquezaesp_palmas integer;
UPDATE departamentos SET riquezaesp_palmas = numespecies
FROM bio_depto WHERE dpto_cnmbr = bio_depto.depto;

--Riqueza de especies de palmas para capa de municipios
ALTER TABLE municipios ADD COLUMN riquezaesp_palmas integer;
UPDATE municipios SET riquezaesp_palmas = riqespecies
FROM bio_muni WHERE mpio_cnmbr = bio_muni.municipio;

--Riqueza de especies de palmas para capa de ecoregiones
ALTER TABLE ecoregiones ADD COLUMN riquezaesp_palmas integer;
UPDATE ecoregiones SET riquezaesp_palmas = riqespecies
FROM bio_ecoregion WHERE eco_name = bio_ecoregion.ecoregion;

--Riqueza de especies de palmas para capa de parques nacionales
ALTER TABLE parquenacional ADD COLUMN riquezaesp_palmas integer;
UPDATE parquenacional SET riquezaesp_palmas = riqespecies
FROM bio_parquenac WHERE nombre = bio_parquenac.parquenac;

-- Consulta de riqueza de especies para cada género botánico de palmas en Colombia

SELECT genus as genero, COUNT(DISTINCT species) as especies
FROM arecaceae GROUP BY genero ORDER BY especies DESC;

-- Consulta de especies para el departamento de Antioquia

SELECT species as especie, COUNT(DISTINCT id) as registros_gbif
FROM arecaceae WHERE depto = 'CAQUETÁ' GROUP BY especie 
ORDER BY registros_gbif DESC;

-- Consulta de riqueza y taxonomia de especies de palmas para el país y el departamento de Amazonas
SELECT municipio, depto as departamento, COUNT(DISTINCT species) as num_especies
FROM arecaceae GROUP BY municipio, departamento ORDER BY num_especies DESC;

-- Consulta de taxonomia de especies de palmas para el departamento de Amazonas

SELECT species as especie, COUNT(DISTINCT id) as registros_gbif
FROM arecaceae WHERE depto = 'AMAZONAS' 
GROUP BY especie ORDER BY registros_gbif DESC;

-- Consulta de taxonomia de especies de palmas para la ecoregion bosque montañoso
-- del valle del río magdalena y bosque húmedo del Chocó-Darien
SELECT species as especie, COUNT(DISTINCT id) as registros_gbif
FROM arecaceae WHERE ecoregion = 'Chocó-Darién moist forests'
GROUP BY especie ORDER BY registros_gbif DESC;

/*Consulta de taxonomia de especies de palmas para los Parques Nacionales
Chiribiquete, Yaigoje Apaporis y Amacayacu*/

SELECT species as especie, COUNT(DISTINCT id) as registros_gbif
FROM arecaceae WHERE parquenac = 'AMACAYACU'
GROUP BY especie ORDER BY registros_gbif DESC;

-- Construcción de buffer de posición con radio de 1 Km
CREATE TABLE buffer_arecaceae(id serial primary key, especie varchar(50), 
							  geom geometry(Polygon, 4326));
							  
INSERT INTO buffer_arecaceae(geom, especie) 
SELECT ST_Buffer(geom, 0.009), species
FROM arecaceae;






















