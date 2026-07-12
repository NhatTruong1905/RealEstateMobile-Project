package com.ndnt.controllers.admin;

import com.ndnt.model.dto.PropertyCategoryDTO;
import com.ndnt.model.dto.response.ResponseDTO;
import com.ndnt.services.PropertyCategoryService;
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
public class PropertyCategoryController {
    @Autowired
    private PropertyCategoryService propertyCategoryService;

    @GetMapping("/property-categories-list")
    public ModelAndView listPropertyCategory() {
        ModelAndView mav = new ModelAndView("property_category/list");
        mav.addObject("propertyCategories", this.propertyCategoryService.getPropertyCategories());

        return mav;
    }

    @GetMapping("/property-categories-edit")
    public ModelAndView addPropertyCategory(@ModelAttribute(name = "propertyCategory") PropertyCategoryDTO PropertyCategoryDTO) {
        return new ModelAndView("property_category/edit");
    }

    @GetMapping("/property-categories-edit-{id}")
    public ModelAndView editPropertyCategory(@PathVariable Integer id) {
        ModelAndView mav = new ModelAndView("property_category/edit");
        mav.addObject("propertyCategory", this.propertyCategoryService.findById(id));
        return mav;
    }

    @PostMapping("/api/property-categories")
    public ResponseEntity<?> createOrUpdatePropertyCategory(@Valid @RequestBody PropertyCategoryDTO PropertyCategoryDTO, BindingResult bindingResult) {
        if (bindingResult.hasErrors()) {
            List<String> errors = bindingResult.getFieldErrors()
                    .stream()
                    .map(FieldError::getDefaultMessage)
                    .collect(Collectors.toList());
            return ResponseEntity.badRequest().body(errors);
        }

        this.propertyCategoryService.createOrUpdatePropertyCategory(PropertyCategoryDTO);

        ResponseDTO responseDTO = new ResponseDTO();
        if (PropertyCategoryDTO.getId() != null) {
            responseDTO.setMessage("Cập nhập phân khúc bất động sản thành công!");
        } else {
            responseDTO.setMessage("Thêm phân khúc bất động sản thành công!");

        }
        responseDTO.setData(PropertyCategoryDTO);
        return ResponseEntity.ok(responseDTO);
    }

    @DeleteMapping("/api/property-categories/{id}")
    public ResponseEntity<?> deletePropertyCategory(@PathVariable Integer id) {
        this.propertyCategoryService.deletePropertyCategory(id);
        return ResponseEntity.noContent().build();
    }
}
