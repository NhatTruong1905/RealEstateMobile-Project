package com.ndnt.controllers.api;

import com.ndnt.model.dto.FavoritePropertyDTO;
import com.ndnt.model.dto.PropertyDTO;
import com.ndnt.model.dto.UserDTO;
import com.ndnt.model.dto.request.PropertyRequestDTO;
import com.ndnt.model.dto.response.ResponseDTO;
import com.ndnt.model.enums.StatusProperty;
import com.ndnt.services.FavoritePropertyService;
import com.ndnt.services.PropertyService;
import com.ndnt.services.UserService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.BindingResult;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

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
    public ResponseEntity<?> getProperties(@ModelAttribute PropertyRequestDTO propertyRequestDTO,
                                           @RequestParam(defaultValue = "1") int page,
                                           @RequestParam(defaultValue = "6") int limit) {
        Pageable pageable = PageRequest.of(page - 1, limit);

        propertyRequestDTO.setStatus(StatusProperty.PUBLISHED.getStatus());
        Page<PropertyDTO> propertyPage = this.propertyService.getProperties(propertyRequestDTO, pageable);

        Map<String, Object> pageData = new HashMap<>();
        pageData.put("content", propertyPage.getContent());
        pageData.put("currentPage", propertyPage.getNumber() + 1);
        pageData.put("totalItems", propertyPage.getTotalElements());
        pageData.put("totalPages", propertyPage.getTotalPages());

        ResponseDTO responseDTO = new ResponseDTO();
        responseDTO.setMessage("Success");
        responseDTO.setData(pageData);

        return ResponseEntity.ok().body(responseDTO);
    }

    @GetMapping("/secure/properties")
    public ResponseEntity<?> getPropertyOfUser(Principal principal) {
        UserDTO currentUser = this.userService.findByUsername(principal.getName());
        if (currentUser == null) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        } else {
            List<PropertyDTO> propertyDTOS = this.propertyService.getPropertyOfUser(currentUser.getId());
            ResponseDTO responseDTO = new ResponseDTO();
            responseDTO.setMessage("Success");
            responseDTO.setData(propertyDTOS);
            return ResponseEntity.ok().body(responseDTO);
        }
    }

    @PostMapping(path = "/secure/properties", consumes = MediaType.MULTIPART_FORM_DATA_VALUE,
            produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<?> updateOrCreateProperty(@Valid @ModelAttribute PropertyDTO propertyDTO, BindingResult bindingResult, Principal principal) {
        if (bindingResult.hasErrors()) {
            List<String> errors = bindingResult.getFieldErrors()
                    .stream()
                    .map(FieldError::getDefaultMessage)
                    .collect(Collectors.toList());
            return ResponseEntity.badRequest().body(errors);
        }

        UserDTO currentUser = this.userService.findByUsername(principal.getName());
        if (currentUser == null) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        } else {
            propertyDTO.setUserId(currentUser.getId());
            ResponseDTO responseDTO = new ResponseDTO();
            this.propertyService.createOrUpdateProperty(propertyDTO);
            responseDTO.setMessage("Success");
            responseDTO.setData(propertyDTO);
            return ResponseEntity.ok().body(responseDTO);
        }
    }

    @GetMapping("/secure/properties/{id}")
    public ResponseEntity<?> getDetailProperty(@PathVariable Integer id) {
        PropertyDTO propertyDTO = this.propertyService.findById(id);

        ResponseDTO responseDTO = new ResponseDTO();
        if (propertyDTO == null) {
            responseDTO.setMessage("Fail");
            return ResponseEntity.badRequest().body(responseDTO);
        }

        responseDTO.setMessage("Success");
        responseDTO.setData(propertyDTO);
        return ResponseEntity.ok().body(responseDTO);
    }

    @DeleteMapping("/secure/properties/{id}")
    public ResponseEntity<?> deleteProperty(@PathVariable Integer id) {
        ResponseDTO responseDTO = new ResponseDTO();

        if (id == null) {
            responseDTO.setMessage("Error");
            return ResponseEntity.badRequest().body(responseDTO);
        } else {
            responseDTO.setMessage("Success");
            this.propertyService.deleteProperty(id);
            return ResponseEntity.ok().body(responseDTO);
        }
    }

    @GetMapping("/secure/favorite-properties")
    public ResponseEntity<?> getFavoriteProperties(Principal principal) {
        UserDTO currentUser = this.userService.findByUsername(principal.getName());
        List<PropertyDTO> propertyDTOS = this.propertyService.getFavoritePropertiesByUser(currentUser.getId());

        ResponseDTO responseDTO = new ResponseDTO();
        if (propertyDTOS.isEmpty()) {
            responseDTO.setMessage("Chưa có tin nào được lưu!");
        } else {
            responseDTO.setMessage("Success");
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
