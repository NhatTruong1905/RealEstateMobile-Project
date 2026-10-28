package com.ndnt.converter;

import com.ndnt.model.dto.PropertyDTO;
import com.ndnt.model.entity.PropertyEntity;
import org.modelmapper.ModelMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import java.util.ArrayList;

@Component
public class PropertyConverter {
    @Autowired
    private ModelMapper modelMapper;

    public PropertyDTO toPropertyDTO(PropertyEntity propertyEntity) {
        PropertyDTO dto = modelMapper.map(propertyEntity, PropertyDTO.class);

        dto.setImages(new ArrayList<>());

        return dto;
    }
}
