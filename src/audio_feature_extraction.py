import os
import glob
import numpy as np
import pandas as pd
import librosa
import opensmile
import warnings

# Suppress warnings for clean output
warnings.filterwarnings('ignore')

def get_speaking_rate(y, sr):
    """
    Estimates speaking rate (syllables per second) using onset detection.
    This is an approximation suitable for continuous speech tasks.
    """
    # Compute onset envelope
    onset_env = librosa.onset.onset_strength(y=y, sr=sr)
    
    # Detect onset peaks (approximate "syllable" starts)
    peaks = librosa.util.peak_pick(onset_env, pre_max=3, post_max=3, pre_avg=3, post_avg=5, delta=0.5, wait=10)
    
    # Duration in seconds
    duration = librosa.get_duration(y=y, sr=sr)
    
    if duration == 0:
        return 0.0
    return len(peaks) / duration

def extract_features_from_audio(file_path):
    """
    Extracts acoustic features from a single audio file.
    Uses librosa for MFCCs, F0, and speaking rate.
    Uses OpenSMILE for clinical voice standard features (Jitter, Shimmer, HNR).
    """
    features = {}
    
    try:
        # Load audio using librosa
        y, sr = librosa.load(file_path, sr=None)
        
        # 1. Fundamental Frequency (F0) using YIN
        # Limit F0 search roughly between 50Hz and 500Hz for human voice
        f0 = librosa.yin(y, fmin=50, fmax=500)
        f0 = f0[~np.isnan(f0)] # Remove NaNs
        features['F0_mean'] = np.mean(f0) if len(f0) > 0 else 0
        features['F0_std'] = np.std(f0) if len(f0) > 0 else 0
        features['F0_range'] = (np.max(f0) - np.min(f0)) if len(f0) > 0 else 0
        
        # 2. MFCCs (13 coefficients)
        mfcc = librosa.feature.mfcc(y=y, sr=sr, n_mfcc=13)
        for i in range(1, 14):
            features[f'MFCC_{i}_mean'] = np.mean(mfcc[i-1])
            features[f'MFCC_{i}_std'] = np.std(mfcc[i-1])
            
        # 3. Speaking Rate
        features['speaking_rate'] = get_speaking_rate(y, sr)
        
        # 4. OpenSMILE features (eGeMAPS standard set contains Jitter, Shimmer, HNR)
        smile = opensmile.Smile(
            feature_set=opensmile.FeatureSet.eGeMAPSv02,
            feature_level=opensmile.FeatureLevel.Functionals,
            log_level=2
        )
        smile_df = smile.process_file(file_path)
        
        # Extract specific phonation features from the OpenSMILE output
        # EGeMAPS names for Jitter, Shimmer, and HNR (Harmonic-to-Noise Ratio)
        cols_of_interest = ['jitterLocal_sma3nz_amean', 'shimmerLocaldB_sma3nz_amean', 'HNRdBACF_sma3nz_amean']
        for col in cols_of_interest:
            if col in smile_df.columns:
                features[col] = smile_df[col].values[0]
                
    except Exception as e:
        print(f"Error processing {file_path}: {e}")
        
    return features


def process_directory_to_subject_matrix(audio_dir):
    """
    Processes all audio files in a directory, aggregates features per recording, 
    and then aggregates per SUBJECT.
    
    Assumes file naming convention includes Subject ID: e.g., 'Subject_S01_task1.wav'
    """
    audio_files = glob.glob(os.path.join(audio_dir, '**', '*.wav'), recursive=True) + \
                  glob.glob(os.path.join(audio_dir, '**', '*.m4a'), recursive=True)
                  
    if not audio_files:
        print(f"No audio files found in {audio_dir}.")
        return pd.DataFrame()
        
    print(f"Found {len(audio_files)} audio files. Starting extraction...")
    
    recording_records = []
    
    # Pass 1: Recording-level extraction
    for file_path in audio_files:
        filename = os.path.basename(file_path)
        
        # --- IMPORTANT ---
        # Modify this splitting logic depending on how mPower files are named tomorrow!
        # E.g., if mPower names are "healthCode_taskID.m4a", then subject_id is split[0]
        try:
            subject_id = filename.split('_')[1] # Placeholder logic
        except IndexError:
            subject_id = "Unknown"
        
        feat_dict = extract_features_from_audio(file_path)
        feat_dict['Subject_ID'] = subject_id
        feat_dict['recording_id'] = filename
        recording_records.append(feat_dict)
        
    recording_df = pd.DataFrame(recording_records)
    
    if recording_df.empty:
        return recording_df
        
    # Standardize missing values if any failed 
    recording_df = recording_df.fillna(recording_df.median(numeric_only=True))

    # Pass 2: Subject-level aggregation
    # We drop 'recording_id' as we aggregate per Subject_ID
    print("Aggregating features per subject to prevent data leakage...")
    
    aggregation_funcs = {col: ['mean', 'std'] for col in recording_df.columns if col not in ['Subject_ID', 'recording_id']}
    
    subject_df = recording_df.groupby('Subject_ID').agg(aggregation_funcs).reset_index()
    
    # Flatten MultiIndex columns (e.g., 'F0_mean_mean', 'F0_mean_std')
    subject_df.columns = ['_'.join(col).strip('_') for col in subject_df.columns.values]
    
    return subject_df

if __name__ == "__main__":
    # Example usage for tomorrow once mPower audio is extracted:
    AUDIO_DIR = "data/mpower_audio"
    
    if not os.path.exists(AUDIO_DIR):
        print(f"Directory {AUDIO_DIR} does not exist yet. Create it and place the raw audio files inside.")
    else:
        subject_level_matrix = process_directory_to_subject_matrix(AUDIO_DIR)
        
        if not subject_level_matrix.empty:
            print("\n" + "="*50)
            print("Feature Extraction Complete!")
            print(f"Final subject-level matrix shape: {subject_level_matrix.shape}")
            print(f"Total Subjects: {subject_level_matrix['Subject_ID'].nunique()}")
            print(f"Total Aggregated Acoustic Features: {subject_level_matrix.shape[1] - 1}")
            print("\nFeature names sample:")
            print(subject_level_matrix.columns[1:10].tolist())
            print("="*50)
            
            # Save the robust subject-level matrix for modeling
            os.makedirs("results", exist_ok=True)
            subject_level_matrix.to_csv("results/mpower_subject_features.csv", index=False)
            print("✅ Features saved to 'results/mpower_subject_features.csv' safely separated per subject.")
