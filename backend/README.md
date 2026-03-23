# College Timetable Scheduler

## Project Structure
```
scheduler/
├── .env                        # DB credentials (you fill this)
├── requirements.txt            # Python dependencies
├── run.py                      # Start the server
├── app/
│   ├── __init__.py
│   ├── main.py                 # FastAPI app entry point
│   ├── database.py             # PostgreSQL connection
│   ├── models.py               # SQLAlchemy ORM models
│   ├── schemas.py              # Pydantic response schemas
│   ├── scheduler.py            # OR-Tools CSP solver (core logic)
│   └── routers/
│       ├── __init__.py
│       ├── scheduler.py        # POST /schedule/generate
│       └── timetable.py        # GET /timetable/... (dashboard reads)
```

## Setup
1. Fill in `.env` with your PostgreSQL credentials
2. `pip install -r requirements.txt`
3. `python run.py`
4. Open http://localhost:8000/docs to test all endpoints
