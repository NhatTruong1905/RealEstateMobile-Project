package com.ndnt.converter;

import com.ndnt.model.dto.InteractionDTO;
import com.ndnt.model.entity.InteractionEntity;
import org.modelmapper.ModelMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

@Component
public class InteractionConverter {
    @Autowired
    private ModelMapper modelMapper;

    public InteractionDTO toInteractionDTO(InteractionEntity interactionEntity) {
        return modelMapper.map(interactionEntity, InteractionDTO.class);
    }
}
