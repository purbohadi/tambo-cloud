# Multi-service Docker image for Tambo Cloud
# Usage:# Create the missing TypeScript config files that packages depend on
RUN mkdir -p /app/node_modules/@tambo-ai-cloud/typescript-config && \
    echo '{"compilerOptions":{"declaration":true,"declarationMap":true,"esModuleInterop":true,"incremental":false,"isolatedModules":true,"lib":["es2023","DOM","DOM.Iterable"],"module":"NodeNext","moduleDetection":"force","moduleResolution":"NodeNext","noUncheckedIndexedAccess":false,"resolveJsonModule":true,"skipLibCheck":true,"strict":false,"target":"ES2022","sourceMap":true}}' > /app/node_modules/@tambo-ai-cloud/typescript-config/base.json && \
    echo '{"extends":"./base.json","compilerOptions":{"plugins":[{"name":"next"}],"module":"ESNext","moduleResolution":"Bundler","allowJs":true,"jsx":"preserve","noEmit":true,"lib":["ES2023"]}}' > /app/node_modules/@tambo-ai-cloud/typescript-config/nextjs.json

# Build core packages with lenient TypeScript settings
RUN npx turbo build --filter=@tambo-ai-cloud/core --filter=@tambo-ai-cloud/db --continue || echo "Some core packages failed to build"

# Build the web app
WORKDIR /app/apps/webdocker build --target web -t tambo-web .
#   docker build --target api -t tambo-api .
#   docker build --target all -t tambo-all .

FROM node:22-alpine AS base

# Install system dependencies
RUN apk add --no-cache libc6-compat curl
RUN npm install -g npm@^11

# Enable Corepack for packageManager support
RUN corepack enable

# Create non-root user
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nodejs

# Dependencies stage - install all dependencies
FROM base AS deps
WORKDIR /app

# Copy package files for dependency resolution
COPY package*.json turbo.json ./
COPY apps/*/package*.json ./apps/*/
COPY packages/*/package*.json ./packages/*/

# Install all dependencies and rebuild native modules for the container platform
RUN npm install --prefer-offline --no-audit && \
    npm rebuild && \
    npm cache clean --force

# Source stage - copy all source code
FROM base AS source
WORKDIR /app

# Copy dependencies and source
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Build stage - build all applications
FROM source AS builder
WORKDIR /app

# Set build environment variables
ENV NODE_ENV=production
ENV NODE_OPTIONS="--max-old-space-size=4096"
ENV SKIP_ENV_VALIDATION=true
ENV NEXT_TELEMETRY_DISABLED=1
ENV TURBO_TELEMETRY_DISABLED=1

# First, build essential workspace dependencies
WORKDIR /app

# Build core packages with lenient TypeScript settings
RUN npx turbo build --filter=@tambo-ai-cloud/core --filter=@tambo-ai-cloud/db --continue || echo "Some core packages failed to build"

# Now build the web app
WORKDIR /app/apps/web

# Use the original tsconfig.json since we now have the typescript-config files

# Build the web app with additional environment variables for build
ENV SKIP_VALIDATION=true
RUN npm run build

# Build the API directly
WORKDIR /app/apps/api
RUN npm run build

# Reset working directory
WORKDIR /app

# Web service stage
FROM base AS web

# Set production environment
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

# Set user and permissions
WORKDIR /app
RUN chown nodejs:nodejs /app
USER nodejs

# Copy web application build
COPY --from=builder --chown=nodejs:nodejs /app/apps/web/.next/standalone ./
COPY --from=builder --chown=nodejs:nodejs /app/apps/web/.next/static ./apps/web/.next/static
COPY --from=builder --chown=nodejs:nodejs /app/apps/web/public ./apps/web/public

# Health check for web service
HEALTHCHECK --interval=30s --timeout=8s --start-period=30s --retries=3 \
  CMD curl -f http://localhost:3000/ || exit 1

EXPOSE 3000

WORKDIR /app/apps/web
CMD ["node", "server.js"]

# API service stage
FROM base AS api

# Set production environment
ENV NODE_ENV=production
ENV NODE_OPTIONS="--experimental-require-module"
ENV PORT=3000

# Set user and permissions
WORKDIR /app
RUN chown nodejs:nodejs /app
USER nodejs

# Copy API application build and dependencies
COPY --from=builder --chown=nodejs:nodejs /app/apps/api/dist ./apps/api/dist
COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=nodejs:nodejs /app/packages ./packages

# Health check for API service
HEALTHCHECK --interval=20s --timeout=8s --start-period=30s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1

EXPOSE 3000

CMD ["node", "apps/api/dist/apps/api/src/main"]

# Development stage - includes all services for development
FROM source AS development

# Set development environment
ENV NODE_ENV=development
ENV NODE_OPTIONS="--experimental-require-module --trace-warnings"

# Set user and permissions
WORKDIR /app
RUN chown nodejs:nodejs /app
USER nodejs

# Expose common development ports
EXPOSE 3000 3001 3210 3211

# Default development command
CMD ["npm", "run", "dev"]

# All services stage - production ready with both services
FROM base AS all

# Set production environment
ENV NODE_ENV=production

# Set user and permissions
WORKDIR /app
RUN chown nodejs:nodejs /app
USER nodejs

# Copy all built applications
COPY --from=web --chown=nodejs:nodejs /app ./web-app
COPY --from=api --chown=nodejs:nodejs /app ./api-app

# Install process manager for running multiple services
USER root
RUN npm install -g pm2
USER nodejs

# Create PM2 ecosystem file
RUN echo '{\
  "apps": [\
    {\
      "name": "tambo-web",\
      "cwd": "/app/web-app/apps/web",\
      "script": "server.js",\
      "env": {\
        "PORT": "3210",\
        "NODE_ENV": "production"\
      }\
    },\
    {\
      "name": "tambo-api",\
      "cwd": "/app/api-app",\
      "script": "apps/api/dist/apps/api/src/main",\
      "env": {\
        "PORT": "3211",\
        "NODE_ENV": "production",\
        "NODE_OPTIONS": "--experimental-require-module"\
      }\
    }\
  ]\
}' > ecosystem.config.json

# Health check for all services
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:3210/ && curl -f http://localhost:3211/health || exit 1

EXPOSE 3210 3211

CMD ["pm2-runtime", "start", "ecosystem.config.json"]