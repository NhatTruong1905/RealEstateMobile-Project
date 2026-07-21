package com.ndnt.utils;


import com.ndnt.model.dto.UserDTO;
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

    public String generateToken(UserDTO userDTO) throws Exception {
        try {
            JWSSigner signer = new MACSigner(getSharedKey());
            JWTClaimsSet claimsSet = new JWTClaimsSet.Builder()
                    .jwtID(UUID.randomUUID().toString())
                    .subject(userDTO.getUsername())
                    .claim("id", userDTO.getId())
                    .claim("role", userDTO.getRoleCode())
                    .claim("mail", userDTO.getEmail())
                    .claim("phone", userDTO.getPhone())
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
