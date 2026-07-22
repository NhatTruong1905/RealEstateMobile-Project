package com.ndnt.model.dto;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;
import org.springframework.web.multipart.MultipartFile;

@Setter
@Getter
public class UserInfoDTO extends BaseDTO {
    @NotBlank(message = "Tên đăng nhập không được để trống!")
    @Size(min = 3, max = 50, message = "Tên đăng nhập phải từ 3 đến 50 ký tự!")
    private String username;
    @Size(min = 6, message = "Mật khẩu phải từ 6 ký tự trở lên!")
    private String password;
    @Email(message = "Email không đúng định dạng (Ví dụ chuẩn: nguyenvan_a@gmail.com)!")
    private String email;
    @NotBlank(message = "Số điện thoại không được để trống!")
    @Pattern(regexp = "^0\\d{9}$", message = "Số điện thoại không hợp lệ (Phải bắt đầu bằng 0 và đủ 10 số)!")
    private String phone;
    private Integer roleId;
    private String roleName;
    private String roleCode;
    private String avatar;
    @JsonIgnore
    private MultipartFile file;
    private String fullname;
    private Integer status = 1;
}
