package com.ndnt.controllers.api;

import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdTokenVerifier;
import com.google.api.client.http.javanet.NetHttpTransport;
import com.google.api.client.json.gson.GsonFactory;
import com.ndnt.model.dto.UserDTO;
import com.ndnt.model.dto.UserInfoDTO;
import com.ndnt.model.dto.request.ForgotPasswordRequest;
import com.ndnt.model.dto.request.ResetPasswordRequest;
import com.ndnt.model.dto.request.VerifyOtpRequest;
import com.ndnt.model.dto.response.ForgotPasswordResponse;
import com.ndnt.model.dto.response.ResponseDTO;
import com.ndnt.model.entity.UserEntity;
import com.ndnt.services.EmailService;
import com.ndnt.services.OtpService;
import com.ndnt.services.UserService;
import com.ndnt.utils.JwtUtils;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.BindingResult;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.Collections;
import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/auth")
public class APILoginController {
    @Autowired
    private UserService userService;

    @Autowired
    private JwtUtils jwtUtils;

    @Autowired
    private EmailService emailService;

    @Autowired
    private OtpService otpService;

    @Value("${GOOGLE_CLIENT_ID}")
    private String GOOGLE_CLIENT_ID;
    @Value("${FACEBOOK_APP_ID}")
    private String FACEBOOK_APP_ID;
    @Value("${FACEBOOK_APP_SECRET}")
    private String FACEBOOK_APP_SECRET;

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody UserDTO userDTO) {
        UserDTO fullUserDTO = this.userService.findByUsername(userDTO.getUsername());
        if (fullUserDTO == null) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("Tài khoản không tồn tại! Vui lòng đăng ký để thực hiện đăng nhập!");
        }

        if (this.userService.authenticate(userDTO.getUsername(), userDTO.getPassword())) {
            try {
                String token = this.jwtUtils.generateToken(fullUserDTO);
                return ResponseEntity.ok().body(Collections.singletonMap("token", token));
            } catch (Exception e) {
                return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("Lỗi khi tạo token");
            }
        }
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Sai thông tin đăng nhập");
    }

    @PostMapping(path = "/register", consumes = MediaType.APPLICATION_JSON_VALUE, produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<?> registerUser(@Valid @RequestBody UserInfoDTO infoDTO, BindingResult bindingResult) {
        if (bindingResult.hasErrors()) {
            Map<String, String> errors = new HashMap<>();
            for (FieldError fieldError : bindingResult.getFieldErrors()) {
                errors.put(fieldError.getField(), fieldError.getDefaultMessage());
            }
            return ResponseEntity.badRequest().body(errors);
        }

        ResponseDTO responseDTO = new ResponseDTO();
        try {
            this.userService.createOrUpdateUser(infoDTO);

            responseDTO.setMessage("Register Success");
            return ResponseEntity.ok().body(responseDTO);
        } catch (Exception e) {
            responseDTO.setMessage(e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(responseDTO);
        }
    }

    @PostMapping("/google")
    public ResponseEntity<Map<String, Object>> loginWithGoogle(@RequestBody Map<String, String> body) {
        String idTokenString = body.get("idToken");
        Map<String, Object> response = new HashMap<>();
        try {
            GoogleIdTokenVerifier verifier = new GoogleIdTokenVerifier.Builder(new NetHttpTransport(), new GsonFactory())
                    .setAudience(Collections.singletonList(GOOGLE_CLIENT_ID))
                    .build();

            GoogleIdToken idToken = verifier.verify(idTokenString);
            if (idToken != null) {
                GoogleIdToken.Payload payload = idToken.getPayload();

                String email = payload.getEmail();
                String name = (String) payload.get("name");
                String pictureUrl = (String) payload.get("picture");

                UserDTO existingUser = userService.findByUsername(email);

                if (existingUser == null) {
                    UserInfoDTO userDTO = new UserInfoDTO();
                    userDTO.setEmail(email);
                    userDTO.setFullname(name != null ? name : email);
                    userDTO.setUsername(email);
                    userDTO.setAvatar(pictureUrl);
                    userDTO.setPhone("gg_" + (System.currentTimeMillis() % 100000000000L));
                    String randomPassword = java.util.UUID.randomUUID().toString();
                    userDTO.setPassword(randomPassword);

                    userService.createOrUpdateUser(userDTO);
                    existingUser = userService.findByUsername(email);
                }

                String jwtToken = this.jwtUtils.generateToken(existingUser);

                response.put("status", "SUCCESS");
                response.put("message", "Đăng nhập Google thành công");
                response.put("token", jwtToken);
                response.put("user", existingUser);
                return ResponseEntity.ok(response);
            } else {
                response.put("status", "FAIL");
                response.put("message", "Token Google không hợp lệ");
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(response);
            }
        } catch (Exception e) {
            e.printStackTrace();
            response.put("status", "ERROR");
            response.put("message", "Lỗi server: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
        }
    }

    @PostMapping("/facebook")
    public ResponseEntity<Map<String, Object>> loginWithFacebook(@RequestBody Map<String, String> body) {
        String accessToken = body.get("accessToken");
        Map<String, Object> response = new HashMap<>();
        try {
            String appAccessToken = FACEBOOK_APP_ID + "|" + FACEBOOK_APP_SECRET;
            String debugUrl = "https://graph.facebook.com/debug_token?input_token=" + accessToken + "&access_token=" + appAccessToken;

            URL urlDebug = new URL(debugUrl);
            HttpURLConnection conDebug = (HttpURLConnection) urlDebug.openConnection();
            conDebug.setRequestMethod("GET");

            if (conDebug.getResponseCode() != 200) {
                response.put("status", "FAIL");
                response.put("message", "Lỗi xác minh token với Facebook.");
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(response);
            }

            BufferedReader inDebug = new BufferedReader(new InputStreamReader(conDebug.getInputStream()));
            String outputDebug;
            StringBuilder resultDebug = new StringBuilder();
            while ((outputDebug = inDebug.readLine()) != null) {
                resultDebug.append(outputDebug);
            }
            inDebug.close();

            com.google.gson.JsonObject debugJson = com.google.gson.JsonParser.parseString(resultDebug.toString()).getAsJsonObject();
            com.google.gson.JsonObject dataJson = debugJson.getAsJsonObject("data");

            if (!dataJson.has("app_id") || !dataJson.get("app_id").getAsString().equals(FACEBOOK_APP_ID)) {
                response.put("status", "FAIL");
                response.put("message", "Cảnh báo bảo mật: Token không thuộc về ứng dụng này!");
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(response);
            }

            if (!dataJson.get("is_valid").getAsBoolean()) {
                response.put("status", "FAIL");
                response.put("message", "Token Facebook đã hết hạn hoặc bị thu hồi.");
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(response);
            }

            String fbGraphUrl = "https://graph.facebook.com/me?fields=id,name,email,picture.width(200).height(200)&access_token=" + accessToken;
            URL url = new URL(fbGraphUrl);
            HttpURLConnection con = (HttpURLConnection) url.openConnection();
            con.setRequestMethod("GET");

            int responseCode = con.getResponseCode();
            if (responseCode == 200) {
                BufferedReader in = new BufferedReader(new InputStreamReader(con.getInputStream()));
                String output;
                StringBuilder result = new StringBuilder();
                while ((output = in.readLine()) != null) {
                    result.append(output);
                }
                in.close();

                String jsonResponse = result.toString();
                com.google.gson.JsonObject jsonObject = com.google.gson.JsonParser.parseString(jsonResponse).getAsJsonObject();

                String facebookId = jsonObject.get("id").getAsString();
                String name = jsonObject.has("name") ? jsonObject.get("name").getAsString() : "fb_" + facebookId;

                String pictureUrl = "https://graph.facebook.com/" + facebookId + "/picture?type=large";
                if (jsonObject.has("picture")) {
                    com.google.gson.JsonObject pictureObj = jsonObject.getAsJsonObject("picture");
                    if (pictureObj.has("data")) {
                        com.google.gson.JsonObject dataObj = pictureObj.getAsJsonObject("data");
                        String rawUrl = dataObj.has("url") ? dataObj.get("url").getAsString() : "";
                        if (!rawUrl.isEmpty() && rawUrl.length() <= 250) {
                            pictureUrl = rawUrl;
                        }
                    }
                }
                String email = jsonObject.has("email") ? jsonObject.get("email").getAsString() : facebookId + "@facebook.com";

                UserDTO existingUser = userService.findByUsername(name);

                if (existingUser == null) {
                    UserInfoDTO userDTO = new UserInfoDTO();
                    userDTO.setUsername(name);
                    userDTO.setFullname(name);
                    userDTO.setAvatar(pictureUrl);
                    userDTO.setEmail(email);
                    String phoneVal = "fb_" + facebookId;
                    if (phoneVal.length() > 20) {
                        phoneVal = phoneVal.substring(0, 20);
                    }
                    userDTO.setPhone(phoneVal);
                    String randomPassword = java.util.UUID.randomUUID().toString();
                    userDTO.setPassword(randomPassword);

                    userService.createOrUpdateUser(userDTO);
                    existingUser = userService.findByUsername(name);
                }

                String jwtToken = this.jwtUtils.generateToken(existingUser);

                response.put("status", "SUCCESS");
                response.put("message", "Đăng nhập Facebook thành công");
                response.put("token", jwtToken);
                response.put("user", existingUser);
                return ResponseEntity.ok(response);
            } else {
                response.put("status", "FAIL");
                response.put("message", "Token Facebook không hợp lệ");
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(response);
            }
        } catch (Exception e) {
            response.put("status", "ERROR");
            response.put("message", "Lỗi server: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
        }
    }

    @PostMapping("/forgot-password")
    public ResponseEntity<?> forgotPassword(@Valid @RequestBody ForgotPasswordRequest request, BindingResult bindingResult) {
        if (bindingResult.hasErrors()) {
            Map<String, String> errors = new HashMap<>();
            for (FieldError fieldError : bindingResult.getFieldErrors()) {
                errors.put(fieldError.getField(), fieldError.getDefaultMessage());
            }
            return ResponseEntity.badRequest().body(errors);
        }

        UserEntity user = this.userService.findEntityByIdentifier(request.getIdentifier());
        if (user == null) {
            Map<String, String> error = new HashMap<>();
            error.put("message", "Không tìm thấy tài khoản với thông tin đã nhập!");
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
        }

        String targetEmail = null;
        boolean hasExistingEmail = user.getEmail() != null && !user.getEmail().trim().isEmpty();

        if (hasExistingEmail) {
            targetEmail = user.getEmail().trim();
        } else {
            if (request.getEmail() == null || request.getEmail().trim().isEmpty()) {
                ForgotPasswordResponse response = ForgotPasswordResponse.builder()
                        .status("REQUIRE_EMAIL")
                        .hasEmail(false)
                        .identifier(request.getIdentifier())
                        .message("Tài khoản của bạn chưa cập nhật email. Vui lòng nhập email để nhận mã xác thực OTP.")
                        .build();
                return ResponseEntity.ok(response);
            }
            targetEmail = request.getEmail().trim();
        }

        String otp = this.otpService.generateOtp(request.getIdentifier(), targetEmail);
        this.emailService.sendOtpEmail(targetEmail, otp, user.getFullname());

        ForgotPasswordResponse response = ForgotPasswordResponse.builder()
                .status("OTP_SENT")
                .hasEmail(hasExistingEmail)
                .maskedEmail(maskEmail(targetEmail))
                .identifier(request.getIdentifier())
                .message("Mã xác thực OTP đã được gửi đến email " + maskEmail(targetEmail) + ". Vui lòng kiểm tra hộp thư!")
                .build();

        return ResponseEntity.ok(response);
    }

    @PostMapping("/verify-otp")
    public ResponseEntity<?> verifyOtp(@Valid @RequestBody VerifyOtpRequest request, BindingResult bindingResult) {
        if (bindingResult.hasErrors()) {
            Map<String, String> errors = new HashMap<>();
            for (FieldError fieldError : bindingResult.getFieldErrors()) {
                errors.put(fieldError.getField(), fieldError.getDefaultMessage());
            }
            return ResponseEntity.badRequest().body(errors);
        }

        boolean isValid = this.otpService.validateOtp(request.getIdentifier(), request.getOtp());
        if (!isValid) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("status", "FAIL");
            errorResponse.put("message", "Mã OTP không chính xác hoặc đã hết hạn. Vui lòng thử lại!");
            return ResponseEntity.badRequest().body(errorResponse);
        }

        String resetToken = this.otpService.getResetToken(request.getIdentifier());
        Map<String, Object> successResponse = new HashMap<>();
        successResponse.put("status", "SUCCESS");
        successResponse.put("message", "Xác thực mã OTP thành công!");
        successResponse.put("resetToken", resetToken);

        return ResponseEntity.ok(successResponse);
    }

    @PostMapping("/reset-password")
    public ResponseEntity<?> resetPassword(@Valid @RequestBody ResetPasswordRequest request, BindingResult bindingResult) {
        if (bindingResult.hasErrors()) {
            Map<String, String> errors = new HashMap<>();
            for (FieldError fieldError : bindingResult.getFieldErrors()) {
                errors.put(fieldError.getField(), fieldError.getDefaultMessage());
            }
            return ResponseEntity.badRequest().body(errors);
        }

        boolean isTokenValid = this.otpService.validateResetToken(request.getIdentifier(), request.getResetToken());
        if (!isTokenValid) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("status", "FAIL");
            errorResponse.put("message", "Yêu cầu đặt lại mật khẩu không hợp lệ hoặc đã hết hạn. Vui lòng thực hiện lại từ đầu!");
            return ResponseEntity.badRequest().body(errorResponse);
        }

        try {
            String emailToUpdate = request.getEmail();
            if (emailToUpdate == null || emailToUpdate.trim().isEmpty()) {
                emailToUpdate = this.otpService.getTargetEmail(request.getIdentifier());
            }

            this.userService.resetPassword(request.getIdentifier(), request.getNewPassword(), emailToUpdate);
            this.otpService.clear(request.getIdentifier());

            Map<String, Object> successResponse = new HashMap<>();
            successResponse.put("status", "SUCCESS");
            successResponse.put("message", "Đặt lại mật khẩu thành công! Bạn có thể đăng nhập bằng mật khẩu mới ngay bây giờ.");

            return ResponseEntity.ok(successResponse);
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("status", "ERROR");
            errorResponse.put("message", e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    private String maskEmail(String email) {
        if (email == null || !email.contains("@")) {
            return email;
        }
        int atIndex = email.indexOf("@");
        String name = email.substring(0, atIndex);
        String domain = email.substring(atIndex);
        if (name.length() <= 2) {
            return name.charAt(0) + "***" + domain;
        }
        return name.substring(0, 2) + "***" + domain;
    }
}
