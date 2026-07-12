package com.ndnt.services;

import com.ndnt.model.dto.PropertyCategoryDTO;
import com.ndnt.model.dto.PropertyTypeDTO;

import java.util.List;

public interface PropertyCategoryService {
    List<PropertyCategoryDTO> getPropertyCategories();

    PropertyCategoryDTO findById(int id);

    void createOrUpdatePropertyCategory(PropertyCategoryDTO propertyCategoryDTO);

    void deletePropertyCategory(int id);
}
