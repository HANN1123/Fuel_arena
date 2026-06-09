import json
import re
import os

def main():
    json_path = "assets/data/vehicle_catalog_kr_seed.json"
    repo_path = "lib/shared/repositories/fuel_arena_repositories.dart"

    print("Loading JSON seed...")
    with open(json_path, "r", encoding="utf-8") as f:
        seed_data = json.load(f)

    # Manufacturers: include all 22
    manufacturers = seed_data.get("manufacturers", [])
    manufacturers_map = {m["id"]: m for m in manufacturers}

    # Fallback models names we want to target
    fallback_model_names = [
        "아반떼", "쏘나타", "그랜저", "코나", "투싼", "싼타페", "팰리세이드", "캐스퍼", "아이오닉 5", "아이오닉 6",
        "K5", "스포티지", "EV6",
        "Model 3", "Model Y",
        "프리우스", "캠리"
    ]

    # Find the models matching these names
    all_models = seed_data.get("models", [])
    fallback_models = []
    fallback_model_ids = set()
    
    for mname in fallback_model_names:
        matched = [m for m in all_models if m["name_ko"] == mname or m["name_en"] == mname]
        if matched:
            # Add all matches (just in case there are multiple, usually one)
            for m in matched:
                fallback_models.append(m)
                fallback_model_ids.add(m["id"])
        else:
            print(f"Warning: Fallback model '{mname}' not found in JSON seed.")

    # Find the latest year for each fallback model
    all_years = seed_data.get("years", [])
    fallback_years = []
    fallback_year_ids = set()
    model_to_latest_year = {}

    for y in all_years:
        mid = y["model_id"]
        if mid in fallback_model_ids:
            year_val = y["year"]
            if mid not in model_to_latest_year or year_val > model_to_latest_year[mid]["year"]:
                model_to_latest_year[mid] = y

    for mid, y in model_to_latest_year.items():
        fallback_years.append(y)
        fallback_year_ids.add(y["id"])

    # Find variants matching the fallback years
    all_variants = seed_data.get("variants", [])
    fallback_variants = []
    for v in all_variants:
        if v["model_year_id"] in fallback_year_ids:
            fallback_variants.append(v)

    print(f"Selected: {len(manufacturers)} manufacturers, {len(fallback_models)} models, {len(fallback_years)} years, {len(fallback_variants)} variants.")

    # Generate Dart code blocks
    m_code = []
    for m in manufacturers:
        is_popular_str = "true" if m.get("is_popular", False) else "false"
        m_code.append(
            f"  VehicleManufacturer(\n"
            f"      id: '{m['id']}',\n"
            f"      nameKo: '{m['name_ko']}',\n"
            f"      nameEn: '{m['name_en']}',\n"
            f"      country: '{m['country']}',\n"
            f"      isPopular: {is_popular_str},\n"
            f"      sortOrder: {m['sort_order']})"
        )

    model_code = []
    # Sort models by manufacturer and sortOrder to look neat
    fallback_models.sort(key=lambda x: (x["manufacturer_id"], x["sort_order"]))
    for m in fallback_models:
        is_popular_str = "true" if m.get("is_popular", False) else "false"
        fuels_str = ", ".join(f"'{f}'" for f in m.get("available_fuel_types", []))
        model_code.append(
            f"  VehicleModel(\n"
            f"      id: '{m['id']}',\n"
            f"      manufacturerId: '{m['manufacturer_id']}',\n"
            f"      nameKo: '{m['name_ko']}',\n"
            f"      nameEn: '{m['name_en']}',\n"
            f"      bodyType: '{m['body_type']}',\n"
            f"      availableFuelTypes: [{fuels_str}],\n"
            f"      isPopular: {is_popular_str},\n"
            f"      sortOrder: {m['sort_order']})"
        )

    year_code = []
    fallback_years.sort(key=lambda x: (x["model_id"], -x["year"]))
    for y in fallback_years:
        year_code.append(
            f"  VehicleModelYear(\n"
            f"      id: '{y['id']}',\n"
            f"      modelId: '{y['model_id']}',\n"
            f"      year: {y['year']})"
        )

    variant_code = []
    fallback_variants.sort(key=lambda x: (x["model_year_id"], x.get("sort_order", 0)))
    for v in fallback_variants:
        disp_cc = v.get("displacement_cc")
        disp_cc_str = str(disp_cc) if disp_cc is not None else "null"
        
        bat_kwh = v.get("battery_kwh")
        bat_kwh_str = str(bat_kwh) if bat_kwh is not None else "null"
        
        eff = v.get("official_efficiency")
        eff_str = str(eff) if eff is not None else "null"

        is_verified_str = "true" if v.get("is_verified", True) else "false"
        sort_order_str = str(v.get("sort_order", 0))

        variant_code.append(
            f"  VehicleVariant(\n"
            f"      id: '{v['id']}',\n"
            f"      modelYearId: '{v['model_year_id']}',\n"
            f"      manufacturerName: '{v['manufacturer_name']}',\n"
            f"      modelName: '{v['model_name']}',\n"
            f"      year: {v['year']},\n"
            f"      trimName: '{v['trim_name']}',\n"
            f"      engineName: '{v['engine_name']}',\n"
            f"      fuelType: '{v['fuel_type']}',\n"
            f"      displacementCc: {disp_cc_str},\n"
            f"      batteryKwh: {bat_kwh_str},\n"
            f"      drivetrain: '{v['drivetrain']}',\n"
            f"      transmission: '{v['transmission']}',\n"
            f"      officialEfficiency: {eff_str},\n"
            f"      efficiencyUnit: '{v['efficiency_unit']}',\n"
            f"      vehicleClass: '{v['vehicle_class']}',\n"
            f"      fuelLeague: '{v['fuel_league']}',\n"
            f"      isVerified: {is_verified_str},\n"
            f"      sortOrder: {sort_order_str})"
        )

    print("Reading repository file...")
    with open(repo_path, "r", encoding="utf-8") as f:
        repo_content = f.read()

    patterns = {
        "manufacturers": (r"(const _catalogManufacturers = \[\s*)(.*?)(\s*\];)", m_code),
        "models": (r"(const _catalogModels = \[\s*)(.*?)(\s*\];)", model_code),
        "years": (r"(const _catalogYears = \[\s*)(.*?)(\s*\];)", year_code),
        "variants": (r"(const _catalogVariants = \[\s*)(.*?)(\s*\];)", variant_code)
    }

    new_content = repo_content
    for key, (pattern, code_list) in patterns.items():
        match = re.search(pattern, new_content, re.DOTALL)
        if not match:
            print(f"Error: Could not find block for {key}")
            continue

        prefix, block_content, suffix = match.groups()
        new_block = prefix + ",\n".join(code_list) + "\n" + suffix
        new_content = new_content.replace(match.group(0), new_block)

    print("Writing updated content to repositories file...")
    with open(repo_path, "w", encoding="utf-8", newline="\n") as f:
        f.write(new_content)

    print("Fallback constants updated successfully!")

if __name__ == "__main__":
    main()
