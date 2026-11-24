package com.ndnt.services;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.thymeleaf.context.Context;
import org.thymeleaf.spring6.SpringTemplateEngine;

import java.util.Locale;
import java.util.Map;

@Component
@RequiredArgsConstructor
public class EmailTemplate {
    private final SpringTemplateEngine templates;

    public String render(String heading, String message, Map<String, Object> details) {
        var context = new Context(Locale.forLanguageTag("vi-VN"), details);
        context.setVariable("heading", heading);
        context.setVariable("message", message);
        return templates.process("email/notification", context);
    }
}
