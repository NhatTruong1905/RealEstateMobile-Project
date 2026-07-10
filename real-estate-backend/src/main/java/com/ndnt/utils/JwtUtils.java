package com.ndnt.utils;


import com.ndnt.model.dto.UserDTO;
import com.nimbusds.jose.JWSAlgorithm;
import com.nimbusds.jose.JWSHeader;
import com.nimbusds.jose.JWSSigner;
import com.nimbusds.jose.JWSVerifier;
import com.nimbusds.jose.crypto.MACSigner;
import com.nimbusds.jose.crypto.MACVerifier;
import com.nimbusds.jwt.JWTClaimsSet;
import com.nimbusds.jwt.SignedJWT;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.util.Date;

@Component
public class JwtUtils {
    private static String secret;

    @Value("${JWT_SECRET}")
    public void setSecret(String secret) {
        JwtUtils.secret = secret;
    }

    private static final long EXPIRATION_MS = 86400000;

    public static String generateToken(UserDTO userDTO) throws Exception {
        JWSSigner signer = new MACSigner(secret);
        JWTClaimsSet claimsSet = new JWTClaimsSet.Builder()
                .subject(userDTO.getUsername())
                .claim("id", userDTO.getId())
                .claim("role", userDTO.getRoleName())
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
    }

    public static String validateTokenAndGetUsername(String token) throws Exception {
        SignedJWT signedJWT = SignedJWT.parse(token);
        JWSVerifier verifier = new MACVerifier(secret);

        if (signedJWT.verify(verifier)) {
            Date expiration = signedJWT.getJWTClaimsSet().getExpirationTime();
            if (expiration.after(new Date())) {
                return signedJWT.getJWTClaimsSet().getSubject();
            }
        }
        return null;
    }
}
