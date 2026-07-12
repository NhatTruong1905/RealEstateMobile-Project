package com.ndnt.services.impl;

import com.ndnt.controlleradvices.exceptions.DuplicateCodeException;
import com.ndnt.converter.PropertyTypeConverter;
import com.ndnt.model.dto.PropertyTypeDTO;
import com.ndnt.model.entity.PropertyTypeEntity;
import com.ndnt.repositories.PropertyTypeRepository;
import com.ndnt.services.PropertyTypeService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;

@Service
@Transactional
public class PropertyTypeServiceImpl implements PropertyTypeService {
    @Autowired
    private PropertyTypeRepository propertyTypeRepository;

    @Autowired
    private PropertyTypeConverter propertyTypeConverter;

    @Override
    public List<PropertyTypeDTO> getPropertyTypes() {
        List<PropertyTypeEntity> propertyTypeEntities = this.propertyTypeRepository.findAll(Sort.by(Sort.Direction.DESC, "id"));

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
        if (propertyTypeDTO.getId() == null) {
            if (this.propertyTypeRepository.existsByCode(propertyTypeDTO.getCode())) {
                throw new DuplicateCodeException("Mã code của loại bất động sản đã tồn tại! Vui lòng thử mã khác");
            }
        }
        this.propertyTypeRepository.save(p);
    }

    @Override
    public void deletePropertyType(int id) {
        this.propertyTypeRepository.deleteById(id);
    }
}
