package com.ndnt.services.impl;

import com.cloudinary.Cloudinary;
import com.cloudinary.utils.ObjectUtils;
import com.ndnt.converter.PropertyConverter;
import com.ndnt.model.dto.AddressParseResult;
import com.ndnt.model.dto.PropertyDTO;
import com.ndnt.model.dto.request.PropertyRequestDTO;
import com.ndnt.model.entity.PropertyEntity;
import com.ndnt.model.entity.PropertyImageEntity;
import com.ndnt.model.entity.WardEntity;
import com.ndnt.model.enums.StatusProperty;
import com.ndnt.repositories.PropertyRepository;
import com.ndnt.repositories.UserRepository;
import com.ndnt.repositories.PropertyTypeRepository;
import com.ndnt.repositories.PropertyCategoryRepository;
import com.ndnt.model.entity.UserEntity;
import com.ndnt.services.property.*;
import java.util.Date;
import java.util.Objects;
import org.springframework.beans.BeanUtils;
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

    @Autowired private PropertyAccess access;
    @Autowired private PropertyMailOutbox mailOutbox;
    @Autowired private UserRepository users;
    @Autowired private PropertyTypeRepository types;
    @Autowired private PropertyCategoryRepository categories;

    private PropertyEntity locked(Integer id) {
        return propertyRepository.findLockedById(id).orElseThrow(PropertyProblem::missing);
    }
    private boolean published(PropertyEntity property) {
        return StatusProperty.PUBLISHED.getStatus().equals(property.getStatus());
    }
    private PropertyDTO dto(PropertyEntity entity, boolean privateReview) {
        PropertyDTO dto = propertyConverter.toPropertyDTO(entity);
        dto.setAssignmentIds(entity.getAssignments().stream().map(com.ndnt.model.entity.AssignmentPropertyEntity::getId).toList());
        String ward = entity.getWard() == null ? "" : entity.getWard().getName();
        String district = entity.getWard() == null || entity.getWard().getDistrict() == null ? "" : entity.getWard().getDistrict().getName();
        dto.setAddressDetail(Objects.toString(entity.getAddress(), "") + ", " + ward + ", " + district + ", " + Objects.toString(entity.getCity(), ""));
        if (!privateReview) { dto.setRejectionReason(null); dto.setReviewedAt(null); dto.setReviewedBy(null); }
        return dto;
    }

    @Override
    public List<PropertyDTO> getProperties() {
        List<PropertyEntity> propertyEntities = propertyRepository.findAll(Sort.by(Sort.Direction.DESC, "id"));

        return propertyEntities.stream().map(p -> dto(p, false)).toList();
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
                    predicates.add(builder.equal(root.get("status"), searchDTO.getStatus().trim()));
                }
            }

            return builder.and(predicates.toArray(new Predicate[0]));
        };

        // Search DTOs never expose review metadata; owner/reviewer detail is the private channel.
        return this.propertyRepository.findAll(spec, pageable).map(p -> dto(p, false));
    }

    @Override
    public PropertyDTO findById(Integer id) {
        UserEntity actor = access.actor();
        PropertyEntity property = propertyRepository.findById(id).orElseThrow(PropertyProblem::missing);
        boolean privateReview = access.owner(actor, property) || access.reviewer(actor, property);
        if (!published(property) && !privateReview) throw PropertyProblem.missing();
        return dto(property, privateReview);
    }

    @Override
    public PropertyDTO saveOwnedProperty(PropertyDTO request) {
        return save(request, false);
    }

    @Override
    public void createOrUpdateProperty(PropertyDTO request) {
        PropertyDTO saved = save(request, true);
        BeanUtils.copyProperties(saved, request);
    }

    private PropertyDTO save(PropertyDTO request, boolean adminRoute) {
        UserEntity actor = access.actor();
        if (adminRoute && !access.hasRole(actor, "ROLE_ADMIN") && !access.hasRole(actor, "ROLE_STAFF"))
            throw PropertyProblem.forbidden();
        boolean create = request.getId() == null;
        PropertyEntity entity = create ? new PropertyEntity() : locked(request.getId());
        if (!create) {
            if (adminRoute) access.requireReviewer(actor, entity); else access.requireOwner(actor, entity);
            if (StatusProperty.DELETED.getStatus().equals(entity.getStatus()))
                throw new PropertyProblem(409, "CONFLICT", "Bài đăng đã xóa");
        }
        String desired = request.getStatus();
        boolean decision = adminRoute && !create && desired != null &&
                (StatusProperty.PUBLISHED.getStatus().equals(desired) || StatusProperty.REJECTED.getStatus().equals(desired));
        boolean transitioned = decision && !desired.equals(entity.getStatus());
        if (adminRoute && !create && desired != null && !desired.equals(entity.getStatus())) {
            if (!decision || !StatusProperty.PENDING.getStatus().equals(entity.getStatus()))
                throw new PropertyProblem(409, "CONFLICT", "Trạng thái không cho phép xét duyệt");
            if (StatusProperty.REJECTED.getStatus().equals(desired)) {
                String reason = request.getRejectionReason() == null ? "" : request.getRejectionReason().trim().strip();
                if (reason.isEmpty() || reason.length() > 1000)
                    throw PropertyProblem.invalid("rejectionReason", "Lý do từ chối phải có từ 1 đến 1000 ký tự");
                entity.setRejectionReason(reason);
            } else entity.setRejectionReason(null);
            entity.setStatus(desired); entity.setReviewedBy(actor.getId()); entity.setReviewedAt(new Date());
        }
        if (create) {
            // Admin retains the ability to create on behalf of a selected account.
            UserEntity owner = actor;
            if (adminRoute && request.getUserId() != null) {
                owner = users.findById(request.getUserId()).orElseThrow(() -> PropertyProblem.invalid("userId", "Tài khoản không tồn tại"));
            }
            if (!Integer.valueOf(1).equals(owner.getStatus())) throw PropertyProblem.invalid("userId", "Tài khoản không hợp lệ");
            entity.setUser(owner); entity.setStatus(StatusProperty.PENDING.getStatus());
        }
        Integer wardId = request.getWardId();
        String rawAddress = request.getAddressDetail() != null && !request.getAddressDetail().isBlank() ? request.getAddressDetail() : request.getAddress();
        if (wardId == null && rawAddress != null && !rawAddress.isBlank()) {
            try {
                AddressParseResult parsed = addressParseService.parseAddress(rawAddress);
                if (parsed != null && parsed.wardName() != null) {
                    Optional<WardEntity> ward = wardRepository.findFirstByMatchingName(parsed.wardName().trim());
                    if (ward.isPresent()) wardId = ward.get().getId();
                    if (parsed.cityName() != null && !parsed.cityName().isBlank()) request.setCity(parsed.cityName());
                    if (parsed.addressDetail() != null && !parsed.addressDetail().isBlank()) request.setAddress(parsed.addressDetail());
                }
            } catch (Exception ignored) { /* Explicit wardId is the safe fallback; do not log address/provider payload. */ }
        }
        if (wardId == null) throw PropertyProblem.invalid("wardId", "Cần phường hợp lệ hoặc địa chỉ có thể xác định phường");
        entity.setWard(wardRepository.findById(wardId).orElseThrow(() -> PropertyProblem.invalid("wardId", "Phường không tồn tại")));
        if (request.getTypeId() == null) throw PropertyProblem.invalid("typeId", "Cần loại hình hợp lệ");
        entity.setType(types.findById(request.getTypeId()).orElseThrow(() -> PropertyProblem.invalid("typeId", "Loại hình không tồn tại")));
        if (request.getCategoryId() == null) throw PropertyProblem.invalid("categoryId", "Cần danh mục hợp lệ");
        entity.setCategory(categories.findById(request.getCategoryId()).orElseThrow(() -> PropertyProblem.invalid("categoryId", "Danh mục không tồn tại")));
        entity.setTitle(request.getTitle()); entity.setDescription(request.getDescription()); entity.setAddress(request.getAddress());
        entity.setCity(request.getCity() == null || request.getCity().isBlank() ? "Hồ Chí Minh" : request.getCity());
        entity.setPrice(request.getPrice()); entity.setArea(request.getArea()); entity.setLegal(request.getLegal());
        entity.setFloorCount(request.getFloorCount()); entity.setBedroomCount(request.getBedroomCount()); entity.setBathroomCount(request.getBathroomCount());
        entity.setDirection(request.getDirection());
        // Retain existing managed images unless an explicit nonempty list chooses a subset.
        if (request.getImages() != null && !request.getImages().isEmpty()) {
            entity.getImages().removeIf(image -> !request.getImages().contains(image.getUrlImage()));
        }
        if (request.getFiles() != null) for (MultipartFile file : request.getFiles()) {
            if (file == null || file.isEmpty()) continue;
            try {
                Map result = cloudinary.uploader().upload(file.getBytes(), ObjectUtils.asMap("resource_type", "auto"));
                PropertyImageEntity image = new PropertyImageEntity();
                image.setUrlImage(result.get("secure_url").toString()); image.setProperty(entity); entity.getImages().add(image);
            } catch (IOException ex) { throw new PropertyProblem(422, "UPLOAD_FAILED", "Không thể tải ảnh lên"); }
        }
        propertyRepository.saveAndFlush(entity);
        if (create) mailOutbox.enqueue(entity, "RECEIVED");
        else if (transitioned) mailOutbox.enqueue(entity, StatusProperty.REJECTED.getStatus().equals(desired) ? "REJECTED" : "APPROVED");
        return dto(entity, true);
    }

    @Override
    public void deleteProperty(Integer id) {
        UserEntity actor = access.actor();
        PropertyEntity property = locked(id); access.requireReviewer(actor, property);
        property.setStatus(StatusProperty.DELETED.getStatus());
    }

    @Override
    public void deleteOwnedProperty(Integer id) {
        UserEntity actor = access.actor();
        PropertyEntity property = locked(id); access.requireOwner(actor, property);
        property.setStatus(StatusProperty.DELETED.getStatus());
    }

    @Override
    public List<PropertyDTO> getPropertyOfUser(Integer userId) {
        UserEntity actor = access.actor();
        if (!actor.getId().equals(userId)) throw PropertyProblem.forbidden();
        return propertyRepository.findByUser_IdOrderByIdDesc(userId).stream().map(p -> dto(p, true)).toList();
    }

    @Override
    public List<PropertyDTO> getFavoritePropertiesByUser(Integer id) {
        UserEntity actor = access.actor();
        if (!actor.getId().equals(id)) throw PropertyProblem.forbidden();
        List<Integer> favorites = favoritePropertyService.getFavoritePropertyIdsByUserId(id);
        return propertyRepository.findById_In(favorites).stream().filter(p -> published(p) || access.owner(actor,p) || access.reviewer(actor,p))
                .map(p -> dto(p, access.owner(actor,p) || access.reviewer(actor,p))).toList();
    }
}
