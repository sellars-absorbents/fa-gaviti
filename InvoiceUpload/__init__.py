import logging
import os
from pathlib import Path
import base64
import io
import time
import zipfile
import requests
from azure.identity import DefaultAzureCredential
from azure.storage.blob import BlobServiceClient
from PyPDF2 import PdfReader, PdfWriter
import azure.functions as func
import logging, importlib.util
logging.info("requests present at runtime? %s", importlib.util.find_spec("requests") is not None)


# -----------------------
# Config
# -----------------------
STORAGE_ACCOUNT_URL = os.getenv("STORAGE_ACCOUNT_URL", "https://samstgprod001.blob.core.windows.net/")
OUTPUT_CONTAINER = os.getenv("OUTPUT_CONTAINER", "processed-invoices")

# Cloudmersive
API_KEY = os.getenv("CLOUDMERSIVE_API_KEY")
HEADERS_JSON = {"Apikey": API_KEY, "Accept": "application/json"}
HEADERS_BIN = {"Apikey": API_KEY}

# Convert endpoint that returns multiple pages (JSON or ZIP):
# You can change this to another Cloudmersive convert endpoint if desired.
CONVERT_ENDPOINT = os.getenv(
    "CLOUDMERSIVE_CONVERT_ENDPOINT",
    "https://api.cloudmersive.com/convert/autodetect/to/png-array"
)

# Barcode scan endpoint (expects image file)
BARCODE_ENDPOINT = os.getenv(
    "CLOUDMERSIVE_BARCODE_ENDPOINT",
    "https://api.cloudmersive.com/barcode/scan/image"
)

REQUEST_TIMEOUT_SECS = int(os.getenv("CLOUDMERSIVE_TIMEOUT", "30"))
MAX_RETRIES = int(os.getenv("CLOUDMERSIVE_RETRIES", "4"))
BACKOFF_BASE_MS = int(os.getenv("CLOUDMERSIVE_BACKOFF_MS", "600"))

# Storage client (uses Managed Identity / Default creds)
credential = DefaultAzureCredential()
blob_service = BlobServiceClient(account_url=STORAGE_ACCOUNT_URL, credential=credential)


# -----------------------
# Cloudmersive helpers
# -----------------------
def _retry_sleep(attempt: int):
    delay = (BACKOFF_BASE_MS / 1000.0) * (2 ** attempt) + (0.1 * attempt)
    time.sleep(delay)


def convert_pdf_to_images(pdf_bytes: bytes) -> list[bytes]:
    """
    Sends the PDF to Cloudmersive to rasterize. Returns a list of PNG bytes,
    one per page. Handles JSON with URLs/base64 OR ZIP OR single-image bytes.
    """
    if not API_KEY:
        raise RuntimeError("CLOUDMERSIVE_API_KEY is not set")

    files = {"inputFile": ("invoices.pdf", pdf_bytes, "application/pdf")}

    # --- Call convert endpoint with retries ---
    for attempt in range(MAX_RETRIES + 1):
        try:
            resp = requests.post(CONVERT_ENDPOINT, headers=HEADERS_JSON, files=files, timeout=REQUEST_TIMEOUT_SECS)
            # Some convert endpoints return non-JSON (zip or image). If 406/415 etc., try bin headers.
            if resp.status_code in (429,) or resp.status_code >= 500:
                raise requests.HTTPError(f"Retryable status {resp.status_code}")
            if "application/json" not in resp.headers.get("Content-Type", "") and resp.status_code == 415:
                # Try again without JSON accept header
                resp = requests.post(CONVERT_ENDPOINT, headers=HEADERS_BIN, files=files, timeout=REQUEST_TIMEOUT_SECS)
            resp.raise_for_status()
            break
        except Exception as e:
            if attempt >= MAX_RETRIES:
                logging.error(f"Convert failed after retries: {e}")
                raise
            logging.warning(f"Convert attempt {attempt+1}/{MAX_RETRIES+1} failed: {e}")
            _retry_sleep(attempt)

    ctype = resp.headers.get("Content-Type", "").lower()
    images: list[bytes] = []

    if "application/json" in ctype:
        data = resp.json()
        # Common JSON shapes:
        #   { "PngResultPages": [ {"PageNumber":1,"URL":"..."}, {"Data":"<base64>"} ... ] }
        pages = data.get("PngResultPages") or []
        for p in pages:
            if "URL" in p and p["URL"]:
                img = requests.get(p["URL"], timeout=REQUEST_TIMEOUT_SECS).content
                images.append(img)
            elif "Data" in p and p["Data"]:
                images.append(base64.b64decode(p["Data"]))
        if not images:
            raise RuntimeError("Convert JSON returned no pages.")
        return images

    if "application/zip" in ctype or resp.content[:2] == b"PK":
        # Multi-page results often come back as a zip
        with zipfile.ZipFile(io.BytesIO(resp.content)) as zf:
            # Sort by filename to keep page order
            for name in sorted(zf.namelist()):
                if name.lower().endswith((".png", ".jpg", ".jpeg")):
                    images.append(zf.read(name))
        if not images:
            raise RuntimeError("ZIP contained no images.")
        return images

    if "image/" in ctype:
        # Single-page PDF → single image
        images.append(resp.content)
        return images

    raise RuntimeError(f"Unexpected content type from convert endpoint: {ctype}")


def extract_first_barcode_value(api_json: dict | None) -> tuple[str | None, str | None]:
    """
    Returns (barcode_type, value) from Cloudmersive scan response.
    Handles single and list response shapes.
    """
    if not api_json:
        return (None, None)

    # Single
    if api_json.get("RawText"):
        return (api_json.get("BarcodeType"), api_json.get("RawText"))

    # Lists
    for key in ("Barcodes", "ParsedBarcodes", "Results"):
        arr = api_json.get(key)
        if isinstance(arr, list) and arr:
            first = arr[0]
            btype = first.get("BarcodeType") or first.get("Type") or first.get("Symbology")
            for k in ("RawText", "Text", "Value", "value", "data"):
                if k in first and first[k]:
                    return (btype, str(first[k]))
    return (None, None)


def scan_image_for_barcode(img_bytes: bytes) -> tuple[str | None, str | None]:
    """
    Posts an image (PNG/JPEG) to Cloudmersive scan endpoint. Returns (type, value).
    Retries on 429/5xx.
    """
    files = {"imageFile": ("page.png", img_bytes, "image/png")}

    for attempt in range(MAX_RETRIES + 1):
        try:
            resp = requests.post(BARCODE_ENDPOINT, headers=HEADERS_JSON, files=files, timeout=REQUEST_TIMEOUT_SECS)
            if resp.status_code in (429,) or resp.status_code >= 500:
                raise requests.HTTPError(f"Retryable status {resp.status_code}")
            resp.raise_for_status()
            return extract_first_barcode_value(resp.json())
        except Exception as e:
            if attempt >= MAX_RETRIES:
                logging.error(f"Scan failed after retries: {e}")
                return (None, None)
            logging.warning(f"Scan attempt {attempt+1}/{MAX_RETRIES+1} failed: {e}")
            _retry_sleep(attempt)


# -----------------------
# Split & upload
# -----------------------
def split_pdf_by_barcode_cloudmersive(pdf_path: Path, output_dir: Path) -> list[Path]:
    output_dir.mkdir(parents=True, exist_ok=True)
    pdf_bytes = pdf_path.read_bytes()

    # 1) PDF -> images (Cloudmersive)
    page_images = convert_pdf_to_images(pdf_bytes)

    # 2) Read original PDF for page copies
    reader = PdfReader(str(pdf_path))

    invoice_writer: PdfWriter | None = None
    invoice_number: str | None = None
    output_files: list[Path] = []

    for i, img in enumerate(page_images):
        bctype, value = scan_image_for_barcode(img)

        # Start a new invoice when we see a barcode (Code128 expected)
        if value:
            if invoice_writer and invoice_number:
                out = output_dir / f"{invoice_number}.pdf"
                with open(out, "wb") as fo:
                    invoice_writer.write(fo)
                output_files.append(out)

            invoice_number = value.strip()
            invoice_writer = PdfWriter()

        if invoice_writer:
            # Add the corresponding page from the ORIGINAL PDF
            invoice_writer.add_page(reader.pages[i])

    # Flush final invoice
    if invoice_writer and invoice_number:
        out = output_dir / f"{invoice_number}.pdf"
        with open(out, "wb") as fo:
            invoice_writer.write(fo)
        output_files.append(out)

    return output_files


def upload_to_blob(file_paths: list[Path]):
    container_client = blob_service.get_container_client(OUTPUT_CONTAINER)
    try:
        container_client.create_container()
    except Exception:
        pass

    for file_path in file_paths:
        blob_name = file_path.name
        with open(file_path, "rb") as data:
            container_client.upload_blob(name=blob_name, data=data, overwrite=True)
            logging.info(f"Uploaded {blob_name} to {OUTPUT_CONTAINER}")


# -----------------------
# Azure Function entry
# -----------------------
def main(myblob: func.InputStream):
    logging.info(f"Triggered by blob: {myblob.name}")

    tmp_input = Path("/tmp/input.pdf")
    tmp_output = Path("/tmp/invoices")
    tmp_input.parent.mkdir(parents=True, exist_ok=True)

    with open(tmp_input, "wb") as f:
        f.write(myblob.read())

    try:
        split_files = split_pdf_by_barcode_cloudmersive(tmp_input, tmp_output)
        if not split_files:
            logging.warning("No barcodes detected; nothing to upload.")
        else:
            upload_to_blob(split_files)
            logging.info("Processing and upload completed successfully.")
    except Exception as e:
        logging.error(f"Failed to process PDF: {e}")
        raise
