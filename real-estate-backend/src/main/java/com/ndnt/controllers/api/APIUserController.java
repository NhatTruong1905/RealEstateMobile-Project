package com.ndnt.controllers.api;

import com.ndnt.model.dto.UserDTO;
import com.ndnt.model.dto.response.ResponseDTO;
import com.ndnt.services.UserService;
import com.ndnt.utils.JwtUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.Collections;

@RestController
@RequestMapping("/api/secure")
public class APIUserController {
    @Autowired
    private UserService userService;

    @Autowired
    private JwtUtils jwtUtils;

    @GetMapping("/secure/profile")
    public ResponseEntity<?> getProfile(Principal principal) {
        UserDTO user = this.userService.findByUsername(principal.getName());

        ResponseDTO responseDTO = new ResponseDTO();
        responseDTO.setMessage("Success");
        responseDTO.setData(user);
        return ResponseEntity.ok().body(responseDTO);
    }

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
