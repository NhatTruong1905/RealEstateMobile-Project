package com.ndnt.services;

import com.ndnt.model.dto.UserAdminDTO;
import com.ndnt.model.dto.UserDTO;
import com.ndnt.model.dto.UserInfoDTO;
import com.ndnt.model.dto.request.UserRequestDTO;
import com.ndnt.model.entity.UserEntity;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.core.userdetails.UserDetailsService;

import javax.net.ssl.SSLSession;
import java.time.LocalDateTime;
import java.util.Date;
import java.util.List;

public interface UserService extends UserDetailsService {
    Page<UserDTO> getUsers(UserRequestDTO searchDTO, Pageable pageable);

    List<UserDTO> getUsers();

    List<UserDTO> getListStaff();

    UserDTO findById(Integer id);

    void deleteUser(Integer id);

    void createOrUpdateUser(UserAdminDTO userDTO);

    UserDTO findByUsername(String username);

    boolean authenticate(String username, String password);

    void createOrUpdateUser(UserInfoDTO userDTO);


}
