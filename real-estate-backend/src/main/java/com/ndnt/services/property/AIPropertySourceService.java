package com.ndnt.services.property;

import com.ndnt.model.entity.PropertyEntity;
import com.ndnt.model.enums.StatusProperty;
import com.ndnt.repositories.PropertyRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.TreeMap;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class AIPropertySourceService {
    private final PropertyRepository properties;

    public Optional<Map<String, Object>> findById(Integer id) {
        return properties.findById(id).map(this::record);
    }

    public List<Map<String, Object>> page(Integer after, Integer limit) {
        return properties.indexPage(after, PageRequest.of(0, limit)).stream().map(this::record).toList();
    }

    public List<Map<String, Object>> resolve(List<Integer> ids) {
        return properties.findById_In(ids).stream().map(this::record).toList();
    }

    private Map<String, Object> record(PropertyEntity p) {
        boolean visible = StatusProperty.PUBLISHED.getStatus().equals(p.getStatus());
        if (!visible) return Map.of("id", p.getId().toString(), "version", p.getIndexVersion(),
                "public", false, "text", "", "metadata", Map.of());
        String ward = p.getWard().getName();
        String district = p.getWard().getDistrict() == null ? "" : p.getWard().getDistrict().getName();
        Map<String, Object> meta = new TreeMap<>();
        meta.put("property_id", p.getId());
        meta.put("title", Objects.toString(p.getTitle(), ""));
        String price = p.getPrice() == null ? "" : p.getPrice().stripTrailingZeros().toPlainString();
        meta.put("price_vnd", price);
        meta.put("area_m2", Objects.toString(p.getArea(), ""));
        meta.put("bedrooms", Objects.toString(p.getBedroomCount(), ""));
        meta.put("legal", Objects.toString(p.getLegal(), ""));
        meta.put("ward", ward);
        meta.put("district", district);
        meta.put("city", Objects.toString(p.getCity(), ""));
        meta.put("category", p.getCategory().getName());
        meta.put("type", p.getType().getName());
        String text = "Property ID " + p.getId() + "\nTiêu đề: " + p.getTitle() +
                "\nDanh mục: " + p.getCategory().getName() + "\nLoại hình: " + p.getType().getName() +
                "\nĐịa chỉ: " + Objects.toString(p.getAddress(), "") + ", " + ward + ", " + district + ", " + Objects.toString(p.getCity(), "") +
                "\nGiá: " + price + " VNĐ" +
                "\nDiện tích: " + Objects.toString(p.getArea(), "") + " m2" +
                "\nPhòng ngủ: " + Objects.toString(p.getBedroomCount(), "") +
                "\nPhòng tắm: " + Objects.toString(p.getBathroomCount(), "") +
                "\nSố tầng: " + Objects.toString(p.getFloorCount(), "") +
                "\nHướng: " + Objects.toString(p.getDirection(), "") +
                "\nPháp lý: " + Objects.toString(p.getLegal(), "") + "\nMô tả: " + Objects.toString(p.getDescription(), "");
        return Map.of("id", p.getId().toString(), "version", p.getIndexVersion(), "public", true, "text", text, "metadata", meta);
    }

}
