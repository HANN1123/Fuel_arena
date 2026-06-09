#!/usr/bin/env python3
"""Analyze vehicle catalog JSON for data quality - writes UTF-8 output."""
import json
import sys
import io
from collections import Counter

def main():
    path = "assets/data/vehicle_catalog_kr_seed.json"
    with open(path, "r", encoding="utf-8") as f:
        d = json.load(f)

    out = io.open("tool/catalog_report.md", "w", encoding="utf-8")

    def p(text=""):
        out.write(text + "\n")

    p("# 차량 카탈로그 품질 분석 보고서")
    p()

    p("## 기본 정보")
    p("- schema_version: {}".format(d.get("schema_version")))
    p("- generated_at: {}".format(d.get("generated_at")))
    p("- notes: {}".format(d.get("notes")))
    p()

    manufacturers = d.get("manufacturers", [])
    models = d.get("models", [])
    years = d.get("years", [])
    variants = d.get("variants", [])

    p("## 수량 요약")
    p("| 항목 | 수 |")
    p("|---|---|")
    p("| 제조사 | {} |".format(len(manufacturers)))
    p("| 모델 | {} |".format(len(models)))
    p("| 연식 | {} |".format(len(years)))
    p("| 트림/변종 | {} |".format(len(variants)))
    p()

    p("## 제조사 목록")
    p("| ID | 한국어명 | 영어명 | 국가 | 인기 |")
    p("|---|---|---|---|---|")
    for m in manufacturers:
        p("| {} | {} | {} | {} | {} |".format(
            m.get("id", ""), m.get("name_ko", ""), m.get("name_en", ""),
            m.get("country", ""), m.get("is_popular", False)))
    p()

    p("## 연료 타입 분포")
    p("| 연료 타입 | 수 |")
    p("|---|---|")
    fuel_types = Counter(v.get("fuel_type", "") for v in variants)
    for ft, count in fuel_types.most_common():
        p("| {} | {} |".format(ft, count))
    p()

    p("## 차급 분포")
    p("| 차급 | 수 |")
    p("|---|---|")
    classes = Counter(v.get("vehicle_class", "") for v in variants)
    for vc, count in classes.most_common():
        p("| {} | {} |".format(vc, count))
    p()

    p("## 리그 분포")
    p("| 리그 | 수 |")
    p("|---|---|")
    leagues = Counter(v.get("fuel_league", "") for v in variants)
    for lg, count in leagues.most_common():
        p("| {} | {} |".format(lg, count))
    p()

    p("## 데이터 품질 검사 결과")
    p()

    # 1. Missing official_efficiency
    missing_eff = [v for v in variants if v.get("official_efficiency") is None]
    p("### 1. 공인연비(official_efficiency) 누락")
    p("- 누락: {} / {} ({:.1f}%)".format(
        len(missing_eff), len(variants),
        100 * len(missing_eff) / max(len(variants), 1)))
    p()

    # 2. Non-EV missing displacement
    non_ev = [v for v in variants if v.get("fuel_type") not in ("electric",)]
    missing_disp = [v for v in non_ev if v.get("displacement_cc") is None]
    p("### 2. 비전기차 배기량(displacement_cc) 누락")
    p("- 누락: {} / {} ({:.1f}%)".format(
        len(missing_disp), len(non_ev),
        100 * len(missing_disp) / max(len(non_ev), 1)))
    p()

    # 3. EV with displacement
    ev_with_disp = [v for v in variants
                    if v.get("fuel_type") == "electric"
                    and v.get("displacement_cc") is not None
                    and v.get("displacement_cc", 0) > 0]
    p("### 3. 전기차인데 배기량이 있는 경우")
    p("- 해당: {} 건".format(len(ev_with_disp)))
    if ev_with_disp:
        for v in ev_with_disp[:10]:
            p("  - {} {} {} {} (disp={}cc)".format(
                v.get("manufacturer_name"), v.get("model_name"),
                v.get("year"), v.get("trim_name"), v.get("displacement_cc")))
    p()

    # 4. EV missing battery
    ev = [v for v in variants if v.get("fuel_type") == "electric"]
    ev_no_batt = [v for v in ev if v.get("battery_kwh") is None]
    p("### 4. 전기차 배터리 용량(battery_kwh) 누락")
    p("- 누락: {} / {}".format(len(ev_no_batt), len(ev)))
    p()

    # 5. Fuel type/league mismatch
    league_map = {
        "gasoline": "gasoline",
        "diesel": "diesel",
        "hybrid": "hybrid",
        "electric": "electric",
        "lpg": "lpg",
        "plug_in_hybrid": "plug_in_hybrid",
    }
    mismatched = []
    for v in variants:
        ft = v.get("fuel_type", "")
        fl = v.get("fuel_league", "")
        expected = league_map.get(ft, "other")
        if fl and fl != expected:
            mismatched.append(v)
    p("### 5. 연료타입/리그 불일치")
    p("- 불일치: {} 건".format(len(mismatched)))
    for v in mismatched[:10]:
        p("  - {} {} {} - fuel_type={} league={}".format(
            v.get("manufacturer_name"), v.get("model_name"),
            v.get("trim_name"), v.get("fuel_type"), v.get("fuel_league")))
    p()

    # 6. Efficiency unit consistency
    eff_units = Counter(v.get("efficiency_unit", "") for v in variants if v.get("official_efficiency") is not None)
    p("### 6. 효율 단위")
    p("- {}".format(dict(eff_units)))
    p()

    # 7. Year range
    all_years = [v.get("year", 0) for v in variants]
    p("### 7. 연식 범위")
    p("- {} ~ {}".format(min(all_years), max(all_years)))
    p()

    # 8. Check for suspicious/generic data patterns
    p("### 8. 의심스러운 데이터 패턴")
    p()

    # Check if many variants have exact same displacement
    disp_counter = Counter(v.get("displacement_cc") for v in variants if v.get("displacement_cc") is not None)
    p("#### 배기량 분포 (상위 10)")
    p("| 배기량(cc) | 수 |")
    p("|---|---|")
    for disp, count in disp_counter.most_common(10):
        p("| {} | {} |".format(disp, count))
    p()

    # Check BMW specifically (common issue with wrong data)
    p("### 9. 제조사별 상세 검증 (문제 의심 차량)")
    p()

    # BMW - Check if BMW 1 Series really has 1.6L engine
    bmw_variants = [v for v in variants if v.get("manufacturer_name") == "BMW"]
    p("#### BMW ({} 트림)".format(len(bmw_variants)))
    p("| 모델 | 연식 | 트림 | 연료 | 배기량 | 구동 | 변속기 |")
    p("|---|---|---|---|---|---|---|")
    bmw_models = {}
    for v in bmw_variants:
        model = v.get("model_name")
        if model not in bmw_models:
            bmw_models[model] = v
            p("| {} | {} | {} | {} | {}cc | {} | {} |".format(
                model, v.get("year"), v.get("trim_name"),
                v.get("fuel_type"), v.get("displacement_cc"),
                v.get("drivetrain"), v.get("transmission")))
    p()

    # Hyundai
    hyundai_variants = [v for v in variants if v.get("manufacturer_name") == "현대"]
    p("#### 현대 ({} 트림)".format(len(hyundai_variants)))
    p("| 모델 | 연식 | 트림 | 연료 | 배기량 | 구동 | 변속기 | 공인연비 |")
    p("|---|---|---|---|---|---|---|---|")
    hyundai_models = {}
    for v in hyundai_variants:
        key = (v.get("model_name"), v.get("fuel_type"), v.get("trim_name"))
        if key not in hyundai_models:
            hyundai_models[key] = v
            p("| {} | {} | {} | {} | {}cc | {} | {} | {} {} |".format(
                v.get("model_name"), v.get("year"), v.get("trim_name"),
                v.get("fuel_type"), v.get("displacement_cc"),
                v.get("drivetrain"), v.get("transmission"),
                v.get("official_efficiency", "N/A"),
                v.get("efficiency_unit", "")))
    p()

    # Kia
    kia_variants = [v for v in variants if v.get("manufacturer_name") == "기아"]
    p("#### 기아 ({} 트림)".format(len(kia_variants)))
    p("| 모델 | 연식 | 트림 | 연료 | 배기량 | 구동 | 변속기 | 공인연비 |")
    p("|---|---|---|---|---|---|---|---|")
    kia_models = {}
    for v in kia_variants:
        key = (v.get("model_name"), v.get("fuel_type"), v.get("trim_name"))
        if key not in kia_models:
            kia_models[key] = v
            p("| {} | {} | {} | {} | {}cc | {} | {} | {} {} |".format(
                v.get("model_name"), v.get("year"), v.get("trim_name"),
                v.get("fuel_type"), v.get("displacement_cc"),
                v.get("drivetrain"), v.get("transmission"),
                v.get("official_efficiency", "N/A"),
                v.get("efficiency_unit", "")))
    p()

    # Tesla
    tesla_variants = [v for v in variants if v.get("manufacturer_name") == "테슬라"]
    p("#### 테슬라 ({} 트림)".format(len(tesla_variants)))
    p("| 모델 | 연식 | 트림 | 배터리 | 구동 | 변속기 |")
    p("|---|---|---|---|---|---|")
    tesla_models = {}
    for v in tesla_variants:
        key = (v.get("model_name"), v.get("trim_name"))
        if key not in tesla_models:
            tesla_models[key] = v
            p("| {} | {} | {} | {}kWh | {} | {} |".format(
                v.get("model_name"), v.get("year"), v.get("trim_name"),
                v.get("battery_kwh"),
                v.get("drivetrain"), v.get("transmission")))
    p()

    # Check Porsche 911 FWD issue
    p("### 10. 특이 사항 검출")
    p()

    # Porsche with FWD?
    porsche_fwd = [v for v in variants if v.get("manufacturer_name") == "포르쉐" and v.get("drivetrain") == "FWD"]
    if porsche_fwd:
        p("#### 포르쉐 FWD 차량 (실제로는 RWD/AWD여야 함)")
        for v in porsche_fwd[:5]:
            p("  - {} {} {} - drivetrain=FWD".format(
                v.get("model_name"), v.get("year"), v.get("trim_name")))
        p()

    # BMW 1-series FWD with 1.6L (BMW 1-series is typically 1.5T/2.0T, FWD or RWD)
    bmw_1_series = [v for v in variants if v.get("manufacturer_name") == "BMW" and "1" in str(v.get("model_name", ""))]
    if bmw_1_series:
        p("#### BMW 1시리즈 실제 확인 필요")
        for v in bmw_1_series[:3]:
            p("  - {} {} {} disp={}cc dt={} trans={}".format(
                v.get("model_name"), v.get("year"), v.get("trim_name"),
                v.get("displacement_cc"), v.get("drivetrain"), v.get("transmission")))
        p()

    # Diesel-only models check: 디젤 배기량이 대부분 비현실적일 수 있음
    diesel = [v for v in variants if v.get("fuel_type") == "diesel"]
    if diesel:
        diesel_disp = Counter(v.get("displacement_cc") for v in diesel)
        p("#### 디젤 차량 배기량 분포")
        p("| 배기량(cc) | 수 |")
        p("|---|---|")
        for disp, count in diesel_disp.most_common(10):
            p("| {} | {} |".format(disp, count))
        p()

    # PHEV battery check
    phev = [v for v in variants if v.get("fuel_type") == "plug_in_hybrid"]
    if phev:
        p("#### PHEV 배터리 정보")
        phev_batt = Counter(v.get("battery_kwh") for v in phev)
        p("- 배터리 값 분포: {}".format(dict(phev_batt)))
        p()

    # hybrid with displacement but wrong fuel league
    hybrid = [v for v in variants if v.get("fuel_type") == "hybrid"]
    if hybrid:
        p("#### 하이브리드 배기량 분포")
        hyb_disp = Counter(v.get("displacement_cc") for v in hybrid)
        p("| 배기량(cc) | 수 |")
        p("|---|---|")
        for disp, count in hyb_disp.most_common(10):
            p("| {} | {} |".format(disp, count))
        p()

    out.close()
    print("Report written to tool/catalog_report.md")

if __name__ == "__main__":
    main()
