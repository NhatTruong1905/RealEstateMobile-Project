package com.ndnt.model.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(name = "ward")
public class Ward extends BaseEntity {
    @Size(max = 50)
    @Column(name = "code", length = 50)
    private String code;

    @Size(max = 45)
    @Column(name = "name", length = 45)
    private String name;
}