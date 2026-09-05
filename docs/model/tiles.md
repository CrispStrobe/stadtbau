# Tile types and per-hectare parameters

Source of truth: `data/params/tiles.json` (every entry carries its own `source`).
This page explains the derivations and lists the primary references.

One tile is 1 ha (100 m × 100 m), the cell size of the Zensus 2022 grid.

## Biotope values (BKompV Anlage 2)

The Bundeskompensationsverordnung (BKompV, 2020) rates biotope types on a 0–24
scale (Anlage 2, column 3). The text is federal law and therefore public domain
(§ 5 UrhG). Codes used:

| Tile | BKompV code and type | Points | Game value / start |
|---|---|---|---|
| meadow | 34.08a.01 Intensiv genutztes frisches Dauergrünland → 34.07a.02 Artenreiche frische (Mäh-)Weide | 8 → 18 | 18, starts at 0.45 (≈ 8), reaches 18 after 120 months |
| cropland | 33.0x.03 Acker mit stark verarmter oder fehlender Segetalvegetation | 6 | 6 |
| forest | 43.07.05M Buchen(misch)wald frischer, basenreicher Standorte (mittlere Ausprägung) 16; 43.07.02M Eichen-Hainbuchenwald (mittlere Ausprägung) 20 | 16–20 | 18, starts at 0.4 (≈ 7, below 42.03.02 Vorwald = 13), reaches 18 after 240 months |
| water | 24.03b Sonstige natürliche mesotrophe Gewässer 19 | 19 | 16 for a constructed pond, starts at 0.5 |
| park | 51.06a.03 Intensiv gepflegte Parkanlage mit altem Baumbestand (51.06a.02.01 extensiv gepflegt = 16) | 13 | 13, starts at 0.5, reaches 13 after 240 months |
| housing_low | 53.01.03b Lockeres Einzelhausgebiet | 5 | 5 |
| housing_high | 53.01.16a.02 Sonstige Blockbebauung | 4 | 4 |
| commercial, industry | 53.01.14a Industrie- und Gewerbefläche inkl. typischen Freiräumen | 2 | 2 |
| road | 52.01.01a Versiegelter Verkehrs- und Betriebsweg | 0 | 0 |

Maturation: `value × (start + (1 − start) · min(1, age / recoveryMonths))`. The
BKompV distinguishes junge/mittlere/alte Ausprägung of woods; the recovery
times are estimates from compensation practice (BfN-Schriften 721) and should
be refined (open in T-103).

## Residents and jobs per hectare

- Living space per resident: 49.2 m² (Destatis, Fortschreibung des
  Wohngebäude- und Wohnungsbestands, Ende 2024).
- Floor-area ratios: BauNVO § 17 caps GFZ at 1.2 for WA/MI; detached-house
  areas are typically built at GFZ ≈ 0.4.
- housing_high: 1.2 × 10 000 m² × 0.8 (net of walls and stairs) = 9 600 m² ÷
  49.2 ≈ 195 residents per net hectare; ≈ 180 gross including local streets.
- housing_low: 0.4 × 10 000 × 0.8 = 3 200 m² ÷ 49.2 ≈ 65 net; × 0.7 gross ≈ 45.
- Jobs: commercial 100/ha and industry 45/ha follow BBSR Flächenkennwerte
  ranges (office/retail 80–150, manufacturing 30–60 employees per ha);
  ground-floor services in apartment blocks 15/ha. Initial estimates.

## Sealing, cooling parameters

Sealing follows Copernicus Imperviousness typical values per land use.
Shade, albedo and ETI are the InVEST Urban Cooling biophysical inputs
(canopy fraction, surface albedo, crop coefficient scaled 0–1); see
`heat.md`.

## Noise emission

See `noise.md`. Tile values are L_eq at the tile boundary (50 m from the
centre): road 60 dB(A) per 100 m segment at 10 000 vehicles/day, industry 65,
commercial 58, apartment blocks 50, detached housing 45. The TA Lärm daytime
limits (WA 55, MI 60, GE 65, GI 70 dB(A)) anchor the scale.

## Costs and maintenance

Build costs are development costs borne by the municipality in the game
(Erschließung, park construction, afforestation), in k€ per hectare. All are
initial estimates; sources to be added per task T-103.

## CO₂ per hectare

Forest −10 t/ha/a (Thünen, Bundeswaldinventur, growing stands), grassland
−1, cropland +1.5 (incl. N₂O), buildings by heating per resident (UBA), industry
+400 t/ha/a for 45 jobs. Traffic CO₂ is computed from car-km (0.15 kg/km, UBA
fleet average). Initial estimates.

## References

- BKompV Anlage 2: https://www.gesetze-im-internet.de/bkompv/anlage_2.html
- BfN-Schriften 721, Kartieranleitung für die Biotoptypen nach Anlage 2 BKompV
- Destatis, Wohnfläche je Einwohner: https://www.destatis.de/DE/Presse/Pressemitteilungen/2025/09/PD25_336_31231.html
- BauNVO § 17: https://www.gesetze-im-internet.de/baunvo/__17.html
- Copernicus Land Monitoring Service, Imperviousness
- InVEST User Guide, Urban Cooling Model
