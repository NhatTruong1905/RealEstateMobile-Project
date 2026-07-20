package com.ndnt.model.entity;

import com.ndnt.model.enums.StatusProperty;
import jakarta.persistence.*;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.ColumnDefault;
import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

@Getter
@Setter
@Entity
@Table(name = "property")
public class PropertyEntity extends BaseEntity {
    @NotNull
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @OnDelete(action = OnDeleteAction.CASCADE)
    @JoinColumn(name = "user_id", nullable = false)
    private UserEntity user;

    @NotNull
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "type_id", nullable = false)
    private PropertyTypeEntity type;

    @NotNull
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "category_id", nullable = false)
    private PropertyCategoryEntity category;

    @Size(max = 255)
    @NotNull
    @Column(name = "title", nullable = false)
    private String title;

    @Size(max = 255)
    @Column(name = "address")
    private String address;

    @NotNull
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "ward_id", nullable = false)
    private WardEntity ward;

    @Size(max = 45)
    @Column(name = "city", length = 45)
    private String city;

    @Column(name = "price", precision = 15, scale = 2)
    private BigDecimal price;

    @Column(name = "area", precision = 10, scale = 2)
    private BigDecimal area;

    @Column(name = "floor_count")
    private Integer floorCount;

    @Column(name = "bedroom_count")
    private Integer bedroomCount;

    @Column(name = "bathroom_count")
    private Integer bathroomCount;

    @Size(max = 45)
    @Column(name = "direction", length = 45)
    private String direction;

    @Size(max = 45)
    @Column(name = "legal", length = 45)
    private String legal;

    @Lob
    @Column(name = "description")
    private String description;

    @Column(name = "image")
    private String image;

    @ColumnDefault("0")
    @Column(name = "status")
    private String status = StatusProperty.PENDING.getStatus();

    @OneToMany(fetch = FetchType.LAZY, mappedBy = "property")
    private List<AssignmentPropertyEntity> assignments = new ArrayList<>();
}