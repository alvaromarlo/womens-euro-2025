import io
import json
import gzip
import logging
import os

import functions_framework
import requests
from google.cloud import storage

logging.basicConfig(level=logging.INFO, format="%(levelname)s - %(message)s")
logger = logging.getLogger(__name__)

# --- CONFIGURACIÓN (sobreescribible via variables de entorno) ---
COMPETITION_ID = int(os.environ.get("COMPETITION_ID", 53))
SEASON_ID = int(os.environ.get("SEASON_ID", 315))
BASE_URL = "https://raw.githubusercontent.com/statsbomb/open-data/master/data"
REQUEST_TIMEOUT = 30


def get_matches() -> list:
    """Obtiene la lista de partidos de la competición y temporada configuradas."""
    url = f"{BASE_URL}/matches/{COMPETITION_ID}/{SEASON_ID}.json"
    response = requests.get(url, timeout=REQUEST_TIMEOUT)
    response.raise_for_status()
    return response.json()


def fetch_data(endpoint: str, match_id: int) -> list | None:
    """Descarga los datos de un endpoint (events, lineups, three-sixty) para un partido."""
    url = f"{BASE_URL}/{endpoint}/{match_id}.json"
    response = requests.get(url, timeout=REQUEST_TIMEOUT)
    if response.status_code == 200:
        return response.json()
    return None


def upload_to_gcs_idempotent(bucket: storage.Bucket, data: list | dict, destination_blob_name: str) -> None:
    """
    Comprime el JSON en memoria a .gz y lo sube a GCS usando streaming.
    Aplica lógica idempotente: omite la subida si el archivo ya existe.
    """
    blob = bucket.blob(destination_blob_name)

    if blob.exists():
        logger.info("⏩ Omitiendo: %s ya existe.", destination_blob_name)
        return

    compressed_buffer = io.BytesIO()
    with gzip.GzipFile(fileobj=compressed_buffer, mode="w") as gz_file:
        gz_file.write(json.dumps(data).encode("utf-8"))

    compressed_buffer.seek(0)
    blob.upload_from_file(compressed_buffer, content_type="application/gzip")
    logger.info("✅ Subido: %s", destination_blob_name)


@functions_framework.http
def ingest_statsbomb_data(request):
    """Punto de entrada HTTP para la Cloud Function de ingesta StatsBomb."""
    bucket_name = os.environ.get("GCP_BUCKET_NAME")
    if not bucket_name:
        return {"error": "La variable de entorno GCP_BUCKET_NAME no está definida."}, 500

    logger.info(
        "Iniciando extracción — Competición: %d, Temporada: %d",
        COMPETITION_ID,
        SEASON_ID,
    )

    storage_client = storage.Client()
    bucket = storage_client.bucket(bucket_name)

    try:
        matches = get_matches()
        logger.info("Se encontraron %d partidos.", len(matches))

        # 1. Guardar el maestro de partidos con particionado Hive
        matches_path = (
            f"bronze/statsbomb/matches"
            f"/competition_id={COMPETITION_ID}"
            f"/season_id={SEASON_ID}"
            f"/matches.json.gz"
        )
        upload_to_gcs_idempotent(bucket, matches, matches_path)

        for match in matches:
            match_id = match.get("match_id")
            logger.info("Procesando partido ID: %s...", match_id)

            # 2. Eventos
            events_data = fetch_data("events", match_id)
            if events_data:
                events_path = f"bronze/statsbomb/events/match_id={match_id}/events.json.gz"
                upload_to_gcs_idempotent(bucket, events_data, events_path)

            # 3. Datos espaciales (360)
            three_sixty_data = fetch_data("three-sixty", match_id)
            if three_sixty_data:
                path_360 = f"bronze/statsbomb/360/match_id={match_id}/360.json.gz"
                upload_to_gcs_idempotent(bucket, three_sixty_data, path_360)

            # 4. Alineaciones
            lineups_data = fetch_data("lineups", match_id)
            if lineups_data:
                lineups_path = f"bronze/statsbomb/lineups/match_id={match_id}/lineups.json.gz"
                upload_to_gcs_idempotent(bucket, lineups_data, lineups_path)

    except Exception as e:
        logger.exception("❌ Error durante la ingesta: %s", e)
        return {"error": str(e)}, 500

    return {"status": "ok", "message": "Ingesta de datos completada con éxito"}, 200