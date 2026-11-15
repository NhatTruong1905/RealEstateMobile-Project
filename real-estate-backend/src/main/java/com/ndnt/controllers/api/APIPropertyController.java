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

    @Autowired
    private com.ndnt.services.PropertyTypeService propertyTypes;
    @Autowired
    private com.ndnt.services.PropertyCategoryService propertyCategories;
    @Autowired
    private com.ndnt.services.WardService wards;

    public record Option(Integer id, String name) {
    }

    public record WardOption(Integer id, String name, String districtName) {
    }

    @GetMapping("/secure/property-options")
    public ResponseEntity<?> options() {
        ResponseDTO response = new ResponseDTO();
        response.setMessage("Success");
        response.setData(Map.of(
                "types", propertyTypes.getPropertyTypes().stream().map(t -> new Option(t.getId(), t.getName())).toList(),
                "categories", propertyCategories.getPropertyCategories().stream().map(c -> new Option(c.getId(), c.getName())).toList(),
                "wards", wards.getWards().stream().map(w -> new WardOption(w.getId(), w.getName(), w.getDistrictName())).toList()));
        return ResponseEntity.ok(response);
    }

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
    public ResponseEntity<?> getPropertyOfUser(Principal principal,
                                               @RequestParam(required = false) Integer page,
                                               @RequestParam(required = false) Integer limit) {
        if ((page != null && page < 1) || (limit != null && (limit < 1 || limit > 100))) {
            return ResponseEntity.badRequest().body(Map.of("message", "page phải từ 1; limit phải từ 1 đến 100."));
        }
        UserDTO currentUser = this.userService.findByUsername(principal.getName());
        if (currentUser == null) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        } else {
            ResponseDTO responseDTO = new ResponseDTO();
            responseDTO.setMessage("Success");
            if (page == null && limit == null) {
                responseDTO.setData(this.propertyService.getPropertyOfUser(currentUser.getId()));
            } else {
                Pageable pageable = PageRequest.of((page == null ? 1 : page) - 1, limit == null ? 6 : limit);
                Page<PropertyDTO> propertyPage = this.propertyService.getPropertyOfUser(currentUser.getId(), pageable);
                responseDTO.setData(Map.of(
                        "content", propertyPage.getContent(),
                        "currentPage", propertyPage.getNumber() + 1,
                        "totalItems", propertyPage.getTotalElements(),
                        "totalPages", propertyPage.getTotalPages()));
            }
            return ResponseEntity.ok().body(responseDTO);
        }
    }

    @PostMapping(path = "/secure/properties", consumes = MediaType.MULTIPART_FORM_DATA_VALUE,
            produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<?> updateOrCreateProperty(@Valid @ModelAttribute PropertyDTO propertyDTO, BindingResult bindingResult, Principal principal) {
        if (bindingResult.hasErrors()) {
            Map<String, String> errors = bindingResult.getFieldErrors().stream()
                    .collect(Collectors.toMap(FieldError::getField, this::propertyValidationMessage,
                            (first, next) -> first, java.util.LinkedHashMap::new));
            ResponseDTO response = new ResponseDTO();
            response.setMessage("Vui lòng kiểm tra các trường được đánh dấu.");
            response.setDetail("VALIDATION_ERROR");
            response.setData(errors);
            return ResponseEntity.badRequest().body(response);
        }

        UserDTO currentUser = this.userService.findByUsername(principal.getName());
        if (currentUser == null) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        } else {
            propertyDTO.setUserId(currentUser.getId());
            ResponseDTO responseDTO = new ResponseDTO();
            propertyDTO = this.propertyService.saveOwnedProperty(propertyDTO);
            responseDTO.setMessage("Success");
            responseDTO.setData(propertyDTO);
            return ResponseEntity.ok().body(responseDTO);
        }
    }

    private String propertyValidationMessage(FieldError error) {
        if (!error.isBindingFailure()) return error.getDefaultMessage();
        return switch (error.getField()) {
            case "price" -> "Giá bất động sản phải là số hợp lệ.";
            case "area" -> "Diện tích phải là số hợp lệ.";
            case "floorCount" -> "Số tầng phải là số nguyên hợp lệ.";
            case "bedroomCount" -> "Số phòng ngủ phải là số nguyên hợp lệ.";
            case "bathroomCount" -> "Số phòng tắm phải là số nguyên hợp lệ.";
            case "typeId" -> "Lựa chọn loại hình giao dịch không hợp lệ. Vui lòng chọn lại.";
            case "categoryId" -> "Lựa chọn phân khúc bất động sản không hợp lệ. Vui lòng chọn lại.";
            case "wardId" -> "Lựa chọn phường/xã không hợp lệ. Vui lòng chọn lại.";
            default -> "Giá trị không hợp lệ. Vui lòng kiểm tra lại.";
        };
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
            this.propertyService.deleteOwnedProperty(id);
            return ResponseEntity.ok().body(responseDTO);
        }
    }

    @GetMapping("/secure/favorite-properties")
    public ResponseEntity<?> getFavoriteProperties(Principal principal) {
        UserDTO currentUser = this.userService.findByUsername(principal.getName());
        if (currentUser == null) throw com.ndnt.services.property.PropertyProblem.forbidden();
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
        if (currentUser == null) throw com.ndnt.services.property.PropertyProblem.forbidden();
        favoritePropertyDTO.setUserId(currentUser.getId());
        if (favoritePropertyDTO.getPropertyIds() == null)
            throw com.ndnt.services.property.PropertyProblem.invalid("propertyIds", "Cần danh sách bài đăng");
        for (Integer propertyId : favoritePropertyDTO.getPropertyIds()) {
            if (propertyId == null)
                throw com.ndnt.services.property.PropertyProblem.invalid("propertyIds", "Mã bài đăng không hợp lệ");
            this.propertyService.findById(propertyId);
        }
        this.favoritePropertyService.createOrUpdateFavoriteProperty(favoritePropertyDTO);
        ResponseDTO responseDTO = new ResponseDTO();
        responseDTO.setMessage("Success");
        responseDTO.setData(favoritePropertyDTO);
        return ResponseEntity.ok().body(responseDTO);
    }
}
