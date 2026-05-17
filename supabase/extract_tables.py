import re

with open('/Users/wahyukurnia/www/pos-saas/supabase/schema.sql', 'r') as f:
    content = f.read()

# Find all CREATE TABLE blocks
# This regex looks for 'CREATE TABLE name (' and captures until the matching ');'
# Note: pg_dump formats CREATE TABLE beautifully.
matches = re.finditer(r'(CREATE TABLE [^;]+;)', content)

extracted = []
for m in matches:
    extracted.append(m.group(1))

with open('/Users/wahyukurnia/www/pos-saas/supabase/schema_tables.sql', 'w') as f:
    f.write('\n\n'.join(extracted))

print(f"Extracted {len(extracted)} tables.")
