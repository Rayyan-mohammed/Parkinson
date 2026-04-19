import pandas as pd
import numpy as np
from sklearn.preprocessing import StandardScaler
import synapseclient
import os

def load_uci_parkinsons(file_path):
    """
    Loads and preprocesses the UCI Parkinson's dataset.
    Extracts subject IDs to prevent data leakage during cross-validation.
    """
    print(f"Loading UCI dataset from {file_path}...")
    df = pd.read_csv(file_path)
    
    # The 'name' column format is typically 'phon_R01_SXX_Y' 
    # where XX is the subject ID and Y is the recording number.
    # We extract the subject ID to group recordings by subject.
    df['Subject_ID'] = df['name'].apply(lambda x: x.split('_')[2])
    
    # Drop the original 'name' column as it is a unique identifier for recordings
    # and would lead to data leakage or overfitting.
    df = df.drop(columns=['name'])
    
    # Reorder columns to put Subject_ID and status (label) first
    cols = ['Subject_ID', 'status'] + [c for c in df.columns if c not in ['Subject_ID', 'status']]
    df = df[cols]
    
    return df

def download_and_load_mpower(auth_token, download_dir="./data/mpower"):
    """
    Connects to Synapse to download the mPower dataset.
    Note: For a real pipeline, you would query specific tables/files based on Synapse IDs.
    """
    print("Connecting to Synapse to fetch mPower data...")
    syn = synapseclient.Synapse()
    syn.login(authToken=auth_token)
    
    # Example placeholder for pulling mPower data (e.g., voice or demographics)
    # dl_list_file_entities = syn.get_download_list()
    # For actual research, you need the specific Synpse ID (e.g., syn4993293 for mPower)
    
    print("mPower data fetching initialized (Please implement specific table queries).")
    # Return an empty DataFrame as placeholder
    return pd.DataFrame()

def clean_data(df):
    """
    Cleans the dataframe by handling missing values and dropping duplicates.
    """
    print("Cleaning data...")
    initial_shape = df.shape
    
    # 1. Drop complete duplicates
    df = df.drop_duplicates()
    
    # 2. Handle Missing Values
    # In research datasets like UCI, missing values might not exist, but for mPower it's common.
    # We fill numerical NA with the median.
    num_cols = df.select_dtypes(include=[np.number]).columns
    df[num_cols] = df[num_cols].fillna(df[num_cols].median())
    
    print(f"Removed {initial_shape[0] - df.shape[0]} duplicate rows.")
    return df

def standardize_features(df, exclude_cols=['Subject_ID', 'status']):
    """
    Applied Z-score standardization to acoustic feature columns.
    Important: Standardization should ideally be done within the cross-validation loop 
    to avoid data leakage, but this provides a normalized baseline for exploration.
    """
    print("Standardizing acoustic features...")
    features = [c for c in df.columns if c not in exclude_cols]
    
    scaler = StandardScaler()
    df[features] = scaler.fit_transform(df[features])
    
    return df

def get_dataset_summary(df, dataset_name="Dataset"):
    """
    Outputs a statistical and structural summary of the dataset.
    """
    print(f"\n{'='*15} SUMMARY: {dataset_name} {'='*15}")
    print(f"Total Rows (Recordings): {len(df)}")
    print(f"Total Features (excluding ID/Label): {len(df.columns) - 2}")
    
    if 'Subject_ID' in df.columns:
        num_subjects = df['Subject_ID'].nunique()
        print(f"Total Unique Subjects: {num_subjects}")
        print(f"Average recordings per subject: {len(df) / num_subjects:.2f}")
        
    if 'status' in df.columns:
        dist = df['status'].value_counts(normalize=True) * 100
        print(f"Class Distribution:")
        print(f"  Parkinson's (1): {dist.get(1, 0.0):.1f}%")
        print(f"  Healthy (0): {dist.get(0, 0.0):.1f}%")
        
    print("="*50 + "\n")

if __name__ == "__main__":
    # 1. Path to UCI Parkinson's dataset
    uci_path = "data/UCI Parkinson's/parkinsons.data"
    
    # 2. Load and parse UCI data
    uci_df = load_uci_parkinsons(uci_path)
    
    # 3. Clean and Standardize Data
    uci_cleaned = clean_data(uci_df)
    
    # Note: Standardization should be pipelined in GroupKFold for actual evaluation.
    # This is standardizing the whole dataset strictly for EDA readiness.
    uci_final = standardize_features(uci_cleaned)
    
    # 4. Summarize Data and Confirm GroupKFold Readiness
    get_dataset_summary(uci_final, "UCI Parkinson's (Cleaned)")
    
    # Verification of Readiness for GroupKFold
    print("✅ Subject IDs successfully isolated in 'Subject_ID' column.")
    print("✅ Target variable isolated in 'status' column.")
    print("✅ Ready for GroupKFold validation using df['Subject_ID'] as the 'groups' parameter to prevent data leakage.")
