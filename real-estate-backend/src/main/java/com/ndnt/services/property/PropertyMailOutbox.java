package com.ndnt.services.property;

import com.ndnt.model.entity.*;
import com.ndnt.repositories.PropertyMailEventRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.util.HtmlUtils;
import java.time.*;
import java.time.format.DateTimeFormatter;

@Service
@RequiredArgsConstructor
public class PropertyMailOutbox {
    private final PropertyMailEventRepository events;
    @Value("${property.mail.zone:Asia/Ho_Chi_Minh}") private String zone;
    @Value("${property.mail.property-url-prefix:}") private String urlPrefix;
    public void enqueue(PropertyEntity property, String type) {
        UserEntity owner = property.getUser();
        PropertyMailEvent event = new PropertyMailEvent();
        event.setPropertyId(property.getId()); event.setEventKey(property.getId()+":"+type); event.setEventType(type);
        // Snapshot trusted account + committed decision in the same transaction as the property.
        event.setRecipient(owner.getEmail() == null ? "" : owner.getEmail());
        String name = owner.getFullname() == null ? owner.getUsername() : owner.getFullname();
        String when = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm z").withZone(ZoneId.of(zone))
                .format((type.equals("RECEIVED") ? property.getCreatedDate() : property.getReviewedAt()).toInstant());
        String text = "Chào " + name + "; bài `" + property.getTitle() + "` (mã " + property.getId() + ") ";
        switch (type) {
            case "RECEIVED" -> {
                event.setSubject("[RealEstateMobile] Đã tiếp nhận bài đăng bất động sản");
                text += "đã được tiếp nhận vào " + when + ". Bài đang chờ xét duyệt, chưa được công khai; sẽ có thông báo khi có kết quả.";
            }
            case "APPROVED" -> {
                event.setSubject("[RealEstateMobile] Bài đăng của bạn đã được phê duyệt");
                text += "đã được Staff phê duyệt vào " + when + " và đã công khai.";
                if (urlPrefix != null && !urlPrefix.isBlank()) text += " Xem bài: " + urlPrefix + property.getId();
            }
            case "REJECTED" -> {
                event.setSubject("[RealEstateMobile] Bài đăng của bạn chưa được phê duyệt");
                text += "chưa được chấp nhận vào " + when + ". Lý do: " + property.getRejectionReason()
                      + ". Vui lòng kiểm tra và điều chỉnh theo chức năng hệ thống đang hỗ trợ.";
            }
            default -> throw new IllegalArgumentException("Unknown property mail event");
        }
        event.setTextBody(text); event.setHtmlBody("<p>" + HtmlUtils.htmlEscape(text, "UTF-8") + "</p>");
        events.save(event);
    }
}
