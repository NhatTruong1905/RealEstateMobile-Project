package com.ndnt.services;

import com.ndnt.model.dto.WardDTO;
import com.ndnt.model.entity.WardEntity;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.util.List;

public interface WardService {
    Page<WardDTO> getWards(Pageable pageable);

    WardDTO findById(Integer id);

    void createOrUpdateWard(WardDTO wardDTO);

    void deleteWard(Integer id);
}
