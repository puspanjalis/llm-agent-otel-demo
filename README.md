# llm-agent-otel-demo

Demo for **LLM/Agent Observability with OpenTelemetry**  
Cloud Native Hyderabad · March 28 2026 · Puspanjali Sarma

---

## What this shows

A FastAPI app that simulates a support agent workflow and emits traces using
the **official OTel GenAI semantic conventions** (Development, 2026):

| Span name | `gen_ai.operation.name` | What it represents |
|---|---|---|
| `invoke_agent support-agent` | `invoke_agent` | Agent entry point |
| `retrieval kb://support-policies` | `retrieval` | RAG / vector search |
| `build_prompt` | *(internal)* | Prompt assembly |
| `chat mock-llm` | `chat` | Model inference |
| `execute_tool ticket_api` | `execute_tool` | Tool invocation |
| `policy.check` | *(internal)* | Safety / redaction gate |

No external LLM API is needed. All traces go to **local Jaeger** via the
**OTel Collector** (which redacts PII before export).

---

## Quick start

```bash
docker compose up --build
```

Open:
- **App (Swagger UI):** http://localhost:8000/docs
- **Jaeger UI:** http://localhost:16686

---

## 5 scenarios

### 1 · Happy path
```bash
curl 'http://localhost:8000/ask?scenario=happy&question=Can+I+change+my+plan'
```
**What to point to in Jaeger:** all spans green, `retrieval.doc_age_days=2`.

---

### 2 · Stale retrieval  ← key demo moment
```bash
curl 'http://localhost:8000/ask?scenario=stale_doc&question=Can+I+change+my+plan'
```
**What to point to:** `retrieval.doc_age_days=30` in the retrieval span.  
**The lesson:** the model behaved consistently — the context was wrong. Logs would have shown "200 OK"; the trace localises the failure to retrieval.

---

### 3 · Tool timeout
```bash
curl 'http://localhost:8000/ask?scenario=tool_error&question=What+is+my+ticket+status'
```
**What to point to:** `execute_tool ticket_api` span is red with `error.type=timeout`.  
**The lesson:** not a prompt problem — it's a downstream dependency problem. Fix: timeout config, retries, SLOs.

---

### 4 · Prompt injection blocked
```bash
curl 'http://localhost:8000/ask?scenario=prompt_injection&question=Summarize+the+policy'
```
**What to point to:** `policy.check` span with `policy.blocked=true` and a `prompt_injection_blocked` event.  
**The lesson:** the policy span blocked the attack, and the exported telemetry is already redacted by the Collector.

---

### 5 · Latency spike
```bash
curl 'http://localhost:8000/ask?scenario=latency_spike&question=What+is+the+refund+policy'
```
**What to point to:** `execute_tool ticket_api` dominates the waterfall (≈0.9 s).  
**The lesson:** retrieval and model are healthy; the tail is a tool problem. This is an SLO / alerting issue, not an accuracy problem.

---

## Run the full demo script

```bash
bash scripts/demo.sh
```

Then open Jaeger → search `service=llm-agent-demo` → compare traces.

---

## Architecture

```
FastAPI app
  └─ OTel SDK (manual instrumentation)
       └─ OTLP HTTP → OTel Collector (redact → batch)
                           └─ OTLP HTTP → Jaeger
```

The Collector `attributes/redact` processor:
- **deletes** `authorization`, `gen_ai.input.messages`, `gen_ai.output.messages`
- **hashes** `user.id` and `user.email`

This is intentional — it matches the "what to redact by default" pattern from the talk.

---

## Payload capture (opt-in)

Prompt/response capture is **off by default**. To enable for a sampled debug session:

```yaml
# docker-compose.yaml
environment:
  OTEL_GENAI_CAPTURE_PAYLOADS: "true"
```

Always pair this with tail sampling + the Collector redaction processor.

---

## Push to GitHub after the meetup

```bash
cd llm-agent-otel-demo-final
git init
git add .
git commit -m "Initial meetup demo – Cloud Native Hyderabad March 2026"
git branch -M main
git remote add origin https://github.com/<your-username>/llm-agent-otel-demo.git
git push -u origin main
```

---

## Files

| File | Purpose |
|---|---|
| `app/main.py` | FastAPI app with mock agent + OTel instrumentation |
| `otel-collector-config.yaml` | Collector pipeline: redact → batch → Jaeger |
| `docker-compose.yaml` | Local stack (app + Collector + Jaeger) |
| `scripts/demo.sh` | Fire all 5 scenarios in sequence |
| `DEMO_RUNBOOK.md` | Live demo script + fallback plan |
