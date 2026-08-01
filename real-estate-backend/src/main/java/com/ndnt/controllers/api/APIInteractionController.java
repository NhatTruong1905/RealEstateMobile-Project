package com.ndnt.controllers.api;

import com.ndnt.model.dto.InteractionDTO;
import com.ndnt.model.dto.UserDTO;
import com.ndnt.model.dto.response.ResponseDTO;
import com.ndnt.services.InteractionService;
import com.ndnt.services.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.List;

@RestController
@RequestMapping("/api/secure")
public class APIInteractionController {
    @Autowired
    private InteractionService interactionService;

    @Autowired
    private UserService userService;

    @PostMapping("/interactions")
    public ResponseEntity<?> addInteraction(@RequestBody InteractionDTO interactionDTO) {
        this.interactionService.createOrUpdateInteraction(interactionDTO);
        ResponseDTO responseDTO = new ResponseDTO();
        responseDTO.setMessage("Success");
        return ResponseEntity.ok().body(responseDTO);
    }

    @GetMapping("/interactions/property/{propertyId}")
    public ResponseEntity<?> getInteractionOfSender(@PathVariable Integer propertyId, Principal principal) {
        ResponseDTO responseDTO = new ResponseDTO();

        UserDTO userDTO = this.userService.findByUsername(principal.getName());
        if (userDTO != null) {
            List<InteractionDTO> interactionDTO = this.interactionService.getInteractionOfSender(propertyId, userDTO.getId());
            responseDTO.setMessage("Success");
            responseDTO.setData(interactionDTO);
            return ResponseEntity.ok().body(responseDTO);
        } else {
            responseDTO.setMessage("Error");
            return ResponseEntity.badRequest().body(responseDTO);
        }
    }

    @GetMapping("/interactions-receiver")
    public ResponseEntity<?> getInteractionsOfReceiver(Principal principal) {
        ResponseDTO responseDTO = new ResponseDTO();

        UserDTO userDTO = this.userService.findByUsername(principal.getName());
        if (userDTO != null) {
            List<InteractionDTO> interactionDTOs = this.interactionService.getInteractionsOfReiver(userDTO.getId());
            responseDTO.setData(interactionDTOs);
            responseDTO.setMessage("Success");
            return ResponseEntity.ok().body(responseDTO);
        } else {
            responseDTO.setMessage("Error");
            return ResponseEntity.badRequest().body(responseDTO);
        }
    }

    @PostMapping("/interactions/completed")
    public ResponseEntity<?> viewingCompleted(@RequestBody List<InteractionDTO> interactionDTOs) {
        ResponseDTO responseDTO = new ResponseDTO();
        this.interactionService.viewingCompleted(interactionDTOs);
        responseDTO.setMessage("Success");
        return ResponseEntity.ok().body(responseDTO);
    }
}
