from fastapi import APIRouter, Depends, HTTPException, status
from app.models.schemas import HealthProfileCreate, HealthProfileResponse
from app.middleware.auth import verify_token
from app.database import get_db
import logging

router = APIRouter()
logger = logging.getLogger(__name__)


@router.get("/me", response_model=HealthProfileResponse)
async def get_profile(current_user: dict = Depends(verify_token), conn=Depends(get_db)):
    row = await conn.fetchrow(
        "SELECT * FROM health_profiles WHERE user_id = $1", current_user["user_id"]
    )
    if not row:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Profile not found.")
    return HealthProfileResponse(**dict(row))


@router.post("/me", response_model=HealthProfileResponse)
async def upsert_profile(
    data: HealthProfileCreate,
    current_user: dict = Depends(verify_token),
    conn=Depends(get_db),
):
    user_id = current_user["user_id"]
    row = await conn.fetchrow(
        """
        INSERT INTO health_profiles (user_id, age, sex, weight_kg, height_cm, goal, diseases, allergies, diet_type)
        VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)
        ON CONFLICT (user_id) DO UPDATE SET
            age = EXCLUDED.age,
            sex = EXCLUDED.sex,
            weight_kg = EXCLUDED.weight_kg,
            height_cm = EXCLUDED.height_cm,
            goal = EXCLUDED.goal,
            diseases = EXCLUDED.diseases,
            allergies = EXCLUDED.allergies,
            diet_type = EXCLUDED.diet_type,
            updated_at = NOW()
        RETURNING *
        """,
        user_id, data.age, data.sex, data.weight_kg, data.height_cm,
        data.goal, data.diseases, data.allergies, data.diet_type,
    )
    return HealthProfileResponse(**dict(row))
