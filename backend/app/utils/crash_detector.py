from typing import Optional, Dict, Any


def evaluate_crash_telemetry(
    impact_g: float,
    speed_before_kmh: float,
    speed_after_kmh: float,
    angular_change_deg: Optional[float] = None
) -> Dict[str, Any]:
    """
    Conservative crash detection model.
    To minimize false positives (e.g. phone dropped in pocket or hitting a pothole):
    A candidate crash event requires:
    1. High peak G-force impact (e.g., > 3.8G).
    2. Significant rapid deceleration (drop from > 20 km/h to near 0 km/h within 2 seconds).
    3. Sustained stillness after impact.
    """
    is_high_g = impact_g >= 3.8
    speed_drop = speed_before_kmh - speed_after_kmh
    is_rapid_decel = (speed_before_kmh >= 20.0 and speed_drop >= 15.0 and speed_after_kmh <= 8.0)
    
    # Probability confidence score
    confidence = 0.0
    if is_high_g:
        confidence += 0.5
    if is_rapid_decel:
        confidence += 0.4
    if angular_change_deg and angular_change_deg > 60:
        confidence += 0.1

    is_probable_crash = confidence >= 0.7

    return {
        "is_probable_crash": is_probable_crash,
        "confidence_score": round(confidence, 2),
        "impact_g": impact_g,
        "speed_drop_kmh": round(speed_drop, 1),
        "recommended_action": "INITIATE_COUNTDOWN" if is_probable_crash else "IGNORE"
    }
