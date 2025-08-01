import logging
import os
from pathlib import Path
from PyPDF2 import PdfReader, PdfWriter
from pdf2image import convert_from_path
from pyzbar.pyzbar import decode
import numpy as np
import cv2
import azure.functions as func

POPPLER_PATH = os.getenv("POPPLER_PATH", "/usr/bin")

def extract_barcode_text(image) -> str | None:
    decoded = decode(image)
    if decoded:
        return decoded[0].data.decode("utf-8")
    return None

def split_pdf_by_barcode(pdf_path: Path, output_dir: Path):
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

def main(myblob: func.InputStream):
    logging.info(f"Processing blob: {myblob.name}")
    tmp_input = Path("/tmp/input.pdf")
    tmp_output = Path("/tmp/invoices")

    with open(tmp_input, "wb") as f:
        f.write(myblob.read())

    split_pdf_by_barcode(tmp_input, tmp_output)
    logging.info("Invoice processing complete.")
