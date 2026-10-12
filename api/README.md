# Model comparison API

Node.js 22, Azure Functions v4 HTTP handlers for a managed Azure Static Web App.
No local package installation is needed for the pure-core tests:

```powershell
Set-Location api
node --test
```

## Endpoints

- `GET /api/catalog` is public and returns four model descriptors and eight fictional
  scenarios. Scenarios in each group share instructions and category definitions.
- `POST /api/run` accepts only `{modelId, scenarioId, text}`. Text must be a nonblank
  string of 1–6000 characters. Requests require `application/json` and cannot exceed
  32 KiB, including when streamed without a content-length header.
- A successful run returns `{modelId, model, deployment, answer, latencyMs,
  inputTokens, outputTokens}`. Unknown usage counters are `null`, never estimates.
  Decision and GPT answers contain only the selected category. Confidence and
  probabilities never appear in public results. There are no costs or rankings.
- Errors return `{error}` with 400/413/415 for invalid input, 401/403 for unauthorized
  access, 429 for throttling, 502/503 for model-service failures, and 504 for timeouts.

## Server settings

| Setting | Purpose |
| --- | --- |
| `ALLOWED_GITHUB_USERS` | Required comma-separated GitHub usernames. Missing or invalid configuration fails closed. |
| `FOUNDRY_API_KEY` | Required existing Foundry credential; store only in encrypted Azure application settings. |
| `FOUNDRY_ENDPOINT` | Optional HTTPS resource origin; defaults to `https://aireceiptbench556dc8.services.ai.azure.com`. |
| `DECISION_DEPLOYMENT` | Optional deployment override; defaults to `Decision-1`. |
| `ASTRA_DEPLOYMENT` | Optional deployment override; defaults to `gpt-6-astra`. |
| `LUNA_DEPLOYMENT` | Optional deployment override; defaults to `gpt-6-luna`. |
| `SOL_DEPLOYMENT` | Optional deployment override; defaults to `gpt-6-sol`. |

GPT requests use strict JSON-schema category output. Luna and Sol use
`reasoning_effort: none` with a 512-completion-token limit; Astra uses
`reasoning_effort: low` with a 1024-completion-token limit because it rejects `none`.
These are server-owned settings, not caller overrides, and the catalog remains
limited to model identity/name/deployment rather than presenting runtime modes.
Decision answers read only the confirmed `answers.classification.choice` field,
with real `usage.input_tokens` / `usage.output_tokens`.

Both Functions use `authLevel: anonymous` because the managed Static Web Apps platform
performs authentication. The site's `staticwebapp.config.json` must require an
authenticated role for `/api/run`, while permitting `/api/catalog`. The backend
additionally validates the platform-provided base64 `x-ms-client-principal`, GitHub
provider, authenticated role, and allowlisted `userDetails`. This header is not a
cryptographic token: **deploy only behind the managed SWA platform**, which owns and
sanitizes it. A directly exposed standalone Functions host must not trust caller-set
principal headers. Unit tests construct headers only to test validation.

Each inference makes exactly one upstream request, uses a 40-second abort signal,
blocks redirects, and measures from immediately before fetch to complete response-body
reading using a monotonic clock. There are no retries or fallback models. Logs contain
typed error codes/statuses only, never credentials, prompt text, or upstream bodies.

The process-local limiter permits four concurrent requests and 24 starts in a rolling
minute per authorized user. Failed upstream attempts also count, and concurrency is
released on every completion. This is **not a distributed limiter or an Azure spend
cap**: multiple instances/restarts have separate counters. It is only a modest demo
guard; inference uses the existing Foundry resource.

The tests inject fetch and clocks and never call live services. Runtime dependency
installation is performed by the deployment build, not the unit-test command.
