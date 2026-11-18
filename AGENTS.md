# Agent guidance

## Purpose and structure

This public repository contains the ACS-CS per-tenant `tenant-resources` Helm
chart. `Chart.yaml` and `values.yaml` are at the root; templates are in
`templates/`, supporting CIDR templates in `config/`, and helm-unittest suites in
`tests/`.

Fleetshard-sync (in `stackrox/acs-fleet-manager`) reconciles tenant ArgoCD
Applications using this chart.

## Commands

```bash
helm lint .
helm unittest .
pre-commit run --all-files
```

Use Helm 3 and helm-unittest v1.0.3, matching CI. See `README.md` for setup.
Add regression tests for template or value behavior changes.

## Working rules

- Preserve chart name `tenant-resources`, helper names, labels, and the values
  interface unless an intentional migration includes fleetshard-sync changes.
- Edit chart sources, not generated tenant manifests.
- Never commit tenant identifiers from real environments, credentials, tokens,
  private certificates, rendered production values, or private runbooks.
- Secret values are injected at runtime; keep fixtures synthetic.
- Do not run live `kubectl`/`oc` modifications or release workflows as validation.
- Environment revisions are managed by the manifests repository's stage/prod
  revision-update workflows. Production must not follow an unpinned `HEAD`.
- Explicit per-tenant source overrides can bypass those defaults. Account for
  both repository URL and root chart path (`.`) when changing source settings.
