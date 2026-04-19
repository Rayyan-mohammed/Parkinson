import pandas as pd
import synapseclient
import os

def download_mpower_from_manifest(manifest_path, download_dir, auth_token=None, limit=None):
    """
    Reads the Synapse manifest file and retrieves all associated files from mPower.
    Due to the size of mPower (thousands of files), this script can take several hours depending on bandwidth.
    """
    if not os.path.exists(manifest_path):
        print(f"Error: Manifest file not found at {manifest_path}")
        return

    # 1. Load the manifest
    print(f"Loading manifest from {manifest_path}...")
    manifest = pd.read_csv(manifest_path)
    
    # 2. Login to Synapse
    syn = synapseclient.Synapse()
    
    try:
        if auth_token:
            print("Logging into Synapse using Auth Token...")
            syn.login(authToken=auth_token)
        else:
            # Assumes .synapseConfig is present in user's home directory
            print("Logging into Synapse using cached credentials (.synapseConfig)...")
            syn.login()
    except Exception as e:
        print(f"Failed to login to Synapse: {e}")
        print("Please provide a valid auth_token or ensure you are logged in.")
        return

    # 3. Prepare the Download directory
    os.makedirs(download_dir, exist_ok=True)
    print(f"Download directory set to: {download_dir}")

    # 4. Iterate over the manifest and download each specified entity
    total_files = len(manifest)
    print(f"Total files in manifest: {total_files}")
    
    # Identify the Synapse ID column (usually 'id' or 'ID')
    id_col = 'id' if 'id' in manifest.columns else 'ID'
    if id_col not in manifest.columns:
        print("Could not locate the Synapse ID column in the manifest.")
        return

    files_to_download = manifest[id_col].dropna().unique()
    
    if limit:
        files_to_download = files_to_download[:limit]
        print(f"--- Limit set: Only downloading the first {limit} files ---")

    downloaded_paths = []
    
    for i, syn_id in enumerate(files_to_download):
        try:
            print(f"[{i+1}/{len(files_to_download)}] Requesting {syn_id}...")
            # Use `syn.get()` to download the file by its Synapse ID
            # Setting downloadLocation specifies where to save it
            entity = syn.get(syn_id, downloadLocation=download_dir, ifcollision="keep.both")
            downloaded_paths.append(entity.path)
            print(f"   Saved to: {entity.path}")
        except Exception as e:
            print(f"   Failed to download {syn_id}: {e}")

    print("\n" + "="*50)
    print(f"Download Process Complete!")
    print(f"Successfully downloaded {len(downloaded_paths)} files to '{download_dir}'.")
    print("="*50)


if __name__ == "__main__":
    # Define file paths
    MANIFEST_PATH = "data/mental health indicators/manifest.csv"
    DOWNLOAD_DIR = "data/mpower_audio"
    
    # Provide your Synapse Token here (or rely on .synapseConfig cache if it's already set up)
    YOUR_SYNAPSE_TOKEN = "eyJ0eXAiOiJKV1QiLCJraWQiOiJXN05OOldMSlQ6SjVSSzpMN1RMOlQ3TDc6M1ZYNjpKRU9VOjY0NFI6VTNJWDo1S1oyOjdaQ0s6RlBUSCIsImFsZyI6IlJTMjU2In0.eyJhY2Nlc3MiOnsic2NvcGUiOlsidmlldyIsImRvd25sb2FkIl0sIm9pZGNfY2xhaW1zIjp7fX0sInRva2VuX3R5cGUiOiJQRVJTT05BTF9BQ0NFU1NfVE9LRU4iLCJpc3MiOiJodHRwczovL3JlcG8tcHJvZC5wcm9kLnNhZ2ViYXNlLm9yZy9hdXRoL3YxIiwiYXVkIjoiMCIsIm5iZiI6MTc3NTYyMzE5MiwiaWF0IjoxNzc1NjIzMTkyLCJqdGkiOiIzNTE4OCIsInN1YiI6IjM1ODMyMzMifQ.aHE6Ld9OTOm5gBhVKLDShxsCqPcTDQKLiGA0BXYaFk-BjQf89PEsYLLCrxygVXCO5OcVgXG2NUfn_OXwHiu7Xnw613GlpCzjekPwgTOUnJKSI2rkW0DuPdCvre1RR9K_ZHPBZpBUt4MTicaJZBmtr1fSf_082vlGLo-69G253o9YHfu4Up9KOfgTQZIHqPPVYAQpEZ71tjfJuyM9D8qwcuIUwK-q5N_WYk4jUFCWekNdhxpmmI9EHI7hQPSue_Q0ii8lLYyFYmJL8Myg1KAt3-CVnSHs0tVGjo5QFSPmu_g2Ctympexax6gJLmmnWaUV1W54CAiL5ts3ZdIhkah0cw"
    
    print("Starting Synapse Wrapper Download Script...")
    
    # Change 'limit=None' to download ALL 19,000+ files. 
    # Current limit is set to 5 for testing your connection without crashing your IDE.
    download_mpower_from_manifest(
        manifest_path=MANIFEST_PATH, 
        download_dir=DOWNLOAD_DIR, 
        auth_token=YOUR_SYNAPSE_TOKEN,
        limit=None # Downloading the full dataset
    )
