package com.ndnt.controllers.api;

import com.ndnt.model.dto.PropertyDTO;
import com.ndnt.model.dto.response.ResponseDTO;
import com.ndnt.services.PropertyService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/secure")
public class APIPropertyController {
    @Autowired
    private PropertyService propertyService;

    @GetMapping("/properties")
    public ResponseEntity<?> getProperties() {
        List<PropertyDTO> propertyDTOList = this.propertyService.getProperties();
        ResponseDTO responseDTO = new ResponseDTO();
        responseDTO.setMessage("success");
        responseDTO.setData(propertyDTOList);
        return ResponseEntity.ok().body(responseDTO);
    }
}
