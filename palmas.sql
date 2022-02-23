CREATE EXTENSION postgis;

-- Creación de campos de enlace espacial por departamentos, municipios y ecoregiones
ALTER TABLE arecaceae ADD COLUMN departamento varchar(40);
ALTER TABLE arecaceae ADD COLUMN depto varchar(80);
ALTER TABLE arecaceae ADD COLUMN municipio varchar(70);
ALTER TABLE arecaceae ADD COLUMN ecoregion varchar(80);

-- Aplicación de funciones de enlace espacial

UPDATE arecaceae SET depto = dpto_cnmbr
FROM departamentos
WHERE ST_Intersects(arecaceae.geom, departamentos.geom);

-- Primera consulta espacial de numero de especies de palmas por departamento
SELECT depto as departamento, COUNT(DISTINCT species) as especies
FROM arecaceae
GROUP BY depto ORDER BY especies DESC;