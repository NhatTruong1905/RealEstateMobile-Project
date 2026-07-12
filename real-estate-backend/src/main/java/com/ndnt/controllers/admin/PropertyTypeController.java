package com.ndnt.controllers.admin;

import com.ndnt.model.dto.PropertyTypeDTO;
import com.ndnt.model.dto.response.ResponseDTO;
import com.ndnt.services.PropertyTypeService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.BindingResult;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.ModelAndView;

import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/admin")
public class PropertyTypeController {
    @Autowired
    private PropertyTypeService propertyTypeService;

    @GetMapping("/property-types-list")
    public ModelAndView listPropertyType() {
        ModelAndView mav = new ModelAndView("property_type/list");
        mav.addObject("propertyTypes", this.propertyTypeService.getPropertyTypes());

        return mav;
    }

    @GetMapping("/property-types-edit")
    public ModelAndView addPropertyType(@ModelAttribute(name = "propertyType") PropertyTypeDTO propertyTypeDTO) {
        return new ModelAndView("property_type/edit");
    }

    @GetMapping("/property-types-edit-{id}")
    public ModelAndView editPropertyType(@PathVariable Integer id) {
        ModelAndView mav = new ModelAndView("property_type/edit");
        mav.addObject("propertyType", this.propertyTypeService.findById(id));
        return mav;
    }

    @PostMapping("/api/property-types")
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
        } else {
            responseDTO.setMessage("Thêm loại bất động sản thành công!");

        }
        responseDTO.setData(propertyTypeDTO);
        return ResponseEntity.ok(responseDTO);
    }

    @DeleteMapping("/api/property-types/{id}")
    public ResponseEntity<?> deletePropertyType(@PathVariable Integer id) {
        this.propertyTypeService.deletePropertyType(id);
        return ResponseEntity.noContent().build();
    }
}
