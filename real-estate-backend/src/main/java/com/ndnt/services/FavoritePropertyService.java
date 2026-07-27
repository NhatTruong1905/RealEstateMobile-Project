package com.ndnt.services;

import com.ndnt.model.dto.FavoritePropertyDTO;

import java.util.List;

public interface FavoritePropertyService {
    List<Integer> getFavoritePropertyIdsByUserId(Integer userId);

    void createOrUpdateFavoriteProperty(FavoritePropertyDTO favoritePropertyDTO);
}
