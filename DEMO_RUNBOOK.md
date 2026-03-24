# DEMO RUNBOOK — Cloud Native Hyderabad · March 28 2026

## Format
- Slides: ~20 minutes
- Live demo: ~4 minutes  ← this file
- Q&A: ~5 minutes

---

## Before you leave home

1. `docker compose up --build` — let everything download and start
2. Run `bash scripts/demo.sh` to pre-warm traces
3. Open two browser tabs:
   - **Jaeger:** http://localhost:16686
   - **Swagger UI:** http://localhost:8000/docs
4. In Jaeger, load one `stale_doc` trace and leave it open as a fallback
5. Keep your terminal visible alongside Jaeger

---

## Safety rules

- **Do not depend on Wi-Fi.** The venue may block GitHub, AI APIs, Docker Hub.
  Everything needed is already in Docker images pulled at home.
- If anything fails: say the line below and switch to your pre-loaded Jaeger screenshot.

> *"The exact mechanics are less important than the pattern: one request
> becomes a trace with retrieval, model, tool, and policy spans.
> Here is the same trace captured earlier."*

---

## Live demo script (~4 minutes)

### Step 1 · Start (30 sec)

Say:
> "Let's bring this to life. I have a local stack running — FastAPI agent,
> OTel Collector, and Jaeger. No hosted LLM, no internet required."

Show the terminal with `docker compose up` running (or already up).  
Show Jaeger at localhost:16686, empty or with old traces.

---

### Step 2 · Happy path (45 sec)

Run in terminal:
```bash
curl 'http://localhost:8000/ask?scenario=happy&question=Can+I+change+my+plan'
```

In Jaeger: search `service=llm-agent-demo`, open the newest trace.

Say:
> "Here's the healthy path. Root span is `invoke_agent`, and you can see
> retrieval, prompt build, model call, tool call, policy check — all as
> child spans with the same trace ID. `retrieval.doc_age_days=2`. Fresh.
> Model is happy. Everything green."

---

### Step 3 · Stale retrieval — the core demo moment (90 sec)

Run in terminal:
```bash
curl 'http://localhost:8000/ask?scenario=stale_doc&question=Can+I+change+my+plan'
```

In Jaeger: open the new trace. Click the retrieval span.

Say:
> "Now look at this. Same question, different trace. The answer came back
> wrong. If I had only logs, I'd see '200 OK from the model'. But the trace
> tells me exactly where to look."

Point to `retrieval.doc_age_days=30`:
> "The retrieval span returned a 30-day-old policy document.
> The model did its job — it answered based on what it was given.
> The context was stale. The fix is a freshness policy on the index,
> not prompt tweaking. Without a trace, we'd have spent hours on the wrong thing."

---

### Step 4 · Tool timeout (45 sec)

Run in terminal:
```bash
curl 'http://localhost:8000/ask?scenario=tool_error&question=What+is+my+ticket+status'
```

In Jaeger: open the trace. Click the red `execute_tool ticket_api` span.

Say:
> "This is a tool failure. The `execute_tool` span is red — timeout after 5 seconds.
> Retrieval was fine. Model was fine. The downstream ticket API timed out.
> This isn't a prompt problem; it's a dependency problem.
> The fix is timeout config, retries, and a downstream SLO — not a new prompt."

---

### Step 5 · Close (30 sec)

Say:
> "One more: prompt injection."

Run:
```bash
curl 'http://localhost:8000/ask?scenario=prompt_injection&question=Summarize+the+policy'
```

In Jaeger: show `policy.check` with `policy.blocked=true`.

Say:
> "The retrieved content contained a hostile instruction. The policy span
> blocked it. And notice — the exported telemetry is already redacted by
> the Collector. You get the signal you need without the payload you don't want."

Pause. Then:
> "Instrument the workflow, not just the model.
> When something fails, the trace tells you where. Every time."

---

## Fallback — if live demo breaks

1. Switch to the pre-loaded Jaeger screenshot / open trace you saved at home
2. Use slide 9 (Demo slide) as a visual walkthrough
3. Say:
   > "The pattern matters more than watching me type curl.
   > Let me show you the same trace I captured earlier this morning."

---

## Q&A seed questions (in case the room is quiet)

- "Do I need to change my existing Prometheus / Grafana stack to use this?"
  → No. The Collector is vendor-neutral. Point it at whatever backends you already have.

- "How is this different from LangSmith or Langfuse?"
  → Those are great closed-ecosystem tools. OTel gives you the same data in an open
    format that works with Jaeger, Datadog, Grafana, Arize — whatever you trust.

- "When will GenAI SemConv be stable?"
  → It's still Development as of March 2026. Pin your instrumentation to a version
    and watch the changelog. The core span names (`chat`, `invoke_agent`,
    `execute_tool`, `retrieval`) have been stable in practice for several months.

- "What about multi-agent / LangGraph / CrewAI?"
  → The `invoke_agent` span is designed for nested agents. Each agent creates its
    own root span as CLIENT or INTERNAL depending on whether it runs in-process.
    Context propagation carries the parent trace ID through.
