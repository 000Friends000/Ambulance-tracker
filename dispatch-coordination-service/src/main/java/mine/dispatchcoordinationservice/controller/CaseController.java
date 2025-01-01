package mine.dispatchcoordinationservice.controller;

import mine.dispatchcoordinationservice.model.Case;
import mine.dispatchcoordinationservice.service.CaseService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/cases")
public class CaseController {

    private final CaseService caseService;

    public CaseController(CaseService caseService) {
        this.caseService = caseService;
    }

    @GetMapping
    public List<Case> getAllCases() {
        return caseService.getAllCases();
    }

    @GetMapping("/{id}")
    public ResponseEntity<Case> getCaseById(@PathVariable Integer id) {
        return caseService.getCaseById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PutMapping("/{id}")
    public ResponseEntity<Case> updateCase(@PathVariable Integer id, @RequestBody Case updatedCase) {
        return caseService.getCaseById(id)
                .map(existingCase -> {
                    updatedCase.setId(existingCase.getId());
                    return ResponseEntity.ok(caseService.updateCase(updatedCase));
                })
                .orElse(ResponseEntity.notFound().build());
    }
}
