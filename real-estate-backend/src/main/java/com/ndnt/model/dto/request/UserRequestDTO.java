package com.ndnt.model.dto.request;

import lombok.Getter;
import lombok.Setter;

@Setter
@Getter
public class UserRequestDTO {
    private String username;
    private String fullname;
    private String email;
    private String phone;
}
