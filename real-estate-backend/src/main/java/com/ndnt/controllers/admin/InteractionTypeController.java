package com.ndnt.controllers.admin;

import com.ndnt.model.dto.InteractionTypeDTO;
import com.ndnt.model.dto.PropertyTypeDTO;
import com.ndnt.model.dto.response.ResponseDTO;
import com.ndnt.services.InteractionTypeService;
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
public class InteractionTypeController {
    @Autowired
    private InteractionTypeService interactionTypeService;

    @GetMapping("/interaction-types-list")
    public ModelAndView listInteractionType() {
        ModelAndView mav = new ModelAndView("interaction_type/list");
        mav.addObject("interactionTypes", this.interactionTypeService.getInteractionTypes());

        return mav;
    }

    @GetMapping("/interaction-types-edit")
    public ModelAndView addInteractionType(@ModelAttribute(name = "interactionType") InteractionTypeDTO interactionTypeDTO) {
        return new ModelAndView("interaction_type/edit");
    }

    @GetMapping("/interaction-types-edit-{id}")
    public ModelAndView editInteractionType(@PathVariable Integer id) {
        ModelAndView mav = new ModelAndView("interaction_type/edit");
        mav.addObject("interactionType", this.interactionTypeService.findById(id));
        return mav;
    }

    @PostMapping("/api/interaction-types")
    public ResponseEntity<?> createOrUpdateInteractionType(@Valid @RequestBody InteractionTypeDTO interactionTypeDTO, BindingResult bindingResult) {
        if (bindingResult.hasErrors()) {
            List<String> errors = bindingResult.getFieldErrors()
                    .stream()
                    .map(FieldError::getDefaultMessage)
                    .collect(Collectors.toList());
            return ResponseEntity.badRequest().body(errors);
        }

        this.interactionTypeService.createOrUpdateInteractionType(interactionTypeDTO);

        ResponseDTO responseDTO = new ResponseDTO();
        if (interactionTypeDTO.getId() != null) {
            responseDTO.setMessage("Cập nhập loại tương tác thành công!");
        } else {
            responseDTO.setMessage("Thêm loại tương tác thành công!");

        }
        responseDTO.setData(interactionTypeDTO);
        return ResponseEntity.ok(responseDTO);
    }

    @DeleteMapping("/api/interaction-types/{id}")
    public ResponseEntity<?> deleteInteractionType(@PathVariable Integer id) {
        this.interactionTypeService.deleteInteractionType(id);
        return ResponseEntity.noContent().build();
    }
}
