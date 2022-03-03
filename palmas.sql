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

-- Calculo de MaxD en Km para cada especie del género Bactris (MaxD entre todos los posibles pares de registros)

SELECT species AS especie, COUNT(DISTINCT arecaceae.id) AS registros_gbif,
MAX(ST_Distance(arecaceae.geom, buffer_arecaceae.geom)*111) AS maxdistancia
FROM arecaceae, buffer_arecaceae
WHERE genus = 'Bactris' AND arecaceae.species = buffer_arecaceae.especie
GROUP BY species ORDER BY maxdistancia;

-- Clasificación por estado de conservación de especies de palmas en Colombia
-- En peligro crítico
SELECT depto, COUNT(DISTINCT id) AS registros_gbif
FROM arecaceae WHERE species = 'Reinhardtia simplex'
GROUP BY depto ORDER BY registros_gbif;

ALTER TABLE arecaceae ADD COLUMN conservacion varchar(20);

UPDATE arecaceae SET conservacion = 'En Peligro Critico'
WHERE species = 'Aiphanes graminifolia' OR
species = 'Aiphanes leiostachys' OR
species = 'Ceroxylon sasaimae' OR
species = 'Reinhardtia gracilis' OR
species = 'Reinhardtia koschnyana' OR
species = 'Reinhardtia simplex';

-- En peligro
UPDATE arecaceae SET conservacion = 'En Peligro'
WHERE species = 'Aiphanes acaulis' OR
species = 'Aiphanes duquei' OR
species = 'Aiphanes parvifolia' OR
species = 'Astrocaryum malibo' OR 
species = 'Astrocaryum triandrum' OR
species = 'Attalea amygdalina' OR
species = 'Attalea cohune' OR
species = 'Attalea colenda' OR
species = 'Ceroxylon alpinum' OR
species = 'Ceroxylon quindiuense' OR
species = 'Ceroxylon ventricosum' OR
species = 'Coccothrinax argentata' OR
species = 'Chamaedorea ricardoi' OR
species = 'Elaeis oleifera' OR
species = 'Hyospathe wendlandiana' OR
species = 'Phytelephas tumacana' OR
species = 'Prestoea simplicifolia';

SELECT species, COUNT(DISTINCT id) AS registros_gbif, COUNT(DISTINCT depto) AS departamentos
FROM arecaceae WHERE conservacion = 'En Peligro'
GROUP BY species ORDER BY registros_gbif, departamentos;

-- VULNERABLE(vu)

UPDATE arecaceae SET conservacion = 'Vulnerable'
WHERE species = 'Acoelorraphe wrightii' OR
species = 'Aiphanes gelatinosa' OR
species = 'Aiphanes pilaris' OR
species = 'Attalea nucifera' OR
species = 'Bactris rostrata' OR
species = 'Cryosophila kalbreyeri' OR
species = 'Chamaedorea pygmaeae' OR
species = 'Chamaedorea sullivaniorum' OR
species = 'Geonoma chlamydostachys' OR
species = 'Geonoma santanderensis' OR
species = 'Hyospathe frontinoensis' OR
species = 'Oenocarpus circumtextus' OR
species = 'Syagrus sancona' OR
species = 'Wettinia hirsuta' OR 
species = 'Wettinia microcarpa';

/*Caluclo de distancia máxima entre todos los posibles pares de registros de
cada especie en peligro critico, en peligro o vulnerable*/
SELECT species AS especie, COUNT(DISTINCT arecaceae.id) AS registros_gbif, 
COUNT(DISTINCT depto) AS numdeptos,
MAX(ST_Distance(arecaceae.geom, buffer_arecaceae.geom)*111) AS maxdistancia
FROM arecaceae, buffer_arecaceae 
WHERE conservacion = 'Vulnerable' AND arecaceae.species = buffer_arecaceae.especie
--AND species <> 'Ceroxylon quindiuense'
GROUP BY species ORDER BY maxdistancia, registros_gbif, numdeptos;

SELECT species AS especie, COUNT(DISTINCT arecaceae.id) AS registros_gbif
FROM arecaceae
WHERE conservacion = 'En Peligro Critico'
GROUP BY species ORDER BY registros_gbif

-- Segmentacion geografica por departamento de especies en peligro critico, en peligro o vulnerables

SELECT depto as departamento, COUNT(DISTINCT species) AS num_especies_peligro_crit
FROM arecaceae WHERE conservacion = 'Vulnerable'
group by depto ORDER BY num_especies_peligro_crit DESC;

SELECT COUNT(DISTINCT genus)
FROM arecaceae;

-- Consolidado de nombre cientifico de especies por departamento

SELECT species AS especie, COUNT(DISTINCT id) AS registros_gbif, conservacion
FROM arecaceae WHERE depto = 'VICHADA'
GROUP BY species, conservacion ORDER BY registros_gbif DESC;

SELECT DISTINCT depto FROM arecaceae group by depto;





























