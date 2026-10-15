# qe-docs-kit

Generate and refresh code-grounded Confluence documentation for FanDuel services.

**Reach for this kit when:** you need a service documented in Confluence, or want to keep
existing service docs from drifting out of sync with the code.

## What's inside

| Type | Name | What it does |
| --- | --- | --- |
| Skill | `auto-documentation` | Orchestrates the whole flow in your context: picks a mode (create one service, sweep several for drift, or report-only), dispatches the extraction agents, assembles the pages, and publishes to Confluence. |
| Agent | `auto-documentation` | The same orchestrator, dispatchable as a subagent — for automation and for other agents that need a service documented without it happening in their own context. |
| Agent | `autodoc-explorer` | Read-only code extraction: stack fingerprint, service compass, contract inventory (Kafka, APIs, databases, schedulers), C4/hexagonal architecture, domain model, and the list of features to document. |
| Agent | `autodoc-deployment-mapper` | Read-only deployment analysis: detects the deployment model, resolves environment config, and maps how the service is built, deployed, verified, and rolled back. |
| Agent | `autodoc-flow-tracer` | Read-only deep dive of one feature: traces the call chain from its entry points, documents business decisions, and produces sequence/decision diagrams. Dispatched once per feature. |
| Agent | `autodoc-reviewer` | Independent check of the assembled drafts against the actual code and the other agents' findings — fixes factual errors and gaps, never touching human-owned sections. |

## Output

One main Confluence page per service, plus one child page per feature:

```
<ServiceName>                       (main page)
├── <ServiceName> — <Feature A>     (child page)
├── <ServiceName> — <Feature B>
└── ...
```

## Modes

- **create** — document a single service from scratch.
- **sweep** — refresh only the services/pages whose docs have drifted from the code, driven by a config file; can run unattended.
- **report-only** — produce the drift report without publishing anything.
