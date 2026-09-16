---
name: support-troubleshooting-guide
description: Create a FanDuel Support & Troubleshooting Guide Confluence page for a service or module. Use whenever the user wants to document a service for support/on-call, create a runbook, build a troubleshooting guide, or produce a Confluence page describing service flow, dependencies, monitoring, and common issues. Also trigger on phrases like "support doc for X", "troubleshooting guide", "on-call doc", "service runbook", "document my service", or any mention of the FanDuel Support Guide template. Prefer activating over not activating — if there's any chance the user wants this kind of structured service doc, use this skill.
---

# Support & Troubleshooting Guide

Generate a FanDuel-standard "Support & Troubleshooting Guide" page on Confluence for a service or module, based on the official RTCMQA template and the PCSA-MD reference implementation.

## When to use

User wants to produce a Confluence page that helps on-call engineers and new team members support a service. Typical triggers:
- "Create a support guide for service X"
- "I need a troubleshooting doc for my module"
- "Write a runbook for the new service"
- "Document [service] like PCSA-MD"

If the user only wants a bug report, an architecture doc, or a generic Confluence page with no support/troubleshooting intent, use a different skill.

## Workflow

### Step 1 — Decide mode

Default: **create the page in Confluence** at the end. If the user says "just give me the markdown" or "dry run", produce the content without publishing.

### Step 2 — Identify the data source

Pick the shortest path to good input:

1. **If the user points at a service repo** (path, GitHub URL, or explicit mention) → read the `service-understand` skill and use it to extract stack, flows, dependencies, Kafka topics, Make targets. Then interview to fill the gaps (troubleshooting cases, dashboards, contacts, glossary).
2. **If no repo** → structured interview (see Step 3).
3. **If the user already pasted raw content** → skip to Step 4 and just structure it into the template.

Don't ask for a repo if none was mentioned — assume interview mode.

### Step 3 — Structured interview

Ask the user for each section. Batch questions by section to avoid ping-pong. Skip sections they flag as not-applicable. Use these prompts:

**Identity**
- Service / module name (e.g., `PCSA-MD`)
- Target Confluence space (key or ID) and parent page (URL or ID)

**1. Introduction**
- One-paragraph purpose
- Scope (what's in / out)

**2. Service Flow**
- Overview paragraph (what it does end-to-end)
- Upstream / downstream systems
- Diagram links or attachments (if any)
- Key concepts specific to this service (subtypes, domain model, hierarchy)

**3. Troubleshooting**
- For each known issue: feature/component, description, root cause, resolution steps, example log/screenshot link
- Minimum: push for at least 2–3 real cases; if none, note the table is seeded empty

**4. Dependencies**
- For each dependency: name, direction (upstream/downstream), description, impact if it fails

**5. Monitoring & Alerts**
- Logs (Datadog/Splunk/etc.) with env + link
- Dashboards with env + link
- Alerts (PagerDuty/Opsgenie) if applicable

**6. Repositories**
- Main service repo
- Config/chef repo
- Docs repo
- Scripts repo

**7. Key Contacts**
- Team name, responsible person(s), role

**8. Glossary / FAQs**
- Domain-specific acronyms and their expansions

**Optional extensions** (offer only if the user opts in or mentions them):
- **Local Setup Guide** — how to run locally, Make targets, Kafka topics, verification steps. Useful for developer-facing services.
- **Technical Overview** — architectural patterns (event sourcing, anti-corruption layer, actor model). Useful when the service uses non-obvious patterns newcomers need explained.

### Step 4 — Render the page

Use `references/template.md` as the base. The full-featured PCSA-MD example is in `references/example-pcsa-md.md` — use it to calibrate the level of detail expected per section, especially for tables.

Rules while rendering:
- Keep section numbering of the core template (1–8). If Local Setup / Technical Overview are included, insert them after Service Flow (before Troubleshooting) and renumber.
- Tables: always include the header row even if empty. An empty table with `| | | | |` is better than omitting the section — it signals "todo" to whoever owns it.
- Links: use Confluence Smart Links where possible (paste the raw URL, Confluence auto-renders). For external docs (Datadog, GitHub, Slack), keep raw URLs.
- Don't invent content. If the user didn't provide troubleshooting cases, leave the table empty rather than hallucinate.
- Title format: `[Service Name] – Support & Troubleshooting Guide` (en-dash, not hyphen).

### Step 5 — Publish or hand off

**Publish mode (default):**
- Call `Atlassian:createConfluencePage` with `contentFormat: "markdown"`, the rendered body, the space ID, and the parent page ID.
- If the user gave a Confluence URL for parent instead of ID, extract the ID from the URL path.
- Return the resulting page URL to the user.

**Dry-run mode:**
- Output the full markdown in a code block for the user to copy.
- Offer to publish it if they want.

### Step 6 — After publishing

Remind the user:
- Attach architecture/flow diagrams manually (the API does not upload images).
- Review the troubleshooting table and add team-specific cases.
- Add page reviewers/watchers via the Confluence UI.

## Output shape

Minimum viable page has these 8 sections in order:

```
# [Service Name] – Support & Troubleshooting Guide

## 1. Introduction
## 2. Service Flow Documentation
## 3. Troubleshooting Guidelines
## 4. Dependencies
## 5. Monitoring & Alerts
## 6. Repositories
## 7. Key Contacts
## 8. Glossary / FAQs
```

With extensions enabled:

```
## 1. Introduction
## 2. Service Flow Documentation
## 3. Local Setup Guide            (optional)
## 4. Technical Overview            (optional)
## 5. Troubleshooting Guidelines
## 6. Dependencies
## 7. Monitoring & Alerts
## 8. Repositories
## 9. Key Contacts
## 10. Glossary / FAQs
```

## Reference files

- `references/template.md` — the empty RTCMQA template, section-by-section
- `references/example-pcsa-md.md` — a full real example, use for calibration of tone and detail

Read `example-pcsa-md.md` whenever unsure how much detail a section should have.

## Anti-patterns

- Don't produce a page with every table empty — that's a template, not a guide. If the user has no data for 3+ sections, stop and interview more.
- Don't paraphrase the template section headers ("Service Flow Documentation" ≠ "How the service works"). Keep the exact names so the docs are scannable across services.
- Don't add sections not in the template without asking (no "Performance", "Security", "Release Notes" etc.).
- Don't publish before showing the user a preview of the rendered markdown unless they explicitly said "just publish it".
