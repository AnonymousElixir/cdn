#!/bin/bash

# Forgejo Docker Setup Script
# This script sets up Forgejo with Docker and Docker Compose

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
FORGEJO_VERSION="9"
INSTALL_DIR="/opt/forgejo"
DATA_DIR="${INSTALL_DIR}/data"
HTTP_PORT="3000"
SSH_PORT="2222"

echo -e "${GREEN}=== Forgejo Docker Setup ===${NC}\n"

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run as root or with sudo${NC}"
    exit 1
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}Docker not found. Installing Docker...${NC}"
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
    systemctl enable docker
    systemctl start docker
    echo -e "${GREEN}Docker installed successfully${NC}\n"
else
    echo -e "${GREEN}Docker is already installed${NC}\n"
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo -e "${YELLOW}Docker Compose not found. Installing...${NC}"
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    echo -e "${GREEN}Docker Compose installed successfully${NC}\n"
else
    echo -e "${GREEN}Docker Compose is already installed${NC}\n"
fi

# Create directory structure
echo "Creating directory structure..."
mkdir -p "${DATA_DIR}"
mkdir -p "${INSTALL_DIR}"

# Create docker-compose.yml
echo "Creating docker-compose.yml..."
cat > "${INSTALL_DIR}/docker-compose.yml" <<EOF
version: "3"

networks:
  forgejo:
    external: false

services:
  server:
    image: codeberg.org/forgejo/forgejo:${FORGEJO_VERSION}
    container_name: forgejo
    environment:
      - USER_UID=1000
      - USER_GID=1000
    restart: always
    networks:
      - forgejo
    volumes:
      - ${DATA_DIR}:/data
      - /etc/timezone:/etc/timezone:ro
      - /etc/localtime:/etc/localtime:ro
    ports:
      - "${HTTP_PORT}:3000"
      - "${SSH_PORT}:22"
EOF

echo -e "${GREEN}docker-compose.yml created${NC}\n"

# Set proper permissions
echo "Setting permissions..."
chown -R 1000:1000 "${DATA_DIR}"

# Create a systemd service (optional, for easier management)
echo "Creating systemd service..."
cat > /etc/systemd/system/forgejo-docker.service <<EOF
[Unit]
Description=Forgejo Docker Container
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=${INSTALL_DIR}
ExecStart=/usr/bin/docker-compose up -d
ExecStop=/usr/bin/docker-compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable forgejo-docker.service

# Start Forgejo
echo -e "\n${YELLOW}Starting Forgejo...${NC}"
cd "${INSTALL_DIR}"
docker-compose up -d

# Wait for container to be ready
echo "Waiting for Forgejo to start..."
sleep 5

# Check if container is running
if docker ps | grep -q forgejo; then
    echo -e "\n${GREEN}=== Installation Complete! ===${NC}\n"
    echo -e "Forgejo is now running!"
    echo -e "Web Interface: ${GREEN}http://localhost:${HTTP_PORT}${NC}"
    echo -e "SSH Port: ${GREEN}${SSH_PORT}${NC}"
    echo -e "\nData directory: ${DATA_DIR}"
    echo -e "Docker Compose file: ${INSTALL_DIR}/docker-compose.yml"
    echo -e "\n${YELLOW}Useful commands:${NC}"
    echo -e "  Start:   ${GREEN}systemctl start forgejo-docker${NC} or ${GREEN}cd ${INSTALL_DIR} && docker-compose up -d${NC}"
    echo -e "  Stop:    ${GREEN}systemctl stop forgejo-docker${NC} or ${GREEN}cd ${INSTALL_DIR} && docker-compose down${NC}"
    echo -e "  Restart: ${GREEN}systemctl restart forgejo-docker${NC} or ${GREEN}cd ${INSTALL_DIR} && docker-compose restart${NC}"
    echo -e "  Logs:    ${GREEN}docker logs forgejo -f${NC}"
    echo -e "  Status:  ${GREEN}docker ps | grep forgejo${NC}"
else
    echo -e "${RED}Error: Container failed to start${NC}"
    echo "Check logs with: docker logs forgejo"
    exit 1
fi
