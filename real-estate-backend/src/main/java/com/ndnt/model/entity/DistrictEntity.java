package com.ndnt.model.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;

import java.util.List;

@Getter
@Setter
@Entity
@Table(name = "district")
public class DistrictEntity extends BaseEntity {
    @Size(max = 50)
    @Column(name = "code", length = 50)
    private String code;

    @Size(max = 45)
    @Column(name = "name", length = 45)
    private String name;

    @OneToMany(fetch = FetchType.LAZY, mappedBy = "district")
    private List<WardEntity> wards;
}
