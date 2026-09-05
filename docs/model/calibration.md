# Calibration

Harness: `packages/stadtbau_sim/tool/calibrate.dart` (`dart run tool/calibrate.dart
[--json]`). It builds seven 16×16 archetypes, pre-populates housing to 90 %,
runs 60 months and prints indicators and raw values. Coefficients are adjusted
only in `data/params/tiles.json`.

## Plausibility ranges and results (2026-09-05)

| Archetype | Quantity | Expected | Result |
|---|---|---|---|
| forest | biodiversity | 85–100 | 92 |
| forest | ΔT | 0 °C | 0.00 |
| meadow | ΔT (rural reference) | 0 °C | 0.00 |
| cropland | air index | > 90 | 96 |
| village (EFH, one shop) | share of residents > 55 dB(A) | < 10 % | 4 % |
| village | mean commute | 3–6 km | 4.2 |
| village | car share | 0.35–0.6 | 0.44 |
| suburb (EFH grid, arterials) | car share | 0.5–0.8 | 0.55 |
| suburb | biodiversity | 30–50 | 40 |
| dense quarter (MFH, 4 arterials) | population | 15 000–25 000 | 21 400 |
| dense quarter | residents > 55 dB(A) | 50–80 % | 67 % |
| dense quarter | air index | 60–85 | 80 |
| dense quarter | ΔT | 1–2.5 °C | 1.6 |
| dense quarter | max road traffic | 3 000–10 000 | 4 000 |
| all levels | solvable with three stars by the plans in `test/level_solutions_test.dart` | yes | yes |
| industrial park with housing | residents > 55 dB(A) | > 50 % | 63 % |
| industrial park | housing score | < 30 (jobs without homes) | 15 |
| mixed town | shopping | > 70 | 84 |
| mixed town | budget delta | positive | +765 k€/month |

## Performance (T-115)

Dense 24×24 map, 18 700 residents, 16 300 jobs: 38 ms per tick on a heavily
loaded 4-core VPS (load average ≈ 17), down from 180 ms before routing trips
per road pair, pruning noise paths and computing fields once per tick.
Commute (22 ms) and noise (7 ms) dominate; see `benchmark/tick_benchmark.dart`.

## Open calibration questions

- Road traffic on arterials stays below real-world 10–20 000 vehicles/day
  because a 2.5 km² map has no through-traffic beyond the 2 000 baseline. A
  level-level "regional traffic" parameter could scale the baseline.
- Budget surpluses are large once a quarter is full; costs of schools, social
  infrastructure and transport are not modelled (Phase 5).
- Noise exposure in the dense quarter is dominated by the sum of many 50 dB
  building sources; verify apartment-block emission against TA Lärm practice.
