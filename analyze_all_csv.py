import csv
import os
import json

files = [
    # RAW (tanpa kalibrasi 3-fase)
    ("Pengujian Teknis (MAD) - RawData.csv", "RAW - Mobile Data"),
    ("Pengujian Teknis (MAD) - RawWIFI.csv", "RAW - WiFi"),
    # NEW (dengan kalibrasi 3-fase)
    ("NEW - Pengujian Teknis (MAD) - NoResyncDataBackground.csv", "NTP+BG - Data, No Resync"),
    ("NEW - Pengujian Teknis (MAD) - NoResyncDataNoBackground.csv", "NTP only - Data, No Resync"),
    ("NEW - Pengujian Teknis (MAD) - NoResyncWifiNoBackground.csv", "NTP only - WiFi, No Resync"),
    ("NEW - Pengujian Teknis (MAD) - NoResyncWifiWithBackground.csv", "NTP+BG - WiFi, No Resync"),
    ("NEW - Pengujian Teknis (MAD) - ResyncWithDataBackground.csv", "NTP+BG+Resync - Data"),
    ("NEW - Pengujian Teknis (MAD) - ResyncWithDataNoBackground.csv", "NTP+Resync - Data, No BG"),
    ("NEW - Pengujian Teknis (MAD) - ResyncWithWifiNoBackground.csv", "NTP+Resync - WiFi, No BG"),
    ("NEW - Pengujian Teknis (MAD) - ResyncWithWifiWithBackground.csv", "NTP+BG+Resync - WiFi"),
]

base_dir = r"d:\SKRIPSI\jam_sync"

results = []

for filename, label in files:
    filepath = os.path.join(base_dir, filename)
    if not os.path.exists(filepath):
        print(f"SKIP: {filename}")
        continue
    
    with open(filepath, 'r', encoding='utf-8') as f:
        reader = csv.reader(f)
        rows = list(reader)
    
    # Parse summary data from rows 2-12 (header area)
    tables = []
    overall_mad = None
    best_mad = None
    worst_mad = None
    
    for row in rows[1:12]:
        # Parse left side tables (table1-10)
        if row[0].startswith('table'):
            try:
                t = {
                    'name': row[0],
                    'mad': float(row[1]),
                    'drift': float(row[2]),
                    'spikes': int(row[3]),
                }
                tables.append(t)
            except:
                pass
        # Parse right side tables (table11-15)
        if len(row) > 5 and row[5].startswith('table'):
            try:
                t = {
                    'name': row[5],
                    'mad': float(row[6]),
                    'drift': float(row[7]),
                    'spikes': int(row[8]),
                }
                tables.append(t)
            except:
                pass
        # Parse HASIL
        if len(row) > 12:
            if row[11] == 'MAD:':
                try: overall_mad = float(row[12])
                except: pass
            if row[11] == 'BEST:':
                try: best_mad = float(row[12])
                except: pass
            if row[11] == 'WORST:':
                try: worst_mad = float(row[12])
                except: pass
    
    # Calculate stats
    mads = [t['mad'] for t in tables]
    spikes_list = [t['spikes'] for t in tables]
    drifts = [t['drift'] for t in tables]
    
    # Count tables meeting threshold
    under_30 = sum(1 for m in mads if m <= 30)
    under_20 = sum(1 for m in mads if m <= 20)
    under_15 = sum(1 for m in mads if m <= 15)
    under_10 = sum(1 for m in mads if m <= 10)
    
    total_spikes = sum(spikes_list)
    tables_with_spikes = sum(1 for s in spikes_list if s > 0)
    
    # Median
    sorted_mads = sorted(mads)
    n = len(sorted_mads)
    if n % 2 == 0:
        median = (sorted_mads[n//2 - 1] + sorted_mads[n//2]) / 2
    else:
        median = sorted_mads[n//2]
    
    # Std dev
    mean = sum(mads) / len(mads)
    variance = sum((m - mean)**2 for m in mads) / len(mads)
    std = variance ** 0.5
    
    result = {
        'label': label,
        'filename': filename,
        'overall_mad': overall_mad or round(mean, 2),
        'best': best_mad or min(mads),
        'worst': worst_mad or max(mads),
        'median': round(median, 2),
        'std': round(std, 2),
        'under_30': under_30,
        'under_20': under_20,
        'under_15': under_15,
        'under_10': under_10,
        'total_tables': len(tables),
        'total_spikes': total_spikes,
        'tables_with_spikes': tables_with_spikes,
        'avg_drift': round(sum(abs(d) for d in drifts) / len(drifts), 4),
        'per_table': [(t['name'], t['mad'], t['spikes'], t['drift']) for t in tables],
    }
    results.append(result)

# Output
output = []
output.append("=" * 120)
output.append("ANALISIS KOMPREHENSIF - 10 FILE CSV PENGUJIAN TEKNIS (MAD)")
output.append("=" * 120)

# Group by network type
raw_data = [r for r in results if 'RAW' in r['label'] and 'Data' in r['label']]
raw_wifi = [r for r in results if 'RAW' in r['label'] and 'WiFi' in r['label']]
ntp_data = [r for r in results if 'RAW' not in r['label'] and ('Data' in r['label'] or 'data' in r['label'].lower())]
ntp_wifi = [r for r in results if 'RAW' not in r['label'] and ('WiFi' in r['label'] or 'wifi' in r['label'].lower())]

output.append("")
output.append("RINGKASAN PER FILE:")
output.append("-" * 120)
output.append(f"{'Label':<35} {'Mean MAD':>10} {'Median':>8} {'Best':>8} {'Worst':>8} {'StdDev':>8} {'<=30ms':>7} {'<=20ms':>7} {'<=10ms':>7} {'Spikes':>7}")
output.append("-" * 120)

for r in results:
    n = r['total_tables']
    output.append(
        f"{r['label']:<35} "
        f"{r['overall_mad']:>10.2f} "
        f"{r['median']:>8.2f} "
        f"{r['best']:>8.2f} "
        f"{r['worst']:>8.2f} "
        f"{r['std']:>8.2f} "
        f"{r['under_30']:>3}/{n:<3} "
        f"{r['under_20']:>3}/{n:<3} "
        f"{r['under_10']:>3}/{n:<3} "
        f"{r['total_spikes']:>7}"
    )

output.append("")
output.append("=" * 120)
output.append("PERBANDINGAN GRUP:")
output.append("=" * 120)

# Group comparisons
groups = {
    'RAW Mobile Data': raw_data,
    'RAW WiFi': raw_wifi,
    'NTP-based Mobile Data': ntp_data,
    'NTP-based WiFi': ntp_wifi,
}

for group_name, group_results in groups.items():
    if not group_results:
        continue
    all_mads = []
    for r in group_results:
        all_mads.extend([t[1] for t in r['per_table']])
    
    if all_mads:
        output.append(f"\n--- {group_name} ({len(group_results)} file, {len(all_mads)} tables total) ---")
        output.append(f"  Grand Mean MAD:    {sum(all_mads)/len(all_mads):.2f} ms")
        output.append(f"  Grand Median MAD:  {sorted(all_mads)[len(all_mads)//2]:.2f} ms")
        output.append(f"  Range:             {min(all_mads):.2f} - {max(all_mads):.2f} ms")
        output.append(f"  Tables <= 30ms:    {sum(1 for m in all_mads if m <= 30)}/{len(all_mads)} ({100*sum(1 for m in all_mads if m <= 30)/len(all_mads):.1f}%)")
        output.append(f"  Tables <= 20ms:    {sum(1 for m in all_mads if m <= 20)}/{len(all_mads)} ({100*sum(1 for m in all_mads if m <= 20)/len(all_mads):.1f}%)")
        output.append(f"  Tables <= 10ms:    {sum(1 for m in all_mads if m <= 10)}/{len(all_mads)} ({100*sum(1 for m in all_mads if m <= 10)/len(all_mads):.1f}%)")

output.append("")
output.append("=" * 120)
output.append("DETAIL PER TABLE - SEMUA FILE:")
output.append("=" * 120)

for r in results:
    output.append(f"\n--- {r['label']} ({r['filename']}) ---")
    output.append(f"  {'Table':<10} {'MAD':>8} {'Spikes':>8} {'Drift':>10} {'Status':<15}")
    output.append(f"  {'-'*60}")
    for name, mad, spikes, drift in r['per_table']:
        status = "OK" if mad <= 30 else "OVER 30ms"
        if spikes > 0:
            status += f" (SPIKE:{spikes})"
        output.append(f"  {name:<10} {mad:>8.2f} {spikes:>8} {drift:>10.2f} {status:<15}")

output.append("")
output.append("=" * 120)
output.append("ANALISIS HEAD-TO-HEAD: RAW vs NTP (Mobile Data)")
output.append("=" * 120)

if raw_data and ntp_data:
    raw_all = []
    for r in raw_data:
        raw_all.extend([t[1] for t in r['per_table']])
    ntp_all = []
    for r in ntp_data:
        ntp_all.extend([t[1] for t in r['per_table']])
    
    output.append(f"\n  RAW Mobile Data:    Mean={sum(raw_all)/len(raw_all):.2f}ms, Median={sorted(raw_all)[len(raw_all)//2]:.2f}ms, n={len(raw_all)}")
    output.append(f"  NTP Mobile Data:    Mean={sum(ntp_all)/len(ntp_all):.2f}ms, Median={sorted(ntp_all)[len(ntp_all)//2]:.2f}ms, n={len(ntp_all)}")
    output.append(f"  Perbaikan Mean:     {sum(raw_all)/len(raw_all) - sum(ntp_all)/len(ntp_all):.2f}ms")
    output.append(f"  RAW <=30ms:         {sum(1 for m in raw_all if m <= 30)}/{len(raw_all)} ({100*sum(1 for m in raw_all if m <= 30)/len(raw_all):.1f}%)")
    output.append(f"  NTP <=30ms:         {sum(1 for m in ntp_all if m <= 30)}/{len(ntp_all)} ({100*sum(1 for m in ntp_all if m <= 30)/len(ntp_all):.1f}%)")

output.append("")
output.append("=" * 120)
output.append("ANALISIS HEAD-TO-HEAD: RAW vs NTP (WiFi)")
output.append("=" * 120)

if raw_wifi and ntp_wifi:
    raw_all = []
    for r in raw_wifi:
        raw_all.extend([t[1] for t in r['per_table']])
    ntp_all = []
    for r in ntp_wifi:
        ntp_all.extend([t[1] for t in r['per_table']])
    
    output.append(f"\n  RAW WiFi:           Mean={sum(raw_all)/len(raw_all):.2f}ms, Median={sorted(raw_all)[len(raw_all)//2]:.2f}ms, n={len(raw_all)}")
    output.append(f"  NTP WiFi:           Mean={sum(ntp_all)/len(ntp_all):.2f}ms, Median={sorted(ntp_all)[len(ntp_all)//2]:.2f}ms, n={len(ntp_all)}")
    output.append(f"  Perbaikan Mean:     {sum(raw_all)/len(raw_all) - sum(ntp_all)/len(ntp_all):.2f}ms")
    output.append(f"  RAW <=30ms:         {sum(1 for m in raw_all if m <= 30)}/{len(raw_all)} ({100*sum(1 for m in raw_all if m <= 30)/len(raw_all):.1f}%)")
    output.append(f"  NTP <=30ms:         {sum(1 for m in ntp_all if m <= 30)}/{len(ntp_all)} ({100*sum(1 for m in ntp_all if m <= 30)/len(ntp_all):.1f}%)")

# Impact of Background Calibration
output.append("")
output.append("=" * 120)
output.append("ANALISIS DAMPAK BACKGROUND CALIBRATION (Mobile Data, No Resync)")
output.append("=" * 120)

bg_data = [r for r in results if r['label'] == "NTP+BG - Data, No Resync"]
no_bg_data = [r for r in results if r['label'] == "NTP only - Data, No Resync"]

if bg_data and no_bg_data:
    bg_mads = [t[1] for t in bg_data[0]['per_table']]
    nobg_mads = [t[1] for t in no_bg_data[0]['per_table']]
    output.append(f"\n  Dengan BG Cal:      Mean={sum(bg_mads)/len(bg_mads):.2f}ms, Median={sorted(bg_mads)[len(bg_mads)//2]:.2f}ms")
    output.append(f"  Tanpa BG Cal:       Mean={sum(nobg_mads)/len(nobg_mads):.2f}ms, Median={sorted(nobg_mads)[len(nobg_mads)//2]:.2f}ms")
    output.append(f"  Selisih Mean:       {sum(nobg_mads)/len(nobg_mads) - sum(bg_mads)/len(bg_mads):.2f}ms")

# Impact of Resync
output.append("")
output.append("=" * 120)
output.append("ANALISIS DAMPAK RESYNC (Mobile Data)")
output.append("=" * 120)

resync_data = [r for r in results if 'Resync' in r['label'] and 'Data' in r['label']]
noresync_data = [r for r in results if 'No Resync' in r['label'] and 'Data' in r['label']]

if resync_data and noresync_data:
    resync_mads = []
    for r in resync_data:
        resync_mads.extend([t[1] for t in r['per_table']])
    noresync_mads = []
    for r in noresync_data:
        noresync_mads.extend([t[1] for t in r['per_table']])
    
    output.append(f"\n  Dengan Resync:      Mean={sum(resync_mads)/len(resync_mads):.2f}ms, n={len(resync_mads)}")
    output.append(f"  Tanpa Resync:       Mean={sum(noresync_mads)/len(noresync_mads):.2f}ms, n={len(noresync_mads)}")
    output.append(f"  Selisih:            {sum(noresync_mads)/len(noresync_mads) - sum(resync_mads)/len(resync_mads):.2f}ms")

result_text = "\n".join(output)
print(result_text)

with open(os.path.join(base_dir, "analysis_output.txt"), 'w', encoding='utf-8') as f:
    f.write(result_text)

print("\n\nOutput saved to analysis_output.txt")
