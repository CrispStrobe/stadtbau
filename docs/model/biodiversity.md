# Habitat quality and biodiversity

Code: `packages/stadtbau_sim/lib/src/model/habitat.dart`. Parameters:
`habitat.*`, `tiles.*.biotopeValue`, `biotopeStart`, `recoveryMonths`.

## Model

1. **Base habitat** for nature and urban-green tiles:
   `H_i = (biotopeValue_i / 24) · maturity_i` with the BKompV Anlage 2 value
   (see `tiles.md`) and maturity growing with tile age.

2. **Threat degradation** after the InVEST Habitat Quality model. Each threat
   land use `r` has weight `w_r` and maximum distance `d_max,r` with linear
   decay:

   `D_i = clamp(Σ_r Σ_y w_r · (1 − d_iy / d_max,r) / 4, 0, 1)`

   (four adjacent full-weight threats saturate). Threats: road 1.0 / 300 m,
   industry 0.8 / 500 m, commercial 0.6 / 300 m, apartment blocks 0.5 / 200 m,
   detached housing 0.3 / 200 m.

   `Q_i = H_i · (1 − D_i^z / (D_i^z + k^z))`, `z = 2.5`, `k = 0.5` (InVEST
   defaults).

3. **Connectivity.** Habitat tiles form patches by 8-neighbourhood. With
   quality-weighted patch areas `A_p = Σ_{i∈p} Q_i`, the effective mesh size
   (Jaeger 2000) is `m_eff = Σ_p A_p² / A_total` and connectivity
   `c = m_eff / A_total ∈ (0, 1]` (1 = one patch).

4. **Biodiversity index.** Species–area relation `S ∝ A^z` with `z = 0.30`
   (habitat islands: 0.25–0.35):

   `B = 100 · (A_total / N)^0.30 · (0.5 + 0.5 · c)`.

## Behaviour

- All-forest map, mature: ≈ 92. Cutting it with a road cross: −15 to −20.
- Suburb with meadows in between: ≈ 40; dense quarter with one park: ≈ 26.
- Newly planted forest starts near a Vorwald value and reaches full value
  after 20 years, so afforestation pays off with delay.

## References

- BKompV Anlage 2 (biotope values): https://www.gesetze-im-internet.de/bkompv/anlage_2.html
- InVEST User Guide, Habitat Quality model (threat decay, half-saturation)
- Jaeger (2000): Landscape division, splitting index, and effective mesh size.
  Landscape Ecology 15, 115–130.
- MacArthur & Wilson (1967): The Theory of Island Biogeography; Arrhenius (1921).
