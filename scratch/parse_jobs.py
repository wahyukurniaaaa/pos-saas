import re
import csv
from pathlib import Path

def parse_min_salary(salary_str):
    matches = re.findall(r'(\d+(?:\.\d+)?)M', salary_str)
    if not matches:
        return 0
    return min(float(m) for m in matches)

def escape_md(text):
    return text.replace('|', '\\|')

def main():
    file_path = Path('/Users/wahyukurnia/www/pos-saas/lowongan_depok.md')
    content = file_path.read_text(encoding='utf-8')
    
    cards = content.split('JobCardsc__JobcardContainer')
    
    results = []
    
    for card in cards[1:]:
        aria_match = re.search(r'aria-label="Job: ([^,]+), Company: ([^,]+), Location: ([^"]+)"', card)
        salary_match = re.search(r'SalaryWrapper[^>]*>([^<]+)</span>', card)
        title_match = re.search(r'JobCardTitleNoStyleAnchor[^>]*>([^<]+)</a>', card)
        
        if (aria_match or title_match) and salary_match:
            if aria_match:
                title = aria_match.group(1).strip()
                company = aria_match.group(2).strip()
                location = aria_match.group(3).strip()
            else:
                title = title_match.group(1).strip()
                company = "N/A"
                location = "Depok"
            
            salary_str = salary_match.group(1).strip()
            min_salary = parse_min_salary(salary_str)
            
            if min_salary >= 4.0:
                kecamatan = location
                
                if "pt rumah penyalur indonesia" in company.lower():
                    kecamatan = "Cinere"
                
                if kecamatan.lower() == "depok":
                    kecamatans = ["Beji", "Pancoran Mas", "Cipayung", "Sukmajaya", "Cilodong", "Limo", "Cinere", "Cimanggis", "Tapos", "Sawangan", "Bojongsari"]
                    for k in kecamatans:
                        if k.lower() in title.lower() or k.lower() in company.lower():
                            kecamatan = k
                            break
                
                results.append({
                    "No": len(results) + 1,
                    "Jabatan": title,
                    "Perusahaan": company,
                    "Gaji": salary_str,
                    "Kecamatan": kecamatan
                })
    
    # Save as Markdown
    md_output = "# Daftar Lowongan Kerja (Gaji Minimal 4 Juta)\n\n"
    md_output += "| No | Jabatan | Perusahaan | Gaji | Kecamatan |\n"
    md_output += "|---|---------|------------|------|-----------|\n"
    for res in results:
        md_output += f"| {res['No']} | {escape_md(res['Jabatan'])} | {escape_md(res['Perusahaan'])} | {escape_md(res['Gaji'])} | {escape_md(res['Kecamatan'])} |\n"
    
    md_file = Path('/Users/wahyukurnia/www/pos-saas/lowongan_depok_table.md')
    md_file.write_text(md_output, encoding='utf-8')
    
    # Save as CSV (for Excel)
    csv_file = Path('/Users/wahyukurnia/www/pos-saas/lowongan_depok.csv')
    with open(csv_file, mode='w', newline='', encoding='utf-8-sig') as f: # utf-8-sig for Excel compatibility
        writer = csv.DictWriter(f, fieldnames=["No", "Jabatan", "Perusahaan", "Gaji", "Kecamatan"])
        writer.writeheader()
        writer.writerows(results)
        
    print(f"Successfully processed {len(results)} jobs. Files generated: .md and .csv")

if __name__ == "__main__":
    main()
