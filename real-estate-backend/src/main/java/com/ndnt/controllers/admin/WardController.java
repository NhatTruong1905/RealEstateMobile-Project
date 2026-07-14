package com.ndnt.controllers.admin;

import com.ndnt.model.dto.WardDTO;
import com.ndnt.model.dto.response.ResponseDTO;
import com.ndnt.services.DistrictService;
import com.ndnt.services.WardService;
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
public class WardController {
    @Autowired
    private WardService wardService;

    @Autowired
    private DistrictService districtService;

    @GetMapping("/wards-list")
    public ModelAndView listWard(@RequestParam(defaultValue = "1") int page,
                                 @RequestParam(defaultValue = "10") int size) {
        ModelAndView mav = new ModelAndView("ward/list");
        Pageable pageable = PageRequest.of(page - 1, size);
        Page<WardDTO> wardPage = this.wardService.getWards(pageable);
        mav.addObject("wards", wardPage.getContent());
        mav.addObject("currentPage", page);
        mav.addObject("totalPages", wardPage.getTotalPages());
        mav.addObject("totalItems", wardPage.getTotalElements());

        int windowSize = 5;
        int startPage = Math.max(1, page - windowSize / 2);
        int endPage = Math.min(wardPage.getTotalPages(), page + windowSize / 2);
        if (endPage - startPage + 1 < windowSize) {
            if (startPage == 1) {
                endPage = Math.min(wardPage.getTotalPages(), startPage + windowSize - 1);
            } else if (endPage == wardPage.getTotalPages()) {
                startPage = Math.max(1, endPage - windowSize + 1);
            }
        }

        mav.addObject("startPage", startPage);
        mav.addObject("endPage", endPage);
        return mav;
    }

    @GetMapping("/wards-edit")
    public ModelAndView addWard(@ModelAttribute(name = "ward") WardDTO wardDTO) {
        ModelAndView mav = new ModelAndView("ward/edit");
        mav.addObject("districts", this.districtService.getAllDistricts());
        return mav;
    }

    @GetMapping("/wards-edit-{id}")
    public ModelAndView editWard(@PathVariable Integer id) {
        ModelAndView mav = new ModelAndView("ward/edit");
        mav.addObject("districts", this.districtService.getAllDistricts());
        mav.addObject("ward", this.wardService.findById(id));
        return mav;
    }

    @PostMapping("/api/wards")
    public ResponseEntity<?> createOrUpdateWard(@Valid @RequestBody WardDTO wardDTO, BindingResult bindingResult) {
        if (bindingResult.hasErrors()) {
            List<String> errors = bindingResult.getFieldErrors()
                    .stream()
                    .map(FieldError::getDefaultMessage)
                    .collect(Collectors.toList());
            return ResponseEntity.badRequest().body(errors);
        }

        this.wardService.createOrUpdateWard(wardDTO);

        ResponseDTO responseDTO = new ResponseDTO();
        if (wardDTO.getId() != null) {
            responseDTO.setMessage("Cập nhập Phường/Xã bất động sản thành công!");
        } else {
            responseDTO.setMessage("Thêm Phường/Xã bất động sản thành công!");

        }
        responseDTO.setData(wardDTO);
        return ResponseEntity.ok(responseDTO);
    }

    @DeleteMapping("/api/wards/{id}")
    public ResponseEntity<?> deleteWard(@PathVariable Integer id) {
        this.wardService.deleteWard(id);
        return ResponseEntity.noContent().build();
    }
}
