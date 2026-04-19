# Parkinson's Disease Detection via Acoustic Biomarkers

An end-to-end, research-grade machine learning pipeline for diagnosing Parkinson's Disease (PD) using vocal and speech-based features. This repository is specifically designed to enforce **subject-level cross-validation** to prevent data leakage—a critical flaw in many medical machine learning studies.

## Key Features
* **Zero Data Leakage:** Implements `GroupKFold` cross-validation to ensure that acoustic recordings from the same underlying patient are never split across train and test sets.
* **Hyperparameter Optimization:** Utilizes Bayesian/GridSearch strategies rigorously finding mathematical optima within nested folds.
* **SMOTE Balancing:** Specifically protects algorithms from over-indexing on Parkinson's prevalence via Synthetic Minority Oversampling Technique strictly within the training loops.
* **Publication-Quality Pipeline:** Calculates metrics with mean and standard deviation matrices across 9 independent modeling paradigms (Deep Learning, SVM-RBF, Tree-based, ensembles). 
* **Explainable AI (XAI):** Unpacks model predictions computationally via SHAP (Shapley Additive exPlanations). Generates both **Global Feature BeeSwarms** and **Local Patient-Specific Waterfall** charts to isolate exactly which vocal biomarkers indicate PD at clinical levels.

## Upcoming Methodologies Supported
* **Deep Learning Audio Transformer Integration:** (Wav2Vec / Whisper compatibility)
* **Cross-Corpus Validation:** Generalization testing between the UCI Dataset and the Synapse `mPower` cohort.

## Repository Structure
```
data/
  ├── UCI Parkinson's/       # Baseline acoustic dataset (195 recordings, 32 subjects)
  └── mPower_audio/          # (Optional) Destination for synapseclient downloads
src/
  ├── data_processing.py            # Baseline cleaning and parsing logic
  ├── modeling.py                   # Initial modeling and baseline SHAP plots
  ├── research_modeling.py          # Academic rigorous modeling (Ensemble, metrics ± std)
  ├── audio_feature_extraction.py   # Librosa/OpenSMILE backend for raw .m4a/.wav processing
  └── download_mpower.py            # Synapse.org mPower Dataset API fetcher
results/
  ├── paper_tables/          # .csv outputs for LaTeX/Word insertion
  └── paper_figures/         # 300 DPI publication plots (ROC curves, SHAP Beeswarms)
```

## Setup & Installation

**1. Create a Virtual Environment and Install Dependencies:**
```bash
pip install pandas numpy scikit-learn xgboost lightgbm shap matplotlib seaborn librosa opensmile synapseclient imbalanced-learn
```

**2. Running the Research Pipeline:**
To reproduce the academic findings from the UCI Parkinson's dataset:
```bash
python src/research_modeling.py
```
This automatically produces the metrics and outputs the high-resolution figures to the `results/paper_figures` directory.

## Integrating mPower Data (Optional)
If scaling to the massive mPower dataset:
1. Register at [Synapse.org](https://www.synapse.org) and accept the mPower Data Use Conditions.
2. Insert your auth token into `src/download_mpower_audio_table.py` and run it.
3. Execute `python src/audio_feature_extraction.py` to convert audio formats into ML matrices.