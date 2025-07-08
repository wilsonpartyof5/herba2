import json
import openai
import getpass

# --- CONFIG ---
INPUT_PATH = 'Herba2/Resources/herbal_knowledge_structured.json'
OUTPUT_PATH = 'Herba2/Resources/herbal_knowledge_categorized.json'

# --- PROMPT TEMPLATE ---
PROMPT_TEMPLATE = '''
Analyze this remedy entry and categorize it into one of these categories:
- herb (for plant-based remedies)
- mineral (for mineral-based remedies)
- essential_oil (for essential oils)
- common_knowledge (for general information about herbalism, categories, or non-specific entries)

Also, clean up the structure by:
1. Removing empty arrays
2. Ensuring consistent formatting
3. Adding relevant tags based on the content

Here is the entry:
{entry}

Return a JSON object with the same structure plus a "category" field.
'''

def get_api_key():
    return getpass.getpass('Enter your OpenAI API key: ')

def get_remedy_name(remedy):
    if isinstance(remedy, dict):
        return remedy.get("name", "Unnamed")
    elif isinstance(remedy, list) and len(remedy) > 0:
        if isinstance(remedy[0], dict):
            return remedy[0].get("name", "Unnamed")
    return "Unnamed"

def process_entry(entry, api_key):
    openai.api_key = api_key
    prompt = PROMPT_TEMPLATE.format(entry=json.dumps(entry, ensure_ascii=False, indent=2))
    try:
        response = openai.chat.completions.create(
            model="gpt-4",
            messages=[{"role": "user", "content": prompt}]
        )
        content = response.choices[0].message.content
        return json.loads(content)
    except Exception as e:
        print(f"Error processing entry: {e}")
        return None

def main():
    # Load the structured remedies
    with open(INPUT_PATH, 'r') as f:
        remedies = json.load(f)
    
    print(f'Loaded {len(remedies)} remedies.')
    
    # Get API key
    api_key = get_api_key()
    
    # Process each remedy
    categorized_remedies = []
    for i, remedy in enumerate(remedies):
        name = get_remedy_name(remedy)
        print(f'Processing remedy {i+1}/{len(remedies)}: {name}')
        categorized = process_entry(remedy, api_key)
        if categorized:
            categorized_remedies.append(categorized)
    
    # Save the categorized remedies
    print(f'Saving {len(categorized_remedies)} categorized remedies...')
    with open(OUTPUT_PATH, 'w') as f:
        json.dump(categorized_remedies, f, indent=2, ensure_ascii=False)
    print('Done!')

if __name__ == '__main__':
    main() 