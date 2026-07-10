package com.ndnt.configs;

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
        /*
         * Spring Security 7 đã bỏ MvcRequestMatcher. Vì thế không còn phải tạo
         * HandlerMappingIntrospector để so khớp URL theo Spring MVC.
         *
         * PathPatternRequestMatcher hỗ trợ pattern hiện đại như "/admin/**".
         * Servlet của Spring Boot mặc định nằm ở "/", nên withDefaults() là đủ.
         * Nếu có servlet path riêng, ví dụ "/mvc", dùng: withDefaults().basePath("/mvc").
         */
        var matcher = withDefaults();

        // OrRequestMatcher gộp các URL mà SecurityFilterChain này sẽ xử lý.
        http.securityMatcher(new OrRequestMatcher(
                        matcher.matcher("/admin/**"),
                        matcher.matcher("/"),
                        matcher.matcher("/login")
                ))
                .authorizeHttpRequests((requests) -> requests
                        // Phải cho phép truy cập trang login trước khi xác thực.
                        .requestMatchers(matcher.matcher("/admin/login")).permitAll()

                        // hasRole("ADMIN") sẽ kiểm tra GrantedAuthority "ROLE_ADMIN".
                        .requestMatchers(matcher.matcher("/admin/**")).hasRole("ADMIN")

                        // Giữ nguyên ý nghĩa cũ: các URL thuộc filter chain này yêu cầu đăng nhập.
                        .anyRequest().authenticated()
                ).formLogin(form -> form.loginPage("/admin/login")
                        // URL POST phải khớp với th:action trong templates/login.html.
                        .loginProcessingUrl("/admin/login")
                        .defaultSuccessUrl("/admin/", true)
                        .failureUrl("/admin/login?error=true")
                        .permitAll()
                )
                .logout((logout) -> logout.logoutSuccessUrl("/admin/login").permitAll());


        return http.build();
    }
}
