from typing import Optional, Tuple
from app.core.config import settings
from app.utils.geo import haversine_distance_meters


class GPSFilter:
    """Kalman-like noise filter and outlier rejector for real-time mobile GNSS feeds."""

    def __init__(self, process_noise: float = 0.005):
        self.process_noise = process_noise
        self.variance = -1.0
        self.lat = 0.0
        self.lng = 0.0

    def is_valid_point(
        self,
        lat: float,
        lng: float,
        accuracy_m: Optional[float] = None,
        speed_kmh: Optional[float] = None,
        last_lat: Optional[float] = None,
        last_lng: Optional[float] = None,
        time_delta_seconds: Optional[float] = None
    ) -> bool:
        """Evaluate if incoming smartphone coordinate is valid or should be filtered as drift/jitter."""
        # 1. Bounds check
        if not (-90.0 <= lat <= 90.0) or not (-180.0 <= lng <= 180.0):
            return False
        
        # 2. Reject 0,0 null island
        if abs(lat) < 0.0001 and abs(lng) < 0.0001:
            return False

        # 3. Accuracy check
        if accuracy_m is not None and accuracy_m > settings.MAX_ALLOWED_ACCURACY_M:
            return False

        # 4. Instantaneous reported speed check
        if speed_kmh is not None and speed_kmh > settings.MAX_VALID_SPEED_KMH:
            return False

        # 5. Jump distance vs time delta check (impossible teleportation jump)
        if last_lat is not None and last_lng is not None and time_delta_seconds and time_delta_seconds > 0:
            dist_m = haversine_distance_meters(last_lat, last_lng, lat, lng)
            calculated_speed_kmh = (dist_m / time_delta_seconds) * 3.6
            if calculated_speed_kmh > settings.MAX_VALID_SPEED_KMH:
                return False

        return True

    def smooth_point(self, lat: float, lng: float, accuracy_m: float) -> Tuple[float, float]:
        """Apply 1D-per-axis variance Kalman smoothing on coordinates."""
        if self.variance < 0:
            self.lat = lat
            self.lng = lng
            self.variance = accuracy_m * accuracy_m
            return lat, lng

        # Predict step
        self.variance += self.process_noise

        # Measurement update
        measurement_variance = accuracy_m * accuracy_m
        if (self.variance + measurement_variance) > 0:
            k = self.variance / (self.variance + measurement_variance)
        else:
            k = 0.5

        self.lat = self.lat + k * (lat - self.lat)
        self.lng = self.lng + k * (lng - self.lng)
        self.variance = (1.0 - k) * self.variance

        return round(self.lat, 7), round(self.lng, 7)


gps_filter = GPSFilter()
