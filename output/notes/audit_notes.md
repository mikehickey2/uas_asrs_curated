# Audit Notes

Generated: 2025-12-27

## Dataset Overview

- 50 reports spanning 2024-11-01 to 2025-03-01
- 125 variables

## Usability Summary

### Well-populated domains (>=80% mean present)

- Time (2 vars, 96% mean)
- Assessments (2 vars, 100% mean)
- Other (1 vars, 100% mean)

### Moderately populated domains (50-79% mean present)

- Events (6 vars, 71.7% mean)

### Sparse domains (<50% mean present)

- Aircraft 2 (35 vars, 6.8% mean)
- Component (4 vars, 11.5% mean)
- Aircraft 1 (35 vars, 32% mean)
- Person (22 vars, 32.2% mean)
- Environment (6 vars, 36.7% mean)
- Report text (5 vars, 44.4% mean)
- Place (7 vars, 46.6% mean)

## Important Notes

- Denominators vary by field: some fields only apply to certain report
  types (e.g., UAS-specific fields only relevant when UAS is Aircraft 1
  or Aircraft 2)
- Empty strings and NA values both treated as missing
- Person and Report domains use numbered entity patterns (person1, person2,
  report1, report2)
