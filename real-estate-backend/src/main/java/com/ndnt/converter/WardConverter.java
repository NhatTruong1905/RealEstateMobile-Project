package com.ndnt.converter;

import com.ndnt.model.dto.WardDTO;
import com.ndnt.model.entity.WardEntity;
import org.modelmapper.ModelMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

@Component
public class WardConverter {
    @Autowired
    private ModelMapper modelMapper;

    public WardDTO toWardDTO(WardEntity wardEntity) {
        return modelMapper.map(wardEntity, WardDTO.class);
    }

    public WardEntity toWardEntity(WardDTO wardDTO) {
        return modelMapper.map(wardDTO, WardEntity.class);
    }
}
