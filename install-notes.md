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
