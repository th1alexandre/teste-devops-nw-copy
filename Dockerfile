### Base stage, load environment variables
FROM python:3.12-slim-bookworm AS python-base

# Python envs
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONFAULTHANDLER=1 \
    PYTHONHASHSEED=random

# Pip envs
ENV PIP_NO_CACHE_DIR=off \
    PIP_DEFAULT_TIMEOUT=100 \
    PIP_DISABLE_PIP_VERSION_CHECK=on

# Poetry envs
ENV POETRY_NO_INTERACTION=1 \
    POETRY_VERSION=1.8.3 \
    POETRY_HOME=/opt/poetry \
    POETRY_VIRTUALENVS_IN_PROJECT=true

# Other envs
ENV APP_PATH=/app \
    PYSETUP_PATH=/opt/pysetup \
    VENV_PATH=/opt/pysetup/.venv \
    PATH="$POETRY_HOME/bin:$VENV_PATH/bin:$PATH"


### Building stage, installs poetry and project dependencies
FROM python-base AS poetry-builder

# Installs essential tools for building poetry
RUN apt-get update \
    && apt-get install --no-install-recommends -y \
        curl build-essential

# Install Poetry, respects $POETRY_VERSION and $POETRY_HOME
RUN curl -sSL https://install.python-poetry.org | python

# Cache requirements and installs project dependencies
WORKDIR $PYSETUP_PATH
COPY ./poetry.lock ./pyproject.toml ./
RUN poetry install


### Production final stage
FROM python-base AS production

# Copy Poetry and pre-build production dependencies
COPY --from=poetry-builder $POETRY_HOME $POETRY_HOME
COPY --from=poetry-builder $PYSETUP_PATH $APP_PATH

# Required to bind docker-compose volumes
WORKDIR $APP_PATH

# Copy only source code for production
COPY ./src /app/src

# Use a non-root user for security
RUN groupadd -r appuser && useradd -r -g appuser appuser
USER appuser

# Flask app port
EXPOSE 5000

# Run flask in production mode, debug false
ENTRYPOINT poetry run python -u src/main.py
