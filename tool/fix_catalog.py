#!/usr/bin/env python3
"""
Fuel Arena 차량 카탈로그 데이터 교정 스크립트.

각 제조사별 실제 차량 정보를 기반으로:
- 배기량(displacement_cc)
- 구동방식(drivetrain)
- 변속기(transmission)
- 배터리 용량(battery_kwh)
- 공인연비(official_efficiency)
- 효율 단위(efficiency_unit)
- 트림명(trim_name)
을 교정합니다.
"""
import json
import copy
import io

INPUT_PATH = "assets/data/vehicle_catalog_kr_seed.json"
OUTPUT_PATH = "assets/data/vehicle_catalog_kr_seed.json"

# ──────────────────────────────────────────────
# 제조사별 실제 모델 스펙 사전
# key: (manufacturer_name, model_name, fuel_type) 또는 (manufacturer_name, model_name)
# value: dict of corrections
# ──────────────────────────────────────────────

# BMW corrections
BMW_MODEL_SPECS = {
    # model_name -> {fuel_type -> {corrections}}
    "1시리즈": {
        "가솔린": {"displacement_cc": 1499, "drivetrain": "FWD", "transmission": "자동 7단 DCT",
                 "trim_name": "118i", "official_efficiency": 14.1, "efficiency_unit": "km/L"},
    },
    "2시리즈": {
        "가솔린": {"displacement_cc": 1998, "drivetrain": "RWD", "transmission": "자동 8단",
                 "trim_name": "220i 쿠페", "official_efficiency": 13.5, "efficiency_unit": "km/L"},
    },
    "3시리즈": {
        "가솔린": {"displacement_cc": 1998, "drivetrain": "RWD", "transmission": "자동 8단",
                 "trim_name": "320i", "official_efficiency": 12.8, "efficiency_unit": "km/L"},
        "디젤": {"displacement_cc": 1995, "drivetrain": "RWD", "transmission": "자동 8단",
                "trim_name": "320d", "official_efficiency": 16.8, "efficiency_unit": "km/L"},
        "플러그인 하이브리드": {"displacement_cc": 1998, "drivetrain": "RWD", "transmission": "자동 8단",
                        "trim_name": "330e", "official_efficiency": 16.0, "efficiency_unit": "km/L"},
    },
    "4시리즈": {
        "가솔린": {"displacement_cc": 1998, "drivetrain": "RWD", "transmission": "자동 8단",
                 "trim_name": "420i 그란쿠페", "official_efficiency": 12.5, "efficiency_unit": "km/L"},
    },
    "5시리즈": {
        "가솔린": {"displacement_cc": 1998, "drivetrain": "RWD", "transmission": "자동 8단",
                 "trim_name": "520i", "official_efficiency": 12.3, "efficiency_unit": "km/L"},
        "디젤": {"displacement_cc": 1995, "drivetrain": "RWD", "transmission": "자동 8단",
                "trim_name": "520d", "official_efficiency": 17.2, "efficiency_unit": "km/L"},
        "플러그인 하이브리드": {"displacement_cc": 1998, "drivetrain": "RWD", "transmission": "자동 8단",
                        "trim_name": "530e", "official_efficiency": 15.5, "efficiency_unit": "km/L"},
    },
    "7시리즈": {
        "가솔린": {"displacement_cc": 2998, "drivetrain": "RWD", "transmission": "자동 8단",
                 "trim_name": "740i", "official_efficiency": 10.2, "efficiency_unit": "km/L"},
    },
    "X1": {
        "가솔린": {"displacement_cc": 1499, "drivetrain": "FWD", "transmission": "자동 7단 DCT",
                 "trim_name": "sDrive18i", "official_efficiency": 13.0, "efficiency_unit": "km/L"},
        "디젤": {"displacement_cc": 1995, "drivetrain": "AWD", "transmission": "자동 8단",
                "trim_name": "xDrive18d", "official_efficiency": 16.5, "efficiency_unit": "km/L"},
        "플러그인 하이브리드": {"displacement_cc": 1499, "drivetrain": "AWD", "transmission": "자동 6단",
                        "trim_name": "xDrive25e", "official_efficiency": 14.8, "efficiency_unit": "km/L"},
    },
    "X3": {
        "가솔린": {"displacement_cc": 1998, "drivetrain": "AWD", "transmission": "자동 8단",
                 "trim_name": "xDrive20i", "official_efficiency": 11.5, "efficiency_unit": "km/L"},
        "디젤": {"displacement_cc": 1995, "drivetrain": "AWD", "transmission": "자동 8단",
                "trim_name": "xDrive20d", "official_efficiency": 14.8, "efficiency_unit": "km/L"},
        "플러그인 하이브리드": {"displacement_cc": 1998, "drivetrain": "AWD", "transmission": "자동 8단",
                        "trim_name": "xDrive30e", "official_efficiency": 13.5, "efficiency_unit": "km/L"},
    },
    "X5": {
        "가솔린": {"displacement_cc": 2998, "drivetrain": "AWD", "transmission": "자동 8단",
                 "trim_name": "xDrive40i", "official_efficiency": 9.8, "efficiency_unit": "km/L"},
        "디젤": {"displacement_cc": 2993, "drivetrain": "AWD", "transmission": "자동 8단",
                "trim_name": "xDrive30d", "official_efficiency": 12.5, "efficiency_unit": "km/L"},
        "플러그인 하이브리드": {"displacement_cc": 2998, "drivetrain": "AWD", "transmission": "자동 8단",
                        "trim_name": "xDrive45e", "official_efficiency": 11.0, "efficiency_unit": "km/L"},
    },
    "X7": {
        "가솔린": {"displacement_cc": 2998, "drivetrain": "AWD", "transmission": "자동 8단",
                 "trim_name": "xDrive40i", "official_efficiency": 9.0, "efficiency_unit": "km/L"},
        "디젤": {"displacement_cc": 2993, "drivetrain": "AWD", "transmission": "자동 8단",
                "trim_name": "xDrive30d", "official_efficiency": 11.2, "efficiency_unit": "km/L"},
    },
    "i4": {
        "전기차": {"battery_kwh": 83.9, "drivetrain": "RWD", "transmission": "감속기",
                 "trim_name": "eDrive40", "official_efficiency": 5.9, "efficiency_unit": "km/kWh"},
    },
    "i5": {
        "전기차": {"battery_kwh": 83.9, "drivetrain": "RWD", "transmission": "감속기",
                 "trim_name": "eDrive40", "official_efficiency": 5.5, "efficiency_unit": "km/kWh"},
    },
    "iX": {
        "전기차": {"battery_kwh": 76.6, "drivetrain": "AWD", "transmission": "감속기",
                 "trim_name": "xDrive40", "official_efficiency": 4.8, "efficiency_unit": "km/kWh"},
    },
    "iX3": {
        "전기차": {"battery_kwh": 80.0, "drivetrain": "RWD", "transmission": "감속기",
                 "trim_name": "eDrive", "official_efficiency": 5.0, "efficiency_unit": "km/kWh"},
    },
}

# Porsche corrections
PORSCHE_MODEL_SPECS = {
    "911": {
        "가솔린": {"displacement_cc": 2981, "drivetrain": "RWD", "transmission": "PDK 8단",
                 "trim_name": "카레라", "official_efficiency": 9.2, "efficiency_unit": "km/L"},
    },
    "카이엔": {
        "가솔린": {"displacement_cc": 2995, "drivetrain": "AWD", "transmission": "자동 8단 (팁트로닉)",
                 "trim_name": "카이엔", "official_efficiency": 8.5, "efficiency_unit": "km/L"},
        "플러그인 하이브리드": {"displacement_cc": 2995, "drivetrain": "AWD", "transmission": "자동 8단 (팁트로닉)",
                        "trim_name": "카이엔 E-Hybrid", "official_efficiency": 10.8, "efficiency_unit": "km/L"},
    },
    "마칸": {
        "가솔린": {"displacement_cc": 1984, "drivetrain": "AWD", "transmission": "PDK 7단",
                 "trim_name": "마칸", "official_efficiency": 10.0, "efficiency_unit": "km/L"},
        "전기차": {"battery_kwh": 100.0, "drivetrain": "AWD", "transmission": "감속기",
                 "trim_name": "마칸 Electric", "official_efficiency": 4.5, "efficiency_unit": "km/kWh"},
    },
    "타이칸": {
        "전기차": {"battery_kwh": 93.4, "drivetrain": "AWD", "transmission": "자동 2단",
                 "trim_name": "타이칸 4S", "official_efficiency": 4.3, "efficiency_unit": "km/kWh"},
    },
    "파나메라": {
        "가솔린": {"displacement_cc": 2894, "drivetrain": "RWD", "transmission": "PDK 8단",
                 "trim_name": "파나메라", "official_efficiency": 9.5, "efficiency_unit": "km/L"},
        "플러그인 하이브리드": {"displacement_cc": 2894, "drivetrain": "AWD", "transmission": "PDK 8단",
                        "trim_name": "파나메라 E-Hybrid", "official_efficiency": 11.5, "efficiency_unit": "km/L"},
    },
}

# Mercedes-Benz corrections
BENZ_MODEL_SPECS = {
    "A-Class": {
        "가솔린": {"displacement_cc": 1332, "drivetrain": "FWD", "transmission": "자동 7단 DCT",
                 "trim_name": "A 200", "official_efficiency": 14.5, "efficiency_unit": "km/L"},
        "디젤": {"displacement_cc": 1950, "drivetrain": "FWD", "transmission": "자동 8단 DCT",
                "trim_name": "A 200 d", "official_efficiency": 18.2, "efficiency_unit": "km/L"},
    },
    "C-Class": {
        "가솔린": {"displacement_cc": 1496, "drivetrain": "RWD", "transmission": "자동 9단",
                 "trim_name": "C 200", "official_efficiency": 12.8, "efficiency_unit": "km/L"},
        "디젤": {"displacement_cc": 1993, "drivetrain": "RWD", "transmission": "자동 9단",
                "trim_name": "C 220 d", "official_efficiency": 17.5, "efficiency_unit": "km/L"},
        "플러그인 하이브리드": {"displacement_cc": 1496, "drivetrain": "RWD", "transmission": "자동 9단",
                        "trim_name": "C 300 e", "official_efficiency": 15.0, "efficiency_unit": "km/L"},
    },
    "E-Class": {
        "가솔린": {"displacement_cc": 1999, "drivetrain": "RWD", "transmission": "자동 9단",
                 "trim_name": "E 200", "official_efficiency": 11.5, "efficiency_unit": "km/L"},
        "디젤": {"displacement_cc": 1993, "drivetrain": "RWD", "transmission": "자동 9단",
                "trim_name": "E 220 d", "official_efficiency": 16.2, "efficiency_unit": "km/L"},
        "하이브리드": {"displacement_cc": 1999, "drivetrain": "RWD", "transmission": "자동 9단",
                   "trim_name": "E 300 e", "official_efficiency": 14.5, "efficiency_unit": "km/L"},
        "플러그인 하이브리드": {"displacement_cc": 1999, "drivetrain": "RWD", "transmission": "자동 9단",
                        "trim_name": "E 300 e PHEV", "official_efficiency": 14.5, "efficiency_unit": "km/L"},
    },
    "S-Class": {
        "가솔린": {"displacement_cc": 2999, "drivetrain": "AWD", "transmission": "자동 9단",
                 "trim_name": "S 450 4MATIC", "official_efficiency": 9.8, "efficiency_unit": "km/L"},
        "디젤": {"displacement_cc": 2925, "drivetrain": "AWD", "transmission": "자동 9단",
                "trim_name": "S 350 d 4MATIC", "official_efficiency": 13.0, "efficiency_unit": "km/L"},
        "플러그인 하이브리드": {"displacement_cc": 2999, "drivetrain": "AWD", "transmission": "자동 9단",
                        "trim_name": "S 580 e 4MATIC", "official_efficiency": 12.0, "efficiency_unit": "km/L"},
    },
    "GLC": {
        "가솔린": {"displacement_cc": 1999, "drivetrain": "AWD", "transmission": "자동 9단",
                 "trim_name": "GLC 300 4MATIC", "official_efficiency": 10.5, "efficiency_unit": "km/L"},
        "디젤": {"displacement_cc": 1993, "drivetrain": "AWD", "transmission": "자동 9단",
                "trim_name": "GLC 220 d 4MATIC", "official_efficiency": 14.8, "efficiency_unit": "km/L"},
        "플러그인 하이브리드": {"displacement_cc": 1999, "drivetrain": "AWD", "transmission": "자동 9단",
                        "trim_name": "GLC 300 e 4MATIC", "official_efficiency": 13.0, "efficiency_unit": "km/L"},
    },
    "GLE": {
        "가솔린": {"displacement_cc": 2999, "drivetrain": "AWD", "transmission": "자동 9단",
                 "trim_name": "GLE 450 4MATIC", "official_efficiency": 9.0, "efficiency_unit": "km/L"},
        "디젤": {"displacement_cc": 1993, "drivetrain": "AWD", "transmission": "자동 9단",
                "trim_name": "GLE 300 d 4MATIC", "official_efficiency": 13.5, "efficiency_unit": "km/L"},
        "플러그인 하이브리드": {"displacement_cc": 1999, "drivetrain": "AWD", "transmission": "자동 9단",
                        "trim_name": "GLE 350 de 4MATIC", "official_efficiency": 12.0, "efficiency_unit": "km/L"},
    },
    "GLS": {
        "가솔린": {"displacement_cc": 2999, "drivetrain": "AWD", "transmission": "자동 9단",
                 "trim_name": "GLS 450 4MATIC", "official_efficiency": 8.5, "efficiency_unit": "km/L"},
        "디젤": {"displacement_cc": 2925, "drivetrain": "AWD", "transmission": "자동 9단",
                "trim_name": "GLS 400 d 4MATIC", "official_efficiency": 12.0, "efficiency_unit": "km/L"},
    },
    "EQE": {
        "전기차": {"battery_kwh": 90.6, "drivetrain": "RWD", "transmission": "감속기",
                 "trim_name": "EQE 350+", "official_efficiency": 5.6, "efficiency_unit": "km/kWh"},
    },
    "EQS": {
        "전기차": {"battery_kwh": 107.8, "drivetrain": "RWD", "transmission": "감속기",
                 "trim_name": "EQS 450+", "official_efficiency": 5.2, "efficiency_unit": "km/kWh"},
    },
    "EQA": {
        "전기차": {"battery_kwh": 66.5, "drivetrain": "FWD", "transmission": "감속기",
                 "trim_name": "EQA 250", "official_efficiency": 5.3, "efficiency_unit": "km/kWh"},
    },
    "EQB": {
        "전기차": {"battery_kwh": 66.5, "drivetrain": "FWD", "transmission": "감속기",
                 "trim_name": "EQB 250", "official_efficiency": 5.0, "efficiency_unit": "km/kWh"},
    },
}

# Audi corrections
AUDI_MODEL_SPECS = {
    "A3": {
        "가솔린": {"displacement_cc": 1498, "drivetrain": "FWD", "transmission": "자동 7단 S tronic",
                 "trim_name": "35 TFSI", "official_efficiency": 14.0, "efficiency_unit": "km/L"},
    },
    "A4": {
        "가솔린": {"displacement_cc": 1984, "drivetrain": "FWD", "transmission": "자동 7단 S tronic",
                 "trim_name": "40 TFSI", "official_efficiency": 12.5, "efficiency_unit": "km/L"},
        "디젤": {"displacement_cc": 1968, "drivetrain": "FWD", "transmission": "자동 7단 S tronic",
                "trim_name": "35 TDI", "official_efficiency": 17.0, "efficiency_unit": "km/L"},
    },
    "A5": {
        "가솔린": {"displacement_cc": 1984, "drivetrain": "FWD", "transmission": "자동 7단 S tronic",
                 "trim_name": "40 TFSI 스포트백", "official_efficiency": 12.3, "efficiency_unit": "km/L"},
    },
    "A6": {
        "가솔린": {"displacement_cc": 1984, "drivetrain": "FWD", "transmission": "자동 7단 S tronic",
                 "trim_name": "45 TFSI", "official_efficiency": 11.8, "efficiency_unit": "km/L"},
        "디젤": {"displacement_cc": 1968, "drivetrain": "AWD", "transmission": "자동 8단 tiptronic",
                "trim_name": "40 TDI quattro", "official_efficiency": 15.5, "efficiency_unit": "km/L"},
    },
    "A7": {
        "가솔린": {"displacement_cc": 1984, "drivetrain": "FWD", "transmission": "자동 7단 S tronic",
                 "trim_name": "45 TFSI", "official_efficiency": 11.5, "efficiency_unit": "km/L"},
    },
    "A8": {
        "가솔린": {"displacement_cc": 2995, "drivetrain": "AWD", "transmission": "자동 8단 tiptronic",
                 "trim_name": "55 TFSI quattro", "official_efficiency": 9.5, "efficiency_unit": "km/L"},
    },
    "Q3": {
        "가솔린": {"displacement_cc": 1498, "drivetrain": "FWD", "transmission": "자동 7단 S tronic",
                 "trim_name": "35 TFSI", "official_efficiency": 12.8, "efficiency_unit": "km/L"},
    },
    "Q5": {
        "가솔린": {"displacement_cc": 1984, "drivetrain": "AWD", "transmission": "자동 7단 S tronic",
                 "trim_name": "45 TFSI quattro", "official_efficiency": 10.8, "efficiency_unit": "km/L"},
        "디젤": {"displacement_cc": 1968, "drivetrain": "AWD", "transmission": "자동 8단 tiptronic",
                "trim_name": "40 TDI quattro", "official_efficiency": 14.5, "efficiency_unit": "km/L"},
    },
    "Q7": {
        "가솔린": {"displacement_cc": 2995, "drivetrain": "AWD", "transmission": "자동 8단 tiptronic",
                 "trim_name": "55 TFSI quattro", "official_efficiency": 8.8, "efficiency_unit": "km/L"},
        "디젤": {"displacement_cc": 2967, "drivetrain": "AWD", "transmission": "자동 8단 tiptronic",
                "trim_name": "45 TDI quattro", "official_efficiency": 12.0, "efficiency_unit": "km/L"},
    },
    "Q8": {
        "가솔린": {"displacement_cc": 2995, "drivetrain": "AWD", "transmission": "자동 8단 tiptronic",
                 "trim_name": "55 TFSI quattro", "official_efficiency": 8.5, "efficiency_unit": "km/L"},
    },
    "e-tron GT": {
        "전기차": {"battery_kwh": 93.4, "drivetrain": "AWD", "transmission": "자동 2단",
                 "trim_name": "e-tron GT quattro", "official_efficiency": 4.5, "efficiency_unit": "km/kWh"},
    },
    "Q4 e-tron": {
        "전기차": {"battery_kwh": 82.0, "drivetrain": "RWD", "transmission": "감속기",
                 "trim_name": "Q4 40 e-tron", "official_efficiency": 5.0, "efficiency_unit": "km/kWh"},
    },
    "Q8 e-tron": {
        "전기차": {"battery_kwh": 114.0, "drivetrain": "AWD", "transmission": "감속기",
                 "trim_name": "Q8 55 e-tron quattro", "official_efficiency": 4.2, "efficiency_unit": "km/kWh"},
    },
}

# Tesla corrections
TESLA_MODEL_SPECS = {
    "Model 3": {
        "전기차": {"battery_kwh": 60.0, "drivetrain": "RWD", "transmission": "감속기",
                 "trim_name": "스탠다드 레인지 플러스", "official_efficiency": 6.4, "efficiency_unit": "km/kWh"},
    },
    "Model Y": {
        "전기차": {"battery_kwh": 75.0, "drivetrain": "AWD", "transmission": "감속기",
                 "trim_name": "롱레인지 AWD", "official_efficiency": 5.6, "efficiency_unit": "km/kWh"},
    },
    "Model S": {
        "전기차": {"battery_kwh": 100.0, "drivetrain": "AWD", "transmission": "감속기",
                 "trim_name": "듀얼 모터 AWD", "official_efficiency": 4.8, "efficiency_unit": "km/kWh"},
    },
    "Model X": {
        "전기차": {"battery_kwh": 100.0, "drivetrain": "AWD", "transmission": "감속기",
                 "trim_name": "듀얼 모터 AWD", "official_efficiency": 4.3, "efficiency_unit": "km/kWh"},
    },
}

# Volkswagen corrections
VW_MODEL_SPECS = {
    "골프": {
        "가솔린": {"displacement_cc": 1498, "drivetrain": "FWD", "transmission": "자동 7단 DSG",
                 "trim_name": "1.5 TSI", "official_efficiency": 14.2, "efficiency_unit": "km/L"},
        "디젤": {"displacement_cc": 1968, "drivetrain": "FWD", "transmission": "자동 7단 DSG",
                "trim_name": "2.0 TDI", "official_efficiency": 18.5, "efficiency_unit": "km/L"},
    },
    "티구안": {
        "가솔린": {"displacement_cc": 1984, "drivetrain": "AWD", "transmission": "자동 7단 DSG",
                 "trim_name": "2.0 TSI 4MOTION", "official_efficiency": 10.8, "efficiency_unit": "km/L"},
        "디젤": {"displacement_cc": 1968, "drivetrain": "AWD", "transmission": "자동 7단 DSG",
                "trim_name": "2.0 TDI 4MOTION", "official_efficiency": 14.0, "efficiency_unit": "km/L"},
    },
    "투아렉": {
        "가솔린": {"displacement_cc": 2995, "drivetrain": "AWD", "transmission": "자동 8단",
                 "trim_name": "3.0 V6 TSI 4MOTION", "official_efficiency": 8.8, "efficiency_unit": "km/L"},
    },
    "아테온": {
        "가솔린": {"displacement_cc": 1984, "drivetrain": "FWD", "transmission": "자동 7단 DSG",
                 "trim_name": "2.0 TSI", "official_efficiency": 11.5, "efficiency_unit": "km/L"},
    },
    "ID.4": {
        "전기차": {"battery_kwh": 82.0, "drivetrain": "RWD", "transmission": "감속기",
                 "trim_name": "Pro S", "official_efficiency": 5.0, "efficiency_unit": "km/kWh"},
    },
}

# Volvo corrections
VOLVO_MODEL_SPECS = {
    "S60": {
        "가솔린": {"displacement_cc": 1969, "drivetrain": "FWD", "transmission": "자동 8단",
                 "trim_name": "B5", "official_efficiency": 11.0, "efficiency_unit": "km/L"},
        "플러그인 하이브리드": {"displacement_cc": 1969, "drivetrain": "AWD", "transmission": "자동 8단",
                        "trim_name": "T8 Recharge", "official_efficiency": 13.5, "efficiency_unit": "km/L"},
    },
    "S90": {
        "가솔린": {"displacement_cc": 1969, "drivetrain": "FWD", "transmission": "자동 8단",
                 "trim_name": "B5", "official_efficiency": 10.5, "efficiency_unit": "km/L"},
        "플러그인 하이브리드": {"displacement_cc": 1969, "drivetrain": "AWD", "transmission": "자동 8단",
                        "trim_name": "T8 Recharge", "official_efficiency": 12.8, "efficiency_unit": "km/L"},
    },
    "XC40": {
        "가솔린": {"displacement_cc": 1969, "drivetrain": "FWD", "transmission": "자동 8단",
                 "trim_name": "B4", "official_efficiency": 11.5, "efficiency_unit": "km/L"},
        "전기차": {"battery_kwh": 78.0, "drivetrain": "AWD", "transmission": "감속기",
                 "trim_name": "Recharge Pure Electric", "official_efficiency": 4.6, "efficiency_unit": "km/kWh"},
        "플러그인 하이브리드": {"displacement_cc": 1477, "drivetrain": "FWD", "transmission": "자동 7단 DCT",
                        "trim_name": "T5 Recharge", "official_efficiency": 13.0, "efficiency_unit": "km/L"},
    },
    "XC60": {
        "가솔린": {"displacement_cc": 1969, "drivetrain": "AWD", "transmission": "자동 8단",
                 "trim_name": "B5 AWD", "official_efficiency": 10.0, "efficiency_unit": "km/L"},
        "디젤": {"displacement_cc": 1969, "drivetrain": "AWD", "transmission": "자동 8단",
                "trim_name": "D5 AWD", "official_efficiency": 13.5, "efficiency_unit": "km/L"},
        "플러그인 하이브리드": {"displacement_cc": 1969, "drivetrain": "AWD", "transmission": "자동 8단",
                        "trim_name": "T8 Recharge AWD", "official_efficiency": 12.0, "efficiency_unit": "km/L"},
    },
    "XC90": {
        "가솔린": {"displacement_cc": 1969, "drivetrain": "AWD", "transmission": "자동 8단",
                 "trim_name": "B5 AWD", "official_efficiency": 9.5, "efficiency_unit": "km/L"},
        "플러그인 하이브리드": {"displacement_cc": 1969, "drivetrain": "AWD", "transmission": "자동 8단",
                        "trim_name": "T8 Recharge AWD", "official_efficiency": 11.0, "efficiency_unit": "km/L"},
    },
    "EX30": {
        "전기차": {"battery_kwh": 69.0, "drivetrain": "RWD", "transmission": "감속기",
                 "trim_name": "Single Motor", "official_efficiency": 5.8, "efficiency_unit": "km/kWh"},
    },
    "EX90": {
        "전기차": {"battery_kwh": 111.0, "drivetrain": "AWD", "transmission": "감속기",
                 "trim_name": "Twin Motor", "official_efficiency": 4.2, "efficiency_unit": "km/kWh"},
    },
}

# Toyota corrections
TOYOTA_MODEL_SPECS = {
    "캠리": {
        "가솔린": {"displacement_cc": 2487, "drivetrain": "FWD", "transmission": "자동 8단",
                 "trim_name": "2.5 가솔린", "official_efficiency": 12.5, "efficiency_unit": "km/L"},
        "하이브리드": {"displacement_cc": 2487, "drivetrain": "FWD", "transmission": "e-CVT",
                   "trim_name": "2.5 하이브리드", "official_efficiency": 19.0, "efficiency_unit": "km/L"},
    },
    "RAV4": {
        "가솔린": {"displacement_cc": 2487, "drivetrain": "FWD", "transmission": "자동 8단",
                 "trim_name": "2.5 가솔린", "official_efficiency": 11.5, "efficiency_unit": "km/L"},
        "하이브리드": {"displacement_cc": 2487, "drivetrain": "AWD", "transmission": "e-CVT",
                   "trim_name": "2.5 하이브리드 AWD", "official_efficiency": 16.5, "efficiency_unit": "km/L"},
        "플러그인 하이브리드": {"displacement_cc": 2487, "drivetrain": "AWD", "transmission": "e-CVT",
                        "trim_name": "프라임 PHEV", "official_efficiency": 17.5, "efficiency_unit": "km/L"},
    },
    "하이랜더": {
        "가솔린": {"displacement_cc": 3456, "drivetrain": "FWD", "transmission": "자동 8단",
                 "trim_name": "3.5 가솔린", "official_efficiency": 9.5, "efficiency_unit": "km/L"},
        "하이브리드": {"displacement_cc": 2487, "drivetrain": "AWD", "transmission": "e-CVT",
                   "trim_name": "2.5 하이브리드 AWD", "official_efficiency": 14.0, "efficiency_unit": "km/L"},
    },
    "프리우스": {
        "하이브리드": {"displacement_cc": 1798, "drivetrain": "FWD", "transmission": "e-CVT",
                   "trim_name": "1.8 하이브리드", "official_efficiency": 24.5, "efficiency_unit": "km/L"},
        "플러그인 하이브리드": {"displacement_cc": 1987, "drivetrain": "FWD", "transmission": "e-CVT",
                        "trim_name": "2.0 PHEV", "official_efficiency": 26.0, "efficiency_unit": "km/L"},
    },
    "bZ4X": {
        "전기차": {"battery_kwh": 71.4, "drivetrain": "FWD", "transmission": "감속기",
                 "trim_name": "FWD", "official_efficiency": 5.5, "efficiency_unit": "km/kWh"},
    },
    "GR86": {
        "가솔린": {"displacement_cc": 2387, "drivetrain": "RWD", "transmission": "수동 6단",
                 "trim_name": "2.4 MT", "official_efficiency": 11.5, "efficiency_unit": "km/L"},
    },
}

# Lexus corrections
LEXUS_MODEL_SPECS = {
    "ES": {
        "하이브리드": {"displacement_cc": 2487, "drivetrain": "FWD", "transmission": "e-CVT",
                   "trim_name": "ES 300h", "official_efficiency": 18.5, "efficiency_unit": "km/L"},
        "가솔린": {"displacement_cc": 2487, "drivetrain": "FWD", "transmission": "자동 8단",
                 "trim_name": "ES 250", "official_efficiency": 11.8, "efficiency_unit": "km/L"},
    },
    "NX": {
        "가솔린": {"displacement_cc": 2487, "drivetrain": "FWD", "transmission": "자동 8단",
                 "trim_name": "NX 250", "official_efficiency": 11.0, "efficiency_unit": "km/L"},
        "하이브리드": {"displacement_cc": 2487, "drivetrain": "AWD", "transmission": "e-CVT",
                   "trim_name": "NX 350h AWD", "official_efficiency": 15.5, "efficiency_unit": "km/L"},
        "플러그인 하이브리드": {"displacement_cc": 2487, "drivetrain": "AWD", "transmission": "e-CVT",
                        "trim_name": "NX 450h+ PHEV", "official_efficiency": 16.0, "efficiency_unit": "km/L"},
    },
    "RX": {
        "하이브리드": {"displacement_cc": 2487, "drivetrain": "AWD", "transmission": "e-CVT",
                   "trim_name": "RX 350h AWD", "official_efficiency": 14.0, "efficiency_unit": "km/L"},
        "가솔린": {"displacement_cc": 2393, "drivetrain": "AWD", "transmission": "자동 8단",
                 "trim_name": "RX 350 AWD", "official_efficiency": 10.0, "efficiency_unit": "km/L"},
        "플러그인 하이브리드": {"displacement_cc": 2487, "drivetrain": "AWD", "transmission": "e-CVT",
                        "trim_name": "RX 450h+ PHEV", "official_efficiency": 15.5, "efficiency_unit": "km/L"},
    },
    "LS": {
        "하이브리드": {"displacement_cc": 3456, "drivetrain": "AWD", "transmission": "e-CVT",
                   "trim_name": "LS 500h AWD", "official_efficiency": 12.0, "efficiency_unit": "km/L"},
        "가솔린": {"displacement_cc": 3444, "drivetrain": "RWD", "transmission": "자동 10단",
                 "trim_name": "LS 500", "official_efficiency": 9.5, "efficiency_unit": "km/L"},
    },
    "UX": {
        "하이브리드": {"displacement_cc": 1987, "drivetrain": "FWD", "transmission": "e-CVT",
                   "trim_name": "UX 250h", "official_efficiency": 19.0, "efficiency_unit": "km/L"},
        "전기차": {"battery_kwh": 72.8, "drivetrain": "FWD", "transmission": "감속기",
                 "trim_name": "UX 300e", "official_efficiency": 5.5, "efficiency_unit": "km/kWh"},
    },
    "RZ": {
        "전기차": {"battery_kwh": 71.4, "drivetrain": "AWD", "transmission": "감속기",
                 "trim_name": "RZ 450e", "official_efficiency": 4.8, "efficiency_unit": "km/kWh"},
    },
}

# Honda corrections
HONDA_MODEL_SPECS = {
    "시빅": {
        "가솔린": {"displacement_cc": 1498, "drivetrain": "FWD", "transmission": "CVT",
                 "trim_name": "1.5 터보 CVT", "official_efficiency": 14.5, "efficiency_unit": "km/L"},
        "하이브리드": {"displacement_cc": 1993, "drivetrain": "FWD", "transmission": "e-CVT",
                   "trim_name": "2.0 e:HEV", "official_efficiency": 20.5, "efficiency_unit": "km/L"},
    },
    "어코드": {
        "가솔린": {"displacement_cc": 1498, "drivetrain": "FWD", "transmission": "CVT",
                 "trim_name": "1.5 터보 CVT", "official_efficiency": 13.5, "efficiency_unit": "km/L"},
        "하이브리드": {"displacement_cc": 1993, "drivetrain": "FWD", "transmission": "e-CVT",
                   "trim_name": "2.0 e:HEV", "official_efficiency": 19.0, "efficiency_unit": "km/L"},
    },
    "CR-V": {
        "가솔린": {"displacement_cc": 1498, "drivetrain": "AWD", "transmission": "CVT",
                 "trim_name": "1.5 터보 AWD", "official_efficiency": 12.0, "efficiency_unit": "km/L"},
        "하이브리드": {"displacement_cc": 1993, "drivetrain": "AWD", "transmission": "e-CVT",
                   "trim_name": "2.0 e:HEV AWD", "official_efficiency": 16.5, "efficiency_unit": "km/L"},
    },
    "HR-V": {
        "하이브리드": {"displacement_cc": 1498, "drivetrain": "FWD", "transmission": "e-CVT",
                   "trim_name": "1.5 e:HEV", "official_efficiency": 21.0, "efficiency_unit": "km/L"},
    },
    "e:NY1": {
        "전기차": {"battery_kwh": 68.8, "drivetrain": "FWD", "transmission": "감속기",
                 "trim_name": "e:NY1", "official_efficiency": 5.2, "efficiency_unit": "km/kWh"},
    },
}

# Nissan corrections
NISSAN_MODEL_SPECS = {
    "알티마": {
        "가솔린": {"displacement_cc": 2488, "drivetrain": "FWD", "transmission": "CVT",
                 "trim_name": "2.5 CVT", "official_efficiency": 13.0, "efficiency_unit": "km/L"},
    },
    "맥시마": {
        "가솔린": {"displacement_cc": 3498, "drivetrain": "FWD", "transmission": "CVT",
                 "trim_name": "3.5 V6 CVT", "official_efficiency": 10.5, "efficiency_unit": "km/L"},
    },
    "X-트레일": {
        "가솔린": {"displacement_cc": 1497, "drivetrain": "FWD", "transmission": "CVT",
                 "trim_name": "1.5 터보 CVT", "official_efficiency": 12.8, "efficiency_unit": "km/L"},
        "하이브리드": {"displacement_cc": 1497, "drivetrain": "FWD", "transmission": "e-CVT",
                   "trim_name": "1.5 e-POWER", "official_efficiency": 17.5, "efficiency_unit": "km/L"},
    },
    "쥬크": {
        "가솔린": {"displacement_cc": 999, "drivetrain": "FWD", "transmission": "자동 7단 DCT",
                 "trim_name": "1.0 DIG-T", "official_efficiency": 14.5, "efficiency_unit": "km/L"},
        "하이브리드": {"displacement_cc": 1598, "drivetrain": "FWD", "transmission": "자동",
                   "trim_name": "1.6 하이브리드", "official_efficiency": 18.0, "efficiency_unit": "km/L"},
    },
    "아리아": {
        "전기차": {"battery_kwh": 87.0, "drivetrain": "AWD", "transmission": "감속기",
                 "trim_name": "e-4ORCE", "official_efficiency": 4.5, "efficiency_unit": "km/kWh"},
    },
    "리프": {
        "전기차": {"battery_kwh": 62.0, "drivetrain": "FWD", "transmission": "감속기",
                 "trim_name": "e+", "official_efficiency": 5.8, "efficiency_unit": "km/kWh"},
    },
}

# MINI corrections
MINI_MODEL_SPECS = {
    "해치": {
        "가솔린": {"displacement_cc": 1499, "drivetrain": "FWD", "transmission": "자동 7단 DCT",
                 "trim_name": "Cooper", "official_efficiency": 14.0, "efficiency_unit": "km/L"},
        "전기차": {"battery_kwh": 54.2, "drivetrain": "FWD", "transmission": "감속기",
                 "trim_name": "Cooper SE", "official_efficiency": 5.8, "efficiency_unit": "km/kWh"},
    },
    "컨트리맨": {
        "가솔린": {"displacement_cc": 1499, "drivetrain": "AWD", "transmission": "자동 7단 DCT",
                 "trim_name": "Cooper S ALL4", "official_efficiency": 12.0, "efficiency_unit": "km/L"},
        "전기차": {"battery_kwh": 66.5, "drivetrain": "AWD", "transmission": "감속기",
                 "trim_name": "Countryman SE ALL4", "official_efficiency": 4.8, "efficiency_unit": "km/kWh"},
        "플러그인 하이브리드": {"displacement_cc": 1499, "drivetrain": "AWD", "transmission": "자동 6단",
                        "trim_name": "Cooper SE ALL4 PHEV", "official_efficiency": 14.0, "efficiency_unit": "km/L"},
    },
}

# Peugeot corrections
PEUGEOT_MODEL_SPECS = {
    "208": {
        "가솔린": {"displacement_cc": 1199, "drivetrain": "FWD", "transmission": "자동 8단",
                 "trim_name": "1.2 PureTech", "official_efficiency": 15.5, "efficiency_unit": "km/L"},
        "전기차": {"battery_kwh": 50.0, "drivetrain": "FWD", "transmission": "감속기",
                 "trim_name": "e-208", "official_efficiency": 6.0, "efficiency_unit": "km/kWh"},
    },
    "308": {
        "가솔린": {"displacement_cc": 1199, "drivetrain": "FWD", "transmission": "자동 8단",
                 "trim_name": "1.2 PureTech", "official_efficiency": 14.8, "efficiency_unit": "km/L"},
        "플러그인 하이브리드": {"displacement_cc": 1598, "drivetrain": "FWD", "transmission": "자동 8단",
                        "trim_name": "Hybrid 225", "official_efficiency": 16.0, "efficiency_unit": "km/L"},
    },
    "3008": {
        "가솔린": {"displacement_cc": 1199, "drivetrain": "FWD", "transmission": "자동 8단",
                 "trim_name": "1.2 PureTech", "official_efficiency": 13.5, "efficiency_unit": "km/L"},
        "플러그인 하이브리드": {"displacement_cc": 1598, "drivetrain": "FWD", "transmission": "자동 8단",
                        "trim_name": "Hybrid 225", "official_efficiency": 15.0, "efficiency_unit": "km/L"},
        "전기차": {"battery_kwh": 73.0, "drivetrain": "FWD", "transmission": "감속기",
                 "trim_name": "E-3008", "official_efficiency": 5.0, "efficiency_unit": "km/kWh"},
    },
    "5008": {
        "가솔린": {"displacement_cc": 1199, "drivetrain": "FWD", "transmission": "자동 8단",
                 "trim_name": "1.2 PureTech", "official_efficiency": 12.5, "efficiency_unit": "km/L"},
        "플러그인 하이브리드": {"displacement_cc": 1598, "drivetrain": "FWD", "transmission": "자동 8단",
                        "trim_name": "Hybrid 225", "official_efficiency": 14.0, "efficiency_unit": "km/L"},
    },
}

# Polestar corrections
POLESTAR_MODEL_SPECS = {
    "Polestar 2": {
        "전기차": {"battery_kwh": 82.0, "drivetrain": "RWD", "transmission": "감속기",
                 "trim_name": "Long Range Single Motor", "official_efficiency": 5.8, "efficiency_unit": "km/kWh"},
    },
    "Polestar 3": {
        "전기차": {"battery_kwh": 111.0, "drivetrain": "AWD", "transmission": "감속기",
                 "trim_name": "Long Range Dual Motor", "official_efficiency": 4.3, "efficiency_unit": "km/kWh"},
    },
    "Polestar 4": {
        "전기차": {"battery_kwh": 100.0, "drivetrain": "AWD", "transmission": "감속기",
                 "trim_name": "Long Range Dual Motor", "official_efficiency": 4.8, "efficiency_unit": "km/kWh"},
    },
}

# Hyundai corrections (supplement efficiency for models missing it)
HYUNDAI_EFFICIENCY_SUPPLEMENT = {
    ("코나", "가솔린"): {"official_efficiency": 14.3, "efficiency_unit": "km/L"},
    ("코나", "하이브리드"): {"official_efficiency": 20.2, "efficiency_unit": "km/L"},
    ("코나", "전기차"): {"official_efficiency": 5.6, "efficiency_unit": "km/kWh", "battery_kwh": 64.8},
    ("투싼", "가솔린"): {"official_efficiency": 12.0, "efficiency_unit": "km/L"},
    ("투싼", "디젤"): {"official_efficiency": 15.2, "efficiency_unit": "km/L", "displacement_cc": 1998},
    ("투싼", "하이브리드"): {"official_efficiency": 16.2, "efficiency_unit": "km/L"},
    ("투싼", "플러그인 하이브리드"): {"official_efficiency": 17.0, "efficiency_unit": "km/L"},
    ("팰리세이드", "가솔린"): {"official_efficiency": 9.6, "efficiency_unit": "km/L"},
    ("팰리세이드", "디젤"): {"official_efficiency": 12.1, "efficiency_unit": "km/L", "displacement_cc": 2199},
    ("아이오닉 5", "전기차"): {"official_efficiency": 5.2, "efficiency_unit": "km/kWh", "battery_kwh": 77.4},
    ("아이오닉 6", "전기차"): {"official_efficiency": 6.2, "efficiency_unit": "km/kWh", "battery_kwh": 77.4},
    ("스타리아", "가솔린"): {"official_efficiency": 9.0, "efficiency_unit": "km/L"},
    ("스타리아", "디젤"): {"official_efficiency": 11.5, "efficiency_unit": "km/L"},
    ("스타리아", "LPG"): {"official_efficiency": 7.0, "efficiency_unit": "km/L"},
    ("포터", "디젤"): {"official_efficiency": 10.5, "efficiency_unit": "km/L"},
    ("포터", "전기차"): {"official_efficiency": 3.5, "efficiency_unit": "km/kWh", "battery_kwh": 76.1},
    ("쏘나타", "LPG"): {"official_efficiency": 8.8, "efficiency_unit": "km/L"},
}

# Kia corrections (supplement efficiency for models missing it)
KIA_EFFICIENCY_SUPPLEMENT = {
    ("K5", "가솔린"): {"official_efficiency": 13.0, "efficiency_unit": "km/L"},
    ("K5", "하이브리드"): {"official_efficiency": 19.5, "efficiency_unit": "km/L"},
    ("K5", "LPG"): {"official_efficiency": 9.0, "efficiency_unit": "km/L"},
    ("K8", "가솔린"): {"official_efficiency": 10.8, "efficiency_unit": "km/L"},
    ("K8", "하이브리드"): {"official_efficiency": 17.5, "efficiency_unit": "km/L"},
    ("K8", "LPG"): {"official_efficiency": 8.0, "efficiency_unit": "km/L"},
    ("K9", "가솔린"): {"official_efficiency": 9.5, "efficiency_unit": "km/L", "displacement_cc": 3342},
    ("니로", "하이브리드"): {"official_efficiency": 20.8, "efficiency_unit": "km/L"},
    ("니로", "전기차"): {"official_efficiency": 5.3, "efficiency_unit": "km/kWh", "battery_kwh": 64.8},
    ("니로", "플러그인 하이브리드"): {"official_efficiency": 17.5, "efficiency_unit": "km/L"},
    ("카니발", "가솔린"): {"official_efficiency": 8.8, "efficiency_unit": "km/L"},
    ("카니발", "디젤"): {"official_efficiency": 11.5, "efficiency_unit": "km/L", "displacement_cc": 2199},
    ("카니발", "하이브리드"): {"official_efficiency": 14.5, "efficiency_unit": "km/L"},
    ("EV3", "전기차"): {"official_efficiency": 5.8, "efficiency_unit": "km/kWh", "battery_kwh": 81.4},
    ("EV6", "전기차"): {"official_efficiency": 5.0, "efficiency_unit": "km/kWh", "battery_kwh": 77.4},
    ("EV9", "전기차"): {"official_efficiency": 4.2, "efficiency_unit": "km/kWh", "battery_kwh": 99.8},
    ("봉고", "디젤"): {"official_efficiency": 10.0, "efficiency_unit": "km/L"},
    ("봉고", "전기차"): {"official_efficiency": 3.0, "efficiency_unit": "km/kWh", "battery_kwh": 68.0},
    ("봉고", "LPG"): {"official_efficiency": 7.5, "efficiency_unit": "km/L"},
}

# Genesis corrections
GENESIS_MODEL_SPECS = {
    "G70": {
        "가솔린": {"displacement_cc": 1998, "drivetrain": "RWD", "transmission": "자동 8단",
                 "trim_name": "2.0T", "official_efficiency": 11.5, "efficiency_unit": "km/L"},
    },
    "G80": {
        "가솔린": {"displacement_cc": 2497, "drivetrain": "RWD", "transmission": "자동 8단",
                 "trim_name": "2.5T", "official_efficiency": 10.5, "efficiency_unit": "km/L"},
        "디젤": {"displacement_cc": 2199, "drivetrain": "RWD", "transmission": "자동 8단",
                "trim_name": "2.2D", "official_efficiency": 13.5, "efficiency_unit": "km/L"},
        "전기차": {"battery_kwh": 87.2, "drivetrain": "AWD", "transmission": "감속기",
                 "trim_name": "전동화 모델 AWD", "official_efficiency": 4.3, "efficiency_unit": "km/kWh"},
    },
    "G90": {
        "가솔린": {"displacement_cc": 3470, "drivetrain": "AWD", "transmission": "자동 8단",
                 "trim_name": "3.5T AWD", "official_efficiency": 8.8, "efficiency_unit": "km/L"},
    },
    "GV60": {
        "전기차": {"battery_kwh": 77.4, "drivetrain": "AWD", "transmission": "감속기",
                 "trim_name": "AWD", "official_efficiency": 4.8, "efficiency_unit": "km/kWh"},
    },
    "GV70": {
        "가솔린": {"displacement_cc": 2497, "drivetrain": "AWD", "transmission": "자동 8단",
                 "trim_name": "2.5T AWD", "official_efficiency": 9.8, "efficiency_unit": "km/L"},
        "디젤": {"displacement_cc": 2199, "drivetrain": "AWD", "transmission": "자동 8단",
                "trim_name": "2.2D AWD", "official_efficiency": 12.5, "efficiency_unit": "km/L"},
        "전기차": {"battery_kwh": 77.4, "drivetrain": "AWD", "transmission": "감속기",
                 "trim_name": "전동화 모델 AWD", "official_efficiency": 4.4, "efficiency_unit": "km/kWh"},
    },
    "GV80": {
        "가솔린": {"displacement_cc": 2497, "drivetrain": "AWD", "transmission": "자동 8단",
                 "trim_name": "2.5T AWD", "official_efficiency": 9.2, "efficiency_unit": "km/L"},
        "디젤": {"displacement_cc": 2199, "drivetrain": "AWD", "transmission": "자동 8단",
                "trim_name": "2.2D AWD", "official_efficiency": 11.8, "efficiency_unit": "km/L"},
    },
    "GV80 쿠페": {
        "가솔린": {"displacement_cc": 2497, "drivetrain": "AWD", "transmission": "자동 8단",
                 "trim_name": "2.5T AWD", "official_efficiency": 9.0, "efficiency_unit": "km/L"},
    },
}

# Chevrolet corrections
CHEVROLET_MODEL_SPECS = {
    "트레일블레이저": {
        "가솔린": {"displacement_cc": 1332, "drivetrain": "FWD", "transmission": "CVT",
                 "trim_name": "1.3 터보", "official_efficiency": 12.5, "efficiency_unit": "km/L"},
    },
    "이쿼녹스": {
        "가솔린": {"displacement_cc": 1998, "drivetrain": "FWD", "transmission": "자동 9단",
                 "trim_name": "2.0 터보", "official_efficiency": 11.0, "efficiency_unit": "km/L"},
        "전기차": {"battery_kwh": 85.0, "drivetrain": "FWD", "transmission": "감속기",
                 "trim_name": "EV", "official_efficiency": 5.0, "efficiency_unit": "km/kWh"},
    },
    "트래버스": {
        "가솔린": {"displacement_cc": 2458, "drivetrain": "FWD", "transmission": "자동 9단",
                 "trim_name": "2.5 터보", "official_efficiency": 9.5, "efficiency_unit": "km/L"},
    },
    "타호": {
        "가솔린": {"displacement_cc": 5328, "drivetrain": "AWD", "transmission": "자동 10단",
                 "trim_name": "5.3 V8", "official_efficiency": 7.0, "efficiency_unit": "km/L"},
    },
    "콜로라도": {
        "가솔린": {"displacement_cc": 2687, "drivetrain": "AWD", "transmission": "자동 8단",
                 "trim_name": "2.7 터보 4WD", "official_efficiency": 8.5, "efficiency_unit": "km/L"},
        "디젤": {"displacement_cc": 1956, "drivetrain": "AWD", "transmission": "자동 6단",
                "trim_name": "2.0 디젤 4WD", "official_efficiency": 11.0, "efficiency_unit": "km/L"},
    },
    "볼트 EV": {
        "전기차": {"battery_kwh": 65.0, "drivetrain": "FWD", "transmission": "감속기",
                 "trim_name": "EV", "official_efficiency": 5.5, "efficiency_unit": "km/kWh"},
    },
    "볼트 EUV": {
        "전기차": {"battery_kwh": 65.0, "drivetrain": "FWD", "transmission": "감속기",
                 "trim_name": "EUV", "official_efficiency": 5.2, "efficiency_unit": "km/kWh"},
    },
}

# Renault Korea corrections
RENAULT_MODEL_SPECS = {
    "SM6": {
        "가솔린": {"displacement_cc": 1998, "drivetrain": "FWD", "transmission": "CVT",
                 "trim_name": "2.0 가솔린", "official_efficiency": 12.5, "efficiency_unit": "km/L"},
        "LPG": {"displacement_cc": 1998, "drivetrain": "FWD", "transmission": "CVT",
                "trim_name": "2.0 LPi", "official_efficiency": 9.0, "efficiency_unit": "km/L"},
    },
    "QM6": {
        "가솔린": {"displacement_cc": 1998, "drivetrain": "FWD", "transmission": "CVT",
                 "trim_name": "2.0 가솔린", "official_efficiency": 11.5, "efficiency_unit": "km/L"},
        "디젤": {"displacement_cc": 1998, "drivetrain": "FWD", "transmission": "CVT",
                "trim_name": "2.0 디젤", "official_efficiency": 14.5, "efficiency_unit": "km/L"},
        "LPG": {"displacement_cc": 1998, "drivetrain": "FWD", "transmission": "CVT",
                "trim_name": "2.0 LPi", "official_efficiency": 8.5, "efficiency_unit": "km/L"},
    },
    "아르카나": {
        "하이브리드": {"displacement_cc": 1598, "drivetrain": "FWD", "transmission": "자동",
                   "trim_name": "1.6 E-TECH 하이브리드", "official_efficiency": 17.5, "efficiency_unit": "km/L"},
    },
    "XM3": {
        "가솔린": {"displacement_cc": 1332, "drivetrain": "FWD", "transmission": "자동 7단 DCT",
                 "trim_name": "1.3 TCe", "official_efficiency": 13.5, "efficiency_unit": "km/L"},
        "LPG": {"displacement_cc": 1998, "drivetrain": "FWD", "transmission": "CVT",
                "trim_name": "2.0 LPi", "official_efficiency": 9.5, "efficiency_unit": "km/L"},
    },
}

# KG Mobility corrections
KGM_MODEL_SPECS = {
    "티볼리": {
        "가솔린": {"displacement_cc": 1498, "drivetrain": "FWD", "transmission": "자동 6단",
                 "trim_name": "1.5 터보", "official_efficiency": 12.5, "efficiency_unit": "km/L"},
    },
    "코란도": {
        "가솔린": {"displacement_cc": 1498, "drivetrain": "FWD", "transmission": "자동 6단",
                 "trim_name": "1.5 터보", "official_efficiency": 11.5, "efficiency_unit": "km/L"},
        "디젤": {"displacement_cc": 1597, "drivetrain": "AWD", "transmission": "자동 6단",
                "trim_name": "1.6 디젤 AWD", "official_efficiency": 13.5, "efficiency_unit": "km/L"},
        "전기차": {"battery_kwh": 61.5, "drivetrain": "FWD", "transmission": "감속기",
                 "trim_name": "e-Motion", "official_efficiency": 5.0, "efficiency_unit": "km/kWh"},
    },
    "렉스턴": {
        "디젤": {"displacement_cc": 2157, "drivetrain": "AWD", "transmission": "자동 8단",
                "trim_name": "2.2 디젤 AWD", "official_efficiency": 10.5, "efficiency_unit": "km/L"},
    },
    "토레스": {
        "가솔린": {"displacement_cc": 1498, "drivetrain": "FWD", "transmission": "자동 6단",
                 "trim_name": "1.5 터보", "official_efficiency": 11.8, "efficiency_unit": "km/L"},
        "전기차": {"battery_kwh": 73.4, "drivetrain": "FWD", "transmission": "감속기",
                 "trim_name": "토레스 EVX", "official_efficiency": 4.8, "efficiency_unit": "km/kWh"},
    },
}

# Jeep corrections
JEEP_MODEL_SPECS = {
    "랭글러": {
        "가솔린": {"displacement_cc": 1995, "drivetrain": "AWD", "transmission": "자동 8단",
                 "trim_name": "2.0 터보 4xe", "official_efficiency": 8.5, "efficiency_unit": "km/L"},
        "플러그인 하이브리드": {"displacement_cc": 1995, "drivetrain": "AWD", "transmission": "자동 8단",
                        "trim_name": "4xe PHEV", "official_efficiency": 10.5, "efficiency_unit": "km/L"},
    },
    "그랜드 체로키": {
        "가솔린": {"displacement_cc": 1995, "drivetrain": "AWD", "transmission": "자동 8단",
                 "trim_name": "2.0 터보 4xe", "official_efficiency": 8.0, "efficiency_unit": "km/L"},
        "플러그인 하이브리드": {"displacement_cc": 1995, "drivetrain": "AWD", "transmission": "자동 8단",
                        "trim_name": "4xe PHEV", "official_efficiency": 9.5, "efficiency_unit": "km/L"},
    },
    "컴패스": {
        "가솔린": {"displacement_cc": 1332, "drivetrain": "FWD", "transmission": "자동 6단 DDCT",
                 "trim_name": "1.3 터보", "official_efficiency": 12.0, "efficiency_unit": "km/L"},
    },
    "레니게이드": {
        "가솔린": {"displacement_cc": 1332, "drivetrain": "FWD", "transmission": "자동 6단 DDCT",
                 "trim_name": "1.3 터보", "official_efficiency": 12.5, "efficiency_unit": "km/L"},
    },
}

# Land Rover corrections
LANDROVER_MODEL_SPECS = {
    "레인지로버": {
        "가솔린": {"displacement_cc": 2996, "drivetrain": "AWD", "transmission": "자동 8단",
                 "trim_name": "P400 6기통", "official_efficiency": 8.0, "efficiency_unit": "km/L"},
        "디젤": {"displacement_cc": 2997, "drivetrain": "AWD", "transmission": "자동 8단",
                "trim_name": "D350 6기통", "official_efficiency": 10.5, "efficiency_unit": "km/L"},
        "플러그인 하이브리드": {"displacement_cc": 2996, "drivetrain": "AWD", "transmission": "자동 8단",
                        "trim_name": "P510e PHEV", "official_efficiency": 11.0, "efficiency_unit": "km/L"},
    },
    "레인지로버 스포츠": {
        "가솔린": {"displacement_cc": 2996, "drivetrain": "AWD", "transmission": "자동 8단",
                 "trim_name": "P400", "official_efficiency": 8.5, "efficiency_unit": "km/L"},
        "디젤": {"displacement_cc": 2997, "drivetrain": "AWD", "transmission": "자동 8단",
                "trim_name": "D350", "official_efficiency": 11.0, "efficiency_unit": "km/L"},
        "플러그인 하이브리드": {"displacement_cc": 2996, "drivetrain": "AWD", "transmission": "자동 8단",
                        "trim_name": "P510e PHEV", "official_efficiency": 11.5, "efficiency_unit": "km/L"},
    },
    "디펜더": {
        "가솔린": {"displacement_cc": 1997, "drivetrain": "AWD", "transmission": "자동 8단",
                 "trim_name": "P300 4기통", "official_efficiency": 8.5, "efficiency_unit": "km/L"},
        "디젤": {"displacement_cc": 2997, "drivetrain": "AWD", "transmission": "자동 8단",
                "trim_name": "D300 6기통", "official_efficiency": 10.0, "efficiency_unit": "km/L"},
    },
    "디스커버리": {
        "가솔린": {"displacement_cc": 1997, "drivetrain": "AWD", "transmission": "자동 9단",
                 "trim_name": "P300 4기통", "official_efficiency": 8.0, "efficiency_unit": "km/L"},
        "디젤": {"displacement_cc": 2997, "drivetrain": "AWD", "transmission": "자동 8단",
                "trim_name": "D300 6기통", "official_efficiency": 10.5, "efficiency_unit": "km/L"},
    },
    "이보크": {
        "가솔린": {"displacement_cc": 1997, "drivetrain": "AWD", "transmission": "자동 9단",
                 "trim_name": "P250", "official_efficiency": 10.5, "efficiency_unit": "km/L"},
        "디젤": {"displacement_cc": 1999, "drivetrain": "AWD", "transmission": "자동 9단",
                "trim_name": "D200", "official_efficiency": 13.5, "efficiency_unit": "km/L"},
    },
    "디스커버리 스포츠": {
        "가솔린": {"displacement_cc": 1997, "drivetrain": "AWD", "transmission": "자동 9단",
                 "trim_name": "P250", "official_efficiency": 10.0, "efficiency_unit": "km/L"},
        "디젤": {"displacement_cc": 1999, "drivetrain": "AWD", "transmission": "자동 9단",
                "trim_name": "D200", "official_efficiency": 13.0, "efficiency_unit": "km/L"},
    },
}

# Map manufacturer_name -> specs dict
MANUFACTURER_SPECS = {
    "BMW": BMW_MODEL_SPECS,
    "포르쉐": PORSCHE_MODEL_SPECS,
    "메르세데스-벤츠": BENZ_MODEL_SPECS,
    "아우디": AUDI_MODEL_SPECS,
    "테슬라": TESLA_MODEL_SPECS,
    "폭스바겐": VW_MODEL_SPECS,
    "볼보": VOLVO_MODEL_SPECS,
    "토요타": TOYOTA_MODEL_SPECS,
    "렉서스": LEXUS_MODEL_SPECS,
    "혼다": HONDA_MODEL_SPECS,
    "닛산": NISSAN_MODEL_SPECS,
    "MINI": MINI_MODEL_SPECS,
    "푸조": PEUGEOT_MODEL_SPECS,
    "폴스타": POLESTAR_MODEL_SPECS,
    "제네시스": GENESIS_MODEL_SPECS,
    "쉐보레": CHEVROLET_MODEL_SPECS,
    "르노코리아": RENAULT_MODEL_SPECS,
    "KG모빌리티": KGM_MODEL_SPECS,
    "지프": JEEP_MODEL_SPECS,
    "랜드로버": LANDROVER_MODEL_SPECS,
}

# Efficiency-only supplements for Hyundai/Kia (they already have some data)
EFFICIENCY_SUPPLEMENTS = {
    "현대": HYUNDAI_EFFICIENCY_SUPPLEMENT,
    "기아": KIA_EFFICIENCY_SUPPLEMENT,
}


def apply_corrections(data):
    """Apply corrections to all variants in the catalog."""
    variants = data.get("variants", [])
    corrected = 0
    eff_added = 0

    for v in variants:
        mfr = v.get("manufacturer_name", "")
        model = v.get("model_name", "")
        fuel = v.get("fuel_type", "")

        # Check full manufacturer spec corrections
        if mfr in MANUFACTURER_SPECS:
            specs = MANUFACTURER_SPECS[mfr]
            if model in specs and fuel in specs[model]:
                corrections = specs[model][fuel]
                for key, value in corrections.items():
                    if key in ("official_efficiency",) and v.get(key) is not None:
                        # Don't override existing efficiency data
                        continue
                    v[key] = value
                corrected += 1
                continue

        # Check efficiency supplements (for Hyundai/Kia)
        if mfr in EFFICIENCY_SUPPLEMENTS:
            supp = EFFICIENCY_SUPPLEMENTS[mfr]
            if (model, fuel) in supp:
                corrections = supp[(model, fuel)]
                for key, value in corrections.items():
                    if key in ("official_efficiency",) and v.get(key) is not None:
                        continue
                    v[key] = value
                eff_added += 1

    return corrected, eff_added


def main():
    print("Loading catalog from {}...".format(INPUT_PATH))
    with open(INPUT_PATH, "r", encoding="utf-8") as f:
        data = json.load(f)

    variants_before = len(data.get("variants", []))
    print("Loaded {} variants".format(variants_before))

    corrected, eff_added = apply_corrections(data)
    print("Corrected {} variants (full spec update)".format(corrected))
    print("Added efficiency data to {} additional variants".format(eff_added))

    # Update generated_at
    from datetime import datetime
    data["generated_at"] = datetime.utcnow().isoformat() + "Z"
    data["notes"] = ("2008-2026 연식을 제조사 > 모델 > 연식 > 파워트레인 단위로 구조화한다. "
                     "각 제조사별 실제 배기량, 구동방식, 변속기, 배터리 용량, 공인연비를 교정했다.")

    print("Writing corrected catalog to {}...".format(OUTPUT_PATH))
    with io.open(OUTPUT_PATH, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

    print("Done!")

    # Quick stats
    variants = data.get("variants", [])
    has_eff = sum(1 for v in variants if v.get("official_efficiency") is not None)
    print("Efficiency coverage: {} / {} ({:.1f}%)".format(
        has_eff, len(variants), 100 * has_eff / max(len(variants), 1)))


if __name__ == "__main__":
    main()
