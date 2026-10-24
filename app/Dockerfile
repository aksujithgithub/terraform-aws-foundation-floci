FROM python:3.12-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application
COPY app.py .

# Run as non-root
RUN useradd -r -u 1001 appuser
USER appuser

EXPOSE 5000

CMD ["python", "app.py"]
