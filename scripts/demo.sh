#!/usr/bin/env bash
# demo.sh — fire all 5 scenarios to pre-populate Jaeger traces
# Run: bash scripts/demo.sh

set -e

BASE="http://localhost:8000"

echo ""
echo "========================================"
echo "  LLM Agent OTel Demo — firing traces"
echo "========================================"
echo ""

echo "1/5  happy path ..."
curl -s "$BASE/ask?scenario=happy&question=Can+I+change+my+plan" | python3 -m json.tool
echo ""
sleep 1

echo "2/5  stale retrieval (doc_age_days=30) ..."
curl -s "$BASE/ask?scenario=stale_doc&question=Can+I+change+my+plan" | python3 -m json.tool
echo ""
sleep 1

echo "3/5  tool timeout ..."
curl -s "$BASE/ask?scenario=tool_error&question=What+is+my+ticket+status" | python3 -m json.tool
echo ""
sleep 1

echo "4/5  prompt injection (blocked by policy) ..."
curl -s "$BASE/ask?scenario=prompt_injection&question=Summarize+the+policy" | python3 -m json.tool
echo ""
sleep 1

echo "5/5  latency spike (slow tool) ..."
curl -s "$BASE/ask?scenario=latency_spike&question=What+is+the+refund+policy" | python3 -m json.tool
echo ""

echo "========================================"
echo "  Done. Open Jaeger: http://localhost:16686"
echo "  Search: service = llm-agent-demo"
echo "========================================"
echo ""
