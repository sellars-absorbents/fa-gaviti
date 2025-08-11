
import os
import logging
import requests
import azure.functions as func
import logging


env_target = os.getenv("DEPLOY_ENV", "prod")
env_file = f"./env/.env.{env_target}"


GAVITI_API_URL = os.getenv("GAVITI_API_URL")

def fetch_cash_data():
    headers = {"Authorization": f"Bearer {os.getenv('GAVITI_TOKEN')}"}
    response = requests.get(GAVITI_API_URL, headers=headers)
    response.raise_for_status()
    return response.json()

def main(mytimer: func.TimerRequest) -> None:
    logging.info("⏱️ Gaviti Cash to GP sync triggered.")
    try:
        data = fetch_cash_data()
        for record in data:
            # utils.execute_gp_proc(record)
            logging.info("✅ Sync completed.")
    except Exception as e:
        logging.error(f"❌ Sync failed: {e}")
