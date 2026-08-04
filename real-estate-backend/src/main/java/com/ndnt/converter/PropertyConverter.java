package com.ndnt.converter;

import com.ndnt.model.dto.PropertyDTO;
import com.ndnt.model.entity.PropertyEntity;
import com.ndnt.model.entity.PropertyImageEntity;
import org.modelmapper.ModelMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;

@Component
public class PropertyConverter {
    @Autowired
    private ModelMapper modelMapper;

    public PropertyDTO toPropertyDTO(PropertyEntity propertyEntity) {
        PropertyDTO dto = modelMapper.map(propertyEntity, PropertyDTO.class);

        if (propertyEntity.getImages() != null && !propertyEntity.getImages().isEmpty()) {
            List<String> imageUrls = new ArrayList<>();
            for (PropertyImageEntity imageEntity : propertyEntity.getImages()) {
                imageUrls.add(imageEntity.getUrlImage());
            }
            dto.setImages(imageUrls);
        } else {
            dto.setImages(new ArrayList<>());
        }

        return dto;
    }

    public PropertyEntity toPropertyEntity(PropertyDTO propertyDTO) {
        return modelMapper.map(propertyDTO, PropertyEntity.class);
    }
}
