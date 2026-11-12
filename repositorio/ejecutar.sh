#!/usr/bin/env bash
# Ejecuta una consulta de Athena, descarga su resultado y la registra en
# evidencias/ejecuciones_athena.csv.
#
# Uso (desde la raíz del repositorio):
#   bash ./ejecutar.sh ETAPA ARCHIVO_SQL ARCHIVO_RESULTADO [N]
#
# N es opcional: si el archivo SQL tiene varias sentencias separadas por ";",
# se ejecuta solo la sentencia número N (1, 2, 3...).
set -euo pipefail

if [[ $# -lt 3 || $# -gt 4 ]]; then
  echo "Uso: bash ./ejecutar.sh ETAPA ARCHIVO_SQL ARCHIVO_RESULTADO [N]" >&2
  exit 1
fi

ETAPA="$1"
SQL="$2"
RESULTADO="$3"
NUMERO="${4:-}"
WORKGROUP="wg-mensajeria"
DATABASE="mensajeria_db"
REGISTRO="evidencias/ejecuciones_athena.csv"

[[ -f "$SQL" ]] || { echo "No existe $SQL (¿estás en la raíz del repositorio?)" >&2; exit 1; }

# Texto de la consulta: el archivo completo o solo la sentencia N.
if [[ -n "$NUMERO" ]]; then
  CONSULTA=$(awk -v n="$NUMERO" 'BEGIN { RS = ";" } NR == n { print }' "$SQL")
  if ! grep -qi "select" <<< "$CONSULTA"; then
    echo "No se encontró la sentencia número $NUMERO en $SQL" >&2
    exit 1
  fi
else
  CONSULTA=$(cat "$SQL")
fi

BUCKET=$(terraform -chdir=infraestructura output -raw bucket_nombre)

ID=$(aws athena start-query-execution \
  --work-group "$WORKGROUP" \
  --query-execution-context Database="$DATABASE" \
  --query-string "$CONSULTA" \
  --query QueryExecutionId --output text)

while true; do
  ESTADO=$(aws athena get-query-execution --query-execution-id "$ID" \
    --query 'QueryExecution.Status.State' --output text)
  case "$ESTADO" in
    SUCCEEDED|FAILED|CANCELLED) break ;;
  esac
  sleep 2
done

echo ">> $SQL ${NUMERO:+(sentencia $NUMERO) }-> $ESTADO (id: $ID)"

if [[ "$ESTADO" != "SUCCEEDED" ]]; then
  aws athena get-query-execution --query-execution-id "$ID" \
    --query 'QueryExecution.Status.StateChangeReason' --output text
  exit 1
fi

mkdir -p "$(dirname "$RESULTADO")" evidencias
aws s3 cp "s3://$BUCKET/resultados-athena/$ID.csv" "$RESULTADO" --quiet

if [[ ! -s "$REGISTRO" ]]; then
  echo "etapa,archivo_sql,id_ejecucion,archivo_resultado" > "$REGISTRO"
fi
echo "$ETAPA,$SQL,$ID,$RESULTADO" >> "$REGISTRO"

cat "$RESULTADO"
