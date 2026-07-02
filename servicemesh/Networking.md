# End-to-end TLS with OpenShift Routes + Istio ingress gateway (wildcard)

**Goal.** Expose a workload through an **OpenShift HAProxy Route** *and* the
**Istio ingress gateway**, with the route being a **wildcard**, so that **every
hop is encrypted**:

```
client ──TLS──▶ HAProxy router ──TLS──▶ istio-ingressgateway ──mTLS──▶ workload
   hop 1                hop 2                       hop 3
```

This was built and verified live on cluster **hub** (`api.hub.k8socp.com`,
OpenShift 4.21.9, OSSM 3.3.3 / Istio 1.28.5). Both router termination models are
shown side by side so you can pick one:

| Variant | Route termination | Who terminates the *client* TLS | Router→gateway leg | Gateway→workload leg |
|---|---|---|---|---|
| **Passthrough** | `passthrough` | the **istio gateway** (router never decrypts) | same TLS stream, SNI-routed | Istio mTLS |
| **Reencrypt** | `reencrypt` | the **router**, then re-encrypts | new TLS, router validates gateway cert | Istio mTLS |

Both satisfy "all three hops encrypted." Passthrough gives the strongest "the
router can never see plaintext" story; reencrypt lets the router inspect/route
L7 and re-encrypt. Self-signed certs are used throughout (swap for cert-manager
or a real CA in production).

---

## Why a wildcard works here

* The route uses `wildcardPolicy: Subdomain`. A route with host
  `gw.pass.tlsdemo.apps.hub.k8socp.com` then admits **`*.pass.tlsdemo.apps.hub.k8socp.com`** —
  any left-most label is matched by the one route.
* The default IngressController must allow wildcard routes. On `hub` it already
  does:

  ```console
  $ oc -n openshift-ingress-operator get ingresscontroller default \
      -o jsonpath='{.spec.routeAdmission.wildcardPolicy}'
  WildcardsAllowed
  ```

  If yours doesn't, set it:

  ```console
  oc -n openshift-ingress-operator patch ingresscontroller default --type=merge \
    -p '{"spec":{"routeAdmission":{"wildcardPolicy":"WildcardsAllowed"}}}'
  ```
* DNS: anything under `*.apps.hub.k8socp.com` already resolves to the router, so
  `<anything>.pass.tlsdemo.apps.hub.k8socp.com` lands on HAProxy with no extra
  DNS records.
* The gateway's serving certificate is a **wildcard** cert (SANs
  `*.pass.tlsdemo...` and `*.reenc.tlsdemo...`), so any subdomain validates.

---

## Two gotchas we hit (read these — they are the whole reason this doc exists)

1. **Istio ≥ 1.28 gates `credentialName` secret access (RBAC).**
   A gateway that loads its TLS cert by `credentialName` reads it over SDS, and
   istiod authorizes the read with a SubjectAccessReview against the **gateway
   pod's ServiceAccount**. Without an explicit Role/RoleBinding you get:

   ```
   proxy istio-ingressgateway/<ns> attempted to access unauthorized certificates
   gw-wildcard-cert: ... is not authorized to read secrets
   ```

   …the `:8443` listener comes up with **no certificate**, and every request
   fails (TLS `unexpected eof` on passthrough, `503` on reencrypt). Fix =
   `manifests/05-gateway-secret-rbac.yaml`.

2. **The OpenShift router sends NO SNI on the reencrypt backend leg.**
   For a `reencrypt` route, HAProxy connects to the gateway with
   `ssl verify required` but **without** an `sni` parameter. If the Istio
   `Gateway` only has SNI-scoped servers (`hosts: ["*.reenc...."]`), the no-SNI
   handshake matches no filter chain → backend marked down → **503**. Fix = give
   the `Gateway` a **default/catch-all** server (`hosts: ["*"]`) with the same
   cert, so it presents a certificate even when no SNI is supplied. (Passthrough
   is unaffected: the client's original SNI is preserved through HAProxy.)

---

## How it's wired

```
                       *.pass...  (passthrough route)
client ──TLS──▶ HAProxy ──raw TLS (mode tcp, SNI-routed, no decrypt)──┐
                       *.reenc... (reencrypt route)                   │
client ──TLS──▶ HAProxy ──terminate, then NEW verified TLS───────────┤
                                                                      ▼
                                       istio-ingressgateway  Service :8443
                                       (Istio Gateway, SIMPLE TLS terminate,
                                        wildcard cert via SDS)
                                                      │ HTTP route by Host header
                                                      ▼  (auto-mTLS, STRICT)
                                       backend  Service :8080  (nginx + sidecar)
```

Both routes point at the **same** `istio-ingressgateway` Service on port `https`
(8443). The Istio `Gateway` terminates the external TLS and the
`VirtualService` routes by HTTP `Host` to `backend`. `PeerAuthentication: STRICT`
forces the gateway→workload hop to be mTLS.

---

## Apply it

Files live in `~/tls-e2e-demo/` on the hub jump host.

```bash
cd ~/tls-e2e-demo

# 0. (one-time) install OSSM 3 + bring up istiod/CNI if not already present
#    oc apply the Subscription for servicemeshoperator3, then ensure the
#    namespaces the Istio/IstioCNI CRs reference exist (istio-system, istio-cni).

# 1. self-signed CA + wildcard server cert (SANs cover both subdomains)
./gen-certs.sh

# 2. namespace, backend, gateway, Gateway, VirtualService, STRICT mTLS
oc apply -f manifests/00-core.yaml

# 3. gateway TLS secret (referenced by Gateway.credentialName)
oc -n tls-e2e-demo create secret tls gw-wildcard-cert \
  --cert=certs/gw.crt --key=certs/gw.key

# 4. RBAC so the gateway SA may read that secret over SDS  (gotcha #1)
oc apply -f manifests/05-gateway-secret-rbac.yaml

# 5. the two wildcard routes
oc apply -f manifests/10-route-passthrough.yaml
oc -n tls-e2e-demo create route reencrypt tlsdemo-reencrypt \
  --service=istio-ingressgateway --port=https \
  --hostname=gw.reenc.tlsdemo.apps.hub.k8socp.com --wildcard-policy=Subdomain \
  --cert=certs/gw.crt --key=certs/gw.key --ca-cert=certs/ca.crt \
  --dest-ca-cert=certs/ca.crt
```

Key manifest excerpts:

* **Gateway** (note the catch-all default server — gotcha #2):

  ```yaml
  apiVersion: networking.istio.io/v1
  kind: Gateway
  metadata: { name: tlsdemo-gateway, namespace: tls-e2e-demo }
  spec:
    selector: { istio: ingressgateway }
    servers:
      - port: { number: 8443, name: https, protocol: HTTPS }
        tls: { mode: SIMPLE, credentialName: gw-wildcard-cert }
        hosts: ["*.pass.tlsdemo.apps.hub.k8socp.com", "*.reenc.tlsdemo.apps.hub.k8socp.com"]
      - port: { number: 8443, name: https-default, protocol: HTTPS }   # no-SNI default
        tls: { mode: SIMPLE, credentialName: gw-wildcard-cert }
        hosts: ["*"]
  ```

* **PeerAuthentication** (makes hop 3 mTLS-only):

  ```yaml
  apiVersion: security.istio.io/v1
  kind: PeerAuthentication
  metadata: { name: default, namespace: tls-e2e-demo }
  spec: { mtls: { mode: STRICT } }
  ```

The ingress gateway itself is the standard **gateway-injection** Deployment
(`inject.istio.io/templates: gateway`, `image: auto`, container port 8443) — the
same pattern as the repo's `charts/spoke-ingress-gateway`. Full YAML in
`manifests/00-core.yaml`.

---

## Verification (this is the live proof captured on hub)

**Hop 1+2 — both wildcard routes return the real backend over TLS** (arbitrary
left-most labels, proving the wildcard):

```console
$ curl --cacert certs/ca.crt https://foo.pass.tlsdemo.apps.hub.k8socp.com/
TLS-E2E-DEMO backend reached over the mesh. hop3=mTLS-OK      # http 200, tls verify 0

$ curl --cacert certs/ca.crt https://alpha.reenc.tlsdemo.apps.hub.k8socp.com/
TLS-E2E-DEMO backend reached over the mesh. hop3=mTLS-OK      # http 200, tls verify 0
```

**Hop 2 — the router really does NOT decrypt on passthrough.** Its HAProxy
backend is plain TCP with no cert; the reencrypt one terminates+re-verifies:

```console
# passthrough -> mode tcp, raw bytes to :8443, no ssl on the server line
backend be_tcp:tls-e2e-demo:tlsdemo-passthrough
  server pod:...:8443 10.128.0.144:8443 weight 1

# reencrypt -> mode http, new TLS to the gateway, cert validated against dest CA
backend be_secure:tls-e2e-demo:tlsdemo-reencrypt
  server pod:...:8443 10.128.0.144:8443 ssl verify required ca-file .../tlsdemo-reencrypt.pem
```

**Hop 3 — gateway→workload is mTLS-only.** A plaintext client from *outside* the
mesh to the backend pod is rejected; only the gateway's sidecar (mTLS) gets
through:

```console
$ oc -n default run plain-probe --image=curlimages/curl --rm -i --restart=Never -- \
    curl -sS http://<backend-pod-ip>:8080/
curl: (56) Recv failure: Connection reset by peer      # STRICT mTLS refuses plaintext
```

All three checks passed on hub on 2026-06-05.

---

## Production notes

* **Certs:** replace the self-signed CA with cert-manager (or your PKI). The
  gateway cert just needs SANs covering the wildcard subdomain(s); reference it
  via `credentialName`. For reencrypt, the route's `destinationCACertificate`
  must be the CA that signed the **gateway** cert.
* **Don't forget the secret-reader RBAC** in every namespace that runs a gateway
  with `credentialName` (gotcha #1).
* **Keep the catch-all gateway server** if you use reencrypt (gotcha #2). If you
  only ever use passthrough, you can drop it and keep the SNI-scoped server only.
* **Gateway scope:** here the gateway lives in the app namespace
  (`tls-e2e-demo`). A shared/central ingress gateway works too — put the cert
  secret + RBAC in the gateway's namespace and use a `ReferenceGrant`/exported
  `Gateway` as appropriate.

---

## Teardown

```bash
oc delete ns tls-e2e-demo
# plus the plain-probe pod if it lingers:  oc -n default delete pod plain-probe --ignore-not-found
```
