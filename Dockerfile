FROM python:3.11-slim

# Force UTF-8 everywhere. The server prints emoji (✅/⚠️) on startup; under a
# C/ASCII locale (the slim image default) that raises UnicodeEncodeError and
# crashes the process. PYTHONUTF8/PYTHONIOENCODING make stdout UTF-8.
# PYTHONUNBUFFERED streams logs straight to the container log.
ENV PYTHONIOENCODING=utf-8 \
    PYTHONUTF8=1 \
    PYTHONUNBUFFERED=1 \
    PORT=8080

# Install build deps (some wheels may need a compiler)
RUN apt-get update && \
    apt-get install -y --no-install-recommends gcc && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install uv
RUN pip install --no-cache-dir --upgrade pip uv

# Install Python dependencies first (better layer caching)
COPY requirements.txt .
RUN uv pip install --system -r requirements.txt

# Copy application
COPY . .

# Run as a non-root user
RUN useradd -m -u 10001 appuser && chown -R appuser /app
USER appuser

EXPOSE 8080

# Run the Streamable-HTTP server, bound to all interfaces.
# Shell form so ${PORT} is expanded at runtime (AWS App Runner / ECS / Cloud Run
# all inject or expect a port). Defaults to 8080 if PORT is unset.
CMD python -m meta_ads_mcp --transport streamable-http --host 0.0.0.0 --port ${PORT:-8080}
