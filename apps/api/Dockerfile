# Multi-stage Docker image for API (NestJS)
FROM node:22-alpine AS base

# Install system dependencies
RUN apk add --no-cache libc6-compat curl
RUN npm install -g npm@^11

# Create non-root user
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nodejs

# Dependencies stage
FROM base AS deps
WORKDIR /app

# Copy package files
COPY package*.json turbo.json ./
COPY apps/api/package*.json ./apps/api/
COPY packages/*/package*.json ./packages/*/

# Install dependencies
RUN npm ci --only=production && npm cache clean --force

# Build stage
FROM base AS builder
WORKDIR /app

# Copy source code
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Set build environment
ENV NODE_OPTIONS="--experimental-require-module"

# Build the application
RUN npx turbo build --filter=hydra-api

# Production stage
FROM base AS runner
WORKDIR /app

# Set production environment
ENV NODE_ENV=production
ENV PORT=3000

# Set user and permissions
RUN chown nodejs:nodejs /app
USER nodejs

# Copy built application and dependencies
COPY --from=builder --chown=nodejs:nodejs /app/apps/api/dist ./apps/api/dist
COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=nodejs:nodejs /app/packages ./packages

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1

EXPOSE 3000

CMD ["node", "apps/api/dist/apps/api/src/main"]