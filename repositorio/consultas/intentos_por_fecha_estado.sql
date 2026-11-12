-- Cantidad de intentos por fecha y estado.
-- Sin filtro de fechas: el rango de partition projection limita las fechas consultables.
SELECT
    fecha,
    estado,
    COUNT(*) AS total_intentos
FROM mensajeria_db.entregas
GROUP BY fecha, estado
ORDER BY fecha ASC, estado ASC
