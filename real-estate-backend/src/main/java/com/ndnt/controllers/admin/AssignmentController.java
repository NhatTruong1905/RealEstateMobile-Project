package com.ndnt.controllers.admin;

import com.ndnt.model.dto.AssignmentDTO;
import com.ndnt.model.dto.response.ResponseDTO;
import com.ndnt.services.AssignmentService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/admin")
public class AssignmentController {
    @Autowired
    private AssignmentService assignmentService;

    @PostMapping("/api/assignment")
    public ResponseEntity<?> createOrUpdateAssignment(@RequestBody AssignmentDTO assignmentDTO) {
        this.assignmentService.createOrUpdateAssignment(assignmentDTO);
        ResponseDTO responseDTO = new ResponseDTO();
        responseDTO.setMessage("Success");
        responseDTO.setData(assignmentDTO);
        return ResponseEntity.ok().body(responseDTO);
    }

    @GetMapping("/api/assignment/{propertyId}")
    public ResponseEntity<?> getAssignedStaffs(@PathVariable Integer propertyId) {
        List<Integer> assignedStaffIds = this.assignmentService.getAssignedStaffIdsByProperty(propertyId);
        return ResponseEntity.ok(assignedStaffIds);
    }
}
