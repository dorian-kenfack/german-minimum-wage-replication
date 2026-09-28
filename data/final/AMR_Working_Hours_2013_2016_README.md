# Average Annual Hours Worked per Employed Person, AMR 2013–2016

## 1. Dataset Overview

`AMR_Working_Hours_2013_2016.csv` contains a balanced annual panel of 257 German labor-market regions (AMRs) for 2013–2016: 1,028 observations, constructed from 400 district-level regions per year.

The main outcome measures annual hours actually worked per employed person at the place of work. It covers employees, self-employed persons, and contributing family workers. It is not restricted to full-time workers or low-wage employment.

Each row represents one AMR and calendar year. The combination of `amr` and `year` uniquely identifies observations. The dataset provides annual, not quarterly, information.

## 2. Variables and Units

Variable names are retained in German to remain consistent with the analysis code.

| Variable | Definition | Unit / format |
|----|----|----|
| `amr` | Labor-market region identifier from the BBSR mapping | Numeric identifier |
| `amr_name` | Labor-market region name from the BBSR mapping | Text |
| `year` | Calendar year | 2013–2016 |
| `erwerbstaetige_tsd` | Annual average number of employed persons at the place of work | Thousands of persons; one decimal place |
| `arbeitsstunden_mio` | Total hours actually worked during the calendar year | Millions of hours; one decimal place |
| `stunden_je_erwerbstaetigen` | Average annual hours worked per employed person | Hours per person per year; six decimal places |
| `anzahl_kreisregionen` | Number of district-level regions assigned to the AMR | Count |

Employed persons are counted once even if they hold multiple jobs. Total hours worked include hours from secondary jobs but exclude paid hours not actually worked. Regional working hours are statistically estimated rather than fully observed directly at the district level.

## 3. Sources

- **Main source:** Arbeitskreis Erwerbstätigenrechnung der Länder, Reihe 2, Band 2, *Arbeitsvolumen in den kreisfreien Städten und Landkreisen der Bundesrepublik Deutschland*, Originärberechnung 2024. Calculation and territorial reference date: August 2025; published February 2026. Tables 1.1 and 1.2 in the embedded Excel attachment provide employed persons and hours worked, respectively. [Download source publication](https://www.statistikportal.de/sites/default/files/2026-02/ETR_R2B2_OB2024_BSAug2025_0.pdf).
- **Cross-check for employed persons:** Reihe 2, Band 1, Table 1, with the same calculation reference date of August 2025. [Download comparison publication](https://www.statistikportal.de/sites/default/files/2025-12/ETR_R2B1_OB2024_BSAug2025.pdf).
- **Regional mapping:** BBSR assignment of districts to 257 labor-market regions, 2017 version. [Download mapping](https://www.bbsr.bund.de/BBSR/DE/forschung/raumbeobachtung/Raumabgrenzungen/deutschland/regionen/arbeitsmarktregionen/arbeitsmarktregionen-2017.csv?__blob=publicationFile&v=2).

The source publications were downloaded and processed on September 21, 2026. The original PDFs were retained unchanged, and their embedded Excel attachments were extracted for processing. No missing values were imputed.

## 4. Data Construction

District-level hours worked and employed persons were summed within each AMR and year. Average annual hours worked per employed person were then calculated as:

``` text
Hours per employed person = (total hours in millions × 1,000)
                            / employed persons in thousands
```

This is a ratio of AMR-level totals, not an unweighted average of district-level ratios. The numerator is a calendar-year total; the denominator is the annual average number of employed persons.

District identifiers were matched to the BBSR 2017 mapping. Only district-level (NUTS-3) records were included; higher-level totals and subordinate entries were excluded to avoid double counting. The following cases received explicit treatment:

- **Eisenach / Wartburgkreis:** Eisenach (16056) is included in Wartburgkreis (16063) in the source statistics. Both belonged to AMR 247 in the 2017 mapping, so no split was required and Eisenach was not counted separately.
- **Göttingen / Osterode:** The merged district of Göttingen (03159) was assigned consistently to AMR 12 in all years. Source values were not artificially split into the former districts.
- **City-states:** Source identifiers `02` and `11` were normalized to `02000` and `11000` for matching.

The final CSV is supplied as the input for the working-hours analysis. This document describes its construction; an executable script rebuilding it from the source publications is not included in this repository.

## 5. Published precision

Calculations used the more precise values stored in the source spreadsheets. After aggregation to AMRs, employed persons and total hours worked were rounded to one decimal place in their respective units of thousands of persons and millions of hours.

The hours-per-person measure was calculated before this rounding and is stored to six decimal places. It therefore cannot be reproduced exactly by dividing the rounded totals in the published CSV. Use `stunden_je_erwerbstaetigen` for the analysis. Its six decimal places indicate storage precision, not equivalent measurement accuracy.

The source publication's precision guidance (page 4) was applied when preparing the CSV: more precise source values were used for internal calculations, while published absolute totals were limited to one decimal place in the specified units. The source spreadsheets containing the more precise values are not part of this repository.

## 6. Limitations

The source statistics use district boundaries as of August 2025, while the AMR assignment uses the BBSR 2017 mapping. Minor municipal transfers across district boundaries were not reconstructed at the municipality level. The dataset should therefore not be treated as a fully verified reconstruction of historical AMR boundaries.

Average annual hours worked can change because of shifts in employment composition, full-time and part-time shares, and the statistical estimation of regional working hours. Such changes do not necessarily reflect changes in the hours worked by the same individuals.

The outcome is intended for an exploratory regional analysis. It does not by itself establish individual reductions in working hours or a causal minimum-wage adjustment mechanism.

## 7. Usage in R

From the repository root:

``` r
hours_data <- read.csv(
  "data/final/AMR_Working_Hours_2013_2016.csv",
  fileEncoding = "UTF-8"
)
```

Use `amr` and `year` when merging with other annual panel data, rather than region names. For time-invariant AMR characteristics, use `amr` and ensure that the characteristics table contains only one row per AMR.

Do not create a quarterly panel by repeating annual observations. For reproducing the reported analysis, use the supplied hours-per-person variable rather than recalculating it from the rounded totals.

## 8. Source File Checksums

The following SHA-256 checksums identify the original downloaded PDFs used during preparation:

| Source publication | SHA-256 |
|----|----|
| Reihe 2, Band 2: `ETR_R2B2_OB2024_BSAug2025.pdf` | `dc8a89c03bd18488cef4b925e12f286cd2fbec279799117dd9bea4a0174b201f` |
| Reihe 2, Band 1: `ETR_R2B1_OB2024_BSAug2025.pdf` | `3251aa0c610b7eaa70ff990a402ab66fac321c769917f48d7ddbb070fa34b3ab` |

These are the filenames recorded during preparation. The Band 2 download URL above has the filename suffix `_0.pdf`.
