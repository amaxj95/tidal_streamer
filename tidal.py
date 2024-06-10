import requests
import time
import vlc

# Replace with your Tidal API credentials
CLIENT_ID = '24XB9Vh5HTLAX89r'
CLIENT_SECRET = 'EdxMIiojRarrBgSjOjucuSEY7h6PfZni4rZlYJD37lg='

# Tidal API endpoints
TOKEN_URL = 'https://api.tidal.com/v1/oauth2/token'
TRACK_URL = 'https://api.tidal.com/v1/tracks/{track_id}/stream-url'

# Track ID for the song
TRACK_ID = '207206899'

# Function to authenticate and get access token
def get_access_token(client_id, client_secret):
    data = {
        'client_id': client_id,
        'client_secret': client_secret,
        'grant_type': 'client_credentials'
    }
    headers = {
        'Content-Type': 'application/x-www-form-urlencoded'
    }
    response = requests.post(TOKEN_URL, data=data, headers=headers)
    
    # Check if the response was successful
    if response.status_code == 200:
        response_data = response.json()
        print("Access Token Response:", response_data)  # Logging
        return response_data.get('access_token')
    else:
        print("Failed to get access token:", response.status_code, response.text)  # Logging
        return None

# Function to get the stream URL of the track
def get_stream_url(access_token, track_id):
    headers = {
        'Authorization': f'Bearer {access_token}'
    }
    response = requests.get(TRACK_URL.format(track_id=track_id), headers=headers)
    
    # Check if the response was successful
    if response.status_code == 200:
        response_data = response.json()
        print("Stream URL Response:", response_data)  # Logging
        return response_data.get('url')
    else:
        print("Failed to get stream URL:", response.status_code, response.text)  # Logging
        return None

# Main function to play the song continuously
def play_song_continuously(track_url):
    instance = vlc.Instance()
    player = instance.media_player_new()
    media = instance.media_new(track_url)
    player.set_media(media)

    while True:
        player.play()
        time.sleep(1)  # Give the player a moment to start
        length = player.get_length() / 1000  # Get track length in seconds
        time.sleep(length)  # Wait for the track to finish

if __name__ == '__main__':
    # Authenticate and get access token
    access_token = get_access_token(CLIENT_ID, CLIENT_SECRET)
    
    if access_token:
        # Get the stream URL for the track
        stream_url = get_stream_url(access_token, TRACK_ID)
        
        if stream_url:
            # Play the song continuously
            play_song_continuously(stream_url)
        else:
            print("Error: Could not retrieve stream URL.")
    else:
        print("Error: Could not retrieve access token.")
