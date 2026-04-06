#!/bin/bash
# Quick start script for Ursh Registry

set -e

echo "🐚 Ursh Registry - Quick Start"
echo "=============================="
echo ""

# Check for Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is required but not installed."
    echo "   Install from: https://nodejs.org/"
    exit 1
fi

echo "✅ Node.js found: $(node --version)"

# Check for npm
if ! command -v npm &> /dev/null; then
    echo "❌ npm is required but not installed."
    exit 1
fi

echo "✅ npm found: $(npm --version)"
echo ""

# Install backend dependencies
echo "📦 Installing backend dependencies..."
cd backend
npm install --silent
echo "   ✅ Backend dependencies installed"

# Check for .env file
if [ ! -f ".env" ]; then
    echo ""
    echo "⚠️  No .env file found in backend/"
    echo "   Copy .env.example to .env and configure:"
    echo "   cp .env.example .env"
    echo ""
    echo "   You'll need GitHub OAuth credentials from:"
    echo "   https://github.com/settings/developers"
fi

cd ..

# Install frontend dependencies
echo "📦 Installing frontend dependencies..."
cd frontend
npm install --silent
echo "   ✅ Frontend dependencies installed"
cd ..

# Initialize database
echo ""
echo "🗄️  Initializing database..."
cd backend
if [ ! -f "../database/ursh.db" ]; then
    npm run init-db
else
    echo "   Database already exists"
fi
cd ..

echo ""
echo "✅ Setup complete!"
echo ""
echo "📋 Next steps:"
echo ""
echo "1. Configure backend/.env with your GitHub OAuth credentials"
echo "   Get them from: https://github.com/settings/developers"
echo ""
echo "2. Start the backend server:"
echo "   cd backend && npm run dev"
echo ""
echo "3. In another terminal, start the frontend:"
echo "   cd frontend && npm run dev"
echo ""
echo "4. Open http://localhost:3000 in your browser"
echo ""
echo "📚 For more information, see README.md"
