package com.ndnt.controlleradvices;

import com.ndnt.controlleradvices.exceptions.DuplicateCodeException;
import com.ndnt.model.dto.response.ResponseDTO;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;

@ControllerAdvice
public class DuplicateDataExceptionHandler {
    @ExceptionHandler(DuplicateCodeException.class)
    public ResponseEntity<?> duplicateCodeHandler(DuplicateCodeException ex) {
        ResponseDTO responseDTO = new ResponseDTO();
        responseDTO.setMessage(ex.getMessage());
        responseDTO.setDetail(ex.toString());

        return new ResponseEntity<>(responseDTO, HttpStatus.BAD_REQUEST);
    }
}
