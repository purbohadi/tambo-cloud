# Multi-stage Docker image for Web (Next.js)
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
COPY apps/web/package*.json ./apps/web/
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
ENV NODE_OPTIONS="--max-old-space-size=4096"
ENV SKIP_ENV_VALIDATION=true

# Build the application
RUN npx turbo build --filter=tambo-ai-landing-page

# Production stage
FROM base AS runner
WORKDIR /app

# Set production environment
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

# Set user and permissions
RUN chown nodejs:nodejs /app
USER nodejs

# Copy built application
COPY --from=builder --chown=nodejs:nodejs /app/apps/web/.next/standalone ./
COPY --from=builder --chown=nodejs:nodejs /app/apps/web/.next/static ./apps/web/.next/static
COPY --from=builder --chown=nodejs:nodejs /app/apps/web/public ./apps/web/public

EXPOSE 3000

WORKDIR /app/apps/web
CMD ["node", "server.js"]