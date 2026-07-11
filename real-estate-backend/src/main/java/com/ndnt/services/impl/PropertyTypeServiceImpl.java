package com.ndnt.services.impl;

import com.ndnt.converter.PropertyTypeConverter;
import com.ndnt.model.dto.PropertyTypeDTO;
import com.ndnt.model.entity.PropertyTypeEntity;
import com.ndnt.repositories.PropertyTypeRepository;
import com.ndnt.services.PropertyTypeService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

@Service
public class PropertyTypeServiceImpl implements PropertyTypeService {
    @Autowired
    private PropertyTypeRepository propertyTypeRepository;

    @Autowired
    private PropertyTypeConverter propertyTypeConverter;

    @Override
    public List<PropertyTypeDTO> getPropertyTypes() {
        List<PropertyTypeEntity> propertyTypeEntities = this.propertyTypeRepository.findAll();

        List<PropertyTypeDTO> propertyTypeDTOs = new ArrayList<>();
        for (PropertyTypeEntity p : propertyTypeEntities) {
            propertyTypeDTOs.add(this.propertyTypeConverter.toPropertyTypeDTO(p));
        }
        return propertyTypeDTOs;
    }

    @Override
    public PropertyTypeDTO findById(int id) {
        PropertyTypeEntity propertyTypeEntity = this.propertyTypeRepository.findById(id);
        return this.propertyTypeConverter.toPropertyTypeDTO(propertyTypeEntity);
    }

    @Override
    public void createOrUpdatePropertyType(PropertyTypeDTO propertyTypeDTO) {
        PropertyTypeEntity p = this.propertyTypeConverter.toPropertyTypeEntity(propertyTypeDTO);
        this.propertyTypeRepository.save(p);
    }
}
