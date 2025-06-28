# Use a specific Python version for better reproducibility
FROM python:3.9-slim

# Set environment variables for non-interactive installation
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies required for Chrome and Python packages
RUN apt-get update && apt-get install -y \
    wget \
    gnupg \
    unzip \
    curl \
    jq \
    # Clean up apt cache to reduce image size
    && rm -rf /var/lib/apt/lists/*

# Add Google Chrome's official repository
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list'

# Install Google Chrome and ChromeDriver
RUN apt-get update \
    && apt-get install -y google-chrome-stable \
    && rm -rf /var/lib/apt/lists/*
    
# --- Install ChromeDriver ---
# Find the latest version of Chrome installed
RUN CHROME_VERSION=$(google-chrome --version | cut -d " " -f3 | cut -d "." -f1-3) \
    # Find the corresponding ChromeDriver version
    && DRIVER_VERSION=$(curl -sS "https://googlechromelabs.github.io/chrome-for-testing/known-good-versions-with-downloads.json" | jq -r ".versions[] | select(.version | startswith(\"$CHROME_VERSION\")) | .downloads.chromedriver[0].url" | head -n 1) \
    && wget -O /tmp/chromedriver.zip "$DRIVER_VERSION" \
    && unzip /tmp/chromedriver.zip -d /usr/local/bin/ \
    # The zip file contains a directory, so we move the executable up
    && mv /usr/local/bin/chromedriver-linux64/chromedriver /usr/local/bin/chromedriver \
    && rm -rf /usr/local/bin/chromedriver-linux64 /tmp/chromedriver.zip \
    && chmod +x /usr/local/bin/chromedriver

# Set the path for Selenium to find the driver
ENV CHROME_DRIVER_PATH=/usr/local/bin/chromedriver

# Set the working directory in the container
WORKDIR /app

# Copy and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application's code
COPY . .

# Expose the port the app runs on
EXPOSE 8080

# The command to run the application
# Using --schedule flag to run in scheduler mode on Cloud Run
CMD ["python", "main.py", "--schedule"]