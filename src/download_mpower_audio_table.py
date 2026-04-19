import synapseclient
import os
import shutil

def download_mpower_audio_from_table(auth_token, download_dir, table_id="syn5511444", limit=None):
    """
    Queries the actual mPower Voice Activity Table on Synapse, 
    extracts the file handles for the audio recordings, and downloads them.
    It automatically renames them to include the Subject's Health Code 
    so our feature extraction script works flawlessly out of the box.
    """
    syn = synapseclient.Synapse()
    print("Logging into Synapse...")
    syn.login(authToken=auth_token)

    os.makedirs(download_dir, exist_ok=True)

    print(f"Querying mPower voice table: {table_id}...")
    
    # Add a limit for testing, or query the entire table
    limit_clause = f" LIMIT {limit}" if limit else ""
    query_str = f"SELECT * FROM {table_id}{limit_clause}"
    
    try:
        results = syn.tableQuery(query_str)
        df = results.asDataFrame()
    except Exception as e:
        print(f"Error querying table {table_id}. Make sure you have authorized access to mPower. Details: {e}")
        return
        
    print(f"Found {len(df)} records. Looking for audio files...")
    
    # In mPower, the audio file is typically stored as file handles in columns like 'audio_audio.m4a'
    file_handle_cols = [col for col in df.columns if "audio" in col.lower() or "file" in col.lower()]
    
    if not file_handle_cols:
        print(f"Could not find an audio file column. Available columns: {df.columns.tolist()}")
        # Let's forcefully check if 'audio_audio.m4a' is there just in case
        if 'audio_audio.m4a' in df.columns:
            file_handle_cols = ['audio_audio.m4a']
        else:
            return
            
    print(f"Downloading audio handles from columns: {file_handle_cols}")
    
    for col in file_handle_cols:
        try:
            print(f"Processing column '{col}'...")
            # This downloads the file handles to a local cache
            file_map = syn.downloadTableColumns(results, [col])
            
            count = 0
            for file_handle_id, cache_path in file_map.items():
                if not cache_path: continue
                
                # We trace back the file handle ID to the row to get the Subject ID ('healthCode')
                # df columns might be floats/strings, let's do a safe string match
                row = df[df[col].astype(str) == str(file_handle_id)]
                if not row.empty:
                    health_code = row['healthCode'].values[0] if 'healthCode' in df.columns else "Unknown"
                    is_pd = row['professional-diagnosis'].values[0] if 'professional-diagnosis' in df.columns else "Unknown"
                    
                    # Naming format: Subject_HealthCode_IsPD_FileID.m4a
                    # This ensures our feature extraction script's split('_')[1] grabs the health_code!
                    new_filename = f"Subject_{health_code}_{is_pd}_{file_handle_id}.m4a"
                    new_path = os.path.join(download_dir, new_filename)
                    
                    shutil.copy(cache_path, new_path)
                    print(f"Saved: {new_filename}")
                    count += 1
            print(f"Successfully processed {count} audio files from '{col}'.")
            
        except Exception as e:
            print(f"Warning: Failed processing column {col}. Error: {e}")

    print("\n" + "="*50)
    print(f"Table Audio Download Process Complete!")
    print(f"Files are ready in '{download_dir}'.")
    print("="*50)

if __name__ == "__main__":
    YOUR_SYNAPSE_TOKEN = "eyJ0eXAiOiJKV1QiLCJraWQiOiJXN05OOldMSlQ6SjVSSzpMN1RMOlQ3TDc6M1ZYNjpKRU9VOjY0NFI6VTNJWDo1S1oyOjdaQ0s6RlBUSCIsImFsZyI6IlJTMjU2In0.eyJhY2Nlc3MiOnsic2NvcGUiOlsidmlldyIsImRvd25sb2FkIl0sIm9pZGNfY2xhaW1zIjp7fX0sInRva2VuX3R5cGUiOiJQRVJTT05BTF9BQ0NFU1NfVE9LRU4iLCJpc3MiOiJodHRwczovL3JlcG8tcHJvZC5wcm9kLnNhZ2ViYXNlLm9yZy9hdXRoL3YxIiwiYXVkIjoiMCIsIm5iZiI6MTc3NTYyMzE5MiwiaWF0IjoxNzc1NjIzMTkyLCJqdGkiOiIzNTE4OCIsInN1YiI6IjM1ODMyMzMifQ.aHE6Ld9OTOm5gBhVKLDShxsCqPcTDQKLiGA0BXYaFk-BjQf89PEsYLLCrxygVXCO5OcVgXG2NUfn_OXwHiu7Xnw613GlpCzjekPwgTOUnJKSI2rkW0DuPdCvre1RR9K_ZHPBZpBUt4MTicaJZBmtr1fSf_082vlGLo-69G253o9YHfu4Up9KOfgTQZIHqPPVYAQpEZ71tjfJuyM9D8qwcuIUwK-q5N_WYk4jUFCWekNdhxpmmI9EHI7hQPSue_Q0ii8lLYyFYmJL8Myg1KAt3-CVnSHs0tVGjo5QFSPmu_g2Ctympexax6gJLmmnWaUV1W54CAiL5ts3ZdIhkah0cw"
    DOWNLOAD_DIR = "data/mpower_audio"
    
    # We will start with a limit of 10 to test it instantly!
    # Removing this limit will download ALL audio from the table.
    download_mpower_audio_from_table(
        auth_token=YOUR_SYNAPSE_TOKEN, 
        download_dir=DOWNLOAD_DIR, 
        table_id="syn5511444", 
        limit=10 
    )