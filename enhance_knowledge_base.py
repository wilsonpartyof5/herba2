import json
import openai
import getpass
import uuid
from datetime import datetime
import re
import os

# --- CONFIG ---
INPUT_PATH = 'Herba2/Resources/herbal_knowledge_categorized.json'
OUTPUT_PATH = 'Herba2/Resources/herbal_knowledge_enhanced.json'
TEMP_PATH = 'Herba2/Resources/herbal_knowledge_enhanced_temp.json'

# --- PROMPT TEMPLATES ---
ENHANCE_TEMPLATE = '''
Enhance this remedy entry with additional information. The entry is categorized as {category}.

For all entries, ensure:
1. At least 3 tags
2. At least 2 uses
3. Evidence level (high/moderate/low)
4. Source references
5. Cross-references to related remedies

For herbs, also add:
- Plant family
- Parts used
- Growing information
- Harvesting information
- Active constituents
- Dosage information (adult/children/elderly)
- Shelf life
- Storage instructions
- Interactions with medications

For essential oils, also add:
- Extraction method
- Dilution ratios
- Carrier oil recommendations
- Safety precautions
- Shelf life
- Storage instructions

For minerals, also add:
- Chemical composition
- Purity requirements
- Sourcing information
- Dosage information
- Shelf life
- Storage instructions

For common knowledge, also add:
- Historical context
- Cultural significance
- Modern applications

Here is the entry:
{entry}

Return a JSON object with all the enhanced information. Keep the original structure and add the new fields.
'''

def get_api_key():
    return getpass.getpass('Enter your OpenAI API key: ')

def generate_id(name):
    if isinstance(name, list):
        name = ', '.join([str(n) for n in name])
    base = re.sub(r'[^a-zA-Z0-9]', '', str(name).lower())
    return f"{base[:8]}-{str(uuid.uuid4())[:8]}"

def enhance_entry(entry, category, api_key):
    openai.api_key = api_key
    prompt = ENHANCE_TEMPLATE.format(
        category=category,
        entry=json.dumps(entry, ensure_ascii=False, indent=2)
    )
    try:
        response = openai.chat.completions.create(
            model="gpt-4",
            messages=[{"role": "user", "content": prompt}]
        )
        content = response.choices[0].message.content
        try:
            enhanced = json.loads(content)
        except Exception as e:
            print(f"Error parsing JSON for entry: {entry.get('name', 'Unnamed')}. Skipping. Error: {e}")
            return None
        # Add metadata
        enhanced.update({
            "id": generate_id(enhanced.get("name", "unknown")),
            "lastUpdated": datetime.now().isoformat(),
            "version": "1.0",
            "crossReferences": [],
            "userRatings": {
                "average": 0,
                "count": 0,
                "reviews": []
            },
            "appSpecific": {
                "preparationDifficulty": "medium",
                "costIndicator": "medium",
                "availabilityRating": "medium",
                "relatedRemedies": [],
                "alternativeRemedies": []
            }
        })
        return enhanced
    except Exception as e:
        print(f"Error enhancing entry: {e}")
        return None

def find_related_remedies(enhanced_entries):
    for entry in enhanced_entries:
        entry['crossReferences'] = []
        entry['appSpecific']['relatedRemedies'] = []
        entry['appSpecific']['alternativeRemedies'] = []
        entry_tags = set(str(tag) for tag in entry.get('tags', []))
        entry_uses = set(str(use) for use in entry.get('uses', []))
        entry_conditions = set(str(condition) for condition in entry.get('conditionsTreated', []))
        for other in enhanced_entries:
            if other['id'] == entry['id']:
                continue
            other_tags = set(str(tag) for tag in other.get('tags', []))
            other_uses = set(str(use) for use in other.get('uses', []))
            other_conditions = set(str(condition) for condition in other.get('conditionsTreated', []))
            tag_similarity = len(entry_tags & other_tags) / len(entry_tags | other_tags) if entry_tags and other_tags else 0
            use_similarity = len(entry_uses & other_uses) / len(entry_uses | other_uses) if entry_uses and other_uses else 0
            condition_similarity = len(entry_conditions & other_conditions) / len(entry_conditions | other_conditions) if entry_conditions and other_conditions else 0
            similarity = (tag_similarity + use_similarity + condition_similarity) / 3
            if similarity > 0.3:
                entry['crossReferences'].append({
                    'id': other['id'],
                    'name': other['name'],
                    'category': other['category'],
                    'similarity': similarity
                })
                if similarity > 0.5:
                    entry['appSpecific']['relatedRemedies'].append(other['id'])
                elif similarity > 0.3:
                    entry['appSpecific']['alternativeRemedies'].append(other['id'])

def load_progress():
    if os.path.exists(TEMP_PATH):
        with open(TEMP_PATH, 'r') as f:
            return json.load(f)
    return []

def save_progress(enhanced_remedies):
    with open(TEMP_PATH, 'w') as f:
        json.dump(enhanced_remedies, f, indent=2, ensure_ascii=False)

def main():
    with open(INPUT_PATH, 'r') as f:
        remedies = json.load(f)
    print(f'Loaded {len(remedies)} remedies.')
    enhanced_remedies = load_progress()
    processed_names = set()
    for r in enhanced_remedies:
        name = r.get('name', 'Unnamed')
        if isinstance(name, list):
            name = ', '.join([str(n) for n in name])
        processed_names.add(name)
    print(f'Found {len(enhanced_remedies)} previously processed remedies.')
    api_key = get_api_key()
    for i, remedy in enumerate(remedies):
        if not isinstance(remedy, dict):
            continue
        name = remedy.get('name', 'Unnamed')
        if isinstance(name, list):
            name = ', '.join([str(n) for n in name])
        if name in processed_names:
            print(f'Skipping already processed remedy: {name}')
            continue
        category = remedy.get('category', 'unknown')
        print(f'Processing remedy {i+1}/{len(remedies)}: {name} ({category})')
        enhanced = enhance_entry(remedy, category, api_key)
        if enhanced:
            enhanced_remedies.append(enhanced)
            save_progress(enhanced_remedies)
    print('Finding related remedies...')
    find_related_remedies(enhanced_remedies)
    print(f'Saving {len(enhanced_remedies)} enhanced remedies...')
    with open(OUTPUT_PATH, 'w') as f:
        json.dump(enhanced_remedies, f, indent=2, ensure_ascii=False)
    if os.path.exists(TEMP_PATH):
        os.remove(TEMP_PATH)
    print('Done!')

if __name__ == '__main__':
    main() 