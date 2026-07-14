package com.ndnt.controllers.admin;

import com.ndnt.model.dto.PropertyTypeDTO;
import com.ndnt.model.dto.UserAdminDTO;
import com.ndnt.model.dto.UserDTO;
import com.ndnt.model.dto.response.ResponseDTO;
import com.ndnt.services.RoleService;
import com.ndnt.services.UserService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.validation.BindingResult;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.ModelAndView;

import java.util.HashMap;
import java.util.Map;

@Controller
@RequestMapping("/admin")
public class UserController {
    @Autowired
    private UserService userService;

    @Autowired
    private RoleService roleService;

    @GetMapping("/users-list")
    public ModelAndView listUsers(@RequestParam(defaultValue = "1") int page,
                                  @RequestParam(defaultValue = "5") int size) {
        ModelAndView mav = new ModelAndView("user/list");
        Pageable pageable = PageRequest.of(page - 1, size, Sort.by("id").descending());
        Page<UserDTO> userPage = this.userService.getUsers(pageable);
        mav.addObject("users", userPage.getContent());
        mav.addObject("currentPage", page);
        mav.addObject("totalPages", userPage.getTotalPages());
        mav.addObject("totalItems", userPage.getTotalElements());

        int windowSize = 5;
        int startPage = Math.max(1, page - windowSize / 2);
        int endPage = Math.min(userPage.getTotalPages(), page + windowSize / 2);

        if (endPage - startPage + 1 < windowSize) {
            if (startPage == 1) {
                endPage = Math.min(userPage.getTotalPages(), startPage + windowSize - 1);
            } else if (endPage == userPage.getTotalPages()) {
                startPage = Math.max(1, endPage - windowSize + 1);
            }
        }
        mav.addObject("startPage", startPage);
        mav.addObject("endPage", endPage);
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


    @PostMapping(path = "/api/users", consumes = MediaType.MULTIPART_FORM_DATA_VALUE,
            produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<?> createOrUpdateUser(@Valid @ModelAttribute(name = "user") UserAdminDTO userDTO, BindingResult bindingResult) {
        if (bindingResult.hasErrors()) {
            Map<String, String> errors = new HashMap<>();
            for (FieldError fieldError : bindingResult.getFieldErrors()) {
                errors.put(fieldError.getField(), fieldError.getDefaultMessage());
            }
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
    public ResponseEntity<?> deleteUser(@PathVariable Integer id) {
        this.userService.deleteUser(id);
        return ResponseEntity.noContent().build();
    }
}
