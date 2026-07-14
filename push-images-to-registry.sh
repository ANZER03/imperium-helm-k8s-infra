#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────
# Configuration
# ─────────────────────────────────────────────────────────────
REGISTRY_NS="registry"
REGISTRY_SVC="registry"
REGISTRY_PORT=5000          # host port
REGISTRY_URL="localhost:${REGISTRY_PORT}"
KUBECONFIG="${KUBECONFIG:-$(pwd)/output/kubeconfig.yaml}"
export KUBECONFIG

# Images to push: "name:tag" (destination) → "source image" (local docker)
declare -A IMAGES=(
  ["imperium-frontend:1.0.0"]="localhost:5000/imperium-frontend:1.0.0"
  ["imperium-frontend:1.0.1"]="localhost:5000/imperium-frontend:1.0.1"
  ["imperium-news-app:1.0.0"]="localhost:5000/imperium-news-app:1.0.0"
  ["imperium-postgres-projector:1.0.0"]="localhost:5000/imperium-postgres-projector:1.0.0"
  ["imperium-redis-projector:1.0.0"]="localhost:5000/imperium-redis-projector:1.0.0"
  ["imperium-classification-driver:1.0.0"]="localhost:5000/imperium-classification-driver:1.0.0"
  ["imperium-canonical-enrichment-driver:1.0.0"]="localhost:5000/imperium-canonical-enrichment-driver:1.0.0"
  ["debezium-avro:1.1.3"]="localhost:30500/debezium-avro:1.1.3"
  ["debezium-avro:1.1.4"]="localhost:30500/debezium-avro:1.1.4"
  ["llama-cpp-gemma:latest"]="localhost:30500/llama-cpp-gemma:latest"
  # imperium-elasticsearch-projector — not available locally, excluded
  # imperium-qdrant-projector        — not available locally, excluded
)

# ─────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────
log()  { echo -e "\033[1;34m[INFO]\033[0m  $*"; }
ok()   { echo -e "\033[1;32m[ OK ]\033[0m  $*"; }
warn() { echo -e "\033[1;33m[WARN]\033[0m  $*"; }
err()  { echo -e "\033[1;31m[ERR ]\033[0m  $*" >&2; }

# cleanup() {
#   if [[ -n "${PF_PID:-}" ]]; then
#     log "Stopping port-forward (PID ${PF_PID})..."
#     kill "${PF_PID}" 2>/dev/null || true
#   fi
# }
# trap cleanup EXIT

# ─────────────────────────────────────────────────────────────
# 1. Start port-forward (run manually before executing this script)
# ─────────────────────────────────────────────────────────────
# kubectl port-forward svc/registry -n registry 5000:5000
# log "Starting port-forward: svc/${REGISTRY_SVC} -n ${REGISTRY_NS}  ${REGISTRY_PORT}:5000"
# kubectl port-forward "svc/${REGISTRY_SVC}" -n "${REGISTRY_NS}" "${REGISTRY_PORT}:5000" &>/tmp/pf-registry.log &
# PF_PID=$!
# log "Port-forward PID: ${PF_PID}"

# ─────────────────────────────────────────────────────────────
# 2. Wait for registry to be reachable
# ─────────────────────────────────────────────────────────────
log "Waiting for registry to be reachable at http://${REGISTRY_URL}/v2/ ..."
MAX_WAIT=30
WAITED=0
until curl -sf "http://${REGISTRY_URL}/v2/" &>/dev/null; do
  if (( WAITED >= MAX_WAIT )); then
    err "Registry not reachable after ${MAX_WAIT}s. Port-forward log:"
    cat /tmp/pf-registry.log
    exit 1
  fi
  sleep 2
  (( WAITED += 2 ))
done
ok "Registry is live at http://${REGISTRY_URL}/v2/"

# ─────────────────────────────────────────────────────────────
# 3. Push images
# ─────────────────────────────────────────────────────────────
PUSHED=0
FAILED=0

for target_tag in "${!IMAGES[@]}"; do
  source_image="${IMAGES[$target_tag]}"
  dest_image="${REGISTRY_URL}/${target_tag}"

  echo ""
  log "────────────────────────────────────────────"
  log "Source : ${source_image}"
  log "Target : ${dest_image}"

  # Check source image exists locally
  if ! docker image inspect "${source_image}" &>/dev/null; then
    warn "Source image not found locally, skipping: ${source_image}"
    (( FAILED += 1 ))
    continue
  fi

  # Re-tag only if source and dest differ
  if [[ "${source_image}" != "${dest_image}" ]]; then
    log "Tagging ${source_image} -> ${dest_image}"
    docker tag "${source_image}" "${dest_image}"
  fi

  # Push
  log "Pushing ${dest_image} ..."
  if docker push "${dest_image}"; then
    ok "Pushed: ${dest_image}"
    (( PUSHED += 1 ))
  else
    err "Failed to push: ${dest_image}"
    (( FAILED += 1 ))
  fi
done

# ─────────────────────────────────────────────────────────────
# 4. Summary + catalog
# ─────────────────────────────────────────────────────────────
echo ""
log "══════════════════════════════════════════════"
log "Done.  Pushed: ${PUSHED}  |  Failed/Skipped: ${FAILED}"
log "══════════════════════════════════════════════"
echo ""
log "Images currently in registry catalog:"
curl -sf "http://${REGISTRY_URL}/v2/_catalog" | python3 -m json.tool 2>/dev/null || \
  curl -sf "http://${REGISTRY_URL}/v2/_catalog"
