package com.ndnt.controllers.admin;


import com.ndnt.model.dto.PropertyCategoryDTO;
import com.ndnt.model.dto.RoleDTO;
import com.ndnt.model.dto.response.ResponseDTO;
import com.ndnt.services.RoleService;
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
public class RoleController {
    @Autowired
    private RoleService roleService;

    @GetMapping("/roles-list")
    public ModelAndView listRole() {
        ModelAndView mav = new ModelAndView("role/list");
        mav.addObject("roles", this.roleService.getRoles());

        return mav;
    }

    @GetMapping("/roles-edit")
    public ModelAndView addRole(@ModelAttribute(name = "role") RoleDTO roleDTO) {
        return new ModelAndView("role/edit");
    }

    @GetMapping("/roles-edit-{id}")
    public ModelAndView editRole(@PathVariable Integer id) {
        ModelAndView mav = new ModelAndView("role/edit");
        mav.addObject("role", this.roleService.findById(id));
        return mav;
    }

    @PostMapping("/api/roles")
    public ResponseEntity<?> createOrUpdateRole(@Valid @RequestBody RoleDTO roleDTO, BindingResult bindingResult) {
        if (bindingResult.hasErrors()) {
            List<String> errors = bindingResult.getFieldErrors()
                    .stream()
                    .map(FieldError::getDefaultMessage)
                    .collect(Collectors.toList());
            return ResponseEntity.badRequest().body(errors);
        }

        this.roleService.createOrUpdateRole(roleDTO);

        ResponseDTO responseDTO = new ResponseDTO();
        if (roleDTO.getId() != null) {
            responseDTO.setMessage("Cập nhật vai trò thành công!");
        } else {
            responseDTO.setMessage("Thêm mới vai trò thành công!");

        }
        responseDTO.setData(roleDTO);
        return ResponseEntity.ok(responseDTO);
    }

    @DeleteMapping("/api/roles/{id}")
    public ResponseEntity<?> deleteRole(@PathVariable Integer id) {
        this.roleService.deleteRole(id);
        return ResponseEntity.noContent().build();
    }
}
