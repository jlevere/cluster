# Elastic Stack on K3s with Fleet Server

This directory contains the configuration for deploying a complete Elastic Stack on K3s using ECK (Elastic Cloud on Kubernetes) with Fleet Server for managing Elastic Agents on Windows machines running in Proxmox.

## Environment

- **K3s Node**: `192.168.88.20` (single node cluster)
- **Proxmox Cluster**: `192.168.88.10-12` (Windows VMs run here)
- **LoadBalancer**: Traefik (built into K3s) provides external access
- **Fleet Server**: Will be accessible at `https://192.168.88.20:8220`

## Components

- **ECK Operator**: Manages Elasticsearch, Kibana, and Elastic Agent deployments
- **Elasticsearch**: Single-node cluster for homelab use
- **Kibana**: Web interface for Elasticsearch with Fleet management
- **Fleet Server**: Manages Elastic Agents running on Windows machines in Proxmox

## Deployment

### Prerequisites

1. K3s cluster running on `192.168.88.20`
2. ArgoCD deployed
3. Local-path storage provisioner (default in K3s)

### Deploy using Taskfile

```bash
# Deploy complete Elastic Stack
task elastic_deploy_all

# Or deploy step by step
task elastic_deploy_operator
task elastic_deploy_stack
task elastic_deploy_fleet

# Check status
task elastic_status

# View logs
task elastic_logs

# Cleanup
task elastic_cleanup
```

## Configuration Details

### Security

- **Authentication**: Enabled with default `elastic` user
- **TLS**: Enabled by default for all components
- **Fleet Server**: Uses LoadBalancer service for external access

### Storage

- **Elasticsearch**: 10GB persistent volume using local-path storage
- **Storage Class**: `local-path` (K3s default)

### Resources

- **Elasticsearch**: 1-2GB RAM, 0.5-1 CPU
- **Kibana**: 512MB-1GB RAM, 0.5-1 CPU
- **Fleet Server**: 512MB-1GB RAM, 0.2-0.5 CPU

## Accessing Services

### Kibana

1. Get the elastic user password:

   ```bash
   kubectl get secret quickstart-es-elastic-user -n elastic-system -o go-template='{{.data.elastic | base64decode}}'
   ```

2. Port-forward to Kibana:

   ```bash
   kubectl port-forward service/quickstart-kb-http 5601 -n elastic-system
   ```

3. Access Kibana at `https://localhost:5601`
   - Username: `elastic`
   - Password: (from step 1)

### Fleet Server

The Fleet Server will be accessible at: **`https://192.168.88.20:8220`**

This uses the K3s node IP with Traefik LoadBalancer to route traffic to the Fleet Server pod.

## Setting up Windows Agents

### 1. Configure Fleet Server in Kibana

**Important**: You must manually configure the Fleet Server host in Kibana:

1. Access Kibana → Fleet → Settings
2. Add Fleet Server host: `https://192.168.88.20:8220`
3. Save the configuration

### 2. Download Elastic Agent

Download the Windows Elastic Agent from the [official Elastic website](https://www.elastic.co/downloads/elastic-agent).

### 3. Create Agent Policy and Get Enrollment Token

1. In Kibana → Fleet → Agent policies
2. Create a new policy for Windows machines
3. Add integrations (Windows Event Logs, System metrics, etc.)
4. Copy the enrollment token

### 4. Install Agent on Windows VMs

Run on Windows machines in Proxmox (as Administrator):

```powershell
# Download and install
.\elastic-agent.exe install --url=https://192.168.88.20:8220 --enrollment-token=<TOKEN> --insecure
```

**Note**: Use `--insecure` flag since you're using self-signed certificates in your homelab.

## Network Flow

```
Windows VM (Proxmox) → 192.168.88.20:8220 → Traefik LoadBalancer → Fleet Server Pod
```

The Windows machines in your Proxmox cluster will connect directly to your K3s node IP address.

## Fleet Server Configuration

The Fleet Server is configured with:

- **External Access**: LoadBalancer service using Traefik
- **IP Address**: `192.168.88.20:8220` (your K3s node)
- **RBAC**: Proper permissions for Kubernetes monitoring
- **Security Context**: Runs as root for full system access

## Monitoring Windows Machines

Once agents are enrolled, you can:

1. **View Agents**: Kibana → Fleet → Agents
2. **Add Integrations**:

   - Windows Event Logs
   - System Metrics
   - Security Events
   - Custom logs

3. **Create Dashboards**: Kibana → Dashboard
4. **Set up Alerts**: Kibana → Stack Management → Rules

## Troubleshooting

### Check Component Status

```bash
kubectl get elasticsearch,kibana,agent -n elastic-system
```

### Verify Fleet Server Access

From a Windows machine, test connectivity:

```powershell
# Test if Fleet Server port is accessible
Test-NetConnection -ComputerName 192.168.88.20 -Port 8220
```

### View Logs

```bash
# ECK Operator
kubectl logs -l app.kubernetes.io/name=elastic-operator -n elastic-system

# Elasticsearch
kubectl logs -l elasticsearch.k8s.elastic.co/cluster-name=quickstart -n elastic-system

# Fleet Server
kubectl logs -l agent.k8s.elastic.co/name=fleet-server -n elastic-system
```

### Common Issues

1. **Fleet Server not accessible**:

   - Check if LoadBalancer service has external IP: `kubectl get svc fleet-server -n elastic-system`
   - Verify Traefik is running: `kubectl get pods -n kube-system | grep traefik`

2. **Agent enrollment fails**:

   - Verify Fleet Server URL is `https://192.168.88.20:8220` in Kibana
   - Check enrollment token is valid
   - Use `--insecure` flag for self-signed certificates

3. **Certificate issues**:

   - Always use `--insecure` flag for homelab setups
   - Fleet Server uses self-signed certificates by default

4. **Storage issues**:
   - Ensure local-path provisioner is working: `kubectl get storageclass`

## Production Considerations

For production use, consider:

- **Multi-node Elasticsearch cluster**
- **Proper TLS certificates** (Let's Encrypt, internal CA)
- **Resource limits and requests**
- **Backup and restore procedures**
- **Security hardening**
- **Monitoring and alerting**

## References

- [ECK Documentation](https://www.elastic.co/docs/deploy-manage/deploy/cloud-on-k8s/deploy-an-orchestrator)
- [Fleet Server on Kubernetes](https://www.elastic.co/docs/reference/fleet/add-fleet-server-kubernetes)
- [Elastic Agent Installation](https://www.elastic.co/guide/en/fleet/current/install-fleet-managed-elastic-agent.html)
