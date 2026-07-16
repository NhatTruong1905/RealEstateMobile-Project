package com.ndnt.converter;

import com.ndnt.model.dto.AssignmentDTO;
import com.ndnt.model.entity.AssignmentEntity;
import org.modelmapper.ModelMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

@Component
public class AssignmentConverter {
    @Autowired
    private ModelMapper modelMapper;

    public AssignmentDTO toAssignmentDTO(AssignmentEntity assignmentEntity) {
        return modelMapper.map(assignmentEntity, AssignmentDTO.class);
    }

    public AssignmentEntity toAssignmentEntity(AssignmentDTO assignmentDTO) {
        return modelMapper.map(assignmentDTO, AssignmentEntity.class);
    }
}
