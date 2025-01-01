package mine.dispatchcoordinationservice.controller;

import mine.dispatchcoordinationservice.dto.DispatchResult;
import mine.dispatchcoordinationservice.dto.EmergencyRequest;
import mine.dispatchcoordinationservice.service.DispatchService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/dispatch")
public class DispatchController {

    private final DispatchService dispatchService;

    public DispatchController(DispatchService dispatchService) {
        this.dispatchService = dispatchService;
    }

    @PostMapping("/emergency")
    public ResponseEntity<DispatchResult> handleEmergency(@RequestBody EmergencyRequest request) {
        DispatchResult result = dispatchService.handleEmergency(request);
        if ("SUCCESS".equals(result.getStatus())) {
            return ResponseEntity.ok(result);
        } else {
            return ResponseEntity.status(404).body(result);
        }
    }
}
