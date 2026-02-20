import re

# Parse log data
client1_data = {}  # logSequence -> currentPosition
client2_data = {}

raw = open('output_export_log.txt', 'r').read()

# Find client sections
sections = raw.split('----------')
# sections[1] = CLIENT 1 header, sections[2] = CLIENT 1 data + CLIENT 2 header, etc.

current_client = None
for line in raw.split('\n'):
    line = line.strip()
    if 'CLIENT 1' in line:
        current_client = 1
        continue
    elif 'CLIENT 2' in line:
        current_client = 2
        continue
    elif 'EXPORT DONE' in line:
        break
    
    # Parse data lines: |logSequence|currentPosition|serverTimeOffset|rawOffset|
    match = re.search(r'\|(\d+)\|(\d+)\|(-?\d+)\|(-?\d+)\|', line)
    if match and current_client:
        seq = int(match.group(1))
        pos = int(match.group(2))
        offset = int(match.group(3))
        raw_offset = int(match.group(4))
        
        data = {'position': pos, 'sequence': seq, 'offset': offset, 'rawOffset': raw_offset}
        
        if current_client == 1:
            client1_data[seq] = data
        else:
            client2_data[seq] = data

print(f"Client 1: {len(client1_data)} entries, offset={list(client1_data.values())[0]['offset']}ms")
print(f"Client 2: {len(client2_data)} entries, offset={list(client2_data.values())[0]['offset']}ms")
print(f"Offset difference: {abs(list(client1_data.values())[0]['offset'] - list(client2_data.values())[0]['offset'])}ms")
print()

# Pair by logSequence and calculate MAD
common_sequences = sorted(set(client1_data.keys()) & set(client2_data.keys()))
print(f"Common logSequence entries: {len(common_sequences)}")
print()

# Calculate MAD
deviations = []
print(f"{'Seq':>4} | {'C1 Pos':>8} | {'C2 Pos':>8} | {'Mean':>10} | {'Dev C1':>8} | {'Dev C2':>8} | {'MAD':>6}")
print("-" * 75)

for seq in common_sequences:
    c1_pos = client1_data[seq]['position']
    c2_pos = client2_data[seq]['position']
    mean_pos = (c1_pos + c2_pos) / 2
    dev_c1 = abs(c1_pos - mean_pos)
    dev_c2 = abs(c2_pos - mean_pos)
    mad = (dev_c1 + dev_c2) / 2  # same as dev_c1 or dev_c2 for 2 clients
    deviations.append(mad)
    print(f"{seq:>4} | {c1_pos:>8} | {c2_pos:>8} | {mean_pos:>10.1f} | {dev_c1:>8.1f} | {dev_c2:>8.1f} | {mad:>6.1f}")

print("-" * 75)
overall_mad = sum(deviations) / len(deviations)
print(f"\nOverall MAD: {overall_mad:.2f}ms")
print(f"Min deviation: {min(deviations):.1f}ms")
print(f"Max deviation: {max(deviations):.1f}ms")
print(f"% samples <= 30ms: {sum(1 for d in deviations if d <= 30) / len(deviations) * 100:.1f}%")
print(f"% samples <= 50ms: {sum(1 for d in deviations if d <= 50) / len(deviations) * 100:.1f}%")

# Check for duplicate sequences
print("\n\n========== DUPLICATE SEQUENCE ANALYSIS ==========")
for name, data in [("Client 1", client1_data), ("Client 2", client2_data)]:
    entries = sorted(data.values(), key=lambda x: x['sequence'])
    prev_seq = -1
    dupes = []
    for e in entries:
        if e['sequence'] == prev_seq:
            dupes.append(e)
        prev_seq = e['sequence']
    print(f"{name}: {len(dupes)} duplicate sequences found")
