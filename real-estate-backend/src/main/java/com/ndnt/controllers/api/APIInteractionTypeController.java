package com.ndnt.controllers.api;

import com.ndnt.model.dto.InteractionTypeDTO;
import com.ndnt.model.dto.response.ResponseDTO;
import com.ndnt.services.InteractionTypeService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api")
public class APIInteractionTypeController {
    @Autowired
    private InteractionTypeService interactionTypeService;

    @GetMapping("/interaction-types")
    public ResponseEntity<?> listInteractionTypes() {
        List<InteractionTypeDTO> interactionTypeDTOS = this.interactionTypeService.getInteractionTypes();

        ResponseDTO responseDTO = new ResponseDTO();
        if (interactionTypeDTOS.isEmpty()) {
            responseDTO.setMessage("Danh sách rỗng");
        } else {
            responseDTO.setMessage("Success");
            responseDTO.setData(interactionTypeDTOS);
        }
        return ResponseEntity.ok().body(responseDTO);
    }
}
