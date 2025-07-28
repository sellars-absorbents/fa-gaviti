import sys
sys.path.append("C:/Code/azure-gaviti")
import os
from pathlib import Path
import logging
import tempfile
from PyPDF2 import PdfReader, PdfWriter
from azure.storage.blob import BlobServiceClient
from azure.identity import DefaultAzureCredential
from dotenv import load_dotenv
import pytesseract
import re
import pdfplumber
from pathlib import Path
from PIL import Image
import cv2
import numpy as np

env_target = os.getenv("DEPLOY_ENV", "prod")
env_file = f"../env/.env.{env_target}"
load_dotenv(dotenv_path=env_file)

storage_url = "https://samstgprod001.blob.core.windows.net/"
STORAGE_URL = "https://samstgprod001.blob.core.windows.net/"
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


INVOICE_REGEX = r'00[4]\d{5}'

# Preprocess function for OCR
def preprocess(image):
    img = np.array(image)

    # Only convert to grayscale if it's not already
    if len(img.shape) == 3 and img.shape[2] == 3:
        gray = cv2.cvtColor(img, cv2.COLOR_RGB2GRAY)
    else:
        gray = img

    _, thresh = cv2.threshold(gray, 150, 255, cv2.THRESH_BINARY)
    return Image.fromarray(thresh)

# OCR function to extract invoice number
def ocr_invoice_number(image: Image.Image) -> str:
    processed_img = preprocess(image)
    custom_config = r'--oem 3 --psm 6 -c tessedit_char_whitelist=0123456789'
    text = pytesseract.image_to_string(processed_img, config=custom_config)
    match = re.search(INVOICE_REGEX, text)
    return match.group(0) if match else None


# Main function to split a PDF by invoice number and save individual PDFs
def split_pdf_by_invoice(blob_file_path: str, output_dir: str):
    blob_file_path = Path(blob_file_path)
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    with open(blob_file_path, "rb") as f_pdf, pdfplumber.open(blob_file_path) as pdf:
        reader = PdfReader(f_pdf)
        writer = None
        invoice_number = None

        for i, page in enumerate(pdf.pages):
            image = page.to_image(resolution=300).original.convert("L")
            new_invoice_number = ocr_invoice_number(image)

            if new_invoice_number:
                # Save previous invoice PDF
                if writer and invoice_number:
                    file_path = output_dir / f"{invoice_number}.pdf"
                    with open(file_path, "wb") as f_out:
                        writer.write(f_out)

                # Start new invoice
                invoice_number = new_invoice_number
                writer = PdfWriter()

            if writer:
                writer.add_page(reader.pages[i])

        # Save last invoice
        if writer and invoice_number:
            file_path = output_dir / f"{invoice_number}.pdf"
            with open(file_path, "wb") as f_out:
                writer.write(f_out)

    return list(output_dir.glob("*.pdf"))
    

def main():
    logging.basicConfig(level=logging.INFO)
    try:
        tmp_dir = Path(tempfile.gettempdir()) / "pdfs"
        output_dir = tmp_dir / "split"
        # Download PDFs from Azure Blob Storage
        downloader = BlobDownloader(STORAGE_URL, CONTAINER_NAME)
        pdf_files = downloader.download_pdfs(tmp_dir)
        for pdf_path in pdf_files:
            invoice_files = split_pdf_by_invoice(pdf_path, output_dir)
            logging.info(f"Found {len(invoice_files)} invoice(s) in {pdf_path}")
            save_and_upload_invoices(invoice_files)
            logging.info(f"Processed {pdf_path}")
            invoice_sets = split_pdf_by_invoice(pdf_path, output_dir)
            logging.info(f"Found {len(invoice_sets)} invoice(s) in {pdf_path}")
    except Exception as e:
        logging.error(f"An error occurred: {e}")
def save_and_upload_invoices(invoice_files):
    for invoice_path in invoice_files:
      
        logging.info(f"Saved invoice: {invoice_path}")
       
if __name__ == "__main__":
    main()
 