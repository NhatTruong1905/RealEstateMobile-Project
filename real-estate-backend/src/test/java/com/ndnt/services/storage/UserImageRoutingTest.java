package com.ndnt.services.storage;

import com.ndnt.converter.UserConverter;
import com.ndnt.model.dto.*;
import com.ndnt.model.entity.UserEntity;
import com.ndnt.repositories.*;
import com.ndnt.services.impl.UserServiceImpl;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import java.util.Optional;
import static org.mockito.Mockito.*;
import static org.junit.jupiter.api.Assertions.*;

@ExtendWith(MockitoExtension.class)
class UserImageRoutingTest {
    @Mock UserRepository users;
    @Mock UserConverter converter;
    @Mock RoleRepository roles;
    @Mock BCryptPasswordEncoder encoder;
    @Mock ImageStorageService storage;
    @InjectMocks UserServiceImpl service;

    @Test void adminCreateAndEditUseSharedStorageAndPreserveAvatarWithoutFile() throws Exception {
        var create = new UserAdminDTO(); create.setUsername("admin-created"); create.setFile(ImageProcessorTest.image());
        var fresh = new UserEntity(); when(converter.toUserEntity(create)).thenReturn(fresh);
        when(storage.uploadAvatar(create.getFile())).thenReturn("https://images.example.invalid/new.jpg");
        service.createOrUpdateUser(create);
        assertEquals("https://images.example.invalid/new.jpg",fresh.getAvatar());
        var edit = new UserAdminDTO(); edit.setId(10); edit.setFile(ImageProcessorTest.image());
        var old = new UserEntity(); old.setAvatar("https://legacy.example.invalid/old.jpg"); old.setPassword("hash");
        var changed = new UserEntity(); when(users.findById(10)).thenReturn(Optional.of(old));
        when(converter.toUserEntity(edit)).thenReturn(changed);
        when(storage.uploadAvatar(edit.getFile())).thenReturn("https://images.example.invalid/replacement.jpg");
        service.createOrUpdateUser(edit);
        assertEquals("hash",changed.getPassword()); assertEquals("https://images.example.invalid/replacement.jpg",changed.getAvatar());
        verify(storage).retire(old.getAvatar());
        edit.setFile(null); service.createOrUpdateUser(edit); assertEquals(old.getAvatar(),changed.getAvatar());
        verify(storage,times(2)).uploadAvatar(any());
    }
    @Test void registrationAndLegacyUserEditUseSharedStorage() throws Exception {
        var create = new UserInfoDTO(); create.setUsername("register-user"); create.setPassword("password"); create.setFile(ImageProcessorTest.image());
        var fresh = new UserEntity(); when(converter.toUserEntity(create)).thenReturn(fresh);
        when(storage.uploadAvatar(create.getFile())).thenReturn("https://images.example.invalid/registered.jpg");
        service.createOrUpdateUser(create);
        assertEquals("https://images.example.invalid/registered.jpg",fresh.getAvatar());
        var edit = new UserInfoDTO(); edit.setId(20); edit.setFile(ImageProcessorTest.image());
        var existing = new UserEntity(); existing.setAvatar("https://social.example.invalid/avatar.jpg");
        when(users.findById(20)).thenReturn(Optional.of(existing));
        when(storage.uploadAvatar(edit.getFile())).thenReturn("https://images.example.invalid/updated.jpg");
        service.createOrUpdateUser(edit);
        assertEquals("https://images.example.invalid/updated.jpg",existing.getAvatar());
        verify(storage).retire("https://social.example.invalid/avatar.jpg");
        verify(storage,times(2)).uploadAvatar(any());
    }
}
