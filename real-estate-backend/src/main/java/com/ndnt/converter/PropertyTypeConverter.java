package com.ndnt.converter;

import com.ndnt.model.dto.PropertyTypeDTO;
import com.ndnt.model.entity.PropertyTypeEntity;
import org.modelmapper.ModelMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

@Component
public class PropertyTypeConverter {
    @Autowired
    private ModelMapper modelMapper;

    public PropertyTypeDTO toPropertyTypeDTO(PropertyTypeEntity propertyType) {
        return modelMapper.map(propertyType, PropertyTypeDTO.class);
    }

    public PropertyTypeEntity toPropertyTypeEntity(PropertyTypeDTO propertyTypeDTO) {
        return modelMapper.map(propertyTypeDTO, PropertyTypeEntity.class);
    }
}
