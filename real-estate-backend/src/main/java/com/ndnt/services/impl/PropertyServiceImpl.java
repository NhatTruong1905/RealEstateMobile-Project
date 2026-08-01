package com.ndnt.services.impl;

import com.ndnt.converter.PropertyConverter;
import com.ndnt.model.dto.FavoritePropertyDTO;
import com.ndnt.model.dto.PropertyDTO;
import com.ndnt.model.dto.request.PropertyRequestDTO;
import com.ndnt.model.entity.AssignmentPropertyEntity;
import com.ndnt.model.entity.PropertyEntity;
import com.ndnt.model.enums.StatusProperty;
import com.ndnt.repositories.PropertyRepository;
import com.ndnt.services.FavoritePropertyService;
import com.ndnt.services.PropertyService;
import jakarta.persistence.criteria.Predicate;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

@Service
public class PropertyServiceImpl implements PropertyService {
    @Autowired
    private PropertyRepository propertyRepository;

    @Autowired
    private PropertyConverter propertyConverter;

    @Autowired
    private FavoritePropertyService favoritePropertyService;

    @Override
    public List<PropertyDTO> getProperties() {
        List<PropertyEntity> propertyEntities = propertyRepository.findAll(Sort.by(Sort.Direction.DESC, "id"));

        List<PropertyDTO> propertyDTOs = new ArrayList<>();
        for (PropertyEntity pEntity : propertyEntities) {
            PropertyDTO pDTO = this.propertyConverter.toPropertyDTO(pEntity);
            pDTO.setAddressDetail(pEntity.getAddress() + ", " + pEntity.getWard().getName() + ", " + pEntity.getWard().getDistrict().getName() + ", " + pEntity.getCity());
            if (!pEntity.getAssignments().isEmpty()) {
                for (AssignmentPropertyEntity assignmentPropertyEntity : pEntity.getAssignments()) {
                    pDTO.getAssignmentIds().add(assignmentPropertyEntity.getId());
                }
            }
            propertyDTOs.add(pDTO);
        }
        return propertyDTOs;
    }

    @Override
    public Page<PropertyDTO> getProperties(PropertyRequestDTO searchDTO, Pageable pageable) {
        Specification<PropertyEntity> spec = (root, query, builder) -> {
            List<Predicate> predicates = new ArrayList<>();

            if (searchDTO != null) {
                if (searchDTO.getTitle() != null && !searchDTO.getTitle().isBlank()) {
                    predicates.add(builder.like(root.get("title"), "%" + searchDTO.getTitle().trim() + "%"));
                }
                if (searchDTO.getAddress() != null && !searchDTO.getAddress().isBlank()) {
                    predicates.add(builder.like(root.get("address"), "%" + searchDTO.getAddress().trim() + "%"));
                }
                if (searchDTO.getDirection() != null && !searchDTO.getDirection().isBlank()) {
                    predicates.add(builder.equal(root.get("direction"), searchDTO.getDirection().trim()));
                }
                if (searchDTO.getLegal() != null && !searchDTO.getLegal().isBlank()) {
                    predicates.add(builder.equal(root.get("legal"), searchDTO.getLegal().trim()));
                }
                if (searchDTO.getArea() != null) {
                    predicates.add(builder.equal(root.get("area"), searchDTO.getArea()));
                }
                if (searchDTO.getFloorCount() != null) {
                    predicates.add(builder.equal(root.get("floorCount"), searchDTO.getFloorCount()));
                }
                if (searchDTO.getBedroomCount() != null) {
                    predicates.add(builder.equal(root.get("bedroomCount"), searchDTO.getBedroomCount()));
                }
                if (searchDTO.getBathroomCount() != null) {
                    predicates.add(builder.equal(root.get("bathroomCount"), searchDTO.getBathroomCount()));
                }
                if (searchDTO.getFromPrice() != null) {
                    predicates.add(builder.greaterThanOrEqualTo(root.get("price"), searchDTO.getFromPrice()));
                }
                if (searchDTO.getToPrice() != null) {
                    predicates.add(builder.lessThanOrEqualTo(root.get("price"), searchDTO.getToPrice()));
                }
                if (searchDTO.getWardId() != null) {
                    predicates.add(builder.equal(root.join("ward").get("id"), searchDTO.getWardId()));
                }
                if (searchDTO.getDistrictId() != null) {
                    predicates.add(builder.equal(root.join("ward").join("district").get("id"), searchDTO.getDistrictId()));
                }
                if (searchDTO.getStaffId() != null) {
                    predicates.add(builder.equal(root.join("assignments").join("staff").get("id"), searchDTO.getStaffId()));
                }
                if (searchDTO.getCategoryId() != null) {
                    predicates.add(builder.equal(root.join("category").get("id"), searchDTO.getCategoryId()));
                }
                if (searchDTO.getTypeId() != null) {
                    predicates.add(builder.equal(root.join("type").get("id"), searchDTO.getTypeId()));
                }
                if (searchDTO.getStatus() != null && !searchDTO.getStatus().isBlank()) {
                    predicates.add(builder.like(root.get("status"), "%" + searchDTO.getStatus().trim() + "%"));
                }
            }

            return builder.and(predicates.toArray(new Predicate[0]));
        };

        return this.propertyRepository.findAll(spec, pageable).map(pEntity -> {
            PropertyDTO pDTO = this.propertyConverter.toPropertyDTO(pEntity);

            String address = pEntity.getAddress() != null ? pEntity.getAddress() : "";
            String wardName = (pEntity.getWard() != null) ? pEntity.getWard().getName() : "";
            String city = pEntity.getCity() != null ? pEntity.getCity() : "";
            String districtName = pEntity.getWard().getDistrict().getName() != null ? pEntity.getWard().getDistrict().getName() : "";
            pDTO.setAddressDetail(address + ", " + wardName + ", " + districtName + ", " + city);

            if (pEntity.getAssignments() != null && !pEntity.getAssignments().isEmpty()) {
                for (AssignmentPropertyEntity assignmentPropertyEntity : pEntity.getAssignments()) {
                    pDTO.getAssignmentIds().add(assignmentPropertyEntity.getId());
                }
            }
            return pDTO;
        });
    }

    @Override
    public PropertyDTO findById(Integer id) {
        PropertyEntity propertyEntity = this.propertyRepository.findById(id).get();
        PropertyDTO propertyDTO = this.propertyConverter.toPropertyDTO(propertyEntity);
        propertyDTO.setAddressDetail(propertyEntity.getAddress() + ", " + propertyEntity.getWard().getName() + ", " + propertyEntity.getWard().getDistrict().getName() + ", " + propertyEntity.getCity());

        return propertyDTO;
    }

    @Override
    public void createOrUpdateProperty(PropertyDTO propertyDTO) {
        PropertyEntity pEntity = this.propertyConverter.toPropertyEntity(propertyDTO);
        pEntity.setCity("Hồ Chí Minh");
        this.propertyRepository.save(pEntity);
    }

    @Override
    public void deleteProperty(Integer id) {
        PropertyEntity propertyEntity = this.propertyRepository.findById(id).get();
        propertyEntity.setStatus(StatusProperty.DELETED.getStatus());
        this.propertyRepository.save(propertyEntity);
    }

    @Override
    public List<PropertyDTO> getPropertyOfUser(Integer userId) {
        List<PropertyEntity> propertyEntities = this.propertyRepository.findByUser_Id(userId);

        List<PropertyDTO> propertyDTOs = new ArrayList<>();
        for (PropertyEntity pEntity : propertyEntities) {
            PropertyDTO pDTO = this.propertyConverter.toPropertyDTO(pEntity);
            pDTO.setAddressDetail(pEntity.getAddress() + "," + pEntity.getWard().getName() + "," + pEntity.getWard().getDistrict().getName() + ", " + pEntity.getCity());
            if (!pEntity.getAssignments().isEmpty()) {
                for (AssignmentPropertyEntity assignmentPropertyEntity : pEntity.getAssignments()) {
                    pDTO.getAssignmentIds().add(assignmentPropertyEntity.getId());
                }
            }
            propertyDTOs.add(pDTO);
        }
        return propertyDTOs;
    }

    @Override
    public List<PropertyDTO> getFavoritePropertiesByUser(Integer id) {
        List<Integer> favoritePropertyDTOS = this.favoritePropertyService.getFavoritePropertyIdsByUserId(id);

        List<PropertyEntity> propertyEntities = this.propertyRepository.findById_In(favoritePropertyDTOS);

        List<PropertyDTO> propertyDTOs = new ArrayList<>();
        for (PropertyEntity pEntity : propertyEntities) {
            PropertyDTO pDTO = this.propertyConverter.toPropertyDTO(pEntity);
            pDTO.setAddressDetail(pEntity.getAddress() + "," + pEntity.getWard().getName() + "," + pEntity.getWard().getDistrict().getName() + ", " + pEntity.getCity());
            if (!pEntity.getAssignments().isEmpty()) {
                for (AssignmentPropertyEntity assignmentPropertyEntity : pEntity.getAssignments()) {
                    pDTO.getAssignmentIds().add(assignmentPropertyEntity.getId());
                }
            }
            propertyDTOs.add(pDTO);
        }
        return propertyDTOs;
    }
}
