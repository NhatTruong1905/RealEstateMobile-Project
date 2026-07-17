package com.ndnt.services;

import com.ndnt.model.dto.InteractionDTO;
import com.ndnt.model.dto.PropertyDTO;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

public interface InteractionService {
    Page<InteractionDTO> getInteractions(Pageable pageable);

    InteractionDTO findById(Integer id);

    void createOrUpdateInteraction(InteractionDTO interactionDTO);

    void deleteInteraction(Integer id);
}
