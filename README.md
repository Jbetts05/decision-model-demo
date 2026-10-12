# The AI Switchboard

A tiny live comparison of Microsoft Decision One, GPT-6 Astra, GPT-6 Luna and
GPT-6 Sol. Select an example, edit the text, and run all four models in parallel.
Cards show the answer, deployment, request latency, and API-reported tokens.
There are no costs, winners, rankings, or stored submissions.
Each example shows its classification question and possible labels. A compact
Details inspector on each result shows the actual context, schema, and model
output. These are observable API inputs and outputs, not internal reasoning.

## Deployment

The `web/` page and managed Node.js 22 Azure Functions API deploy together to
Azure Static Web Apps. Every push to `main` runs the API tests and deploys through
GitHub Actions. No frontend build, database, containers, or local package install.

GitHub Actions requires the repository secret `AZURE_STATIC_WEB_APPS_API_TOKEN`.
The API requires these encrypted Static Web Apps application settings:

| Setting | Value |
| --- | --- |
| `FOUNDRY_ENDPOINT` | Existing Foundry resource endpoint |
| `FOUNDRY_API_KEY` | Existing Foundry API key, never committed |

Deployment names default to `Decision-1`, `gpt-6-astra`, `gpt-6-luna`, and
`gpt-6-sol`. Model credentials stay server-side. The page and sample catalog are
public, including live inference. Share the site URL directly with colleagues;
no sign-in, invitation, access code, or GitHub account is required.
Existing Foundry usage charges still apply to public requests.

For the approved Azure subscription and receipt benchmark resource, run
`scripts\provision.ps1` after creating the private repository. It provisions only
the Free Static Web App, configures the existing Foundry credential server-side,
and pipes the deployment token directly into the repository secret. Azure CLI
and GitHub CLI must already be signed in. Then push to `main`.

Latency measures server-to-Foundry request time through receipt of the complete
response. It excludes the browser round trip and API cold start. Tokens are
reported by each model API, not locally estimated; missing usage is shown as a
dash. GPT output tokens include any reported reasoning tokens. Astra uses its
lowest supported reasoning effort, `low`; Luna and Sol use `none`. The different
APIs and prompt representations mean token counts need not match.

Each request has a 40-second model timeout, below the managed API's 45-second
limit. Errors appear only in the affected card. The demo uses existing billable
Foundry deployments even though the interface does not display cost.
The API caps public usage at 16 concurrent requests and 96 requests per minute
per API instance. This lightweight in-memory guard is shared across visitors,
resets on restart, and is not a global quota across scaled-out instances.

## Tests

```powershell
node --test api\test\core.test.js
```

Tests use Node's built-in runner and do not require a dependency installation.
Cloud deployment installs the Functions runtime dependency in its isolated build
environment. Keep the repository private unless its contents are reviewed for
public release.
