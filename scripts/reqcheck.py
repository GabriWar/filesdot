import subprocess
import time
import hashlib
import difflib
import os


def execute_curl_command(file_path):
    with open(file_path, "r") as file:
        curl_command = file.read().strip()

    result = subprocess.run(curl_command, shell=True, capture_output=True, text=True)
    return result.stdout


def save_to_cache(response_line, cache_file):
    with open(cache_file, "w") as file:
        file.write(response_line)


def load_from_cache(cache_file):
    try:
        with open(cache_file, "r") as file:
            return file.read()
    except FileNotFoundError:
        return None


def get_hash(content):
    return hashlib.md5(content.encode()).hexdigest()


def highlight_changes(old, new):
    diff = difflib.unified_diff(
        old.splitlines(keepends=True),
        new.splitlines(keepends=True),
        fromfile="previous_response",
        tofile="current_response",
        lineterm="",
    )
    return "".join(diff)


def extract_last_line(response):
    # Split the response into headers and body
    parts = response.split("\r\n\r\n", 1)
    if len(parts) > 1:
        body = parts[1]
    else:
        body = response
    # Get the last line of the body
    return body.strip().split("\n")[-1]


def send_notification(message):
    subprocess.run(["notify-send", message])


def main():
    file_path = "request.txt"  # Path to the file containing the curl command
    cache_file = "response_cache.txt"  # Path to the cache file

    if not os.path.exists(file_path):
        print(f"The file '{file_path}' does not exist.")
        print(
            "This script executes a curl command from the specified file and checks for changes in the response."
        )
        print(
            "Please create a 'request.txt' file with the curl command to be executed."
        )
        return

    previous_line = load_from_cache(cache_file)
    previous_hash = get_hash(previous_line) if previous_line else None

    while True:
        response = execute_curl_command(file_path)
        current_line = extract_last_line(response)
        current_hash = get_hash(current_line)

        if previous_hash and current_hash != previous_hash:
            print("Response has changed.")
            print("Changes:")
            if previous_line:
                print(highlight_changes(previous_line, current_line))
            send_notification("Response has changed.")
            previous_line = current_line
            previous_hash = current_hash
        else:
            save_to_cache(current_line, cache_file)
            previous_hash = current_hash
            print("Response has not changed. Checking again in 10 seconds...")

        time.sleep(10)


if __name__ == "__main__":
    main()
