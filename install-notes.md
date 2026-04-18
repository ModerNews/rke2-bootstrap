# RKE2 Installation Notes

> [!IMPORTANT]
> Each hostname has to be unique in the cluster range.

## Install order

```mermaid
flowchart LR
    A[Pre-config] --> B[master-init]
    B -->|VIP live| C[master-join ×2]
    C --> D[Workers]
```

---

## Automated Install

The Ansible playbook mirrors the manual bootstrap order and exposes each stage through tags.
Preflight checks always run first, while `master-join` and `workers` also refresh bootstrap
artifacts from the first master before proceeding.

```mermaid
flowchart LR
    A[Preflight] --> B[Host prep]
    B --> C[master-init]
    C --> D[bootstrap-artifacts]
    D --> E[master-join ×2<br/>serial: 1]
    E --> F[Workers ×N<br/>parallel]
```

### Setup

Install the `kubernetes` Python library via your system package manager — pip is not sufficient as it needs to be available system-wide for Ansible's delegate_to tasks:

```sh
# Arch
sudo pacman -S python-kubernetes
# Debian/Ubuntu
sudo apt install python3-kubernetes
# RHEL/Fedora
sudo dnf install python3-kubernetes
```

Then install Ansible collections:

```sh
ansible-galaxy collection install -r collections/requirements.yml
```

### Full run

```sh
ansible-playbook playbooks/main.yaml
```

### Stage runs

```sh
ansible-playbook playbooks/main.yaml --tags preflight
ansible-playbook playbooks/main.yaml --tags host_prep
ansible-playbook playbooks/main.yaml --tags master_init
ansible-playbook playbooks/main.yaml --tags master_join
ansible-playbook playbooks/main.yaml --tags workers
```

> [!NOTE]
> `master_join` and `workers` depend on artifacts collected from the first master.
> The playbook refreshes those artifacts automatically before running either stage.

> [!NOTE]
> After rebuilding VMs, SSH host keys change and preflight will fail with `Host key verification failed`.
> Pass `-e refresh_host_keys=true` to clear stale entries and re-scan before connecting:
> ```sh
> ansible-playbook playbooks/main.yaml --tags preflight -e refresh_host_keys=true
> ```

---

## Pre-config

> [!NOTE]
> SELinux and system params should be handled by the RKE2 installer. You can validate or set them manually if needed.

**Kernel modules**

```sh
cat > /etc/modules-load.d/rke2.conf << 'EOF'
br_netfilter
overlay
EOF
modprobe br_netfilter overlay
```

**Sysctl**

```sh
cat > /etc/sysctl.d/99-rke2.conf << 'EOF'
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF
sysctl --system
```

**NetworkManager — exclude Cilium interfaces**

```sh
cat > /etc/NetworkManager/conf.d/99-cilium.conf << 'EOF'
[keyfile]
unmanaged-devices=interface-name:cilium*;interface-name:lxc*
EOF
systemctl reload NetworkManager
```

**Disable swap**

```sh
swapoff -a
sed -i '/swap/d' /etc/fstab
```

---

## First master — `master-init`

### Step 1 — Hostname

```sh
hostnamectl set-hostname master1
```

### Step 2 — Installer

```sh
curl -sfL https://get.rke2.io | sh -
```

### Step 3 — [Pre-config](#pre-config)

### Step 4 — Config

Paste `master-init.yaml` into `/etc/rancher/rke2/config.yaml`. Don't forget to set `node-ip` & `advertise-address`.

### Step 5 — Manifests

> [!IMPORTANT]
> Do this before starting the service. With `cni: none` and `disable-kube-proxy: true`, the node will stay `NotReady` until a CNI is present.

- `cilium.yaml` → `/var/lib/rancher/rke2/server/manifests/`
- `kube-vip.yaml` → `/var/lib/rancher/rke2/agent/pod-manifests/`

### Step 6 — Start

```sh
systemctl enable --now rke2-server
journalctl -u rke2-server -f
```

You will see some errors — that's expected. Time has to pass before dependencies are pulled and the etcd pod can be spawned. Wait until the VIP is live before proceeding to `master-join` nodes.

---

## Remaining masters — `master-join`

Repeat steps 1–6 per node.

### Step 1 — Hostname

```sh
hostnamectl set-hostname master2  # adjust per node
```

### Step 2 — Installer

```sh
curl -sfL https://get.rke2.io | sh -
```

### Step 3 — [Pre-config](#pre-config)

### Step 4 — Config

Paste `master-join.yaml` into `/etc/rancher/rke2/config.yaml`. Don't forget to set `node-ip` & `advertise-address`.

### Step 5 — Manifests

> [!IMPORTANT]
> Same requirement as `master-init` — manifests must be in place before starting.

- `kube-vip.yaml` → `/var/lib/rancher/rke2/agent/pod-manifests/`

### Step 6 — Start

```sh
systemctl enable --now rke2-server
journalctl -u rke2-server -f
```

Node should reconcile with the cluster in short time.

---

## Workers

Repeat steps 1–5 per node.

### Step 1 — Hostname

```sh
hostnamectl set-hostname worker1  # adjust per node
```

### Step 2 — Installer

```sh
curl -sfL https://get.rke2.io | INSTALL_RKE2_TYPE="agent" sh -
```

### Step 3 — [Pre-config](#pre-config)

### Step 4 — Config

Paste `worker.yaml` into `/etc/rancher/rke2/config.yaml`. Don't forget to set `node-ip`.

### Step 5 — Start

```sh
systemctl enable --now rke2-agent
journalctl -u rke2-agent -f
```

Node should reconcile with the cluster in short time.

---

## ArgoCD Bootstrap

### Step 1 — Install ArgoCD (stub)

```sh
kubectl create namespace argocd
cd infra-helm/ArgoCD
helm dependency update
helm install argocd . -n argocd -f <path-to-rke2-bootstrap>/argocd/values.bootstrap.yaml
```

### Step 2 — Apply repository secret

```sh
kubectl create secret generic infra-helm-repo -n argocd \
  --from-literal=type=git \
  --from-literal=url=https://github.com/WMS-DEV/infra-helm.git \
  --from-literal=githubAppID=<app-id> \
  --from-literal=githubAppInstallationID=<installation-id> \
  --from-file=githubAppPrivateKey=<path/to/github-app.pem>

kubectl label secret infra-helm-repo -n argocd \
  argocd.argoproj.io/secret-type=repository
```

> [!IMPORTANT]
> This must be applied before the bootstrap root app, otherwise ArgoCD cannot pull from the repo.

### Step 3 — Apply bootstrap root app

```sh
kubectl apply -f argocd/bootstrap-roots/tools.yaml
```

ArgoCD will now sync waves automatically. Monitor progress:

```sh
kubectl get applications -n argocd -w
```

### Step 3.5 — Reconfigure Vault Kubernetes auth

> [!IMPORTANT]
> Do this after wave 1 (VSO) is healthy but before wave 2 (ceph-csi) syncs.
> Vault's Kubernetes auth backend must point at this cluster — it will still hold
> the previous cluster's CA and API server from the last bootstrap.

```sh
# Get new cluster CA cert and API server
kubectl config view --raw -o jsonpath='{.clusters[0].cluster.server}'
kubectl config view --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | base64 -d > /tmp/k8s-ca.crt

# Create a non-expiring token reviewer secret for VSO's service account
# (kubectl create token caps at 1h regardless of --duration; SA token secrets do not expire)
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: vault-reviewer-token
  namespace: hashicorp-vault
  annotations:
    kubernetes.io/service-account.name: vault-secrets-provider
type: kubernetes.io/service-account-token
EOF

TOKEN=$(kubectl get secret vault-reviewer-token -n hashicorp-vault -o jsonpath='{.data.token}' | base64 -d)

# Reconfigure
vault write auth/kubernetes/config \
  kubernetes_host=https://<api-server>:6443 \
  kubernetes_ca_cert=@/tmp/k8s-ca.crt \
  token_reviewer_jwt=$TOKEN
```

### Step 4 — Flip bootstrap label

Once all waves are healthy, update the cluster secret to trigger ApplicationSets:

```sh
kubectl label secret tools-k8s-internal-wmsdev-pl -n argocd bootstrap-stage=ready --overwrite
```
