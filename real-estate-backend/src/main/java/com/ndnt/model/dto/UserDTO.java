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
    private String roleCode;
    private String fullname;
    private String email;
    private String phone;
    private Integer status;
    private String avatar;
}
