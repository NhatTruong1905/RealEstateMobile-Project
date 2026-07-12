package com.ndnt.converter;

import com.ndnt.model.dto.PropertyCategoryDTO;
import com.ndnt.model.entity.PropertyCategoryEntity;
import org.modelmapper.ModelMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

@Component
public class PropertyCategoryConverter {
    @Autowired
    private ModelMapper modelMapper;

    public PropertyCategoryDTO toPropertyCategoryDTO(PropertyCategoryEntity propertyCategoryEntity) {
        return modelMapper.map(propertyCategoryEntity, PropertyCategoryDTO.class);
    }

    public PropertyCategoryEntity toPropertyCategoryEntity(PropertyCategoryDTO propertyCategoryDTO) {
        return modelMapper.map(propertyCategoryDTO, PropertyCategoryEntity.class);
    }
}
