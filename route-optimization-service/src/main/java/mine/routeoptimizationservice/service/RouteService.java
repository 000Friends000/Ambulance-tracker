package mine.routeoptimizationservice.service;

import mine.routeoptimizationservice.dto.MapboxDirectionsResponse;
import mine.routeoptimizationservice.dto.RouteResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;

@Service
public class
RouteService {

    @Value("${mapbox.api-key}")
    private String mapboxApiKey;

    private final WebClient webClient;

    public RouteService(WebClient.Builder webClientBuilder) {
        this.webClient = webClientBuilder.baseUrl("https://api.mapbox.com").build();
    }

    public RouteResponse getOptimizedRoute(Double originLat, Double originLng, Double destLat, Double destLng) {
        String coordinates = String.format("%f,%f;%f,%f", originLng, originLat, destLng, destLat);

        String url = String.format(
                "/directions/v5/mapbox/driving/%s?access_token=%s&overview=full&geometries=polyline",
                coordinates,
                mapboxApiKey
        );

        MapboxDirectionsResponse response = webClient.get()
                .uri(url)
                .retrieve()
                .bodyToMono(MapboxDirectionsResponse.class)
                .block();

        if (response != null && !response.getRoutes().isEmpty()) {
            MapboxDirectionsResponse.Route route = response.getRoutes().get(0);
            RouteResponse routeResponse = new RouteResponse();
            routeResponse.setGeometry(route.getGeometry());
            routeResponse.setDistance(route.getDistance());
            routeResponse.setDuration(route.getDuration());
            routeResponse.setStatus("SUCCESS");
            return routeResponse;
        } else {
            RouteResponse routeResponse = new RouteResponse();
            routeResponse.setStatus("FAILURE");
            return routeResponse;
        }
    }
}
