package com.ndnt.model.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.ColumnDefault;

import java.util.ArrayList;
import java.util.List;

@Getter
@Setter
@Entity
@Table(name = "user")
public class UserEntity extends BaseEntity {
    @NotNull
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "role_id", nullable = false)
    private RoleEntity role;

    @Size(max = 255)
    @NotNull
    @Column(name = "username", nullable = false)
    private String username;

    @Size(max = 255)
    @NotNull
    @Column(name = "password", nullable = false)
    private String password;

    @Size(max = 255)
    @Column(name = "fullname")
    private String fullname;

    @Size(max = 20)
    @Column(name = "phone", length = 20, unique = true)
    private String phone;

    @Size(max = 255)
    @Column(name = "email", unique = true)
    private String email;

    @ColumnDefault("1")
    @Column(name = "status")
    private Integer status = 1;

    @Column(name = "avatar", columnDefinition = "TEXT")
    private String avatar;

    @OneToMany(fetch = FetchType.LAZY, mappedBy = "staff")
    private List<AssignmentPropertyEntity> assignments = new ArrayList<>();

    @OneToMany(fetch = FetchType.LAZY, mappedBy = "user")
    private List<AssignmentUserEntity> assignmentUserUsers = new ArrayList<>();

    @OneToMany(fetch = FetchType.LAZY,mappedBy = "staff")
    private List<AssignmentUserEntity> assignmentUserStaffs = new ArrayList<>();
}