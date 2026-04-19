import os
import glob
import numpy as np
import pandas as pd
import librosa
import torch
import warnings
from transformers import Wav2Vec2Processor, Wav2Vec2Model
from tqdm import tqdm

# Suppress librosa warning about PySoundFile missing temporarily
warnings.filterwarnings('ignore', category=UserWarning)

class DeepAudioEmbedder:
    def __init__(self, model_name="facebook/wav2vec2-base", device=None):
        """
        Initializes the Wav2Vec 2.0 processor and model.
        """
        print(f"Loading transformer model: {model_name}...")
        self.processor = Wav2Vec2Processor.from_pretrained(model_name)
        self.model = Wav2Vec2Model.from_pretrained(model_name)
        
        # Use GPU if available
        if device is None:
            self.device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
        else:
            self.device = torch.device(device)
            
        print(f"Using device: {self.device}")
        self.model.to(self.device)
        self.model.eval()

    def process_audio_file(self, file_path):
        """
        Loads an audio file and returns the mean pooled transformer embedding.
        """
        try:
            # Wav2Vec requires exactly 16kHz sample rate
            audio, sr = librosa.load(file_path, sr=16000)
            
            # Pad short audio to minimum length (at least 1 second)
            if len(audio) < 16000:
                audio = librosa.util.pad_center(audio, size=16000)
                
            # Process to PyTorch tensors
            inputs = self.processor(audio, sampling_rate=16000, return_tensors="pt", padding=True)
            input_values = inputs.input_values.to(self.device)
            
            # Forward pass (no gradients needed)
            with torch.no_grad():
                outputs = self.model(input_values)
                
            # Wav2Vec outputs contextualized representations for each timeframe.
            # Shape is (batch_size, sequence_length, hidden_size).
            hidden_states = outputs.last_hidden_state
            
            # To get a single vector per audio file, we pool the hidden states.
            # Mean pooling across the time dimension:
            pooled_embedding = torch.mean(hidden_states, dim=1).squeeze().cpu().numpy()
            return pooled_embedding
            
        except Exception as e:
            print(f"Error processing {file_path}: {e}")
            return None

def extract_features(data_dir, output_csv="results/paper_tables/mPower_Transformer_Embeddings.csv"):
    """
    Scans data directory for audio, runs Wav2Vec2, and saves to CSV.
    """
    os.makedirs(os.path.dirname(output_csv), exist_ok=True)
    
    audio_files = glob.glob(os.path.join(data_dir, "**", "*.wav"), recursive=True) + \
                  glob.glob(os.path.join(data_dir, "**", "*.m4a"), recursive=True)
                  
    if not audio_files:
        print(f"No .wav or .m4a files found in {data_dir}. Ensure download finished.")
        return
        
    print(f"Found {len(audio_files)} audio files for deep learning extraction.")
    
    embedder = DeepAudioEmbedder()
    
    results = []
    
    print("\nStarting neural feature extraction (this requires heavy computation)...")
    for file in tqdm(audio_files):
        # Infer subject/record ID from filename (assuming mPower structure)
        filename = os.path.basename(file)
        
        embedding = embedder.process_audio_file(file)
        
        if embedding is not None:
            # Create a dictionary with filename and the 768 hidden features
            row = {'filename': filename}
            for i, val in enumerate(embedding):
                row[f'wav2vec_hidden_{i}'] = val
                
            results.append(row)
            
    if results:
        df = pd.DataFrame(results)
        df.to_csv(output_csv, index=False)
        print(f"\nExtraction complete! Saved {df.shape[1]-1} transformer dimensions to {output_csv}")
    else:
        print("No features extracted.")

if __name__ == "__main__":
    # Point this to where the mPower audio files will ultimately land
    target_directory = os.path.join("data", "mpower_audio")
    extract_features(target_directory)
