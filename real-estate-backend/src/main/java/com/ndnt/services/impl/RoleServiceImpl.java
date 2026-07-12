package com.ndnt.services.impl;

import com.ndnt.converter.RoleConverter;
import com.ndnt.model.dto.RoleDTO;
import com.ndnt.model.entity.RoleEntity;
import com.ndnt.repositories.RoleRepository;
import com.ndnt.services.RoleService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@Transactional
public class RoleServiceImpl implements RoleService {
    @Autowired
    private RoleRepository roleRepository;

    @Autowired
    private RoleConverter roleConverter;

    @Override
    public List<RoleDTO> getRoles() {
        return this.roleRepository.findAll().stream().map(r -> this.roleConverter.toRoleDTO(r)).toList();
    }
}
