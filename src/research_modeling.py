import os
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import shap

from sklearn.preprocessing import StandardScaler
from sklearn.model_selection import GroupKFold
from sklearn.metrics import (accuracy_score, precision_score, recall_score, 
                             f1_score, roc_auc_score, roc_curve, auc, confusion_matrix)
from sklearn.ensemble import RandomForestClassifier, StackingClassifier, VotingClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.svm import SVC
from sklearn.neural_network import MLPClassifier
from sklearn.neighbors import KNeighborsClassifier
from xgboost import XGBClassifier
from lightgbm import LGBMClassifier

import sys
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from data_processing import load_uci_parkinsons, clean_data

# Set styling for publication-quality plots
plt.style.use('seaborn-v0_8-whitegrid')
sns.set_context("paper", font_scale=1.5)

def plot_mean_roc_curves(results_prob, y_true_all, models, title="Mean ROC Curves across Subject-Level Folds"):
    """Plots the aggregate ROC curves for all models for a research paper."""
    plt.figure(figsize=(10, 8))
    
    for name in models.keys():
        if name not in results_prob or len(results_prob[name]) == 0:
            continue
        
        y_prob = np.concatenate(results_prob[name])
        y_true = np.concatenate(y_true_all)
        
        fpr, tpr, _ = roc_curve(y_true, y_prob)
        roc_auc = auc(fpr, tpr)
        
        plt.plot(fpr, tpr, lw=2.5, alpha=0.8, label=f'{name} (AUC = {roc_auc:.3f})')
        
    plt.plot([0, 1], [0, 1], linestyle='--', lw=2, color='gray', label='Chance', alpha=0.8)
    plt.xlim([-0.05, 1.05])
    plt.ylim([-0.05, 1.05])
    plt.xlabel('False Positive Rate', fontweight='bold')
    plt.ylabel('True Positive Rate', fontweight='bold')
    plt.title(title, fontweight='bold')
    plt.legend(loc="lower right", frameon=True, fancybox=True, framealpha=0.9)
    plt.grid(True, linestyle='--', alpha=0.6)
    
    os.makedirs('results/paper_figures', exist_ok=True)
    plt.savefig('results/paper_figures/ROC_Curves Comparison.png', dpi=300, bbox_inches='tight')
    plt.close()

def evaluate_models_robust(df, n_splits=5):
    """
    Advanced GroupKFold evaluation including a Stacking Ensemble, 
    designed to produce research-paper quality metrics and visualizations.
    """
    print("\n" + "="*60)
    print(f"Executing Research Methodology (GroupKFold = {n_splits})")
    print("="*60)

    groups = df['Subject_ID'].values
    y = df['status'].values
    X_df = df.drop(columns=['Subject_ID', 'status'])
    X = X_df.values
    feature_names = X_df.columns.tolist()

    # Define Base Models
    base_models = [
        ('lr', LogisticRegression(random_state=42, max_iter=1000)),
        ('knn', KNeighborsClassifier(n_neighbors=5)),
        ('rf', RandomForestClassifier(n_estimators=200, max_depth=10, random_state=42)),
        ('xgb', XGBClassifier(n_estimators=200, learning_rate=0.05, random_state=42, eval_metric='logloss')),
        ('lgbm', LGBMClassifier(n_estimators=200, learning_rate=0.05, random_state=42, verbose=-1)),
        ('svm', SVC(kernel='rbf', probability=True, C=1.0, random_state=42)),
        ('mlp', MLPClassifier(hidden_layer_sizes=(100, 50), activation='relu', solver='adam', max_iter=1000, random_state=42))
    ]
    
    models = {
        'Logistic Regression (Baseline)': base_models[0][1],
        'KNN (Distance)': base_models[1][1],
        'Random Forest (Bagging)': base_models[2][1],
        'XGBoost (Boosting)': base_models[3][1],
        'LightGBM (Boosting)': base_models[4][1],
        'SVM-RBF (Kernel)': base_models[5][1],
        'Deep Neural Network (MLP)': base_models[6][1],
        # Meta-classifiers (Ensembles of different paradigms)
        'Voting Ensemble (Soft)': VotingClassifier(estimators=[('rf', base_models[2][1]), ('svm', base_models[5][1]), ('mlp', base_models[6][1])], voting='soft'),
        'Stacking Ensemble': StackingClassifier(estimators=[('rf', base_models[2][1]), ('xgb', base_models[3][1]), ('svm', base_models[5][1])], final_estimator=LogisticRegression(), cv=3)
    }

    # Store comprehensive results
    metrics = {name: {'acc': [], 'prec': [], 'rec': [], 'f1': [], 'auc': []} for name in models.keys()}
    predictions = {name: [] for name in models.keys()}
    probabilities = {name: [] for name in models.keys()}
    y_true_all = []

    gkf = GroupKFold(n_splits=n_splits)

    for fold, (train_idx, test_idx) in enumerate(gkf.split(X, y, groups=groups)):
        X_train, X_test = X[train_idx], X[test_idx]
        y_train, y_test = y[train_idx], y[test_idx]

        # Prevent Data Leakage: Standardize inside CV loop
        scaler = StandardScaler()
        X_train_scaled = scaler.fit_transform(X_train)
        X_test_scaled = scaler.transform(X_test)
        
        y_true_all.append(y_test)

        for name, model in models.items():
            model.fit(X_train_scaled, y_train)
            
            y_pred = model.predict(X_test_scaled)
            y_proba = model.predict_proba(X_test_scaled)[:, 1] if hasattr(model, "predict_proba") else y_pred

            metrics[name]['acc'].append(accuracy_score(y_test, y_pred))
            metrics[name]['prec'].append(precision_score(y_test, y_pred, zero_division=0))
            metrics[name]['rec'].append(recall_score(y_test, y_pred, zero_division=0))
            metrics[name]['f1'].append(f1_score(y_test, y_pred, zero_division=0))
            
            try:
                metrics[name]['auc'].append(roc_auc_score(y_test, y_proba))
            except ValueError:
                metrics[name]['auc'].append(0.5)
                
            predictions[name].extend(y_pred)
            probabilities[name].append(y_proba)

    # Format Results for Paper (Mean ± Std)
    summary_df = pd.DataFrame(index=models.keys(), columns=['Accuracy', 'Precision', 'Recall', 'F1-Score', 'ROC-AUC'])
    raw_summary_df = pd.DataFrame(index=models.keys(), columns=['Accuracy', 'Precision', 'Recall', 'F1-Score', 'ROC-AUC'])
    
    for name in models.keys():
        acc = np.mean(metrics[name]['acc'])
        acc_std = np.std(metrics[name]['acc'])
        prec = np.mean(metrics[name]['prec'])
        rec = np.mean(metrics[name]['rec'])
        f1 = np.mean(metrics[name]['f1'])
        f1_std = np.std(metrics[name]['f1'])
        auc_score = np.mean(metrics[name]['auc'])
        auc_std = np.std(metrics[name]['auc'])
        
        # Formatted for LaTeX/Markdown Tables
        summary_df.loc[name] = [
            f"{acc:.3f} ± {acc_std:.3f}",
            f"{prec:.3f}",
            f"{rec:.3f}",
            f"{f1:.3f} ± {f1_std:.3f}",
            f"{auc_score:.3f} ± {auc_std:.3f}"
        ]
        
        # Raw for numerical sorting
        raw_summary_df.loc[name] = [acc, prec, rec, f1, auc_score]

    print("\nPaper-Ready Metrics (Mean ± Std. Deviation):")
    print(summary_df.to_string())
    
    os.makedirs('results/paper_tables', exist_ok=True)
    summary_df.to_csv('results/paper_tables/Model_Performance_CV.csv')
    
    # Plotting ROC Curves
    plot_mean_roc_curves(probabilities, y_true_all, models)
    
    return raw_summary_df, X_df, y

def robust_shap_analysis(df):
    """
    Advanced SHAP analysis using the best performing baseline model (XGBoost).
    """
    print("\n" + "="*60)
    print("Executing Feature Importance Analysis (SHAP)")
    print("="*60)
    
    y = df['status'].values
    X_df = df.drop(columns=['Subject_ID', 'status'])
    feature_names = X_df.columns.tolist()
    
    # Scale dataset fully for global interpretation
    scaler = StandardScaler()
    X_scaled = pd.DataFrame(scaler.fit_transform(X_df), columns=feature_names)
    
    model = XGBClassifier(n_estimators=200, learning_rate=0.05, random_state=42, eval_metric='logloss')
    model.fit(X_scaled, y)
    
    explainer = shap.TreeExplainer(model)
    shap_values = explainer.shap_values(X_scaled)
    
    os.makedirs('results/paper_figures', exist_ok=True)
    
    # 1. SHAP Summary Plot (Beeswarm)
    plt.figure(figsize=(10, 8))
    shap.summary_plot(shap_values, X_scaled, show=False, max_display=15)
    plt.title("Top 15 Biomarkers for Parkinson's Detection (SHAP)", fontweight='bold', fontsize=16)
    plt.tight_layout()
    plt.savefig('results/paper_figures/SHAP_Beeswarm.png', dpi=300, bbox_inches='tight')
    plt.close()
    
    # 2. SHAP Bar Plot (Absolute magnitude)
    plt.figure(figsize=(10, 6))
    shap.summary_plot(shap_values, X_scaled, plot_type="bar", show=False, max_display=15, color='#1f77b4')
    plt.title("Mean Absolute Biomarker Importance", fontweight='bold', fontsize=16)
    plt.tight_layout()
    plt.savefig('results/paper_figures/SHAP_Barplot.png', dpi=300, bbox_inches='tight')
    plt.close()
    
    print("✅ High-resolution SHAP figures saved in 'results/paper_figures/'.")

if __name__ == "__main__":
    uci_path = "data/UCI Parkinson's/parkinsons.data"
    
    df = load_uci_parkinsons(uci_path)
    df = clean_data(df)
    
    evaluate_models_robust(df, n_splits=5)
    robust_shap_analysis(df)
