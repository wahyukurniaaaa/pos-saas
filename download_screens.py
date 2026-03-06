import json
import subprocess
import os
import re

json_file = r'C:\Users\wahyu\.gemini\antigravity\brain\316d0b20-59b5-43d2-a66b-8fcf1ee64048\.system_generated\steps\51\output.txt'

with open(json_file, 'r', encoding='utf-8') as f:
    data = json.load(f)

output_dir = r'c:\www\pos-umkm-saas\stitch_screens'
os.makedirs(output_dir, exist_ok=True)

for screen in data['screens']:
    title = screen.get('title', 'Unknown')
    clean_title = re.sub(r'[^\w\s-]', '', title).strip().replace(' ', '_')
    
    html_url = screen.get('htmlCode', {}).get('downloadUrl')
    img_url = screen.get('screenshot', {}).get('downloadUrl')
    
    if html_url:
        html_path = os.path.join(output_dir, f"{clean_title}.html")
        print(f"Downloading HTML for {title}...")
        subprocess.run(['curl', '-L', html_url, '-o', html_path], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    if img_url:
        img_path = os.path.join(output_dir, f"{clean_title}.png")
        print(f"Downloading Image for {title}...")
        subprocess.run(['curl', '-L', img_url, '-o', img_path], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

print("Done downloading screens.")
