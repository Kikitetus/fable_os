# JITX-class AI PCB design: feasibility

Scope: build-vs-reuse decision for fable_os, based on JITX public docs/GitHub and the open ecosystem as of 2026-11-01. JITX web pages were mostly unreachable; [snippet] marks claims taken from search-result text.

## Verdict

**Partly.** A JITX-shaped workflow (Python design-as-code, an AI agent that writes the design, deterministic checks, an HFSS loop) is buildable here on top of KiCad, Freerouting, PyEDB/PyAEDT and our own agent layer. A JITX-comparable *product* is not: JITX's value is in closed deterministic engines (topological autorouter with BGA escape and via fencing, pin-assignment solver, SI constraint engine, DRC, exporters) that appear in no public repo (jitx-skills/skills/jitx-physical-layout/SKILL.md, jitx-skills/skills/jitx-pin-assignment/SKILL.md). "From scratch" means rewriting those, and that is a multi-year effort.

What makes it hard:
1. SI-aware routing. Nothing open autoroutes a board end to end with diff-pair, length-match, BGA-escape and via-fence constraints; atopile, tscircuit, SKiDL, edg and circuit-synth all hand off to KiCad (https://github.com/atopile/atopile, https://github.com/tscircuit/tscircuit, https://github.com/devbisme/skidl, https://github.com/BerkeleyHCI/PolymorphicBlocks, https://github.com/circuit-synth/circuit-synth). Freerouting is the only open router and has no SI constraint model (https://github.com/freerouting/freerouting).
2. Footprint and component correctness. JITX gates MPN/package choice and footprint consent on a human (jitx-skills/skills/jitx/references/project-builder-flow.md). A wrong footprint is a scrapped board; an LLM cannot verify one from a datasheet alone.
3. Parts data. JITX queries eight distributors (https://docs.jitx.com/en/latest/jitxlib/jitxlib.parts.query_api.html [snippet]). Open options are JLC-only (jlcparts) or rate-limited (Octopart 100 parts free tier, Mouser 1,000 calls/day [snippet]).
4. The HFSS bridge is unproven. PyEDB imports IPC-2581/ODB++ but not .kicad_pcb or Gerber, and kicad-cli IPC-2581/ODB++ → PyEDB is untested (https://github.com/ansys/pyedb). License terms for non-graphical runs are unverified.
5. IP. jitx-skills is proprietary (jitx-skills/LICENSE); the agent layer must be written independently.

Rough effort (team assumption stated):
- **Internal workflow** — agent + KiCad/Freerouting glue + HFSS loop for one board class (e.g. a few differential lanes on a 4–8 layer board): 1–2 engineers, 3–6 months to a gated pipeline. Realistic.
- **JITX-comparable product** — own SI-aware router, pin-assignment solver, parts network, Altium/Siemens integrations: 5–8 engineers, 2–3 years. For scale: JITX raised a $12M Series A in 2022 (https://www.jitx.com/blog/series-a-announcement [snippet]) and still does not autoroute general boards, only constrained structures (jitx-examples/jumpstart-kits/shared/JITX_Architecture_and_Systems_Requirements_v2_0.md).

Fit of this repo and container: fable_os is suited to maintaining the glue code (parsers, constraint checkers, gates, tests on fixture files) in 200-line increments with machine-checkable done_when and verify.sh as the vote. It is not suited to running the toolchain: the container has no KiCad, no HFSS, and the network policy blocks jitx.com, kicad.org and ansyshelp.ansys.com. KiCad, Freerouting and all Ansys steps run on the user's workstation, reached via Remote Control (Mac/Linux only) or by running Claude Code locally there.

## What JITX is

- "Software-defined electronics" (https://www.jitx.com/ [snippet]): the board is a Python program; the runtime builds geometry, routes constrained structures, enforces fab rules, generates simulation setups, and exports ODB++/STEP/BOM (architecture doc, local path above; web copy https://docs.jitx.com/en/latest/jumpstart-kits/shared/JITX_Architecture_and_Systems_Requirements_v2_0.html).
- On-prem, per-seat annual subscription, no hosted backend; cloud only for licensing, auth, updates, support uploads. Free tier for CERN-OHL-P v2 open designs; Professional/Enterprise quote-based (https://www.jitx.com/plans [snippet]).
- "JITX does not bundle an AI." The customer's assistant (Claude Code or Codex) writes design code using jitx-skills. Engines are "conventional deterministic algorithms" with "no ML models" (architecture doc).
- HFSS/Q3D run under the customer's own AEDT license; handoff by EDB export, raw S-parameters/TDR/fields back (architecture doc). Analytic SI constraints: dB/mm loss per layer, impedance per routing structure, COM-style figure of merit (https://docs.jitx.com/en/latest/essentials/SI/constraints.html [snippet]).
- 2025 additions: AI-written component code from datasheets, topological autorouter (8 vs 6 traces on one chiplet package), RF via-fence generation, Stanza→Python move (https://blog.jitx.com/jitx-corporate-blog/whats-new-in-jitx-2025 [snippet]; https://jobs.lever.co/jitxinc/0a97f3ef-57ee-4ce0-a218-579eb36a25f3 [snippet]). STANZA_MAX_HEAP_SIZE in the requirements shows the runtime is still Stanza-derived.
- VS Code extension with schematic/board viewers (https://docs.jitx.com/en/latest/getting-started/using-vscode.html [snippet]); Altium and Siemens Expedition integrations (https://docs.jitx.com/cad-integration/altium-install.html [snippet]).
- JITX's own 2024 test: a generative-AI circuit came out at 3x the cost and size of an expert TI design (https://blog.jitx.com/jitx-corporate-blog/testing-generative-ai-for-circuit-board-design [snippet]). Their product answer was deterministic engines plus human gates, not a bigger model.
- Python 3.12+, Windows/macOS/Linux, 16–32 GB RAM routine, 64–128 GB large (architecture doc).

## What their GitHub contains

https://github.com/JITx-Inc: 10 own public repos plus forks (stanzapm, OdbDesign AGPL, conan). Updated through 2026-10-30. The core `jitx`/`jitxlib` runtime is in no repo; it installs from pypi.jitx.com and runs as a local websocket runtime behind the `jitx` CLI (jitx-skills/skills/jitx/SKILL.md). No MCP server anywhere.

- **jitx-skills** v1.7.0 (jitx-skills/.claude-plugin/plugin.json): 9 skills — base/CLI, component-modeler, circuit-builder, substrate-modeler, physical-layout, interconnect-constraints, pin-assignment, code-review, mechanical. Workflow: requirements → PLAN.md/ARCHITECTURE.md → substrate + components → constraints/pin assignment/circuits → top level → four-pass audit → `jitx build` + viewer DRC/SI (jitx-skills/skills/jitx/references/project-builder-flow.md). **License is proprietary** — no copying, modification or derivative works (jitx-skills/LICENSE), contradicting the architecture doc's "open jitx-skills bundle". Treat as read-only reference for *what* a skill must cover; do not reuse text or structure.
- **jitx-examples** (no LICENSE): ~70 components, a 20-layer substrate, an SI BGA-escape demo with an HFSS-instrumented lane (jitx-examples/src/jitxexamples/demos/si_bga_optimization/si_geometry.py, .../bga_escape.py). Useful as a spec of the API surface (jitx.circuit, jitx.net, jitx.si, jitx.board, jitx.stackup, jitx.via, jitx.model3d; example jitx-examples/src/jitxexamples/components/opamps/texas_instruments_OPA189.py). No license means no reuse of code.
- **MIT utilities**: py-jitx-mechanical (DXF/IDF import, DXF export), jitx-pnp and jitx-refdes (consume "JITX XML board export"), jitx-emn-importer, jitx-protocols-ext (DDR4/5, LPDDR4/5, GDDR7, JESD204, PCIe, SATA, SFP constraint bundles; jitx-protocols-ext/src/jitx_protocols_ext/protocols/pcie.py). All depend on the closed `jitx` package (pinned jitx==4.4.2 in py-jitx-mechanical/.github/workflows/ci.yml); the protocol *numbers* are the reusable part, as a data reference.
- voltage-divider: proprietary classifier (voltage-divider/pyproject.toml); not reusable.

Net: the GitHub is an SDK periphery. Everything that makes JITX work is closed.

## Build vs. reuse

| capability | JITX | reuse (name, license) | build ourselves | difficulty |
|---|---|---|---|---|
| Design language/API | Python `jitx` package, closed; Circuit/Net/Port/Provide/Constrain | atopile (.ato, MIT); SKiDL 3.0.0 (MIT); edg 0.5.2 (BSD-3); circuit-synth 0.12.1 (MIT) | Thin Python DSL emitting KiCad netlist + constraint JSON; mirror JITX concepts, not code | Medium |
| Parts data, component modeling | 8-distributor query API [snippet]; cofactr_id in mocks (inference); AI datasheet→component | jlcparts (MIT); easyeda2kicad (AGPL-3.0, subprocess); kicad-symbols (CC-BY-SA 4.0); Octopart/Mouser APIs (quota-limited [snippet]) | Datasheet→pin-table extractor with human footprint consent gate | High (correctness) |
| Pin assignment | Solver in layout engine, provide/require, lane/byte swaps (closed) | None found | Constraint solver (bank/swap rules) over KiCad netlist; start with manual + lint | High |
| Schematic | Generated, VS Code viewer [snippet] | KiCad 10 (GPL-3.0, separate process); SKiDL schematic gen (MIT) | Not needed initially; netlist-first | Low |
| Placement | `.at(floating=True)` placer (closed) | kicad-python 0.8.0 (MIT, needs running KiCad) for scripted placement | Heuristic/force placement later; agent + human placement first | Medium |
| Routing, general | Topological autorouter (closed) | Freerouting 2.5.0 (GPL-3.0, `java -jar`, DSN→SES via kicad-cli specctra export) | No | Medium (quality limits) |
| Routing, SI-aware (diff pairs, length match, BGA escape, via fencing) | Constrained-structure routing, escape, fence generation | None; Freerouting lacks constraints | Own generators for escape patterns and via fences as KiCad geometry; post-route length checker | Very high |
| DRC/ERC | Runtime DRC + viewer | kicad-cli pcb drc / sch erc (https://github.com/KiCad/kicad-source-mirror/tree/master/kicad/cli); KiCad MCP server (MIT) | Custom rule checker on parsed .kicad_pcb | Low |
| Stackup/impedance | Substrate modeler, routing structures | KiCad stackup; scikit-rf 2.2.0 (BSD-3) | Analytic impedance/loss calculators; own stackup schema | Medium |
| SI/PI analysis | HFSS/Q3D via EDB, SPICE, analytic COM-style FoM [snippet] | PyAEDT 1.9.0 (MIT), PyEDB 0.86.0 (MIT), ansys-aedt-mcp 0.3.1 (Apache-2.0); openEMS (GPL-3.0) as license-free fallback | Metric extraction and pass/fail on Touchstone | Medium; license/format risk |
| Mechanical | DXF/IDF/EMN import, STEP out | py-jitx-mechanical ideas (MIT, but tied to closed jitx); kicad-cli step export | DXF outline import for KiCad | Low |
| Outputs | ODB++, STEP, BOM, Altium/Siemens | kicad-cli gerbers, ipc2581, odb, ipcd356, step; BOM via kicad-python | None beyond glue | Low |
| AI agent layer (skills/MCP) | jitx-skills (proprietary); no MCP | KiCad MCP server (MIT, https://github.com/mixelpixx/KiCAD-MCP-Server); ansys-aedt-mcp | Our own skills, gates and done_when checks | Medium |

License cautions: KiCad, Freerouting, easyeda2kicad and openEMS are GPL/AGPL; invoke them as separate processes over files, never link or vendor. jitx-skills is proprietary (jitx-skills/LICENSE): write ours from scratch; no copying, paraphrasing or structural adaptation. jitx-examples has no license: do not reuse code. CC-BY-SA KiCad libraries require attribution.

## HFSS in the loop

Toolchain (design code → S-parameters → checks), all Ansys steps on the licensed workstation:

1. **Design code → KiCad.** Our Python DSL (cloud repo, fixtures-tested) emits netlist + constraint JSON; KiCad 10 builds `.kicad_pcb`; Freerouting routes via DSN/SES; kicad-cli runs DRC and exports **IPC-2581 or ODB++** (kicad-cli has both; https://github.com/KiCad/kicad-source-mirror/tree/master/kicad/cli).
2. **KiCad → EDB.** PyEDB `import_layout_file` accepts IPC-2581 XML and ODB++ TGZ/ZIP through AEDT's anstranslator; not Gerber, not `.kicad_pcb` (https://github.com/ansys/pyedb). This step is **untested** and is the Phase 0 experiment. PyEDB then sets stackup, materials, cutout around the lane, ports, and the sweep.
3. **EDB → HFSS 3D Layout → Touchstone.** PyAEDT drives the solve, `non_graphical` where licensing permits, `export_touchstone` writes `.sNp` (https://github.com/ansys/pyaedt). SIwave (2.5D) is the cheaper first pass; HFSS 3D Layout is full-wave (https://www.ansys.com/resource-center/white-paper/hfss-regions-siwave [snippet]).
4. **Touchstone → verdict.** scikit-rf parses `.sNp` (https://scikit-rf-official.readthedocs.io/en/latest/_modules/skrf/io/touchstone.html); our checker computes IL, RL, skew/TDR-derived impedance, mode conversion against thresholds in the design's spec file; exits nonzero on failure. Fully machine-checkable; this is the verify.sh hook.
5. **Back to design.** Claude reads the failing metrics and edits the design code (stackup, via geometry, fence pitch, trace width) and reruns. Human reviews geometry changes before fab.

Roles: PyEDB = geometry/ports/stackup in the EDB database. PyAEDT = launching AEDT, solving, exporting. ansys-aedt-mcp 0.3.1 (Apache-2.0, Python 3.13+, stdio/HTTP, can launch AEDT; https://github.com/ansys/pyaedt-mcp) = the interactive handle for Claude on the workstation; batch runs should use plain PyAEDT scripts so results are reproducible and gate-able. Claude writes design code, simulation setup and interprets results; it does not click AEDT.

Where it runs: steps 1 (except DSL unit tests) through 4 on the workstation; the cloud repo holds code, fixtures and recorded Touchstone files so verify.sh can run without a license. Remote Control works only if the workstation is Mac or Linux; AEDT 2026 R1 supports Ubuntu 22.04/24.04, RHEL 8/9, SLES 15, Rocky [snippet] (https://ansyshelp.ansys.com/public/Views/Secured/corp/v261/en/installation/unix_sysprereqs.html). Otherwise run Claude Code locally on the workstation.

Confirm on the user's side: AEDT version and OS; whether HFSS 3D Layout, SIwave and Q3D are licensed, not only HFSS; license terms for non-graphical/batch solves (UNVERIFIED; also note Synopsys closed the Ansys acquisition 2025-07-17, https://news.synopsys.com/2025-07-17-Synopsys-Completes-Acquisition-of-Ansys [snippet], so terms may be changing); workstation OS for Remote Control; Python 3.13+ available there for ansys-aedt-mcp; whether anstranslator is present in the install.

## Phased plan

**Phase 0 — prove the HFSS bridge (2–3 weeks, 1 engineer + the user's workstation).**
Goal: one hand-drawn differential lane in KiCad goes through kicad-cli export → PyEDB import → HFSS/SIwave solve → Touchstone → automated pass/fail, with no manual AEDT steps.
- Scope: a 4-layer test board with one 100 Ω diff pair and a via transition, built by hand in KiCad; export IPC-2581 and ODB++; try both in PyEDB; set ports and a sweep; solve non-graphically; export `.s4p`; write `tools/check_sparam.py` (scikit-rf) with thresholds in `specs/lane.json`; record the Touchstone as a repo fixture.
- Exit: both export paths characterized (which imports cleanly, what stackup/material data is lost); batch solve under the user's license confirmed or ruled out; checker runs in the cloud container against the fixture.
- done_when: `test -s fixtures/phase0/lane.s4p && python -I tools/check_sparam.py fixtures/phase0/lane.s4p --spec specs/lane.json`
- New dependencies to propose in loop/memory/STATE.md (proposals only): scikit-rf 2.2.0 (BSD-3), PyEDB 0.86.0 (MIT), PyAEDT 1.9.0 (MIT), KiCad 10.x (GPL-3.0, workstation binary, subprocess only), ansys-aedt-mcp 0.3.1 (Apache-2.0, optional, workstation only).

**Phase 1 — code-first board kernel (6–8 weeks).**
Goal: a Python design file produces a DRC-clean, routed KiCad board with BOM and Gerbers, with no human in the loop except a footprint-consent gate.
- Scope: DSL (components, nets, diff pairs, provide/require as plain data); KiCad netlist writer; component ingestion from kicad-symbols and easyeda2kicad (subprocess) with a consent record per footprint; agent-driven placement via kicad-python; Freerouting DSN/SES; kicad-cli drc, gerbers, ipc2581, odb, step; own skills (written clean-room) covering requirements, component modeling, review.
- Exit: three reference boards (power supply, MCU breakout, a 2-lane SERDES stub) build from code; DRC zero violations; footprint consent file present for every part.
- done_when: `./loop/guardrails/verify.sh && python -I tools/drc_gate.py out/ref/*.drc.json && python -I tools/consent_gate.py out/ref/*.bom.csv consents/`

**Phase 2 — SI constraints and structures (8–12 weeks).**
Goal: the DSL carries JITX-style constraints (impedance per routing structure, length/skew, protocol bundles) and the pipeline enforces them.
- Scope: stackup schema with analytic impedance and dB/mm loss; routing-structure definitions; post-route checker for length match, skew, diff-pair gap, reference-plane continuity on parsed `.kicad_pcb`; generators for BGA escape patterns and via fences as placed KiCad geometry; protocol constraint tables (own numbers from public specs; jitx-protocols-ext consulted only as a reference).
- Exit: the SERDES stub passes the constraint checker; a BGA escape generator produces fanout for one package family; Freerouting completes remaining nets without violating the pre-placed structures.
- done_when: `python -I tools/si_gate.py out/serdes/board.kicad_pcb specs/serdes.constraints.json && python -I tools/drc_gate.py out/serdes/board.drc.json`

**Phase 3 — closed simulation loop and release outputs (6–8 weeks).**
Goal: the agent iterates design code against HFSS/SIwave results to a passing spec, and emits a release bundle.
- Scope: simulation setup generated from constraints (ports, sweeps, metrics); PyAEDT batch runner on the workstation with run manifests committed as fixtures; agent loop with a bounded iteration count and human review of each geometry change; release gate for ODB++, STEP, BOM, Touchstone, DRC and constraint reports.
- Exit: the SERDES stub passes IL/RL/skew thresholds in simulation; the release bundle is produced by one command; verify.sh reproduces every gate from fixtures in the cloud container.
- done_when: `python -I tools/release_gate.py out/serdes/release/ --spec specs/serdes.constraints.json --sparam-spec specs/serdes.si.json`

Beyond Phase 3 (not funded by this plan): own SI-aware router, pin-assignment solver, parts network with purchasable-stock checks, Altium/Siemens export. That is the JITX moat; evaluate Quilter, Diode (MIT Rust `pcb` tool) and Flux before building it (https://www.quilter.ai/blog/pcb-software-subscriptions-in-2026-comparing-per-seat-vs-ai-powered-plans, https://www.pcbdirectory.com/news/diode-computers-develops-ai-powered-tools-to-revolutionize-pcb-design-and-manufacturing, https://pricingsaas.com/companies/flux/diffs/2026W44, all [snippet]).

## Risks

- **Legal/IP.** jitx-skills is proprietary and jitx-examples unlicensed; any derived skill text or component code is exposure. Mitigation: clean-room authoring from our own requirements list, a repo rule banning JITX-sourced text, and GPL/AGPL tools only as subprocesses (KiCad, Freerouting, easyeda2kicad, openEMS).
- **Footprint correctness.** Wrong pad geometry is discovered at assembly. Mitigation: human consent record per footprint (Phase 1 gate), prefer kicad-symbols/kicad-footprints and vendor-verified LCSC data, render-and-diff checks against datasheet drawings, and no unattended fab orders.
- **Router quality.** Freerouting cannot do constrained SI routing and may fail on dense BGAs; JITX's own router handles only constrained structures. Mitigation: pre-place escapes and fences as geometry (Phase 2), restrict Phase 1–3 to boards Freerouting completes, and budget the custom router as a separate decision.
- **HFSS licensing/automation.** Non-graphical batch terms are unverified; kicad-cli IPC-2581/ODB++ → PyEDB is untested; AEDT must be on the user's workstation, which the cloud container cannot run. Mitigation: Phase 0 settles both before further spend; SIwave or openEMS as fallbacks; record Touchstone fixtures so gates run without a license.
- **Agent reliability.** JITX's own test produced a 3x cost/size design [snippet]; LLM-authored circuits need deterministic checks. Mitigation: every phase gated by DRC/constraint/S-parameter scripts; the fable_os rule that a fresh-context verifier and verify.sh decide, not the author.
- **Parts data limits.** Octopart free tier 100 parts, Mouser 1,000 calls/day [snippet]; JLC-only coverage otherwise. Mitigation: cache queries, start JLC/LCSC-first, budget a paid tier before Phase 2.
- **Unverified JITX claims.** jitx.com, docs and blog were unreachable; tagline, pricing, 2025 feature list, router benchmark, SI constraint docs, Altium/Siemens integrations and the 3x test are [snippet]-sourced. Mitigation: re-verify from the user's network before quoting any of it externally; nothing in the phased plan depends on these claims.
- **Operational fit.** fable_os's 200-line commits and no-new-dependency rule slow a toolchain build, and the container cannot run KiCad/HFSS. Mitigation: propose the Phase 0 dependencies in STATE.md first; keep workstation runs as fixture-producing steps; split tooling into small verifiable tasks.
