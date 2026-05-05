# syntax=docker/dockerfile:1
# Containerfile — runs the Flask site behind gunicorn,
# with cloudflared tunnel in the same container.

FROM python:3.13-slim AS base

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    APP_HOME=/app \
    APP_PORT=8000

# --- System deps + cloudflared ---------------------------------------------
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl tini \
 && curl -fsSL -o /usr/local/bin/cloudflared \
    "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-$(dpkg --print-architecture)" \
 && chmod +x /usr/local/bin/cloudflared \
 && rm -rf /var/lib/apt/lists/*

# --- Python deps -----------------------------------------------------------
WORKDIR ${APP_HOME}
COPY pyproject.toml uv.lock ./
RUN pip install --no-cache-dir flask gunicorn

# --- App -------------------------------------------------------------------
COPY app.py ./
COPY templates ./templates

# --- Entrypoint ------------------------------------------------------------
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Run as non-root
RUN useradd --system --uid 1001 --home-dir ${APP_HOME} appuser \
 && chown -R appuser:appuser ${APP_HOME}
USER appuser

EXPOSE 8000

# tini reaps zombie processes from the two background workers
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/entrypoint.sh"]
