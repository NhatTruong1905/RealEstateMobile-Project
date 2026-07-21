package com.ndnt.controllers.api;

import com.ndnt.model.dto.UserDTO;
import com.ndnt.services.UserService;
import com.ndnt.utils.JwtUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Collections;

@RestController
@RequestMapping("/api/auth")
public class APILoginController {
    @Autowired
    private UserService userService;
    
    @Autowired
    private JwtUtils jwtUtils;

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody UserDTO userDTO) {
        if (this.userService.authenticate(userDTO.getUsername(), userDTO.getPassword())) {
            try {
                UserDTO fullUserDTO = this.userService.findByUsername(userDTO.getUsername());
                String token = this.jwtUtils.generateToken(fullUserDTO);
                return ResponseEntity.ok().body(Collections.singletonMap("token", token));
            } catch (Exception e) {
                return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("Lỗi khi tạo token");
            }
        }
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Sai thông tin đăng nhập");
    }

}
