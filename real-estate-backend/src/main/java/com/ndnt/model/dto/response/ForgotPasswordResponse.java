package com.ndnt.model.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ForgotPasswordResponse {
    private String status;

    private String message;
    private String maskedEmail;
    private boolean hasEmail;
    private String identifier;
}
