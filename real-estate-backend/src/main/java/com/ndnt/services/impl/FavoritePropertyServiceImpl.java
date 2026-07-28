package com.ndnt.services.impl;

import com.ndnt.converter.FavoritePropertyConverter;
import com.ndnt.model.dto.FavoritePropertyDTO;
import com.ndnt.model.entity.FavoritePropertyEntity;
import com.ndnt.model.entity.PropertyEntity;
import com.ndnt.model.entity.UserEntity;
import com.ndnt.repositories.FavoritePropertyRepository;
import com.ndnt.repositories.PropertyRepository;
import com.ndnt.repositories.UserRepository;
import com.ndnt.services.FavoritePropertyService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Service
@Transactional
public class FavoritePropertyServiceImpl implements FavoritePropertyService {
    @Autowired
    private FavoritePropertyRepository favoritePropertyRepository;
    @Autowired
    private FavoritePropertyConverter favoritePropertyConverter;
    @Autowired
    private PropertyRepository propertyRepository;
    @Autowired
    private UserRepository userRepository;

    @Override
    public List<Integer> getFavoritePropertyIdsByUserId(Integer userId) {
        List<FavoritePropertyEntity> favoritePropertyEntities = this.favoritePropertyRepository.findByUser_Id(userId);

        return favoritePropertyEntities.stream()
                .map(f -> f.getProperty().getId())
                .collect(Collectors.toList());
    }

    @Override
    public void createOrUpdateFavoriteProperty(FavoritePropertyDTO favoritePropertyDTO) {
        if (this.favoritePropertyRepository.existsByUser_Id(favoritePropertyDTO.getUserId())) {
            this.favoritePropertyRepository.deleteAllByUser_Id(favoritePropertyDTO.getUserId());
            this.favoritePropertyRepository.flush();
        }
        UserEntity u = this.userRepository.findById(favoritePropertyDTO.getUserId()).get();
        for (Integer pId : favoritePropertyDTO.getPropertyIds()) {
            PropertyEntity p = this.propertyRepository.findById(pId).get();
            FavoritePropertyEntity favorite = new FavoritePropertyEntity();
            favorite.setProperty(p);
            favorite.setUser(u);
            this.favoritePropertyRepository.save(favorite);
        }
    }


}
