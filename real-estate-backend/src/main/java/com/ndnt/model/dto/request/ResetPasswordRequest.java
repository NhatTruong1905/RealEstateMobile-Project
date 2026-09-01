package com.ndnt.model.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ResetPasswordRequest {
    @NotBlank(message = "Vui lòng nhập định danh tài khoản")
    private String identifier;

    @NotBlank(message = "Mã xác thực đặt lại mật khẩu không hợp lệ")
    private String resetToken;

    @NotBlank(message = "Vui lòng nhập mật khẩu mới")
    @Size(min = 6, message = "Mật khẩu mới phải có ít nhất 6 ký tự")
    private String newPassword;

    private String email;
}
