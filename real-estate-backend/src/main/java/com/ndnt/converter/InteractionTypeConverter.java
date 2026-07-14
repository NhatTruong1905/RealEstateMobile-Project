package com.ndnt.converter;

import com.ndnt.model.dto.InteractionTypeDTO;
import com.ndnt.model.entity.InteractionTypeEntity;
import org.modelmapper.ModelMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

@Component
public class InteractionTypeConverter {
    @Autowired
    private ModelMapper modelMapper;

    public InteractionTypeDTO toInteractionTypeDTO(InteractionTypeEntity interactionTypeEntity) {
        return modelMapper.map(interactionTypeEntity, InteractionTypeDTO.class);
    }

    public InteractionTypeEntity toInteractionTypeEntity(InteractionTypeDTO interactionTypeDTO) {
        return modelMapper.map(interactionTypeDTO, InteractionTypeEntity.class);
    }
}
