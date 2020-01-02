import os
import shutil

os.system("flutter clean")

folders = [
    "example/build",
    "example/ios/Pods",
    "android/.gradle",
    "example/android/.gradle"
]

for folder in folders:
    if not os.path.exists(folder):
        continue
    shutil.rmtree(folder)
