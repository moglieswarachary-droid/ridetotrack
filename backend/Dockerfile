FROM python:3.12-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Install uv for fast package management
COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/uv

# Copy project specification and install dependencies
COPY pyproject.toml README.md* ./
RUN uv venv /opt/venv && uv pip install --python /opt/venv/bin/python -e .

ENV PATH="/opt/venv/bin:$PATH"
ENV PYTHONPATH="/app"

# Copy backend application source code and web viewer
COPY . .

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
