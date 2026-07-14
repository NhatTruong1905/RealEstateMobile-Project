package com.ndnt.services.impl;

import com.ndnt.controlleradvices.exceptions.DuplicateCodeException;
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
        return this.roleRepository.findAll(Sort.by(Sort.Direction.DESC, "id")).stream().map(r -> this.roleConverter.toRoleDTO(r)).toList();
    }

    @Override
    public RoleDTO findById(Integer id) {
        return this.roleConverter.toRoleDTO(this.roleRepository.findById(id).get());
    }

    @Override
    public void createOrUpdateRole(RoleDTO roleDTO) {
        RoleEntity r = this.roleConverter.toRoleEntity(roleDTO);
        if (roleDTO.getId() == null) {
            if (this.roleRepository.existsByCode(roleDTO.getCode())) {
                throw new DuplicateCodeException("Mã code của vai trò hệ thống đã tồn tại! Vui lòng thử mã khác");
            }
        }
        this.roleRepository.save(r);
    }

    @Override
    public void deleteRole(Integer id) {
        this.roleRepository.deleteById(id);
    }
}
