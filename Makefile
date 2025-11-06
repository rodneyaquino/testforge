# ======================================================================
# 🔧 TestForge - Full-Stack QA Framework
# Automated testing for Web, API, Performance, and Agentic AI
# Author: Rodney Aquino
# Description:
#   A composable, Makefile-driven quality engineering framework that
#   validates modern applications end to end using Playwright, Pytest,
#   and k6. Designed for clarity, speed, and reuse.
# ======================================================================


# Use bash so we can reliably read pipeline exit codes via PIPESTATUS.
SHELL := /bin/bash
.SHELLFLAGS := -o pipefail -c


# .PHONY ensures these targets always run (not confused with files of same name).
.PHONY: help setup install clean clean-all reinstall test test-smoke test-web test-api test-perf test-all report open-report validate status check-prereqs create-dirs ci watch-web lint-python fmt-python docs tree quick-test dev-setup summary perf-gate


# Set default target so `make` with no args prints the help menu.
.DEFAULT_GOAL := help


# ANSI colors for readable CLI output.
BLUE   := \033[0;34m
GREEN  := \033[0;32m
YELLOW := \033[0;33m
RED    := \033[0;31m
NC     := \033[0m  # No Color / reset


# ---------------------------------------------------------------------
# 🧾 Result/Log Paths
# WHY:
#   Centralize all artifact/log locations so other targets can read from
#   known, stable paths—especially the summary aggregator.
# WHAT:
#   Text logs (smoke/web/api), JUnit XML (api), and k6 outputs (json/stdout/warn).
# ---------------------------------------------------------------------
RESULT_DIR  := test-results
SMOKE_LOG   := $(RESULT_DIR)/smoke-results.txt
WEB_LOG     := $(RESULT_DIR)/web-results.txt
API_LOG     := $(RESULT_DIR)/api-results.txt
API_JUNIT   := $(RESULT_DIR)/api-results.xml
PERF_DIR    := tests/perf/results
PERF_JSON   := $(PERF_DIR)/k6-export.json
PERF_OUT    := $(PERF_DIR)/k6-output.txt
PERF_STD    := $(PERF_DIR)/k6-stdout.txt
PERF_WARN   := $(PERF_DIR)/k6-warn.log
PERF_MARK   := $(PERF_DIR)/.perf_status
SMOKE_MARK  := $(RESULT_DIR)/.smoke-passed


##@ General
# ---------------------------------------------------------------------
# 🧭 Help
# WHY:
#   Provide a discoverable command index with one-line docs per target.
# WHAT:
#   Prints grouped sections (##@) and <target> names with their descriptions.
# HOW:
#   Parses this file for "##" comments aligned to targets.
# ---------------------------------------------------------------------
help: ## Display this help message
	@printf "$(BLUE)🔧 TestForge - QA Framework$(NC)\n"
	@awk 'BEGIN {FS = ":.*##"; printf "Usage:\n  make $(GREEN)<target>$(NC)\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  $(GREEN)%-22s$(NC) %s\n", $$1, $$2 } /^##@/ { printf "\n$(BLUE)%s$(NC)\n", substr($$0, 5) } ' $(MAKEFILE_LIST)


##@ Setup & Installation
# ---------------------------------------------------------------------
# 🏗️ Setup (one-and-done)
# WHY:
#   Establish a predictable local environment across machines.
# WHAT:
#   Runs: check-prereqs → install → install-node → install-k6 → create-dirs.
# ---------------------------------------------------------------------
setup: ## 🏗️ Complete first-time setup (Python + Node + k6 + dirs)
	@$(MAKE) --no-print-directory check-prereqs
	@$(MAKE) --no-print-directory install
	@$(MAKE) --no-print-directory install-node
	@$(MAKE) --no-print-directory install-k6
	@$(MAKE) --no-print-directory create-dirs
	@printf "$(GREEN)✅ Setup complete$(NC) - Try: $(GREEN)make test-all$(NC)\n"


# ---------------------------------------------------------------------
# ⚙️ Installers
# WHY:
#   Ensure required runtimes/packages for each suite are present.
# WHAT:
#   Node/Playwright for web tests; k6 binary for perf tests.
# ---------------------------------------------------------------------
install-node:
	@printf "$(BLUE)🧩 Installing Node.js dependencies (for Playwright tests)$(NC)\n"
	@if ! command -v node >/dev/null 2>&1; then \
		printf "$(YELLOW)⚠️  Node not found. Installing via Homebrew...$(NC)\n"; \
		brew install node || printf "$(RED)❌ Failed to install Node$(NC)\n"; \
	fi
	@if [ -f tests/web/package.json ]; then \
		cd tests/web && npm install && npx playwright install --with-deps; \
	else \
		printf "$(YELLOW)⚠️  No web tests found; skipping Node deps$(NC)\n"; \
	fi


install-k6:
	@printf "$(BLUE)⚡ Checking k6 installation$(NC)\n"
	@if ! command -v k6 >/dev/null 2>&1; then \
		printf "$(YELLOW)⚠️  k6 not found. Installing via Homebrew...$(NC)\n"; \
		brew install k6 || printf "$(RED)❌ Failed to install k6$(NC)\n"; \
	else \
		printf "$(GREEN)✅ k6 already installed$(NC)\n"; \
	fi


# ---------------------------------------------------------------------
# 🔎 Prerequisite Check
# WHY:
#   Fail fast if core tools are missing; show versions for quick triage.
# WHAT:
#   Requires Node and Python; k6 is optional (perf suite will be skipped).
# ---------------------------------------------------------------------
check-prereqs: ## Check for Node, Python, and k6 (optional)
	@printf "$(BLUE)Checking prerequisites...$(NC)\n"
	@command -v node >/dev/null 2>&1 || { printf "$(RED)❌ Node.js not found$(NC)\n"; exit 1; }
	@printf "$(GREEN)✅ Node.js %s$(NC)\n" "$$(node --version)"
	@command -v python3 >/dev/null 2>&1 || { printf "$(RED)❌ Python3 not found$(NC)\n"; exit 1; }
	@printf "$(GREEN)✅ Python %s$(NC)\n" "$$(python3 --version)"
	@command -v k6 >/dev/null 2>&1 && printf "$(GREEN)✅ k6 %s$(NC)\n" "$$(k6 version --quiet)" || printf "$(YELLOW)⚠️  k6 not found (perf will be skipped)$(NC)\n"


# ---------------------------------------------------------------------
# 📦 Dependency Install
# WHY:
#   Bring web (Playwright) and API (pytest) stacks to a known-good state.
# WHAT:
#   npm install + install Chromium; upgrade pip; install API requirements.
# ---------------------------------------------------------------------
install: ## Install web (Playwright) + API (pytest) dependencies
	@printf "$(BLUE)Installing dependencies...$(NC)\n"
	@cd tests/web && npm install
	@cd tests/web && npx playwright install chromium --with-deps || npx playwright install chromium
	@python3 -m pip install --upgrade pip
	@python3 -m pip install -r tests/api/requirements.txt
	@printf "$(GREEN)✅ Dependencies installed$(NC)\n"


# ---------------------------------------------------------------------
# 📂 Directory Prep
# WHY:
#   Ensure artifact/report folders exist so all suites write to predictable paths.
# WHAT:
#   Create canonical directories for results, reports, and transcripts.
# ---------------------------------------------------------------------
create-dirs: ## Create report and output folders
	@mkdir -p \
		$(RESULT_DIR) \
		tests/web/playwright-report \
		$(PERF_DIR) \
		reports/bugs/evidence \
		agent-evals/transcripts


##@ Run full suite of tests
# ---------------------------------------------------------------------
# 🚦 Test-All Orchestrator
# WHY:
#   Provide a single command to run all suites and produce a readable summary.
# WHAT:
#   Orchestrates: smoke → web → api → perf, then prints the summary and status line.
# ---------------------------------------------------------------------
test-all: test-smoke test-web test-api test-perf ## Run smoke + web + API + perf
	@$(MAKE) --no-print-directory summary
	@$(MAKE) --no-print-directory status


##@ Testing
# ---------------------------------------------------------------------
# 🔍 Smoke Tests
# WHY:
#   Validate environment reachability to de-risk deeper suites.
# WHAT:
#   Run lightweight GET calls against public endpoints and classify outcomes.
# HOW:
#   Parse pytest output; fail only on true failures/errors. Record a simple pass marker.
# ---------------------------------------------------------------------
test-smoke: create-dirs ## Run reachability checks (web + APIs) and print a pass/fail summary
	@printf "$(BLUE)🔍 Smoke Tests$(NC)\n"
	@python3 -m pytest tests/integration/smoke_integration.py -v --disable-warnings --tb=short --no-header \
		| tee $(SMOKE_LOG)
	@printf "\n"
	@if grep -Eqi "(FAILED|ERROR)" $(SMOKE_LOG); then \
		printf "$(RED)❌ Smoke failed$(NC)\n"; \
		rm -f $(SMOKE_MARK); \
	else \
		printf "$(GREEN)✅ Smoke passed$(NC)\n"; \
		printf "PASS\n" > $(SMOKE_MARK); \
	fi
	@printf "$(BLUE)📋 Summary of Smoke Tests$(NC)\n"
	@grep -E "PASSED|FAILED|XFAIL" $(SMOKE_LOG) | \
		sed -E 's/.*::test_([a-zA-Z0-9_]+).* (PASSED|FAILED|XFAIL).*/\1 \2/' | \
		while read name status; do \
			if [ "$$status" = "PASSED" ]; then icon="✅"; \
			elif [ "$$status" = "XFAIL" ]; then icon="⚠️"; \
			else icon="❌"; fi; \
			printf "   %s %s\n" "$$icon" "$$name"; \
		done
	@printf "\n"


# ---------------------------------------------------------------------
# 🌐 Web E2E (Playwright)
# WHY:
#   Exercise core user journeys and a11y checks against the demo app.
# WHAT:
#   Runs `npm test` and persists the raw output to $(WEB_LOG) for parsing.
# HOW:
#   Strip ANSI sequences post-run so grep-based summaries stay reliable.
# ---------------------------------------------------------------------
test-web: ## Run Playwright E2E (includes a11y)
	@printf "$(BLUE)🌐 Web E2E (Playwright)$(NC)\n"
	@cd tests/web && npm test 2>&1 | tee $(abspath $(WEB_LOG)) >/dev/null || { printf "$(RED)❌ Web failed$(NC)\n"; exit 1; }
	@perl -i -pe 's/\e\[[0-9;]*[A-Za-z]//g' $(WEB_LOG) || true
	@printf "$(GREEN)✅ Web passed$(NC)\n"


# ---------------------------------------------------------------------
# 🔌 API Tests (pytest)
# WHY:
#   Validate schema shape, echo behavior, and idempotency using public APIs.
# WHAT:
#   Verbose pytest run with JUnit XML and plain-text logs; show skip/xfail summary.
# HOW:
#   Strip ANSI sequences so downstream grep works; honor pytest exit code.
# ---------------------------------------------------------------------
test-api: ## Run pytest-based API tests with readable per-test summary
	@printf "$(BLUE)🔌 API Tests (pytest)$(NC)\n"
	@mkdir -p $(RESULT_DIR)
	@{ \
		echo "# 🧪 Running pytest with detailed summary..."; \
		python3 -m pytest tests/api \
			-v -ra --color=yes --tb=short --disable-warnings --maxfail=1 \
			--junit-xml=$(API_JUNIT) \
		2>&1 | tee $(API_LOG) ; \
		STATUS=$${PIPESTATUS[0]}; \
		perl -i -pe 's/\e\[[0-9;]*[A-Za-z]//g' $(API_LOG) || true; \
		SKIPPED=$$(grep -Eo '[0-9]+ skipped' $(API_LOG) | tail -1 | awk '{print $$1}'); \
		XFAILED=$$(grep -Eo '[0-9]+ xfailed' $(API_LOG) | tail -1 | awk '{print $$1}'); \
		[ -z "$$SKIPPED" ] && SKIPPED=0; \
		[ -z "$$XFAILED" ] && XFAILED=0; \
		echo ""; \
		printf "$(YELLOW)ℹ️  Summary — Skipped: $$SKIPPED  ·  XFailed: $$XFAILED$(NC)\n"; \
		if [ "$$STATUS" -eq 0 ]; then \
			printf "$(GREEN)✅ API passed$(NC)\n"; \
		else \
			printf "$(RED)❌ API failed$(NC)\n"; \
			exit $$STATUS; \
		fi; \
	}


# ---------------------------------------------------------------------
# ⚡ Performance (k6)
# WHY:
#   Provide a fast performance signal suitable for laptops and CI.
# WHAT:
#   Runs a micro-benchmark with k6; saves JSON summary, stdout, and warnings.
# HOW:
#   Wrap with `script` to keep the live progress bar; tee stdout for summary parsing.
# ---------------------------------------------------------------------
##@ Performance
test-perf: ## Baseline performance check with real k6 status bar; writes logs & mirrors k6 exit
	@printf "$(BLUE)⚡ Baseline Perf (k6) — $${K6_VUS:-1} VU • $${K6_DURATION:-60s} run$(NC)\n"
	@mkdir -p $(PERF_DIR)
	@{ \
		K6_LOG_LEVEL=$${K6_LOG_LEVEL:-error} \
		K6_PROGRESS=$${K6_PROGRESS:-0} \
		K6_VUS=$${K6_VUS:-1} \
		K6_DURATION=$${K6_DURATION:-60s} \
		K6_TARGET=$${K6_TARGET:-https://jsonplaceholder.typicode.com/posts/1} \
		script -q /dev/null k6 run \
			--console-output=$(PERF_OUT) \
			--summary-export=$(PERF_JSON) \
			tests/perf/baseline_perf.js \
			2> $(PERF_WARN) | tee $(PERF_STD); \
		rc=$${PIPESTATUS[0]}; \
		if [ "$$rc" -eq 0 ]; then \
			printf "$(GREEN)✅ Perf passed$(NC)\n"; \
			printf "PASS\n" > $(PERF_MARK); \
		else \
			printf "$(RED)❌ Perf failed (thresholds)$(NC)\n"; \
			printf "$(YELLOW)ℹ Saved warnings: $(PERF_WARN)$(NC)\n"; \
			printf "FAIL\n" > $(PERF_MARK); \
			if [ -s $(PERF_WARN) ]; then \
				printf "\n$(YELLOW)--- warn.log (tail) ---$(NC)\n"; tail -n 20 $(PERF_WARN); \
			fi; \
			if [ -s $(PERF_OUT) ]; then \
				printf "\n$(YELLOW)--- k6-output (tail) ---$(NC)\n"; tail -n 20 $(PERF_OUT); \
			fi; \
		fi; \
		exit $$rc; \
	}



# ---------------------------------------------------------------------
# 🎯 Perf Gate
# WHY:
#   Enforce SLOs programmatically from the exported k6 JSON.
# WHAT:
#   Checks p95 latency and error rate thresholds to gate a release.
# ---------------------------------------------------------------------
perf-gate: ## Enforce perf SLOs by reading the k6 JSON (p95 + error rate)
	@python3 tests/perf/perf_gate.py $(PERF_JSON)


##@ Reports & Results
# ---------------------------------------------------------------------
# 🧭 Report Pointers
# WHY:
#   Provide quick paths to open or inspect latest artifacts.
# WHAT:
#   Print locations for Playwright HTML, text logs, and k6 JSON summary.
# ---------------------------------------------------------------------
report: ## Print where to find reports and results
	@printf "$(BLUE)Web report:$(NC) tests/web/playwright-report/index.html\n"
	@printf "$(BLUE)Web results:$(NC) $(WEB_LOG)\n"
	@printf "$(BLUE)API results:$(NC) $(API_LOG)\n"
	@printf "$(BLUE)Perf summary:$(NC) $(PERF_JSON)\n"


# ---------------------------------------------------------------------
# 🖱️ Open Web Report (macOS)
# WHY:
#   Shortcut to view the Playwright HTML report locally.
# WHAT:
#   Opens the report if present; otherwise prints a helpful hint.
# ---------------------------------------------------------------------
open-report: ## Open Playwright HTML report (macOS open)
	@[ -f tests/web/playwright-report/index.html ] && open tests/web/playwright-report/index.html || printf "$(YELLOW)⚠️  No report. Run 'make test-web'.$(NC)\n"


# ---------------------------------------------------------------------
# 📊 Quick Status Line
# WHY:
#   Show a fast, human-friendly PASS/NR snapshot after any run.
# WHAT:
#   Derives per-suite status from presence of artifacts/logs.
# ---------------------------------------------------------------------
status: ## Show quick PASS or NR per suite
	@echo "Smoke: $$([ -f $(SMOKE_MARK) ] && echo '✅' || echo 'NR')  Web: $$(( [ -f tests/web/playwright-report/index.html ] || ( [ -f $(WEB_LOG) ] && grep -q 'passed' $(WEB_LOG) ) ) && echo '✅' || echo 'NR')  API: $$([ -f $(API_JUNIT) ] && echo '✅' || echo 'NR')  Perf: $$([ -f $(PERF_JSON) ] && echo '✅' || echo 'NR')"


##@ Validation & Gates
# ---------------------------------------------------------------------
# 🧰 Validate (Aggregate)
# WHY:
#   Provide a single gating step after running all suites.
# WHAT:
#   Requires API pass signal and an agent-evals results file.
# ---------------------------------------------------------------------
validate: test-all ## Run suites and check simple release gates
	@$(MAKE) --no-print-directory check-gates


# ---------------------------------------------------------------------
# 🚧 Gate Checks
# WHY:
#   Keep release criteria explicit and simple.
# WHAT:
#   Grep API logs for "passed" and require agent eval results.
# ---------------------------------------------------------------------
check-gates: ## Enforce basic release criteria
	@grep -q "passed" test-results/api-results.txt && printf "$(GREEN)✅ API gate$(NC)\n" || { printf "$(RED)❌ API gate failed$(NC)\n"; exit 1; }
	@[ -f agent-evals/results.md ] && printf "$(GREEN)✅ Agent eval results found$(NC)\n" || { printf "$(RED)❌ Missing agent-evals/results.md$(NC)\n"; exit 1; }
	@printf "$(GREEN)✅ Gates satisfied$(NC)\n"


##@ Maintenance
# ---------------------------------------------------------------------
# 🧹 Clean (Artifacts Only)
# WHY:
#   Remove generated artifacts to keep the repo tidy between runs.
# WHAT:
#   Deletes reports, caches, and Python bytecode—safe and fast.
# ---------------------------------------------------------------------
clean: ## Remove generated results (quiet but informative)
	@printf "$(BLUE)🧹 Clean (artifacts only)$(NC)\n"
	@{ \
		ARTIFACT_DIRS="$(RESULT_DIR) tests/web/playwright-report tests/web/test-results tests/perf/results"; \
		for d in $$ARTIFACT_DIRS; do \
			if [ -e "$$d" ]; then \
				FILE_CT=$$(find "$$d" -type f 2>/dev/null | wc -l | tr -d ' '); \
				printf " - $(YELLOW)Removing$(NC) %s  (files: %s)\n" "$$d" "$$FILE_CT"; \
				rm -rf "$$d"; \
			fi; \
		done; \
		PYCACHE_CT=$$(find tests -name '__pycache__' -type d 2>/dev/null | wc -l | tr -d ' '); \
		if [ "$$PYCACHE_CT" -gt 0 ]; then \
			printf " - $(YELLOW)Removing$(NC) %s __pycache__ dirs\n" "$$PYCACHE_CT"; \
			find tests -name '__pycache__' -type d -prune -exec rm -rf {} +; \
		fi; \
		PYC_CT=$$(find tests \( -name '*.pyc' -o -name '*.pyo' \) -type f 2>/dev/null | wc -l | tr -d ' '); \
		if [ "$$PYC_CT" -gt 0 ]; then \
			printf " - $(YELLOW)Removing$(NC) %s *.pyc/*.pyo files\n" "$$PYC_CT"; \
			find tests \( -name '*.pyc' -o -name '*.pyo' \) -type f -delete; \
		fi; \
		printf "$(GREEN)✅ Clean complete$(NC)\n"; \
	}


# ---------------------------------------------------------------------
# 🧼 Clean-All (Deep)
# WHY:
#   Full reset when troubleshooting or prepping a clean environment.
# WHAT:
#   Runs `clean`, then removes Node deps, venv, caches, temp files.
# ---------------------------------------------------------------------
clean-all: ## Deep clean (quiet but informative)
	@printf "$(BLUE)🧼 Clean-All (deep)$(NC)\n"
	@$(MAKE) --no-print-directory clean
	@{ \
		EXTRA_PATHS="tests/web/node_modules tests/web/package-lock.json venv .pytest_cache tests/perf/results"; \
		for p in $$EXTRA_PATHS; do \
			if [ -e "$$p" ] || [ -L "$$p" ]; then \
				if [ -d "$$p" ]; then \
					FILE_CT=$$(find "$$p" -type f 2>/dev/null | wc -l | tr -d ' '); \
					printf " - $(YELLOW)Removing$(NC) %s (files: %s)\n" "$$p" "$$FILE_CT"; \
					rm -rf "$$p"; \
				else \
					printf " - $(YELLOW)Removing$(NC) %s\n" "$$p"; \
					rm -f "$$p"; \
				fi; \
			fi; \
		done; \
		DS_CT=$$(find . -name '.DS_Store' 2>/dev/null | wc -l | tr -d ' '); \
		if [ "$$DS_CT" -gt 0 ]; then \
			printf " - $(YELLOW)Removing$(NC) %s .DS_Store files\n" "$$DS_CT"; \
			find . -name '.DS_Store' -type f -delete; \
		fi; \
		printf "$(GREEN)✅ Clean-All complete$(NC)\n"; \
	}


# ---------------------------------------------------------------------
# 🔁 Reinstall
# WHY:
#   Convenience target for "nuke and pave" installs.
# WHAT:
#   Chains clean-all → setup to rebootstrap the environment.
# ---------------------------------------------------------------------
reinstall: clean-all setup ## Deep clean and reinstall


##@ CI/CD
# ---------------------------------------------------------------------
# 🤖 CI Entrypoint
# WHY:
#   Mirror the local workflow in CI for reproducible outcomes.
# WHAT:
#   Executes smoke → web → api → perf, then applies gate checks.
# ---------------------------------------------------------------------
ci: ## CI entrypoint for GitHub Actions
	@$(MAKE) --no-print-directory test-smoke
	@$(MAKE) --no-print-directory test-web
	@$(MAKE) --no-print-directory test-api
	@$(MAKE) --no-print-directory test-perf
	@$(MAKE) --no-print-directory check-gates



##@ Docs
# ---------------------------------------------------------------------
# 📚 Docs Index
# WHY:
#   Point contributors to canonical strategy, agent eval, performance,
#   and bug report documentation.
# WHAT:
#   Prints stable paths organized by category for quick reference.
# ---------------------------------------------------------------------
docs: ## List all key documentation files
	@printf "$(BLUE)📘 Documentation Files:$(NC)\n"
	@printf "\n$(BLUE)📂 Strategy & Planning:$(NC)\n"
	@printf "  strategy/TEST_STRATEGY.md\n"
	@printf "  strategy/TRACEABILITY_MATRIX.md\n"
	@printf "\n$(BLUE)📂 Agent Evaluations:$(NC)\n"
	@printf "  agent-evals/README.md\n"
	@printf "  agent-evals/prompts.md\n"
	@printf "  agent-evals/rubric.md\n"
	@printf "  agent-evals/results-template.md\n"
	@printf "  agent-evals/results.md\n"
	@printf "\n$(BLUE)📂 Performance:$(NC)\n"
	@printf "  tests/perf/PERF_PLAN.md\n"
	@printf "\n$(BLUE)📂 Bug Reports:$(NC)\n"
	@printf "  reports/bugs/BUG_TEMPLATE.md\n"
	@printf "  reports/bugs/BUG-001-a11y-sort-select-label.md\n"
	@printf "  reports/bugs/BUG-002-login-error-literal-sadface.md\n"
	@printf "  reports/bugs/BUG-003-api-put-no-persist.md\n"
	@printf "\n$(BLUE)📂 Main Documentation:$(NC)\n"
	@printf "  README.md\n"
	@printf "\n"


# ---------------------------------------------------------------------
# 📦 Full TestForge Run Summary
# WHY:
#   Provide a single, human-readable roll-up across all suites to finish the run.
# WHAT:
#   Reads suite artifacts/logs and prints normalized lines for:
#     - Smoke: pass flag + passed count + duration
#     - Web (PW): pass/NR + passed count + duration + skipped count
#     - API (pytest): pass/fail + passed count + duration (from text log)
#     - Perf (k6): pass/NR + the exact "Perf summary:" banner line
# HOW:
#   Uses grep-only parsing on the saved logs; for perf, it also strips CR/ANSI
#   due to PTY progress output. No behavior changes—purely a reporting shim.
# ---------------------------------------------------------------------
summary: ## Print consolidated run results for Smoke, Web, API, Perf
	@printf "$(BLUE)────────────────────────────────────────────────────────$(NC)\n"
	@printf "$(BLUE)📦 Full TestForge Run Summary$(NC)\n"
	@printf "$(BLUE)────────────────────────────────────────────────────────$(NC)\n"
	@SMK_STATUS=$$([ -f "$(SMOKE_MARK)" ] && echo "✅" || echo "❌"); \
	SMK_LINE=$$(grep -Eo '[0-9]+ passed in [0-9.]+s' "$(SMOKE_LOG)" 2>/dev/null | tail -1); \
	printf "🔍 Smoke       : %s %s\n" "$$SMK_STATUS" "$${SMK_LINE:-0 passed in ?s}"
	@WEB_LINE=$$(grep -Eo '[0-9]+ passed \([0-9.]+s\)' "$(WEB_LOG)" 2>/dev/null | tail -1); \
	WEB_SK=$$(grep -Eo '[0-9]+ skipped' "$(WEB_LOG)" 2>/dev/null | tail -1 | cut -d' ' -f1); \
	WEB_STATUS=$$([ -n "$$WEB_LINE" ] && echo "✅" || echo "NR"); \
	printf "🌐 Web (PW)    : %s %s · %s skipped\n" "$$WEB_STATUS" "$${WEB_LINE:-0 passed (?s)}" "$${WEB_SK:-0}"
	@API_LINE=$$(grep -Eo '[0-9]+ passed in [0-9.]+s' "$(API_LOG)" 2>/dev/null | tail -1); \
	API_FAIL=$$(grep -E '^(=+ FAILURES =+|FAILED )' "$(API_LOG)" 2>/dev/null | wc -l | tr -d ' '); \
	API_STATUS=$$([ "$$API_FAIL" -eq 0 ] && [ -n "$$API_LINE" ] && echo "✅" || echo "❌"); \
	printf "🔌 API (pytest): %s %s\n" "$$API_STATUS" "$${API_LINE:-0 passed in ?s}"
	@PERF_SUM=$$( [ -f "$(PERF_STD)" ] && cat "$(PERF_STD)" \
		| tr -d '\r' \
		| perl -pe 's/\e\[[0-9;]*[A-Za-z]//g' \
		| grep -m1 'Perf summary:' || true ); \
	[ -z "$$PERF_SUM" ] && PERF_SUM="Perf summary: p95=? errors=?"; \
	PERF_STATUS=$$([ -f "$(PERF_MARK)" ] && grep -q "PASS" "$(PERF_MARK)" && echo "✅" || { [ -f "$(PERF_JSON)" ] && echo "❌" || echo "NR"; }); \
	printf "⚡ Perf (k6)   : %s %s\n" "$$PERF_STATUS" "$$PERF_SUM"