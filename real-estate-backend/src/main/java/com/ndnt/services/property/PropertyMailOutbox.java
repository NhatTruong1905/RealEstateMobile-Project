package com.ndnt.services.property;

import com.ndnt.model.entity.*;
import com.ndnt.repositories.PropertyMailEventRepository;
import com.ndnt.repositories.UserRepository;
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
    private final UserRepository users;
    private final EmailTemplate template;
    @Value("${property.mail.zone:Asia/Ho_Chi_Minh}") private String zone;
    @Value("${property.mail.property-url-prefix:}") private String urlPrefix;
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
        switch (type) {
            case "RECEIVED" -> {
                heading = "Tin đăng đã được tiếp nhận";
                message = "Tin đã được tiếp nhận lúc " + when
                        + " và chưa được công khai. Nhà Thật sẽ thông báo khi có kết quả xét duyệt.";
            }
            case "APPROVED" -> {
                heading = "Tin đăng đã được phê duyệt";
                message = "Tin đã được phê duyệt lúc " + when + " và đã công khai.";
                if (urlPrefix != null && !urlPrefix.isBlank()) details.put("actionUrl", urlPrefix + property.getId());
            }
            case "REJECTED" -> {
                heading = "Tin đăng cần chỉnh sửa";
                message = "Tin chưa được phê duyệt trong lần xét duyệt lúc " + when + ".";
                details.put("reason", property.getRejectionReason());
                details.put("note", "Bạn có thể sửa tin và gửi lại để xét duyệt trong mục Tin đăng của tôi.");
            }
            default -> throw new IllegalArgumentException("Unknown property mail event");
        }
        saveEmail(event, heading, "Chào " + name + ", " + message, details);
    }

    private Map<String, Object> listingDetails(PropertyEntity property) {
        return Map.of("listingId", property.getId(), "listingTitle", property.getTitle());
    }

    private void saveEmail(PropertyMailEvent event, String heading, String message, Map<String, Object> details) {
        event.setSubject(heading + " | Nhà Thật");
        String text = message + "\n\nTin #" + details.get("listingId") + " - " + details.get("listingTitle");
        if (details.containsKey("reason")) text += "\nLý do: " + details.get("reason") + ".";
        if (details.containsKey("note")) text += "\n" + details.get("note");
        if (details.containsKey("actionUrl")) text += "\nXem tin đăng: " + details.get("actionUrl");
        event.setTextBody(text);
        event.setHtmlBody(template.render(heading, message, details));
        events.save(event);
    }

    public void enqueueResubmission(PropertyEntity property) {
        var admins = users.findAllByStatusAndRole_Code(1, "ROLE_ADMIN").stream()
                .filter(admin -> admin.getEmail() != null && !admin.getEmail().isBlank()).toList();
        if (admins.isEmpty()) {
            throw new PropertyProblem(409, "CONFLICT", "Chưa có email quản trị viên để nhận thông báo xét duyệt.");
        }
        var notified = new java.util.HashSet<String>();
        for (UserEntity admin : admins) {
            String email = admin.getEmail().trim();
            if (!notified.add(email.toLowerCase(java.util.Locale.ROOT))) continue;
            var event = new PropertyMailEvent();
            event.setPropertyId(property.getId());
            event.setEventType("RESUBMITTED");
            event.setEventKey(property.getId()+":RESUBMITTED:"+property.getIndexVersion()+":"+admin.getId());
            event.setRecipient(email);
            saveEmail(event, "Tin đăng được gửi lại để xét duyệt",
                    "Người đăng đã gửi lại tin. Vui lòng mở danh sách tin chờ duyệt trong trang quản trị.",
                    listingDetails(property));
        }
    }
}
