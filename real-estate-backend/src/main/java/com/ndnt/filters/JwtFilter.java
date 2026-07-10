package com.ndnt.filters;

import com.ndnt.utils.JwtUtils;
import jakarta.servlet.*;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;

import java.io.IOException;

@Component
public class JwtFilter implements Filter {

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain) throws IOException, ServletException {
        HttpServletRequest httpRequest = (HttpServletRequest) request;

        if (httpRequest.getRequestURI().startsWith(String.format("%s/api/secure", httpRequest.getContextPath())) == true) {

            String header = httpRequest.getHeader("Authorization");

            if (header == null || !header.startsWith("Bearer ")) {
                ((HttpServletResponse) response).sendError(HttpServletResponse.SC_UNAUTHORIZED, "Missing or invalid Authorization header.");
                return;
            } else {
                String token = header.substring(7);
                try {
                    String username = JwtUtils.validateTokenAndGetUsername(token);
                    if (username != null) {
                        httpRequest.setAttribute("username", username);

                        UsernamePasswordAuthenticationToken authentication = new UsernamePasswordAuthenticationToken(username, null, null);
                        SecurityContextHolder.getContext().setAuthentication(authentication);

                        chain.doFilter(request, response);
                        return;
                    }
                } catch (Exception e) {
                    System.err.println(e.getMessage());
                    // Log lỗi
                }
            }
            ((HttpServletResponse) response).sendError(HttpServletResponse.SC_UNAUTHORIZED, "Token không hợp lệ hoặc hết hạn");
            return;
        }

        chain.doFilter(request, response);
    }
}
