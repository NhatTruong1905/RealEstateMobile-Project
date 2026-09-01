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
public class VerifyOtpRequest {
    @NotBlank(message = "Vui lòng nhập định danh tài khoản")
    private String identifier;

    @NotBlank(message = "Vui lòng nhập mã OTP 6 số")
    private String otp;

    private String email;
}
