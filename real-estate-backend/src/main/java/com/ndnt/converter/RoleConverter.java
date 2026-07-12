package com.ndnt.converter;

import com.ndnt.model.dto.RoleDTO;
import com.ndnt.model.entity.RoleEntity;
import org.modelmapper.ModelMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

@Component
public class RoleConverter {
    @Autowired
    private ModelMapper modelMapper;

    public RoleDTO toRoleDTO(RoleEntity roleEntity) {
        return modelMapper.map(roleEntity, RoleDTO.class);
    }

    public RoleEntity toRoleEntity(RoleDTO roleDTO) {
        return modelMapper.map(roleDTO, RoleEntity.class);
    }
}
