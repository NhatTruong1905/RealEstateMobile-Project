package com.ndnt.services.impl;

import com.ndnt.model.entity.*;
import com.ndnt.model.enums.StatusProperty;
import com.ndnt.repositories.*;
import com.ndnt.services.*;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.TestPropertySource;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@TestPropertySource("/test.properties")
@Transactional
public class DeleteOperationIntegrationTest {

    @Autowired
    private UserService userService;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private RoleRepository roleRepository;

    @Autowired
    private RoleService roleService;

    @Autowired
    private DistrictRepository districtRepository;

    @Autowired
    private DistrictService districtService;

    @Autowired
    private WardRepository wardRepository;

    @Autowired
    private WardService wardService;

    @Autowired
    private PropertyTypeRepository propertyTypeRepository;

    @Autowired
    private PropertyTypeService propertyTypeService;

    @Autowired
    private PropertyCategoryRepository propertyCategoryRepository;

    @Autowired
    private PropertyCategoryService propertyCategoryService;

    @Autowired
    private PropertyRepository propertyRepository;

    @Autowired
    private PropertyService propertyService;

    @Autowired
    private InteractionTypeRepository interactionTypeRepository;

    @Autowired
    private InteractionTypeService interactionTypeService;

    @Autowired
    private InteractionRepository interactionRepository;

    @Autowired
    private InteractionService interactionService;

    // ==========================================
    // CÁC TEST XÓA MỀM (Soft Delete: Kiểm tra status = 0 hoặc DELETED)
    // ==========================================

    @Test
    @DisplayName("Xóa mềm User: Kiểm tra status = 0 trong DB sau khi xóa")
    void testSoftDeleteUser_StatusIsZeroInDb() {
        RoleEntity role = new RoleEntity();
        role.setCode("ROLE_TEST_USER");
        role.setName("Test User Role");
        role = roleRepository.save(role);

        UserEntity user = new UserEntity();
        user.setUsername("softdelete_user");
        user.setPassword("123456");
        user.setFullname("Nguyen Van Soft");
        user.setPhone("0987654321");
        user.setEmail("soft@test.com");
        user.setRole(role);
        user.setStatus(1);
        user = userRepository.save(user);

        // Thực hiện xóa mềm
        userService.deleteUser(user.getId());

        // Kiểm tra trong DB: Entity vẫn còn nhưng status = 0
        Optional<UserEntity> updatedUserOpt = userRepository.findById(user.getId());
        assertTrue(updatedUserOpt.isPresent(), "User vẫn còn trong DB");
        assertEquals(0, updatedUserOpt.get().getStatus(), "Status của User phải là 0 sau khi xóa mềm");
    }

    @Test
    @DisplayName("Xóa mềm Property: Kiểm tra status = 'Đã xóa' (DELETED) trong DB")
    void testSoftDeleteProperty_StatusIsDeletedInDb() {
        RoleEntity role = new RoleEntity();
        role.setCode("ROLE_TEST_SELLER");
        role.setName("Test Seller Role");
        role = roleRepository.save(role);

        UserEntity user = new UserEntity();
        user.setUsername("seller_prop_user");
        user.setPassword("123456");
        user.setRole(role);
        user.setStatus(1);
        user = userRepository.save(user);

        DistrictEntity district = new DistrictEntity();
        district.setCode("Q_TEST");
        district.setName("Quận Test");
        district = districtRepository.save(district);

        WardEntity ward = new WardEntity();
        ward.setCode("P_TEST");
        ward.setName("Phường Test");
        ward.setDistrict(district);
        ward = wardRepository.save(ward);

        PropertyTypeEntity type = new PropertyTypeEntity();
        type.setCode("TYPE_TEST");
        type.setName("Nhà phố");
        type = propertyTypeRepository.save(type);

        PropertyCategoryEntity category = new PropertyCategoryEntity();
        category.setCode("CAT_TEST");
        category.setName("Cao cấp");
        category = propertyCategoryRepository.save(category);

        PropertyEntity property = new PropertyEntity();
        property.setTitle("Nhà đẹp trung tâm");
        property.setUser(user);
        property.setWard(ward);
        property.setType(type);
        property.setCategory(category);
        property.setAddress("123 Đường Test");
        property.setCity("TP HCM");
        property.setPrice(BigDecimal.valueOf(5000000000L));
        property.setArea(BigDecimal.valueOf(100));
        property.setStatus(StatusProperty.PUBLISHED.getStatus());
        property = propertyRepository.save(property);

        // Thực hiện xóa mềm
        propertyService.deleteProperty(property.getId());

        // Kiểm tra trong DB: Entity vẫn còn nhưng status = 'Đã xóa'
        Optional<PropertyEntity> updatedPropertyOpt = propertyRepository.findById(property.getId());
        assertTrue(updatedPropertyOpt.isPresent(), "Property vẫn còn trong DB");
        assertEquals(StatusProperty.DELETED.getStatus(), updatedPropertyOpt.get().getStatus(), "Status phải là 'Đã xóa'");
    }

    @Test
    @DisplayName("Xóa mềm Interaction: Kiểm tra status = 0 trong DB")
    void testSoftDeleteInteraction_StatusIsZeroInDb() {
        RoleEntity role = new RoleEntity();
        role.setCode("ROLE_INTERACTION_TEST");
        role.setName("Role Test");
        role = roleRepository.save(role);

        UserEntity sender = new UserEntity();
        sender.setUsername("sender_user");
        sender.setPassword("123456");
        sender.setRole(role);
        sender.setStatus(1);
        sender = userRepository.save(sender);

        UserEntity receiver = new UserEntity();
        receiver.setUsername("receiver_user");
        receiver.setPassword("123456");
        receiver.setRole(role);
        receiver.setStatus(1);
        receiver = userRepository.save(receiver);

        DistrictEntity district = new DistrictEntity();
        district.setCode("Q_INTERACTION");
        district.setName("Quận Interaction");
        district = districtRepository.save(district);

        WardEntity ward = new WardEntity();
        ward.setCode("P_INTERACTION");
        ward.setName("Phường Interaction");
        ward.setDistrict(district);
        ward = wardRepository.save(ward);

        PropertyTypeEntity type = new PropertyTypeEntity();
        type.setCode("TYPE_INTERACTION");
        type.setName("Căn hộ");
        type = propertyTypeRepository.save(type);

        PropertyCategoryEntity category = new PropertyCategoryEntity();
        category.setCode("CAT_INTERACTION");
        category.setName("Trung cấp");
        category = propertyCategoryRepository.save(category);

        PropertyEntity property = new PropertyEntity();
        property.setTitle("Căn hộ test tương tác");
        property.setUser(receiver);
        property.setWard(ward);
        property.setType(type);
        property.setCategory(category);
        property.setAddress("456 Đường Test");
        property.setCity("TP HCM");
        property.setPrice(BigDecimal.valueOf(2000000000L));
        property.setArea(BigDecimal.valueOf(70));
        property.setStatus(StatusProperty.PUBLISHED.getStatus());
        property = propertyRepository.save(property);

        InteractionTypeEntity interactionType = new InteractionTypeEntity();
        interactionType.setCode("INTERACT_TEST");
        interactionType.setName("Nhắn tin");
        interactionType = interactionTypeRepository.save(interactionType);

        InteractionEntity interaction = new InteractionEntity();
        interaction.setProperty(property);
        interaction.setSender(sender);
        interaction.setReceiver(receiver);
        interaction.setInteractionType(interactionType);
        interaction.setMessage("Tôi quan tâm căn nhà này");
        interaction.setStatus(1);
        interaction = interactionRepository.save(interaction);

        // Thực hiện xóa mềm
        interactionService.deleteInteraction(interaction.getId());

        // Kiểm tra trong DB: Entity vẫn còn nhưng status = 0
        Optional<InteractionEntity> updatedOpt = interactionRepository.findById(interaction.getId());
        assertTrue(updatedOpt.isPresent(), "Interaction vẫn còn trong DB");
        assertEquals(0, updatedOpt.get().getStatus(), "Status của Interaction phải là 0 sau khi xóa mềm");
    }

    // ==========================================
    // CÁC TEST XÓA CỨNG (Hard Delete: Kiểm tra KHÔNG CÒN trong DB)
    // ==========================================

    @Test
    @DisplayName("Xóa cứng Ward: Kiểm tra không còn tồn tại trong DB sau khi xóa")
    void testHardDeleteWard_NotFoundInDb() {
        DistrictEntity district = new DistrictEntity();
        district.setCode("Q_HARD_WARD");
        district.setName("Quận Hard Ward");
        district = districtRepository.save(district);

        WardEntity ward = new WardEntity();
        ward.setCode("P_HARD_1");
        ward.setName("Phường Hard 1");
        ward.setDistrict(district);
        ward = wardRepository.save(ward);
        Integer wardId = ward.getId();

        // Thực hiện xóa cứng
        wardService.deleteWard(wardId);

        // Tìm thử trong DB -> Phải trống (empty)
        Optional<WardEntity> found = wardRepository.findById(wardId);
        assertTrue(found.isEmpty(), "Ward không còn tồn tại trong DB sau khi xóa cứng");
    }

    @Test
    @DisplayName("Xóa cứng District: Kiểm tra không còn tồn tại trong DB sau khi xóa")
    void testHardDeleteDistrict_NotFoundInDb() {
        DistrictEntity district = new DistrictEntity();
        district.setCode("Q_HARD_DISTRICT");
        district.setName("Quận Hard District");
        district = districtRepository.save(district);
        Integer districtId = district.getId();

        // Thực hiện xóa cứng
        districtService.deleteDistrict(districtId);

        // Tìm thử trong DB -> Phải trống (empty)
        Optional<DistrictEntity> found = districtRepository.findById(districtId);
        assertTrue(found.isEmpty(), "District không còn tồn tại trong DB sau khi xóa cứng");
    }

    @Test
    @DisplayName("Xóa cứng Role: Kiểm tra không còn tồn tại trong DB sau khi xóa")
    void testHardDeleteRole_NotFoundInDb() {
        RoleEntity role = new RoleEntity();
        role.setCode("ROLE_HARD_DELETE");
        role.setName("Role Hard Delete");
        role = roleRepository.save(role);
        Integer roleId = role.getId();

        // Thực hiện xóa cứng
        roleService.deleteRole(roleId);

        // Tìm thử trong DB -> Phải trống (empty)
        Optional<RoleEntity> found = roleRepository.findById(roleId);
        assertTrue(found.isEmpty(), "Role không còn tồn tại trong DB sau khi xóa cứng");
    }

    @Test
    @DisplayName("Xóa cứng PropertyType: Kiểm tra không còn tồn tại trong DB sau khi xóa")
    void testHardDeletePropertyType_NotFoundInDb() {
        PropertyTypeEntity type = new PropertyTypeEntity();
        type.setCode("TYPE_HARD_DELETE");
        type.setName("Type Hard Delete");
        type = propertyTypeRepository.save(type);
        Integer typeId = type.getId();

        // Thực hiện xóa cứng
        propertyTypeService.deletePropertyType(typeId);

        // Tìm thử trong DB -> Phải trống (empty)
        Optional<PropertyTypeEntity> found = propertyTypeRepository.findById(Integer.valueOf(typeId));
        assertTrue(found.isEmpty(), "PropertyType không còn tồn tại trong DB sau khi xóa cứng");
    }

    @Test
    @DisplayName("Xóa cứng PropertyCategory: Kiểm tra không còn tồn tại trong DB sau khi xóa")
    void testHardDeletePropertyCategory_NotFoundInDb() {
        PropertyCategoryEntity category = new PropertyCategoryEntity();
        category.setCode("CAT_HARD_DELETE");
        category.setName("Cat Hard Delete");
        category = propertyCategoryRepository.save(category);
        Integer categoryId = category.getId();

        // Thực hiện xóa cứng
        propertyCategoryService.deletePropertyCategory(categoryId);

        // Tìm thử trong DB -> Phải trống (empty)
        Optional<PropertyCategoryEntity> found = propertyCategoryRepository.findById(Integer.valueOf(categoryId));
        assertTrue(found.isEmpty(), "PropertyCategory không còn tồn tại trong DB sau khi xóa cứng");
    }

    @Test
    @DisplayName("Xóa cứng InteractionType: Kiểm tra không còn tồn tại trong DB sau khi xóa")
    void testHardDeleteInteractionType_NotFoundInDb() {
        InteractionTypeEntity type = new InteractionTypeEntity();
        type.setCode("INTERACT_TYPE_HARD");
        type.setName("Interaction Type Hard");
        type = interactionTypeRepository.save(type);
        Integer typeId = type.getId();

        // Thực hiện xóa cứng
        interactionTypeService.deleteInteractionType(typeId);

        // Tìm thử trong DB -> Phải trống (empty)
        Optional<InteractionTypeEntity> found = interactionTypeRepository.findById(typeId);
        assertTrue(found.isEmpty(), "InteractionType không còn tồn tại trong DB sau khi xóa cứng");
    }
}
