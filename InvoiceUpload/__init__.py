
import sys
import os
from pathlib import Path
from shared import utils
import logging
import tempfile
import pdfplumber
from PyPDF2 import PdfWriter
import azure.functions as func
from azure.storage.blob import BlobServiceClient
from azure.identity import DefaultAzureCredential

STORAGE_URL = os.getenv("STORAGE_URL")
CONTAINER_NAME = os.getenv("CONTAINER_NAME", "invoices")

class BlobDownloader:
    def __init__(self, storage_url, container_name):
        self.blob_service_client = BlobServiceClient(account_url=storage_url, credential=DefaultAzureCredential())
        self.container_client = self.blob_service_client.get_container_client(container_name)

    def download_pdfs(self, target_dir):
        target_dir = Path(target_dir)
        target_dir.mkdir(parents=True, exist_ok=True)
        pdf_paths = []
        for blob in self.container_client.list_blobs():
            if blob.name.lower().endswith('.pdf'):
                blob_client = self.container_client.get_blob_client(blob)
                safe_filename = os.path.basename(blob.name)
                file_path = target_dir / safe_filename
                file_path.parent.mkdir(parents=True, exist_ok=True)
                with open(file_path, "wb") as f:
                    f.write(blob_client.download_blob().readall())
                pdf_paths.append(str(file_path))
        return pdf_paths

def split_pdf_by_invoice(blob_file_path):
    with pdfplumber.open(blob_file_path) as pdf:
        invoice_groups = []
        current_invoice = []
        for i, page in enumerate(pdf.pages):
            image = page.to_image(resolution=300).original.convert("L")
            if utils.ocr_invoice_number(image):
                if current_invoice:
                    invoice_groups.append(current_invoice)
                current_invoice = [i]
            else:
                current_invoice.append(i)
        if current_invoice:
            invoice_groups.append(current_invoice)
    return invoice_groups

def save_and_upload_invoices(groups, blob_file_path):
    with pdfplumber.open(blob_file_path) as pdf:
        for pages in groups:
            writer = PdfWriter()
            invoice_number = None
            for page_num in pages:
                page = pdf.pages[page_num]
                writer.add_page(page)
                if invoice_number is None:
                    image = page.to_image(resolution=300).original.convert("L")
                    invoice_number = utils.ocr_invoice_number(image)
            if not invoice_number:
                invoice_number = f"unknown_{pages[0]+1}"
            file_path = os.path.join(tempfile.gettempdir(), f"invoice_{invoice_number}.pdf")
            with open(file_path, "wb") as f:
                writer.write(f)
            utils.upload_to_gaviti(file_path, invoice_number)

def azure_function_main(inputBlob: func.InputStream):
    logging.info(f"Triggered by blob: {inputBlob.name} ({inputBlob.length} bytes)")
    temp_pdf_path = os.path.join(tempfile.gettempdir(), inputBlob.name.replace("/", "_"))
    with open(temp_pdf_path, "wb") as f:
        f.write(inputBlob.read())
    invoice_sets = split_pdf_by_invoice(temp_pdf_path)
    logging.info(f"Found {len(invoice_sets)} invoice(s) to process.")
    save_and_upload_invoices(invoice_sets, temp_pdf_path)
    logging.info("Processing complete.")

def main():
    logging.basicConfig(level=logging.INFO)
    tmp_dir = Path(tempfile.gettempdir()) / "pdfs"
    downloader = BlobDownloader(STORAGE_URL, CONTAINER_NAME)
    pdf_files = downloader.download_pdfs(tmp_dir)
    logging.info(f"Downloaded {len(pdf_files)} PDF(s) to {tmp_dir}")
    for pdf_path in pdf_files:
        invoice_sets = split_pdf_by_invoice(pdf_path)
        logging.info(f"Found {len(invoice_sets)} invoice(s) in {pdf_path}")
        save_and_upload_invoices(invoice_sets, pdf_path)
        logging.info(f"Processed {pdf_path}")

if __name__ == "__main__":
    main()
