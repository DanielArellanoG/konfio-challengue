from fastapi import FastAPI, HTTPException
import random
import time
import os

app = FastAPI()

RETRIES = int(os.getenv("RETRY_COUNT", "1"))
DELAY = int(os.getenv("RETRY_DELAY_MS", "100")) / 1000

def call_external_provider():
    if random.random() < 0.3:
        raise Exception("Provider timeout")
    return random.randint(600, 800)

@app.post("/score")
def score(payload: dict):
    last_error = None
    for attempt in range(RETRIES):
        try:
            score = call_external_provider()
            return {
                "score": score,
                "provider": "mock-provider"
            }
        except Exception as e:
            last_error = e
            time.sleep(DELAY)

    raise HTTPException(status_code=504, detail=str(last_error))
