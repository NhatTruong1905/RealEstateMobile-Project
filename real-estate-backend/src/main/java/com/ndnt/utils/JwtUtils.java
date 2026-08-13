package com.ndnt.utils;


import com.ndnt.model.dto.UserDTO;
import com.ndnt.model.dto.UserInfoDTO;
import com.nimbusds.jose.*;
import com.nimbusds.jose.crypto.MACSigner;
import com.nimbusds.jose.crypto.MACVerifier;
import com.nimbusds.jwt.JWTClaimsSet;
import com.nimbusds.jwt.SignedJWT;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.UUID;

@Component
public class JwtUtils {
    private static String secret;

    @Value("${JWT_SECRET}")
    public void setSecret(String secret) {
        JwtUtils.secret = secret;
    }

    private static final long EXPIRATION_MS = 86400000;

    private byte[] getSharedKey() {
        return secret.getBytes(StandardCharsets.UTF_8);
    }

    public String generateToken(UserDTO user) throws Exception {
        return createJwtToken(user.getUsername(), user.getId(), user.getFullname(),
                user.getPhone(), user.getEmail(), user.getRoleCode());
    }

    public String generateToken(UserInfoDTO user) throws Exception {
        return createJwtToken(user.getUsername(), user.getId(), user.getFullname(),
                user.getPhone(), user.getEmail(), user.getRoleCode());
    }

    private String createJwtToken(String username, Object id, String fullname,
                                  String phone, String email, String role) {
        try {
            JWSSigner signer = new MACSigner(getSharedKey());
            JWTClaimsSet claimsSet = new JWTClaimsSet.Builder()
                    .jwtID(UUID.randomUUID().toString())
                    .subject(username)
                    .claim("id", id)
                    .claim("fullname", fullname)
                    .claim("phone", phone)
                    .claim("email", email)
                    .claim("role", role)
                    .expirationTime(new Date(System.currentTimeMillis() + EXPIRATION_MS))
                    .issueTime(new Date())
                    .build();

            SignedJWT signedJWT = new SignedJWT(
                    new JWSHeader(JWSAlgorithm.HS256),
                    claimsSet
            );

            signedJWT.sign(signer);
            return signedJWT.serialize();
        } catch (JOSEException e) {
            throw new RuntimeException("Lỗi khi tạo JWT Token: " + e.getMessage());
        }
    }

    public JWTClaimsSet validateTokenAndGetClaims(String token) {
        try {
            SignedJWT signedJWT = SignedJWT.parse(token);
            JWSVerifier verifier = new MACVerifier(secret);
            if (!signedJWT.verify(verifier)) {
                return null;
            }
            JWTClaimsSet claims = signedJWT.getJWTClaimsSet();
            Date expiration = claims.getExpirationTime();
            if (expiration == null || expiration.before(new Date())) {
                return null;
            }
            return claims;
        } catch (Exception e) {
            return null;
        }
    }
}
