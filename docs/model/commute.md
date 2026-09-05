# Commuting and traffic

Code: `packages/stadtbau_sim/lib/src/model/commute.dart`. Parameters: `commute.*`.

## Model

1. **Workers.** `W_i = P_i · 0.52` (Destatis: employed persons ÷ population).
2. **Local share.** `f_local = min(1, J_total / W_total)`; the rest commute out
   (15 km, MiD 2017 mean for out-commuters, initial estimate). Unfilled jobs
   are taken by in-commuters (`J_total − W_total`).
3. **Distribution.** Local workers of cell `i` go to job cell `j` in proportion
   to `jobs_j · exp(−d_ij / 2 km)` (gravity kernel, shared with job access).
4. **Mode share by distance** (MiD 2017 Ergebnisbericht and MiD 2017 Analysen
   zum Rad- und Fußverkehr, rounded):

   | one-way distance | walk | bike | car |
   |---|---|---|---|
   | ≤ 1 km | 0.55 | 0.20 | 0.25 |
   | 1–3 km | 0.15 | 0.35 | 0.50 |
   | > 3 km and external | 0.02 | 0.13 | 0.85 |

5. **Traffic assignment.** Car trips (× 2 for the return) enter the road
   network at the nearest main road within 300 m of origin and destination and
   follow the shortest road path (breadth-first search over 4-connected road
   cells). External trips leave via the nearest border road. Every main road
   carries 2 000 vehicles/day of through traffic as a baseline.
6. **Outputs.** Vehicles/day per road cell (feeds noise and air), mean commute
   distance and car share per residential cell, total car-km per weekday
   (× 20 days × 12 months × 0.15 kg CO₂/km for the climate balance).

## Feedback loops

- More jobs than housing → in-commuters → traffic, noise, pollution.
- Housing without nearby jobs → long car commutes → traffic and CO₂.
- Housing without a main road within 300 m → attractiveness × 0.7.

## References

- Mobilität in Deutschland 2017, Ergebnisbericht (BMVI/infas):
  https://www.mobilitaet-in-deutschland.de/archive/pdf/MiD2017_Ergebnisbericht.pdf
- MiD 2017, Analysen zum Rad- und Fußverkehr:
  https://www.mobilitaet-in-deutschland.de/archive/pdf/MiD2017_Analyse_zum_Rad_und_Fussverkehr.pdf
- Destatis, Erwerbstätigenrechnung
- Umweltbundesamt, Emissionsdaten Pkw (≈ 150 g CO₂/km Flottenmittel)
