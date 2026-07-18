package com.ndnt.controllers.admin;

import com.ndnt.model.dto.AssignmentDTO;
import com.ndnt.model.dto.response.ResponseDTO;
import com.ndnt.services.AssignmentInteractionService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/admin")
public class AssignmentInteractionController {
    @Autowired
    private AssignmentInteractionService assignmentInteractionService;

    @PostMapping("/api/assignment-interaction")
    public ResponseEntity<?> createOrUpdateAssignment(@RequestBody AssignmentDTO assignmentDTO) {
        this.assignmentInteractionService.createOrUpdateAssignment(assignmentDTO);
        ResponseDTO responseDTO = new ResponseDTO();
        responseDTO.setMessage("Success");
        responseDTO.setData(assignmentDTO);
        return ResponseEntity.ok().body(responseDTO);
    }

    @GetMapping("/api/assignment-interaction/{interactionId}")
    public ResponseEntity<?> getAssignedStaffs(@PathVariable Integer interactionId) {
        List<Integer> assignedStaffIds = this.assignmentInteractionService.getAssignedStaffIdsByInteraction(interactionId);
        return ResponseEntity.ok(assignedStaffIds);
    }
}
