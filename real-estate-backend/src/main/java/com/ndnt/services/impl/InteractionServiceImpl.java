package com.ndnt.services.impl;

import com.ndnt.converter.InteractionConverter;
import com.ndnt.model.dto.InteractionDTO;
import com.ndnt.model.entity.InteractionEntity;
import com.ndnt.model.entity.InteractionTypeEntity;
import com.ndnt.model.entity.PropertyEntity;
import com.ndnt.model.entity.UserEntity;
import com.ndnt.repositories.InteractionRepository;
import com.ndnt.repositories.InteractionTypeRepository;
import com.ndnt.repositories.PropertyRepository;
import com.ndnt.repositories.UserRepository;
import com.ndnt.services.InteractionService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

@Service
public class InteractionServiceImpl implements InteractionService {
    @Autowired
    private InteractionRepository interactionRepository;
    @Autowired
    private InteractionConverter interactionConverter;
    @Autowired
    private PropertyRepository propertyRepository;
    @Autowired
    private UserRepository userRepository;
    @Autowired
    private InteractionTypeRepository interactionTypeRepository;

    @Override
    public Page<InteractionDTO> getInteractions(Pageable pageable) {
        Page<InteractionEntity> interactionEntities = interactionRepository.findAllByStatus(1, pageable);

        return interactionEntities.map(iEntity -> {
            InteractionDTO iDTO = this.interactionConverter.toInteractionDTO(iEntity);
            iDTO.setPropertyTitle(iEntity.getProperty().getTitle());
            iDTO.setReceiverUsername(iEntity.getReceiver().getUsername());
            iDTO.setSenderUsername(iEntity.getSender().getUsername());
            iDTO.setInteractionTypeName(iEntity.getInteractionType().getCode());
            return iDTO;
        });
    }

    @Override
    public InteractionDTO findById(Integer id) {
        return this.interactionConverter.toInteractionDTO(this.interactionRepository.findById(id).get());
    }

    @Override
    public void createOrUpdateInteraction(InteractionDTO interactionDTO) {
        InteractionEntity interactionEntity = this.interactionConverter.toInteractionEntity(interactionDTO);
//        PropertyEntity propertyEntity = this.propertyRepository.findById(interactionEntity.getProperty().getId()).get();
//        UserEntity senderUserEntity = this.userRepository.findById(interactionEntity.getSender().getId()).get();
//        UserEntity receiverUserEntity = this.userRepository.findById(interactionEntity.getReceiver().getId()).get();
//        InteractionTypeEntity interactionTypeEntity = this.interactionTypeRepository.findById(interactionEntity.getInteractionType().getId()).get();
//
//        interactionEntity.setProperty(propertyEntity);
//        interactionEntity.setSender(senderUserEntity);
//        interactionEntity.setReceiver(receiverUserEntity);
//        interactionEntity.setInteractionType(interactionTypeEntity);
        this.interactionRepository.save(interactionEntity);
    }

    @Override
    public void deleteInteraction(Integer id) {
        InteractionEntity interactionEntity = this.interactionRepository.findById(id).get();
        interactionEntity.setStatus(0);
        this.interactionRepository.save(interactionEntity);
    }
}
