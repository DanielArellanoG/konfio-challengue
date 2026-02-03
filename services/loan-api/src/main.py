from fastapi import FastAPI, HTTPException
import uuid
import httpx
import os
import asyncpg

app = FastAPI()

AUTH_URL = os.getenv("AUTH_SERVICE_URL")
SCORING_URL = os.getenv("SCORING_SERVICE_URL")
DATABASE_URL = os.getenv("DATABASE_URL")

@app.post("/loan/apply")
async def apply_loan(payload: dict):
    application_id = f"app-{uuid.uuid4().hex[:8]}"

    async with httpx.AsyncClient(timeout=2.0) as client:
        auth_resp = await client.post(
            f"{AUTH_URL}/validate",
            json={"userId": payload["userId"]}
        )
        if auth_resp.status_code != 200:
            raise HTTPException(status_code=401, detail="Unauthorized")

    conn = await asyncpg.connect(DATABASE_URL)
    await conn.execute(
        """
        INSERT INTO loan_applications(application_id, user_id, amount, status)
        VALUES ($1, $2, $3, 'RECEIVED')
        """,
        application_id,
        payload["userId"],
        payload["amount"]
    )

    async with httpx.AsyncClient(timeout=5.0) as client:
        scoring_resp = await client.post(
            f"{SCORING_URL}/score",
            json={
                "applicationId": application_id,
                "userId": payload["userId"],
                "amount": payload["amount"],
                "income": payload["income"]
            }
        )

    score = scoring_resp.json()["score"]
    decision = "APPROVED" if score >= 700 else "REJECTED"

    await conn.execute(
        """
        UPDATE loan_applications
        SET status = $1
        WHERE application_id = $2
        """,
        decision,
        application_id
    )

    await conn.close()

    return {
        "applicationId": application_id,
        "status": decision,
        "interestRate": 11.9 if decision == "APPROVED" else None
    }
