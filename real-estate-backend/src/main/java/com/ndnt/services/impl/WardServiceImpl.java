package com.ndnt.services.impl;

import com.ndnt.controlleradvices.exceptions.DuplicateCodeException;
import com.ndnt.converter.WardConverter;
import com.ndnt.model.dto.WardDTO;
import com.ndnt.model.entity.WardEntity;
import com.ndnt.repositories.WardRepository;
import com.ndnt.services.WardService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

@Service
public class WardServiceImpl implements WardService {
    @Autowired
    private WardRepository wardRepository;

    @Autowired
    private WardConverter wardConverter;

    @Override
    public Page<WardDTO> getWards(Pageable pageable) {
        Page<WardEntity> wardEntities = wardRepository.findAll(pageable);
        return wardEntities.map(wEntity -> {
            WardDTO wDTO = this.wardConverter.toWardDTO(wEntity);
            wDTO.setDistrictId(wEntity.getDistrict().getId());
            wDTO.setDistrictName(wEntity.getDistrict().getName());
            wDTO.setDistrictCode(wEntity.getDistrict().getCode());
            return wDTO;
        });
    }

    @Override
    public List<WardDTO> getWards() {
        List<WardEntity> wardEntities = wardRepository.findAll();
        List<WardDTO> wardDTOs = new ArrayList<>();
        for (WardEntity wEntity : wardEntities) {
            WardDTO wDTO = this.wardConverter.toWardDTO(wEntity);
            if (wEntity.getDistrict() != null) {
                wDTO.setDistrictId(wEntity.getDistrict().getId());
                wDTO.setDistrictName(wEntity.getDistrict().getName());
                wDTO.setDistrictCode(wEntity.getDistrict().getCode());
            }
            wardDTOs.add(wDTO);
        }
        return wardDTOs;
    }

    @Override
    public WardDTO findById(Integer id) {
        return this.wardConverter.toWardDTO(this.wardRepository.findById(id).get());
    }

    @Override
    public void createOrUpdateWard(WardDTO wardDTO) {
        WardEntity wardEntity = this.wardConverter.toWardEntity(wardDTO);
        if (wardDTO.getId() == null) {
            if (this.wardRepository.existsByCode(wardEntity.getCode())) {
                throw new DuplicateCodeException("Mã code của Phường/Xã đã tồn tại! Vui lòng thử mã khác!");
            }
        }
        this.wardRepository.save(wardEntity);
    }

    @Override
    public void deleteWard(Integer id) {
        this.wardRepository.deleteById(id);
    }
}
