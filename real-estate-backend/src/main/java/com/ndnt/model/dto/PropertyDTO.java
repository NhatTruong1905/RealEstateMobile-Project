package com.ndnt.model.dto;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.Getter;
import lombok.Setter;
import org.springframework.web.multipart.MultipartFile;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

@Setter
@Getter
public class PropertyDTO extends BaseDTO {
    private Integer userId;
    private String userFullname;
    private String userEmail;
    private String userPhone;
    private Integer typeId;
    private String typeName;
    private String typeCode;
    private Integer categoryId;
    private String categoryName;
    private String categoryCode;
    @NotBlank(message = "Tựa đề không được trống!")
    private String title;
    private String description;
    @NotBlank(message = "Địa chỉ không được trống!")
    private String address;
    private String city;
    private Integer wardId;
    private String addressDetail;
    @NotNull(message = "Giá không được để trống!")
    @Positive(message = "Giá bất động sản phải lớn hơn 0!")
    private BigDecimal price;
    @NotNull(message = "Diện tích không được để trống!")
    @Positive(message = "Diện tích phải lớn hơn 0!")
    private BigDecimal area;
    private Integer floorCount;
    private Integer bedroomCount;
    private Integer bathroomCount;
    private String direction;
    @NotBlank(message = "Giấy tờ pháp lý không được trống!")
    private String legal;
    private String status;
    private List<String> images = new ArrayList<>();
    @JsonIgnore
    private List<MultipartFile> files = new ArrayList<>();
    private List<Integer> assignmentIds = new ArrayList<>();
}
