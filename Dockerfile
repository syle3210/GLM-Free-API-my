FROM golang:1.25-bookworm

WORKDIR /app

# System packages required by Playwright/Chromium
RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    wget \
    git \
    xvfb \
    libnss3 \
    libatk-bridge2.0-0 \
    libgtk-3-0 \
    libgbm1 \
    libasound2 \
    libxshmfence1 \
    libx11-xcb1 \
    libxcomposite1 \
    libxdamage1 \
    libxrandr2 \
    libpango-1.0-0 \
    libcairo2 \
    fonts-liberation \
    && rm -rf /var/lib/apt/lists/*

COPY . .

RUN go mod init zai-api && go mod tidy

# Install Playwright's browser/driver and Chromium
RUN go run github.com/mxschmitt/playwright-go/cmd/playwright install chromium

# Build the token collector
RUN go build -trimpath -ldflags="-s -w" \
    -o /usr/local/bin/token-collector \
    ./cmd/token-collector

# Build the API server
RUN go build -trimpath -ldflags="-s -w" \
    -o /usr/local/bin/zai-api \
    .

ENV HOST=0.0.0.0
ENV PORT=10000

EXPOSE 10000

CMD /bin/sh -c "/usr/local/bin/token-collector --tokens 100 --batch 1 --parallel 1 --no-tui && exec /usr/local/bin/zai-api"
