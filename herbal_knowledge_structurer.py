import json
import os
import openai
from striprtf.striprtf import rtf_to_text
from collections import OrderedDict

# --- CONFIG ---
JSON_PATH = 'Herba2/Resources/herbal_knowledge.json'
RTF_PATH = 'Herba2/Resources/-The-Complete-Collection-of-Barbara-ONeill-Lost.rtf'
OUTPUT_PATH = 'Herba2/Resources/herbal_knowledge_structured.json'

# --- PROMPT TEMPLATE ---
PROMPT_TEMPLATE = '''
Restructure the following herbal remedy entry into a JSON object with these fields:
- name
- synonyms (array)
- properties (array)
- uses (array)
- preparationMethods (array)
- cautions (array)
- tags (array)
- conditionsTreated (array)
- evidenceLevel (string: 'high', 'moderate', 'low')
- sourceReferences (array of URLs or citations)

Here is the entry:
{entry}
'''

# --- GET OPENAI API KEY ---
def get_api_key():
    import getpass
    return getpass.getpass('Enter your OpenAI API key: ')

# --- LOAD JSON REMEDIES ---
def load_json_remedies(path):
    with open(path, 'r') as f:
        data = json.load(f)
    remedies = []
    # Try to extract remedies from both dict and list structures
    if isinstance(data, dict):
        for k, v in data.items():
            if isinstance(v, dict) or isinstance(v, list):
                remedies.append({k: v})
    elif isinstance(data, list):
        remedies = data
    return remedies

# --- LOAD RTF REMEDIES ---
def load_rtf_remedies(path):
    with open(path, 'r') as f:
        rtf_content = f.read()
    text = rtf_to_text(rtf_content)
    # Naive split: assume remedies are separated by double newlines or similar
    entries = [e.strip() for e in text.split('\n\n') if len(e.strip()) > 30]
    return entries

# --- DEDUPLICATE BY NAME ---
def deduplicate_remedies(remedies):
    seen = OrderedDict()
    for entry in remedies:
        # Try to get the name (first key or 'name' field)
        if isinstance(entry, dict):
            if 'name' in entry:
                name = entry['name']
            else:
                name = list(entry.keys())[0]
        else:
            # For plain text, use first line as name
            name = entry.split('\n')[0].strip()
        key = name.lower()
        if key not in seen:
            seen[key] = entry
    return list(seen.values())

# --- ENRICH WITH OPENAI ---
def enrich_remedy(entry, api_key):
    openai.api_key = api_key
    prompt = PROMPT_TEMPLATE.format(entry=json.dumps(entry, ensure_ascii=False, indent=2) if isinstance(entry, dict) else entry)
    try:
        response = openai.chat.completions.create(
            model="gpt-4",
            messages=[{"role": "user", "content": prompt}]
        )
        content = response.choices[0].message.content
        # Try to parse JSON from response
        return json.loads(content)
    except Exception as e:
        print(f"Error enriching remedy: {e}\nPrompt was:\n{prompt}")
        return None

# --- MAIN ---
def main():
    api_key = get_api_key()
    print('Loading remedies from JSON...')
    json_remedies = load_json_remedies(JSON_PATH)
    print(f'Loaded {len(json_remedies)} remedies from JSON.')
    print('Loading remedies from RTF...')
    rtf_remedies = load_rtf_remedies(RTF_PATH)
    print(f'Loaded {len(rtf_remedies)} entries from RTF.')
    all_entries = json_remedies + rtf_remedies
    print('Deduplicating remedies...')
    unique_entries = deduplicate_remedies(all_entries)
    print(f'{len(unique_entries)} unique remedies to process.')
    structured = []
    for i, entry in enumerate(unique_entries):
        print(f'[{i+1}/{len(unique_entries)}] Enriching remedy: {str(entry)[:60]}...')
        enriched = enrich_remedy(entry, api_key)
        if enriched:
            structured.append(enriched)
    print(f'Saving {len(structured)} structured remedies to {OUTPUT_PATH}')
    with open(OUTPUT_PATH, 'w') as f:
        json.dump(structured, f, indent=2, ensure_ascii=False)
    print('Done!')

if __name__ == '__main__':
    main() 