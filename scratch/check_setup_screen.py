with open("lib/features/vehicle/presentation/vehicle_setup_screen.dart", "r", encoding="utf-8") as f:
    lines = f.readlines()

for i, line in enumerate(lines):
    if "VehicleVariant" in line or "trimName" in line or "officialEfficiency" in line or "efficiencyUnit" in line or "variant" in line.lower():
        # print line index and content
        print(f"L{i+1}: {line.strip()}")
