#!/usr/bin/env bash
#
# Deploy the Productivity OS API to Cloud Run.
#
# One-command release: builds the linux/amd64 image from the working tree,
# pushes it to Artifact Registry, deploys it to Cloud Run (existing env and
# secret config preserved), then verifies the health endpoint.
#
# Usage:
#   ./scripts/deploy-api.sh            # build + push + deploy + health check
#   ./scripts/deploy-api.sh --check    # validate local config only, no build
#
# Overrides (env vars): GCLOUD_PROJECT, CLOUD_RUN_REGION, CLOUD_RUN_SERVICE,
# IMAGE_REPO, IMAGE_TAG.
set -euo pipefail

PROJECT="${GCLOUD_PROJECT:-productivity-os-prod}"
REGION="${CLOUD_RUN_REGION:-asia-southeast1}"
SERVICE="${CLOUD_RUN_SERVICE:-productivity-os-api}"
IMAGE_REPO="${IMAGE_REPO:-asia-southeast1-docker.pkg.dev/productivity-os-prod/productivity-os/productivity-os-api}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
IMAGE="$IMAGE_REPO:$IMAGE_TAG"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
  sed -n '2,14p' "$0" | sed 's/^# \{0,1\}//'
  exit 0
}

case "${1:-}" in
  --help) usage ;;
  --check) CHECK_ONLY=1 ;;
  "") CHECK_ONLY=0 ;;
  *)
    echo "ERROR: unknown argument '$1' (see --help)" >&2
    exit 1
    ;;
esac

cd "$ROOT_DIR"

echo "==> Project:  $PROJECT"
echo "==> Region:   $REGION"
echo "==> Service:  $SERVICE"
echo "==> Image:    $IMAGE"

if ! command -v gcloud >/dev/null; then
  echo "ERROR: gcloud not found — install Google Cloud CLI" >&2
  exit 1
fi
if ! command -v docker >/dev/null; then
  echo "ERROR: docker not found — start Docker Desktop" >&2
  exit 1
fi

ACTUAL_PROJECT="$(gcloud config get-value project 2>/dev/null || true)"
if [ "$ACTUAL_PROJECT" != "$PROJECT" ]; then
  echo "ERROR: gcloud project is '$ACTUAL_PROJECT', expected '$PROJECT'" >&2
  echo "       fix with: gcloud config set project $PROJECT" >&2
  exit 1
fi

if ! gcloud run services describe "$SERVICE" --region "$REGION" --format='value(status.url)' >/dev/null 2>&1; then
  echo "ERROR: Cloud Run service '$SERVICE' not found in $REGION" >&2
  exit 1
fi

if ! git diff --quiet --exit-code; then
  echo "WARNING: uncommitted changes present — image will include working-tree state."
fi

if [ "$CHECK_ONLY" -eq 1 ]; then
  echo "==> Config OK — ready to deploy"
  exit 0
fi

echo "==> Authenticating docker for Artifact Registry"
gcloud auth configure-docker "$REGION-docker.pkg.dev" --quiet >/dev/null

echo "==> Building $IMAGE (linux/amd64)"
docker build --platform=linux/amd64 -t "$IMAGE" .

echo "==> Pushing $IMAGE"
docker push "$IMAGE"

echo "==> Deploying $SERVICE"
gcloud run deploy "$SERVICE" --image "$IMAGE" --region "$REGION" --platform managed --quiet

URL="$(gcloud run services describe "$SERVICE" --region "$REGION" --format='value(status.url)')"
echo "==> Waiting for $URL/api/v1/health"
for _ in $(seq 1 15); do
  if curl -fsS --max-time 10 "$URL/api/v1/health" >/dev/null 2>&1; then
    echo "==> Deploy OK: $URL"
    echo "==> Frontend: push to main triggers Vercel (no action needed here)."
    exit 0
  fi
  sleep 3
done

echo "ERROR: health check failed after deploy: $URL/api/v1/health" >&2
exit 1
