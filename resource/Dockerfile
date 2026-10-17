FROM python:3.10-slim

WORKDIR /app

COPY requirements.txt requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

COPY sample-stocks/ ./sample-stocks/
COPY ["app.py", "utils.py", "./"]

EXPOSE 5001

# --preload bach start_time yb9a nafs l-qima f ga3 workers
CMD ["gunicorn", "--preload", "-w", "2", "--threads", "4", "--keep-alive", "30", "-b", "0.0.0.0:5001", "app:app"]