package com.ndnt.converter;

import com.ndnt.model.dto.FavoritePropertyDTO;
import com.ndnt.model.entity.FavoritePropertyEntity;
import org.modelmapper.ModelMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

@Component
public class FavoritePropertyConverter {
    @Autowired
    private ModelMapper modelMapper;

    public FavoritePropertyDTO toFavoritePropertyDTO(FavoritePropertyEntity favoritePropertyEntity) {
        return modelMapper.map(favoritePropertyEntity, FavoritePropertyDTO.class);
    }

    public FavoritePropertyEntity toFavoritePropertyEntity(FavoritePropertyDTO favoritePropertyDTO) {
        return modelMapper.map(favoritePropertyDTO, FavoritePropertyEntity.class);
    }
}
