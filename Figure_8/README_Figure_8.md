# Figure 8 data and analysis

`Figure_8.m` reads the field-level measurements from `Final Data_Cell Viability Assay.xlsx`, calculates one mean per independent experiment, and generates the Figure 8 panel and its supporting tables.

## Data handling

- The raw Excel workbook is not modified by the analysis.
- Each processed field is listed in `Figure_8_processed_fields.csv` with its source worksheet, source cell, source label, experiment number, and analysis group.
- The nine measurements in `Cell Viability Data!F13:F21` are assigned to the convective-cooling group because the adjacent source labels in `E13:E21` identify them as `Conv Rewarm`. This corrects their placement under the spray-control column in the flattened `Sheet1` worksheet without changing the measured values.
- `Figure_8_experiment_means.csv` reports the field count and mean for each independent experiment.

## Statistical analysis

Bars show the mean and standard deviation of independent-experiment means. Grey points show individual imaging fields for descriptive purposes. The statistical unit is the independent experiment: control, n = 4; spray control, n = 3; cryoaerosolization plus rewarming, n = 3; convective cooling plus rewarming, n = 3.

Three prespecified adjacent comparisons are evaluated using two-sided Welch t-tests. P values are adjusted together with the Holm method. The raw and adjusted values are reported in `Figure_8_statistics.csv`.

## Generated files

- `Figure_8.png` and `Figure_8.pdf`: figure exports
- `Figure_8_processed_fields.csv`: traceable field-level data used by the script
- `Figure_8_experiment_means.csv`: independent-experiment means
- `Figure_8_statistics.csv`: Welch-test results and Holm-adjusted p values
- `Figure_8_source_data.xlsx`: the four supporting tables in a single workbook
