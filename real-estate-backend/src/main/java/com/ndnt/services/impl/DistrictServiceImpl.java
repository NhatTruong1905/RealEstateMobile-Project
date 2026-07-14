package com.ndnt.services.impl;

import com.ndnt.controlleradvices.exceptions.DuplicateCodeException;
import com.ndnt.converter.DistrictConverter;
import com.ndnt.model.dto.DistrictDTO;
import com.ndnt.model.entity.DistrictEntity;
import com.ndnt.model.entity.WardEntity;
import com.ndnt.repositories.DistrictRepository;
import com.ndnt.repositories.WardRepository;
import com.ndnt.services.DistrictService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

@Service
public class DistrictServiceImpl implements DistrictService {
    @Autowired
    private DistrictRepository districtRepository;

    @Autowired
    private DistrictConverter districtConverter;

    @Override
    public Page<DistrictDTO> getDistricts(Pageable pageable) {
        Page<DistrictEntity> districtEntities = this.districtRepository.findAll(pageable);

        return districtEntities.map(dEntity -> {
            DistrictDTO dDTO = this.districtConverter.toDistrictDTO(dEntity);
            for (WardEntity wEntity : dEntity.getWards()) {
                dDTO.getWardIds().add(wEntity.getId());
            }
            return dDTO;
        });
    }

    @Override
    public List<DistrictDTO> getAllDistricts() {
        List<DistrictEntity> districtEntities = this.districtRepository.findAll();

        List<DistrictDTO> districtDTOs = new ArrayList<>();
        for (DistrictEntity dEntity : districtEntities) {
            DistrictDTO dDTO = this.districtConverter.toDistrictDTO(dEntity);
            for (WardEntity wEntity : dEntity.getWards()) {
                dDTO.getWardIds().add(wEntity.getId());
            }
            districtDTOs.add(dDTO);
        }
        return districtDTOs;
    }

    @Override
    public DistrictDTO findById(Integer id) {
        return this.districtConverter.toDistrictDTO(this.districtRepository.findById(id).get());
    }

    @Override
    public void createOrUpdateDistrict(DistrictDTO districtDTO) {
        DistrictEntity d = this.districtConverter.toDistrictEntity(districtDTO);
        if (districtDTO.getId() == null) {
            if (this.districtRepository.existsByCode(d.getCode())) {
                throw new DuplicateCodeException("Mã code của Quận/Huyện đã tồn tại! Vui lòng thử mã khác!");
            }
        }
        this.districtRepository.save(d);
    }

    @Override
    public void deleteDistrict(Integer id) {
        this.districtRepository.deleteById(id);
    }
}
