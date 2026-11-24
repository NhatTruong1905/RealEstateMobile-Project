package com.ndnt.model.dto;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Digits;
import lombok.Getter;
import lombok.Setter;
import org.springframework.web.multipart.MultipartFile;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

@Setter
@Getter
public class PropertyDTO extends BaseDTO {
    private Long reviewVersion;
    private Integer userId;
    private String userFullname;
    private String userEmail;
    private String userPhone;
    @NotNull(message = "Vui lòng chọn loại hình giao dịch.")
    @Positive(message = "Lựa chọn loại hình giao dịch không hợp lệ. Vui lòng chọn lại.")
    private Integer typeId;
    private String typeName;
    private String typeCode;
    @NotNull(message = "Vui lòng chọn phân khúc bất động sản.")
    @Positive(message = "Lựa chọn phân khúc bất động sản không hợp lệ. Vui lòng chọn lại.")
    private Integer categoryId;
    private String categoryName;
    private String categoryCode;
    @NotBlank(message = "Vui lòng nhập tiêu đề tin đăng.")
    @Size(max = 255, message = "Tiêu đề tin đăng không được vượt quá 255 ký tự.")
    private String title;
    private String description;
    @NotBlank(message = "Vui lòng nhập địa chỉ đầy đủ.")
    @Size(max = 255, message = "Địa chỉ đầy đủ không được vượt quá 255 ký tự.")
    private String address;
    @Size(max = 45, message = "Tỉnh/thành phố không được vượt quá 45 ký tự.")
    private String city;
    @Positive(message = "Lựa chọn phường/xã không hợp lệ. Vui lòng chọn lại.")
    private Integer wardId;
    private String addressDetail;
    @NotNull(message = "Vui lòng nhập giá bất động sản.")
    @Positive(message = "Giá bất động sản phải lớn hơn 0.")
    @Digits(integer = 13, fraction = 2, message = "Giá bất động sản chỉ được có tối đa 13 chữ số phần nguyên và 2 chữ số sau dấu thập phân.")
    private BigDecimal price;
    @NotNull(message = "Vui lòng nhập diện tích.")
    @Positive(message = "Diện tích phải lớn hơn 0.")
    @Digits(integer = 8, fraction = 2, message = "Diện tích chỉ được có tối đa 8 chữ số phần nguyên và 2 chữ số sau dấu thập phân.")
    private BigDecimal area;
    @Min(value = 0, message = "Số tầng không được nhỏ hơn 0.")
    private Integer floorCount;
    @Min(value = 0, message = "Số phòng ngủ không được nhỏ hơn 0.")
    private Integer bedroomCount;
    @Min(value = 0, message = "Số phòng tắm không được nhỏ hơn 0.")
    private Integer bathroomCount;
    @Size(max = 45, message = "Hướng nhà không được vượt quá 45 ký tự.")
    private String direction;
    @NotBlank(message = "Vui lòng nhập thông tin pháp lý.")
    @Size(max = 45, message = "Thông tin pháp lý không được vượt quá 45 ký tự.")
    private String legal;
    private String status;
    @com.fasterxml.jackson.annotation.JsonInclude(com.fasterxml.jackson.annotation.JsonInclude.Include.NON_NULL)
    private String rejectionReason;
    @com.fasterxml.jackson.annotation.JsonInclude(com.fasterxml.jackson.annotation.JsonInclude.Include.NON_NULL)
    private Integer reviewedBy;
    @com.fasterxml.jackson.annotation.JsonInclude(com.fasterxml.jackson.annotation.JsonInclude.Include.NON_NULL)
    private java.util.Date reviewedAt;

    private List<String> images;
    @JsonIgnore
    private List<MultipartFile> files = new ArrayList<>();
    private List<Integer> assignmentIds = new ArrayList<>();
}
