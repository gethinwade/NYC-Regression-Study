
## Overview
This project applies multiple linear regression techniques to analyze NYC rat inspection data, exploring relationships between rat activity and various neighborhood characteristics. The analysis demonstrates comprehensive statistical modeling, from exploratory data analysis through advanced model refinement and validation.


## Project Structure
- `data_pull.py` - Python script for pulling data from NYC Open Data portal and the Census Bureau
- `project_data.csv` - Comprehensive dataset used for analysis
- `regression_analysis.R` - R code implementing the full regression workflow
- `regression_analysis.pdf` - Complete regression analysis with code and outputs


## Methodology

The analysis progresses through several key stages:

- **Exploratory Data Analysis**: Initial examination of variables and relationships
- **Model Building**: Multiple linear regression with various neighborhood predictors
- **Diagnostic Testing**: Residual analysis and Cook's Distance to identify influential points
- **Transformation**: Box-Cox transformation to address model assumptions
- **Advanced Techniques**: Interaction effects and k-fold cross-validation for model validation
- **Model Refinement**: Iterative improvement based on diagnostic results


## Key Features

- Emphasis on statistical assumptions and proper model diagnostics
- Implementation of robust regression methods
- Rigorous validation through cross-validation techniques
- Clear interpretation of regression coefficients and their practical significance
- Dual implementation in R and Python demonstrating versatility in statistical computing


## Technologies

- **Python**: Data acquisition and preprocessing
- **R**: Primary statistical analysis and modeling
- **NYC Open Data API**: Primary data source

## Results

The analysis identifies significant predictors of rat activity across NYC zip codes and validates model performance through comprehensive diagnostic testing and cross-validation, ensuring statistical validity.

