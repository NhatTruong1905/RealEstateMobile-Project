package com.ndnt.services;

import java.util.Map;

public interface DashboardService {
    Long getTotalActiveUsers();

    Long getTotalProperties();

    Long getTotalInteractions();

    Map<String, Object> getUserStatsByQuarter(int year);

    Map<String, Object> getPropertyStatsByQuarter(int year);

    Map<String, Object> getInteractionStatsByQuarter(int year);
}
