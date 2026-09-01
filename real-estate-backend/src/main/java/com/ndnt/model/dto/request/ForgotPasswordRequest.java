package com.ndnt.model.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ForgotPasswordRequest {
    @NotBlank(message = "Vui lòng nhập Tên đăng nhập, Số điện thoại hoặc Email")
    private String identifier;

    private String email;
}
