package com.ndnt.services.impl;

import com.ndnt.converter.InteractionConverter;
import com.ndnt.model.dto.ChatMessageDTO;
import com.ndnt.model.dto.InteractionDTO;
import com.ndnt.model.dto.request.InteractionRequestDTO;
import com.ndnt.model.entity.InteractionEntity;
import com.ndnt.model.entity.InteractionTypeEntity;
import com.ndnt.model.entity.PropertyEntity;
import com.ndnt.model.entity.UserEntity;
import com.ndnt.repositories.InteractionRepository;
import com.ndnt.repositories.InteractionTypeRepository;
import com.ndnt.repositories.PropertyRepository;
import com.ndnt.repositories.UserRepository;
import com.ndnt.services.InteractionService;
import jakarta.persistence.criteria.Join;
import jakarta.persistence.criteria.JoinType;
import jakarta.persistence.criteria.Predicate;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

@Service
@Transactional
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
    public Page<InteractionDTO> getInteractions(InteractionRequestDTO searchDTO, Pageable pageable) {
        Specification<InteractionEntity> spec = (root, query, builder) -> {
            List<Predicate> predicates = new ArrayList<>();

            if (searchDTO != null) {
                if (searchDTO.getUsername() != null && !searchDTO.getUsername().trim().isEmpty()) {
                    String usernamePattern = "%" + searchDTO.getUsername().trim() + "%";
                    Predicate usernameInSender = builder.like(root.join("sender").get("username"), usernamePattern);
                    Predicate usernameInReceiver = builder.like(root.join("receiver").get("username"), usernamePattern);
                    predicates.add(builder.or(usernameInSender, usernameInReceiver));
                }
                if (searchDTO.getTitle() != null && !searchDTO.getTitle().trim().isEmpty()) {
                    predicates.add(builder.like(builder.lower(root.get("property").get("title")), "%" + searchDTO.getTitle().trim().toLowerCase() + "%"));
                }
                if (searchDTO.getInteractionTypeId() != null) {
                    predicates.add(builder.equal(root.join("interactionType").get("id"), searchDTO.getInteractionTypeId()));
                }
                if (searchDTO.getStaffId() != null) {
                    predicates.add(builder.equal(root.join("assignmentInteractions").join("staff").get("id"), searchDTO.getStaffId()));
                }
            }

            return builder.and(predicates.toArray(new Predicate[0]));
        };

        return this.interactionRepository.findAll(spec, pageable).map(iEntity -> {
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
        InteractionEntity interactionEntity = new InteractionEntity();

        if (interactionDTO.getId() != null) {
            interactionEntity = this.interactionRepository.findById(interactionDTO.getId()).orElse(new InteractionEntity());
        }

        if (interactionDTO.getPropertyId() != null) {
            PropertyEntity property = this.propertyRepository.findById(interactionDTO.getPropertyId()).orElse(null);
            interactionEntity.setProperty(property);
        }

        if (interactionDTO.getSenderId() != null) {
            UserEntity sender = this.userRepository.findById(interactionDTO.getSenderId()).orElse(null);
            interactionEntity.setSender(sender);
        }

        if (interactionDTO.getReceiverId() != null) {
            UserEntity receiver = this.userRepository.findById(interactionDTO.getReceiverId()).orElse(null);
            interactionEntity.setReceiver(receiver);
        }

        InteractionTypeEntity iTypeEntity = null;
        if (interactionDTO.getInteractionTypeCode() != null && !interactionDTO.getInteractionTypeCode().isEmpty()) {
            iTypeEntity = this.interactionTypeRepository.findFirstByCode(interactionDTO.getInteractionTypeCode());
        }
        if (iTypeEntity == null && interactionDTO.getInteractionTypeId() != null) {
            iTypeEntity = this.interactionTypeRepository.findById(interactionDTO.getInteractionTypeId()).orElse(null);
        }
        if (iTypeEntity == null) {
            iTypeEntity = this.interactionTypeRepository.findById(1).orElse(null);
        }
        interactionEntity.setInteractionType(iTypeEntity);

        if (interactionDTO.getMessage() != null && !interactionDTO.getMessage().isEmpty()) {
            interactionEntity.setMessage(interactionDTO.getMessage());
        } else if (iTypeEntity != null) {
            interactionEntity.setMessage(iTypeEntity.getName());
        }

        if (interactionDTO.getStatus() != null) {
            interactionEntity.setStatus(interactionDTO.getStatus());
        }

        this.interactionRepository.save(interactionEntity);
    }

    @Override
    public void deleteInteraction(Integer id) {
        InteractionEntity interactionEntity = this.interactionRepository.findById(id).get();
        interactionEntity.setStatus(0);
        this.interactionRepository.save(interactionEntity);
    }

    @Override
    public List<InteractionDTO> getInteractionOfSender(Integer propertyId, Integer senderId) {
        List<InteractionEntity> interactionEntities = this.interactionRepository.findByProperty_IdAndSender_Id(propertyId, senderId);

        List<InteractionDTO> interactionDTOs = new ArrayList<>();
        for (InteractionEntity interactionEntity : interactionEntities) {
            interactionDTOs.add(this.interactionConverter.toInteractionDTO(interactionEntity));
        }
        return interactionDTOs;
    }

    @Override
    public List<InteractionDTO> getInteractionsOfReiver(Integer receiverId) {
        List<InteractionEntity> interactionEntities = this.interactionRepository.findByReceiver_IdOrderByIdDesc(receiverId);

        List<InteractionDTO> interactionDTOs = new ArrayList<>();
        for (InteractionEntity interactionEntity : interactionEntities) {
            interactionDTOs.add(this.interactionConverter.toInteractionDTO(interactionEntity));
        }
        return interactionDTOs;
    }

    @Override
    public void saveMessage(ChatMessageDTO chatMessageDTO) {
        if (chatMessageDTO.getPropertyId() == null || chatMessageDTO.getSenderId() == null) {
            return;
        }

        InteractionDTO iDTO = new InteractionDTO();
        iDTO.setMessage(chatMessageDTO.getMessage());
        iDTO.setPropertyId(chatMessageDTO.getPropertyId());
        iDTO.setSenderId(chatMessageDTO.getSenderId());
        iDTO.setReceiverId(chatMessageDTO.getReceiverId());
        iDTO.setInteractionTypeCode("MESSAGE");
        iDTO.setInteractionTypeId(2);

        this.createOrUpdateInteraction(iDTO);
    }

    @Override
    public void viewingCompleted(List<InteractionDTO> interactionDTOs) {
        List<InteractionTypeEntity> types = this.interactionTypeRepository.findByCodeIn(Arrays.asList("MESSAGE", "VIEWING"));

        List<Integer> targetTypeIds = types.stream()
                .map(InteractionTypeEntity::getId)
                .collect(Collectors.toList());

        for (InteractionDTO dto : interactionDTOs) {
            this.interactionRepository.updateStatusToZeroForSpecificTypes(
                    dto.getPropertyId(),
                    dto.getSenderId(),
                    dto.getReceiverId(),
                    targetTypeIds
            );
        }
    }
}
