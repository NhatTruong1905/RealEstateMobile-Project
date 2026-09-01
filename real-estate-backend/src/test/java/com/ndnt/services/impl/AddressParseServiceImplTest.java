package com.ndnt.services.impl;

import com.ndnt.model.dto.AddressParseResult;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Answers;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.ai.chat.prompt.Prompt;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class AddressParseServiceImplTest {

    @Mock
    private ChatClient.Builder chatClientBuilder;

    @Mock(answer = Answers.RETURNS_DEEP_STUBS)
    private ChatClient chatClient;

    @Test
    @DisplayName("parseAddress - Phân tích địa chỉ sử dụng Spring AI ChatClient")
    void parseAddress_Success() {
        when(chatClientBuilder.build()).thenReturn(chatClient);

        AddressParseResult expectedResult = new AddressParseResult(
                "221/45E",
                "Đông Thạnh",
                "Hóc Môn",
                "Hồ Chí Minh"
        );

        when(chatClient.prompt(any(Prompt.class))
                .call()
                .entity(AddressParseResult.class))
                .thenReturn(expectedResult);

        AddressParseServiceImpl addressParseService = new AddressParseServiceImpl(chatClientBuilder);
        AddressParseResult result = addressParseService.parseAddress("221/45E Đông Thạnh, Hóc Môn, Hồ Chí Minh");

        assertNotNull(result);
        assertEquals("Hồ Chí Minh", result.cityName());
        assertEquals("Hóc Môn", result.districtName());
        assertEquals("Đông Thạnh", result.wardName());
        assertEquals("221/45E", result.addressDetail());
    }
}
