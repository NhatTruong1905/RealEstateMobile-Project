package com.ndnt.controllers.api;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.ndnt.model.dto.FavoritePropertyDTO;
import com.ndnt.model.dto.PropertyDTO;
import com.ndnt.model.dto.UserDTO;
import com.ndnt.model.dto.request.PropertyRequestDTO;
import com.ndnt.services.FavoritePropertyService;
import com.ndnt.services.PropertyService;
import com.ndnt.services.UserService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.security.Principal;
import java.util.Collections;
import java.util.List;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@ExtendWith(MockitoExtension.class)
public class APIPropertyControllerTest {

    private MockMvc mockMvc;
    private ObjectMapper objectMapper;

    @Mock
    private PropertyService propertyService;

    @Mock
    private FavoritePropertyService favoritePropertyService;

    @Mock
    private UserService userService;

    @InjectMocks
    private APIPropertyController apiPropertyController;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.standaloneSetup(apiPropertyController).build();
        objectMapper = new ObjectMapper();
    }

    @Test
    @DisplayName("GET /api/properties - Lấy danh sách tin bất động sản công khai thành công")
    void getProperties_Success() throws Exception {
        PropertyDTO property = new PropertyDTO();
        property.setId(1);
        property.setTitle("Nhà đẹp quận 1");

        Page<PropertyDTO> page = new PageImpl<>(List.of(property));

        when(propertyService.getProperties(any(PropertyRequestDTO.class), any(Pageable.class))).thenReturn(page);

        mockMvc.perform(get("/api/properties")
                        .param("page", "1")
                        .param("limit", "6"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Success"))
                .andExpect(jsonPath("$.data.content[0].title").value("Nhà đẹp quận 1"))
                .andExpect(jsonPath("$.data.totalItems").value(1));

        verify(propertyService, times(1)).getProperties(any(PropertyRequestDTO.class), any(Pageable.class));
    }

    @Test
    @DisplayName("GET /api/secure/properties - Lấy danh sách tin của người dùng đăng nhập")
    void getPropertyOfUser_Success() throws Exception {
        Principal principal = () -> "testuser";
        UserDTO user = new UserDTO();
        user.setId(1);
        user.setUsername("testuser");

        PropertyDTO property = new PropertyDTO();
        property.setId(10);
        property.setTitle("Căn hộ cao cấp");

        when(userService.findByUsername("testuser")).thenReturn(user);
        when(propertyService.getPropertyOfUser(1)).thenReturn(List.of(property));

        mockMvc.perform(get("/api/secure/properties").principal(principal))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Success"))
                .andExpect(jsonPath("$.data[0].title").value("Căn hộ cao cấp"));

        verify(userService, times(1)).findByUsername("testuser");
        verify(propertyService, times(1)).getPropertyOfUser(1);
    }

    @Test
    void getPropertyOfUser_Paginated() throws Exception {
        UserDTO user = new UserDTO(); user.setId(1);
        PropertyDTO property = new PropertyDTO(); property.setId(10);
        var pageable = org.springframework.data.domain.PageRequest.of(1, 6);
        when(userService.findByUsername("testuser")).thenReturn(user);
        when(propertyService.getPropertyOfUser(1, pageable))
            .thenReturn(new PageImpl<>(List.of(property), pageable, 7));
        mockMvc.perform(get("/api/secure/properties").principal(() -> "testuser")
                .param("page", "2").param("limit", "6"))
            .andExpect(status().isOk()).andExpect(jsonPath("$.data.content[0].id").value(10))
            .andExpect(jsonPath("$.data.currentPage").value(2))
            .andExpect(jsonPath("$.data.totalItems").value(7))
            .andExpect(jsonPath("$.data.totalPages").value(2));
        verify(propertyService).getPropertyOfUser(1, pageable);
        verify(propertyService, never()).getPropertyOfUser(any(Integer.class));
    }

    @Test
    void getPropertyOfUser_InvalidPageBounds() throws Exception {
        for (String[] query : List.of(new String[]{"0", "6"}, new String[]{"-1", "6"},
                new String[]{"1", "0"}, new String[]{"1", "101"})) {
            mockMvc.perform(get("/api/secure/properties").principal(() -> "testuser")
                .param("page", query[0]).param("limit", query[1])).andExpect(status().isBadRequest());
        }
        verifyNoInteractions(propertyService, userService);
    }

    @Test
    void createProperty_RequiredErrorsAreAssignedToTheirFields() throws Exception {
        mockMvc.perform(multipart("/api/secure/properties").principal(() -> "testuser"))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.detail").value("VALIDATION_ERROR"))
            .andExpect(jsonPath("$.data.typeId").value("Vui lòng chọn loại hình giao dịch."))
            .andExpect(jsonPath("$.data.categoryId").value("Vui lòng chọn phân khúc bất động sản."))
            .andExpect(jsonPath("$.data.title").value("Vui lòng nhập tiêu đề tin đăng."))
            .andExpect(jsonPath("$.data.address").value("Vui lòng nhập địa chỉ đầy đủ."))
            .andExpect(jsonPath("$.data.price").value("Vui lòng nhập giá bất động sản."))
            .andExpect(jsonPath("$.data.area").value("Vui lòng nhập diện tích."))
            .andExpect(jsonPath("$.data.legal").value("Vui lòng nhập thông tin pháp lý."));
        verifyNoInteractions(propertyService, userService);
    }

    @Test
    void createProperty_InvalidNumbersDoNotExposeJavaConversionErrors() throws Exception {
        mockMvc.perform(multipart("/api/secure/properties").principal(() -> "testuser")
                .param("price", "abc").param("area", "-1").param("bedroomCount", "1.5"))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.data.price").value("Giá bất động sản phải là số hợp lệ."))
            .andExpect(jsonPath("$.data.area").value("Diện tích phải lớn hơn 0."))
            .andExpect(jsonPath("$.data.bedroomCount").value("Số phòng ngủ phải là số nguyên hợp lệ."));
        verifyNoInteractions(propertyService, userService);
    }

    @Test
    @DisplayName("GET /api/secure/properties/{id} - Lấy chi tiết bất động sản thành công")
    void getDetailProperty_Success() throws Exception {
        PropertyDTO property = new PropertyDTO();
        property.setId(5);
        property.setTitle("Biệt thự sân vườn");

        when(propertyService.findById(5)).thenReturn(property);

        mockMvc.perform(get("/api/secure/properties/{id}", 5))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Success"))
                .andExpect(jsonPath("$.data.title").value("Biệt thự sân vườn"));

        verify(propertyService, times(1)).findById(5);
    }

    @Test
    @DisplayName("GET /api/secure/properties/{id} - Không tìm thấy tin trả về 400")
    void getDetailProperty_NotFound() throws Exception {
        when(propertyService.findById(999)).thenReturn(null);

        mockMvc.perform(get("/api/secure/properties/{id}", 999))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("Fail"));

        verify(propertyService, times(1)).findById(999);
    }

    @Test
    @DisplayName("DELETE /api/secure/properties/{id} - Xóa tin thành công")
    void deleteProperty_Success() throws Exception {
        doNothing().when(propertyService).deleteOwnedProperty(5);

        mockMvc.perform(delete("/api/secure/properties/{id}", 5))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Success"));

        verify(propertyService, times(1)).deleteOwnedProperty(5);
    }

    @Test
    @DisplayName("POST /api/secure/favorite-properties - Lưu tin yêu thích thành công")
    void createOrUpdateFavoriteProperty_Success() throws Exception {
        Principal principal = () -> "testuser";
        UserDTO user = new UserDTO();
        user.setId(1);
        user.setUsername("testuser");

        FavoritePropertyDTO favDTO = new FavoritePropertyDTO();
        favDTO.setPropertyIds(List.of(10));

        when(userService.findByUsername("testuser")).thenReturn(user);
        doNothing().when(favoritePropertyService).createOrUpdateFavoriteProperty(any(FavoritePropertyDTO.class));

        mockMvc.perform(post("/api/secure/favorite-properties")
                        .principal(principal)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(favDTO)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Success"));

        verify(favoritePropertyService, times(1)).createOrUpdateFavoriteProperty(any(FavoritePropertyDTO.class));
    }
}
