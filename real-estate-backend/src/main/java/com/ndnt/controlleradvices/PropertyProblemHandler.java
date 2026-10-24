package com.ndnt.controlleradvices;

import com.ndnt.model.dto.response.ResponseDTO;
import com.ndnt.services.property.PropertyProblem;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice
public class PropertyProblemHandler {
    @ExceptionHandler({org.springframework.dao.PessimisticLockingFailureException.class,
                       org.springframework.dao.OptimisticLockingFailureException.class})
    public ResponseEntity<ResponseDTO> conflict(RuntimeException ex) {
        return handle(new PropertyProblem(409, "CONFLICT", "Bài đăng đang được cập nhật; vui lòng tải lại"));
    }

    @ExceptionHandler(PropertyProblem.class)
    public ResponseEntity<ResponseDTO> handle(PropertyProblem ex) {
        ResponseDTO response = new ResponseDTO();
        response.setMessage(ex.getMessage()); response.setDetail(ex.getCode()); response.setData(ex.getFields());
        return ResponseEntity.status(ex.getStatus()).body(response);
    }
}
