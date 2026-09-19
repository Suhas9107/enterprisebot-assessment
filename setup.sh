#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLUSTER_NAME="enterprisebot"
NAMESPACE="demo"
IMAGE_REPOSITORY="demo-service"
IMAGE_TAG="0.1.0"
IMAGE="${IMAGE_REPOSITORY}:${IMAGE_TAG}"

command -v docker >/dev/null || { echo "docker is required" >&2; exit 1; }
command -v kind >/dev/null || { echo "kind is required" >&2; exit 1; }
command -v kubectl >/dev/null || { echo "kubectl is required" >&2; exit 1; }
command -v helm >/dev/null || { echo "helm is required" >&2; exit 1; }

if ! kind get clusters | grep -qx "${CLUSTER_NAME}"; then
  echo "Creating kind cluster ${CLUSTER_NAME}..."

  cat <<EOF | kind create cluster --name "${CLUSTER_NAME}" --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    labels:
      ingress-ready: "true"
    extraPortMappings:
      - containerPort: 80
        hostPort: 8080
        protocol: TCP
      - containerPort: 443
        hostPort: 8443
        protocol: TCP
EOF

else
  echo "Reusing kind cluster ${CLUSTER_NAME}"
fi

kubectl cluster-info --context "kind-${CLUSTER_NAME}" >/dev/null
kubectl config use-context "kind-${CLUSTER_NAME}" >/dev/null

if ! kubectl get namespace ingress-nginx >/dev/null 2>&1; then
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.12.1/deploy/static/provider/kind/deploy.yaml
fi
kubectl rollout status deployment/ingress-nginx-controller -n ingress-nginx --timeout=180s

docker build -t "${IMAGE}" "${ROOT_DIR}/service"
kind load docker-image "${IMAGE}" --name "${CLUSTER_NAME}"

helm upgrade --install demo "${ROOT_DIR}/chart" \
  --namespace "${NAMESPACE}" \
  --create-namespace \
  --set image.repository="${IMAGE_REPOSITORY}" \
  --set image.tag="${IMAGE_TAG}"

kubectl rollout status deployment/demo-service -n "${NAMESPACE}" --timeout=180s

echo "Setup complete."
