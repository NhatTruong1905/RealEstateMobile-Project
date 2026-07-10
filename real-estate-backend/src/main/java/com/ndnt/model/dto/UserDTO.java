package com.ndnt.model.dto;

import lombok.Getter;
import lombok.Setter;

@Setter
@Getter
public class UserDTO extends BaseDTO {
    private String username;
    private String password;
    private Integer roleId;
    private String roleName;
    private String fullName;
    private String email;
    private String phone;
}
