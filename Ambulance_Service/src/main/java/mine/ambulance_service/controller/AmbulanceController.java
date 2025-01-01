package mine.ambulance_service.controller;

import mine.ambulance_service.model.Ambulance;
import mine.ambulance_service.service.AmbulanceService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/ambulances")
public class AmbulanceController {

    private final AmbulanceService ambulanceService;

    public AmbulanceController(AmbulanceService ambulanceService) {
        this.ambulanceService = ambulanceService;
    }

    @GetMapping
    public List<Ambulance> getAllAmbulances() {
        return ambulanceService.getAllAmbulances();
    }

    @GetMapping("/{id}")
    public ResponseEntity<Ambulance> getAmbulanceById(@PathVariable Long id) {
        return ambulanceService.getAmbulanceById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public ResponseEntity<Ambulance> createAmbulance(@RequestBody Ambulance ambulance) {
        if (ambulance.getLatitude() == null || ambulance.getLongitude() == null) {
            return ResponseEntity.badRequest().build();
        }
        Ambulance created = ambulanceService.createAmbulance(ambulance);
        return ResponseEntity.ok(created);
    }

    @PutMapping("/{id}")
    public ResponseEntity<Ambulance> updateAmbulance(@PathVariable Long id, @RequestBody Ambulance updatedAmbulance) {
        return ambulanceService.updateAmbulance(id, updatedAmbulance)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }
    @PutMapping("/{id}/location")
    public ResponseEntity<Ambulance> updateAmbulanceLocation(@PathVariable Long id, @RequestBody Ambulance updatedAmbulance) {
        return ambulanceService.updateAmbulanceLocation(id, updatedAmbulance.getLatitude(), updatedAmbulance.getLongitude())
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteAmbulance(@PathVariable Long id) {
        boolean deleted = ambulanceService.deleteAmbulance(id);
        return deleted ? ResponseEntity.noContent().build() : ResponseEntity.notFound().build();
    }
    @PutMapping("/{id}/availability")
    public ResponseEntity<Ambulance> updateAmbulanceAvailability(@PathVariable Long id, @RequestBody Ambulance updatedAmbulance) {
        return ambulanceService.updateAmbulanceAvailability(id, updatedAmbulance.isAvailable())
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

}
