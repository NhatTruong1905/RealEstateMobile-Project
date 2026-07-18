package com.ndnt.controllers.admin;

import com.ndnt.model.dto.PropertyCategoryDTO;
import com.ndnt.model.dto.PropertyDTO;
import com.ndnt.model.dto.request.PropertyRequestDTO;
import com.ndnt.model.dto.response.ResponseDTO;
import com.ndnt.model.enums.StatusProperty;
import com.ndnt.services.*;
import com.ndnt.utils.SecurityUtils;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.validation.BindingResult;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.ModelAndView;

import java.security.Principal;
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
    @Autowired
    private DistrictService districtService;
    @Autowired
    private AssignmentService assignmentService;


    @GetMapping("/properties-list")
    public ModelAndView listProperty(@RequestParam(defaultValue = "1") int page,
                                     @RequestParam(defaultValue = "8") int size,
                                     @ModelAttribute("search") PropertyRequestDTO searchDTO) {
        ModelAndView mav = new ModelAndView("property/list");
        Pageable pageable = PageRequest.of(page - 1, size, Sort.by("id").descending());

        if (SecurityUtils.getAuthorities().contains("ROLE_STAFF")) {
            String username = SecurityUtils.getPrincipal().getUsername();
            Integer staffId = this.userService.findByUsername(username).getId();
            searchDTO.setStaffId(staffId);
        }
        Page<PropertyDTO> propertyPage = this.propertyService.getProperties(searchDTO, pageable);

        mav.addObject("staffs", this.userService.getListStaff());
        mav.addObject("properties", propertyPage.getContent());
        mav.addObject("currentPage", page);
        mav.addObject("totalPages", propertyPage.getTotalPages());
        mav.addObject("totalItems", propertyPage.getTotalElements());
        mav.addObject("wards", this.wardService.getWards());
        mav.addObject("districts", this.districtService.getAllDistricts());
        mav.addObject("search", searchDTO);

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
        mav.addObject("users", this.userService.getUsers());
        mav.addObject("status", StatusProperty.values());
        return mav;
    }

    @GetMapping("/properties-edit-{id}")
    public ModelAndView editProperty(@PathVariable Integer id) {
        ModelAndView mav = new ModelAndView("property/edit");

        if (SecurityUtils.getAuthorities().contains("ROLE_STAFF")) {
            String username = SecurityUtils.getPrincipal().getUsername();
            Integer staffId = this.userService.findByUsername(username).getId();
            if (!this.assignmentService.isStaffOfProperty(staffId, id)) {
                mav.setViewName("error/error");
                return mav;
            }
        }

        PropertyDTO propertyDTO = this.propertyService.findById(id);
        if (propertyDTO == null) {
            mav.setViewName("error/error");
            return mav;
        }

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
