package com.ndnt.controllers.admin;

import com.ndnt.model.dto.DistrictDTO;
import com.ndnt.model.dto.PropertyCategoryDTO;
import com.ndnt.model.dto.response.ResponseDTO;
import com.ndnt.services.DistrictService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.validation.BindingResult;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.ModelAndView;

import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/admin")
public class DistrictController {
    @Autowired
    private DistrictService districtService;

    @GetMapping("/districts-list")
    public ModelAndView listDistrict(@RequestParam(defaultValue = "1") int page,
                                     @RequestParam(defaultValue = "10") int size) {
        ModelAndView mav = new ModelAndView("district/list");
        Pageable pageable = PageRequest.of(page - 1, size);
        Page<DistrictDTO> districtPage = this.districtService.getDistricts(pageable);
        mav.addObject("districts", districtPage.getContent());
        mav.addObject("currentPage", page);
        mav.addObject("totalPages", districtPage.getTotalPages());
        mav.addObject("totalItems", districtPage.getTotalElements());

        int windowSize = 5;
        int startPage = Math.max(1, page - windowSize / 2);
        int endPage = Math.min(districtPage.getTotalPages(), page + windowSize / 2);
        if (endPage - startPage + 1 < windowSize) {
            if (startPage == 1) {
                endPage = Math.min(districtPage.getTotalPages(), startPage + windowSize - 1);
            } else if (endPage == districtPage.getTotalPages()) {
                startPage = Math.max(1, endPage - windowSize + 1);
            }
        }

        mav.addObject("startPage", startPage);
        mav.addObject("endPage", endPage);
        return mav;
    }

    @GetMapping("/districts-edit")
    public ModelAndView addDistrict(@ModelAttribute(name = "district") DistrictDTO districtDTO) {
        return new ModelAndView("district/edit");
    }

    @GetMapping("/districts-edit-{id}")
    public ModelAndView editDistrict(@PathVariable Integer id) {
        ModelAndView mav = new ModelAndView("district/edit");
        mav.addObject("district", this.districtService.findById(id));
        return mav;
    }

    @PostMapping("/api/districts")
    public ResponseEntity<?> createOrUpdateDistrict(@Valid @RequestBody DistrictDTO districtDTO, BindingResult bindingResult) {
        if (bindingResult.hasErrors()) {
            List<String> errors = bindingResult.getFieldErrors()
                    .stream()
                    .map(FieldError::getDefaultMessage)
                    .collect(Collectors.toList());
            return ResponseEntity.badRequest().body(errors);
        }

        this.districtService.createOrUpdateDistrict(districtDTO);

        ResponseDTO responseDTO = new ResponseDTO();
        if (districtDTO.getId() != null) {
            responseDTO.setMessage("Cập nhập Quận/Huyện bất động sản thành công!");
        } else {
            responseDTO.setMessage("Thêm Quận/Huyện bất động sản thành công!");

        }
        responseDTO.setData(districtDTO);
        return ResponseEntity.ok(responseDTO);
    }

    @DeleteMapping("/api/districts/{id}")
    public ResponseEntity<?> deleteDistrict(@PathVariable Integer id) {
        this.districtService.deleteDistrict(id);
        return ResponseEntity.noContent().build();
    }
}
