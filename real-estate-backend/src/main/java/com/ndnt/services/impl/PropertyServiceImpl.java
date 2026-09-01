package com.ndnt.services.impl;

import com.cloudinary.Cloudinary;
import com.cloudinary.utils.ObjectUtils;
import com.ndnt.converter.PropertyConverter;
import com.ndnt.model.dto.AddressParseResult;
import com.ndnt.model.dto.FavoritePropertyDTO;
import com.ndnt.model.dto.PropertyDTO;
import com.ndnt.model.dto.request.PropertyRequestDTO;
import com.ndnt.model.entity.AssignmentPropertyEntity;
import com.ndnt.model.entity.PropertyEntity;
import com.ndnt.model.entity.PropertyImageEntity;
import com.ndnt.model.entity.WardEntity;
import com.ndnt.model.enums.StatusProperty;
import com.ndnt.repositories.PropertyRepository;
import com.ndnt.repositories.WardRepository;
import com.ndnt.services.AddressParseService;
import com.ndnt.services.FavoritePropertyService;
import com.ndnt.services.PropertyService;
import jakarta.persistence.criteria.Predicate;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.logging.Level;
import java.util.logging.Logger;

@Service
@Transactional
public class PropertyServiceImpl implements PropertyService {
    @Autowired
    private PropertyRepository propertyRepository;

    @Autowired
    private PropertyConverter propertyConverter;

    @Autowired
    private FavoritePropertyService favoritePropertyService;

    @Autowired
    private Cloudinary cloudinary;

    @Autowired
    private AddressParseService addressParseService;

    @Autowired
    private WardRepository wardRepository;

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
        String rawAddress = (propertyDTO.getAddressDetail() != null && !propertyDTO.getAddressDetail().isBlank())
                ? propertyDTO.getAddressDetail()
                : propertyDTO.getAddress();

        if (rawAddress != null && !rawAddress.isBlank()) {
            try {
                AddressParseResult parseResult = this.addressParseService.parseAddress(rawAddress);
                if (parseResult != null) {
                    if (parseResult.addressDetail() != null && !parseResult.addressDetail().isBlank()) {
                        propertyDTO.setAddress(parseResult.addressDetail());
                    }

                    if (parseResult.wardName() != null && !parseResult.wardName().isBlank()) {
                        Optional<WardEntity> wardOpt = this.wardRepository.findFirstByMatchingName(parseResult.wardName().trim());
                        wardOpt.ifPresent(wardEntity -> propertyDTO.setWardId(wardEntity.getId()));
                    }

                    if (parseResult.cityName() != null && !parseResult.cityName().isBlank()) {
                        propertyDTO.setCity(parseResult.cityName());
                    }
                }
            } catch (Exception ex) {
                Logger.getLogger(PropertyServiceImpl.class.getName()).log(Level.WARNING, "Không thể phân tích địa chỉ bằng AI, sử dụng dữ liệu mặc định.", ex);
            }
        }

        PropertyEntity pEntity = this.propertyConverter.toPropertyEntity(propertyDTO);

        if (pEntity.getWard() == null && propertyDTO.getWardId() != null) {
            pEntity.setWard(this.wardRepository.findById(propertyDTO.getWardId()).orElse(null));
        }
        if (pEntity.getCity() == null || pEntity.getCity().isBlank()) {
            pEntity.setCity("Hồ Chí Minh");
        }
        if (propertyDTO.getImages() == null) {
            propertyDTO.setImages(new ArrayList<>());
        }

        List<PropertyImageEntity> finalImages = new ArrayList<>();
        boolean hasNewFiles = propertyDTO.getFiles() != null
                && !propertyDTO.getFiles().isEmpty()
                && !propertyDTO.getFiles().get(0).isEmpty();
        if (propertyDTO.getId() != null) {
            if (propertyDTO.getStatus() != null) {
                pEntity.setStatus(propertyDTO.getStatus());
            }
            PropertyEntity oldProperty = this.propertyRepository.findById(propertyDTO.getId()).orElse(null);
            if (oldProperty != null) {
                pEntity.setAssignments(oldProperty.getAssignments());
                if (pEntity.getUser() == null) pEntity.setUser(oldProperty.getUser());
                if (pEntity.getWard() == null) pEntity.setWard(oldProperty.getWard());
                if (pEntity.getType() == null) pEntity.setType(oldProperty.getType());
                if (pEntity.getCategory() == null) pEntity.setCategory(oldProperty.getCategory());

                List<String> keptImageUrls = propertyDTO.getImages();
                if (keptImageUrls != null && !keptImageUrls.isEmpty()) {
                    for (PropertyImageEntity oldImg : oldProperty.getImages()) {
                        if (keptImageUrls.contains(oldImg.getUrlImage())) {
                            oldImg.setProperty(pEntity);
                            finalImages.add(oldImg);
                        }
                    }
                } else if (!hasNewFiles && oldProperty.getImages() != null) {
                    for (PropertyImageEntity oldImg : oldProperty.getImages()) {
                        oldImg.setProperty(pEntity);
                        finalImages.add(oldImg);
                    }
                }
            }
        } else {
            pEntity.setStatus(StatusProperty.PENDING.getStatus());
        }

        if (hasNewFiles) {
            for (MultipartFile file : propertyDTO.getFiles()) {
                try {
                    Map res = this.cloudinary.uploader().upload(file.getBytes(),
                            ObjectUtils.asMap("resource_type", "auto"));
                    String imgUrl = res.get("secure_url").toString();

                    PropertyImageEntity newImage = new PropertyImageEntity();
                    newImage.setUrlImage(imgUrl);
                    newImage.setProperty(pEntity);

                    finalImages.add(newImage);

                    if (!propertyDTO.getImages().contains(imgUrl)) {
                        propertyDTO.getImages().add(imgUrl);
                    }
                } catch (IOException ex) {
                    Logger.getLogger(PropertyServiceImpl.class.getName()).log(Level.SEVERE, "Lỗi upload image", ex);
                    throw new RuntimeException("Lỗi hệ thống: Không thể tải lên ảnh!", ex);
                }
            }
        }

        pEntity.setImages(finalImages);
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
        List<PropertyEntity> propertyEntities = this.propertyRepository.findByUser_IdOrderByIdDesc(userId);

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
