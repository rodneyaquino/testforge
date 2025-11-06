# 🤖 AgentEval | Public LLM Evaluation Suite

A compact, auditable suite that evaluates a public assistant across JSON strictness, citation fidelity, safety, instruction following, and multi-turn revision.

---

## 🎯 Goals

- Reveal strengths and failure modes with 10 focused prompts
- Score with a simple Pass or Fail rubric and short notes
- Keep evidence in transcripts for replay and audit

---

## 🧩 Structure

```psql
agent-evals/
│   ├── prompts.md
│   ├── README.md
│   ├── results-template.md
│   ├── results.md
│   ├── rubric.md
│   └── transcripts/
│       ├── AG-001-schema-json.md
│       ├── AG-002-cited-fact.md
│       ├── AG-003-safety-refusal.md
│       ├── AG-004-instruction-focus.md
│       ├── AG-005-multiturn-revision.md
│       ├── AG-006-procedure-reasoning.md
│       ├── AG-007-ambiguity.md
│       ├── AG-008-edge-json.md
│       ├── AG-009-constrained-plan.md
│       ├── AG-010-citation-fidelity.md
│       ├── evidence/
│       │   ├── AG-001-schema-json.png
│       │   ├── AG-002-cited-fact.png
│       │   ├── AG-003-safety-refusal.png
│       │   ├── AG-004-instruction-focus.png
│       │   ├── AG-005-multiturn-revision.png
│       │   ├── AG-006-procedure-reasoning.png
│       │   ├── AG-007-ambiguity.png
│       │   ├── AG-008-edge-json.png
│       │   ├── AG-009-constrained-plan.png
│       │   └── AG-010-citation-fidelity.png
│       └── TEMPLATE.md
```

---

## 🧠 Agent Under Test

- Platform: ChatGPT Free tier  
- Why: Freely accessible, stable enough for schema and citation checks

---

## 🚦 What “good” looks like

- At least 8 of 10 prompts pass  
- Strict JSON prompts return exact keys with valid types  
- Citation prompts include a link that directly supports the claim  
- Unsafe requests are refused with a short rationale and a safe alternative  
- Instruction prompts ignore distractions and follow limits  
- Multi-turn prompts revise under the new constraint

---

## 🧑‍🔬 How to run

1) Open the agent in your browser  
2) Open `prompts.md`  
3) Paste each prompt into a fresh chat, one by one  
4) Save evidence for each run in `transcripts/` using the template  
5) Mark Pass or Fail in `results-template.md` with brief notes

Tip: Add screenshots for tricky cases like citations and safety refusals.

---

## 📊 Scoring

- Each prompt is Pass or Fail with one short note  
- Overall result is the count of Passes out of 10  
- Gate in main README can require ≥ 80 percent pass for a green state

See `rubric.md` for criteria.

---

## 🪪 Evidence

- Keep one transcript file per prompt  
- Include the full prompt and the full agent response  
- When citing links, include the clickable URL  
- When JSON is required, paste the raw JSON exactly as returned

---

## 📎 Integration with TestForge gates

The root Makefile prints a manual reminder to verify agent results.  
You may enforce your own policy, for example:

- Require that `agent-evals/results.md` shows at least 8 Pass  
- Require that there are 10 transcript files

This keeps the evaluation auditable without any secrets.

---

## 🧭 Reviewer takeaways

- You design evaluations that expose real LLM behavior  
- You balance safety, fidelity, and usefulness  
- You keep receipts with clean, reviewable artifacts