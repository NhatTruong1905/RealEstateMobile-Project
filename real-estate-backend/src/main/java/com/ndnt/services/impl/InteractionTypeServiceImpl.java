package com.ndnt.services.impl;

import com.ndnt.controlleradvices.exceptions.DuplicateCodeException;
import com.ndnt.converter.InteractionTypeConverter;
import com.ndnt.model.dto.InteractionTypeDTO;
import com.ndnt.model.entity.InteractionEntity;
import com.ndnt.model.entity.InteractionTypeEntity;
import com.ndnt.repositories.InteractionTypeRepository;
import com.ndnt.services.InteractionTypeService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

@Service
public class InteractionTypeServiceImpl implements InteractionTypeService {
    @Autowired
    private InteractionTypeRepository interactionTypeRepository;
    @Autowired
    private InteractionTypeConverter interactionTypeConverter;

    @Override
    public List<InteractionTypeDTO> getInteractionTypes() {
        List<InteractionTypeEntity> interactionTypeEntities = interactionTypeRepository.findAll();
        List<InteractionTypeDTO> interactionTypeDTOs = new ArrayList<>();
        for (InteractionTypeEntity iTypeEntity : interactionTypeEntities) {
            InteractionTypeDTO iTypeDTO = this.interactionTypeConverter.toInteractionTypeDTO(iTypeEntity);
            for (InteractionEntity iEntity : iTypeEntity.getInteractionEntities()) {
                iTypeDTO.getInteractionIds().add(iEntity.getId());
            }
            interactionTypeDTOs.add(iTypeDTO);
        }
        return interactionTypeDTOs;
    }

    @Override
    public InteractionTypeDTO findById(int id) {
        return this.interactionTypeConverter.toInteractionTypeDTO(this.interactionTypeRepository.findById(id).get());
    }

    @Override
    public void createOrUpdateInteractionType(InteractionTypeDTO interactionTypeDTO) {
        InteractionTypeEntity i = this.interactionTypeConverter.toInteractionTypeEntity(interactionTypeDTO);
        if (interactionTypeDTO.getId() == null) {
            if (this.interactionTypeRepository.existsByCode(interactionTypeDTO.getCode())) {
                throw new DuplicateCodeException("Mã code của liên lạc đã tồn tại! Vui lòng thử mã khác");
            }
        }
        this.interactionTypeRepository.save(i);
    }

    @Override
    public void deleteInteractionType(int id) {
        this.interactionTypeRepository.deleteById(id);
    }

    @Override
    public String getNameInteractionTypeByCode(String code) {
        return this.interactionTypeRepository.findFirstByCode(code).getName();
    }



}
