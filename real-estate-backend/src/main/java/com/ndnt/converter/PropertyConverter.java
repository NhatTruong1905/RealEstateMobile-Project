package com.ndnt.converter;

import com.ndnt.model.dto.PropertyDTO;
import com.ndnt.model.entity.PropertyEntity;
import org.modelmapper.ModelMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

@Component
public class PropertyConverter {
    @Autowired
    private ModelMapper modelMapper;

    public PropertyDTO toPropertyDTO(PropertyEntity propertyEntity) {
        return modelMapper.map(propertyEntity, PropertyDTO.class);
    }

    public PropertyEntity toPropertyEntity(PropertyDTO propertyDTO) {
        return modelMapper.map(propertyDTO, PropertyEntity.class);
    }
}
