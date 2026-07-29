package com.ndnt.services;

import com.ndnt.model.dto.InteractionTypeDTO;
import com.ndnt.model.dto.PropertyTypeDTO;

import java.util.List;

public interface InteractionTypeService {
    List<InteractionTypeDTO> getInteractionTypes();

    InteractionTypeDTO findById(int id);

    void createOrUpdateInteractionType(InteractionTypeDTO interactionTypeDTO);

    void deleteInteractionType(int id);

    String getNameInteractionTypeByCode(String code);
}
