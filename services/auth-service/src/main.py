from fastapi import FastAPI, HTTPException

app = FastAPI()

@app.post("/validate")
def validate(payload: dict):
    user_id = payload.get("userId")
    if not user_id:
        raise HTTPException(status_code=401)
    return {"valid": True}
