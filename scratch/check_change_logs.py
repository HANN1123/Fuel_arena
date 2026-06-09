import os

for root, dirs, files in os.walk("supabase/migrations"):
    for file in files:
        if file.endswith(".sql"):
            path = os.path.join(root, file)
            with open(path, "r", encoding="utf-8") as f:
                content = f.read()
            if "vehicle_catalog_change_logs" in content:
                print(f"File: {path}")
                lines = content.splitlines()
                for i, line in enumerate(lines):
                    if "vehicle_catalog_change_logs" in line:
                        print(f"  L{i+1}: {line.strip()}")
