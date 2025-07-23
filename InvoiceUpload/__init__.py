
import os
import logging
import tempfile
import pdfplumber
from PyPDF2 import PdfWriter
import azure.functions as func 
from shared import utils


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
                writer.add_page(page.page_obj)
                if invoice_number is None:
                    image = page.to_image(resolution=300).original.convert("L")
                    invoice_number = utils.ocr_invoice_number(image)
            if not invoice_number:
                invoice_number = f"unknown_{pages[0]+1}"
            file_path = os.path.join(tempfile.gettempdir(), f"invoice_{invoice_number}.pdf")
            with open(file_path, "wb") as f:
                writer.write(f)
            utils.upload_to_gaviti(file_path, invoice_number)

def main(inputBlob: func.InputStream):
    logging.info(f"Triggered by blob: {inputBlob.name} ({inputBlob.length} bytes)")
    temp_pdf_path = os.path.join(tempfile.gettempdir(), inputBlob.name.replace("/", "_"))
    with open(temp_pdf_path, "wb") as f:
        f.write(inputBlob.read())
    invoice_sets = split_pdf_by_invoice(temp_pdf_path)
    logging.info(f"Found {len(invoice_sets)} invoice(s) to process.")
    save_and_upload_invoices(invoice_sets, temp_pdf_path)
    logging.info("Processing complete.")
