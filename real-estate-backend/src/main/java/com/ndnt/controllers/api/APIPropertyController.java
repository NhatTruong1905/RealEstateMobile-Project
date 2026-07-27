package com.ndnt.controllers.api;

import com.ndnt.model.dto.FavoritePropertyDTO;
import com.ndnt.model.dto.PropertyDTO;
import com.ndnt.model.dto.UserDTO;
import com.ndnt.model.dto.response.ResponseDTO;
import com.ndnt.services.FavoritePropertyService;
import com.ndnt.services.PropertyService;
import com.ndnt.services.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.List;

@RestController
@RequestMapping("/api")
public class APIPropertyController {
    @Autowired
    private PropertyService propertyService;
    @Autowired
    private FavoritePropertyService favoritePropertyService;
    @Autowired
    private UserService userService;

    @GetMapping("/properties")
    public ResponseEntity<?> getProperties() {
        List<PropertyDTO> propertyDTOList = this.propertyService.getPublishedProperties();
        ResponseDTO responseDTO = new ResponseDTO();
        responseDTO.setMessage("success");
        responseDTO.setData(propertyDTOList);
        return ResponseEntity.ok().body(responseDTO);
    }

    @GetMapping("/secure/favorite-properties")
    public ResponseEntity<?> getFavoriteProperties(Principal principal) {
        UserDTO currentUser = this.userService.findByUsername(principal.getName());
        List<PropertyDTO> propertyDTOS = this.propertyService.getFavoritePropertiesByUser(currentUser.getId());

        ResponseDTO responseDTO = new ResponseDTO();
        if (propertyDTOS.isEmpty()) {
            responseDTO.setMessage("Chưa có tin nào được lưu!");
        } else {
            responseDTO.setMessage("success");
            responseDTO.setData(propertyDTOS);
        }
        return ResponseEntity.ok().body(responseDTO);
    }

    @PostMapping("/secure/favorite-properties")
    public ResponseEntity<?> createOrUpdateFavoriteProperty(@RequestBody FavoritePropertyDTO favoritePropertyDTO, Principal principal) {
        UserDTO currentUser = this.userService.findByUsername(principal.getName());
        favoritePropertyDTO.setUserId(currentUser.getId());
        this.favoritePropertyService.createOrUpdateFavoriteProperty(favoritePropertyDTO);
        ResponseDTO responseDTO = new ResponseDTO();
        responseDTO.setMessage("Success");
        responseDTO.setData(favoritePropertyDTO);
        return ResponseEntity.ok().body(responseDTO);
    }
}
