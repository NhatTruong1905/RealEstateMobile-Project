package com.ndnt.controllers.admin;

import com.ndnt.model.dto.InteractionDTO;
import com.ndnt.model.dto.PropertyTypeDTO;
import com.ndnt.model.dto.response.ResponseDTO;
import com.ndnt.services.InteractionService;
import com.ndnt.services.InteractionTypeService;
import com.ndnt.services.PropertyService;
import com.ndnt.services.UserService;
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
public class InteractionController {
    @Autowired
    private InteractionService interactionService;

    @Autowired
    private UserService userService;

    @Autowired
    private InteractionTypeService interactionTypeService;

    @Autowired
    private PropertyService propertyService;

    @GetMapping("/interactions-list")
    public ModelAndView listInteraction(@RequestParam(defaultValue = "1") int page,
                                        @RequestParam(defaultValue = "8") int size) {
        ModelAndView mav = new ModelAndView("interaction/list");
        Pageable pageable = PageRequest.of(page - 1, size, Sort.by("id").descending());
        Page<InteractionDTO> interactionPage = this.interactionService.getInteractions(pageable);

        mav.addObject("interactions", interactionPage.getContent());
        mav.addObject("currentPage", page);
        mav.addObject("totalPages", interactionPage.getTotalPages());
        mav.addObject("totalItems", interactionPage.getTotalElements());

        int windowSize = 5;
        int startPage = Math.max(1, page - windowSize / 2);
        int endPage = Math.min(interactionPage.getTotalPages(), page + windowSize / 2);
        if (endPage - startPage + 1 < windowSize) {
            if (startPage == 1) {
                endPage = Math.min(interactionPage.getTotalPages(), startPage + windowSize - 1);
            } else if (endPage == interactionPage.getTotalPages()) {
                startPage = Math.max(1, endPage - windowSize + 1);
            }
        }
        mav.addObject("startPage", startPage);
        mav.addObject("endPage", endPage);
        return mav;
    }

    @GetMapping("/interactions-edit")
    public ModelAndView addInteraction(@ModelAttribute(name = "interaction") InteractionDTO interactionDTO) {
        ModelAndView mav = new ModelAndView("interaction/edit");
        mav.addObject("users", this.userService.getUsers());
        mav.addObject("interactionTypes", this.interactionTypeService.getInteractionTypes());
        mav.addObject("properties", this.propertyService.getProperties());
        return mav;
    }

    @GetMapping("/interactions-edit-{id}")
    public ModelAndView editInteraction(@PathVariable Integer id) {
        ModelAndView mav = new ModelAndView("interaction/edit");
        mav.addObject("interaction", this.interactionService.findById(id));
        mav.addObject("users", this.userService.getUsers());
        mav.addObject("interactionTypes", this.interactionTypeService.getInteractionTypes());
        mav.addObject("properties", this.propertyService.getProperties());
        return mav;
    }

    @PostMapping("/api/interactions")
    public ResponseEntity<?> createOrUpdateInteraction(@Valid @RequestBody InteractionDTO interactionDTO, BindingResult bindingResult) {
        if (bindingResult.hasErrors()) {
            List<String> errors = bindingResult.getFieldErrors()
                    .stream()
                    .map(FieldError::getDefaultMessage)
                    .collect(Collectors.toList());
            return ResponseEntity.badRequest().body(errors);
        }

        this.interactionService.createOrUpdateInteraction(interactionDTO);

        ResponseDTO responseDTO = new ResponseDTO();
        if (interactionDTO.getId() != null) {
            responseDTO.setMessage("Cập nhập lịch sử liên hệ thành công!");
        } else {
            responseDTO.setMessage("Thêm lịch sử liên hệ thành công!");

        }
        responseDTO.setData(interactionDTO);
        return ResponseEntity.ok(responseDTO);
    }

    @DeleteMapping("/api/interactions/{id}")
    public ResponseEntity<?> deleteInteraction(@PathVariable Integer id) {
        this.interactionService.deleteInteraction(id);
        return ResponseEntity.noContent().build();
    }
}
