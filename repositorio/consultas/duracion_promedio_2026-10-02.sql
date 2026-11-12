-- Duración promedio de las entregas exitosas del 2 de octubre de 2026.
-- Solo estado 'entregado' (se excluyen los intentos fallidos con duración 0).
SELECT
    fecha,
    CAST(
        ROUND(AVG(CAST(duracion_minutos AS DOUBLE)), 2)
        AS DECIMAL(10, 2)
    ) AS duracion_promedio_minutos
FROM mensajeria_db.entregas
WHERE fecha = '2026-10-02'
  AND estado = 'entregado'
GROUP BY fecha
