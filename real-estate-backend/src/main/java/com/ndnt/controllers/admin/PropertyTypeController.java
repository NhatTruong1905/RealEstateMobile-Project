package com.ndnt.controllers.admin;

import com.ndnt.model.dto.PropertyTypeDTO;
import com.ndnt.services.PropertyTypeService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.ModelAndView;

@RestController
@RequestMapping("/admin")
public class PropertyTypeController {
    @Autowired
    private PropertyTypeService propertyTypeService;

    @GetMapping("/property-types-list")
    public ModelAndView listPropertyType() {
        ModelAndView mav = new ModelAndView("property_type/list");
        mav.addObject("propertyTypes", this.propertyTypeService.getPropertyTypes());

        return mav;
    }

    @GetMapping("/property-types-edit")
    public ModelAndView addPropertyType(@ModelAttribute(name = "propertyType") PropertyTypeDTO propertyTypeDTO) {
        return new ModelAndView("property_type/edit");
    }

    @GetMapping("/property-types-edit-{id}")
    public ModelAndView editPropertyType(@PathVariable Integer id) {
        ModelAndView mav = new ModelAndView("property_type/edit");
        mav.addObject("propertyType", this.propertyTypeService.findById(id));
        return mav;
    }
}
