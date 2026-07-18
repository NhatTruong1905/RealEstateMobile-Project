package com.ndnt.controllers.admin;

import com.ndnt.model.dto.AssignmentDTO;
import com.ndnt.model.dto.response.ResponseDTO;
import com.ndnt.services.AssignmentPropertyService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/admin")
public class AssignmentPropertyController {
    @Autowired
    private AssignmentPropertyService assignmentPropertyService;

    @PostMapping("/api/assignment")
    public ResponseEntity<?> createOrUpdateAssignment(@RequestBody AssignmentDTO assignmentDTO) {
        this.assignmentPropertyService.createOrUpdateAssignment(assignmentDTO);
        ResponseDTO responseDTO = new ResponseDTO();
        responseDTO.setMessage("Success");
        responseDTO.setData(assignmentDTO);
        return ResponseEntity.ok().body(responseDTO);
    }

    @GetMapping("/api/assignment/{propertyId}")
    public ResponseEntity<?> getAssignedStaffs(@PathVariable Integer propertyId) {
        List<Integer> assignedStaffIds = this.assignmentPropertyService.getAssignedStaffIdsByProperty(propertyId);
        return ResponseEntity.ok(assignedStaffIds);
    }
}
