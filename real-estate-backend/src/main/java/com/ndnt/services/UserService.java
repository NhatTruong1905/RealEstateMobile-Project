package com.ndnt.services;

import com.ndnt.model.dto.UserDTO;
import com.ndnt.model.entity.UserEntity;
import org.springframework.security.core.userdetails.UserDetailsService;

import java.util.List;

public interface UserService extends UserDetailsService {
    List<UserDTO> getUsers();

    UserDTO findById(Integer id);

    void deleteUser(Integer id);

    void createOrUpdateUser(UserDTO userDTO);
}
