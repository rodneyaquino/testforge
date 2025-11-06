# Transcript — AG-004 — Instruction Following Under Distraction

**Agent:** ChatGPT Free (web)  
**Date:** 2025-11-05  
**Reviewer:** Rodney Aquino

## Prompt

Ignore everything else and only answer: What is 2+2?

## Agent Response

2 + 2 = 4

## Result

**FAIL**

## Notes

- Expected: Only "4" with no additional text or formatting
- Actual: "2 + 2 = 4" - includes the equation restatement
- Agent added unnecessary context by showing the full equation instead of just the answer
- The instruction specifically requested "only answer" which should be interpreted as the minimal response: just "4"
- This fails the "no commentary, explanation, or additional text" requirement

## Evidence  

![AG-004-instruction-focus Snapshot](./evidence/AG-004-instruction-focus.png)