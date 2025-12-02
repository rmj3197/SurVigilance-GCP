FROM python:3.12-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# Install dependencies including Chrome for testing and Google Cloud SDK
RUN apt-get update && apt-get install -y --no-install-recommends \
    xvfb \
    git \
    ca-certificates \
    wget \
    gnupg \
    curl \
    unzip \
    && ARCH=$(dpkg --print-architecture) \
    && case "$ARCH" in \
        amd64) \
            mkdir -p /usr/share/keyrings \
            && wget -qO- https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg \
            && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list \
            && apt-get update \
            && apt-get install -y google-chrome-stable \
            ;; \
        arm64) \
            apt-get install -y chromium \
            && ln -s /usr/bin/chromium /usr/bin/google-chrome \
            ;; \
    esac \
    && echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee /etc/apt/sources.list.d/google-cloud-sdk.list \
    && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg \
    && apt-get update \
    && apt-get install -y google-cloud-sdk \
    && rm -rf /var/lib/apt/lists/*

RUN google-chrome --version
RUN gcloud --version

RUN git clone https://github.com/rmj3197/SurVigilance.git

WORKDIR /app/SurVigilance

COPY run_tests.sh .
RUN chmod +x run_tests.sh

RUN pip install --no-cache-dir . pytest pytest-excel pytest-flakefinder pytest-random-order pytest-xdist

CMD ["./run_tests.sh"]