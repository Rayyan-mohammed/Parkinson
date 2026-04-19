import os
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import shap

from sklearn.preprocessing import StandardScaler
from sklearn.model_selection import GroupKFold
from sklearn.metrics import accuracy_score, precision_score, recall_score, f1_score, roc_auc_score
from sklearn.ensemble import RandomForestClassifier
from sklearn.svm import SVC
from xgboost import XGBClassifier
from lightgbm import LGBMClassifier

import sys
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from data_processing import load_uci_parkinsons, clean_data

def evaluate_models_with_groupkfold(df, n_splits=5):
    """
    Evaluates multiple ML models using Subject-level GroupKFold to prevent data leakage.
    Standardization is performed correctly inside the CV loop.
    """
    print("\n" + "="*50)
    print(f"Starting Model Evaluation (GroupKFold = {n_splits})")
    print("="*50)

    # Separate Features, Target, and Groups (Subject ID)
    groups = df['Subject_ID'].values
    y = df['status'].values
    X = df.drop(columns=['Subject_ID', 'status'])
    feature_names = X.columns.tolist()
    X = X.values

    # Initialize Models
    models = {
        'Random Forest': RandomForestClassifier(random_state=42),
        'XGBoost': XGBClassifier(random_state=42, eval_metric='logloss'),
        'LightGBM': LGBMClassifier(random_state=42, verbose=-1),
        'SVM (RBF)': SVC(kernel='rbf', probability=True, random_state=42)
    }

    # Store results
    results = {name: {'acc': [], 'prec': [], 'rec': [], 'f1': [], 'auc': []} for name in models.keys()}

    gkf = GroupKFold(n_splits=n_splits)

    for fold, (train_idx, test_idx) in enumerate(gkf.split(X, y, groups=groups)):
        X_train, X_test = X[train_idx], X[test_idx]
        y_train, y_test = y[train_idx], y[test_idx]

        # Prevent Data Leakage: Standardize ONLY on training data, then transform test data
        scaler = StandardScaler()
        X_train_scaled = scaler.fit_transform(X_train)
        X_test_scaled = scaler.transform(X_test)

        # Train and Predict for each model
        for name, model in models.items():
            model.fit(X_train_scaled, y_train)
            
            y_pred = model.predict(X_test_scaled)
            y_proba = model.predict_proba(X_test_scaled)[:, 1] if hasattr(model, "predict_proba") else y_pred

            results[name]['acc'].append(accuracy_score(y_test, y_pred))
            results[name]['prec'].append(precision_score(y_test, y_pred, zero_division=0))
            results[name]['rec'].append(recall_score(y_test, y_pred, zero_division=0))
            results[name]['f1'].append(f1_score(y_test, y_pred, zero_division=0))
            try:
                results[name]['auc'].append(roc_auc_score(y_test, y_proba))
            except ValueError:
                results[name]['auc'].append(0.5) # ROC AUC fails if only one class in test fold

    # Aggregate Results
    summary_df = pd.DataFrame(index=models.keys(), columns=['Accuracy', 'Precision', 'Recall', 'F1-Score', 'ROC-AUC'])
    
    for name in models.keys():
        summary_df.loc[name] = [
            np.mean(results[name]['acc']),
            np.mean(results[name]['prec']),
            np.mean(results[name]['rec']),
            np.mean(results[name]['f1']),
            np.mean(results[name]['auc'])
        ]
        
    print("\nAverage Performance Metrics across Subject-Level Folds:")
    print(summary_df.round(4))
    
    return summary_df, X, y, feature_names

def generate_shap_explanations(df):
    """
    Fits an XGBoost model on the whole dataset (standard scaled) and generates 
    SHAP explainability plots to see which acoustic features drive the predictions.
    Saves plots to the 'results' folder.
    """
    print("\n" + "="*50)
    print("Generating SHAP Explainability Analytics...")
    print("="*50)
    
    # Ensure results directory exists
    os.makedirs('results', exist_ok=True)
    
    groups = df['Subject_ID'].values
    y = df['status'].values
    X_df = df.drop(columns=['Subject_ID', 'status'])
    feature_names = X_df.columns.tolist()
    
    # Scale dataset for SHAP
    scaler = StandardScaler()
    X_scaled = scaler.fit_transform(X_df)
    X_scaled_df = pd.DataFrame(X_scaled, columns=feature_names)
    
    # Train Global Model for Interpretation
    model = XGBClassifier(random_state=42, eval_metric='logloss')
    model.fit(X_scaled_df, y)
    
    # SHAP Explainer
    explainer = shap.TreeExplainer(model)
    shap_values = explainer.shap_values(X_scaled_df)
    
    # 1. SHAP Summary Plot (Global Importance & Direction of Impact)
    plt.figure()
    shap.summary_plot(shap_values, X_scaled_df, show=False)
    plt.title("SHAP Feature Importance (XGBoost) - Parkinson's Detection")
    plt.tight_layout()
    plot_path = os.path.join('results', 'shap_summary_plot.png')
    plt.savefig(plot_path, dpi=300, bbox_inches='tight')
    plt.close()
    
    # 2. SHAP Absolute Bar Plot (Global Importance Magnitude)
    plt.figure()
    shap.summary_plot(shap_values, X_scaled_df, plot_type="bar", show=False)
    plt.title("Mean Absolute SHAP Value (XGBoost)")
    plt.tight_layout()
    bar_path = os.path.join('results', 'shap_bar_plot.png')
    plt.savefig(bar_path, dpi=300, bbox_inches='tight')
    plt.close()
    
    print(f"✅ SHAP plots successfully saved to: \n  - {plot_path}\n  - {bar_path}")


if __name__ == "__main__":
    # Load and clean baseline UCI dataset
    uci_path = "data/UCI Parkinson's/parkinsons.data"
    
    # Re-using previous script's loading framework
    df = load_uci_parkinsons(uci_path)
    df = clean_data(df)
    
    # Task 1 & 2: Subject-Level GroupKFold Validation and Comparison of Models
    _ = evaluate_models_with_groupkfold(df, n_splits=5)
    
    # Task 3: Global Explainability using SHAP
    generate_shap_explanations(df)
