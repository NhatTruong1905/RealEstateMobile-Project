package com.ndnt.services.property;

import java.util.Map;
import lombok.Getter;

@Getter
public class PropertyProblem extends RuntimeException {
    private final int status;
    private final String code;
    private final Map<String, String> fields;
    public PropertyProblem(int status, String code, String message) {
        this(status, code, message, Map.of());
    }
    public PropertyProblem(int status, String code, String message, Map<String, String> fields) {
        super(message); this.status = status; this.code = code; this.fields = fields;
    }
    public static PropertyProblem invalid(String field, String message) {
        return new PropertyProblem(422, "VALIDATION_ERROR", message, Map.of(field, message));
    }
    public static PropertyProblem missing() { return new PropertyProblem(404, "NOT_FOUND", "Không tìm thấy bài đăng"); }
    public static PropertyProblem forbidden() { return new PropertyProblem(403, "FORBIDDEN", "Không đủ quyền thao tác"); }
}
