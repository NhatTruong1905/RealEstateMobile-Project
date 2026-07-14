package com.ndnt.services;

import com.ndnt.model.dto.RoleDTO;
import com.ndnt.model.entity.RoleEntity;

import java.util.List;

public interface RoleService {
    List<RoleDTO> getRoles();

    RoleDTO findById(Integer id);

    void createOrUpdateRole(RoleDTO roleDTO);

    void deleteRole(Integer id);
}
