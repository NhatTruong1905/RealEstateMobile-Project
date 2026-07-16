package com.ndnt.controllers.admin;

import com.ndnt.model.dto.PropertyCategoryDTO;
import com.ndnt.model.dto.PropertyDTO;
import com.ndnt.model.dto.response.ResponseDTO;
import com.ndnt.model.enums.StatusProperty;
import com.ndnt.services.*;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.BindingResult;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.ModelAndView;

import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/admin")
public class PropertyController {
    @Autowired
    private PropertyService propertyService;
    @Autowired
    private UserService userService;
    @Autowired
    private PropertyCategoryService propertyCategoryService;
    @Autowired
    private PropertyTypeService propertyTypeService;
    @Autowired
    private WardService wardService;


    @GetMapping("/properties-list")
    public ModelAndView listProperty(@RequestParam(defaultValue = "1") int page,
                                     @RequestParam(defaultValue = "8") int size) {
        ModelAndView mav = new ModelAndView("property/list");
        Pageable pageable = PageRequest.of(page - 1, size, Sort.by("id").descending());

        Page<PropertyDTO> propertyPage = this.propertyService.getProperties(pageable);

        mav.addObject("staffs", this.userService.getListStaff());
        mav.addObject("properties", propertyPage.getContent());
        mav.addObject("currentPage", page);
        mav.addObject("totalPages", propertyPage.getTotalPages());
        mav.addObject("totalItems", propertyPage.getTotalElements());

        int windowSize = 5;
        int startPage = Math.max(1, page - windowSize / 2);
        int endPage = Math.min(propertyPage.getTotalPages(), page + windowSize / 2);
        if (endPage - startPage + 1 < windowSize) {
            if (startPage == 1) {
                endPage = Math.min(propertyPage.getTotalPages(), startPage + windowSize - 1);
            } else if (endPage == propertyPage.getTotalPages()) {
                startPage = Math.max(1, endPage - windowSize + 1);
            }
        }
        mav.addObject("startPage", startPage);
        mav.addObject("endPage", endPage);
        return mav;
    }

    @GetMapping("/properties-edit")
    public ModelAndView addProperty(@ModelAttribute(name = "property") PropertyDTO propertyDTO) {
        ModelAndView mav = new ModelAndView("property/edit");
        mav.addObject("users", this.userService.getUsers());
        mav.addObject("types", this.propertyTypeService.getPropertyTypes());
        mav.addObject("categories", this.propertyCategoryService.getPropertyCategories());
        mav.addObject("wards", this.wardService.getWards());
        mav.addObject("status", StatusProperty.values());
        return mav;
    }

    @GetMapping("/properties-edit-{id}")
    public ModelAndView editProperty(@PathVariable Integer id) {
        ModelAndView mav = new ModelAndView("property/edit");
        mav.addObject("users", this.userService.getUsers());
        mav.addObject("types", this.propertyTypeService.getPropertyTypes());
        mav.addObject("categories", this.propertyCategoryService.getPropertyCategories());
        mav.addObject("wards", this.wardService.getWards());
        mav.addObject("property", this.propertyService.findById(id));
        mav.addObject("status", StatusProperty.values());
        return mav;
    }

    @PostMapping("/api/properties")
    public ResponseEntity<?> createOrUpdateProperty(@Valid @RequestBody PropertyDTO propertyDTO, BindingResult bindingResult) {
        if (bindingResult.hasErrors()) {
            List<String> errors = bindingResult.getFieldErrors()
                    .stream()
                    .map(FieldError::getDefaultMessage)
                    .collect(Collectors.toList());
            return ResponseEntity.badRequest().body(errors);
        }

        this.propertyService.createOrUpdateProperty(propertyDTO);

        ResponseDTO responseDTO = new ResponseDTO();
        if (propertyDTO.getId() != null) {
            responseDTO.setMessage("Cập nhập bài đăng thành công!");
        } else {
            responseDTO.setMessage("Thêm bài đăng thành công!");

        }
        responseDTO.setData(propertyDTO);
        return ResponseEntity.ok(responseDTO);
    }

    @DeleteMapping("/api/properties/{id}")
    public ResponseEntity<?> deleteProperty(@PathVariable Integer id) {
        this.propertyService.deleteProperty(id);
        return ResponseEntity.noContent().build();
    }
}
