package com.ndnt.services;

import com.ndnt.model.dto.PropertyTypeDTO;

import java.util.List;

public interface PropertyTypeService {
    List<PropertyTypeDTO> getPropertyTypes();

    PropertyTypeDTO findById(int id);

    void createOrUpdatePropertyType(PropertyTypeDTO propertyTypeDTO);

    void deletePropertyType(int id);
}
