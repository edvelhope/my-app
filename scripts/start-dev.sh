#!/usr/bin/env bash
#
# Script avvio rapido Hubso
# Avvia tutto: Docker, Backend, Frontend
# Esegui: ./scripts/start-dev.sh
#

echo "🚀 Avvio ambiente Hubso..."
echo ""

# 1. Avvia Docker
echo "📦 Step 1/3 - Avvio database (Docker)..."
docker compose up -d
echo "   ✅ Docker pronto"
echo ""

# 2. Avvia Backend
echo "⚙️  Step 2/3 - Avvio backend NestJS..."
cd hubso-api
npm run start:dev &
BACKEND_PID=$!
echo "   ✅ Backend avviato (PID: $BACKEND_PID)"
echo "   📡 http://localhost:3000"
echo ""

# 3. Avvia Frontend
echo "🎨 Step 3/3 - Avvio frontend Angular..."
cd ../hubso-web
npm start &
FRONTEND_PID=$!
echo "   ✅ Frontend avviato (PID: $FRONTEND_PID)"
echo "   🌐 http://localhost:4200"
echo ""

echo "========================================"
echo "  AMBIENTE PRONTO!"
echo "========================================"
echo ""
echo "Servizi attivi:"
echo "  🐘 PostgreSQL  → localhost:5432"
echo "  🔴 Redis       → localhost:6379"
echo "  ⚙️  Backend     → http://localhost:3000"
echo "  🎨 Frontend    → http://localhost:4200"
echo ""
echo "Per fermare tutto:"
echo "  kill $BACKEND_PID $FRONTEND_PID"
echo "  docker compose down"
echo ""
echo "Prisma Studio:"
echo "  cd hubso-api && npx prisma studio"
echo ""

# Aspetta che l'utente prema Ctrl+C
trap "echo ''; echo '🛑 Arresto servizi...'; kill $BACKEND_PID $FRONTEND_PID 2>/dev/null; docker compose down; exit 0" INT
wait
