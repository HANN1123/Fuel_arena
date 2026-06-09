#!/usr/bin/env python3
"""Second pass corrections for remaining uncorrected models."""
import json
import io

INPUT_PATH = "assets/data/vehicle_catalog_kr_seed.json"
OUTPUT_PATH = "assets/data/vehicle_catalog_kr_seed.json"

# Additional corrections for models missed in first pass
ADDITIONAL_CORRECTIONS = {
    # (manufacturer, model, fuel_type) -> corrections
    ("BMW", "4시리즈", "디젤"): {"displacement_cc": 1995, "drivetrain": "RWD", "transmission": "자동 8단",
                              "trim_name": "420d 그란쿠페", "official_efficiency": 16.5, "efficiency_unit": "km/L"},
    ("BMW", "7시리즈", "플러그인 하이브리드"): {"displacement_cc": 2998, "drivetrain": "AWD", "transmission": "자동 8단",
                                       "trim_name": "750e xDrive", "official_efficiency": 12.5, "efficiency_unit": "km/L"},

    # KG모빌리티
    ("KG모빌리티", "렉스턴 스포츠", "디젤"): {"displacement_cc": 2157, "drivetrain": "AWD", "transmission": "자동 6단",
                                       "trim_name": "2.2 디젤 4WD", "official_efficiency": 10.0, "efficiency_unit": "km/L"},

    # MINI
    ("MINI", "컨버터블", "가솔린"): {"displacement_cc": 1499, "drivetrain": "FWD", "transmission": "자동 7단 DCT",
                              "trim_name": "Cooper 컨버터블", "official_efficiency": 13.5, "efficiency_unit": "km/L"},
    ("MINI", "쿠퍼 SE", "전기차"): {"battery_kwh": 54.2, "drivetrain": "FWD", "transmission": "감속기",
                              "trim_name": "Cooper SE", "official_efficiency": 5.8, "efficiency_unit": "km/kWh"},
    ("MINI", "클럽맨", "가솔린"): {"displacement_cc": 1499, "drivetrain": "FWD", "transmission": "자동 7단 DCT",
                             "trim_name": "Cooper 클럽맨", "official_efficiency": 13.0, "efficiency_unit": "km/L"},

    # 닛산
    ("닛산", "로그", "가솔린"): {"displacement_cc": 1497, "drivetrain": "FWD", "transmission": "CVT",
                          "trim_name": "1.5 터보 CVT", "official_efficiency": 12.0, "efficiency_unit": "km/L"},
    ("닛산", "아리야", "전기차"): {"battery_kwh": 87.0, "drivetrain": "AWD", "transmission": "감속기",
                           "trim_name": "e-4ORCE", "official_efficiency": 4.5, "efficiency_unit": "km/kWh"},

    # 랜드로버
    ("랜드로버", "디펜더", "플러그인 하이브리드"): {"displacement_cc": 1997, "drivetrain": "AWD", "transmission": "자동 8단",
                                       "trim_name": "P400e PHEV", "official_efficiency": 10.0, "efficiency_unit": "km/L"},
    ("랜드로버", "레인지로버 이보크", "가솔린"): {"displacement_cc": 1997, "drivetrain": "AWD", "transmission": "자동 9단",
                                       "trim_name": "P250", "official_efficiency": 10.5, "efficiency_unit": "km/L"},
    ("랜드로버", "레인지로버 이보크", "디젤"): {"displacement_cc": 1999, "drivetrain": "AWD", "transmission": "자동 9단",
                                      "trim_name": "D200", "official_efficiency": 13.5, "efficiency_unit": "km/L"},

    # 르노코리아
    ("르노코리아", "XM3", "하이브리드"): {"displacement_cc": 1598, "drivetrain": "FWD", "transmission": "자동",
                                  "trim_name": "E-TECH 하이브리드", "official_efficiency": 17.0, "efficiency_unit": "km/L"},
    ("르노코리아", "그랑 콜레오스", "가솔린"): {"displacement_cc": 1998, "drivetrain": "FWD", "transmission": "CVT",
                                      "trim_name": "2.0 가솔린 TCe", "official_efficiency": 11.0, "efficiency_unit": "km/L"},
    ("르노코리아", "그랑 콜레오스", "하이브리드"): {"displacement_cc": 1598, "drivetrain": "FWD", "transmission": "자동",
                                        "trim_name": "E-TECH 하이브리드", "official_efficiency": 15.5, "efficiency_unit": "km/L"},

    # 메르세데스-벤츠 GLA
    ("메르세데스-벤츠", "GLA", "가솔린"): {"displacement_cc": 1332, "drivetrain": "FWD", "transmission": "자동 7단 DCT",
                                   "trim_name": "GLA 200", "official_efficiency": 13.5, "efficiency_unit": "km/L"},

    # 볼보 C40
    ("볼보", "C40", "전기차"): {"battery_kwh": 78.0, "drivetrain": "AWD", "transmission": "감속기",
                           "trim_name": "Recharge Twin", "official_efficiency": 4.5, "efficiency_unit": "km/kWh"},

    # 쉐보레
    ("쉐보레", "말리부", "가솔린"): {"displacement_cc": 1998, "drivetrain": "FWD", "transmission": "자동 9단",
                             "trim_name": "2.0 터보", "official_efficiency": 11.5, "efficiency_unit": "km/L"},
    ("쉐보레", "스파크", "가솔린"): {"displacement_cc": 998, "drivetrain": "FWD", "transmission": "CVT",
                             "trim_name": "1.0", "official_efficiency": 15.0, "efficiency_unit": "km/L"},
    ("쉐보레", "트랙스", "가솔린"): {"displacement_cc": 1332, "drivetrain": "FWD", "transmission": "자동 6단",
                             "trim_name": "1.3 터보", "official_efficiency": 13.0, "efficiency_unit": "km/L"},

    # 아우디 추가
    ("아우디", "A5", "디젤"): {"displacement_cc": 1968, "drivetrain": "FWD", "transmission": "자동 7단 S tronic",
                          "trim_name": "35 TDI 스포트백", "official_efficiency": 16.5, "efficiency_unit": "km/L"},
    ("아우디", "A6", "플러그인 하이브리드"): {"displacement_cc": 1984, "drivetrain": "AWD", "transmission": "자동 7단 S tronic",
                                    "trim_name": "55 TFSI e quattro", "official_efficiency": 13.0, "efficiency_unit": "km/L"},
    ("아우디", "A7", "디젤"): {"displacement_cc": 2967, "drivetrain": "AWD", "transmission": "자동 8단 tiptronic",
                          "trim_name": "45 TDI quattro", "official_efficiency": 13.5, "efficiency_unit": "km/L"},
    ("아우디", "Q5", "플러그인 하이브리드"): {"displacement_cc": 1984, "drivetrain": "AWD", "transmission": "자동 7단 S tronic",
                                    "trim_name": "55 TFSI e quattro", "official_efficiency": 12.5, "efficiency_unit": "km/L"},
    ("아우디", "Q8", "디젤"): {"displacement_cc": 2967, "drivetrain": "AWD", "transmission": "자동 8단 tiptronic",
                          "trim_name": "50 TDI quattro", "official_efficiency": 11.0, "efficiency_unit": "km/L"},
    ("아우디", "e-tron", "전기차"): {"battery_kwh": 95.0, "drivetrain": "AWD", "transmission": "감속기",
                              "trim_name": "55 quattro", "official_efficiency": 4.0, "efficiency_unit": "km/kWh"},

    # 지프
    ("지프", "체로키", "가솔린"): {"displacement_cc": 1995, "drivetrain": "AWD", "transmission": "자동 9단",
                           "trim_name": "2.0 터보 4WD", "official_efficiency": 9.5, "efficiency_unit": "km/L"},

    # 토요타 추가
    ("토요타", "라브4", "플러그인 하이브리드"): {"displacement_cc": 2487, "drivetrain": "AWD", "transmission": "e-CVT",
                                      "trim_name": "프라임 PHEV", "official_efficiency": 17.5, "efficiency_unit": "km/L"},
    ("토요타", "라브4", "하이브리드"): {"displacement_cc": 2487, "drivetrain": "AWD", "transmission": "e-CVT",
                               "trim_name": "2.5 하이브리드 AWD", "official_efficiency": 16.5, "efficiency_unit": "km/L"},
    ("토요타", "시에나", "하이브리드"): {"displacement_cc": 2487, "drivetrain": "AWD", "transmission": "e-CVT",
                              "trim_name": "2.5 하이브리드 AWD", "official_efficiency": 14.5, "efficiency_unit": "km/L"},
    ("토요타", "크라운", "하이브리드"): {"displacement_cc": 2487, "drivetrain": "AWD", "transmission": "e-CVT",
                              "trim_name": "2.5 하이브리드 AWD", "official_efficiency": 15.0, "efficiency_unit": "km/L"},

    # 포르쉐 추가
    ("포르쉐", "박스터", "가솔린"): {"displacement_cc": 2687, "drivetrain": "RWD", "transmission": "PDK 7단",
                             "trim_name": "718 박스터", "official_efficiency": 10.5, "efficiency_unit": "km/L"},
    ("포르쉐", "카이맨", "가솔린"): {"displacement_cc": 2687, "drivetrain": "RWD", "transmission": "PDK 7단",
                             "trim_name": "718 카이맨", "official_efficiency": 10.8, "efficiency_unit": "km/L"},

    # 폭스바겐 추가
    ("폭스바겐", "아테온", "디젤"): {"displacement_cc": 1968, "drivetrain": "FWD", "transmission": "자동 7단 DSG",
                             "trim_name": "2.0 TDI", "official_efficiency": 16.0, "efficiency_unit": "km/L"},
    ("폭스바겐", "제타", "가솔린"): {"displacement_cc": 1498, "drivetrain": "FWD", "transmission": "자동 7단 DSG",
                             "trim_name": "1.5 TSI", "official_efficiency": 14.5, "efficiency_unit": "km/L"},
    ("폭스바겐", "투아렉", "디젤"): {"displacement_cc": 2967, "drivetrain": "AWD", "transmission": "자동 8단",
                             "trim_name": "3.0 V6 TDI 4MOTION", "official_efficiency": 11.5, "efficiency_unit": "km/L"},
    ("폭스바겐", "파사트", "가솔린"): {"displacement_cc": 1984, "drivetrain": "FWD", "transmission": "자동 7단 DSG",
                              "trim_name": "2.0 TSI", "official_efficiency": 12.5, "efficiency_unit": "km/L"},
    ("폭스바겐", "파사트", "디젤"): {"displacement_cc": 1968, "drivetrain": "FWD", "transmission": "자동 7단 DSG",
                             "trim_name": "2.0 TDI", "official_efficiency": 16.5, "efficiency_unit": "km/L"},

    # 푸조 추가
    ("푸조", "2008", "가솔린"): {"displacement_cc": 1199, "drivetrain": "FWD", "transmission": "자동 8단",
                            "trim_name": "1.2 PureTech", "official_efficiency": 14.5, "efficiency_unit": "km/L"},
    ("푸조", "2008", "전기차"): {"battery_kwh": 50.0, "drivetrain": "FWD", "transmission": "감속기",
                            "trim_name": "e-2008", "official_efficiency": 5.8, "efficiency_unit": "km/kWh"},
    ("푸조", "3008", "디젤"): {"displacement_cc": 1499, "drivetrain": "FWD", "transmission": "자동 8단",
                           "trim_name": "1.5 BlueHDi", "official_efficiency": 18.0, "efficiency_unit": "km/L"},
    ("푸조", "308", "디젤"): {"displacement_cc": 1499, "drivetrain": "FWD", "transmission": "자동 8단",
                          "trim_name": "1.5 BlueHDi", "official_efficiency": 19.0, "efficiency_unit": "km/L"},
    ("푸조", "5008", "디젤"): {"displacement_cc": 1499, "drivetrain": "FWD", "transmission": "자동 8단",
                           "trim_name": "1.5 BlueHDi", "official_efficiency": 17.0, "efficiency_unit": "km/L"},

    # 현대 아반떼 스포츠
    ("현대", "아반떼 스포츠", "가솔린"): {"official_efficiency": 11.8, "efficiency_unit": "km/L"},

    # 혼다 추가
    ("혼다", "HR-V", "가솔린"): {"displacement_cc": 1498, "drivetrain": "FWD", "transmission": "CVT",
                            "trim_name": "1.5 터보 CVT", "official_efficiency": 13.5, "efficiency_unit": "km/L"},
    ("혼다", "오딧세이", "가솔린"): {"displacement_cc": 2356, "drivetrain": "FWD", "transmission": "자동 10단",
                            "trim_name": "2.4 가솔린", "official_efficiency": 10.0, "efficiency_unit": "km/L"},
    ("혼다", "파일럿", "가솔린"): {"displacement_cc": 3471, "drivetrain": "AWD", "transmission": "자동 10단",
                           "trim_name": "3.5 V6 AWD", "official_efficiency": 8.5, "efficiency_unit": "km/L"},
}

# EV trim name cleanup - replace generic "전기차" trim with model-specific names
EV_TRIM_NAMES = {
    ("기아", "EV3"): "EV3 스탠다드",
    ("기아", "EV6"): "EV6 스탠다드",
    ("기아", "EV9"): "EV9 스탠다드",
    ("기아", "니로", "전기차"): "니로 EV",
    ("기아", "봉고", "전기차"): "봉고 일렉트릭",
    ("기아", "레이", "전기차"): "레이 EV",
    ("현대", "아이오닉 5"): "아이오닉 5 스탠다드",
    ("현대", "아이오닉 6"): "아이오닉 6 스탠다드",
    ("현대", "코나", "전기차"): "코나 일렉트릭",
    ("현대", "포터", "전기차"): "포터 일렉트릭",
}


def main():
    print("Loading catalog...")
    with open(INPUT_PATH, "r", encoding="utf-8") as f:
        data = json.load(f)

    variants = data.get("variants", [])
    corrected = 0
    ev_trimmed = 0

    for v in variants:
        mfr = v.get("manufacturer_name", "")
        model = v.get("model_name", "")
        fuel = v.get("fuel_type", "")

        key = (mfr, model, fuel)
        if key in ADDITIONAL_CORRECTIONS:
            corrections = ADDITIONAL_CORRECTIONS[key]
            for k, val in corrections.items():
                if k == "official_efficiency" and v.get(k) is not None:
                    continue
                v[k] = val
            corrected += 1

        # Fix generic EV trim names
        if fuel == "전기차" and v.get("trim_name") == "전기차":
            ev_key = (mfr, model, fuel)
            ev_key2 = (mfr, model)
            if ev_key in EV_TRIM_NAMES:
                v["trim_name"] = EV_TRIM_NAMES[ev_key]
                ev_trimmed += 1
            elif ev_key2 in EV_TRIM_NAMES:
                v["trim_name"] = EV_TRIM_NAMES[ev_key2]
                ev_trimmed += 1

    from datetime import datetime
    data["generated_at"] = datetime.utcnow().isoformat() + "Z"

    print("2nd pass: corrected {} variants, fixed {} EV trims".format(corrected, ev_trimmed))

    with io.open(OUTPUT_PATH, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

    # Stats
    has_eff = sum(1 for v in variants if v.get("official_efficiency") is not None)
    print("Efficiency coverage: {} / {} ({:.1f}%)".format(
        has_eff, len(variants), 100 * has_eff / max(len(variants), 1)))

    # Remaining None efficiency
    none_eff = [v for v in variants if v.get("official_efficiency") is None]
    print("Still missing efficiency: {} variants".format(len(none_eff)))
    seen = set()
    for v in none_eff:
        key = (v.get("manufacturer_name"), v.get("model_name"), v.get("fuel_type"))
        if key not in seen:
            seen.add(key)
            print("  {} {} {}".format(*key))

if __name__ == "__main__":
    main()
