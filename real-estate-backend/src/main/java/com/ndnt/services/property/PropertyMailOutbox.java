package com.ndnt.services.property;

import com.ndnt.model.entity.*;
import com.ndnt.repositories.PropertyMailEventRepository;
import com.ndnt.services.EmailTemplate;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import java.time.*;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class PropertyMailOutbox {
    private final PropertyMailEventRepository events;
    private final EmailTemplate template;
    @Value("${property.mail.zone:Asia/Ho_Chi_Minh}") private String zone;
    @Value("${property.mail.property-url-prefix:}") private String urlPrefix;
    @Value("${property.mail.review-inbox:moderation@nhtr.id.vn}") private String reviewInbox;
    public void enqueue(PropertyEntity property, String type) {
        UserEntity owner = property.getUser();
        PropertyMailEvent event = new PropertyMailEvent();
        event.setPropertyId(property.getId()); event.setEventKey(property.getId()+":"+type+":"+property.getIndexVersion()); event.setEventType(type);

        event.setRecipient(owner.getEmail() == null ? "" : owner.getEmail());
        String name = owner.getFullname() == null ? owner.getUsername() : owner.getFullname();
        String when = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm z").withZone(ZoneId.of(zone))
                .format((type.equals("RECEIVED") ? property.getCreatedDate() : property.getReviewedAt()).toInstant());
        String heading;
        String message;
        var details = new HashMap<String, Object>(listingDetails(property));
        details.put("greeting", name == null || name.isBlank() ? "Xin chào," : "Chào " + name.trim() + ",");
        switch (type) {
            case "RECEIVED" -> {
                heading = "Tin đăng đã được tiếp nhận";
                message = "Nhà Thật đã nhận tin của bạn lúc " + when
                        + ". Tin đang chờ xét duyệt. Chúng tôi sẽ gửi email khi có kết quả.";
            }
            case "APPROVED" -> {
                heading = "Tin đăng đã được phê duyệt";
                message = "Tin của bạn được phê duyệt lúc " + when + " và hiện đã hiển thị công khai trên Nhà Thật.";
                if (urlPrefix != null && !urlPrefix.isBlank()) details.put("actionUrl", urlPrefix + property.getId());
            }
            case "REJECTED" -> {
                heading = "Tin đăng cần chỉnh sửa";
                message = "Sau khi xét duyệt lúc " + when + ", Nhà Thật đề nghị bạn chỉnh sửa tin theo lý do bên dưới.";
                details.put("reason", property.getRejectionReason());
                details.put("note", "Bạn có thể sửa tin và gửi lại để xét duyệt trong mục Tin đăng của tôi.");
            }
            default -> throw new IllegalArgumentException("Unknown property mail event");
        }
        saveEmail(event, heading, message, details);
    }

    private Map<String, Object> listingDetails(PropertyEntity property) {
        return Map.of("listingId", property.getId(), "listingTitle", property.getTitle());
    }

    private void saveEmail(PropertyMailEvent event, String heading, String message, Map<String, Object> details) {
        event.setSubject(heading + " | Nhà Thật");
        Object greeting = details.get("greeting");
        String text = (greeting == null ? "" : greeting + "\n\n") + message
                + "\n\n" + details.get("listingTitle") + "\nMã tin #" + details.get("listingId");
        if (details.get("reason") != null) text += "\n\nLý do từ chối\n" + details.get("reason");
        if (details.containsKey("note")) text += "\n\n" + details.get("note");
        if (details.containsKey("actionUrl")) text += "\n\nXem tin đăng: " + details.get("actionUrl");
        text += "\n\nTrân trọng,\nNhà Thật";
        if (greeting != null) text += "\n\nHỗ trợ qua support@nhtr.id.vn";
        event.setTextBody(text);
        event.setHtmlBody(template.render(heading, message, details));
        events.save(event);
    }

    public void enqueueResubmission(PropertyEntity property) {
        if (reviewInbox.isBlank()) {
            throw new PropertyProblem(409, "CONFLICT", "Chưa cấu hình hộp thư xét duyệt.");
        }
        var event = new PropertyMailEvent();
        event.setPropertyId(property.getId());
        event.setEventType("RESUBMITTED");
        event.setEventKey(property.getId() + ":RESUBMITTED:" + property.getIndexVersion());
        event.setRecipient(reviewInbox.trim());
        saveEmail(event, "Tin đăng được gửi lại để xét duyệt",
                "Người đăng đã gửi lại tin. Vui lòng mở danh sách tin chờ duyệt trong trang quản trị.",
                listingDetails(property));
    }
}
