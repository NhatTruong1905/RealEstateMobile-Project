package com.ndnt.controllers.admin;

import com.ndnt.model.dto.AssignmentDTO;
import com.ndnt.model.dto.response.ResponseDTO;
import com.ndnt.services.AssignmentUserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/admin")
public class AssignmentUserController {
    @Autowired
    private AssignmentUserService assignmentUserService;

    @PostMapping("/api/assignment-user")
    public ResponseEntity<?> createOrUpdateAssignment(@RequestBody AssignmentDTO assignmentDTO) {
        this.assignmentUserService.createOrUpdateAssignment(assignmentDTO);
        ResponseDTO responseDTO = new ResponseDTO();
        responseDTO.setMessage("Success");
        responseDTO.setData(assignmentDTO);
        return ResponseEntity.ok().body(responseDTO);
    }

    @GetMapping("/api/assignment-user/{userId}")
    public ResponseEntity<?> getAssignedStaffs(@PathVariable Integer userId) {
        List<Integer> assignedStaffIds = this.assignmentUserService.getAssignedStaffIdsByUser(userId);
        return ResponseEntity.ok(assignedStaffIds);
    }
}
