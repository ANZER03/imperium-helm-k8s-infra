# Kong API Gateway — Deployment Documentation

> **Date:** 2026-07-03
> **Cluster:** k3s (3-node: `k3s-server`, `k3s-agent-1`, `k3s-agent-2`)
> **Namespace:** `imperium-news-ns`
> **Kong Operator version:** 1.6 (chart `gateway-operator:0.6.1`)
> **Helm release:** `imperium-streaming-news-processing` (umbrella chart)

---

## 1. Why This Approach (Design Rationale)

### The "Modern Way" — Kong Gateway Operator + Kubernetes Gateway API

There are two ways to deploy Kong on Kubernetes:

| Approach | Method | Status |
|---|---|---|
| **Legacy** | `kong/ingress-controller` Helm chart + Kubernetes `Ingress` resource | Still works, but deprecated pattern |
| **Modern** ✅ | **Kong Gateway Operator (KGO)** + **Kubernetes Gateway API** CRDs | Standard since Kong 3.x, cloud-native |

This deployment uses the **modern approach**:

- **Kubernetes Gateway API** — a SIG-networking standard (not Kong-specific). Uses `GatewayClass`, `Gateway`, `HTTPRoute` resources instead of the legacy `Ingress`. Vendor-neutral and more expressive.
- **Kong Gateway Operator (KGO)** — an operator that watches `Gateway` CRs and automatically provisions the Kong proxy (DataPlane) and admin API (ControlPlane) pods. No manual management of Kong Deployment/Service resources needed.

### Integration with the Umbrella Chart

Kong is deployed as a **subchart** of the existing umbrella chart `imperium-streaming-news-processing`, following the exact same pattern as other local subcharts (`imperium-frontend`, `imperium-news-app`, etc.):

- Gated by `kong-gateway.enabled: true` in `values.yaml`
- Local subchart in `charts/kong-gateway/` that wraps the upstream `kong/gateway-operator` chart
- Toggled on/off with a single values flag

---

## 2. Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                     imperium-news-ns                         │
│                                                              │
│  ┌───────────────────────────────────────────────────────┐  │
│  │            Kong Gateway Operator (KGO)                │  │
│  │          kong-gw-controller-manager pod               │  │
│  │                                                       │  │
│  │  Watches: GatewayClass, Gateway CRs                   │  │
│  │  Provisions: ControlPlane + DataPlane automatically   │  │
│  └───────────────────────┬───────────────────────────────┘  │
│                          │ auto-creates                      │
│            ┌─────────────┴──────────────┐                   │
│            ▼                            ▼                    │
│  ┌─────────────────┐        ┌──────────────────────┐        │
│  │  ControlPlane   │        │     DataPlane         │        │
│  │  (Kong Admin)   │        │   (Kong Proxy)        │        │
│  │  port 8444      │        │   port 80 (HTTP)      │        │
│  └─────────────────┘        └──────────┬────────────┘        │
│                                        │                     │
└────────────────────────────────────────┼─────────────────────┘
                                         │
                          ┌──────────────▼──────────────┐
                          │  LoadBalancer Service        │
                          │  dataplane-ingress-kong-*    │
                          │  172.18.0.34:80              │
                          │  NodePort: 31607             │
                          └──────────────────────────────┘
                                         │
                                    [Client Traffic]
```

### Resource Ownership

| Resource | Created by | Kind |
|---|---|---|
| `GatewayClass: kong` | Helm subchart template | cluster-scoped |
| `Gateway: kong` | Helm subchart template | namespaced |
| `controlplane-kong-*` pod | KGO (auto) | ControlPlane CR → Deployment |
| `dataplane-kong-*` pod | KGO (auto) | DataPlane CR → Deployment |
| `dataplane-ingress-*` svc | KGO (auto) | Service (LoadBalancer) |
| `kong-gw-*` operator resources | Helm (upstream chart) | RBAC, Deployment, Services |

---

## 3. Files Created / Modified

### New: `imperium-streaming-news-processing/charts/kong-gateway/`

A local Helm subchart that wraps the upstream `kong/gateway-operator` chart and adds the `GatewayClass` + `Gateway` resources on top.

#### `charts/kong-gateway/Chart.yaml`

```yaml
apiVersion: v2
name: kong-gateway
description: |
  Kong Gateway Operator subchart for Imperium.
  Deploys Kong Gateway Operator (KGO v1.6) which manages the Kong proxy
  lifecycle via Kubernetes Gateway API standard resources.
type: application
version: 0.1.0
appVersion: "1.6"

dependencies:
  - name: gateway-operator
    version: 0.6.1
    repository: "https://charts.konghq.com"
```

#### `charts/kong-gateway/values.yaml`

```yaml
gateway-operator:
  # Short name override — prevents exceeding the 63-char k8s resource name limit
  # when the umbrella release "imperium-streaming-news-processing" prefixes names.
  fullnameOverride: "kong-gw"

  image:
    tag: "1.6"

  env:
    GATEWAY_OPERATOR_ANONYMOUS_REPORTS: "false"

  resources:
    requests:
      cpu: 100m
      memory: 128Mi
    limits:
      cpu: 500m
      memory: 256Mi

proxy:
  serviceType: LoadBalancer
```

> **IMPORTANT:** `fullnameOverride: "kong-gw"` is critical. Without it, the upstream chart generates
> service names prefixed by `imperium-streaming-news-processing-gateway-operator-*`
> which exceeds Kubernetes' 63-character DNS name limit and causes the deployment to fail.

#### `charts/kong-gateway/templates/gatewayclass.yaml`

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: kong
spec:
  controllerName: konghq.com/gateway-operator
```

Cluster-scoped resource. Registers `kong` as a gateway implementation backed by KGO.
Any `Gateway` that sets `gatewayClassName: kong` will be managed by this operator.

#### `charts/kong-gateway/templates/gateway.yaml`

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: kong
  namespace: {{ .Release.Namespace }}
  annotations:
    konghq.com/gatewayclass-unmanaged: "true"
spec:
  gatewayClassName: kong
  listeners:
    - name: proxy
      protocol: HTTP
      port: 80
```

This is the resource KGO watches. When it sees this, it automatically provisions the ControlPlane
and DataPlane pods + the `dataplane-ingress-*` LoadBalancer Service.

---

### Modified: Umbrella Chart

#### `Chart.yaml` — added dependency

```yaml
  - name: kong-gateway
    version: 0.1.0
    repository: "file://charts/kong-gateway"
    condition: kong-gateway.enabled
```

#### `values.yaml` — added values block

```yaml
kong-gateway:
  enabled: true
  gateway-operator:
    env:
      GATEWAY_OPERATOR_ANONYMOUS_REPORTS: "false"
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
      limits:
        cpu: 500m
        memory: 256Mi
```

---

## 4. Step-by-Step: What Was Done

### Step 1 — Install Kubernetes Gateway API CRDs

The Kubernetes Gateway API CRDs are not bundled with k3s. They must be installed from the
official SIG-networking releases.

```bash
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.3.0/standard-install.yaml
```

**CRDs installed:**
- `gatewayclasses.gateway.networking.k8s.io`
- `gateways.gateway.networking.k8s.io`
- `httproutes.gateway.networking.k8s.io`
- `grpcroutes.gateway.networking.k8s.io`
- `referencegrants.gateway.networking.k8s.io`

### Step 2 — Add Kong Helm Repository

```bash
helm repo add kong https://charts.konghq.com
helm repo update kong
```

Latest chart found: `kong/gateway-operator:0.6.1` (app version `1.6`).

### Step 3 — Create the `kong-gateway` Subchart

Created directory structure:

```
imperium-streaming-news-processing/
└── charts/
    └── kong-gateway/
        ├── Chart.yaml              # wraps kong/gateway-operator:0.6.1
        ├── values.yaml             # fullnameOverride + resource limits
        └── templates/
            ├── gatewayclass.yaml   # GatewayClass: kong
            └── gateway.yaml        # Gateway: kong (HTTP/80)
```

### Step 4 — Fetch Upstream Dependency into Subchart

```bash
cd imperium-streaming-news-processing/charts/kong-gateway
helm dependency update .
```

Downloads `gateway-operator-0.6.1.tgz` into `charts/kong-gateway/charts/`.

### Step 5 — Wire into Umbrella Chart

Added `kong-gateway` as a local `file://` dependency in the umbrella `Chart.yaml` and `values.yaml`,
then re-packaged:

```bash
helm dependency update ./imperium-streaming-news-processing
```

> **Critical workflow rule:** After editing ANY file inside `charts/kong-gateway/`, you MUST re-run
> `helm dependency update ./imperium-streaming-news-processing` before deploying. The umbrella
> uses the packaged `kong-gateway-0.1.0.tgz` in its `charts/` dir — NOT the live directory.
> Forgetting this causes stale values to be deployed silently.

### Step 6 — Install Kong Operator CRDs (Prerequisite)

The Kong Gateway Operator requires its own CRDs (`DataPlane`, `ControlPlane`, `GatewayConfiguration`)
to exist before it can start. These are bundled inside the chart's `crds/` directory.

Helm only installs `crds/` on a **fresh `helm install`**, never on `helm upgrade`. Since this was
an upgrade of an existing release, the CRDs were skipped.

**Fix — extract and apply manually:**

```bash
# Extract CRDs from the packaged subchart
tar -xzf imperium-streaming-news-processing/charts/kong-gateway/charts/gateway-operator-0.6.1.tgz \
  -C /tmp gateway-operator/crds/custom-resource-definitions.yaml

# Apply with server-side strategy (required — CRDs exceed 262144-byte annotation limit)
kubectl apply --server-side -f /tmp/gateway-operator/crds/custom-resource-definitions.yaml
```

### Step 7 — Deploy

```bash
helm upgrade --install imperium-streaming-news-processing \
  ./imperium-streaming-news-processing \
  -n imperium-news-ns
```

Output: `Release "imperium-streaming-news-processing" has been upgraded. STATUS: deployed. REVISION: 124`

### Step 8 — Operator Pod Restart

After CRDs were registered, the crash-looping operator pod was deleted to force immediate restart:

```bash
kubectl delete pod -n imperium-news-ns -l app.kubernetes.io/name=gateway-operator
```

The operator came up cleanly, reconciled the `Gateway` CR, and auto-provisioned the ControlPlane
and DataPlane pods within seconds.

---

## 5. Troubleshooting — Issues Encountered and Resolved

### Issue 1: Wrong Gateway API release URL

- **Error:** `404 Not Found` when fetching `standard-channel.yaml`
- **Cause:** The file was renamed to `standard-install.yaml` in newer Gateway API releases
- **Fix:** Use `v1.3.0/standard-install.yaml`

### Issue 2: Kubernetes 63-char resource name limit

- **Error:** `Service "imperium-streaming-news-processing-gateway-operator-metrics-service" is invalid: metadata.name: must be no more than 63 characters` (67 chars)
- **Cause:** The upstream chart generates service names as `<release-name>-gateway-operator-*`. The umbrella release name `imperium-streaming-news-processing` is already very long.
- **Fix:** Set `fullnameOverride: "kong-gw"` in the subchart's `values.yaml` under the `gateway-operator:` key. Resources become `kong-gw-*` instead.

### Issue 3: Stale `.tgz` after values edit

- **Symptom:** `helm template` showed correct short names (`kong-gw-*`), but `helm upgrade` still failed with the long name.
- **Cause:** `helm template` reads from the live filesystem. `helm upgrade` uses the packaged `kong-gateway-0.1.0.tgz`. The `.tgz` was packed before `fullnameOverride` was added.
- **Fix:** Re-run `helm dependency update ./imperium-streaming-news-processing` to repack the subchart.
- **Verification:** `tar -xzf .../kong-gateway-0.1.0.tgz -O kong-gateway/values.yaml | grep fullnameOverride`

### Issue 4: Kong Operator CRDs not installed (CrashLoopBackOff)

- **Error in logs:** `failed to set up index "*v1beta1.ControlPlane[dataplane]": unable to retrieve the complete list of server APIs: gateway-operator.konghq.com/v1beta1: no matches`
- **Cause:** Helm skips `crds/` directories on `helm upgrade` by design. The operator's own CRDs weren't registered, so it crashed on startup.
- **Fix:** Manually extract and apply CRDs with `--server-side` before deploying.

### Issue 5: Large CRD client-side annotation limit

- **Error:** `CustomResourceDefinition "controlplanes.gateway-operator.konghq.com" is invalid: metadata.annotations: Too long: may not be more than 262144 bytes`
- **Cause:** Client-side `kubectl apply` stores the full manifest in a `last-applied-configuration` annotation. The Kong CRDs are too large for this.
- **Fix:** `kubectl apply --server-side` — the server tracks field manager state instead, bypassing the annotation size limit.

---

## 6. Live Cluster State

### Pods

```
NAME                                                    READY   STATUS    RESTARTS
kong-gw-controller-manager-5c95d5b7b6-xln9b           1/1     Running   0
controlplane-kong-jrmxm-2pc5m-677b999657-crdlb         1/1     Running   0
dataplane-kong-8d58k-kxx5b-57d9c9c689-r5wz5            1/1     Running   0
```

### GatewayClass

```
NAME   CONTROLLER                    ACCEPTED   AGE
kong   konghq.com/gateway-operator   True
```

### Gateway

```
NAME   CLASS   ADDRESS       PROGRAMMED
kong   kong    172.18.0.34   True
```

### Services

| Service | Type | Cluster IP | External IPs | Ports |
|---|---|---|---|---|
| `kong-gw` | ClusterIP | 10.43.125.115 | — | 8443/TCP |
| `kong-gw-metrics-service` | ClusterIP | 10.43.46.18 | — | 8443/TCP |
| `dataplane-ingress-kong-*` | **LoadBalancer** | 10.43.29.199 | 172.18.0.34,.35,.36 | **80:31607/TCP** |
| `dataplane-admin-kong-*` | ClusterIP (Headless) | None | — | 8444/TCP |
| `controlplane-webhook-kong-*` | ClusterIP | 10.43.247.147 | — | 8080/TCP |

### CRDs Installed

**Kubernetes Gateway API (5 CRDs):**

```
gatewayclasses.gateway.networking.k8s.io
gateways.gateway.networking.k8s.io
httproutes.gateway.networking.k8s.io
grpcroutes.gateway.networking.k8s.io
referencegrants.gateway.networking.k8s.io
```

**Kong Operator CRDs (30+ CRDs):**

```
controlplanes.gateway-operator.konghq.com
dataplanes.gateway-operator.konghq.com
gatewayconfigurations.gateway-operator.konghq.com
kongconsumers.configuration.konghq.com
kongplugins.configuration.konghq.com
kongroutes.configuration.konghq.com
kongservices.configuration.konghq.com
kongupstreams.configuration.konghq.com
kongvaults.configuration.konghq.com
... (and 20+ more)
```

---

## 7. Accessing Kong Proxy

The Kong proxy is exposed via a LoadBalancer service on the k3s nodes:

- **External IPs (k3s Klipper LB):** `172.18.0.34`, `172.18.0.35`, `172.18.0.36`
- **Port:** `80` (HTTP), NodePort `31607`

**Local port-forward (for development):**

```bash
KONG_SVC=$(kubectl get svc -n imperium-news-ns -o name | grep dataplane-ingress | cut -d/ -f2)
kubectl port-forward svc/$KONG_SVC -n imperium-news-ns 8000:80
```

**Test:**

```bash
curl http://localhost:8000
# {"message":"no Route matched with those values"}
```

A `404` from Kong means the proxy is working correctly — no routes are configured yet.

---

## 8. Next Steps — Adding HTTPRoutes

Routes use standard Kubernetes Gateway API `HTTPRoute` resources. No Kong-specific CRDs required.

### Route traffic to the backend API

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: imperium-news-app-route
  namespace: imperium-news-ns
spec:
  parentRefs:
    - name: kong
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /api
      backendRefs:
        - name: imperium-streaming-news-processing-imperium-news-app
          port: 8999
```

### Route traffic to the frontend

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: imperium-frontend-route
  namespace: imperium-news-ns
spec:
  parentRefs:
    - name: kong
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /
      backendRefs:
        - name: imperium-streaming-news-processing-imperium-frontend
          port: 3000
```

### Adding HTTPS (with cert-manager)

Add a second listener to `templates/gateway.yaml`:

```yaml
listeners:
  - name: proxy
    protocol: HTTP
    port: 80
  - name: proxy-tls
    protocol: HTTPS
    port: 443
    tls:
      mode: Terminate
      certificateRefs:
        - name: imperium-tls-cert   # a cert-manager Certificate Secret
          kind: Secret
```

---

## 9. Upgrade Checklist

When modifying the Kong subchart:

- [ ] Edit files in `charts/kong-gateway/`
- [ ] Run `helm dependency update ./imperium-streaming-news-processing` to repack
- [ ] Dry-run: `helm template imperium-streaming-news-processing ./imperium-streaming-news-processing -n imperium-news-ns | grep -E "GatewayClass|kind: Gateway|kong-gw"`
- [ ] Deploy: `helm upgrade --install imperium-streaming-news-processing ./imperium-streaming-news-processing -n imperium-news-ns`
- [ ] Verify: `kubectl get gateway kong -n imperium-news-ns` shows `PROGRAMMED: True`

When bumping Kong operator version:

- [ ] Update `gateway-operator` version in `charts/kong-gateway/Chart.yaml`
- [ ] Run `helm dependency update` inside `charts/kong-gateway/` to fetch new tgz
- [ ] Re-extract and re-apply CRDs with `--server-side` (new version may have changed CRDs)
- [ ] Re-run `helm dependency update` on the umbrella to repack
- [ ] Deploy
