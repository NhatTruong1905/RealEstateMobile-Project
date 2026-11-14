package com.ndnt.controllers.api;

import com.ndnt.model.entity.PropertyEntity;
import com.ndnt.model.enums.StatusProperty;
import com.ndnt.repositories.PropertyRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.*;

@RestController @RequestMapping("/api/internal/ai") @RequiredArgsConstructor
@Transactional(readOnly=true)
public class AIPropertySourceController {
    private final PropertyRepository properties;
    @Value("${property.index.service-token:}") private String serviceToken;

    private void authorize(String supplied) {
        if (serviceToken.isBlank() || supplied == null || !MessageDigest.isEqual(
                serviceToken.getBytes(StandardCharsets.UTF_8), supplied.getBytes(StandardCharsets.UTF_8)))
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED);
    }

    @GetMapping("/properties/{id}")
    public Map<String,Object> get(@RequestHeader(value="X-AI-Service-Token", required=false) String token,
                                 @PathVariable Integer id) {
        authorize(token);
        return record(properties.findById(id).orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND)));
    }

    @GetMapping("/properties")
    public Map<String,Object> page(@RequestHeader(value="X-AI-Service-Token", required=false) String token,
                                  @RequestParam(defaultValue="0") Integer after,
                                  @RequestParam(defaultValue="20") Integer limit) {
        authorize(token);
        if (after < 0 || limit < 1 || limit > 100) throw new ResponseStatusException(HttpStatus.BAD_REQUEST);
        return Map.of("records", properties.indexPage(after, PageRequest.of(0,limit)).stream().map(this::record).toList());
    }

    @GetMapping("/properties/resolve")
    public Map<String,Object> resolve(@RequestHeader(value="X-AI-Service-Token", required=false) String token,
                                     @RequestParam List<Integer> ids) {
        authorize(token);
        if (ids.isEmpty() || ids.size() > 100 || ids.stream().anyMatch(id -> id == null || id < 1))
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST);
        return Map.of("records",properties.findById_In(ids).stream().map(this::record).toList());
    }

    private Map<String,Object> record(PropertyEntity p) {
        boolean visible = StatusProperty.PUBLISHED.getStatus().equals(p.getStatus());
        if (!visible) return Map.of("id",p.getId().toString(), "version",p.getIndexVersion(),
                "public",false, "text","", "metadata",Map.of());
        String ward = p.getWard().getName();
        String district = p.getWard().getDistrict() == null ? "" : p.getWard().getDistrict().getName();
        Map<String,Object> meta = new TreeMap<>();
        meta.put("property_id",p.getId());
        meta.put("title",Objects.toString(p.getTitle(),""));
        String price = p.getPrice()==null ? "" : p.getPrice().stripTrailingZeros().toPlainString();
        meta.put("price_vnd",price);
        meta.put("area_m2",Objects.toString(p.getArea(),""));
        meta.put("bedrooms",Objects.toString(p.getBedroomCount(),""));
        meta.put("legal",Objects.toString(p.getLegal(),""));
        meta.put("ward",ward); meta.put("district",district);
        meta.put("city",Objects.toString(p.getCity(),""));
        meta.put("category",p.getCategory().getName());
        meta.put("type",p.getType().getName());
        String text = "Property ID " + p.getId() + "\nTiêu đề: " + p.getTitle() +
                "\nDanh mục: " + p.getCategory().getName() + "\nLoại hình: " + p.getType().getName() +
                "\nĐịa chỉ: " + Objects.toString(p.getAddress(),"") + ", " + ward + ", " + district + ", " + Objects.toString(p.getCity(),"") +
                "\nGiá: " + price + " VNĐ" +
                "\nDiện tích: " + Objects.toString(p.getArea(),"") + " m2" +
                "\nPhòng ngủ: " + Objects.toString(p.getBedroomCount(),"") +
                "\nPhòng tắm: " + Objects.toString(p.getBathroomCount(),"") +
                "\nSố tầng: " + Objects.toString(p.getFloorCount(),"") +
                "\nHướng: " + Objects.toString(p.getDirection(),"") +
                "\nPháp lý: " + Objects.toString(p.getLegal(),"") + "\nMô tả: " + Objects.toString(p.getDescription(),"");
        return Map.of("id",p.getId().toString(), "version",p.getIndexVersion(), "public",true, "text",text, "metadata",meta);
    }
}
