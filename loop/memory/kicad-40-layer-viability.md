## Verdict

No. KiCad 10 cannot hold a 40-copper-layer board. The stackup cap is a compile-time constant of 32 copper layers (`MAX_CU_LAYERS 32`, F_Cu + In1_Cu…In30_Cu + B_Cu) in 10.0.8 (https://github.com/KiCad/kicad-source-mirror/blob/10.0.8/include/layer_ids.h), and master, the next-version development branch, still has the same cap as of 2026-11-01 (https://github.com/KiCad/kicad-source-mirror/blob/master/include/layer_ids.h). For the 40-layer ASIC board, use a commercial layout database and keep KiCad for the smaller boards.

If "40 layers" meant a total count that includes mask, silk, paste and mechanical layers, and the copper count is 32 or fewer, KiCad fits numerically; the verdict then becomes "viable but unproven at this scale" because performance on AI-ASIC pin/net counts is not verified.

## Why

- The limit is a compile-time `#define`, not a setting: KiCad cannot represent a 40-copper-layer stackup without changing its source and rebuilding it.
- A 40-layer AI ASIC board is the hardest-to-fabricate artifact in the program: HDI, backdrill, many diff pairs at high rate, tight impedance and delay windows. Betting it on an unverified tool path is a schedule risk independent of the layer cap.
- The KiCad → IPC-2581 → PyEDB import route is untested; PyEDB does not read `.kicad_pcb` or Gerber (https://github.com/ansys/pyedb). On a 40-layer board every stackup, padstack and backdrill detail must round-trip into HFSS correctly.
- Performance (zone fill, DRC time, netlist size) and multi-user editing at this scale are not verified. Treat them as unknowns, not strengths.

## What KiCad 10 does have

- Backdrill (`BACKDRILL_MODE`: bottom, top, both) and counterbore/countersink post-machining in the padstack model (https://github.com/KiCad/kicad-source-mirror/blob/10.0.8/pcbnew/padstack.h).
- Propagation-delay-based tuning: via, track, pad-to-die and per-layer delays with tuning profiles (https://github.com/KiCad/kicad-source-mirror/blob/10.0.8/pcbnew/length_delay_calculation/length_delay_calculation.h).
- kicad-cli: DRC, IPC-2581, ODB++, Specctra DSN, IPC-D-356, STEP, Gerbers (https://github.com/KiCad/kicad-source-mirror/tree/master/kicad/cli).
- Headroom in the layer ID space (even IDs 64–126 unassigned) means a higher cap is architecturally possible, but it is not implemented.

Those features make KiCad serious for boards up to 32 copper layers. They do not change the verdict for 40.

## What to use instead

Recommendation: (a) plus (d). Put the 40-layer board in a commercial layout database (Allegro, Xpedition or equivalent; specific layer limits and API names unverified here, but boards above 32 copper layers are routine industry practice in those tools). Our code-first/AI layer produces netlist, constraints, stackup definition and checks around it, and consumes its native or IPC-2581 output for the HFSS loop. Keep KiCad as the backend for every board at 32 copper layers or fewer: fixtures, power modules, breakouts, interposer test cards.

Rejected:
- (b) Own geometry engine emitting IPC-2581/ODB++: this is building a layout tool. Multi-year scope for a single board; the fab-ready DRC, padstack and backdrill correctness burden lands on us.
- (c) Fork KiCad to raise `MAX_CU_LAYERS`: feasible in principle via the unused IDs, but it likely touches the file format, stackup UI, exporters, DRC and router (scope unverified), and the fork must be carried across releases. Not worth it for one board compared with licensing a commercial tool.

## Impact on the JITX-style plan

- Phase 0 (HFSS bridge on one diff pair): unchanged in intent, but add a second import path. Validate PyEDB import from the commercial tool's native export (BRD or its IPC-2581) alongside the KiCad → IPC-2581 route, since the ASIC board will come through the former.
- Phase 1 (code-first board kernel): split the backend. The kernel targets an abstract board model; KiCad is one emitter (≤32 copper layers), the commercial tool is the other (netlist, constraint set, stackup via its scripting interface, exact API unverified). Add a layer-count check that refuses to emit a >32-copper stackup to KiCad.
- Phase 2 (SI constraints): author constraints once in our code and translate to both targets. KiCad's delay-tuning profiles cover the small boards; the commercial constraint manager covers the ASIC board.
- Phase 3 (closed simulation loop): the loop runs on IPC-2581 from whichever backend produced the board, so it is backend-agnostic by design. The ASIC board exercises the commercial path only.
- Freerouting is removed from the ASIC board's path entirely; routing of a 40-layer HDI board stays in the commercial tool (or hand/AI-assisted within it). Freerouting remains for the KiCad-side boards.
