import logging
import os
import dotenv
from pathlib import Path
import numpy as np
import cv2
from azure.identity import DefaultAzureCredential
from azure.storage.blob import BlobServiceClient

dotenv.load_dotenv()

from PyPDF2 import PdfReader, PdfWriter
from pdf2image import convert_from_path
from pyzbar.pyzbar import decode
from azure.storage.blob import BlobServiceClient
import azure.functions as func

STORAGE_ACCOUNT_URL = "https://samstgprod001.blob.core.windows.net/"
credential = DefaultAzureCredential()
blob_service = BlobServiceClient(account_url=STORAGE_ACCOUNT_URL, credential=credential)
POPPLER_PATH =  "/tools/poppler/bin"
OUTPUT_CONTAINER = "processed-invoices"

def extract_barcode_text(image) -> str | None:
    decoded = decode(image)
    if decoded:
        return decoded[0].data.decode("utf-8")
    return None

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
            if invoice_writer and invoice_number:
                output_path = output_dir / f"{invoice_number}.pdf"
                with open(output_path, "wb") as f_out:
                    invoice_writer.write(f_out)
                    output_files.append(output_path)

            invoice_number = detected_number
            invoice_writer = PdfWriter()

        if invoice_writer:
            invoice_writer.add_page(reader.pages[i])

    if invoice_writer and invoice_number:
        output_path = output_dir / f"{invoice_number}.pdf"
        with open(output_path, "wb") as f_out:
            invoice_writer.write(f_out)
            output_files.append(output_path)

    return output_files

def upload_to_blob(file_paths: list[Path]):
    blob_service = BlobServiceClient(account_url=STORAGE_ACCOUNT_URL, credential=credential)
    container_client = blob_service.get_container_client(OUTPUT_CONTAINER)

    for file_path in file_paths:
        blob_name = file_path.name
        with open(file_path, "rb") as data:
            container_client.upload_blob(name=blob_name, data=data, overwrite=True)
            logging.info(f"Uploaded {blob_name} to {OUTPUT_CONTAINER}")

def main(myblob: func.InputStream):
    logging.info(f"Triggered by blob: {myblob.name}")

    tmp_input = Path("/tmp/input.pdf")
    tmp_output = Path("/tmp/invoices")

    with open(tmp_input, "wb") as f:
        f.write(myblob.read())

    try:
        split_files = split_pdf_by_barcode(tmp_input, tmp_output)
        upload_to_blob(split_files)
        logging.info("Processing and upload completed successfully.")
    except Exception as e:
        logging.error(f"Failed to process PDF: {e}")