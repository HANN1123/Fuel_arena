#!/usr/bin/env python3
"""Find models still needing correction."""
import json
import io

d = json.load(open('assets/data/vehicle_catalog_kr_seed.json', 'r', encoding='utf-8'))
out = io.open('tool/uncorrected_models.txt', 'w', encoding='utf-8')

mfr_models = {}
for v in d['variants']:
    mfr = v.get('manufacturer_name', '')
    model = v.get('model_name', '')
    fuel = v.get('fuel_type', '')
    key = (mfr, model, fuel)
    if key not in mfr_models:
        mfr_models[key] = v

out.write("=== Models still needing correction ===\n")
for (mfr, model, fuel), v in sorted(mfr_models.items()):
    trim = v.get('trim_name', '')
    eff = v.get('official_efficiency')
    disp = v.get('displacement_cc')
    dt = v.get('drivetrain', '')
    trans = v.get('transmission', '')
    generic_trim = any(x in trim for x in ['가솔린', '디젤', '전기차', 'LPi', '하이브리드', '플러그인'])
    if eff is None or generic_trim:
        out.write("{} | {} | {} | trim={} | eff={} | disp={} | dt={} | trans={}\n".format(
            mfr, model, fuel, trim, eff, disp, dt, trans))

out.close()
print("Written to tool/uncorrected_models.txt")
