package com.ndnt.controlleradvices;

import com.ndnt.model.dto.response.ResponseDTO;
import com.ndnt.services.storage.StorageProblem;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.multipart.MaxUploadSizeExceededException;

@RestControllerAdvice
public class StorageProblemHandler {
    @ExceptionHandler(StorageProblem.class)
    public ResponseEntity<ResponseDTO> handle(StorageProblem ex) {
        ResponseDTO response = new ResponseDTO();
        response.setMessage(ex.getMessage());
        response.setDetail(ex.getCode());
        return ResponseEntity.status(ex.getStatus()).body(response);
    }
    @ExceptionHandler(MaxUploadSizeExceededException.class)
    public ResponseEntity<ResponseDTO> tooLarge(MaxUploadSizeExceededException ex) {
        return handle(new StorageProblem(413, "IMAGE_TOO_LARGE", "Tối đa 5 MB mỗi ảnh và 15 MB mỗi request"));
    }
}
