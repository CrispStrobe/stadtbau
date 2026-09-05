# Urban heat

Code: `packages/stadtbau_sim/lib/src/model/heat.dart`. Parameters: `heat.*` and
`tiles.*.shade`, `albedo`, `eti`.

## Model (after InVEST Urban Cooling)

Cooling capacity per land cover:

`CC = 0.6 · shade + 0.2 · albedo + 0.2 · ETI`

(shade = canopy fraction ≥ 2 m, albedo = surface albedo, ETI = crop coefficient
scaled 0–1; weights are the InVEST recommended defaults).

Green patches (nature and urban green, 8-connected) of at least 2 ha cool
their surroundings: within `d_cool` (InVEST default 450 m; game: 3 tiles) the
heat mitigation index is

`HM_i = max(CC_i, max_j CC_j · (1 − d_ij / (d_cool + 1)))` over green cells `j`
of qualifying patches.

InVEST then writes `T_i = T_rural + UHI_max · (1 − HM_i)`. Because the rural
reference land cover itself has `HM ≈ 0.2–0.3`, the game rescales so that the
base terrain (meadow) has ΔT = 0 and the least cooling land cover (road) has
ΔT = UHI_max:

`ΔT_i = UHI_max · clamp((CC_meadow − HM_i) / (CC_meadow − CC_min), 0, 1)`

with `UHI_max = 3 °C` (user input in InVEST; DWD reports 2–4 K for German
mid-size cities).

## Calibration (T-114)

Mean resident ΔT: village 0.5 °C, suburb 0.7 °C, dense quarter 1.6 °C, all-road
3.0 °C. Forest and water 0 °C.

## References

- InVEST User Guide, Urban Cooling Model:
  https://storage.googleapis.com/releases.naturalcapitalproject.org/invest-userguide/latest/en/urban_cooling_model.html
- Zawadzka et al. (2021): A spatially explicit approach to simulate urban heat
  mitigation with InVEST (v3.8.0). Geosci. Model Dev. 14, 3521–3537.
