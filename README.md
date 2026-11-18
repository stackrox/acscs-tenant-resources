# ACS-CS tenant resources

Helm chart for the per-tenant RHACS resources managed by ACS Cloud Service.
The chart renders a `Central` custom resource and supporting network policies,
routes, declarative configuration, secret-store integration, and optional
monitoring, priority classes, disruption budgets, and autoscaling resources.

## How it is deployed

Fleetshard-sync reconciles a tenant ArgoCD Application pointing at this repository.
ArgoCD renders and synchronizes the chart.

The fleetshard-sync chart in
[`stackrox/acs-fleet-manager`](https://github.com/stackrox/acs-fleet-manager)
accepts:

```yaml
gitops:
  tenantDefaultAppSourceRepoUrl: https://github.com/stackrox/acscs-tenant-resources
  tenantDefaultAppSourceTargetRevision: HEAD
  tenantDefaultAppSourcePath: .
```

## Configuration

[`values.yaml`](values.yaml) is the configuration reference. Fleetshard-sync
provides tenant identity, environment, database connection references, routes,
and resource settings at reconciliation time. Important groups include:

- Tenant identity: `organizationId`, `instanceId`, `instanceName`, `instanceType`.
- Placement and rollout: `clusterName`, `environment`, `rolloutGroup`, affinities,
  node selectors, and tolerations.
- Workloads: `centralResources`, `scannerResources`, `scannerV4Enabled`, and
  the corresponding database and Scanner V4 resource settings.
- Networking: `centralUIHost`, `centralDataHost`, route restrictions, and network
  policy CIDR templates in `config/`.
- Configuration and integrations: `declarativeConfig`, secret-store resources,
  profiling, health checks, and VPA.

Never commit real tenant data, database credentials, tokens, certificates, or
rendered production manifests. Supply secrets through the existing runtime
secret-management integrations.

## Development

Install Helm 3 and [pre-commit](https://pre-commit.com/), then:

```bash
helm plugin install https://github.com/helm-unittest/helm-unittest.git --version v1.0.3
pre-commit install
helm lint .
helm unittest .
pre-commit run --all-files
```

Render locally with non-sensitive example values:

```bash
helm template example . --namespace example-tenant \
  --set instanceId=example --set instanceName=example \
  --set organizationId=example --set clusterName=example \
  --set centralUIHost=central.example.com \
  --set centralDataHost=central-data.example.com
```

Tests in `tests/` use helm-unittest. Add focused regression tests when changing
templates or value semantics. Keep the chart name and existing value interface
compatible with fleetshard-sync.
