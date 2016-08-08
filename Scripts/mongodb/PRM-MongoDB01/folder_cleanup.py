"""
## CODE OWNERS: Ben Wyatt, Steve Gredell

### OBJECTIVE:
  Clean up outdated backup files from PRM-MongoDB01

### DEVELOPER NOTES:

"""
import re
import time
import shutil
#from pathlib import Path
from indypy.file_utils import IndyPyPath

# number of seconds in a day * number of days of folders to keep
NUMDAYS = 86400*15
NOW = time.time()

# Path to the folder to be cleaned up
CHECK_DIRECTORY = r"C:\PRM-CDR_Archive"
TARGET_DIRECTORY = r"\\indy-backup\PRM-MONGODB\PRM-MongoDB01"

print("Copying folders from", CHECK_DIRECTORY, "to", TARGET_DIRECTORY)
print("")

# Regular expression to match folder names to be removed
FOLDER_PATTERN = "20[0-9]{2}y-[0-9]{2}m-[0-9]{2}d@[0-9]+h-[0-9]{2}mPT"

# Recurse over the indicated directory
# Remove folders that match the regex and age
for folder in IndyPyPath(CHECK_DIRECTORY).collect_files_regex(FOLDER_PATTERN, collect_dirs = True):
    if NOW-NUMDAYS > folder.stat().st_mtime:
        try:
            print("Moving", folder)
            shutil.move(folder, TARGET_DIRECTORY)
        except shutil.Error as err:
            print(err)
        else:
            print("success\n")
    else:
        print("not moving", folder, "\n")
