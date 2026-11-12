-- Porcentaje de entregas exitosas por fecha y ciudad.
-- 100 * entregas exitosas / total de intentos (todos los estados en el denominador).
-- Se usa DOUBLE para evitar la división entera y DECIMAL(5,2) para mostrar dos decimales.
SELECT
    fecha,
    ciudad,
    CAST(
        ROUND(100.0E0 * COUNT_IF(estado = 'entregado') / COUNT(*), 2)
        AS DECIMAL(5, 2)
    ) AS porcentaje_exito
FROM mensajeria_db.entregas
GROUP BY fecha, ciudad
ORDER BY fecha ASC, ciudad ASC
