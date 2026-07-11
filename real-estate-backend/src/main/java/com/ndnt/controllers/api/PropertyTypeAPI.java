package com.ndnt.controllers.api;

import com.ndnt.model.dto.PropertyTypeDTO;
import com.ndnt.model.dto.response.ResponseDTO;
import com.ndnt.services.PropertyTypeService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.BindingResult;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.stream.Collectors;

@RequestMapping("/api/property-type")
@RestController
public class PropertyTypeAPI {
    @Autowired
    private PropertyTypeService propertyTypeService;

    @PostMapping()
    public ResponseEntity<?> createOrUpdatePropertyType(@Valid @RequestBody PropertyTypeDTO propertyTypeDTO, BindingResult bindingResult) {
        if (bindingResult.hasErrors()) {
            List<String> errors = bindingResult.getFieldErrors()
                    .stream()
                    .map(FieldError::getDefaultMessage)
                    .collect(Collectors.toList());
            return ResponseEntity.badRequest().body(errors);
        }

        this.propertyTypeService.createOrUpdatePropertyType(propertyTypeDTO);

        ResponseDTO responseDTO = new ResponseDTO();
        if (propertyTypeDTO.getId() != null) {
            responseDTO.setMessage("Cập nhập loại bất động sản thành công!");
        }else{
            responseDTO.setMessage("Thêm loại bất động sản thành công!");

        }
        responseDTO.setData(propertyTypeDTO);
        return ResponseEntity.ok(responseDTO);
    }
}
