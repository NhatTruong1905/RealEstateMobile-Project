package com.ndnt.services;

import com.ndnt.model.dto.DistrictDTO;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.util.List;

public interface DistrictService {
    Page<DistrictDTO> getDistricts(Pageable pageable);

    List<DistrictDTO> getAllDistricts();

    DistrictDTO findById(Integer id);

    void createOrUpdateDistrict(DistrictDTO districtDTO);

    void deleteDistrict(Integer id);
}
