package com.ndnt.services.storage;

import lombok.Getter;

@Getter
public class StorageProblem extends RuntimeException {
    private final int status;
    private final String code;
    public StorageProblem(int status, String code, String message) {
        super(message);
        this.status = status;
        this.code = code;
    }
    public static StorageProblem invalid() {
        return new StorageProblem(400, "INVALID_IMAGE", "Ảnh phải là JPEG, PNG hoặc WebP hợp lệ, không rỗng, tối đa 5 MB và 20 triệu pixel");
    }
    public static StorageProblem unavailable() {
        return new StorageProblem(502, "STORAGE_UNAVAILABLE", "Không thể truy cập kho ảnh lúc này; vui lòng thử lại");
    }
}
