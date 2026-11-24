package com.ndnt.services.impl;

import com.ndnt.services.storage.ImageStorageService;
import com.ndnt.converter.PropertyConverter;
import com.ndnt.model.dto.AddressParseResult;
import com.ndnt.model.dto.PropertyDTO;
import com.ndnt.model.dto.request.PropertyRequestDTO;
import com.ndnt.model.entity.PropertyEntity;
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

import java.util.ArrayList;
import java.util.List;
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
    private ImageStorageService imageStorage;

    @Autowired
    private AddressParseService addressParseService;

    @Autowired
    private WardRepository wardRepository;

    @Autowired
    private PropertyAccess access;
    @Autowired
    private PropertyMailOutbox mailOutbox;
    @Autowired
    private PropertyIndexOutbox indexOutbox;
    @Autowired
    private UserRepository users;
    @Autowired
    private PropertyTypeRepository types;
    @Autowired
    private PropertyCategoryRepository categories;

    private PropertyEntity locked(Integer id) {
        return propertyRepository.findLockedById(id).orElseThrow(PropertyProblem::missing);
    }

    private boolean published(PropertyEntity property) {
        return StatusProperty.PUBLISHED.getStatus().equals(property.getStatus());
    }

    private List<Object> indexedFields(PropertyEntity p) {
        return java.util.Arrays.asList(p.getTitle(), p.getDescription(), p.getAddress(), p.getCity(), p.getStatus(),
                p.getLegal(), p.getDirection(), p.getBedroomCount(), p.getBathroomCount(), p.getFloorCount(),
                p.getPrice() == null ? null : p.getPrice().stripTrailingZeros(),
                p.getArea() == null ? null : p.getArea().stripTrailingZeros(),
                p.getWard() == null ? null : p.getWard().getId(), p.getType() == null ? null : p.getType().getId(),
                p.getCategory() == null ? null : p.getCategory().getId());
    }

    private PropertyDTO dto(PropertyEntity entity, boolean privateReview) {
        return dto(entity, privateReview, imageStorage.propertyImages(entity.getId()));
    }

    private PropertyDTO dto(PropertyEntity entity, boolean privateReview, List<String> images) {
        PropertyDTO dto = propertyConverter.toPropertyDTO(entity);
        dto.setImages(images);
        if (privateReview) dto.setReviewVersion(entity.getIndexVersion());
        dto.setAssignmentIds(entity.getAssignments().stream().map(com.ndnt.model.entity.AssignmentPropertyEntity::getId).toList());
        String ward = entity.getWard() == null ? "" : entity.getWard().getName();
        String district = entity.getWard() == null || entity.getWard().getDistrict() == null ? "" : entity.getWard().getDistrict().getName();
        dto.setAddressDetail(Objects.toString(entity.getAddress(), "") + ", " + ward + ", " + district + ", " + Objects.toString(entity.getCity(), ""));
        if (!privateReview) {
            dto.setRejectionReason(null);
            dto.setReviewedAt(null);
            dto.setReviewedBy(null);
        }
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
    public PropertyDTO findOwnedById(Integer id) {
        UserEntity actor = access.actor();
        PropertyEntity property = propertyRepository.findById(id).orElseThrow(PropertyProblem::missing);
        if (!access.owner(actor, property)) throw PropertyProblem.missing();
        return dto(property, true);
    }

    @Override
    public PropertyDTO saveOwnedProperty(PropertyDTO request) {
        return save(request, false, false);
    }

    @Override
    public PropertyDTO saveRejectedDraft(PropertyDTO request) {
        if (request.getId() == null) throw PropertyProblem.invalid("id", "Thiếu mã tin đăng.");
        return save(request, false, true);
    }

    @Override
    public PropertyDTO resubmitOwnedProperty(Integer id) {
        PropertyEntity property = locked(id);
        access.requireOwner(access.actor(), property);
        requireRejected(property);
        property.setStatus(StatusProperty.PENDING.getStatus());
        property.setRejectionReason(null);
        property.setReviewedAt(null);
        property.setReviewedBy(null);
        property.setIndexVersion(property.getIndexVersion() + 1);
        mailOutbox.enqueueResubmission(property);
        indexOutbox.enqueue(property, false);
        return dto(property, true);
    }

    private void requireRejected(PropertyEntity property) {
        if (!StatusProperty.REJECTED.getStatus().equals(property.getStatus())) {
            throw new PropertyProblem(409, "CONFLICT", "Chỉ có thể sửa bản nháp hoặc gửi lại tin bị từ chối.");
        }
    }

    @Override
    public void createOrUpdateProperty(PropertyDTO request) {
        PropertyDTO saved = save(request, true, false);
        BeanUtils.copyProperties(saved, request);
    }

    private String normalizeRejectionReason(String reason) {
        if (reason == null) return "";
        int start = 0, end = reason.length();
        while (start < end && reasonWhitespace(reason.codePointAt(start)))
            start += Character.charCount(reason.codePointAt(start));
        while (end > start && reasonWhitespace(reason.codePointBefore(end)))
            end -= Character.charCount(reason.codePointBefore(end));
        return reason.substring(start, end);
    }

    private boolean reasonWhitespace(int codePoint) {
        return Character.isWhitespace(codePoint) || Character.isSpaceChar(codePoint) || codePoint == 0xFEFF;
    }

    private PropertyDTO save(PropertyDTO request, boolean adminRoute, boolean rejectedDraft) {
        UserEntity actor = access.actor();
        if (adminRoute && !access.hasRole(actor, "ROLE_ADMIN") && !access.hasRole(actor, "ROLE_STAFF"))
            throw PropertyProblem.forbidden();
        boolean create = request.getId() == null;
        PropertyEntity entity = create ? new PropertyEntity() : locked(request.getId());
        List<Object> previousIndexFields = indexedFields(entity);
        if (!create) {
            if (adminRoute) access.requireReviewer(actor, entity);
            else access.requireOwner(actor, entity);
            if (rejectedDraft) requireRejected(entity);
            if (StatusProperty.DELETED.getStatus().equals(entity.getStatus()))
                throw new PropertyProblem(409, "CONFLICT", "Bài đăng đã xóa");
        }
        String desired = request.getStatus();
        boolean decision = adminRoute && !create && desired != null &&
                (StatusProperty.PUBLISHED.getStatus().equals(desired) || StatusProperty.REJECTED.getStatus().equals(desired));
        boolean transitioned = decision && !desired.equals(entity.getStatus());
        if (decision && request.getReviewVersion() != null && request.getReviewVersion() != entity.getIndexVersion()) {
            throw new PropertyProblem(409, "CONFLICT", "Tin đã được cập nhật. Hãy tải lại trước khi xét duyệt.");
        }
        if (adminRoute && !create && desired != null && !desired.equals(entity.getStatus())) {
            if (!decision || !StatusProperty.PENDING.getStatus().equals(entity.getStatus()))
                throw new PropertyProblem(409, "CONFLICT", "Trạng thái không cho phép xét duyệt");
            if (StatusProperty.REJECTED.getStatus().equals(desired)) {
                String reason = normalizeRejectionReason(request.getRejectionReason());
                if (reason.isEmpty() || reason.length() > 1000)
                    throw PropertyProblem.invalid("rejectionReason", "Lý do từ chối phải có từ 1 đến 1000 ký tự");
                entity.setRejectionReason(reason);
            } else entity.setRejectionReason(null);
            entity.setStatus(desired);
            entity.setReviewedBy(actor.getId());
            entity.setReviewedAt(new Date());
        }
        if (create) {

            UserEntity owner = actor;
            if (adminRoute && request.getUserId() != null) {
                owner = users.findById(request.getUserId()).orElseThrow(() -> PropertyProblem.invalid("userId", "Tài khoản không tồn tại"));
            }
            if (!Integer.valueOf(1).equals(owner.getStatus()))
                throw PropertyProblem.invalid("userId", "Tài khoản không hợp lệ");
            entity.setUser(owner);
            entity.setStatus(StatusProperty.PENDING.getStatus());
        }
        Integer wardId = request.getWardId();
        String rawAddress = request.getAddressDetail() != null && !request.getAddressDetail().isBlank() ? request.getAddressDetail() : request.getAddress();
        if (wardId == null && rawAddress != null && !rawAddress.isBlank()) {
            try {
                AddressParseResult parsed = addressParseService.parseAddress(rawAddress);
                if (parsed != null && parsed.wardName() != null) {
                    Optional<WardEntity> ward = wardRepository.findFirstByMatchingName(parsed.wardName().trim());
                    if (ward.isPresent()) wardId = ward.get().getId();
                    if ((request.getCity() == null || request.getCity().isBlank())
                            && parsed.cityName() != null && !parsed.cityName().isBlank())
                        request.setCity(parsed.cityName());
                    if (parsed.addressDetail() != null && !parsed.addressDetail().isBlank())
                        request.setAddress(parsed.addressDetail());
                }
            } catch (Exception ignored) {
            }
        }
        if (wardId == null)
            throw PropertyProblem.invalid("wardId", "Không xác định được phường/xã từ địa chỉ. Vui lòng chọn phường/xã.");
        entity.setWard(wardRepository.findById(wardId).orElseThrow(() -> PropertyProblem.invalid("wardId", "Phường/xã không còn tồn tại. Vui lòng chọn lại.")));
        if (request.getTypeId() == null) throw PropertyProblem.invalid("typeId", "Vui lòng chọn loại hình giao dịch.");
        entity.setType(types.findById(request.getTypeId()).orElseThrow(() -> PropertyProblem.invalid("typeId", "Loại hình giao dịch không còn tồn tại. Vui lòng chọn lại.")));
        if (request.getCategoryId() == null)
            throw PropertyProblem.invalid("categoryId", "Vui lòng chọn phân khúc bất động sản.");
        entity.setCategory(categories.findById(request.getCategoryId()).orElseThrow(() -> PropertyProblem.invalid("categoryId", "Phân khúc bất động sản không còn tồn tại. Vui lòng chọn lại.")));
        entity.setTitle(request.getTitle());
        entity.setDescription(request.getDescription());
        entity.setAddress(request.getAddress());
        entity.setCity(request.getCity() == null || request.getCity().isBlank() ? "Hồ Chí Minh" : request.getCity());
        entity.setPrice(request.getPrice());
        entity.setArea(request.getArea());
        entity.setLegal(request.getLegal());
        entity.setFloorCount(request.getFloorCount());
        entity.setBedroomCount(request.getBedroomCount());
        entity.setBathroomCount(request.getBathroomCount());
        entity.setDirection(request.getDirection());

        boolean indexChanged = create || !previousIndexFields.equals(indexedFields(entity));
        if (!create && indexChanged) entity.setIndexVersion(entity.getIndexVersion() + 1);
        propertyRepository.saveAndFlush(entity);
        List<String> existing = create ? List.of() : imageStorage.propertyImages(entity.getId());
        List<String> retained = existing;
        if (request.getImages() != null) {
            if (!existing.containsAll(request.getImages()))
                throw PropertyProblem.invalid("images", "Ảnh không thuộc bài đăng này");
            retained = existing.stream().filter(request.getImages()::contains).toList();
        }
        List<String> imageUrls = new ArrayList<>(retained);
        imageUrls.addAll(imageStorage.uploadProperty(entity.getId(), request.getFiles(), retained.size()));
        for (String url : existing) if (!retained.contains(url)) imageStorage.retire(url);
        if (create) mailOutbox.enqueue(entity, "RECEIVED");
        else if (transitioned)
            mailOutbox.enqueue(entity, StatusProperty.REJECTED.getStatus().equals(desired) ? "REJECTED" : "APPROVED");
        if (indexChanged) indexOutbox.enqueue(entity, transitioned && published(entity));
        return dto(entity, true, imageUrls);
    }

    @Override
    public void deleteProperty(Integer id) {
        UserEntity actor = access.actor();
        PropertyEntity property = locked(id);
        access.requireReviewer(actor, property);
        property.setStatus(StatusProperty.DELETED.getStatus());
        property.setIndexVersion(property.getIndexVersion() + 1);
        indexOutbox.enqueue(property, false);
    }

    @Override
    public void deleteOwnedProperty(Integer id) {
        UserEntity actor = access.actor();
        PropertyEntity property = locked(id);
        access.requireOwner(actor, property);
        property.setStatus(StatusProperty.DELETED.getStatus());
        property.setIndexVersion(property.getIndexVersion() + 1);
        indexOutbox.enqueue(property, false);
    }

    @Override
    public List<PropertyDTO> getPropertyOfUser(Integer userId) {
        UserEntity actor = access.actor();
        if (!actor.getId().equals(userId)) throw PropertyProblem.forbidden();
        return propertyRepository.findOwnedNewestFirst(userId).stream().map(p -> dto(p, true)).toList();
    }

    @Override
    @Transactional(readOnly = true)
    public Page<PropertyDTO> getPropertyOfUser(Integer userId, Pageable pageable) {
        UserEntity actor = access.actor();
        if (!actor.getId().equals(userId)) throw PropertyProblem.forbidden();
        return propertyRepository.findOwnedNewestFirst(userId, pageable).map(p -> dto(p, true));
    }

    @Override
    public List<PropertyDTO> getFavoritePropertiesByUser(Integer id) {
        UserEntity actor = access.actor();
        if (!actor.getId().equals(id)) throw PropertyProblem.forbidden();
        List<Integer> favorites = favoritePropertyService.getFavoritePropertyIdsByUserId(id);
        return propertyRepository.findById_In(favorites).stream().filter(p -> published(p) || access.owner(actor, p) || access.reviewer(actor, p))
                .map(p -> dto(p, access.owner(actor, p) || access.reviewer(actor, p))).toList();
    }
}
