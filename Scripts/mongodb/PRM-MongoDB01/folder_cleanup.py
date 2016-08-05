"""
## CODE OWNERS: Ben Wyatt

### OBJECTIVE:
  Clean up outdated backup files from PRM-MongoDB02

### DEVELOPER NOTES:

"""
import os
import re
import time
import shutil

# number of seconds in a day * number of days of folders to keep
NUMDAYS = 86400*15
NOW = time.time()

# Path to the folder to be cleaned up
CHECK_DIRECTORY = os.path.abspath(r"C:\PRM-CDR_Archive")
TARGET_DIRECTORY = r"\\indy-backup\PRM-MONGODB\PRM-MongoDB01"

print("Copying folders from ", CHECK_DIRECTORY, " to ", TARGET_DIRECTORY)
print("")

# Regular expression to match folder names to be removed
FOLDER_PATTERN = "^20[0-9]{2}y-[0-9]{2}m-[0-9]{2}d@[0-9]+h-[0-9]{2}mPT$"

# Recurse over the indicated directory
# Remove folders that match the regex and age
for r, d, f in os.walk(CHECK_DIRECTORY):
    for foldername in d:
        full_path = os.path.join(r, foldername)
        timestamp = os.path.getmtime(full_path)
        if NOW-NUMDAYS > timestamp and re.match(FOLDER_PATTERN, foldername):
            try:
                print("Moving ", full_path)
                shutil.move(full_path, TARGET_DIRECTORY)
            except shutil.Error as err:
                print(err)
            else:
                print("success\n\n")
        else:
            print("not removing", full_path, "\n")
