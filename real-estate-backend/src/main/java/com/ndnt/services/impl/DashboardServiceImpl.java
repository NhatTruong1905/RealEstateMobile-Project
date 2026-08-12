package com.ndnt.services.impl;

import com.ndnt.repositories.InteractionRepository;
import com.ndnt.repositories.PropertyRepository;
import com.ndnt.repositories.UserRepository;
import com.ndnt.services.DashboardService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.*;
import java.util.*;

@Service
public class DashboardServiceImpl implements DashboardService {
    @Autowired
    private UserRepository userRepository;
    @Autowired
    private PropertyRepository propertyRepository;
    @Autowired
    private InteractionRepository interactionRepository;

    @Override
    public Long getTotalActiveUsers() {
        return this.userRepository.count();
    }

    @Override
    public Long getTotalProperties() {
        return this.propertyRepository.count();
    }

    @Override
    public Long getTotalInteractions() {
        return this.interactionRepository.count();
    }

    @Override
    public Map<String, Object> getUserStatsByQuarter(int year) {
        List<Object[]> results = userRepository.countUsersByQuarterInYear(year);

        long[] quarterCounts = new long[4];

        for (Object[] row : results) {
            int quarter = ((Number) row[0]).intValue();
            long count = ((Number) row[1]).longValue();
            if (quarter >= 1 && quarter <= 4) {
                quarterCounts[quarter - 1] = count;
            }
        }

        Map<String, Object> response = new HashMap<>();
        response.put("year", year);
        response.put("labels", Arrays.asList("Quý 1", "Quý 2", "Quý 3", "Quý 4"));
        response.put("data", quarterCounts);
        return response;
    }

    @Override
    public Map<String, Object> getPropertyStatsByQuarter(int year) {
        List<Object[]> results = propertyRepository.countPropertiesByQuarterInYear(year);
        long[] quarterCounts = new long[4];

        for (Object[] row : results) {
            int quarter = ((Number) row[0]).intValue();
            long count = ((Number) row[1]).longValue();
            if (quarter >= 1 && quarter <= 4) {
                quarterCounts[quarter - 1] = count;
            }
        }

        Map<String, Object> response = new HashMap<>();
        response.put("year", year);
        response.put("labels", Arrays.asList("Quý 1", "Quý 2", "Quý 3", "Quý 4"));
        response.put("data", quarterCounts);
        return response;
    }

    @Override
    public Map<String, Object> getInteractionStatsByQuarter(int year) {
        List<Object[]> results = interactionRepository.countInteractionsByQuarterInYear(year);
        long[] quarterCounts = new long[4];

        for (Object[] row : results) {
            int quarter = ((Number) row[0]).intValue();
            long count = ((Number) row[1]).longValue();
            if (quarter >= 1 && quarter <= 4) {
                quarterCounts[quarter - 1] = count;
            }
        }

        Map<String, Object> response = new HashMap<>();
        response.put("year", year);
        response.put("labels", Arrays.asList("Quý 1", "Quý 2", "Quý 3", "Quý 4"));
        response.put("data", quarterCounts);
        return response;
    }
}
