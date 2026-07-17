# Incident Workflow

Processes automated by `scripts/investigate_incident.sh`, flagship script that ties together log analysis, SQL, and batch job checks into a single guided investigation.

## Trigger

The script accepts a single input: either a **customer email** (contains `@`) or a **campaign ID**. It branches its investigation logic based on which was provided.

## Steps

1. **Receive Incident** — capture the input, generate a timestamped report filename (`reports/incident_<id>_<timestamp>.md`).
2. **Check Batch Jobs** — query `batch_jobs` for any `status='failed'` rows regardless of investigation type, since failed jobs are common root causes.
3. **Read Logs** — `grep` all `logs/*.log` files for the input string to surface related log lines.
4. **Run SQL** (branches on input type):
   - **Customer email** — look up the customer row, count total deliveries and bounces, find the last delivery date.
   - **Campaign ID** — count recipients, compute bounce rate, find the most common bounce code, and pull the most frequent recent error message from logs.
5. **Determine Root Cause** — apply simple heuristics:
   - Customer: unsubscribed status or bounce count > 0 drives the recommendation.
   - Campaign: bounce rate > 5% triggers a "warm sending domain" recommendation; any failed batch jobs get appended to the recommendation.
6. **Generate Report** — write a .md summary (customer or campaign variant) to `reports/`, echoed to the terminal via `tee`.

## Example Usage

```bash
./scripts/investigate_incident.sh
# Enter Campaign ID or Customer Email: CMP-1023
```

## Design Notes

- Customer vs. campaign logic is kept in one script (not split) since both share the "check batch jobs first" step and report-generation pattern.
- Recommendations are intentionally simple (rule-based), matching the level of a first-line support runbook rather than a diagnostic engine.
- The same investigation logic is also exposed over HTTP via `api/app.py`'s `/incidents/<id>` endpoint.
