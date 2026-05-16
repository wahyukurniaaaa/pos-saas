import re
import os
import glob

# Read SQL
with open('../supabase/schema.sql', 'r') as f:
    sql_content = f.read()

# Parse SQL tables and columns
sql_tables = {}
current_table = None
for line in sql_content.split('\n'):
    line = line.strip()
    if line.startswith('CREATE TABLE'):
        match = re.search(r'CREATE TABLE public\.([a-z_]+)', line)
        if match:
            current_table = match.group(1)
            sql_tables[current_table] = {}
    elif current_table and line and not line.startswith(')') and not line.startswith('CONSTRAINT') and not line.startswith('CREATE'):
        parts = line.split()
        if len(parts) >= 2:
            col_name = parts[0]
            if col_name.startswith('CONSTRAINT'):
                continue
            is_nullable = 'NOT NULL' not in line
            sql_tables[current_table][col_name] = {'nullable': is_nullable}

# Function to convert camelCase to snake_case
def to_snake_case(name):
    s1 = re.sub('(.)([A-Z][a-z]+)', r'\1_\2', name)
    return re.sub('([a-z0-9])([A-Z])', r'\1_\2', s1).lower()

# Parse Dart tables
dart_tables = {}
for filepath in glob.glob('lib/core/database/tables/*.dart'):
    with open(filepath, 'r') as f:
        content = f.read()
    
    current_table = None
    # Very basic parsing, assuming table name matches filename roughly or class name
    for line in content.split('\n'):
        line = line.strip()
        class_match = re.search(r'class ([A-Za-z]+) extends Table', line)
        if class_match:
            class_name = class_match.group(1)
            # convert ClassName to snake_case for comparison
            # special cases might exist but mostly it works
            current_table = to_snake_case(class_name)
            dart_tables[current_table] = {}
        
        col_match = re.search(r'(Text|Int|Bool|Real|DateTime)Column get ([a-zA-Z0-9_]+) =>', line)
        if col_match and current_table:
            col_name_camel = col_match.group(2)
            col_name_snake = to_snake_case(col_name_camel)
            is_nullable = '.nullable()' in line
            dart_tables[current_table][col_name_snake] = {'nullable': is_nullable}

# Compare
print("=== SCHEMA COMPARISON REPORT ===")
for table, sql_cols in sql_tables.items():
    if table in ['users', 'user_roles', 'mapping_skus', 'license_devices', 'landing_page_settings']:
        continue # Ignore auth/system tables
        
    print(f"\n--- Table: {table} ---")
    if table not in dart_tables:
        print(f"  WARNING: Table '{table}' found in SQL but not parsed in Dart.")
        continue
    
    dart_cols = dart_tables[table]
    
    # Check SQL to Dart
    for col_name, sql_info in sql_cols.items():
        if col_name not in dart_cols:
            print(f"  [MISSING IN DART] Column '{col_name}' exists in SQL but not in Dart.")
        else:
            dart_info = dart_cols[col_name]
            if sql_info['nullable'] != dart_info['nullable']:
                print(f"  [NULLABLE GAP] Column '{col_name}' -> SQL nullable: {sql_info['nullable']}, Dart nullable: {dart_info['nullable']}")
                
    # Check Dart to SQL
    for col_name in dart_cols:
        if col_name not in sql_cols:
            print(f"  [MISSING IN SQL] Column '{col_name}' exists in Dart but not in SQL.")

