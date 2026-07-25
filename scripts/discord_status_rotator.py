import requests
import time
import random
import threading
import os
import logging
import subprocess

logging.basicConfig(
    level=logging.INFO,
    format="[%(asctime)s] %(message)s",
    datefmt="%H:%M:%S"
)
# Please, Please, Please use a .env file instead of hardcoding your tokens if you want to reuse this script i dont do it because im too lazy
# but genuinely if you want to publish this with modifications or share it do not hardcode the tokens
TOKENS = []
LYRICS = "" # replace with your lyrics file (must be in the same folder as this script)

# NO this wont work without systemd half the time

# thread management for systemd state (requires Spotify and a seperate script, but this is usually off by default)
state_lock = threading.Lock()
node_service_active = False
lyric_service = False

def manage_node_service():
    global node_service_active

    if not lyric_service:
        return False
    try:
        status = subprocess.check_output(
            ["dbus-send", "--print-reply", "--dest=org.mpris.MediaPlayer2.spotify",
             "/org/mpris/MediaPlayer2", "org.freedesktop.DBus.Properties.Get",
             "string:org.mpris.MediaPlayer2.Player", "string:PlaybackStatus"],
            stderr=subprocess.DEVNULL
        ).decode()
        playing = "string \"Playing\"" in status
    except (subprocess.CalledProcessError, FileNotFoundError):
        playing = False

    with state_lock:
        if playing and not node_service_active:
            logging.info("spotify playback detected, running lyrics-status service.")
            subprocess.run(["systemctl", "--user", "start", "lyrics-status.service"], stderr=subprocess.DEVNULL)
            node_service_active = True
        elif not playing and node_service_active:
            logging.info("spotify idle/stopped, killing lyrics-status service.")
            subprocess.run(["systemctl", "--user", "stop", "lyrics-status.service"], stderr=subprocess.DEVNULL)
            node_service_active = False

    return playing

def get_lyrics():
    if os.path.exists(LYRICS):
        with open(LYRICS, "r") as f:
            return [line.strip() for line in f.readlines() if line.strip()]
    return []

def run_account_rotator(token, lyrics_list):
    session = requests.Session()
    session.headers.update({
        "Authorization": token,
        "Content-Type": "application/json"
    })

    last_status = None

    while True:
        try:
            if manage_node_service():
                time.sleep(10)
                continue

            choices = [s for s in lyrics_list if s != last_status] if len(lyrics_list) > 1 else lyrics_list
            status = random.choice(choices)

            data = {
                "custom_status": {
                    "text": status,
                    "emoji_id": "", # put emoji id from discord here (use \:emojiname: to get the id)
                    "emoji_name": "", # put emoji name from discord here
                    "animated": False
                }
            }
          # its probably not the best idea to ping discord api directly without something like discord.py but i dont care
            response = session.patch(
                "https://discord.com/api/v9/users/@me/settings",
                json=data,
                timeout=10
            )

            if response.status_code == 200:
                logging.info(f"updating status for account {token[:10]}... with status: {status}")
                last_status = status
            elif response.status_code == 429:
                wait = response.json().get("retry_after", 60)
                logging.warning(f"rate limited on account {token[:10]}... sleeping {wait}s")
                time.sleep(wait)
                continue
            else:
                logging.error(f"error {response.status_code} for account {token[:10]}...: {response.text}")

        except Exception as e:
            logging.error(f"connection error for {token[:10]}...: {e}")

        time.sleep(random.randint(15, 60))

if __name__ == "__main__":
    lyrics = get_lyrics()
    if not lyrics:
        logging.error(f"error, cannot start: {LYRICS} is empty or missing")
        exit(1)

    threads = []
    for token in TOKENS:
        thread = threading.Thread(target=run_account_rotator, args=(token, lyrics), daemon=False)
        threads.append(thread)
        thread.start()

    for thread in threads:
        thread.join()
