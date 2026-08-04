package com.ndnt.configs;

import com.cloudinary.Cloudinary;
import com.cloudinary.utils.ObjectUtils;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class CloudinaryConfig {

    @Bean
    public Cloudinary cloudinary() {
        Cloudinary cloudinary
                = new Cloudinary(ObjectUtils.asMap(
                "cloud_name", "dokjzty69",
                "api_key", "283182293216446",
                "api_secret", "u0B3MQtHRwSrTuLmTM30qyiUxMQ",
                "secure", true));
        return cloudinary;
    }
}
