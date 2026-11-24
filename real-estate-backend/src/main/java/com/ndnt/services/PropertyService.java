package com.ndnt.services;

import com.ndnt.model.dto.PropertyDTO;
import com.ndnt.model.dto.request.PropertyRequestDTO;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.util.List;

public interface PropertyService {
    List<PropertyDTO> getProperties();

    Page<PropertyDTO> getProperties(PropertyRequestDTO propertyRequestDTO, Pageable pageable);

    PropertyDTO findById(Integer id);
    PropertyDTO findOwnedById(Integer id);

    PropertyDTO saveOwnedProperty(PropertyDTO propertyDTO);
    PropertyDTO saveRejectedDraft(PropertyDTO propertyDTO);
    PropertyDTO resubmitOwnedProperty(Integer id);

    void deleteOwnedProperty(Integer id);

    void createOrUpdateProperty(PropertyDTO propertyDTO);

    void deleteProperty(Integer id);

    List<PropertyDTO> getPropertyOfUser(Integer userId);

    Page<PropertyDTO> getPropertyOfUser(Integer userId, Pageable pageable);

    List<PropertyDTO> getFavoritePropertiesByUser(Integer id);
}
