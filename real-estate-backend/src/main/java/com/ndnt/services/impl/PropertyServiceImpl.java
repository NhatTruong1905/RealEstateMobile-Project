package com.ndnt.services.impl;

import com.ndnt.converter.PropertyConverter;
import com.ndnt.model.dto.PropertyDTO;
import com.ndnt.model.entity.AssignmentEntity;
import com.ndnt.model.entity.PropertyEntity;
import com.ndnt.model.enums.StatusProperty;
import com.ndnt.repositories.PropertyRepository;
import com.ndnt.services.PropertyService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

@Service
public class PropertyServiceImpl implements PropertyService {
    @Autowired
    private PropertyRepository propertyRepository;

    @Autowired
    private PropertyConverter propertyConverter;

    @Override
    public List<PropertyDTO> getProperties() {
        List<PropertyEntity> propertyEntities = propertyRepository.findAll(Sort.by(Sort.Direction.DESC, "id"));

        List<PropertyDTO> propertyDTOs = new ArrayList<>();
        for (PropertyEntity pEntity : propertyEntities) {
            PropertyDTO pDTO = this.propertyConverter.toPropertyDTO(pEntity);
            pDTO.setAddressProperty(pEntity.getAddress() + "," + pEntity.getWard().getName() + "," + pEntity.getCity());
            if (!pEntity.getAssignments().isEmpty()) {
                for (AssignmentEntity assignmentEntity : pEntity.getAssignments()) {
                    pDTO.getAssignmentIds().add(assignmentEntity.getId());
                }
            }
            propertyDTOs.add(pDTO);
        }
        return propertyDTOs;
    }

    @Override
    public Page<PropertyDTO> getProperties(Pageable pageable) {
        Page<PropertyEntity> propertyEntities = propertyRepository.findAll(pageable);

        return propertyEntities.map(pEntity -> {
            PropertyDTO pDTO = this.propertyConverter.toPropertyDTO(pEntity);

            String address = pEntity.getAddress() != null ? pEntity.getAddress() : "";
            String wardName = (pEntity.getWard() != null) ? pEntity.getWard().getName() : "";
            String city = pEntity.getCity() != null ? pEntity.getCity() : "";
            pDTO.setAddressProperty(address + ", " + wardName + ", " + city);

            if (pEntity.getAssignments() != null && !pEntity.getAssignments().isEmpty()) {
                for (AssignmentEntity assignmentEntity : pEntity.getAssignments()) {
                    pDTO.getAssignmentIds().add(assignmentEntity.getId());
                }
            }
            return pDTO;
        });
    }

    @Override
    public PropertyDTO findById(Integer id) {
        return this.propertyConverter.toPropertyDTO(this.propertyRepository.findById(id).get());
    }

    @Override
    public void createOrUpdateProperty(PropertyDTO propertyDTO) {
        this.propertyRepository.save(this.propertyConverter.toPropertyEntity(propertyDTO));
    }

    @Override
    public void deleteProperty(Integer id) {
        PropertyEntity propertyEntity = this.propertyRepository.findById(id).get();
        propertyEntity.setStatus(StatusProperty.DELETED.getStatus());
        this.propertyRepository.save(propertyEntity);
    }
}
