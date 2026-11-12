# Respuestas conceptuales

## 1. ¿Por qué se pudo consultar el tercer día sin registrar una partición nueva?

Porque la tabla `mensajeria_db.entregas` usa **partition projection**. En lugar de guardar en Glue Data Catalog una lista de particiones con su ubicación, la tabla guarda unas reglas en sus propiedades (definidas en `infraestructura/principal.tf`):

| Propiedad | Valor |
| --- | --- |
| `projection.fecha.type` | `date` |
| `projection.fecha.format` | `yyyy-MM-dd` |
| `projection.fecha.range` | `2026-10-01,2026-10-03` |
| `projection.fecha.interval` / `interval.unit` | `1` / `DAYS` |
| `storage.location.template` | `s3://entregas-mensajeria-victor-2026/entregas/fecha=${fecha}/` |

Cuando se ejecuta una consulta, Athena **calcula** las fechas posibles a partir del rango y el intervalo (01, 02 y 03 de octubre) y, con la plantilla, obtiene el prefijo de S3 de cada una. Después lee los objetos que encuentre en esos prefijos.

El 3 de octubre estaba dentro del rango **desde el despliegue inicial**. En la primera etapa su prefijo no tenía objetos, por eso `SELECT COUNT(*)` devolvía **12**: la proyección no crea datos, solo indica dónde buscarlos. Al subir `entregas.csv` a `s3://.../entregas/fecha=2026-10-03/`, que es exactamente la ruta que genera la plantilla, Athena lo encontró en la siguiente consulta sin ningún paso adicional: no se ejecutaron crawlers, `MSCK REPAIR TABLE`, `ALTER TABLE ADD PARTITION`, ni se cambió Terraform o la tabla.

La evidencia está en `evidencias/ejecuciones_athena.csv`, etapa `final`:

- `fa4fc33c-d5b5-478d-b2e1-951e5e4f92fc` → `resultados/final/verificacion_tercer_dia.csv`: los seis registros del 2026-10-03 (ENV-013 a ENV-018).
- `c4239909-dcdf-45d4-9651-1f7ed506c31f` → `resultados/final/registros_por_fecha.csv`: seis registros por cada uno de los tres días.
- `217072cf-ddc9-467f-a4a5-c042fa19af90` → `resultados/final/total_registros.csv`: **18** registros en total.
- `5cc9e8fc-612e-424f-b4a9-939bcc1406a5` → `resultados/final/conteo_estado_tercer_dia.csv`: 2 `entregado`, 3 `destinatario_ausente` y 1 `direccion_incorrecta`.
- `b9383e58-ab8f-4432-9804-2a4f55d22b41` y `88918a41-6c0f-4d65-8a2e-2e2e0f942808`: las consultas agregadas ya incluyen el tercer día y coinciden con las referencias finales.

## 2. Si se subiera un archivo para el 4 de octubre manteniendo la configuración actual, ¿qué resultado se esperaría y qué se debería modificar para incluirlo?

**Resultado esperado:** el archivo quedaría en S3, pero **Athena no lo leería**. El rango proyectado termina en `2026-10-03`, así que Athena nunca genera la fecha `2026-10-04` ni calcula su prefijo. Las consultas no darían error, pero:

- `SELECT COUNT(*) FROM entregas` seguiría devolviendo **18**.
- `... WHERE fecha = '2026-10-04'` devolvería **cero filas**.
- Las consultas de intentos y porcentaje seguirían mostrando solo tres fechas.

Es decir, los datos se ignorarían en silencio, lo que puede llevar a pensar que no hubo intentos ese día.

**Qué modificar:** ampliar el rango de la proyección en Terraform, que es donde está definida la tabla. En este proyecto el final del rango es la variable `fecha_fin_proyeccion` de `infraestructura/variables.tf`:

```bash
terraform -chdir=infraestructura apply -var="fecha_fin_proyeccion=2026-10-04"
```

o cambiar su valor por defecto y aplicar. Esto solo actualiza la propiedad `projection.fecha.range` de la tabla; sigue sin ser necesario registrar particiones. Si se esperan archivos diarios de forma continua, se podría usar un rango relativo como `2026-10-01,NOW` para no modificarlo cada día. Además, el archivo nuevo debe respetar la ruta `entregas/fecha=2026-10-04/` y el mismo esquema de cinco columnas.
