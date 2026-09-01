package com.ndnt.services.impl;

import com.ndnt.repositories.InteractionRepository;
import com.ndnt.repositories.PropertyRepository;
import com.ndnt.repositories.UserRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class DashboardServiceImplTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private PropertyRepository propertyRepository;

    @Mock
    private InteractionRepository interactionRepository;

    @InjectMocks
    private DashboardServiceImpl dashboardService;

    @Test
    @DisplayName("getTotalActiveUsers - Đếm tổng số user")
    void getTotalActiveUsers_Success() {
        when(userRepository.count()).thenReturn(50L);

        Long count = dashboardService.getTotalActiveUsers();

        assertEquals(50L, count);
        verify(userRepository, times(1)).count();
    }

    @Test
    @DisplayName("getTotalProperties - Đếm tổng số bất động sản")
    void getTotalProperties_Success() {
        when(propertyRepository.count()).thenReturn(100L);

        Long count = dashboardService.getTotalProperties();

        assertEquals(100L, count);
        verify(propertyRepository, times(1)).count();
    }

    @Test
    @DisplayName("getTotalInteractions - Đếm tổng số tương tác")
    void getTotalInteractions_Success() {
        when(interactionRepository.count()).thenReturn(200L);

        Long count = dashboardService.getTotalInteractions();

        assertEquals(200L, count);
        verify(interactionRepository, times(1)).count();
    }

    @Test
    @DisplayName("getUserStatsByQuarter - Thống kê user theo quý")
    void getUserStatsByQuarter_Success() {
        List<Object[]> rawStats = new ArrayList<>();
        rawStats.add(new Object[]{1, 10L});
        rawStats.add(new Object[]{2, 15L});

        when(userRepository.countUsersByQuarterInYear(2026)).thenReturn(rawStats);

        Map<String, Object> result = dashboardService.getUserStatsByQuarter(2026);

        assertNotNull(result);
        assertEquals(2026, result.get("year"));
        long[] data = (long[]) result.get("data");
        assertEquals(10L, data[0]);
        assertEquals(15L, data[1]);
        verify(userRepository, times(1)).countUsersByQuarterInYear(2026);
    }
}
