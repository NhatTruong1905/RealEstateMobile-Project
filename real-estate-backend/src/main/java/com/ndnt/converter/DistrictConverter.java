package com.ndnt.converter;

import com.ndnt.model.dto.DistrictDTO;
import com.ndnt.model.entity.DistrictEntity;
import org.modelmapper.ModelMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

@Component
public class DistrictConverter {
    @Autowired
    private ModelMapper modelMapper;

    public DistrictDTO toDistrictDTO(DistrictEntity districtEntity) {
        return modelMapper.map(districtEntity, DistrictDTO.class);
    }

    public DistrictEntity toDistrictEntity(DistrictDTO districtDTO) {
        return modelMapper.map(districtDTO, DistrictEntity.class);
    }
}
