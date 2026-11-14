#!/usr/bin/env python3
import json
import subprocess
import sys


def run_cmd(cmd):
    result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, shell=True)
    return result.stdout.strip()

def get_windows():
    try:
        return json.loads(run_cmd("niri msg -j windows"))
    except Exception:
        return []

def main():
    # Track mapping of child window ID -> swallowed terminal ID
    swallowed_map = {}
    
    # Listen to niri event stream
    proc = subprocess.Popen(["niri", "msg", "event-stream"], stdout=subprocess.PIPE, text=True)
    
    for line in proc.stdout:
        line = line.strip()
        if not line.startswith("{"):
            continue
        try:
            event = json.loads(line)
        except json.JSONDecodeError:
            continue
            
        # Handle WindowOpened event
        if "WindowOpened" in event:
            win = event["WindowOpened"].get("window", {})
            child_id = win.get("id")
            app_id = win.get("app_id", "").lower()
            
            # Skip terminals themselves
            terminals = ["kitty", "alacritty", "foot", "wezterm", "ghostty"]
            if not child_id or any(t in app_id for t in terminals):
                continue
                
            windows = get_windows()
            # Find currently focused window (which launched the app)
            focused = next((w for w in windows if w.get("is_focused")), None)
            
            if focused and focused["id"] != child_id:
                term_id = focused["id"]
                term_app = focused.get("app_id", "").lower()
                
                if any(t in term_app for t in terminals):
                    # Hide terminal to a hidden scratchpad workspace
                    subprocess.run(f"niri msg action move-window-to-workspace --window-id {term_id} swallowed --focus false", shell=True)
                    swallowed_map[child_id] = term_id

        # Handle WindowClosed event
        elif "WindowClosed" in event:
            closed_id = event["WindowClosed"].get("id")
            if closed_id in swallowed_map:
                term_id = swallowed_map.pop(closed_id)
                # Get current active workspace name
                workspaces = json.loads(run_cmd("niri msg -j workspaces"))
                current_ws = next((ws["name"] for ws in workspaces if ws.get("is_focused")), "1")
                
                # Bring terminal back to current workspace and focus it
                subprocess.run(f"niri msg action move-window-to-workspace --window-id {term_id} {current_ws}", shell=True)
                subprocess.run(f"niri msg action focus-window --id {term_id}", shell=True)

if __name__ == "__main__":
    main()
