import json

f = 'Herba2/Resources/herbal_knowledge_enhanced.json'
with open(f, 'r', encoding='utf-8') as infile:
    data = json.load(infile)

for entry in data:
    if entry.get('name') in ['Chamomile', 'Echinacea', 'Ginger', 'Turmeric', 'Garlic'] and not entry.get('category'):
        entry['category'] = 'herb'

with open(f, 'w', encoding='utf-8') as outfile:
    json.dump(data, outfile, ensure_ascii=False, indent=2) 