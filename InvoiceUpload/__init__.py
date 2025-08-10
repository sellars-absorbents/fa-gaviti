import logging
import os
import dotenv
from pathlib import Path
import numpy as np
import cv2
import requests
from azure.identity import DefaultAzureCredential
from azure.storage.blob import BlobServiceClient

dotenv.load_dotenv()

from PyPDF2 import PdfReader, PdfWriter
from pdf2image import convert_from_path
import azure.functions as func
import time

STORAGE_ACCOUNT_URL = os.getenv("STORAGE_ACCOUNT_URL", "https://samstgprod001.blob.core.windows.net/")
credential = DefaultAzureCredential()
blob_service = BlobServiceClient(account_url=STORAGE_ACCOUNT_URL, credential=credential)


OUTPUT_CONTAINER = os.getenv("OUTPUT_CONTAINER", "processed-invoices")

# --- Cloudmersive config ---
CLOUDMERSIVE_API_KEY = os.getenv("CLOUDMERSIVE_API_KEY")
# Default to the standard scan endpoint; you can switch to the advanced QR endpoint if you mainly scan QRs:
CLOUDMERSIVE_ENDPOINT = os.getenv(
    "CLOUDMERSIVE_ENDPOINT",
    "https://api.cloudmersive.com/barcode/scan/image"
)
REQUEST_TIMEOUT_SECS = int(os.getenv("CLOUDMERSIVE_TIMEOUT", "15"))
MAX_RETRIES = int(os.getenv("CLOUDMERSIVE_RETRIES", "4"))
BACKOFF_BASE_MS = int(os.getenv("CLOUDMERSIVE_BACKOFF_MS", "600"))  # exponential backoff base

def call_cloudmersive(image_bytes: bytes, filename: str = "page.jpg") -> dict | None:
    """
    Sends an image to Cloudmersive and returns the parsed JSON (or None on failure).
    Retries on 429/5xx with exponential backoff.
    """
    if not CLOUDMERSIVE_API_KEY:
        raise RuntimeError("CLOUDMERSIVE_API_KEY is not set")

    files = {"imageFile": (filename, image_bytes, "image/jpeg")}
    headers = {"Apikey": CLOUDMERSIVE_API_KEY, "Accept": "application/json"}

    for attempt in range(MAX_RETRIES + 1):
        try:
            resp = requests.post(
                CLOUDMERSIVE_ENDPOINT,
                files=files,
                headers=headers,
                timeout=REQUEST_TIMEOUT_SECS,
            )
            # Retry on rate limit or server errors
            if resp.status_code in (429,) or resp.status_code >= 500:
                raise requests.HTTPError(f"Retryable status {resp.status_code}")
            resp.raise_for_status()
            return resp.json()
        except Exception as e:
            if attempt >= MAX_RETRIES:
                logging.error(f"Cloudmersive request failed after retries: {e}")
                return None
            # exponential backoff with jitter
            delay = (BACKOFF_BASE_MS / 1000.0) * (2 ** attempt) + (0.1 * attempt)
            logging.warning(f"Cloudmersive call failed (attempt {attempt+1}/{MAX_RETRIES+1}): {e}. "
                            f"Backing off {delay:.2f}s")
            time.sleep(delay)

    return None

def extract_first_barcode_value(api_json: dict | None) -> str | None:
    """
    Normalizes Cloudmersive responses.
    - Some responses include 'Successful', 'BarcodeType', 'RawText'
    - Others may include arrays (e.g., 'Barcodes', 'ParsedBarcodes')
    Returns the first decoded text value if available.
    """
    if not api_json:
        return None

    # Common single result shape
    raw = api_json.get("RawText")
    if raw:
        return str(raw)

    # Try common list shapes
    for key in ("Barcodes", "ParsedBarcodes", "Results"):
        items = api_json.get(key)
        if isinstance(items, list) and items:
            # Look for RawText/Text/value-like keys
            first = items[0]
            for k in ("RawText", "Text", "Value", "value", "data"):
                if isinstance(first, dict) and k in first and first[k]:
                    return str(first[k])

    return None

def extract_barcode_text(image) -> str | None:
    """
    Replaces local pyzbar decoding with Cloudmersive.
    Accepts a NumPy BGR image (cv2 style), encodes to JPEG, calls the API, and returns a string or None.
    """
    # Ensure BGR uint8 image -> encode JPEG
    ok, enc = cv2.imencode(".jpg", image)
    if not ok:
        return None
    api_json = call_cloudmersive(enc.tobytes(), filename="page.jpg")
    return extract_first_barcode_value(api_json)

def split_pdf_by_barcode(pdf_path: Path, output_dir: Path) -> list[Path]:
    output_dir.mkdir(parents=True, exist_ok=True)
    images = convert_from_path(str(pdf_path), dpi=300, poppler_path=POPPLER_PATH)
    reader = PdfReader(str(pdf_path))

    invoice_writer = None
    invoice_number = None
    output_files = []

    for i, image in enumerate(images):
        img_cv = cv2.cvtColor(np.array(image), cv2.COLOR_RGB2BGR)
        detected_number = extract_barcode_text(img_cv)

        if detected_number:
            # If we were collecting a previous invoice, flush it
            if invoice_writer and invoice_number:
                output_path = output_dir / f"{invoice_number}.pdf"
                with open(output_path, "wb") as f_out:
                    invoice_writer.write(f_out)
                output_files.append(output_path)

            invoice_number = detected_number.strip()
            invoice_writer = PdfWriter()

        # Keep adding pages to the current invoice writer (if any)
        if invoice_writer:
            invoice_writer.add_page(reader.pages[i])

    # Flush the final invoice
    if invoice_writer and invoice_number:
        output_path = output_dir / f"{invoice_number}.pdf"
        with open(output_path, "wb") as f_out:
            invoice_writer.write(f_out)
        output_files.append(output_path)

    return output_files

def upload_to_blob(file_paths: list[Path]):
    container_client = blob_service.get_container_client(OUTPUT_CONTAINER)
    # Create container if it doesn't exist
    try:
        container_client.create_container()
    except Exception:
        pass

    for file_path in file_paths:
        blob_name = file_path.name
        with open(file_path, "rb") as data:
            container_client.upload_blob(name=blob_name, data=data, overwrite=True)
            logging.info(f"Uploaded {blob_name} to {OUTPUT_CONTAINER}")

def main(myblob: func.InputStream):
    logging.info(f"Triggered by blob: {myblob.name}")

    tmp_input = Path("/tmp/input.pdf")
    tmp_output = Path("/tmp/invoices")
    tmp_input.parent.mkdir(parents=True, exist_ok=True)

    with open(tmp_input, "wb") as f:
        f.write(myblob.read())

    try:
        split_files = split_pdf_by_barcode(tmp_input, tmp_output)
        if not split_files:
            logging.warning("No barcodes detected; nothing to upload.")
        else:
            upload_to_blob(split_files)
            logging.info("Processing and upload completed successfully.")
    except Exception as e:
        logging.error(f"Failed to process PDF: {e}")
        raise
