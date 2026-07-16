package com.ndnt.services;

import com.ndnt.model.dto.PropertyDTO;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.util.List;

public interface PropertyService {
    List<PropertyDTO> getProperties();

    Page<PropertyDTO> getProperties(Pageable pageable);

    PropertyDTO findById(Integer id);

    void createOrUpdateProperty(PropertyDTO propertyDTO);

    void deleteProperty(Integer id);
}
