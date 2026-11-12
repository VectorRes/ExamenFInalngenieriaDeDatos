variable "region" {
  description = "Región de AWS donde se despliegan los recursos."
  type        = string
  default     = "us-east-1"
}

variable "nombre_bucket" {
  description = "Nombre global y único del bucket S3 del ejercicio."
  type        = string
  default     = "entregas-mensajeria-victor-2026"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.nombre_bucket))
    error_message = "El nombre del bucket debe tener entre 3 y 63 caracteres: minúsculas, números, puntos o guiones."
  }
}

variable "nombre_base_datos" {
  description = "Nombre de la base de datos en Glue Data Catalog."
  type        = string
  default     = "mensajeria_db"

  validation {
    condition     = can(regex("^[a-z0-9_]+$", var.nombre_base_datos))
    error_message = "Use solo minúsculas, números y guion bajo."
  }
}

variable "nombre_tabla" {
  description = "Nombre de la tabla externa de entregas."
  type        = string
  default     = "entregas"

  validation {
    condition     = can(regex("^[a-z0-9_]+$", var.nombre_tabla))
    error_message = "Use solo minúsculas, números y guion bajo."
  }
}

variable "nombre_workgroup" {
  description = "Nombre del workgroup de Athena."
  type        = string
  default     = "wg-mensajeria"
}

variable "fecha_inicio_proyeccion" {
  description = "Primera fecha proyectada (incluida), formato yyyy-MM-dd."
  type        = string
  default     = "2026-10-01"
}

variable "fecha_fin_proyeccion" {
  description = "Última fecha proyectada (incluida), formato yyyy-MM-dd."
  type        = string
  default     = "2026-10-03"
}
