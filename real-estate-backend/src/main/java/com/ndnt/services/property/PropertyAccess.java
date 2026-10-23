package com.ndnt.services.property;

import com.ndnt.model.entity.*;
import com.ndnt.repositories.*;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.authentication.AnonymousAuthenticationToken;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
public class PropertyAccess {
    private final UserRepository users;
    private final AssignmentPropertyRepository assignments;
    public UserEntity actor() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !auth.isAuthenticated() || auth instanceof AnonymousAuthenticationToken)
            throw new PropertyProblem(401, "UNAUTHORIZED", "Yêu cầu đăng nhập");
        UserEntity user = users.findByUsername(auth.getName());
        if (user == null || !Integer.valueOf(1).equals(user.getStatus())) throw PropertyProblem.forbidden();
        return user;
    }
    public boolean hasRole(UserEntity actor, String role) {
        return actor.getRole() != null && role.equals(actor.getRole().getCode());
    }
    public boolean reviewer(UserEntity actor, PropertyEntity property) {
        return hasRole(actor, "ROLE_ADMIN") || (hasRole(actor, "ROLE_STAFF") &&
                assignments.existsByStaff_IdAndProperty_Id(actor.getId(), property.getId()));
    }
    public boolean owner(UserEntity actor, PropertyEntity property) {
        return property.getUser().getId().equals(actor.getId());
    }
    public void requireReviewer(UserEntity actor, PropertyEntity property) {
        if (!reviewer(actor, property)) throw PropertyProblem.forbidden();
    }
    public void requireOwner(UserEntity actor, PropertyEntity property) {
        if (!owner(actor, property)) throw PropertyProblem.forbidden();
    }
}
