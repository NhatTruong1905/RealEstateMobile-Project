package com.ndnt.controlleradvices;

import com.ndnt.controlleradvices.exceptions.DuplicateCodeException;
import com.ndnt.controlleradvices.exceptions.DuplicateEmailException;
import com.ndnt.controlleradvices.exceptions.DuplicatePhoneException;
import com.ndnt.controlleradvices.exceptions.DuplicateUsernameException;
import com.ndnt.model.dto.response.ResponseDTO;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;

import java.util.HashMap;
import java.util.Map;

@ControllerAdvice
public class DuplicateDataExceptionHandler {
    @ExceptionHandler(DuplicateCodeException.class)
    public ResponseEntity<?> duplicateCodeHandler(DuplicateCodeException ex) {
        ResponseDTO responseDTO = new ResponseDTO();
        responseDTO.setMessage(ex.getMessage());
        responseDTO.setDetail(ex.toString());
        return new ResponseEntity<>(responseDTO, HttpStatus.BAD_REQUEST);
    }

    @ExceptionHandler(DuplicateUsernameException.class)
    public ResponseEntity<?> duplicateUsernameHandler(DuplicateUsernameException ex) {
        Map<String, String> errors = new HashMap<>();
        errors.put("username", ex.getMessage());

        return ResponseEntity.badRequest().body(errors);
    }

    @ExceptionHandler(DuplicatePhoneException.class)
    public ResponseEntity<?> duplicatePhoneHandler(DuplicatePhoneException ex) {
        Map<String, String> errors = new HashMap<>();
        errors.put("phone", ex.getMessage());
        return ResponseEntity.badRequest().body(errors);
    }

    @ExceptionHandler(DuplicateEmailException.class)
    public ResponseEntity<?> duplicateEmailHandler(DuplicateEmailException ex) {
        Map<String, String> errors = new HashMap<>();
        errors.put("email", ex.getMessage());
        return ResponseEntity.badRequest().body(errors);
    }
}
