package com.ndnt.controllers.api;

import com.ndnt.model.dto.UserDTO;
import com.ndnt.model.dto.UserInfoDTO;
import com.ndnt.model.dto.response.ResponseDTO;
import com.ndnt.services.UserService;
import com.ndnt.utils.JwtUtils;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.Collections;

@RestController
@RequestMapping("/api/secure")
public class APIUserController {
    @Autowired
    private UserService userService;

    @GetMapping("/profile")
    public ResponseEntity<?> getProfile(Principal principal) {
        UserDTO user = this.userService.findByUsername(principal.getName());

        ResponseDTO responseDTO = new ResponseDTO();
        responseDTO.setMessage("Success");
        responseDTO.setData(user);
        return ResponseEntity.ok().body(responseDTO);
    }

    @PostMapping(path = "/update/profile", consumes = MediaType.MULTIPART_FORM_DATA_VALUE,
            produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<?> addOrUpdateUser(@Valid @ModelAttribute UserInfoDTO infoDTO, Principal principal) {
        UserDTO currentUser = this.userService.findByUsername(principal.getName());
        infoDTO.setId(currentUser.getId());
        infoDTO.setUsername(currentUser.getUsername());

        this.userService.createOrUpdateUser(infoDTO);
        ResponseDTO responseDTO = new ResponseDTO();
        responseDTO.setMessage("Success");
        return ResponseEntity.ok().body(responseDTO);
    }
}
