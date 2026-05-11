#!/usr/bin/env bash
#
# Script di test ambiente Hubso
# Esegui: ./scripts/test-env.sh
#

set -e  # Fermati al primo errore

echo "========================================"
echo "  HUBSO - Test Ambiente di Sviluppo"
echo "========================================"
echo ""

# Colori per output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ERRORS=0

# Funzione per stampare OK
check_ok() {
  echo -e "${GREEN}✅ $1${NC}"
}

# Funzione per stampare ERRORE
check_fail() {
  echo -e "${RED}❌ $1${NC}"
  ERRORS=$((ERRORS + 1))
}

# Funzione per stampare WARNING
check_warn() {
  echo -e "${YELLOW}⚠️  $1${NC}"
}

# ==========================================
# 1. Docker
# ==========================================
echo "Step 1/7 - Docker"
echo "-----------------"

if ! command -v docker &> /dev/null; then
  check_fail "Docker non trovato. Installa Docker: https://docs.docker.com/get-docker/"
else
  check_ok "Docker installato ($(docker --version))"
fi

if ! docker info &> /dev/null; then
  check_fail "Docker daemon non in esecuzione. Avvia Docker Desktop o 'sudo systemctl start docker'"
else
  check_ok "Docker daemon attivo"
fi

# ==========================================
# 2. Docker Compose
# ==========================================
echo ""
echo "Step 2/7 - Docker Compose (Database)"
echo "-------------------------------------"

cd "$(dirname "$0")/.."

if ! docker compose ps | grep -q "hubso-postgres"; then
  check_warn "PostgreSQL non in esecuzione. Avvia con: docker compose up -d"
  echo "   Eseguo avvio automatico..."
  docker compose up -d
  sleep 3
fi

if docker compose ps | grep -q "hubso-postgres.*Up"; then
  check_ok "PostgreSQL container attivo"
else
  check_fail "PostgreSQL container non avviato"
fi

if docker compose ps | grep -q "hubso-redis.*Up"; then
  check_ok "Redis container attivo"
else
  check_warn "Redis container non avviato. Avvio..."
  docker compose up -d
  sleep 2
fi

# ==========================================
# 3. PostgreSQL
# ==========================================
echo ""
echo "Step 3/7 - Connessione PostgreSQL"
echo "----------------------------------"

# Aspetta che PostgreSQL sia pronto
for i in {1..10}; do
  if docker compose exec -T postgres pg_isready -U hubso -d hubso &> /dev/null; then
    break
  fi
  sleep 1
done

if docker compose exec -T postgres pg_isready -U hubso -d hubso &> /dev/null; then
  check_ok "PostgreSQL risponde"
else
  check_fail "PostgreSQL non risponde"
fi

# Verifica tabelle
if docker compose exec -T postgres psql -U hubso -d hubso -c "\dt" | grep -q "users"; then
  check_ok "Tabelle Prisma presenti (users, social_accounts, etc.)"
else
  check_warn "Tabelle non trovate. Esegui: cd hubso-api && npx prisma migrate deploy"
fi

# ==========================================
# 4. Redis
# ==========================================
echo ""
echo "Step 4/7 - Connessione Redis"
echo "-----------------------------"

if docker compose exec -T redis redis-cli ping | grep -q "PONG"; then
  check_ok "Redis risponde (PONG)"
else
  check_fail "Redis non risponde"
fi

# ==========================================
# 5. Backend NestJS
# ==========================================
echo ""
echo "Step 5/7 - Backend NestJS"
echo "-------------------------"

if [ ! -d "hubso-api/node_modules" ]; then
  check_warn "Node modules backend mancanti. Installo..."
  cd hubso-api && npm install && cd ..
fi

cd hubso-api

# Verifica Prisma Client generato
if [ -d "node_modules/@prisma/client" ]; then
  check_ok "Prisma Client generato"
else
  check_warn "Prisma Client non trovato. Genero..."
  npx prisma generate
  check_ok "Prisma Client generato"
fi

# Verifica build backend
if npm run build &> /tmp/hubso-build.log; then
  check_ok "Backend compila senza errori"
else
  check_fail "Backend ha errori di compilazione"
  echo "   Log: /tmp/hubso-build.log"
fi

cd ..

# ==========================================
# 6. Frontend Angular
# ==========================================
echo ""
echo "Step 6/7 - Frontend Angular"
echo "---------------------------"

if [ ! -d "hubso-web/node_modules" ]; then
  check_warn "Node modules frontend mancanti. Installo..."
  cd hubso-web && npm install && cd ..
fi

cd hubso-web

# Verifica build frontend
if npm run build &> /tmp/hubso-web-build.log; then
  check_ok "Frontend compila senza errori"
else
  check_fail "Frontend ha errori di compilazione"
  echo "   Log: /tmp/hubso-web-build.log"
fi

cd ..

# ==========================================
# 7. File Configurazione
# ==========================================
echo ""
echo "Step 7/7 - Configurazione"
echo "------------------------"

if [ -f "hubso-api/.env" ]; then
  check_ok "File .env backend presente"
else
  check_warn "File .env backend mancante. Copia da .env.example: cp hubso-api/.env.example hubso-api/.env"
fi

if [ -f "hubso-web/.env" ]; then
  check_ok "File .env frontend presente"
else
  check_warn "File .env frontend mancante. Copia da .env.example: cp hubso-web/.env.example hubso-web/.env"
fi

# ==========================================
# Riepilogo
# ==========================================
echo ""
echo "========================================"
echo "  RIEPILOGO"
echo "========================================"

if [ $ERRORS -eq 0 ]; then
  echo -e "${GREEN}✅ Ambiente pronto per lo sviluppo!${NC}"
  echo ""
  echo "Per avviare il backend:"
  echo "  cd hubso-api && npm run start:dev"
  echo ""
  echo "Per avviare il frontend:"
  echo "  cd hubso-web && npm start"
  echo ""
  echo "Per testare Prisma:"
  echo "  cd hubso-api && npx prisma studio"
  exit 0
else
  echo -e "${RED}❌ Trovati $ERRORS errori. Correggi prima di procedere.${NC}"
  exit 1
fi
