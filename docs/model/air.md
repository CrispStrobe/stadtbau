# Air pollution

Code: `packages/stadtbau_sim/lib/src/model/air.dart`. Parameters: `air.*` and
`tiles.*.airEmission`, `tiles.*.airSink`.

## Model

Relative emission rates `E` per tile (road 1.0 at 10 000 vehicles/day, industry
3.0, commercial 0.6, apartment blocks 0.3, detached housing 0.15, cropland 0.05).
Road emission scales linearly with traffic (EMEP/EEA road transport emissions ∝
vehicle-km).

Concentration at cell `i`:

`C_i = Σ_s E_s · k(d_si) / K`, `k(d) = exp(−d / 300 m)`, `K = Σ_k k(d_k)` over the
6-tile neighbourhood including the centre.

The normalisation `K` makes a uniform field of emitters produce `C = E`, and a
single emitter dilute with distance. The kernel is an isotropic near-field
simplification of a Gaussian plume; wind is task T-501.

Deposition: `C_i ← C_i · (1 − mean sink of the 3-tile neighbourhood)`, with sink
coefficients forest 0.20, park 0.10, meadow 0.05 (magnitudes after Nowak et al.
2006, i-Tree: urban trees remove a few percent of local PM and NO₂; the game
uses a larger local effect for legibility).

Index: `AQI_i = 100 · exp(−C_i / 1.0)`.

## Calibration (T-114)

| Archetype | Mean resident index |
|---|---|
| village | ≈ 92 |
| suburb | ≈ 89 |
| dense quarter | ≈ 80 |
| mixed town with industry | ≈ 73 |
| inside an industrial area | ≈ 5 |

## References

- EMEP/EEA air pollutant emission inventory guidebook 2023, chapters 1.A.3.b
  (road transport), 1.A.4 (small combustion), 2 (industrial processes)
- Nowak, Crane, Stevens (2006): Air pollution removal by urban trees and shrubs
  in the United States. Urban Forestry & Urban Greening 4, 115–123.
- Umweltbundesamt, Luftschadstoff-Emissionen in Deutschland
