---
name: datadog-service-catalog-validator
description: Validate and fix FanDuel Datadog service.datadog.yaml files against the v2.2 Tag Baseline. Use when creating, editing, reviewing, or troubleshooting service.datadog.yaml files, or when the user mentions service catalog compliance, SCV validation, or tag baseline.
---

# Datadog Service Catalog Validator

Locally validate `service.datadog.yaml` against FanDuel's Tag Baseline (v2.2) and fix non-compliant files.

Reference: [Tag Baseline - Datadog Service Catalog](https://fanduel.atlassian.net/wiki/spaces/PE1/pages/310074016861/Tag+Baseline+-+Datadog+Service+Catalog)

## Validation Workflow

1. **Read** the `service.datadog.yaml` file (repo root)
2. **Validate** against rules below, collecting errors and warnings
3. **Report** findings in a structured table (errors first, then warnings)
4. **Fix** issues if the user requests it, or propose changes for confirmation

## Validation Rules

### Step 1: Check Required Top-Level Fields

All of these must be present and non-empty:

| Field | Valid Values |
|-------|-------------|
| `schema-version` | `v2.2` |
| `dd-service` | Any unique string (typically the repo name) |
| `team` | Must match [fd-org table](https://fdorg.fanduel.dev/table) |
| `application` | Any string (often same as dd-service) |
| `tier` | `p1`, `p2`, `p3`, `p4` |
| `lifecycle` | `experimental`, `sandbox`, `staging`, `production`, `sunsetting`, `deprecated` |

### Step 2: Check Contacts

At least one contact is required:
- Must have `type: slack`
- Must have `name` (human-readable Slack channel name)
- Must have `contact` as `https://fanduel.slack.com/archives/<CHANNEL_NAME_OR_ID>`
- **Advisory**: Slack Channel ID is preferred over channel name for resilience against renames

### Step 3: Check Links

A repo link is always required:
```yaml
links:
  - name: <REPO_NAME>
    type: repo
    provider: github
    url: https://github.com/fanduel/<REPO_NAME>
```

**Pipeline links** — the baseline requires **separate** Build Pipeline (`links[1]`) and Deploy Pipeline (`links[2]`) entries for applicable kinds. When a single pipeline handles both build and deploy, use the same URL for both entries:

```yaml
  - name: Build Pipeline
    type: other
    provider: buildkite  # or github
    url: <PIPELINE_URL>
  - name: Deploy Pipeline
    type: other
    provider: buildkite  # or argocd
    url: <PIPELINE_URL>
```

Pipeline link requirements by kind — see [reference.md](reference.md) for full details:

| Kind | Build Pipeline | Deploy Pipeline |
|------|---------------|-----------------|
| `service` | Required* | Required* |
| `library` | Required* | Optional |
| `ui` | Required* | Optional |
| `infra` | Optional | Required* |
| Others | Optional | Optional |

*Optional if a pipeline simply does not exist.

### Step 4: Check Required Tags

All of these tags must be present:

| Tag | Valid Values |
|-----|-------------|
| `kind` | `service`, `library`, `plugin`, `ui`, `infra`, `terraform-module`, `scripts`, `docs`, `test`, `hackathon`, `transformation`, `container-image`, `base-template` |
| `domain` | Must match [fd-org table](https://fdorg.fanduel.dev/table) |
| `vertical` | Must match [fd-org table](https://fdorg.fanduel.dev/table) |

### Step 5: Check Conditionally Required Fields by Kind

Use the `kind` tag value to determine which additional fields/tags are required:

#### `kind:service`
- `languages` (top-level field, yaml array) — use languages of the **service**, not infra tooling
- `platform` tag — `podium`, `vm-evo`, `aws`, `gcp`, `dbt`, `kong`, `datadog`, `v3`, `v2`
- `deployment-ui` tag — `cpanel`, `verum`, `portal`, `buildkite`
- `application-state` tag — `stateless-share-nothing`, `stateless-gossip`, `stateful-share-nothing`, `stateful-gossip`
- Build Pipeline link + Deploy Pipeline link

#### `kind:infra`
- `platform` tag (same values as above)
- `deployment-ui` tag (same values as above)
- Deploy Pipeline link

#### `kind:ui`
- `languages` (top-level field)
- `platform` tag (same values as above)
- `deployment-ui` tag (same values as above)
- Build Pipeline link

#### `kind:library`
- `languages` (top-level field)
- Build Pipeline link

#### `kind:transformation`
- `platform` tag (same values as above)

#### All other kinds
No additional conditionally required fields.

### Step 6: Check Optional Fields for Validity

If present, these must use valid values:

| Field/Tag | Valid Values |
|-----------|-------------|
| `type` | `web`, `db`, `cache`, `function`, `browser`, `mobile`, `custom` |
| `division` tag | `fd`, `gbp` |
| `data-classification` tag | `public`, `internal`, `confidential`, `restricted` |
| `regulated-sox` tag | `true`, `false` |
| `regulated-gli` tag | `true`, `false` |
| `regulated-pci` tag | `true`, `false` |

**Note**: `data-classification` and `regulated-*` tags are required for protected/regulated services.

## Report Format

Present findings as:

```
## Service Catalog Compliance Report

**File**: service.datadog.yaml
**dd-service**: <name>
**kind**: <kind>

### Errors (must fix)
| # | Field/Tag | Issue |
|---|-----------|-------|
| 1 | ...       | ...   |

### Warnings (recommended)
| # | Field/Tag | Issue |
|---|-----------|-------|
| 1 | ...       | ...   |

### Summary
- X error(s), Y warning(s)
- [PASS/FAIL] — would the SCV pass this file?
```

## Fixing Issues

When fixing, apply changes directly to the file. For fields requiring user input (team, domain, vertical, pipeline URLs, Slack channel ID), ask the user. For enum-constrained fields, select the most appropriate value based on context or ask if ambiguous.

## Common Pitfalls

1. **Single "Build & Deploy Pipeline" link** — The baseline requires separate Build Pipeline (`links[1]`) + Deploy Pipeline (`links[2]`) entries. Use the same URL for both if it's one pipeline.
2. **`hcl` in languages for `kind:service`** — languages should reflect the service's code, not infrastructure tooling. Use `hcl` only for `kind:infra`.
3. **Slack channel name vs ID** — Channel ID (e.g., `C06TMG311FY`) is preferred over the name to survive renames.
4. **Placeholder values left in** — Any `[YOUR_...]` placeholder will fail validation. Remove or fill them.
5. **team/domain/vertical mismatch** — These must match the [fd-org table](https://fdorg.fanduel.dev/table) exactly (lowercase, hyphens for spaces).

## Additional Resources

- For complete field-by-field reference, see [reference.md](reference.md)
