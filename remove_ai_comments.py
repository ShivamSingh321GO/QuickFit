import os
import re

def is_ai_comment(line):
    line = line.strip()
    if not line.startswith('//'): return False
    
    # Ignore empty comments
    if line == '//': return False
    
    # Ignore file headers (e.g. //  HomeView.swift)
    if re.match(r'^//\s+[a-zA-Z0-9_\-\+]+\.swift$', line): return False
    
    # Ignore project names (e.g. //  QuickFit)
    if re.match(r'^//\s+QuickFit$', line): return False
    
    # Ignore standard MARKs
    if line.startswith('// MARK:'): return False
    
    return True

def process_file(filepath):
    with open(filepath, 'r') as f:
        lines = f.readlines()
        
    new_lines = []
    changed = False
    for line in lines:
        if is_ai_comment(line):
            changed = True
            continue
        new_lines.append(line)
        
    if changed:
        with open(filepath, 'w') as f:
            f.writelines(new_lines)
        print(f"Cleaned {filepath}")

for root, dirs, files in os.walk('QuickFit'):
    for file in files:
        if file.endswith('.swift'):
            process_file(os.path.join(root, file))
