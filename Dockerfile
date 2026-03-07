# Install uv
ARG CUDA_VERSION=12.4.1
ARG OS_VERSION=22.04
FROM nvidia/cuda:${CUDA_VERSION}-base-ubuntu${OS_VERSION}

# Define Python version argument
ARG PYTHON_VERSION=3.11

# Configure environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    MUJOCO_GL=egl \
    PATH=/lerobot/.venv/bin:$PATH \
    CUDA_VISIBLE_DEVICES=0 \
    TEST_TYPE=single_gpu \
    DEVICE=cuda

# Install Python, system dependencies, and uv (as root)
RUN apt-get update && apt-get install -y --no-install-recommends \
    software-properties-common build-essential git curl \
    libglib2.0-0 libgl1-mesa-glx libegl1-mesa ffmpeg \
    libusb-1.0-0-dev speech-dispatcher libgeos-dev portaudio19-dev \
    cmake pkg-config ninja-build \
    && add-apt-repository -y ppa:deadsnakes/ppa \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
       python${PYTHON_VERSION} \
       python${PYTHON_VERSION}-venv \
       python${PYTHON_VERSION}-dev \
    && curl -LsSf https://astral.sh/uv/install.sh | sh \
    && mv /root/.local/bin/uv /usr/local/bin/uv \
    && useradd --create-home --shell /bin/bash user_lerobot \
    && usermod -aG sudo user_lerobot \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install Python and necessary tools
RUN apt-get update && \
    apt-get install -y \
    software-properties-common \
    curl \
    ca-certificates \
    gnupg \
    && add-apt-repository ppa:deadsnakes/ppa \
    rm -rf /var/lib/apt/lists/*

# Install system dependencies
RUN apt-get update && apt-get install -y \
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
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

RUN uv python install 3.11

ENV __GLX_VENDOR_LIBRARY_NAME=nvidia
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility,graphics
ENV UV_PYTHON=python3.11

## Clone and configure IsaacLab
RUN if [ ! -d "third_party/IsaacLab" ]; then git clone https://github.com/lehome-official/IsaacLab.git third_party/IsaacLab; fi

# Install dependencies
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --locked --no-install-project

# install IsaacLab dependencies
RUN TERM=xterm /bin/bash -c "source .venv/bin/activate && yes | ./third_party/IsaacLab/isaaclab.sh -i none"

# Copy the project into the image
COPY . /app

# Sync the project
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --locked

# Install LeHome package
RUN uv pip install -e ./source/lehome
