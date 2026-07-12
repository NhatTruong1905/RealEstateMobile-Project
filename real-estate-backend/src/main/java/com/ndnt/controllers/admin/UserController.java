package com.ndnt.controllers.admin;

import com.ndnt.model.dto.PropertyTypeDTO;
import com.ndnt.model.dto.UserDTO;
import com.ndnt.model.dto.response.ResponseDTO;
import com.ndnt.services.RoleService;
import com.ndnt.services.UserService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.validation.BindingResult;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.ModelAndView;

import java.util.List;
import java.util.stream.Collectors;

@Controller
@RequestMapping("/admin")
public class UserController {
    @Autowired
    private UserService userService;

    @Autowired
    private RoleService roleService;

    @GetMapping("/users-list")
    public ModelAndView listUsers() {
        ModelAndView mav = new ModelAndView("user/list");
        mav.addObject("users", this.userService.getUsers());
        return mav;
    }

    @GetMapping("/users-edit")
    public ModelAndView addUser(@ModelAttribute(name = "user") UserDTO userDTO) {
        ModelAndView mav = new ModelAndView("user/edit");
        mav.addObject("roles", this.roleService.getRoles());
        return mav;
    }

    @GetMapping("/users-edit-{id}")
    public ModelAndView editUser(@PathVariable Integer id) {
        ModelAndView mav = new ModelAndView("user/edit");
        mav.addObject("roles", this.roleService.getRoles());
        mav.addObject("user", this.userService.findById(id));
        return mav;
    }


    @PostMapping("/api/users")
    public ResponseEntity<?> createOrUpdateUser(@Valid @RequestBody UserDTO userDTO, BindingResult bindingResult) {
        if (bindingResult.hasErrors()) {
            List<String> errors = bindingResult.getFieldErrors()
                    .stream()
                    .map(FieldError::getDefaultMessage)
                    .collect(Collectors.toList());
            return ResponseEntity.badRequest().body(errors);
        }

        this.userService.createOrUpdateUser(userDTO);

        ResponseDTO responseDTO = new ResponseDTO();
        if (userDTO.getId() != null) {
            responseDTO.setMessage("Cập nhập khách hàng thành công!");
        } else {
            responseDTO.setMessage("Thêm khách hàng thành công!");

        }
        responseDTO.setData(userDTO);
        return ResponseEntity.ok(responseDTO);
    }

    @DeleteMapping("/api/users/{id}")
    public ResponseEntity<?> deletePropertyType(@PathVariable Integer id) {
        this.userService.deleteUser(id);
        return ResponseEntity.noContent().build();
    }
}
