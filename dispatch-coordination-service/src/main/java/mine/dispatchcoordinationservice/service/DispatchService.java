package mine.dispatchcoordinationservice.service;

import mine.dispatchcoordinationservice.dto.*;
import mine.dispatchcoordinationservice.model.Case;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatusCode;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;

import java.time.LocalDateTime;
import java.util.*;

@Service
public class DispatchService {

    private static final Logger log = LoggerFactory.getLogger(DispatchService.class);

    private static final String HOSPITAL_MANAGEMENT_SERVICE_URL = "http://hospital-management-service";
    private static final String ROUTE_OPTIMIZATION_SERVICE_URL = "http://route-optimization-service";
    private static final String AMBULANCE_SERVICE_URL = "http://ambulance-service";

    private final WebClient webClient;
    private final CaseService caseService;

    public DispatchService(WebClient.Builder webClientBuilder, CaseService caseService) {
        this.webClient = webClientBuilder.build();
        this.caseService = caseService;
    }

    public DispatchResult handleEmergency(EmergencyRequest request) {
        // Step 1: Fetch hospitals by specialization
        List<Hospital> hospitals = fetchHospitalsBySpeciality(request.getSpecialization());
        if (hospitals.isEmpty()) {
            return createFailureResult("No hospital with the required specialization found.");
        }

        // Step 2: Fetch available ambulances associated with hospitals
        List<AmbulanceHospitalPair> ambulanceHospitalPairs = getAvailableAmbulances(hospitals);
        if (ambulanceHospitalPairs.isEmpty()) {
            return createFailureResult("No available ambulances found for the required specialization.");
        }

        // Step 3: Find the nearest ambulance
        AmbulanceHospitalPair selectedPair = findNearestAmbulance(ambulanceHospitalPairs, request);
        if (selectedPair == null) {
            return createFailureResult("No suitable ambulance found.");
        }

        // Step 4: Calculate route
        RouteResponse routeResponse = fetchRoute(selectedPair.getAmbulance(), request);
        if (!"SUCCESS".equals(routeResponse.getStatus())) {
            return createFailureResult("Route calculation failed.");
        }

        // Step 5: Mark ambulance as unavailable
        boolean isUpdated = updateAmbulanceAvailability(selectedPair.getAmbulance().getId(), false);
        if (!isUpdated) {
            return createFailureResult("Failed to update ambulance availability.");
        }

        // Step 6: Save case to database
        Case newCase = saveDispatchCase(request, selectedPair, routeResponse);

        // Step 7: Create DispatchResult
        DispatchResult dispatchResult = createDispatchResult(selectedPair, routeResponse, newCase);
        return dispatchResult;
    }

    private List<Hospital> fetchHospitalsBySpeciality(String speciality) {
        try {
            return webClient.get()
                    .uri(HOSPITAL_MANAGEMENT_SERVICE_URL + "/hospitals?speciality=" + speciality)
                    .retrieve()
                    .onStatus(HttpStatusCode::isError, response -> Mono.error(new RuntimeException("Error fetching hospitals")))
                    .bodyToFlux(Hospital.class)
                    .collectList()
                    .block();
        } catch (Exception e) {
            log.error("Error fetching hospitals by specialization: {}", speciality, e);
            return Collections.emptyList();
        }
    }

    private List<AmbulanceHospitalPair> getAvailableAmbulances(List<Hospital> hospitals) {
        List<AmbulanceHospitalPair> pairs = new ArrayList<>();
        for (Hospital hospital : hospitals) {
            List<Ambulance> ambulances = fetchAmbulancesByHospital(hospital.getId());
            ambulances.stream()
                    .filter(Ambulance::isAvailable)
                    .forEach(ambulance -> pairs.add(new AmbulanceHospitalPair(ambulance, hospital)));
        }
        return pairs;
    }

    private List<Ambulance> fetchAmbulancesByHospital(Long hospitalId) {
        try {
            return webClient.get()
                    .uri(HOSPITAL_MANAGEMENT_SERVICE_URL + "/hospitals/by-hospital/" + hospitalId)
                    .retrieve()
                    .onStatus(HttpStatusCode::isError, response -> Mono.error(new RuntimeException("Error fetching ambulances")))
                    .bodyToFlux(Ambulance.class)
                    .collectList()
                    .block();
        } catch (Exception e) {
            log.error("Error fetching ambulances for hospital ID: {}", hospitalId, e);
            return Collections.emptyList();
        }
    }

    private AmbulanceHospitalPair findNearestAmbulance(List<AmbulanceHospitalPair> pairs, EmergencyRequest request) {
        return pairs.stream()
                .min(Comparator.comparingDouble(pair -> calculateDistance(
                        pair.getAmbulance().getLatitude(),
                        pair.getAmbulance().getLongitude(),
                        request.getLatitude(),
                        request.getLongitude())))
                .orElse(null);
    }

    private RouteResponse fetchRoute(Ambulance ambulance, EmergencyRequest request) {
        try {
            return webClient.get()
                    .uri(uriBuilder -> uriBuilder
                            .scheme("http")
                            .host("route-optimization-service")
                            .path("/routes")
                            .queryParam("originLat", ambulance.getLatitude())
                            .queryParam("originLng", ambulance.getLongitude())
                            .queryParam("destLat", request.getLatitude())
                            .queryParam("destLng", request.getLongitude())
                            .build())
                    .retrieve()
                    .onStatus(HttpStatusCode::isError, response -> Mono.error(new RuntimeException("Error calculating route")))
                    .bodyToMono(RouteResponse.class)
                    .block();
        } catch (Exception e) {
            log.error("Error fetching route for ambulance ID: {}", ambulance.getId(), e);
            return new RouteResponse("FAILURE", null);
        }
    }


    private boolean updateAmbulanceAvailability(Integer ambulanceId, boolean availability) {
        try {
            webClient.put()
                    .uri(AMBULANCE_SERVICE_URL + "/ambulances/" + ambulanceId + "/availability")
                    .bodyValue(java.util.Map.of("available", availability))
                    .retrieve()
                    .onStatus(HttpStatusCode::isError, response -> Mono.error(new RuntimeException("Error updating ambulance availability")))
                    .toBodilessEntity()
                    .block();
            return true;
        } catch (Exception e) {
            log.error("Error updating availability for ambulance ID: {}", ambulanceId, e);
            return false;
        }
    }

    private Case saveDispatchCase(EmergencyRequest request, AmbulanceHospitalPair selectedPair, RouteResponse routeResponse) {
        Case newCase = new Case();
        newCase.setLatitude(request.getLatitude());
        newCase.setLongitude(request.getLongitude());
        newCase.setSpecialization(request.getSpecialization());
        newCase.setStatus("OPEN");
        newCase.setAssignedAmbulanceId(selectedPair.getAmbulance().getId());
        newCase.setAssignedHospitalId(selectedPair.getHospital().getId());
        newCase.setEstimatedDuration(routeResponse.getDuration());
        newCase.setEstimatedDistance(routeResponse.getDistance());
        newCase.setRouteGeometry(routeResponse.getGeometry());
        newCase.setCreatedAt(LocalDateTime.now());
        caseService.createCase(newCase);
        return newCase;
    }

    private DispatchResult createDispatchResult(AmbulanceHospitalPair selectedPair, RouteResponse routeResponse, Case savedCase) {
        DispatchResult result = new DispatchResult();
        result.setAssignedAmbulance(selectedPair.getAmbulance());
        result.setAssignedHospital(selectedPair.getHospital());
        result.setRoutePolyline(routeResponse.getGeometry());
        result.setStatus("SUCCESS");
        return result;
    }

    private double calculateDistance(Double lat1, Double lon1, Double lat2, Double lon2) {
        double R = 6371e3; // Earth radius in meters
        double phi1 = Math.toRadians(lat1);
        double phi2 = Math.toRadians(lat2);
        double deltaPhi = Math.toRadians(lat2 - lat1);
        double deltaLambda = Math.toRadians(lon2 - lon1);
        double a = Math.sin(deltaPhi / 2) * Math.sin(deltaPhi / 2) +
                Math.cos(phi1) * Math.cos(phi2) *
                        Math.sin(deltaLambda / 2) * Math.sin(deltaLambda / 2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return R * c;
    }

    private DispatchResult createFailureResult(String message) {
        DispatchResult result = new DispatchResult();
        result.setStatus("FAILURE");
        log.error("Dispatch failed: {}", message);
        return result;
    }

    private static class AmbulanceHospitalPair {
        private final Ambulance ambulance;
        private final Hospital hospital;

        public AmbulanceHospitalPair(Ambulance ambulance, Hospital hospital) {
            this.ambulance = ambulance;
            this.hospital = hospital;
        }

        public Ambulance getAmbulance() {
            return ambulance;
        }

        public Hospital getHospital() {
            return hospital;
        }
    }
}
