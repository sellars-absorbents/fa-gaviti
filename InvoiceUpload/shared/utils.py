""" import os
import re
import base64
import logging
import pytesseract
import re
import logging
from pdf2image import convert_from_path
import requests
import pyodbc
from PIL import Image
from pathlib import Path
from shared import utils
import tempfile
import pdfplumber
import pytesseract
from PyPDF2 import PdfReader, PdfWriter
import azure.functions as func
from azure.storage.blob import BlobServiceClient
from azure.identity import DefaultAzureCredential
from dotenv import load_dotenv
from shared.utils import split_pdf_by_invoice, save_and_upload_invoices
from InvoiceUpload.utils import BlobDownloader

# Environment settings
GAVITI_TOKEN = os.getenv("GAVITI_TOKEN")
GAVITI_ADAPTER_URL = os.getenv("GAVITI_ADAPTER_URL")
SQL_SERVER = os.getenv("SQL_SERVER")
SQL_DATABASE = os.getenv("SQL_DATABASE")
SQL_USERNAME = os.getenv("SQL_USERNAME")
SQL_PASSWORD = os.getenv("SQL_PASSWORD")
SQL_PROC_NAME = os.getenv("SQL_PROC_NAME", "usp_ApplyCashToGP")
KEYWORD_REGEX = r"(?:invoice\s*[#:]?\s*|inv(?:oice)?\s*no\.?\s*)(\d{4,})"

SQL_CONN_STR = f"DRIVER={{ODBC Driver 17 for SQL Server}};SERVER={SQL_SERVER};DATABASE={SQL_DATABASE};UID={SQL_USERNAME};PWD={SQL_PASSWORD}"



def upload_to_gaviti(file_path, invoice_id):
    with open(file_path, "rb") as f:
        encoded_pdf = base64.b64encode(f.read()).decode("utf-8")
    payload = {
        "invoiceId": invoice_id,
        "fileName": os.path.basename(file_path),
        "token": GAVITI_TOKEN,
        "data": encoded_pdf,
        "allowNotExistsInvoices": False
    }
    response = requests.post(GAVITI_ADAPTER_URL, json=payload)
    if response.status_code == 200:
        logging.info(f"Uploaded: {invoice_id}")
    else:
        logging.error(f"Upload failed for {invoice_id}: {response.status_code} - {response.text}")

def ocr_invoice_number(image):
    text = pytesseract.image_to_string(image)
    match = re.search(r'\b(004\d{5})\b', text)
    return match.group(1) if match else None

def split_pdf_by_invoice(pdf_path: Path, output_dir: Path):
    output_dir.mkdir(parents=True, exist_ok=True)
    invoice_writer = None
    invoice_number = None

    with pdfplumber.open(pdf_path) as pdf, open(pdf_path, "rb") as f:
        reader = PdfReader(f)
        for i, page in enumerate(pdf.pages):
            # Convert PDF page to image
            image = page.to_image(resolution=300).original.convert("L")
            detected_invoice = ocr_invoice_number(image)

            if detected_invoice:
                # Save previous invoice before starting a new one
                if invoice_writer and invoice_number:
                    out_path = output_dir / f"{invoice_number}.pdf"
                    with open(out_path, "wb") as out_f:
                        invoice_writer.write(out_f)

                # Start new invoice
                invoice_number = detected_invoice
                invoice_writer = PdfWriter()

            if invoice_writer:
                invoice_writer.add_page(reader.pages[i])
            else:
                logging.warning(f"Page {i} skipped – no invoice detected yet.")

        # Save the last invoice
        if invoice_writer and invoice_number:
            out_path = output_dir / f"{invoice_number}.pdf"
            with open(out_path, "wb") as out_f:
                invoice_writer.write(out_f)

    logging.info(f"Invoices saved to {output_dir}")

    

def save_and_upload_invoices(invoice_sets, original_pdf_path):
    reader = PdfReader(original_pdf_path)

    for i, page_indices in enumerate(invoice_sets):
        writer = PdfWriter()

        for index in page_indices:
            writer.add_page(reader.pages[index])

        invoice_path = Path(original_pdf_path).parent / f"invoice_{i + 1}.pdf"
        with open(invoice_path, "wb") as f:
            writer.write(f)

        # Upload logic here
        # blob_service.upload_blob(invoice_path)


def execute_gp_proc(cash_record):
    try:
        with pyodbc.connect(SQL_CONN_STR) as conn:
            with conn.cursor() as cursor:
                cursor.execute(f"{{CALL {SQL_PROC_NAME} (?, ?, ?, ?)}}",
                    cash_record.get("invoiceId"),
                    cash_record.get("amountApplied"),
                    cash_record.get("paymentDate"),
                    cash_record.get("reference")
                )
                conn.commit()
                logging.info(f"✅ Cash applied for {cash_record.get('invoiceId')}")
    except Exception as e:
        logging.error(f"❌ Failed to insert {cash_record.get('invoiceId')}: {e}")
 """