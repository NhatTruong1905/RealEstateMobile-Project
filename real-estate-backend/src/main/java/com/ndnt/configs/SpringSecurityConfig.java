package com.ndnt.configs;

import com.cloudinary.Cloudinary;
import com.cloudinary.utils.ObjectUtils;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.annotation.Order;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.util.matcher.OrRequestMatcher;
import org.springframework.transaction.annotation.EnableTransactionManagement;

import static org.springframework.security.web.servlet.util.matcher.PathPatternRequestMatcher.withDefaults;

@Configuration
@EnableWebSecurity
@EnableTransactionManagement
@ComponentScan(
        basePackages = {
                "com.ndnt"
        }
)
@Order(2)
public class SpringSecurityConfig {
    @Bean
    public BCryptPasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        var matcher = withDefaults();

        http.securityMatcher(new OrRequestMatcher(
                        matcher.matcher("/admin/**"),
                        matcher.matcher("/"),
                        matcher.matcher("/login")
                ))
                .authorizeHttpRequests((requests) -> requests
                        .requestMatchers(matcher.matcher("/admin/login")).permitAll()
                        .requestMatchers(matcher.matcher("/admin/logout")).permitAll()
                        .requestMatchers(matcher.matcher("/admin/error")).permitAll()
                        .requestMatchers(new OrRequestMatcher(
                                matcher.matcher("/admin/"),
                                matcher.matcher("/admin/properties-list"),
                                matcher.matcher("/admin/properties-edit*"),
                                matcher.matcher("/admin/api/properties"),
                                matcher.matcher("/admin/api/properties/**"),
                                matcher.matcher("/admin/interactions-list"),
                                matcher.matcher("/admin/interactions-edit*"),
                                matcher.matcher("/admin/api/interactions"),
                                matcher.matcher("/admin/api/interactions/**"),
                                matcher.matcher("/admin/users-list"),
                                matcher.matcher("/admin/users-edit*"),
                                matcher.matcher("/admin/api/users")
                        )).hasAnyRole("STAFF", "ADMIN")
                        .requestMatchers(matcher.matcher("/admin/**")).hasRole("ADMIN")
                        .anyRequest().authenticated()
                ).formLogin(form -> form.loginPage("/admin/login")
                        .loginProcessingUrl("/admin/login")
                        .defaultSuccessUrl("/admin/", true)
                        .failureUrl("/admin/login?error=true")
                        .permitAll()
                )
                .logout((logout) -> logout.logoutSuccessUrl("/admin/login")
                        .permitAll().deleteCookies("JSESSIONID"))
                .exceptionHandling(exception -> exception.accessDeniedPage("/admin/error"));


        return http.build();
    }

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
