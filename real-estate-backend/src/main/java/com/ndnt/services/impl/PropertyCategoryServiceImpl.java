package com.ndnt.services.impl;

import com.ndnt.controlleradvices.exceptions.DuplicateCodeException;
import com.ndnt.converter.PropertyCategoryConverter;
import com.ndnt.model.dto.PropertyCategoryDTO;
import com.ndnt.model.dto.PropertyCategoryDTO;
import com.ndnt.model.entity.PropertyCategoryEntity;
import com.ndnt.repositories.PropertyCategoryRepository;
import com.ndnt.services.PropertyCategoryService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;

@Service
@Transactional
public class PropertyCategoryServiceImpl implements PropertyCategoryService {
    @Autowired
    private PropertyCategoryRepository propertyCategoryRepository;

    @Autowired
    private PropertyCategoryConverter propertyCategoryConverter;

    @Override
    public List<PropertyCategoryDTO> getPropertyCategories() {
        List<PropertyCategoryEntity> PropertyCategoryEntities = this.propertyCategoryRepository.findAll(Sort.by(Sort.Direction.DESC, "id"));

        List<PropertyCategoryDTO> PropertyCategoryDTOs = new ArrayList<>();
        for (PropertyCategoryEntity p : PropertyCategoryEntities) {
            PropertyCategoryDTOs.add(this.propertyCategoryConverter.toPropertyCategoryDTO(p));
        }
        return PropertyCategoryDTOs;
    }

    @Override
    public PropertyCategoryDTO findById(int id) {
        PropertyCategoryEntity PropertyCategoryEntity = this.propertyCategoryRepository.findById(id);
        return this.propertyCategoryConverter.toPropertyCategoryDTO(PropertyCategoryEntity);
    }

    @Override
    public void createOrUpdatePropertyCategory(PropertyCategoryDTO propertyCategoryDTO) {
        PropertyCategoryEntity p = this.propertyCategoryConverter.toPropertyCategoryEntity(propertyCategoryDTO);
        if (propertyCategoryDTO.getId() == null) {
            if (this.propertyCategoryRepository.existsByCode(propertyCategoryDTO.getCode())) {
                throw new DuplicateCodeException("Mã code của phân khúc bất động sản đã tồn tại! Vui lòng thử mã khác");
            }
        }
        this.propertyCategoryRepository.save(p);
    }

    @Override
    public void deletePropertyCategory(int id) {
        this.propertyCategoryRepository.deleteById(id);
    }
}
