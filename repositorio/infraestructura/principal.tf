terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Proyecto = "entregas-partition-projection"
    }
  }
}

locals {
  prefijo_entregas     = "entregas/"
  prefijo_resultados   = "resultados-athena/"
  ubicacion_entregas   = "s3://${aws_s3_bucket.datos.bucket}/${local.prefijo_entregas}"
  ubicacion_resultados = "s3://${aws_s3_bucket.datos.bucket}/${local.prefijo_resultados}"
}

# ---------------------------------------------------------------------------
# 1. Bucket S3 privado (datos en entregas/ y resultados en resultados-athena/)
# ---------------------------------------------------------------------------
resource "aws_s3_bucket" "datos" {
  bucket = var.nombre_bucket
}

resource "aws_s3_bucket_public_access_block" "datos" {
  bucket = aws_s3_bucket.datos.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ---------------------------------------------------------------------------
# 2. Base de datos de Glue Data Catalog
# ---------------------------------------------------------------------------
resource "aws_glue_catalog_database" "mensajeria" {
  name        = var.nombre_base_datos
  description = "Base de datos del ejercicio de intentos de entrega."
}

# ---------------------------------------------------------------------------
# 3. Tabla externa CSV con partition projection por fecha
# ---------------------------------------------------------------------------
resource "aws_glue_catalog_table" "entregas" {
  name          = var.nombre_tabla
  database_name = aws_glue_catalog_database.mensajeria.name
  description   = "Intentos de entrega en CSV, particionados por fecha mediante partition projection."
  table_type    = "EXTERNAL_TABLE"

  parameters = {
    "EXTERNAL"               = "TRUE"
    "classification"         = "csv"
    "skip.header.line.count" = "1"

    # Partition projection: Athena calcula las particiones al consultar.
    "projection.enabled"             = "true"
    "projection.fecha.type"          = "date"
    "projection.fecha.format"        = "yyyy-MM-dd"
    "projection.fecha.range"         = "${var.fecha_inicio_proyeccion},${var.fecha_fin_proyeccion}"
    "projection.fecha.interval"      = "1"
    "projection.fecha.interval.unit" = "DAYS"

    # $${fecha} se escribe con doble $ para que Terraform no lo interpole;
    # en el catálogo queda como ${fecha}. El prefijo termina en "/".
    "storage.location.template" = "${local.ubicacion_entregas}fecha=$${fecha}/"
  }

  # Clave de partición: no es columna del CSV, sale de la carpeta fecha=yyyy-MM-dd.
  partition_keys {
    name    = "fecha"
    type    = "string"
    comment = "Fecha del archivo, formato yyyy-MM-dd"
  }

  storage_descriptor {
    location      = local.ubicacion_entregas
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      name                  = "csv-coma"
      serialization_library = "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe"

      parameters = {
        "field.delim"          = ","
        "serialization.format" = ","
      }
    }

    # Las cinco columnas del CSV, en el orden del archivo.
    columns {
      name = "id_envio"
      type = "string"
    }

    columns {
      name = "ciudad"
      type = "string"
    }

    columns {
      name = "transportadora"
      type = "string"
    }

    columns {
      name = "estado"
      type = "string"
    }

    columns {
      name = "duracion_minutos"
      type = "int"
    }
  }
}

# ---------------------------------------------------------------------------
# 4. Workgroup de Athena con resultados en resultados-athena/
# ---------------------------------------------------------------------------
resource "aws_athena_workgroup" "mensajeria" {
  name          = var.nombre_workgroup
  description   = "Workgroup del ejercicio de partition projection."
  force_destroy = true

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = false

    result_configuration {
      output_location = local.ubicacion_resultados

      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }
  }
}
