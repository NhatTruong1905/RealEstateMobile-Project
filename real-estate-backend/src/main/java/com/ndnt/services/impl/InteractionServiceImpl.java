package com.ndnt.services.impl;

import com.ndnt.converter.InteractionConverter;
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

import java.util.ArrayList;
import java.util.List;

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
        InteractionEntity interactionEntity = this.interactionConverter.toInteractionEntity(interactionDTO);
        this.interactionRepository.save(interactionEntity);
    }

    @Override
    public void deleteInteraction(Integer id) {
        InteractionEntity interactionEntity = this.interactionRepository.findById(id).get();
        interactionEntity.setStatus(0);
        this.interactionRepository.save(interactionEntity);
    }
}
