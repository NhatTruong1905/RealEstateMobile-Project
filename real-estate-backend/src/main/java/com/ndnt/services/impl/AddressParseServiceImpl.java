package com.ndnt.services.impl;

import com.ndnt.model.dto.AddressParseResult;
import com.ndnt.services.AddressParseService;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.ai.chat.messages.SystemMessage;
import org.springframework.ai.chat.messages.UserMessage;
import org.springframework.ai.chat.prompt.Prompt;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class AddressParseServiceImpl implements AddressParseService {
    private final ChatClient chatClient;

    public AddressParseServiceImpl(ChatClient.Builder builder) {
        this.chatClient = builder.build();
    }

    @Override
    public AddressParseResult parseAddress(String rawAddress) {
        SystemMessage systemMessage = new SystemMessage("""
                You are an expert Vietnamese real estate address parser.
                Your task is to extract address components from a raw string:
                1. addressDetail: Alley number, house number, street name (e.g., "221/45E").
                2. wardName: Name of the Ward or Commune (e.g., "Đông Thạnh").
                3. districtName: Name of the District (e.g., "Hóc Môn").
                4. cityName: Name of the City or Province (e.g., "Hồ Chí Minh").
                
                Always return standardized Vietnamese words.
                """);

        UserMessage userMessage = new UserMessage("Parse this address: " + rawAddress);
        Prompt prompt = new Prompt(List.of(systemMessage, userMessage));

        return this.chatClient.prompt(prompt)
                .call()
                .entity(AddressParseResult.class);
    }

}
