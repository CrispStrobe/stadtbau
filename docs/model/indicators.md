# Indicators

Code: `packages/stadtbau_sim/lib/src/indicators.dart`. All scores are 0–100.
"Resident-weighted" means weighted by residents per cell, falling back to
housing capacity (new, empty housing) and then to a plain map mean.

| Indicator | Formula |
|---|---|
| Biodiversity | `B` from `biodiversity.md` |
| Air quality | resident-weighted air index |
| Quiet (noise) | resident-weighted `clamp((65 − L) / 10)` × 100 |
| Housing | `100 · min(1, capacity / (jobs / 0.52)) · (0.5 + 0.5 · occupancy)`; 0 without housing |
| Economy | `100 · (0.6 · min(1, jobs / workers) + 0.4 · trend)`, trend 1 if the last month was positive, else `clamp(1 + Δbudget / 500 k€)` |
| Shopping | resident-weighted retail access × 100 |
| Recreation | resident-weighted `0.7 · green access + 0.3 · (1 − ΔT / UHI_max)` × 100 |
| Commuting | `100 · (0.5 · (1 − min(1, d̄ / 20 km)) + 0.5 · (1 − car share))` (20 km ≈ MiD 2017 mean commute plus margin) |
| Climate | `100 · (0.7 · clamp(1 − CO₂ per person / 2.5 t) + 0.3 · (1 − ΔT̄ / UHI_max))`, persons = residents + jobs, floored at cells / 10 |
| Budget | `clamp(budget / starting budget) × 100` |

Raw values shown alongside: population, capacity, jobs, budget and monthly
delta, mean noise dB(A), mean air index, mean commute km, car share, CO₂ t/a,
mean ΔT, effective habitat area and connectivity.
