// SPDX-License-Identifier: AGPL-3.0-or-later
// GENERATED FILE - do not edit. Source: data/params/tiles.json
// Regenerate with: dart run tools/gen_params.dart

/// Default simulation parameters as JSON (mirror of data/params/tiles.json).
const String defaultParamsJson = r'''
{
  "schemaVersion": 1,
  "notes": "Source of truth for all simulation parameters. Regenerate the Dart mirror with `dart run tools/gen_params.dart`. Every numeric entry is {value, source, note?}. Values marked 'initial estimate' must be verified in task T-103.",
  "grid": {
    "cellSizeM": {
      "value": 100,
      "source": "Zensus 2022 100 m grid (Destatis, dl-de/by-2.0); 1 tile = 1 ha"
    },
    "tickMonths": {
      "value": 1,
      "source": "design: one tick = one month"
    }
  },
  "tiles": {
    "meadow": {
      "category": "nature",
      "residentsPerHa": {
        "value": 0,
        "source": "n/a"
      },
      "jobsPerHa": {
        "value": 0,
        "source": "n/a"
      },
      "sealing": {
        "value": 0.0,
        "source": "Copernicus Imperviousness: grassland ~0 %"
      },
      "biotopeValue": {
        "value": 13,
        "source": "BKompV Anlage 2, mesophiles Grünland (verify code, T-103)",
        "note": "initial estimate"
      },
      "biotopeStart": {
        "value": 0.6,
        "source": "design: sown meadow reaches full value after recoveryMonths"
      },
      "recoveryMonths": {
        "value": 60,
        "source": "BfN: Extensivgrünland Entwicklungszeit 5–10 Jahre (initial estimate)"
      },
      "noiseEmissionDb": {
        "value": 0,
        "source": "no source"
      },
      "airEmission": {
        "value": 0.0,
        "source": "no source"
      },
      "airSink": {
        "value": 0.05,
        "source": "Nowak et al. 2006 deposition magnitudes; grass minor (initial estimate)"
      },
      "shade": {
        "value": 0.05,
        "source": "InVEST Urban Cooling: shade = canopy fraction"
      },
      "albedo": {
        "value": 0.2,
        "source": "InVEST Urban Cooling biophysical table example values"
      },
      "eti": {
        "value": 0.8,
        "source": "InVEST Urban Cooling crop coefficient Kc scaled 0–1"
      },
      "greenWeight": {
        "value": 0.6,
        "source": "design: recreational usability of open meadow"
      },
      "co2PerHaYear": {
        "value": -1.0,
        "source": "UBA / Thünen: grassland soil carbon sink ~1 t CO2/ha/a (initial estimate)"
      },
      "buildCostKEur": {
        "value": 5,
        "source": "Ansaat Extensivwiese ~0.5 €/m² (initial estimate)"
      },
      "maintenanceKEurYear": {
        "value": 1,
        "source": "1–2 Mahden/Jahr (initial estimate)"
      }
    },
    "cropland": {
      "category": "nature",
      "residentsPerHa": {
        "value": 0,
        "source": "n/a"
      },
      "jobsPerHa": {
        "value": 1,
        "source": "Destatis Landwirtschaftszählung: ~1 AK je 50 ha; rounded up for game"
      },
      "sealing": {
        "value": 0.0,
        "source": "Copernicus Imperviousness"
      },
      "biotopeValue": {
        "value": 6,
        "source": "BKompV Anlage 2, intensiv genutzter Acker (verify code, T-103)",
        "note": "initial estimate"
      },
      "biotopeStart": {
        "value": 1.0,
        "source": "design"
      },
      "recoveryMonths": {
        "value": 1,
        "source": "design"
      },
      "noiseEmissionDb": {
        "value": 0,
        "source": "no source"
      },
      "airEmission": {
        "value": 0.05,
        "source": "EMEP/EEA Guidebook: agriculture NH3/PM minor at this scale (initial estimate)"
      },
      "airSink": {
        "value": 0.02,
        "source": "initial estimate"
      },
      "shade": {
        "value": 0.02,
        "source": "InVEST Urban Cooling"
      },
      "albedo": {
        "value": 0.2,
        "source": "InVEST Urban Cooling"
      },
      "eti": {
        "value": 0.6,
        "source": "InVEST Urban Cooling"
      },
      "greenWeight": {
        "value": 0.3,
        "source": "design: fields are walkable at the edge only"
      },
      "co2PerHaYear": {
        "value": 1.5,
        "source": "UBA: cropland net source incl. fertiliser N2O (initial estimate)"
      },
      "buildCostKEur": {
        "value": 2,
        "source": "initial estimate"
      },
      "maintenanceKEurYear": {
        "value": 0,
        "source": "privately farmed"
      }
    },
    "forest": {
      "category": "nature",
      "residentsPerHa": {
        "value": 0,
        "source": "n/a"
      },
      "jobsPerHa": {
        "value": 0,
        "source": "n/a"
      },
      "sealing": {
        "value": 0.0,
        "source": "Copernicus Imperviousness"
      },
      "biotopeValue": {
        "value": 17,
        "source": "BKompV Anlage 2, Laubwald mittleren Alters (verify code, T-103)",
        "note": "initial estimate"
      },
      "biotopeStart": {
        "value": 0.3,
        "source": "design: young plantation ~ Vorwald value"
      },
      "recoveryMonths": {
        "value": 240,
        "source": "BKompV/BfN: Waldentwicklung 20+ Jahre bis mittleres Alter (initial estimate)"
      },
      "noiseEmissionDb": {
        "value": 0,
        "source": "no source"
      },
      "airEmission": {
        "value": 0.0,
        "source": "no source"
      },
      "airSink": {
        "value": 0.2,
        "source": "Nowak et al. 2006 (i-Tree): urban trees remove up to few % of PM/NO2 locally; scaled to 20 % of local index (initial estimate)"
      },
      "shade": {
        "value": 0.9,
        "source": "InVEST Urban Cooling: closed canopy"
      },
      "albedo": {
        "value": 0.15,
        "source": "InVEST Urban Cooling"
      },
      "eti": {
        "value": 1.0,
        "source": "InVEST Urban Cooling"
      },
      "greenWeight": {
        "value": 0.9,
        "source": "design: forest walks highly valued (WHO urban green space review)"
      },
      "co2PerHaYear": {
        "value": -10.0,
        "source": "Thünen Bundeswaldinventur: ~10 t CO2/ha/a net sink in growing forest (initial estimate)"
      },
      "buildCostKEur": {
        "value": 20,
        "source": "Aufforstung 1–2 €/m² (initial estimate)"
      },
      "maintenanceKEurYear": {
        "value": 1,
        "source": "initial estimate"
      }
    },
    "water": {
      "category": "nature",
      "residentsPerHa": {
        "value": 0,
        "source": "n/a"
      },
      "jobsPerHa": {
        "value": 0,
        "source": "n/a"
      },
      "sealing": {
        "value": 0.0,
        "source": "n/a"
      },
      "biotopeValue": {
        "value": 16,
        "source": "BKompV Anlage 2, naturnahes Stillgewässer (verify code, T-103)",
        "note": "initial estimate"
      },
      "biotopeStart": {
        "value": 0.5,
        "source": "design: new pond matures over years"
      },
      "recoveryMonths": {
        "value": 120,
        "source": "initial estimate"
      },
      "noiseEmissionDb": {
        "value": 0,
        "source": "no source"
      },
      "airEmission": {
        "value": 0.0,
        "source": "no source"
      },
      "airSink": {
        "value": 0.03,
        "source": "initial estimate"
      },
      "shade": {
        "value": 0.0,
        "source": "InVEST Urban Cooling"
      },
      "albedo": {
        "value": 0.08,
        "source": "InVEST Urban Cooling: water albedo"
      },
      "eti": {
        "value": 1.0,
        "source": "InVEST Urban Cooling: open water evaporation"
      },
      "greenWeight": {
        "value": 0.7,
        "source": "design: blue space recreation (WHO)"
      },
      "co2PerHaYear": {
        "value": 0.0,
        "source": "neutral in v1"
      },
      "buildCostKEur": {
        "value": 200,
        "source": "Teichbau/Renaturierung ~20 €/m² (initial estimate)"
      },
      "maintenanceKEurYear": {
        "value": 2,
        "source": "initial estimate"
      }
    },
    "park": {
      "category": "green_urban",
      "residentsPerHa": {
        "value": 0,
        "source": "n/a"
      },
      "jobsPerHa": {
        "value": 2,
        "source": "Grünflächenamt/Gastronomie (initial estimate)"
      },
      "sealing": {
        "value": 0.15,
        "source": "paths and playgrounds (initial estimate)"
      },
      "biotopeValue": {
        "value": 9,
        "source": "BKompV Anlage 2, Parkanlage mit Baumbestand (verify code, T-103)",
        "note": "initial estimate"
      },
      "biotopeStart": {
        "value": 0.5,
        "source": "design"
      },
      "recoveryMonths": {
        "value": 120,
        "source": "initial estimate"
      },
      "noiseEmissionDb": {
        "value": 0,
        "source": "no source"
      },
      "airEmission": {
        "value": 0.0,
        "source": "no source"
      },
      "airSink": {
        "value": 0.1,
        "source": "Nowak et al. 2006 scaled (initial estimate)"
      },
      "shade": {
        "value": 0.5,
        "source": "InVEST Urban Cooling"
      },
      "albedo": {
        "value": 0.18,
        "source": "InVEST Urban Cooling"
      },
      "eti": {
        "value": 0.7,
        "source": "InVEST Urban Cooling"
      },
      "greenWeight": {
        "value": 1.0,
        "source": "design: park is the reference recreation space (WHO 300 m rule)"
      },
      "co2PerHaYear": {
        "value": -3.0,
        "source": "initial estimate"
      },
      "buildCostKEur": {
        "value": 400,
        "source": "Parkneubau 30–50 €/m² (initial estimate)"
      },
      "maintenanceKEurYear": {
        "value": 20,
        "source": "Grünflächenpflege 1–3 €/m²/a (initial estimate)"
      }
    },
    "housing_low": {
      "category": "residential",
      "residentsPerHa": {
        "value": 45,
        "source": "BBSR städtebauliche Dichte: Einfamilienhausgebiet 30–60 EW/ha; Destatis 47.4 m² Wohnfläche/EW"
      },
      "jobsPerHa": {
        "value": 3,
        "source": "home offices, local trades (initial estimate)"
      },
      "sealing": {
        "value": 0.45,
        "source": "BauNVO WR/WA GRZ 0.4 plus roads (initial estimate)"
      },
      "biotopeValue": {
        "value": 5,
        "source": "BKompV Anlage 2, locker bebaute Siedlung mit Gärten (verify code, T-103)",
        "note": "initial estimate"
      },
      "biotopeStart": {
        "value": 1.0,
        "source": "design"
      },
      "recoveryMonths": {
        "value": 1,
        "source": "design"
      },
      "noiseEmissionDb": {
        "value": 45,
        "source": "TA Lärm: residential background; own traffic (initial estimate)"
      },
      "airEmission": {
        "value": 0.15,
        "source": "EMEP/EEA: residential heating share (initial estimate)"
      },
      "airSink": {
        "value": 0.03,
        "source": "gardens (initial estimate)"
      },
      "shade": {
        "value": 0.25,
        "source": "InVEST Urban Cooling: garden trees"
      },
      "albedo": {
        "value": 0.2,
        "source": "InVEST Urban Cooling"
      },
      "eti": {
        "value": 0.4,
        "source": "InVEST Urban Cooling"
      },
      "greenWeight": {
        "value": 0.0,
        "source": "n/a"
      },
      "co2PerHaYear": {
        "value": 25,
        "source": "UBA: ~2 t CO2/EW/a Wohnen bei 45 EW/ha, minus gardens (initial estimate)"
      },
      "buildCostKEur": {
        "value": 200,
        "source": "Erschließungskosten ~20 €/m² Bruttobauland (initial estimate)"
      },
      "maintenanceKEurYear": {
        "value": 2,
        "source": "initial estimate"
      }
    },
    "housing_high": {
      "category": "residential",
      "residentsPerHa": {
        "value": 180,
        "source": "BBSR: Geschosswohnungsbau GFZ 1.2 → 150–250 EW/ha; Destatis 47.4 m² Wohnfläche/EW"
      },
      "jobsPerHa": {
        "value": 15,
        "source": "ground-floor services (initial estimate)"
      },
      "sealing": {
        "value": 0.75,
        "source": "BauNVO WA/MI GRZ 0.6 plus roads (initial estimate)"
      },
      "biotopeValue": {
        "value": 2,
        "source": "BKompV Anlage 2, dicht bebautes Siedlungsgebiet (verify code, T-103)",
        "note": "initial estimate"
      },
      "biotopeStart": {
        "value": 1.0,
        "source": "design"
      },
      "recoveryMonths": {
        "value": 1,
        "source": "design"
      },
      "noiseEmissionDb": {
        "value": 50,
        "source": "TA Lärm: urban residential background (initial estimate)"
      },
      "airEmission": {
        "value": 0.3,
        "source": "EMEP/EEA: heating + local traffic (initial estimate)"
      },
      "airSink": {
        "value": 0.01,
        "source": "initial estimate"
      },
      "shade": {
        "value": 0.1,
        "source": "InVEST Urban Cooling"
      },
      "albedo": {
        "value": 0.15,
        "source": "InVEST Urban Cooling"
      },
      "eti": {
        "value": 0.15,
        "source": "InVEST Urban Cooling"
      },
      "greenWeight": {
        "value": 0.0,
        "source": "n/a"
      },
      "co2PerHaYear": {
        "value": 50,
        "source": "UBA: heating per EW lower in multi-family, 180 EW/ha (initial estimate)"
      },
      "buildCostKEur": {
        "value": 400,
        "source": "Erschließung + Infrastrukturfolgekosten (initial estimate)"
      },
      "maintenanceKEurYear": {
        "value": 4,
        "source": "initial estimate"
      }
    },
    "commercial": {
      "category": "work",
      "residentsPerHa": {
        "value": 0,
        "source": "n/a"
      },
      "jobsPerHa": {
        "value": 100,
        "source": "BBSR Flächenkennwerte: Büro/Einzelhandel 80–150 Beschäftigte/ha (initial estimate)"
      },
      "retailFloorM2": {
        "value": 2000,
        "source": "design: 20 % of 1 ha plot as retail floor; HDE 1.4 m²/EW"
      },
      "sealing": {
        "value": 0.85,
        "source": "BauNVO GE GRZ 0.8 (initial estimate)"
      },
      "biotopeValue": {
        "value": 2,
        "source": "BKompV Anlage 2, Gewerbegebiet (verify code, T-103)",
        "note": "initial estimate"
      },
      "biotopeStart": {
        "value": 1.0,
        "source": "design"
      },
      "recoveryMonths": {
        "value": 1,
        "source": "design"
      },
      "noiseEmissionDb": {
        "value": 58,
        "source": "TA Lärm GE limit 65 day; delivery traffic typical 55–60 at boundary (initial estimate)"
      },
      "airEmission": {
        "value": 0.6,
        "source": "EMEP/EEA: delivery traffic, HVAC (initial estimate)"
      },
      "airSink": {
        "value": 0.0,
        "source": "n/a"
      },
      "shade": {
        "value": 0.05,
        "source": "InVEST Urban Cooling"
      },
      "albedo": {
        "value": 0.2,
        "source": "InVEST Urban Cooling"
      },
      "eti": {
        "value": 0.1,
        "source": "InVEST Urban Cooling"
      },
      "greenWeight": {
        "value": 0.0,
        "source": "n/a"
      },
      "co2PerHaYear": {
        "value": 60,
        "source": "initial estimate"
      },
      "buildCostKEur": {
        "value": 300,
        "source": "Erschließung Gewerbe (initial estimate)"
      },
      "maintenanceKEurYear": {
        "value": 3,
        "source": "initial estimate"
      }
    },
    "industry": {
      "category": "work",
      "residentsPerHa": {
        "value": 0,
        "source": "n/a"
      },
      "jobsPerHa": {
        "value": 45,
        "source": "BBSR Flächenkennwerte: produzierendes Gewerbe 30–60 Beschäftigte/ha (initial estimate)"
      },
      "sealing": {
        "value": 0.9,
        "source": "BauNVO GI GRZ 0.8 plus yards (initial estimate)"
      },
      "biotopeValue": {
        "value": 1,
        "source": "BKompV Anlage 2, Industriegebiet, weitgehend versiegelt (verify code, T-103)",
        "note": "initial estimate"
      },
      "biotopeStart": {
        "value": 1.0,
        "source": "design"
      },
      "recoveryMonths": {
        "value": 1,
        "source": "design"
      },
      "noiseEmissionDb": {
        "value": 65,
        "source": "TA Lärm GI limit 70 day; typical plant boundary 60–68 (initial estimate)"
      },
      "airEmission": {
        "value": 3.0,
        "source": "EMEP/EEA: industrial combustion and processes dominate local PM/NOx (initial estimate, relative units)"
      },
      "airSink": {
        "value": 0.0,
        "source": "n/a"
      },
      "shade": {
        "value": 0.02,
        "source": "InVEST Urban Cooling"
      },
      "albedo": {
        "value": 0.25,
        "source": "InVEST Urban Cooling: light roofs"
      },
      "eti": {
        "value": 0.05,
        "source": "InVEST Urban Cooling"
      },
      "greenWeight": {
        "value": 0.0,
        "source": "n/a"
      },
      "co2PerHaYear": {
        "value": 400,
        "source": "UBA Emissionsdaten Industrie je Beschäftigten, scaled to 45 Besch./ha (initial estimate)"
      },
      "buildCostKEur": {
        "value": 300,
        "source": "initial estimate"
      },
      "maintenanceKEurYear": {
        "value": 3,
        "source": "initial estimate"
      }
    },
    "road": {
      "category": "infrastructure",
      "residentsPerHa": {
        "value": 0,
        "source": "n/a"
      },
      "jobsPerHa": {
        "value": 0,
        "source": "n/a"
      },
      "sealing": {
        "value": 0.95,
        "source": "n/a"
      },
      "biotopeValue": {
        "value": 0,
        "source": "BKompV Anlage 2, versiegelte Verkehrsfläche = 0"
      },
      "biotopeStart": {
        "value": 1.0,
        "source": "design"
      },
      "recoveryMonths": {
        "value": 1,
        "source": "design"
      },
      "noiseEmissionDb": {
        "value": 60,
        "source": "Sound power of one 100 m segment at the 50 m reference, calibrated so that the energetic sum of segments gives L_den ≈ 58 dB(A) at 100 m and ≈ 65 dB(A) at 25 m from a straight road with 10 000 Kfz/24h at 50 km/h (RLS-19 / CNOSSOS-EU orders of magnitude)",
        "note": "initial estimate"
      },
      "airEmission": {
        "value": 1.0,
        "source": "EMEP/EEA road transport NOx/PM at 10 000 Kfz/24h (relative unit 1.0)"
      },
      "airSink": {
        "value": 0.0,
        "source": "n/a"
      },
      "shade": {
        "value": 0.05,
        "source": "InVEST Urban Cooling"
      },
      "albedo": {
        "value": 0.1,
        "source": "InVEST Urban Cooling: asphalt"
      },
      "eti": {
        "value": 0.02,
        "source": "InVEST Urban Cooling"
      },
      "greenWeight": {
        "value": 0.0,
        "source": "n/a"
      },
      "co2PerHaYear": {
        "value": 0,
        "source": "traffic CO2 is computed from commute km, not per tile"
      },
      "buildCostKEur": {
        "value": 300,
        "source": "Hauptstraße ~2–4 M€/km inkl. Knoten → 100 m Abschnitt (initial estimate)"
      },
      "maintenanceKEurYear": {
        "value": 25,
        "source": "Straßenunterhalt ~2 €/m² Fahrbahn/a (initial estimate)"
      }
    }
  },
  "noise": {
    "areaReferenceDistanceM": {
      "value": 50,
      "source": "half tile: boundary of a 1 ha area source; roads are split into 100 m segments (CNOSSOS-EU point-source segmentation)"
    },
    "areaDecayDbPerDecade": {
      "value": 20,
      "source": "ISO 9613-2 / CNOSSOS-EU: geometric divergence of a point source, 6 dB per doubling; summing segments reproduces the 3 dB/doubling of a line"
    },
    "foliageAttenuationDbPerTile": {
      "value": 2,
      "source": "ISO 9613-2 Table A.2 foliage attenuation up to ~10 dB over 200 m; simplified per 100 m tile"
    },
    "buildingScreeningDbPerTile": {
      "value": 5,
      "source": "CNOSSOS-EU diffraction; dense building row typical 5–10 dB (initial estimate)"
    },
    "maxPathAttenuationDb": {
      "value": 20,
      "source": "ISO 9613-2 practical cap"
    },
    "backgroundDb": {
      "value": 35,
      "source": "TA Lärm: rural night background (initial estimate)"
    },
    "radiusTiles": {
      "value": 8,
      "source": "design: beyond 800 m contributions < 45 dB"
    },
    "trafficReferenceVehiclesPerDay": {
      "value": 10000,
      "source": "RLS-19: emission scales with 10·log10(Q)"
    },
    "baselineThroughTraffic": {
      "value": 2000,
      "source": "design: any main road carries some through traffic"
    },
    "limitDayDb": {
      "value": 55,
      "source": "TA Lärm: allgemeines Wohngebiet (WA) Tag 55 dB(A)"
    },
    "limitBadDb": {
      "value": 65,
      "source": "TA Lärm: Gewerbegebiet 65; used as 0-score for residents"
    }
  },
  "air": {
    "decayLengthM": {
      "value": 300,
      "source": "simplified Gaussian-plume near-field; EMEP/EEA guidance for street-scale gradients (initial estimate)"
    },
    "radiusTiles": {
      "value": 6,
      "source": "design: exp(-600/300) ≈ 0.14"
    },
    "sinkRadiusTiles": {
      "value": 3,
      "source": "Nowak et al.: local deposition effect within ~300 m (initial estimate)"
    },
    "indexScale": {
      "value": 2.5,
      "source": "calibration: index = 100·exp(−C/scale), T-114"
    },
    "trafficReferenceVehiclesPerDay": {
      "value": 10000,
      "source": "EMEP/EEA road transport emission ∝ vehicle-km"
    }
  },
  "heat": {
    "shadeWeight": {
      "value": 0.6,
      "source": "InVEST Urban Cooling: CC = 0.6·shade + 0.2·albedo + 0.2·ETI"
    },
    "albedoWeight": {
      "value": 0.2,
      "source": "InVEST Urban Cooling"
    },
    "etiWeight": {
      "value": 0.2,
      "source": "InVEST Urban Cooling"
    },
    "uhiMaxC": {
      "value": 3.0,
      "source": "InVEST Urban Cooling: UHI magnitude user input; German mid-size cities 2–4 K (DWD) (initial estimate)"
    },
    "greenPatchMinHa": {
      "value": 2,
      "source": "InVEST Urban Cooling: green area ≥ 2 ha cools surroundings"
    },
    "coolingDistanceTiles": {
      "value": 2,
      "source": "InVEST Urban Cooling default d_cool 100 m; game uses 2 tiles for visibility (initial estimate)"
    }
  },
  "access": {
    "greenRadiusTiles": {
      "value": 3,
      "source": "WHO Urban green spaces 2016: ≥0.5 ha within 300 m; 3-30-300 rule (Konijnendijk 2021)"
    },
    "greenVarietyBonus": {
      "value": 0.2,
      "source": "design"
    },
    "greenVarietyMinTiles": {
      "value": 3,
      "source": "design"
    },
    "retailRadiusTiles": {
      "value": 7,
      "source": "BBSR Nahversorgung: fußläufig 500–700 m"
    },
    "huffLambda": {
      "value": 2.0,
      "source": "Huff 1963; walking distance exponent ~2"
    },
    "retailM2PerResident": {
      "value": 1.4,
      "source": "HDE Zahlenspiegel: ~1.4 m² Verkaufsfläche je Einwohner"
    },
    "retailReferenceSupply": {
      "value": 222,
      "source": "calibration: one commercial tile at 300 m = full score (2000/3²)"
    },
    "jobDecayM": {
      "value": 2000,
      "source": "MiD 2017: median commute ~ 10 km, but local job access decays within few km (initial estimate)"
    },
    "jobReferenceJobs": {
      "value": 400,
      "source": "calibration: ~one commercial + one industry tile within 500 m = full score, T-114"
    }
  },
  "habitat": {
    "halfSaturation": {
      "value": 0.5,
      "source": "InVEST Habitat Quality: k = 0.5"
    },
    "scalingZ": {
      "value": 2.5,
      "source": "InVEST Habitat Quality: z = 2.5"
    },
    "speciesAreaZ": {
      "value": 0.3,
      "source": "Arrhenius / MacArthur–Wilson: z ≈ 0.25–0.35 for habitat islands"
    },
    "threats": {
      "road": {
        "weight": {
          "value": 1.0,
          "source": "InVEST HQ sample threat table: roads"
        },
        "maxDistanceM": {
          "value": 300,
          "source": "InVEST HQ sample (initial estimate)"
        }
      },
      "industry": {
        "weight": {
          "value": 0.8,
          "source": "InVEST HQ sample (initial estimate)"
        },
        "maxDistanceM": {
          "value": 500,
          "source": "initial estimate"
        }
      },
      "commercial": {
        "weight": {
          "value": 0.6,
          "source": "initial estimate"
        },
        "maxDistanceM": {
          "value": 300,
          "source": "initial estimate"
        }
      },
      "housing_high": {
        "weight": {
          "value": 0.5,
          "source": "InVEST HQ sample: urban"
        },
        "maxDistanceM": {
          "value": 200,
          "source": "initial estimate"
        }
      },
      "housing_low": {
        "weight": {
          "value": 0.3,
          "source": "initial estimate"
        },
        "maxDistanceM": {
          "value": 200,
          "source": "initial estimate"
        }
      }
    }
  },
  "commute": {
    "labourParticipation": {
      "value": 0.52,
      "source": "Destatis: Erwerbstätige / Bevölkerung ≈ 0.52 (2023)"
    },
    "modeShareByDistance": {
      "source": "MiD 2017 (BMVI), Wegelängenklassen; rounded",
      "bins": [
        {
          "maxKm": 1,
          "walk": 0.6,
          "bike": 0.2,
          "car": 0.2
        },
        {
          "maxKm": 3,
          "walk": 0.2,
          "bike": 0.35,
          "car": 0.45
        },
        {
          "maxKm": 1000,
          "walk": 0.02,
          "bike": 0.13,
          "car": 0.85
        }
      ]
    },
    "roadSearchRadiusTiles": {
      "value": 3,
      "source": "design: 300 m to a main road counts as connected"
    },
    "externalCommuteKm": {
      "value": 15,
      "source": "MiD 2017: mean commute ~ 16 km for out-commuters (initial estimate)"
    },
    "externalCarShare": {
      "value": 0.8,
      "source": "MiD 2017: long trips car dominant"
    },
    "carKgCo2PerKm": {
      "value": 0.15,
      "source": "UBA: Pkw ~150 g CO2/km (2023 fleet)"
    },
    "workingDaysPerMonth": {
      "value": 20,
      "source": "convention"
    }
  },
  "economy": {
    "incomeTaxPerResidentYear": {
      "value": 600,
      "source": "Destatis kommunale Finanzen: Gemeindeanteil Einkommensteuer ≈ 50 Mrd € / 84 Mio EW (2023)"
    },
    "propertyTaxPerResidentYear": {
      "value": 180,
      "source": "Destatis: Grundsteuer ≈ 15 Mrd € / 84 Mio EW (2023)"
    },
    "businessTaxPerJobYear": {
      "value": 2100,
      "source": "Destatis: Gewerbesteuer netto ≈ 75 Mrd € / 35 Mio SV-Beschäftigte (2023)"
    },
    "startBudgetKEur": {
      "value": 25000,
      "source": "design: enough for a 12-tile main road plus a mixed quarter of ~25 tiles"
    },
    "demolitionCostKEur": {
      "value": 50,
      "source": "initial estimate"
    },
    "immigrationRate": {
      "value": 0.08,
      "source": "design: new housing fills within ~2 years at high attractiveness"
    },
    "emigrationRate": {
      "value": 0.03,
      "source": "design"
    },
    "unconnectedAttractivenessFactor": {
      "value": 0.7,
      "source": "design: no main road within 300 m"
    },
    "attractivenessWeights": {
      "source": "design; relative importance from Wohnzufriedenheit surveys (BBSR) (initial estimate)",
      "noise": 0.25,
      "air": 0.2,
      "green": 0.15,
      "retail": 0.15,
      "jobs": 0.15,
      "heat": 0.1
    }
  }
}''';
