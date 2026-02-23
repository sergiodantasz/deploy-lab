FROM ghcr.io/astral-sh/uv:0.9.29-trixie-slim AS builder

ENV \
  UV_COMPILE_BYTECODE=1 \
  UV_LINK_MODE=copy \
  UV_PYTHON_PREFERENCE=only-managed \
  UV_NO_DEV=1 \
  UV_PYTHON_INSTALL_DIR=/python

RUN \
  apt update && \
  apt upgrade -y && \
  apt autoremove -y && \
  apt clean && \
  rm -rf /var/lib/apt/lists/*

RUN uv python install 3.14.2

WORKDIR /app

RUN \
  --mount=type=cache,target=/root/.cache/uv \
  --mount=type=bind,source=uv.lock,target=uv.lock \
  --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
  uv sync --locked

COPY . /app

RUN \
  --mount=type=cache,target=/root/.cache/uv \
  uv sync --locked

FROM debian:trixie-slim AS development

ENV PYTHONUNBUFFERED=1

RUN \
  apt update && \
  apt upgrade -y && \
  apt install -y --no-install-recommends curl && \
  apt autoremove -y && \
  apt clean && \
  rm -rf /var/lib/apt/lists/*

RUN \
  groupadd --gid 1000 app && \
  useradd --uid 1000 --gid app --shell /bin/bash --create-home app

COPY --from=builder --chown=app:app /python /python
COPY --from=builder --chown=app:app /app /app

ENV PATH="/app/.venv/bin:$PATH"

USER app

WORKDIR /app

ENTRYPOINT [ "sh", "./scripts/entrypoint.sh" ]
