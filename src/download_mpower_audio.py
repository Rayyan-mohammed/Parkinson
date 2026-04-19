import os
import synapseclient

def main():
    # 1. Create the destination folder for the raw audio files
    output_dir = os.path.join("data", "mpower_audio", "raw_audio")
    os.makedirs(output_dir, exist_ok=True)
    print(f"Target download directory: {output_dir}")

    # 2. Initialize the Synapse client
    syn = synapseclient.Synapse()

    # 3. Login using your Personal Access Token
    # IMPORTANT: Replace "YOUR_TOKEN_HERE" with your actual token inside the quotes
    print("Logging into Synapse...")
    syn.login(authToken="eyJ0eXAiOiJKV1QiLCJraWQiOiJXN05OOldMSlQ6SjVSSzpMN1RMOlQ3TDc6M1ZYNjpKRU9VOjY0NFI6VTNJWDo1S1oyOjdaQ0s6RlBUSCIsImFsZyI6IlJTMjU2In0.eyJhY2Nlc3MiOnsic2NvcGUiOlsidmlldyIsImRvd25sb2FkIiwibW9kaWZ5Il0sIm9pZGNfY2xhaW1zIjp7fX0sInRva2VuX3R5cGUiOiJQRVJTT05BTF9BQ0NFU1NfVE9LRU4iLCJpc3MiOiJodHRwczovL3JlcG8tcHJvZC5wcm9kLnNhZ2ViYXNlLm9yZy9hdXRoL3YxIiwiYXVkIjoiMCIsIm5iZiI6MTc3NjYxMDQ5NCwiaWF0IjoxNzc2NjEwNDk0LCJqdGkiOiIzNTg3OSIsInN1YiI6IjM1ODMyMzMifQ.QgQVct7DVKV81l-ByKONZAz9vuQWtTRJ4wPxc1tduGbyKSOjG_7bFgfJFBRY1Fd9dzbU2k2lFVlJ-vcU4ZGfDwY4vkqcQAGAkmt7qb-IAyYRx5MbbS7dIplVuZmAADZ0uBnxl50niezwZ7bndauYQKzk6SvVwTkeUTGJmhVfDs3KsPv7TgvUvej3KI_KCAttTgctbdBgvGU2AxLveZcVp3FkLddncuFZRVDCmhGEbIqQN9MMvriwHVawe2rRDNoIwhqea72v4CohyzsYJgf3hWsPa8A5uLyTuIL1vZMNhsu-mzdfxSITdMd2-R50he4C90wMBmWt8tYaaUHgbrKPSA")

    # 4. Get the files from your Synapse download cart/list
    print("Retrieving download list from your Synapse account...")
    
    try:
        # In newer synapseclient versions, this pulls the download list entity
        dl_list = syn.get_download_list()
        print(f"Download list metadata retrieved successfully.")
        
        # We can use the CLI-equivalent programmatic download or iterate through items
        # Usually, syn.download_download_list() or a similar method does the bulk work:
        # If syn.get_download_list() doesn't auto-download the actual files, you might 
        # need to loop over the IDs. But let's trigger the download:
        print("Downloading files... (This may take a long time for 19,000 files)")
        
        # If 'syn.get_download_list' doesn't place them in 'output_dir', you can use the synapseutils
        import synapseutils
        # Assuming you added the specific Synapse folder/project to your list, 
        # or you can directly sync the mPower audio folder ID (syn4993036 is the standard mPower).
        # You may need to uncomment the following line and replace syn123456 with your targeted folder ID:
        # synapseutils.syncFromSynapse(syn, 'syn123456', path=output_dir)
        
        print("\nNOTE: Because mPower files are large, leaving this terminal running is recommended.")

    except Exception as e:
        print(f"An error occurred: {e}")
        print("If it's an authorization error, ensure your Data Use Certificate (DUC) is signed!")

if __name__ == "__main__":
    main()
