package com.ndnt.model.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;
import org.springframework.web.multipart.MultipartFile;

@Getter @Setter
public class ProfileUpdateDTO {
    @Size(max=255, message="Họ tên tối đa 255 ký tự") private String fullname;
    @Email(message="Email không đúng định dạng") @Size(max=255) private String email;
    @Size(max=50, message="Số điện thoại quá dài") private String phone;
    private MultipartFile file;
}
