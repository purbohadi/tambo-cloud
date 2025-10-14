#!/bin/bash

# Docker build script for Tambo Cloud services
# Usage: ./docker-build.sh [service] [tag]
# Services: web, api, all, dev
# Default tag: latest

set -e

SERVICE=${1:-all}
TAG=${2:-latest}

echo "🚀 Building Tambo Cloud Docker images..."
echo "Service: $SERVICE"
echo "Tag: $TAG"
echo ""

case $SERVICE in
  "web")
    echo "📦 Building Web service (Next.js)..."
    docker build --target web -t tambo-web:$TAG .
    echo "✅ Web service built successfully as tambo-web:$TAG"
    ;;
  
  "api")
    echo "📦 Building API service (NestJS)..."
    docker build --target api -t tambo-api:$TAG .
    echo "✅ API service built successfully as tambo-api:$TAG"
    ;;
  
  "dev")
    echo "📦 Building Development environment..."
    docker build --target development -t tambo-dev:$TAG .
    echo "✅ Development environment built successfully as tambo-dev:$TAG"
    ;;
  
  "all")
    echo "📦 Building all services..."
    docker build --target web -t tambo-web:$TAG .
    echo "✅ Web service built successfully"
    
    docker build --target api -t tambo-api:$TAG .
    echo "✅ API service built successfully"
    
    docker build --target all -t tambo-all:$TAG .
    echo "✅ All services built successfully"
    ;;
  
  *)
    echo "❌ Invalid service: $SERVICE"
    echo "Available services: web, api, all, dev"
    exit 1
    ;;
esac

echo ""
echo "🎉 Build completed successfully!"
echo ""
echo "📋 Available images:"
docker images | grep tambo- | head -10

echo ""
echo "🚀 To run with docker-compose:"
echo "  docker-compose up"
echo ""
echo "🔧 To run individual services:"
echo "  docker run -p 3210:3000 tambo-web:$TAG"
echo "  docker run -p 3211:3000 tambo-api:$TAG"