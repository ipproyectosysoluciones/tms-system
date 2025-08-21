#!/bin/bash

# ==========================================================
# TMS Transportation Logistics System - Advanced Setup Script
# Description: Complete setup script with error handling,
# validation, and multi-purpose functionality for TMS project
# Version: 2.0
# ==========================================================

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# ==================== CONFIGURATION ====================
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
readonly LOG_FILE="${PROJECT_ROOT}/setup.log"
readonly BACKUP_DIR="${PROJECT_ROOT}/backups"
readonly CONFIG_FILE="${PROJECT_ROOT}/.setup-config"

# Version requirements
readonly REQUIRED_NODE_VERSION="22.0.0"
readonly MYSQL_VERSION="8.0"
readonly REDIS_VERSION="7-alpine"

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# ==================== LOGGING FUNCTIONS ====================
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        "INFO")  echo -e "${GREEN}[INFO]${NC} $message" | tee -a "$LOG_FILE" ;;
        "WARN")  echo -e "${YELLOW}[WARN]${NC} $message" | tee -a "$LOG_FILE" ;;
        "ERROR") echo -e "${RED}[ERROR]${NC} $message" | tee -a "$LOG_FILE" ;;
        "DEBUG") [[ "${DEBUG:-0}" == "1" ]] && echo -e "${BLUE}[DEBUG]${NC} $message" | tee -a "$LOG_FILE" ;;
    esac
    
    echo "[$timestamp][$level] $message" >> "$LOG_FILE"
}

# ==================== ERROR HANDLING ====================
cleanup() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        log "ERROR" "Script failed with exit code $exit_code"
        log "INFO" "Check $LOG_FILE for details"
        
        # Offer to rollback changes
        if [[ -d "$BACKUP_DIR" ]] && [[ "$(ls -A $BACKUP_DIR 2>/dev/null)" ]]; then
            read -p "Do you want to rollback changes? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                rollback_changes
            fi
        fi
    fi
    exit $exit_code
}

trap cleanup EXIT ERR INT TERM

# ==================== VALIDATION FUNCTIONS ====================
check_prerequisites() {
    log "INFO" "Checking prerequisites..."
    
    local missing_tools=()
    
    # Check required tools
    for tool in node npm pnpm git docker docker-compose; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        log "WARN" "Missing required tools: ${missing_tools[*]}"
        log "INFO" "Installing missing global tools..."
    fi

    # Check Node.js version (must be 22.x)
    local node_version=$(node -v | sed 's/v//')
    if ! version_compare "$node_version" "$REQUIRED_NODE_VERSION"; then
        log "ERROR" "Node.js version $node_version is incompatible. Required: Node.js 22.x"
        return 1
    fi
    
    # Check Docker status
    if ! docker info &> /dev/null; then
        log "WARN" "Docker is not running. Docker configurations will be created but won't be tested"
    fi
    
    log "INFO" "All prerequisites are met (Node.js $node_version)"
    return 0
}

version_compare() {
    local version1="$1"
    local version2="$2"
    
    if [[ "$(printf '%s\n' "$version2" "$version1" | sort -V | head -n1)" == "$version2" ]]; then
        return 0
    else
        return 1
    fi
}

check_existing_project() {
    if [[ -f "package.json" ]] || [[ -d "backend" ]] || [[ -d ".git" ]]; then
        log "WARN" "Existing project detected"
        read -p "This will modify existing files. Continue? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log "INFO" "Setup cancelled by user"
            exit 0
        fi
        return 0
    fi
    return 1
}

# ==================== BACKUP FUNCTIONS ====================
create_backup() {
    if check_existing_project; then
        log "INFO" "Creating backup of existing files..."
        
        mkdir -p "$BACKUP_DIR"
        local backup_name="backup_$(date +%Y%m%d_%H%M%S)"
        local backup_path="$BACKUP_DIR/$backup_name"
        
        mkdir -p "$backup_path"
        
        # Backup existing files
        [[ -f "package.json" ]] && cp "package.json" "$backup_path/"
        [[ -f ".env" ]] && cp ".env" "$backup_path/"
        [[ -d "backend" ]] && cp -r "backend" "$backup_path/"
        [[ -f "docker-compose.yml" ]] && cp "docker-compose.yml" "$backup_path/"
        
        log "INFO" "Backup created at: $backup_path"
        echo "$backup_path" > "$BACKUP_DIR/.last_backup"
    fi
}

rollback_changes() {
    local last_backup_file="$BACKUP_DIR/.last_backup"
    
    if [[ -f "$last_backup_file" ]]; then
        local backup_path=$(cat "$last_backup_file")
        
        if [[ -d "$backup_path" ]]; then
            log "INFO" "Rolling back changes from: $backup_path"
            
            # Restore files
            [[ -f "$backup_path/package.json" ]] && cp "$backup_path/package.json" .
            [[ -f "$backup_path/.env" ]] && cp "$backup_path/.env" .
            [[ -d "$backup_path/backend" ]] && cp -r "$backup_path/backend" .
            [[ -f "$backup_path/docker-compose.yml" ]] && cp "$backup_path/docker-compose.yml" .
            
            log "INFO" "Rollback completed"
        else
            log "ERROR" "Backup directory not found: $backup_path"
        fi
    else
        log "WARN" "No backup found to rollback"
    fi
}

# ==================== CORE SETUP FUNCTIONS ====================

# Development Configuration Functions
create_typescript_config() {
    log "INFO" "Creating TypeScript configuration..."
    
    cat > backend/tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "module": "commonjs",
    "declaration": true,
    "removeComments": true,
    "emitDecoratorMetadata": true,
    "experimentalDecorators": true,
    "allowSyntheticDefaultImports": true,
    "target": "es2022",
    "sourceMap": true,
    "outDir": "./dist",
    "baseUrl": "./",
    "incremental": true,
    "skipLibCheck": true,
    "strict": true,
    "strictNullChecks": true,
    "noImplicitAny": true,
    "strictBindCallApply": true,
    "forceConsistentCasingInFileNames": true,
    "noFallthroughCasesInSwitch": true,
    "paths": {
      "@/*": ["src/*"],
      "@core/*": ["src/core/*"],
      "@infrastructure/*": ["src/infrastructure/*"],
      "@application/*": ["src/application/*"],
      "@presentation/*": ["src/presentation/*"]
    }
  },
  "include": ["src/**/*", "prisma/**/*"],
  "exclude": ["node_modules", "dist"]
}
EOF
    log "INFO" "TypeScript configuration created successfully"
}

create_pnpm_config() {
    log "INFO" "Creating PNPM configuration..."
    
    cat > backend/.npmrc << 'EOF'
engine-strict=true
auto-install-peers=true
shamefully-hoist=true
strict-peer-dependencies=false
EOF
    log "INFO" "PNPM configuration created successfully"
}

create_prisma_seed() {
    log "INFO" "Creating Prisma seed file..."
    
    cat > backend/prisma/seed.ts << 'EOF'
import { PrismaClient } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
  // Create roles first
  const roles = await Promise.all([
    prisma.role.create({
      data: {
        name: 'admin',
        description: 'Full system access and control',
        permissions: ['all'],
      },
    }),
    prisma.role.create({
      data: {
        name: 'carrier',
        description: 'Fleet and transport management',
        permissions: [
          'read:orders',
          'read:shipments',
          'read:vehicles',
          'read:drivers',
          'read:rates',
          'write:assignments',
          'write:vehicles',
          'write:rates',
        ],
      },
    }),
    prisma.role.create({
      data: {
        name: 'client',
        description: 'Customer who creates and tracks orders',
        permissions: [
          'read:own_orders',
          'read:own_deliveries',
          'read:own_shipments',
          'create:orders',
        ],
      },
    }),
    prisma.role.create({
      data: {
        name: 'driver',
        description: 'Assigned driver for deliveries',
        permissions: [
          'read:assigned_orders',
          'read:assigned_deliveries',
          'read:assigned_routes',
          'update:delivery_status',
        ],
      },
    }),
  ]);

  // Create demo users for each role
  const saltRounds = 10;
  const defaultPassword = await bcrypt.hash('password123', saltRounds);

  await Promise.all([
    // Admin user
    prisma.user.create({
      data: {
        email: 'admin@tms.com',
        password: defaultPassword,
        firstName: 'System',
        lastName: 'Administrator',
        role: { connect: { name: 'admin' } },
        isActive: true,
      },
    }),
    // Carrier user
    prisma.user.create({
      data: {
        email: 'carrier@transport.com',
        password: defaultPassword,
        firstName: 'Carrier',
        lastName: 'Manager',
        role: { connect: { name: 'carrier' } },
        company: {
          create: {
            name: 'Fast Transport Co.',
            type: 'carrier',
            status: 'active',
          },
        },
        isActive: true,
      },
    }),
    // Client user
    prisma.user.create({
      data: {
        email: 'client@example.com',
        password: defaultPassword,
        firstName: 'Client',
        lastName: 'User',
        role: { connect: { name: 'client' } },
        company: {
          create: {
            name: 'Example Corp',
            type: 'client',
            status: 'active',
          },
        },
        isActive: true,
      },
    }),
    // Driver user
    prisma.user.create({
      data: {
        email: 'driver@transport.com',
        password: defaultPassword,
        firstName: 'Driver',
        lastName: 'One',
        role: { connect: { name: 'driver' } },
        isActive: true,
      },
    }),
  ]);

  console.log('Seed completed successfully');
}

main()
  .catch((e) => {
    console.error('Error during seeding:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
EOF
    log "INFO" "Prisma seed file created successfully"
}

install_development_dependencies() {
    log "INFO" "Installing development dependencies..."
    
    # Change to backend directory
    cd backend || exit 1
    
    # Install dependencies with pnpm
    log "INFO" "Installing project dependencies..."
    pnpm install
    
    # Install specific development dependencies needed for seed
    log "INFO" "Installing additional development dependencies..."
    pnpm add -D @types/bcrypt @types/node typescript ts-node @types/jest
    
    # Generate Prisma client
    log "INFO" "Generating Prisma client..."
    pnpm prisma generate
    
    # Return to previous directory
    cd - || exit 1
    
    log "INFO" "Development dependencies installed successfully"
}

create_directory_structure() {
    log "INFO" "Creating TMS project directory structure..."
    
    local directories=(
        ".github/workflows"
        "scripts"
        "backend/src/core/entities"
        "backend/src/core/repositories"
        "backend/src/core/services"
        "backend/src/infrastructure/database"
        "backend/src/infrastructure/repositories"
        "backend/src/infrastructure/external"
        "backend/src/application/dtos"
        "backend/src/application/services"
        "backend/src/application/use-cases"
        "backend/src/presentation/controllers"
        "backend/src/presentation/middlewares"
        "backend/src/presentation/guards"
        "backend/prisma/migrations"
        "backend/prisma/seeds"
        "backend/test/unit"
        "backend/test/integration"
        "backend/test/e2e"
        "mysql"
        "redis"
        "docs/api"
        "docs/architecture"
        "logs"
        "monitoring"
    )
    
    for dir in "${directories[@]}"; do
        if mkdir -p "$dir"; then
            log "DEBUG" "Created directory: $dir"
        else
            log "ERROR" "Failed to create directory: $dir"
            return 1
        fi
    done
    
    log "INFO" "Directory structure created successfully"
    return 0
}

create_essential_files() {
    log "INFO" "Creating essential project files..."
    
    local files=(
        ".gitignore:Git ignore rules"
        ".dockerignore:Docker ignore rules"
        "backend/README.md:Backend documentation"
        "backend/.nvmrc:Node version specification"
        "backend/tsconfig.json:TypeScript configuration"
        "backend/.npmrc:PNPM configuration"
        "README.md:Project documentation"
        "LICENSE:Project license"
        "docs/CONTRIBUTING.md:Contributing guidelines"
        "docs/DEPLOYMENT.md:Deployment guide"
        "monitoring/prometheus.yml:Monitoring configuration"
        "backend/prisma/seed.ts:Database seed file"
    )
    
    for file_info in "${files[@]}"; do
        local file="${file_info%:*}"
        local description="${file_info#*:}"
        
        if [[ ! -f "$file" ]]; then
            if touch "$file"; then
                log "DEBUG" "Created file: $file ($description)"
            else
                log "ERROR" "Failed to create file: $file"
                return 1
            fi
        else
            log "DEBUG" "File already exists: $file"
        fi
    done
    
    log "INFO" "Essential files created successfully"
    return 0
}

create_environment_files() {
    log "INFO" "Creating environment configuration files..."
    
    # Create .env file
    cat > .env << 'EOF'
# Environment Configuration
NODE_ENV=development
PORT=3000

# Database Configuration
DATABASE_URL="mysql://tms_user:tms_password@localhost:3306/tms_db"
DB_HOST=mysql
DB_PORT=3306
DB_USER=tms_user
DB_PASSWORD=tms_password
DB_NAME=tms_db

# Redis Configuration
REDIS_URL="redis://redis:6379"
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=redis_password

# JWT Configuration
JWT_SECRET=your-super-secret-jwt-key-change-in-production
JWT_EXPIRES_IN=15m
JWT_REFRESH_SECRET=your-super-secret-refresh-key-change-in-production
JWT_REFRESH_EXPIRES_IN=7d

# PayPal Configuration
PAYPAL_CLIENT_ID=your-paypal-client-id
PAYPAL_CLIENT_SECRET=your-paypal-client-secret
PAYPAL_MODE=sandbox

# Monitoring
PROMETHEUS_PORT=9090
GRAFANA_PORT=3001

# Backup Configuration
BACKUP_RETENTION_DAYS=7
BACKUP_SCHEDULE="0 2 * * *"
EOF

    # Create .env.example
    cp .env .env.example
    
    # Create .env.test
    cat > .env.test << 'EOF'
# Test Environment Configuration
NODE_ENV=test
PORT=3001

# Test Database Configuration
DATABASE_URL="mysql://tms_user:tms_password@localhost:3307/tms_test_db"
DB_HOST=localhost
DB_PORT=3307
DB_USER=tms_user
DB_PASSWORD=tms_password
DB_NAME=tms_test_db

# Test Redis Configuration
REDIS_URL="redis://localhost:6380"
REDIS_HOST=localhost
REDIS_PORT=6380
REDIS_PASSWORD=redis_password

# Test JWT Configuration
JWT_SECRET=test-jwt-secret-key
JWT_EXPIRES_IN=1h
JWT_REFRESH_SECRET=test-refresh-secret-key
JWT_REFRESH_EXPIRES_IN=1d
EOF

    # Create backend/.nvmrc
    echo "22" > backend/.nvmrc
    
    log "INFO" "Environment files created successfully"
}

create_mysql_configuration() {
    log "INFO" "Creating MySQL configuration files..."
    
    # Create mysql/init.sql
    cat > mysql/init.sql << 'EOF'
-- TMS Transportation Logistics System Database Initialization
-- MySQL 8.0

-- Create database
CREATE DATABASE IF NOT EXISTS tms_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS tms_test_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE tms_db;

-- Create users with specific roles
CREATE USER IF NOT EXISTS 'tms_user'@'%' IDENTIFIED BY 'tms_password';
CREATE USER IF NOT EXISTS 'tms_admin'@'%' IDENTIFIED BY 'tms_admin_password';
CREATE USER IF NOT EXISTS 'tms_carrier'@'%' IDENTIFIED BY 'tms_carrier_password';
CREATE USER IF NOT EXISTS 'tms_client'@'%' IDENTIFIED BY 'tms_client_password';
CREATE USER IF NOT EXISTS 'tms_driver'@'%' IDENTIFIED BY 'tms_driver_password';

-- Grant permissions based on roles

-- Admin: Total control over the database
GRANT ALL PRIVILEGES ON tms_db.* TO 'tms_admin'@'%';
GRANT ALL PRIVILEGES ON tms_test_db.* TO 'tms_admin'@'%';

-- Main application user: Full access for application operations
GRANT ALL PRIVILEGES ON tms_db.* TO 'tms_user'@'%';
GRANT ALL PRIVILEGES ON tms_test_db.* TO 'tms_user'@'%';

-- Carrier: Companies that manage fleets, transport and assignments
GRANT SELECT ON tms_db.orders TO 'tms_carrier'@'%';
GRANT SELECT ON tms_db.shipments TO 'tms_carrier'@'%';
GRANT SELECT ON tms_db.vehicles TO 'tms_carrier'@'%';
GRANT SELECT ON tms_db.drivers TO 'tms_carrier'@'%';
GRANT SELECT ON tms_db.rates TO 'tms_carrier'@'%';
GRANT INSERT, UPDATE ON tms_db.assignments TO 'tms_carrier'@'%';
GRANT INSERT, UPDATE ON tms_db.vehicles TO 'tms_carrier'@'%';
GRANT INSERT, UPDATE ON tms_db.rates TO 'tms_carrier'@'%';

-- Client: Customer who creates orders and tracks their shipments
GRANT SELECT ON tms_db.orders TO 'tms_client'@'%';
GRANT SELECT ON tms_db.deliveries TO 'tms_client'@'%';
GRANT SELECT ON tms_db.shipments TO 'tms_client'@'%';
GRANT INSERT ON tms_db.orders TO 'tms_client'@'%';

-- Driver: Driver assigned to routes or vehicles
GRANT SELECT ON tms_db.orders TO 'tms_driver'@'%';
GRANT SELECT ON tms_db.deliveries TO 'tms_driver'@'%';
GRANT SELECT ON tms_db.routes TO 'tms_driver'@'%';
GRANT UPDATE ON tms_db.deliveries TO 'tms_driver'@'%';

-- Flush privileges
FLUSH PRIVILEGES;

-- Basic table structure (will be managed by Prisma migrations)
-- These are just examples for initial setup

CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role ENUM('admin', 'carrier', 'client', 'driver') NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS companies (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    type ENUM('carrier', 'client') NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert initial admin user (password should be hashed in real application)
INSERT IGNORE INTO users (email, password, role) VALUES 
('admin@tms.com', '$2b$10$example_hashed_password', 'admin');

-- Log initialization
INSERT INTO information_schema.processlist (db, command, info) 
VALUES ('tms_db', 'Init', 'TMS Database initialized successfully') 
ON DUPLICATE KEY UPDATE info = 'TMS Database re-initialized';

SELECT 'TMS Database initialization completed successfully' AS status;
EOF

    # Create mysql/my.cnf (basic configuration)
    cat > mysql/my.cnf << 'EOF'
[mysqld]
# Basic MySQL 8.0 configuration for TMS
default-authentication-plugin=mysql_native_password
character-set-server=utf8mb4
collation-server=utf8mb4_unicode_ci

# Performance optimizations
innodb_buffer_pool_size=256M
max_connections=200
query_cache_type=1
query_cache_size=64M

# Logging
slow_query_log=1
slow_query_log_file=/var/log/mysql/slow.log
long_query_time=2

[client]
default-character-set=utf8mb4
EOF

    log "INFO" "MySQL configuration created successfully"
}

create_redis_configuration() {
    log "INFO" "Creating Redis configuration..."
    
    cat > redis/redis.conf << 'EOF'
# Redis configuration for TMS Transportation Logistics System
# Version: 7-alpine

# Network
bind 0.0.0.0
port 6379
protected-mode yes

# Authentication
requirepass redis_password

# General
daemonize no
databases 16
timeout 300
tcp-keepalive 300

# Memory management
maxmemory 256mb
maxmemory-policy allkeys-lru

# Persistence for sessions and cache
save 900 1
save 300 10
save 60 10000

# Security
rename-command FLUSHDB ""
rename-command FLUSHALL ""
rename-command DEBUG ""

# Logging
loglevel notice
logfile ""

# Session management
# Database 0: Sessions
# Database 1: Cache
# Database 2: Queues (Bull)

# Enable keyspace notifications for cache invalidation
notify-keyspace-events Ex
EOF

    log "INFO" "Redis configuration created successfully"
}

create_docker_files() {
    log "INFO" "Creating Docker configuration files..."
    
    # Create backend/Dockerfile (Development)
    cat > backend/Dockerfile << 'EOF'
# TMS Backend Dockerfile - Development
FROM node:22-alpine

# Set working directory
WORKDIR /app

# Create app user for security
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nestjs -u 1001

# Install dependencies for native modules
RUN apk add --no-cache libc6-compat python3 make g++

# Copy package files
COPY package*.json ./
COPY pnpm-lock.yaml ./

# Install pnpm and dependencies
RUN npm install -g pnpm
RUN pnpm install

# Copy source code
COPY . .

# Change ownership
RUN chown -R nestjs:nodejs /app

# Switch to non-root user
USER nestjs

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

# Start development server
CMD ["pnpm", "start:dev"]
EOF

    # Create backend/Dockerfile.prod (Production)
    cat > backend/Dockerfile.prod << 'EOF'
# TMS Backend Dockerfile - Production
FROM node:22-alpine AS builder

# Set working directory
WORKDIR /app

# Install dependencies for native modules
RUN apk add --no-cache libc6-compat python3 make g++

# Copy package files
COPY package*.json ./
COPY pnpm-lock.yaml ./

# Install pnpm
RUN npm install -g pnpm

# Install dependencies
RUN pnpm install --frozen-lockfile

# Copy source code
COPY . .

# Generate Prisma client
RUN npx prisma generate

# Build the application
RUN pnpm build

# Production stage
FROM node:22-alpine AS runner

# Set working directory
WORKDIR /app

# Create app user for security
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nestjs -u 1001

# Install curl for health checks
RUN apk add --no-cache curl

# Copy package files
COPY package*.json ./
COPY pnpm-lock.yaml ./

# Install pnpm and production dependencies only
RUN npm install -g pnpm
RUN pnpm install --frozen-lockfile --prod

# Copy built application
COPY --from=builder --chown=nestjs:nodejs /app/dist ./dist
COPY --from=builder --chown=nestjs:nodejs /app/prisma ./prisma

# Generate Prisma client
RUN npx prisma generate

# Switch to non-root user
USER nestjs

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

# Start production server
CMD ["node", "dist/main"]
EOF

    # Create docker-compose.yml (Development)
    cat > docker-compose.yml << 'EOF'
# TMS Transportation Logistics System - Development Environment

services:
  # Backend Service
  backend:
    build: 
      context: ./backend
      dockerfile: Dockerfile
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=development
      - DATABASE_URL=mysql://tms_user:tms_password@mysql:3306/tms_db
      - REDIS_URL=redis://redis:6379
    volumes:
      - ./backend:/app
      - /app/node_modules
      - ./logs:/app/logs
    depends_on:
      - mysql
      - redis
    networks:
      - tms-network
    restart: unless-stopped

  # MySQL Database
  mysql:
    image: mysql:8.0
    ports:
      - "3306:3306"
    environment:
      MYSQL_ROOT_PASSWORD: root_password
      MYSQL_DATABASE: tms_db
      MYSQL_USER: tms_user
      MYSQL_PASSWORD: tms_password
    volumes:
      - mysql_data:/var/lib/mysql
      - ./mysql/init.sql:/docker-entrypoint-initdb.d/init.sql
      - ./mysql/my.cnf:/etc/mysql/conf.d/custom.cnf
      - ./logs/mysql:/var/log/mysql
    networks:
      - tms-network
    restart: unless-stopped

  # Redis Cache and Sessions
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
      - ./redis/redis.conf:/usr/local/etc/redis/redis.conf
    command: redis-server /usr/local/etc/redis/redis.conf
    networks:
      - tms-network
    restart: unless-stopped

  # Monitoring - Prometheus
  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./monitoring/prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
    networks:
      - tms-network
    restart: unless-stopped

  # Monitoring - Grafana
  grafana:
    image: grafana/grafana:latest
    ports:
      - "3001:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    volumes:
      - grafana_data:/var/lib/grafana
    networks:
      - tms-network
    restart: unless-stopped

networks:
  tms-network:
    driver: bridge

volumes:
  mysql_data:
  redis_data:
  prometheus_data:
  grafana_data:
EOF

    # Create docker-compose.prod.yml (Production)
    cat > docker-compose.prod.yml << 'EOF'
# TMS Transportation Logistics System - Production Environment

services:
  # Backend Service
  backend:
    build: 
      context: ./backend
      dockerfile: Dockerfile.prod
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - DATABASE_URL=mysql://tms_user:tms_password@mysql:3306/tms_db
      - REDIS_URL=redis://redis:6379
    volumes:
      - ./logs:/app/logs
    depends_on:
      - mysql
      - redis
    networks:
      - tms-network
    restart: always
    deploy:
      resources:
        limits:
          memory: 512M
        reservations:
          memory: 256M

  # MySQL Database
  mysql:
    image: mysql:8.0
    ports:
      - "3306:3306"
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: tms_db
      MYSQL_USER: tms_user
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}
    volumes:
      - mysql_data:/var/lib/mysql
      - ./mysql/init.sql:/docker-entrypoint-initdb.d/init.sql
      - ./mysql/my.cnf:/etc/mysql/conf.d/custom.cnf
      - ./logs/mysql:/var/log/mysql
    networks:
      - tms-network
    restart: always
    deploy:
      resources:
        limits:
          memory: 1G
        reservations:
          memory: 512M

  # Redis Cache and Sessions
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
      - ./redis/redis.conf:/usr/local/etc/redis/redis.conf
    command: redis-server /usr/local/etc/redis/redis.conf
    networks:
      - tms-network
    restart: always
    deploy:
      resources:
        limits:
          memory: 256M
        reservations:
          memory: 128M

  # Load Balancer (Nginx)
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf
      - ./nginx/ssl:/etc/nginx/ssl
    depends_on:
      - backend
    networks:
      - tms-network
    restart: always

networks:
  tms-network:
    driver: bridge

volumes:
  mysql_data:
  redis_data:
EOF

    # Create docker-compose.test.yml (Testing)
    cat > docker-compose.test.yml << 'EOF'
# TMS Transportation Logistics System - Test Environment

services:
  # Test Database
  mysql-test:
    image: mysql:8.0
    ports:
      - "3307:3306"
    environment:
      MYSQL_ROOT_PASSWORD: root_password
      MYSQL_DATABASE: tms_test_db
      MYSQL_USER: tms_user
      MYSQL_PASSWORD: tms_password
    volumes:
      - ./mysql/init.sql:/docker-entrypoint-initdb.d/init.sql
    networks:
      - tms-test-network
    restart: "no"

  # Test Redis
  redis-test:
    image: redis:7-alpine
    ports:
      - "6380:6379"
    command: redis-server --requirepass redis_password
    networks:
      - tms-test-network
    restart: "no"

networks:
  tms-test-network:
    driver: bridge
EOF

    log "INFO" "Docker configuration files created successfully"
}

create_github_workflows() {
    log "INFO" "Creating GitHub Actions workflows..."
    
    # Create CI workflow
    cat > .github/workflows/ci.yml << 'EOF'
name: TMS CI Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  test:
    runs-on: ubuntu-latest
    
    services:
      mysql:
        image: mysql:8.0
        env:
          MYSQL_ROOT_PASSWORD: root_password
          MYSQL_DATABASE: tms_test_db
          MYSQL_USER: tms_user
          MYSQL_PASSWORD: tms_password
        ports:
          - 3307:3306
        options: >-
          --health-cmd="mysqladmin ping"
          --health-interval=10s
          --health-timeout=5s
          --health-retries=3
      
      redis:
        image: redis:7-alpine
        ports:
          - 6380:6379
        options: >-
          --health-cmd="redis-cli ping"
          --health-interval=10s
          --health-timeout=5s
          --health-retries=3

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Node.js 22
        uses: actions/setup-node@v4
        with:
          node-version: '22'
          cache: 'npm'

      - name: Install pnpm
        run: npm install -g pnpm

      - name: Install dependencies
        run: |
          cd backend
          pnpm install --frozen-lockfile

      - name: Run linting
        run: |
          cd backend
          pnpm run lint

      - name: Run unit tests
        run: |
          cd backend
          pnpm run test
        env:
          DATABASE_URL: mysql://tms_user:tms_password@localhost:3307/tms_test_db
          REDIS_URL: redis://localhost:6380

      - name: Run e2e tests
        run: |
          cd backend
          pnpm run test:e2e
        env:
          DATABASE_URL: mysql://tms_user:tms_password@localhost:3307/tms_test_db
          REDIS_URL: redis://localhost:6380

      - name: Generate test coverage
        run: |
          cd backend
          pnpm run test:cov

      - name: Upload coverage reports
        uses: codecov/codecov-action@v3
        with:
          file: ./backend/coverage/lcov.info
EOF

    # Create deployment workflow
    cat > .github/workflows/deploy.yml << 'EOF'
name: TMS Deployment Pipeline

on:
  push:
    branches: [ main ]
  workflow_dispatch:

jobs:
  deploy:
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Node.js 22
        uses: actions/setup-node@v4
        with:
          node-version: '22'

      - name: Install pnpm
        run: npm install -g pnpm

      - name: Build application
        run: |
          cd backend
          pnpm install --frozen-lockfile
          pnpm run build

      - name: Run tests before deployment
        run: |
          cd backend
          pnpm run test

      - name: Deploy to production
        run: |
          # Deploy to on-premise server
          ./scripts/deploy.sh production
        env:
          DEPLOY_HOST: ${{ secrets.DEPLOY_HOST }}
          DEPLOY_USER: ${{ secrets.DEPLOY_USER }}
          DEPLOY_KEY: ${{ secrets.DEPLOY_KEY }}

  pr-checks:
    name: PR Quality Checks
    runs-on: ubuntu-latest
    if: github.event_name == 'pull_request'
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Node.js 22
        uses: actions/setup-node@v4
        with:
          node-version: '22'

      - name: Install pnpm
        run: npm install -g pnpm

      - name: Install dependencies
        run: |
          cd backend
          pnpm install --frozen-lockfile

      - name: Check code formatting
        run: |
          cd backend
          pnpm run format:check

      - name: Run security audit
        run: |
          cd backend
          pnpm audit --audit-level moderate

      - name: Check for vulnerabilities
        run: |
          cd backend
          pnpm run security:check
EOF

    log "INFO" "GitHub Actions workflows created successfully"
}

create_scripts() {
    log "INFO" "Creating project scripts..."
    
    # Create scripts/setup.sh (self-replication)
    cat > scripts/setup.sh << 'SCRIPT_EOF'
#!/bin/bash

# ==========================================================
# TMS Transportation Logistics System - Advanced Setup Script
# Description: Complete setup script with error handling,
# validation, and multi-purpose functionality for TMS project
# Version: 2.0
# ==========================================================

# This script is auto-generated by the main setup script
# Run this script to set up the TMS project from scratch

echo "==> TMS Transportation Logistics System Setup"
echo "    Version: 2.0"
echo "    Node.js Required: 22.x"
echo "    Database: MySQL 8.0"
echo "    Cache: Redis 7-alpine"
echo ""

# Change to project root
cd "$(dirname "$0")/.."

# Run the main setup
if [[ -f "setup.sh" ]]; then
    ./setup.sh "$@"
else
    echo "Error: Main setup script not found"
    exit 1
fi
SCRIPT_EOF

    # Create scripts/deploy.sh
    cat > scripts/deploy.sh << 'SCRIPT_EOF'
#!/bin/bash

# ==========================================================
# TMS Deployment Script
# Description: Deploy TMS application to production
# ==========================================================

set -euo pipefail

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
readonly DEPLOY_LOG="$PROJECT_ROOT/logs/deploy.log"

# Colors
readonly GREEN='\033[0;32m'
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        "INFO")  echo -e "${GREEN}[DEPLOY-INFO]${NC} $message" ;;
        "WARN")  echo -e "${YELLOW}[DEPLOY-WARN]${NC} $message" ;;
        "ERROR") echo -e "${RED}[DEPLOY-ERROR]${NC} $message" ;;
    esac
    
    echo "[$timestamp][$level] $message" >> "$DEPLOY_LOG"
}

deploy_production() {
    log "INFO" "Starting production deployment..."
    
    # Pre-deployment checks
    log "INFO" "Running pre-deployment checks..."
    
    # Check if Docker is running
    if ! docker info &> /dev/null; then
        log "ERROR" "Docker is not running"
        return 1
    fi
    
    # Check environment variables
    if [[ -z "${DEPLOY_HOST:-}" ]] || [[ -z "${DEPLOY_USER:-}" ]]; then
        log "ERROR" "Missing deployment environment variables"
        return 1
    fi
    
    # Build and test
    log "INFO" "Building application..."
    cd "$PROJECT_ROOT/backend"
    
    if ! pnpm install --frozen-lockfile; then
        log "ERROR" "Failed to install dependencies"
        return 1
    fi
    
    if ! pnpm run build; then
        log "ERROR" "Failed to build application"
        return 1
    fi
    
    if ! pnpm run test; then
        log "ERROR" "Tests failed, aborting deployment"
        return 1
    fi
    
    # Database migration
    log "INFO" "Running database migrations..."
    if ! npx prisma migrate deploy; then
        log "ERROR" "Database migration failed"
        return 1
    fi
    
    # Docker deployment
    log "INFO" "Deploying Docker containers..."
    cd "$PROJECT_ROOT"
    
    # Stop existing containers
    docker-compose -f docker-compose.prod.yml down
    
    # Start new containers
    if ! docker-compose -f docker-compose.prod.yml up -d --build; then
        log "ERROR" "Failed to start production containers"
        return 1
    fi
    
    # Health check
    log "INFO" "Performing health checks..."
    sleep 30
    
    if ! curl -f http://localhost:3000/health &> /dev/null; then
        log "ERROR" "Health check failed"
        return 1
    fi
    
    log "INFO" "Production deployment completed successfully!"
}

deploy_staging() {
    log "INFO" "Starting staging deployment..."
    
    cd "$PROJECT_ROOT"
    
    # Use development compose with staging overrides
    docker-compose -f docker-compose.yml down
    docker-compose -f docker-compose.yml up -d --build
    
    log "INFO" "Staging deployment completed!"
}

rollback() {
    log "INFO" "Rolling back to previous version..."
    
    cd "$PROJECT_ROOT"
    
    # Stop current containers
    docker-compose -f docker-compose.prod.yml down
    
    # Restore from backup (implement based on your backup strategy)
    if [[ -f "backups/last_working_version.tar.gz" ]]; then
        log "INFO" "Restoring from backup..."
        tar -xzf "backups/last_working_version.tar.gz"
        docker-compose -f docker-compose.prod.yml up -d
    else
        log "ERROR" "No backup found for rollback"
        return 1
    fi
    
    log "INFO" "Rollback completed!"
}

show_help() {
    cat << EOF
TMS Deployment Script

Usage: ./deploy.sh [OPTION]

Options:
  production    Deploy to production environment
  staging       Deploy to staging environment
  rollback      Rollback to previous version
  -h, --help    Show this help

Examples:
  ./deploy.sh production
  ./deploy.sh staging
  ./deploy.sh rollback
EOF
}

# Main execution
main() {
    mkdir -p "$(dirname "$DEPLOY_LOG")"
    
    case "${1:-}" in
        "production")
            deploy_production
            ;;
        "staging")
            deploy_staging
            ;;
        "rollback")
            rollback
            ;;
        "-h"|"--help")
            show_help
            ;;
        *)
            log "ERROR" "Invalid option: ${1:-}"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
SCRIPT_EOF

    # Create scripts/backup.sh
    cat > scripts/backup.sh << 'SCRIPT_EOF'
#!/bin/bash

# ==========================================================
# TMS Backup Script
# Description: Backup TMS database and application data
# ==========================================================

set -euo pipefail

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
readonly BACKUP_DIR="$PROJECT_ROOT/backups"
readonly BACKUP_LOG="$PROJECT_ROOT/logs/backup.log"
readonly RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-7}"

# Colors
readonly GREEN='\033[0;32m'
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        "INFO")  echo -e "${GREEN}[BACKUP-INFO]${NC} $message" ;;
        "WARN")  echo -e "${YELLOW}[BACKUP-WARN]${NC} $message" ;;
        "ERROR") echo -e "${RED}[BACKUP-ERROR]${NC} $message" ;;
    esac
    
    echo "[$timestamp][$level] $message" >> "$BACKUP_LOG"
}

backup_database() {
    local backup_name="mysql_backup_$(date +%Y%m%d_%H%M%S).sql"
    local backup_path="$BACKUP_DIR/database/$backup_name"
    
    log "INFO" "Starting database backup..."
    
    mkdir -p "$(dirname "$backup_path")"
    
    # Backup using Docker exec
    if docker-compose ps mysql | grep -q "Up"; then
        if docker-compose exec -T mysql mysqldump \
            --user=tms_user \
            --password=tms_password \
            --single-transaction \
            --routines \
            --triggers \
            tms_db > "$backup_path"; then
            
            # Compress backup
            gzip "$backup_path"
            log "INFO" "Database backup completed: ${backup_path}.gz"
        else
            log "ERROR" "Database backup failed"
            return 1
        fi
    else
        log "ERROR" "MySQL container is not running"
        return 1
    fi
}

backup_redis() {
    local backup_name="redis_backup_$(date +%Y%m%d_%H%M%S).rdb"
    local backup_path="$BACKUP_DIR/redis/$backup_name"
    
    log "INFO" "Starting Redis backup..."
    
    mkdir -p "$(dirname "$backup_path")"
    
    # Backup Redis data
    if docker-compose ps redis | grep -q "Up"; then
        if docker-compose exec -T redis redis-cli --rdb /tmp/dump.rdb && \
           docker cp "$(docker-compose ps -q redis):/tmp/dump.rdb" "$backup_path"; then
            
            gzip "$backup_path"
            log "INFO" "Redis backup completed: ${backup_path}.gz"
        else
            log "ERROR" "Redis backup failed"
            return 1
        fi
    else
        log "ERROR" "Redis container is not running"
        return 1
    fi
}

backup_application() {
    local backup_name="app_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
    local backup_path="$BACKUP_DIR/application/$backup_name"
    
    log "INFO" "Starting application backup..."
    
    mkdir -p "$(dirname "$backup_path")"
    
    # Backup application files
    tar -czf "$backup_path" \
        --exclude='node_modules' \
        --exclude='dist' \
        --exclude='logs' \
        --exclude='backups' \
        --exclude='.git' \
        -C "$PROJECT_ROOT" .
    
    if [[ -f "$backup_path" ]]; then
        log "INFO" "Application backup completed: $backup_path"
    else
        log "ERROR" "Application backup failed"
        return 1
    fi
}

cleanup_old_backups() {
    log "INFO" "Cleaning up old backups (retention: $RETENTION_DAYS days)..."
    
    find "$BACKUP_DIR" -name "*.gz" -type f -mtime +$RETENTION_DAYS -delete
    find "$BACKUP_DIR" -name "*.tar.gz" -type f -mtime +$RETENTION_DAYS -delete
    find "$BACKUP_DIR" -name "*.sql" -type f -mtime +$RETENTION_DAYS -delete
    
    log "INFO" "Old backups cleaned up"
}

restore_database() {
    local backup_file="$1"
    
    if [[ ! -f "$backup_file" ]]; then
        log "ERROR" "Backup file not found: $backup_file"
        return 1
    fi
    
    log "INFO" "Restoring database from: $backup_file"
    
    # Decompress if needed
    if [[ "$backup_file" == *.gz ]]; then
        local temp_file="/tmp/restore_$(basename "$backup_file" .gz)"
        gunzip -c "$backup_file" > "$temp_file"
        backup_file="$temp_file"
    fi
    
    # Restore database
    if docker-compose exec -T mysql mysql \
        --user=tms_user \
        --password=tms_password \
        tms_db < "$backup_file"; then
        
        log "INFO" "Database restore completed successfully"
        [[ -f "$temp_file" ]] && rm -f "$temp_file"
    else
        log "ERROR" "Database restore failed"
        [[ -f "$temp_file" ]] && rm -f "$temp_file"
        return 1
    fi
}

full_backup() {
    log "INFO" "Starting full TMS backup..."
    
    mkdir -p "$BACKUP_DIR"/{database,redis,application}
    
    backup_database
    backup_redis
    backup_application
    cleanup_old_backups
    
    log "INFO" "Full backup completed successfully!"
}

show_help() {
    cat << EOF
TMS Backup Script

Usage: ./backup.sh [OPTION] [FILE]

Options:
  full                    Perform full backup (database + redis + application)
  database               Backup database only
  redis                  Backup Redis only  
  application            Backup application files only
  restore-db FILE        Restore database from backup file
  cleanup                Clean up old backups
  -h, --help             Show this help

Examples:
  ./backup.sh full
  ./backup.sh database
  ./backup.sh restore-db backups/database/mysql_backup_20231215_120000.sql.gz
EOF
}

# Main execution
main() {
    mkdir -p "$(dirname "$BACKUP_LOG")"
    
    case "${1:-}" in
        "full")
            full_backup
            ;;
        "database")
            backup_database
            ;;
        "redis")
            backup_redis
            ;;
        "application")
            backup_application
            ;;
        "restore-db")
            if [[ -z "${2:-}" ]]; then
                log "ERROR" "Please specify backup file to restore"
                exit 1
            fi
            restore_database "$2"
            ;;
        "cleanup")
            cleanup_old_backups
            ;;
        "-h"|"--help")
            show_help
            ;;
        *)
            log "ERROR" "Invalid option: ${1:-}"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
SCRIPT_EOF

    # Create scripts/test.sh
    cat > scripts/test.sh << 'SCRIPT_EOF'
#!/bin/bash

# ==========================================================
# TMS Testing Script
# Description: Run various types of tests for TMS project
# ==========================================================

set -euo pipefail

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
readonly TEST_LOG="$PROJECT_ROOT/logs/test.log"

# Colors
readonly GREEN='\033[0;32m'
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        "INFO")  echo -e "${GREEN}[TEST-INFO]${NC} $message" ;;
        "WARN")  echo -e "${YELLOW}[TEST-WARN]${NC} $message" ;;
        "ERROR") echo -e "${RED}[TEST-ERROR]${NC} $message" ;;
    esac
    
    echo "[$timestamp][$level] $message" >> "$TEST_LOG"
}

setup_test_environment() {
    log "INFO" "Setting up test environment..."
    
    cd "$PROJECT_ROOT"
    
    # Start test containers
    docker-compose -f docker-compose.test.yml up -d
    
    # Wait for services to be ready
    sleep 10
    
    # Run database migrations for test
    cd backend
    DATABASE_URL="mysql://tms_user:tms_password@localhost:3307/tms_test_db" \
        npx prisma migrate deploy
    
    log "INFO" "Test environment ready"
}

cleanup_test_environment() {
    log "INFO" "Cleaning up test environment..."
    
    cd "$PROJECT_ROOT"
    docker-compose -f docker-compose.test.yml down -v
    
    log "INFO" "Test environment cleaned up"
}

run_unit_tests() {
    log "INFO" "Running unit tests..."
    
    cd "$PROJECT_ROOT/backend"
    
    if pnpm run test; then
        log "INFO" "Unit tests passed"
    else
        log "ERROR" "Unit tests failed"
        return 1
    fi
}

run_integration_tests() {
    log "INFO" "Running integration tests..."
    
    cd "$PROJECT_ROOT/backend"
    
    if pnpm run test:integration; then
        log "INFO" "Integration tests passed"
    else
        log "ERROR" "Integration tests failed"
        return 1
    fi
}

run_e2e_tests() {
    log "INFO" "Running end-to-end tests..."
    
    cd "$PROJECT_ROOT/backend"
    
    if pnpm run test:e2e; then
        log "INFO" "E2E tests passed"
    else
        log "ERROR" "E2E tests failed"
        return 1
    fi
}

run_performance_tests() {
    log "INFO" "Running performance tests..."
    
    cd "$PROJECT_ROOT/backend"
    
    if pnpm run test:performance; then
        log "INFO" "Performance tests passed"
    else
        log "ERROR" "Performance tests failed"
        return 1
    fi
}

run_security_tests() {
    log "INFO" "Running security tests..."
    
    cd "$PROJECT_ROOT/backend"
    
    # Run security audit
    if pnpm audit --audit-level moderate; then
        log "INFO" "Security audit passed"
    else
        log "WARN" "Security audit found issues"
    fi
    
    # Run additional security checks if available
    if command -v npm-check-security &> /dev/null; then
        if npm-check-security; then
            log "INFO" "Security checks passed"
        else
            log "ERROR" "Security checks failed"
            return 1
        fi
    fi
}

generate_coverage_report() {
    log "INFO" "Generating test coverage report..."
    
    cd "$PROJECT_ROOT/backend"
    
    if pnpm run test:cov; then
        log "INFO" "Coverage report generated at backend/coverage/"
    else
        log "ERROR" "Failed to generate coverage report"
        return 1
    fi
}

run_all_tests() {
    log "INFO" "Running complete test suite..."
    
    setup_test_environment
    
    local failed=0
    
    run_unit_tests || failed=1
    run_integration_tests || failed=1
    run_e2e_tests || failed=1
    run_security_tests || failed=1
    generate_coverage_report || failed=1
    
    cleanup_test_environment
    
    if [[ $failed -eq 0 ]]; then
        log "INFO" "All tests completed successfully!"
    else
        log "ERROR" "Some tests failed"
        return 1
    fi
}

show_help() {
    cat << EOF
TMS Testing Script

Usage: ./test.sh [OPTION]

Options:
  all           Run all tests
  unit          Run unit tests only
  integration   Run integration tests only
  e2e           Run end-to-end tests only
  performance   Run performance tests only
  security      Run security tests only
  coverage      Generate coverage report only
  setup         Setup test environment only
  cleanup       Cleanup test environment only
  -h, --help    Show this help

Examples:
  ./test.sh all
  ./test.sh unit
  ./test.sh security
EOF
}

# Main execution
main() {
    mkdir -p "$(dirname "$TEST_LOG")"
    
    case "${1:-}" in
        "all")
            run_all_tests
            ;;
        "unit")
            setup_test_environment
            run_unit_tests
            cleanup_test_environment
            ;;
        "integration")
            setup_test_environment
            run_integration_tests
            cleanup_test_environment
            ;;
        "e2e")
            setup_test_environment
            run_e2e_tests
            cleanup_test_environment
            ;;
        "performance")
            setup_test_environment
            run_performance_tests
            cleanup_test_environment
            ;;
        "security")
            run_security_tests
            ;;
        "coverage")
            setup_test_environment
            generate_coverage_report
            cleanup_test_environment
            ;;
        "setup")
            setup_test_environment
            ;;
        "cleanup")
            cleanup_test_environment
            ;;
        "-h"|"--help")
            show_help
            ;;
        *)
            log "ERROR" "Invalid option: ${1:-}"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
SCRIPT_EOF

    # Make all scripts executable
    chmod +x scripts/*.sh
    
    log "INFO" "Project scripts created successfully"
}

setup_package_json() {
    log "INFO" "Setting up package.json and dependencies..."
    
    cd backend || {
        log "ERROR" "Cannot change to backend directory"
        return 1
    }
    
    # Initialize package.json with custom configuration
    if ! pnpm init; then
        log "ERROR" "Failed to initialize package.json"
        return 1
    fi
    
    # Update package.json with project-specific configuration
    cat > package.json << 'EOF'
{
  "name": "tms-backend",
  "version": "1.0.0",
  "description": "TMS Transportation Logistics System Backend",
  "main": "dist/main.js",
  "packageManager": "pnpm@10.14.0",
  "scripts": {
    "build": "nest build",
    "format": "prettier --write \"src/**/*.ts\" \"test/**/*.ts\"",
    "format:check": "prettier --check \"src/**/*.ts\" \"test/**/*.ts\"",
    "start": "nest start",
    "start:dev": "nest start --watch",
    "start:debug": "nest start --debug --watch",
    "start:prod": "node dist/main",
    "lint": "eslint \"{src,apps,libs,test}/**/*.ts\" --fix",
    "lint:check": "eslint \"{src,apps,libs,test}/**/*.ts\"",
    "test": "jest",
    "test:watch": "jest --watch",
    "test:cov": "jest --coverage",
    "test:debug": "node --inspect-brk -r tsconfig-paths/register -r ts-node/register node_modules/.bin/jest --runInBand",
    "test:e2e": "jest --config ./test/jest-e2e.json",
    "test:integration": "jest --config ./test/jest-integration.json",
    "test:performance": "jest --config ./test/jest-performance.json",
    "security:check": "npm audit --audit-level moderate",
    "db:migrate": "prisma migrate dev",
    "db:migrate:deploy": "prisma migrate deploy",
    "db:generate": "prisma generate",
    "db:seed": "ts-node prisma/seed.ts",
    "db:studio": "prisma studio",
    "db:reset": "prisma migrate reset"
  },
  "dependencies": {},
  "devDependencies": {},
  "jest": {
    "moduleFileExtensions": [
      "js",
      "json",
      "ts"
    ],
    "rootDir": "src",
    "testRegex": ".*\\.spec\\.ts$",
    "transform": {
      "^.+\\.(t|j)s$": "ts-jest"
    },
    "collectCoverageFrom": [
      "**/*.(t|j)s"
    ],
    "coverageDirectory": "../coverage",
    "testEnvironment": "node"
  }
}
EOF
    
    # Install dependencies with error handling
    local dependency_groups=(
        "@nestjs/cli:CLI tools"
        "@nestjs/core @nestjs/common @nestjs/platform-express reflect-metadata rxjs class-validator class-transformer:Core dependencies"
        "prisma @prisma/client:Database ORM"
        "@nestjs/swagger swagger-ui-express:API documentation"
        "@nestjs/bull bull ioredis:Queue and caching"
        "@nestjs/jwt passport-jwt passport bcryptjs:Authentication"
        "@nestjs/config @nestjs/throttler helmet:Security and configuration"
    )
    
    for dep_group in "${dependency_groups[@]}"; do
        local packages="${dep_group%:*}"
        local description="${dep_group#*:}"
        
        log "INFO" "Installing $description..."
        
        if ! pnpm add $packages; then
            log "ERROR" "Failed to install: $packages"
            return 1
        fi
        
        log "DEBUG" "Successfully installed: $packages"
    done
    
    # Install dev dependencies
    local dev_dependencies="@nestjs/testing jest ts-jest supertest @types/node @types/express @types/jest @types/supertest @types/bcryptjs @typescript-eslint/eslint-plugin @typescript-eslint/parser eslint prettier"
    
    log "INFO" "Installing development dependencies..."
    if ! pnpm add --save-dev $dev_dependencies; then
        log "ERROR" "Failed to install development dependencies"
        return 1
    fi
    
    cd .. || {
        log "ERROR" "Cannot return to project root"
        return 1
    }
    
    log "INFO" "Package.json and dependencies set up successfully"
    return 0
}

create_nestjs_structure() {
    log "INFO" "Creating NestJS application structure..."
    
    local backend_src="backend/src"
    
    # Create app.module.ts with proper structure
    cat > "$backend_src/app.module.ts" << 'EOF'
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ThrottlerModule } from '@nestjs/throttler';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: ['.env.local', '.env'],
    }),
    ThrottlerModule.forRoot({
      throttlers: [
        {
          ttl: 60000,
          limit: 10,
        },
      ],
    }),
  ],
  controllers: [],
  providers: [],
})
export class AppModule {}
EOF

    # Create main.ts with proper configuration
    cat > "$backend_src/main.ts" << 'EOF'
import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import helmet from 'helmet';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  
  // Security
  app.use(helmet());
  app.enableCors();
  
  // Validation
  app.useGlobalPipes(new ValidationPipe({
    whitelist: true,
    forbidNonWhitelisted: true,
    transform: true,
  }));
  
  // Swagger documentation
  const config = new DocumentBuilder()
    .setTitle('TMS API')
    .setDescription('Transportation Management System API')
    .setVersion('1.0')
    .addBearerAuth()
    .build();
  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api/docs', app, document);
  
  // Health check endpoint
  app.use('/health', (req, res) => {
    res.status(200).json({
      status: 'OK',
      timestamp: new Date().toISOString(),
      service: 'TMS Backend'
    });
  });
  
  const port = process.env.PORT || 3000;
  await app.listen(port);
  console.log(`🚀 TMS Application is running on: http://localhost:${port}`);
  console.log(`📖 API Documentation: http://localhost:${port}/api/docs`);
}

bootstrap();
EOF

    # Create basic Prisma schema
    cat > backend/prisma/schema.prisma << 'EOF'
// TMS Transportation Logistics System - Database Schema
// This is your Prisma schema file for MySQL 8.0

generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "mysql"
  url      = env("DATABASE_URL")
}

// User roles enum
enum UserRole {
  ADMIN
  CARRIER
  CLIENT  
  DRIVER
}

// Base User model
model User {
  id        Int      @id @default(autoincrement())
  email     String   @unique
  password  String
  role      UserRole
  firstName String?  @map("first_name")
  lastName  String?  @map("last_name")
  phone     String?
  isActive  Boolean  @default(true) @map("is_active")
  createdAt DateTime @default(now()) @map("created_at")
  updatedAt DateTime @updatedAt @map("updated_at")

  // Relations will be added as the project develops
  @@map("users")
}

// Company model for carriers and clients
model Company {
  id          Int         @id @default(autoincrement())
  name        String
  type        CompanyType
  email       String?
  phone       String?
  address     String?
  city        String?
  state       String?
  zipCode     String?     @map("zip_code")
  country     String      @default("CO")
  taxId       String?     @map("tax_id")
  isActive    Boolean     @default(true) @map("is_active")
  createdAt   DateTime    @default(now()) @map("created_at")
  updatedAt   DateTime    @updatedAt @map("updated_at")

  @@map("companies")
}

enum CompanyType {
  CARRIER
  CLIENT
}
EOF

    log "INFO" "NestJS structure created successfully"
    return 0
}

create_additional_configs() {
    log "INFO" "Creating additional configuration files..."
    
    # Create .gitignore
    cat > .gitignore << 'EOF'
# Dependencies
node_modules/
*/node_modules/

# Build outputs
dist/
build/
*.tsbuildinfo

# Environment variables
.env
.env.local
.env.production
.env.test

# Logs
logs/
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Runtime data
pids
*.pid
*.seed
*.pid.lock

# Coverage directory used by tools like istanbul
coverage/
*.lcov

# Dependency directories
node_modules/
jspm_packages/

# Optional npm cache directory
.npm

# Optional REPL history
.node_repl_history

# Output of 'npm pack'
*.tgz

# Yarn Integrity file
.yarn-integrity

# parcel-bundler cache (https://parceljs.org/)
.cache
.parcel-cache

# next.js build output
.next

# nuxt.js build output
.nuxt

# vuepress build output
.vuepress/dist

# Serverless directories
.serverless

# FuseBox cache
.fusebox/

# DynamoDB Local files
.dynamodb/

# TernJS port file
.tern-port

# Docker
.dockerignore

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# Database
*.sqlite
*.db

# Backup files
backups/
*.backup

# Temporary files
temp/
tmp/
*.tmp

# Prisma
prisma/migrations/migration_lock.toml

# Test files
test-results/
playwright-report/
EOF

    # Create .dockerignore
    cat > .dockerignore << 'EOF'
# Dependencies
node_modules/
npm-debug.log*

# Build outputs
dist/
build/

# Environment variables
.env
.env.local
.env.production

# Git
.git/
.gitignore

# Documentation
README.md
docs/

# Logs
logs/
*.log

# Test files
test/
coverage/
*.spec.ts
*.test.ts

# Development files
.vscode/
.idea/

# Backup files
backups/

# OS
.DS_Store
Thumbs.db
EOF

    # Create README.md
    cat > README.md << 'EOF'
# TMS Transportation Logistics System

A comprehensive Transportation Management System (TMS) built with NestJS, MySQL, and Redis.

## 🚀 Features

- **Multi-role System**: Admin, Carrier, Client, and Driver roles with specific permissions
- **Real-time Tracking**: Track shipments and deliveries in real-time
- **Fleet Management**: Manage vehicles and drivers efficiently
- **Order Management**: Create, track, and manage transportation orders
- **Payment Integration**: PayPal integration for payments
- **API Documentation**: Swagger/OpenAPI documentation
- **Monitoring**: Prometheus and Grafana integration
- **Containerized**: Docker and Docker Compose setup

## 🛠 Tech Stack

- **Backend**: NestJS (Node.js 22)
- **Database**: MySQL 8.0
- **Cache**: Redis 7-alpine
- **ORM**: Prisma
- **Authentication**: JWT with Passport
- **API Docs**: Swagger/OpenAPI
- **Monitoring**: Prometheus & Grafana
- **Containerization**: Docker & Docker Compose
- **CI/CD**: GitHub Actions

## 📋 Prerequisites

- Node.js 22.x
- pnpm
- Docker & Docker Compose
- Git

## 🚦 Quick Start

1. **Clone and Setup**
   ```bash
   git clone <repository-url>
   cd tms-project
   chmod +x setup.sh
   ./setup.sh
   ```

2. **Configure Environment**
   ```bash
   # Edit .env file with your configurations
   nano .env
   ```

3. **Start Development Environment**
   ```bash
   docker-compose up -d
   cd backend
   pnpm start:dev
   ```

4. **Access Services**
   - Backend API: http://localhost:3000
   - API Documentation: http://localhost:3000/api/docs
   - Database: localhost:3306
   - Redis: localhost:6379
   - Prometheus: http://localhost:9090
   - Grafana: http://localhost:3001

## 🏗 Project Structure

```
tms-project/
├── backend/                 # NestJS Backend
│   ├── src/
│   │   ├── core/           # Business logic & entities
│   │   ├── infrastructure/ # Data access & external services
│   │   ├── application/    # Use cases & services
│   │   └── presentation/   # Controllers & middlewares
│   ├── prisma/             # Database schema & migrations
│   └── test/               # Test files
├── scripts/                # Automation scripts
├── mysql/                  # MySQL configuration
├── redis/                  # Redis configuration
├── monitoring/             # Monitoring configs
├── docs/                   # Documentation
└── docker-compose.yml      # Docker services
```

## 🎭 User Roles & Permissions

### 👨‍💼 Admin
- Complete system access
- User management
- System configuration

### 🚛 Carrier
- Fleet management (vehicles, drivers)
- Order assignment
- Route optimization
- Pricing management

### 👤 Client
- Create transportation orders
- Track shipments
- View delivery status
- Manage profile

### 🚚 Driver
- View assigned routes
- Update delivery status
- Vehicle inspection
- Route navigation

## 🗄 Database Schema

The system uses MySQL 8.0 with the following main entities:
- Users (multi-role system)
- Companies (Carriers & Clients)
- Orders & Shipments
- Vehicles & Drivers
- Routes & Deliveries

## 🧪 Testing

```bash
# Run all tests
./scripts/test.sh all

# Run specific test types
./scripts/test.sh unit
./scripts/test.sh integration
./scripts/test.sh e2e
./scripts/test.sh security
```

## 🚀 Deployment

```bash
# Production deployment
./scripts/deploy.sh production

# Staging deployment
./scripts/deploy.sh staging
```

## 💾 Backup & Recovery

```bash
# Full backup
./scripts/backup.sh full

# Database only
./scripts/backup.sh database

# Restore database
./scripts/backup.sh restore-db backup-file.sql.gz
```

## 📊 Monitoring

- **Prometheus**: Metrics collection (http://localhost:9090)
- **Grafana**: Monitoring dashboards (http://localhost:3001)
- **Health Check**: http://localhost:3000/health

## 🔧 Development Commands

```bash
# Backend development
cd backend
pnpm start:dev          # Start development server
pnpm run lint           # Lint code
pnpm run test           # Run tests
pnpm run build          # Build for production

# Database operations
pnpm db:migrate         # Run migrations
pnpm db:generate        # Generate Prisma client
pnpm db:seed            # Seed database
pnpm db:studio          # Open Prisma Studio
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Run the test suite
6. Submit a pull request

## 📝 API Documentation

Once the server is running, visit:
- Swagger UI: http://localhost:3000/api/docs
- OpenAPI JSON: http://localhost:3000/api/docs-json

## 🐳 Docker Commands

```bash
# Development environment
docker-compose up -d

# Production environment
docker-compose -f docker-compose.prod.yml up -d

# View logs
docker-compose logs -f backend

# Shell access
docker-compose exec backend sh
```

## 🔐 Security

- JWT authentication with refresh tokens
- Role-based access control (RBAC)
- Input validation with class-validator
- Helmet.js for security headers
- Rate limiting with throttler
- Password hashing with bcrypt

## 📈 Performance

- Redis caching for improved performance
- Database indexing for optimal queries
- Connection pooling for database efficiency
- Compression middleware for API responses

## 🐛 Troubleshooting

### Common Issues

1. **Docker containers won't start**
   - Check if ports 3000, 3306, 6379 are available
   - Verify Docker is running: `docker info`

2. **Database connection failed**
   - Check MySQL container status: `docker-compose ps mysql`
   - Verify environment variables in .env file

3. **Redis connection failed**
   - Check Redis container: `docker-compose ps redis`
   - Verify Redis password in configuration

4. **Node.js version mismatch**
   - Ensure Node.js 22.x is installed: `node --version`
   - Use nvm to switch versions if needed

## 📞 Support

For support and questions:
- Create an issue in the repository
- Check the documentation in `/docs`
- Review logs in `/logs` directory

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

**Built with ❤️ for efficient transportation logistics management**
EOF

    # Create LICENSE
    cat > LICENSE << 'EOF'
MIT License

Copyright (c) 2024 TMS Transportation Logistics System

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF

    # Create backend/README.md
    cat > backend/README.md << 'EOF'
# TMS Backend Service

NestJS-based backend service for the Transportation Management System.

## Development Setup

1. Install dependencies:
   ```bash
   pnpm install
   ```

2. Set up environment variables:
   ```bash
   cp ../.env.example .env
   # Edit .env with your configurations
   ```

3. Start development server:
   ```bash
   pnpm start:dev
   ```

## Available Scripts

- `pnpm start` - Start production server
- `pnpm start:dev` - Start development server with hot reload
- `pnpm start:debug` - Start server in debug mode
- `pnpm build` - Build for production
- `pnpm test` - Run unit tests
- `pnpm test:e2e` - Run end-to-end tests
- `pnpm test:cov` - Generate test coverage report
- `pnpm lint` - Run ESLint
- `pnpm format` - Format code with Prettier

## Database Commands

- `pnpm db:migrate` - Run database migrations
- `pnpm db:generate` - Generate Prisma client
- `pnpm db:seed` - Seed database with test data
- `pnpm db:studio` - Open Prisma Studio
- `pnpm db:reset` - Reset database

## Architecture

The backend follows Clean Architecture principles:

- `core/` - Business logic and entities
- `infrastructure/` - Data access and external services
- `application/` - Use cases and application services
- `presentation/` - Controllers, guards, and middlewares

## Testing

The project includes comprehensive testing:

- Unit tests for business logic
- Integration tests for API endpoints
- End-to-end tests for complete workflows
- Performance tests for critical paths
EOF

    # Create monitoring/prometheus.yml
    cat > monitoring/prometheus.yml << 'EOF'
# Prometheus configuration for TMS monitoring
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  # - "first_rules.yml"
  # - "second_rules.yml"

scrape_configs:
  # The job name is added as a label `job=<job_name>` to any timeseries scraped from this config.
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'tms-backend'
    static_configs:
      - targets: ['backend:3000']
    metrics_path: '/metrics'
    scrape_interval: 30s

  - job_name: 'mysql-exporter'
    static_configs:
      - targets: ['mysql:3306']
    scrape_interval: 30s

  - job_name: 'redis-exporter'
    static_configs:
      - targets: ['redis:6379']
    scrape_interval: 30s
EOF

    # Create docs/CONTRIBUTING.md
    cat > docs/CONTRIBUTING.md << 'EOF'
# Contributing to TMS Transportation Logistics System

We welcome contributions to the TMS project! This document provides guidelines for contributing.

## Getting Started

1. Fork the repository
2. Clone your fork locally
3. Create a feature branch from `develop`
4. Make your changes
5. Test your changes thoroughly
6. Submit a pull request

## Development Workflow

### Branch Strategy
- `main` - Production-ready code
- `develop` - Integration branch for features
- `feature/*` - Feature branches
- `hotfix/*` - Critical bug fixes
- `release/*` - Release preparation

### Commit Messages
Use conventional commit format:
```
type(scope): description

[optional body]

[optional footer]
```

Types:
- `feat` - New feature
- `fix` - Bug fix
- `docs` - Documentation changes
- `style` - Code style changes
- `refactor` - Code refactoring
- `test` - Adding tests
- `chore` - Maintenance tasks

### Code Standards

#### TypeScript/NestJS
- Use TypeScript strict mode
- Follow NestJS conventions
- Use dependency injection
- Implement proper error handling
- Add comprehensive tests

#### Database
- Use Prisma migrations for schema changes
- Follow naming conventions (snake_case)
- Add proper indexes
- Document complex queries

#### API Design
- Follow RESTful principles
- Use proper HTTP status codes
- Validate all inputs
- Document with Swagger
- Version APIs appropriately

### Testing Requirements

All contributions must include:
- Unit tests for business logic
- Integration tests for API endpoints
- Update existing tests if needed
- Maintain test coverage above 80%

### Pull Request Process

1. **Pre-submission Checklist:**
   - [ ] Code follows project standards
   - [ ] All tests pass
   - [ ] Documentation updated
   - [ ] No merge conflicts
   - [ ] Security considerations addressed

2. **PR Description:**
   - Clear description of changes
   - Link to related issues
   - Screenshots for UI changes
   - Performance impact notes

3. **Review Process:**
   - At least one code review required
   - All CI checks must pass
   - Address all review comments
   - Squash commits before merge

## Development Setup

```bash
# Clone and setup
git clone <your-fork>
cd tms-project
./setup.sh

# Create feature branch
git checkout -b feature/your-feature-name

# Make changes and test
./scripts/test.sh all

# Commit and push
git commit -m "feat: add new feature"
git push origin feature/your-feature-name
```

## Reporting Issues

### Bug Reports
Include:
- Clear description of the issue
- Steps to reproduce
- Expected vs actual behavior
- Environment details
- Logs or error messages

### Feature Requests
Include:
- Clear description of the feature
- Use cases and benefits
- Proposed implementation approach
- Mockups or diagrams if applicable

## Code Review Guidelines

### For Authors
- Keep PRs focused and small
- Write clear commit messages
- Add comprehensive tests
- Update documentation
- Respond promptly to feedback

### For Reviewers
- Be constructive and respectful
- Focus on code quality and maintainability
- Check for security issues
- Verify test coverage
- Consider performance impact

## Documentation

- Update README.md for user-facing changes
- Add inline code comments for complex logic
- Update API documentation in Swagger
- Create architecture diagrams when needed

## Security

- Never commit secrets or credentials
- Follow OWASP security guidelines
- Use parameterized queries
- Validate and sanitize all inputs
- Report security issues privately

## Performance

- Consider database query performance
- Optimize critical code paths
- Monitor memory usage
- Use appropriate caching strategies
- Load test significant changes

## Questions?

- Create an issue for general questions
- Join our development discussions
- Check existing documentation first
- Contact maintainers for urgent issues

Thank you for contributing to TMS! 🚀
EOF

    # Create docs/DEPLOYMENT.md
    cat > docs/DEPLOYMENT.md << 'EOF'
# TMS Deployment Guide

This guide covers deploying the TMS Transportation Logistics System to production.

## Prerequisites

- Docker and Docker Compose
- SSL certificates (for HTTPS)
- Domain name configured
- Server with adequate resources

## Production Deployment

### 1. Server Requirements

**Minimum Requirements:**
- 4 GB RAM
- 2 CPU cores
- 50 GB SSD storage
- Ubuntu 20.04+ or similar

**Recommended Requirements:**
- 8 GB RAM
- 4 CPU cores
- 100 GB SSD storage
- Load balancer for high availability

### 2. Environment Setup

```bash
# Clone repository
git clone <repository-url>
cd tms-project

# Copy and configure environment
cp .env.example .env
nano .env

# Set production values
NODE_ENV=production
DATABASE_URL="mysql://tms_user:secure_password@mysql:3306/tms_db"
JWT_SECRET="your-production-jwt-secret"
# ... other production values
```

### 3. SSL Configuration

Create SSL directory and add certificates:
```bash
mkdir -p nginx/ssl
# Copy your SSL certificates
cp your-domain.crt nginx/ssl/
cp your-domain.key nginx/ssl/
```

### 4. Deploy with Docker

```bash
# Build and start production containers
docker-compose -f docker-compose.prod.yml up -d --build

# Check container status
docker-compose -f docker-compose.prod.yml ps
```

### 5. Database Setup

```bash
# Run migrations
docker-compose -f docker-compose.prod.yml exec backend npx prisma migrate deploy

# Seed initial data (optional)
docker-compose -f docker-compose.prod.yml exec backend npx prisma db seed
```

## Automated Deployment

### Using GitHub Actions

The project includes CI/CD workflows for automated deployment:

1. **Setup Secrets in GitHub:**
   ```
   DEPLOY_HOST - Your server IP/domain
   DEPLOY_USER - SSH username
   DEPLOY_KEY - SSH private key
   MYSQL_ROOT_PASSWORD - MySQL root password
   MYSQL_PASSWORD - Application database password
   ```

2. **Deploy Process:**
   - Push to `main` branch triggers deployment
   - Tests run automatically
   - Builds Docker images
   - Deploys to production server

### Manual Deployment Script

```bash
# Deploy to production
./scripts/deploy.sh production

# Deploy to staging
./scripts/deploy.sh staging
```

## Monitoring Setup

### 1. Prometheus & Grafana

Access monitoring dashboards:
- Prometheus: http://your-domain:9090
- Grafana: http://your-domain:3001 (admin/admin)

### 2. Log Monitoring

Logs are stored in `/logs` directory:
```bash
# View application logs
docker-compose -f docker-compose.prod.yml logs -f backend

# View database logs
docker-compose -f docker-compose.prod.yml logs -f mysql
```

## Backup Strategy

### 1. Automated Backups

Set up cron job for regular backups:
```bash
# Add to crontab
0 2 * * * /path/to/tms-project/scripts/backup.sh full
```

### 2. Manual Backup

```bash
# Full backup
./scripts/backup.sh full

# Database only
./scripts/backup.sh database
```

## Security Considerations

### 1. Network Security
- Use firewall rules to restrict access
- Close unnecessary ports
- Use VPN for administrative access

### 2. Application Security
- Regular security updates
- Strong passwords and secrets
- Enable HTTPS only
- Regular security audits

### 3. Database Security
- Regular security patches
- Strong passwords
- Limit network access
- Regular backups

## Performance Optimization

### 1. Database Optimization
- Regular maintenance and optimization
- Monitor slow queries
- Optimize indexes
- Connection pooling

### 2. Application Optimization
- Enable Redis caching
- Optimize API responses
- Monitor resource usage
- Load balancing for scale

### 3. Infrastructure Optimization
- Use SSD storage
- Adequate RAM allocation
- CDN for static assets
- Regular performance monitoring

## Scaling

### Horizontal Scaling

For high-traffic scenarios:

1. **Load Balancer Setup**
   ```yaml
   # Add to docker-compose.prod.yml
   nginx:
     image: nginx:alpine
     volumes:
       - ./nginx/nginx.conf:/etc/nginx/nginx.conf
     ports:
       - "80:80"
       - "443:443"
   ```

2. **Multiple Backend Instances**
   ```yaml
   backend:
     deploy:
       replicas: 3
   ```

3. **Database Clustering**
   - MySQL master-slave setup
   - Read replicas for scaling reads

### Vertical Scaling

Increase server resources:
```yaml
# Resource limits in docker-compose.prod.yml
services:
  backend:
    deploy:
      resources:
        limits:
          memory: 1G
          cpus: '2'
```

## Troubleshooting

### Common Issues

1. **Container Won't Start**
   ```bash
   # Check logs
   docker-compose -f docker-compose.prod.yml logs backend
   
   # Check system resources
   docker system df
   docker system prune
   ```

2. **Database Connection Issues**
   ```bash
   # Check MySQL container
   docker-compose -f docker-compose.prod.yml exec mysql mysql -u root -p
   
   # Verify environment variables
   docker-compose -f docker-compose.prod.yml exec backend env | grep DB
   ```

3. **High Memory Usage**
   ```bash
   # Monitor container resources
   docker stats
   
   # Check application metrics
   curl http://localhost:3000/metrics
   ```

### Health Checks

Monitor application health:
```bash
# Application health
curl http://your-domain/health

# Database connectivity
curl http://your-domain/api/health/db

# Redis connectivity  
curl http://your-domain/api/health/redis
```

## Maintenance

### Regular Tasks

1. **Weekly:**
   - Check application logs
   - Monitor system resources
   - Verify backups

2. **Monthly:**
   - Update dependencies
   - Security patches
   - Performance review

3. **Quarterly:**
   - Full security audit
   - Disaster recovery test
   - Capacity planning review

### Update Procedure

```bash
# 1. Backup current version
./scripts/backup.sh full

# 2. Pull latest changes
git pull origin main

# 3. Update containers
docker-compose -f docker-compose.prod.yml down
docker-compose -f docker-compose.prod.yml up -d --build

# 4. Run migrations
docker-compose -f docker-compose.prod.yml exec backend npx prisma migrate deploy

# 5. Verify deployment
curl http://your-domain/health
```

## Rollback Procedure

In case of issues:
```bash
# 1. Stop current deployment
docker-compose -f docker-compose.prod.yml down

# 2. Rollback using script
./scripts/deploy.sh rollback

# 3. Restore database if needed
./scripts/backup.sh restore-db /path/to/backup.sql.gz

# 4. Verify rollback
curl http://your-domain/health
```

For immediate assistance during deployment issues, refer to the troubleshooting logs and monitoring dashboards.
EOF

    log "INFO" "Additional configuration files created successfully"
}

# ==================== CONFIGURATION FUNCTIONS ====================
save_config() {
    local config_data="SETUP_DATE=$(date '+%Y-%m-%d %H:%M:%S')
SETUP_VERSION=2.0
NODE_VERSION=$(node -v)
PNPM_VERSION=$(pnpm -v)
LAST_OPERATION=$1
PROJECT_TYPE=TMS_LOGISTICS
DATABASE=MySQL_8.0
CACHE=Redis_7_Alpine"
    
    echo "$config_data" > "$CONFIG_FILE"
    log "DEBUG" "Configuration saved to $CONFIG_FILE"
}

load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
        log "DEBUG" "Configuration loaded from $CONFIG_FILE"
        return 0
    fi
    return 1
}

# ==================== UTILITY FUNCTIONS ====================
show_help() {
    cat << 'EOF'
TMS Transportation Logistics System - Advanced Setup Script v2.0

Usage: ./setup.sh [OPTION]

Options:
  -h, --help          Show this help message
  -f, --full          Full project setup (default)
  -u, --update        Update existing project dependencies
  -c, --check         Check prerequisites only
  -r, --rollback      Rollback to last backup
  -v, --verbose       Enable verbose output
  --clean             Clean setup (remove existing files)

Project Specifications:
  - Node.js: 22.x (Required)
  - Database: MySQL 8.0
  - Cache: Redis 7-alpine
  - Framework: NestJS with Clean Architecture
  - Containerization: Docker & Docker Compose
  - Monitoring: Prometheus & Grafana

Examples:
  ./setup.sh          # Full TMS setup
  ./setup.sh -c       # Check prerequisites
  ./setup.sh -u       # Update dependencies
  ./setup.sh -r       # Rollback changes
  ./setup.sh --clean  # Clean setup

After setup, you can use:
  ./scripts/deploy.sh production  # Deploy to production
  ./scripts/backup.sh full        # Create full backup
  ./scripts/test.sh all          # Run all tests

EOF
}

show_summary() {
    log "INFO" "TMS Transportation Logistics System Setup Complete!"
    echo "================================================================"
    echo "✅ Directory structure created (Clean Architecture)"
    echo "✅ MySQL 8.0 configuration with multi-role permissions"
    echo "✅ Redis 7-alpine for caching and sessions"
    echo "✅ NestJS backend with security features"
    echo "✅ Docker configurations (dev/prod/test)"
    echo "✅ GitHub Actions workflows (CI/CD)"
    echo "✅ Comprehensive scripts (deploy/backup/test)"
    echo "✅ Monitoring setup (Prometheus/Grafana)"
    echo "✅ Complete documentation"
    echo ""
    echo "🚀 Quick Start:"
    echo "1. Configure environment: nano .env"
    echo "2. Start services: docker-compose up -d"
    echo "3. Run migrations: cd backend && npx prisma migrate dev"
    echo "4. Start development: pnpm start:dev"
    echo ""
    echo "🌐 Access Points:"
    echo "• Backend API: http://localhost:3000"
    echo "• API Docs: http://localhost:3000/api/docs"
    echo "• Database: localhost:3306 (MySQL 8.0)"
    echo "• Redis: localhost:6379"
    echo "• Prometheus: http://localhost:9090"
    echo "• Grafana: http://localhost:3001"
    echo ""
    echo "📋 User Roles Available:"
    echo "• Admin: Full system control"
    echo "• Carrier: Fleet & transport management"
    echo "• Client: Order creation & tracking"
    echo "• Driver: Route & delivery management"
    echo ""
    echo "🛠 Useful Commands:"
    echo "• ./scripts/deploy.sh production  # Deploy"
    echo "• ./scripts/backup.sh full        # Backup"
    echo "• ./scripts/test.sh all           # Test"
    echo ""
    echo "📖 Documentation: Check README.md and docs/ folder"
    echo "================================================================"
}

# ==================== MAIN FUNCTIONS ====================
full_setup() {
    log "INFO" "Starting TMS Transportation Logistics System full setup..."
    log "INFO" "Node.js: 22.x | Database: MySQL 8.0 | Cache: Redis 7-alpine"
    
    check_prerequisites || return 1
    create_backup
    create_directory_structure || return 1
    create_essential_files || return 1
    create_environment_files || return 1
    create_mysql_configuration || return 1
    create_redis_configuration || return 1
    create_docker_files || return 1
    create_github_workflows || return 1
    create_scripts || return 1
    setup_package_json || return 1
    create_nestjs_structure || return 1
    create_additional_configs || return 1
    
    # Setup development configuration
    create_typescript_config || return 1
    create_pnpm_config || return 1
    create_prisma_seed || return 1
    install_development_dependencies || return 1
    
    save_config "full_setup"
    show_summary
    log "INFO" "TMS project setup completed successfully!"
}

update_dependencies() {
    log "INFO" "Updating TMS project dependencies..."
    
    if [[ ! -d "backend" ]]; then
        log "ERROR" "Backend directory not found. Run full setup first."
        return 1
    fi
    
    cd backend || return 1
    
    if ! pnpm update; then
        log "ERROR" "Failed to update dependencies"
        return 1
    fi
    
    # Update Prisma client
    if ! npx prisma generate; then
        log "ERROR" "Failed to update Prisma client"
        return 1
    fi
    
    cd .. || return 1
    save_config "update_dependencies"
    log "INFO" "Dependencies updated successfully!"
}

clean_setup() {
    log "WARN" "This will remove all existing TMS project files!"
    read -p "Are you sure? This action cannot be undone (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log "INFO" "Performing clean TMS setup..."
        
        # Remove existing directories and files
        rm -rf backend node_modules .env docker-compose*.yml mysql redis logs backups
        
        full_setup
    else
        log "INFO" "Clean setup cancelled"
    fi
}

# ==================== MAIN SCRIPT ====================
main() {
    # Initialize log file
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "TMS Transportation Logistics System Setup - $(date)" > "$LOG_FILE"
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -f|--full)
                full_setup
                exit $?
                ;;
            -u|--update)
                update_dependencies
                exit $?
                ;;
            -c|--check)
                check_prerequisites
                exit $?
                ;;
            -r|--rollback)
                rollback_changes
                exit $?
                ;;
            -v|--verbose)
                export DEBUG=1
                shift
                ;;
            --clean)
                clean_setup
                exit $?
                ;;
            *)
                log "ERROR" "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Default action: full setup
    full_setup
}

# Run main function with all arguments
main "$@"
