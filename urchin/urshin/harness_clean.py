"""urshin - clean version with LOGLEVEL support"""
import os

LOGLEVEL = os.environ.get("LOGLEVEL", "INFO").upper()

def log(level, msg, *args):
    if level == "DEBUG" and LOGLEVEL == "DEBUG":
        print(f"DEBUG: {msg % args if args else msg}")
    elif level in ["INFO", "WARNING", "ERROR"]:
        print(f"{level}: {msg % args if args else msg}")

# Test
log("INFO", "Logging initialized at %s", LOGLEVEL)
