import json

def load_json_file(file_path):
    try:
        with open(file_path, 'r') as f:
            return json.load(f)
    except FileNotFoundError:
        print(f"Error: {file_path} not found")
        return None
    except json.JSONDecodeError:
        print(f"Error: {file_path} contains invalid JSON")
        return None

def extract_names(remedies):
    names = set()
    for r in remedies:
        if isinstance(r, dict):
            names.add(str(r.get('name', 'Unnamed')))
        elif isinstance(r, list):
            for item in r:
                if isinstance(item, dict):
                    names.add(str(item.get('name', 'Unnamed')))
    return names

def check_completion():
    # Load files
    input_remedies = load_json_file('Herba2/Resources/herbal_knowledge_categorized.json')
    temp_remedies = load_json_file('Herba2/Resources/herbal_knowledge_enhanced_temp.json')
    
    if not input_remedies:
        return
    
    # Get sets of remedy names
    input_names = extract_names(input_remedies)
    temp_names = extract_names(temp_remedies) if temp_remedies else set()
    
    # Find missing remedies
    missing_remedies = input_names - temp_names
    
    # Print results
    print(f"\nTotal input remedies: {len(input_names)}")
    print(f"Total processed remedies: {len(temp_names)}")
    print(f"Missing remedies: {len(missing_remedies)}")
    
    if missing_remedies:
        print("\nMissing remedies:")
        for name in sorted(missing_remedies):
            print(f"- {name}")
    else:
        print("\nAll remedies have been processed!")

if __name__ == '__main__':
    check_completion() 