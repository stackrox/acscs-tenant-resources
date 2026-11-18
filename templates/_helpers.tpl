{{/*
Expand the name of the chart.
*/}}
{{- define "tenant-resources.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "tenant-resources.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Tenant Labels
*/}}
{{- define "tenant-resources.tenantLabels" -}}
rhacs.redhat.com/org-id: "{{ .Values.organizationId }}"
rhacs.redhat.com/tenant: "{{ .Values.instanceId }}"
rhacs.redhat.com/instance-type: "{{ .Values.instanceType }}"
{{- end }}

{{/*
Common labels
*/}}
{{- define "tenant-resources.labels" -}}
helm.sh/chart: {{ include "tenant-resources.chart" . }}
{{ include "tenant-resources.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{ include "tenant-resources.tenantLabels" . }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "tenant-resources.annotations" -}}
rhacs.redhat.com/org-name: "{{ .Values.organizationName }}"
{{- end }}

{{/*
Selector labels
*/}}
{{- define "tenant-resources.selectorLabels" -}}
app.kubernetes.io/name: {{ include "tenant-resources.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "localNetworkCidrRanges" -}}
{{- tpl (.Files.Get "config/local-network-cidr-ranges.yaml.tpl") . -}}
{{- end -}}

{{- define "localNetworkCidrRangesIPv6" -}}
{{- tpl (.Files.Get "config/local-network-cidr-ranges-ipv6.yaml.tpl") . -}}
{{- end -}}


{{/*
    Documentation for the route annotations to configure DDoS protection:
	https://docs.openshift.com/container-platform/4.13/networking/routes/route-configuration.html#nw-route-specific-annotations_route-configuration
*/}}
{{- define "tenant-resources.commonRouteAnnotations" -}}
haproxy.router.openshift.io/rate-limit-connections: {{ .Values.routeEnableThrottling | quote }}
haproxy.router.openshift.io/rate-limit-connections.concurrent-tcp: {{ .Values.routeConcurrentTcpConnections | quote }}
haproxy.router.openshift.io/rate-limit-connections.rate-http: {{ .Values.routeHttpRequestRate | quote }}
haproxy.router.openshift.io/rate-limit-connections.rate-tcp: {{ .Values.routeTcpNewConnectionRate | quote }}
haproxy.router.openshift.io/timeout: {{ .Values.routeTimeout | quote }}
{{- /* Add backbox-exporter probe service IPs to the Central CIDR whitelist if the whitelist is not empty */}}
{{- $centralWhitelistCidrRanges := "" -}}
{{- if .Values.routeAllowedCidrRanges }}
{{- $whitelistWithBlackboxExporterCidrRanges := concat .Values.routeAllowedCidrRanges .Values.blackboxExporterProbeIps -}}
{{- $centralWhitelistCidrRanges = join " " $whitelistWithBlackboxExporterCidrRanges -}}
{{- end}}
haproxy.router.openshift.io/ip_whitelist: {{ $centralWhitelistCidrRanges | quote }}
{{- end }}


{{/*
Converts Kubernetes resource quantities to numeric byte values.
Supports both base-2 (Ki, Mi, Gi, Ti, Pi, Ei) and base-10 (m, k, M, G, T, P, E) units.
Returns the numeric value in bytes as a float.

Examples:
  - "1000Mi" -> 1048576000 (1000 * 2^20)
  - "1Gi"    -> 1073741824 (1 * 2^30)
  - "1.2G"   -> 1200000000 (1.2 * 10^9)
  - 1024     -> 1024 (numeric values passed through)

Usage: {{ include "tenant-resources.resource-quantity" .Values.centralResources.limits.memory }}
See: https://github.com/helm/helm/issues/11376#issuecomment-1256831105
*/}}
{{- define "tenant-resources.resource-quantity" -}}
    {{- $value := . -}}
    {{- $unit := 1.0 -}}
    {{- if typeIs "string" . -}}
        {{- $base2 := dict "Ki" 0x1p10 "Mi" 0x1p20 "Gi" 0x1p30 "Ti" 0x1p40 "Pi" 0x1p50 "Ei" 0x1p60 -}}
        {{- $base10 := dict "m" 1e-3 "k" 1e3 "M" 1e6 "G" 1e9 "T" 1e12 "P" 1e15 "E" 1e18 -}}
        {{- range $k, $v := merge $base2 $base10 -}}
            {{- if hasSuffix $k $ -}}
                {{- $value = trimSuffix $k $ -}}
                {{- $unit = $v -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- mulf (float64 $value) $unit -}}
{{- end -}}

{{/*
Calculates GOMEMLIMIT as a configurable percentage of the given memory limit.
Takes a dict with "memory" (a resource quantity) and "percentage" (0-100 integer).
Returns that percentage of the memory value in bytes, rounded up.

Examples (with percentage=90):
  - "1000Mi" -> 943718400 (90% of 1000 * 2^20)
  - "1Gi"    -> 966367642 (90% of 1 * 2^30)
  - "1.2G"   -> 1080000000 (90% of 1.2 * 10^9)

Usage: {{ include "tenant-resources.gomemlimit" (dict "memory" .Values.centralResources.limits.memory "percentage" .Values.centralGomemlimitPercentage) }}
*/}}
{{- define "tenant-resources.gomemlimit" -}}
    {{- $fraction := divf .percentage 100.0 -}}
    {{- include "tenant-resources.resource-quantity" .memory | float64 | mulf $fraction | ceil | int -}}
{{- end -}}

{{/*
Deduces auth provider name from issuer URL.
*/}}
{{- define "tenant-resources.authProviderName" -}}
{{- $issuer := .Values.declarativeConfig.defaultAuthProvider.oidc.issuer -}}
{{- if contains "sso.stage.redhat" $issuer -}}
Red Hat SSO (stage)
{{- else if contains "sso.redhat" $issuer -}}
Red Hat SSO
{{- else -}}
{{ (urlParse $issuer).host | default "SSO" }}
{{- end -}}
{{- end -}}
