package com.ndnt.model.enums;

import lombok.Getter;
import lombok.Setter;


@Getter
public enum StatusProperty {
    PENDING("Chờ duyệt"),
    PUBLISHED("Đang mở bán"),
    REJECTED("Từ chối"),
    DELETED("Đã xóa");

    private String status;

    StatusProperty(String status) {
        this.status = status;
    }
}
