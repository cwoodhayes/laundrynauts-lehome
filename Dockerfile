# Install uv
FROM python:3.11-slim
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# Change the working directory to the `app` directory
WORKDIR /app

# Install system dependencies
RUN apt update && apt install -y \
    build-essential \
    linux-libc-dev \
    libglu1-mesa \
    libgl1 \
    libegl1 \
    libxrandr2 \
    libxinerama1 \
    libxcursor1 \
    libxi6 \
    libxext6 \
    libx11-6 \
    git \
    && rm -rf /var/lib/apt/lists/*

ENV __GLX_VENDOR_LIBRARY_NAME=nvidia

## Clone and configure IsaacLab
RUN git clone https://github.com/lehome-official/IsaacLab.git third_party/IsaacLab

# Install dependencies
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --locked --no-install-project

# Copy the project into the image
COPY . /app

# Sync the project
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --locked

# Install LeHome package
RUN uv pip install -e ./source/lehome
