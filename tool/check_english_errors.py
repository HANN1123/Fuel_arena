import os
import re

dart_dir = "lib"

# Patterns: throw Exception('...'), throw StateError('...'), throw ArgumentError('...'), etc.
error_patterns = [
    re.compile(r'throw\s+\w+(?:Error|Exception)\(\s*["\']([^"\']+)["\']'),
    re.compile(r'StateError\(\s*["\']([^"\']+)["\']'),
    re.compile(r'ArgumentError\(\s*["\']([^"\']+)["\']'),
    re.compile(r'UnsupportedError\(\s*["\']([^"\']+)["\']'),
    re.compile(r'Exception\(\s*["\']([^"\']+)["\']'),
]

results = []

def has_korean(text):
    return any(0xac00 <= ord(char) <= 0xd7a3 for char in text)

for root, dirs, files in os.walk(dart_dir):
    for file in files:
        if file.endswith(".dart"):
            file_path = os.path.join(root, file)
            with open(file_path, "r", encoding="utf-8") as f:
                lines = f.readlines()
            
            for idx, line in enumerate(lines):
                for pattern in error_patterns:
                    matches = pattern.findall(line)
                    for m in matches:
                        if not has_korean(m):
                            results.append((file_path, idx + 1, line.strip(), m))

for filepath, line_num, line_content, text in results:
    print(f"{filepath} L{line_num}: {line_content}  --> [{text}]")
