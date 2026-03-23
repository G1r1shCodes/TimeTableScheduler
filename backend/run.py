import uvicorn

if __name__ == "__main__":
    uvicorn.run(
        "app.main:app",
        host     = "0.0.0.0",
        port     = 8000,
        reload   = True,     # Set to False in production
        workers  = 1,        # Keep 1 for the scheduler (OR-Tools uses its own threads)
    )
