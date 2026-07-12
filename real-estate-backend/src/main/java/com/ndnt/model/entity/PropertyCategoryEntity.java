package com.ndnt.model.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(name = "property_category")
public class PropertyCategoryEntity extends BaseEntity {
    @Size(max = 50)
    @NotNull
    @Column(name = "code", nullable = false, length = 50, unique = true)
    private String code;

    @Size(max = 255)
    @NotNull
    @Column(name = "name", nullable = false)
    private String name;
}