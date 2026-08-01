package com.ndnt.services;

import com.ndnt.model.dto.ChatMessageDTO;
import com.ndnt.model.dto.InteractionDTO;
import com.ndnt.model.dto.PropertyDTO;
import com.ndnt.model.dto.request.InteractionRequestDTO;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.util.List;

public interface InteractionService {
    Page<InteractionDTO> getInteractions(InteractionRequestDTO searchDTO, Pageable pageable);

    InteractionDTO findById(Integer id);

    void createOrUpdateInteraction(InteractionDTO interactionDTO);

    void deleteInteraction(Integer id);

    List<InteractionDTO> getInteractionOfSender(Integer propertyId, Integer senderId);

    List<InteractionDTO> getInteractionsOfReiver(Integer receiverId);

    void saveMessage(ChatMessageDTO chatMessageDTO);

    void viewingCompleted(List<InteractionDTO> interactionDTOs);
}
