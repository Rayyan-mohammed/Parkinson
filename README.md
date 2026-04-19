# Parkinson's Disease Detection via Acoustic Biomarkers

An end-to-end, research-grade machine learning pipeline for diagnosing Parkinson's Disease (PD) using vocal and speech-based features. This repository is specifically designed to enforce **subject-level cross-validation** to prevent data leakage—a critical flaw in many medical machine learning studies.

## Key Features & Methodologies Developed
* **Zero Data Leakage (GroupKFold):** Implements explicit subject-level cross-validation to ensure that acoustic recordings from the same underlying patient are never split across train and test sets, avoiding algorithmic memorization.
* **Hyperparameter Optimization (HPO):** Rigorously bounds hyperparameter grids strictly within inner folds (e.g., GridSearching XGBoost to optimal learning_rate=0.01, max_depth=5, 
_estimators=100) preventing artificial gradient inflation.
* **SMOTE Class Balancing:** Protects models from over-indexing on Parkinson's prevalence (75% of dataset) by injecting Synthetic Minority Oversampling Technique *exclusively* inside the training loops to preserve strict isolation mathematically.
* **Deep Explainable AI (Local & Global SHAP):** Unpacks model predictions computationally. Generates both **Global Feature BeeSwarms** (revealing Pitch Period Entropy as a primary biomarker) and **Local Patient-Specific Waterfall** charts to isolate personalized diagnosis thresholds.
* **Deep Learning Audio Transformer Extraction:** Implements an automated pipeline using HuggingFace acebook/wav2vec2-base over raw unseen audio waveforms to synthesize 768-dimensional semantic embeddings representing micro-acoustic phonations explicitly replacing traditional hand-crafted parameters.
* **Cross-Corpus Independence framework:** Designed explicitly to train on Dataset A (e.g., UCI subset) and structurally deploy evaluations on generalized Dataset B (e.g., mPower) proving microphone-agnostic integrity for major clinical relevance.

## Empirical Metrics (Subject-Isolated CV)
| Architecture | Accuracy | Precision | Recall | F1-Score | ROC-AUC |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Deep Neural Net (MLP)** | **0.756 ± 0.057** | **0.840** | 0.855 | **0.837 ± 0.048** | **0.851 ± 0.116** |
| **XGBoost (Boosting)** | **0.760 ± 0.114** | 0.825 | 0.875 | **0.837 ± 0.097** | 0.793 ± 0.204 |
| **Stacking Ensemble** | 0.748 ± 0.079 | 0.812 | **0.880** | 0.836 ± 0.066 | 0.783 ± 0.178 |
| **Random Forest** | 0.743 ± 0.076 | 0.814 | 0.867 | 0.830 ± 0.067 | 0.808 ± 0.171 |

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