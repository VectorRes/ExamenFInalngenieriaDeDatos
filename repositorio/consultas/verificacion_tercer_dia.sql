    -- Verificación del tercer día (2026-10-03), incorporado solo subiendo el archivo a S3,
-- sin crawlers, sin MSCK REPAIR TABLE, sin ALTER TABLE ADD PARTITION y sin cambiar la tabla.
-- Athena ejecuta una sentencia por ejecución, así que cada consulta se lanza por separado.

-- Consulta 1: los seis registros del 2026-10-03
SELECT
    fecha,
    id_envio,
    ciudad,
    transportadora,
    estado,
    duracion_minutos
FROM mensajeria_db.entregas
WHERE fecha = '2026-10-03'
ORDER BY id_envio ASC;

-- Consulta 2: registros por fecha (esperado: 6 por cada uno de los tres días)
SELECT
    fecha,
    COUNT(*) AS total_registros
FROM mensajeria_db.entregas
GROUP BY fecha
ORDER BY fecha ASC;

-- Consulta 3: total de registros de la tabla (esperado: 18)
SELECT
    COUNT(*) AS total_registros
FROM mensajeria_db.entregas;

-- Consulta 4: conteo por estado del 2026-10-03
SELECT
    fecha,
    estado,
    COUNT(*) AS total_intentos
FROM mensajeria_db.entregas
WHERE fecha = '2026-10-03'
GROUP BY fecha, estado
ORDER BY estado ASC;
