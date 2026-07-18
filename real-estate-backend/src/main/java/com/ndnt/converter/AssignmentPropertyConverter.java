package com.ndnt.converter;

import com.ndnt.model.dto.AssignmentDTO;
import com.ndnt.model.entity.AssignmentPropertyEntity;
import org.modelmapper.ModelMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

@Component
public class AssignmentPropertyConverter {
    @Autowired
    private ModelMapper modelMapper;

    public AssignmentDTO toAssignmentDTO(AssignmentPropertyEntity assignmentPropertyEntity) {
        return modelMapper.map(assignmentPropertyEntity, AssignmentDTO.class);
    }

    public AssignmentPropertyEntity toAssignmentEntity(AssignmentDTO assignmentDTO) {
        return modelMapper.map(assignmentDTO, AssignmentPropertyEntity.class);
    }
}
