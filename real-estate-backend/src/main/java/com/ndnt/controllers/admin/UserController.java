package com.ndnt.controllers.admin;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.ModelAndView;

@Controller
@RequestMapping("/admin")
public class UserController {

    @GetMapping("/login")
    public ModelAndView loginView() {
        return new ModelAndView("login");
    }
}
