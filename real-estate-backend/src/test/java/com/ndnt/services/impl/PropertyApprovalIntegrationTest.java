package com.ndnt.services.impl;

import com.cloudinary.Cloudinary;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.ndnt.model.dto.*;
import com.ndnt.model.entity.*;
import com.ndnt.model.enums.StatusProperty;
import com.ndnt.repositories.*;
import com.ndnt.services.*;
import com.ndnt.services.property.*;
import com.ndnt.utils.JwtUtils;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.*;
import org.springframework.test.web.servlet.request.MockMultipartHttpServletRequestBuilder;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.WebApplicationContext;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.*;
import java.util.concurrent.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;
import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest(properties={"spring.config.location=classpath:test.properties","spring.datasource.url=jdbc:h2:mem:approval;MODE=MYSQL;NON_KEYWORDS=USER;DB_CLOSE_DELAY=-1;LOCK_TIMEOUT=10000",
    "spring.jpa.show-sql=false", "property.mail.worker-enabled=false", "property.mail.max-attempts=2"})
@TestPropertySource("/test.properties")
class PropertyApprovalIntegrationTest {
    @Autowired WebApplicationContext context;
    @Autowired PlatformTransactionManager transactionManager;
    @Autowired PropertyService service;
    @Autowired PropertyRepository properties;
    @Autowired PropertyMailEventRepository events;
    @Autowired PropertyMailDelivery delivery;
    @Autowired UserRepository users;
    @Autowired RoleRepository roles;
    @Autowired WardRepository wards;
    @Autowired DistrictRepository districts;
    @Autowired PropertyTypeRepository types;
    @Autowired PropertyCategoryRepository categories;
    @Autowired AssignmentPropertyRepository assignments;
    @Autowired FavoritePropertyService favorites;
    @Autowired JwtUtils jwt;
    @MockitoBean AddressParseService parser;
    @MockitoBean Cloudinary cloudinary;
    @MockitoBean PropertyMailer mailer;
    MockMvc mvc;
    ObjectMapper json = new ObjectMapper();
    UserEntity owner, other, staff, unassigned, admin;
    Integer wardId, typeId, categoryId;
    TransactionTemplate tx;

    @BeforeEach void setup() {
        mvc = MockMvcBuilders.webAppContextSetup(context).apply(springSecurity()).build();
        tx = new TransactionTemplate(transactionManager);
        String suffix = UUID.randomUUID().toString().substring(0,8);
        RoleEntity userRole = role("USER", suffix), staffRole = role("STAFF",suffix), adminRole = role("ADMIN",suffix);
        owner = account("owner"+suffix, userRole); other = account("other"+suffix,userRole);
        staff = account("staff"+suffix,staffRole); unassigned = account("unassigned"+suffix,staffRole); admin = account("admin"+suffix,adminRole);
        DistrictEntity d = new DistrictEntity(); d.setCode("D"+suffix); d.setName("Quận thử"); d = districts.save(d);
        WardEntity w = new WardEntity(); w.setCode("W"+suffix); w.setName("Phường thử "+suffix); w.setDistrict(d); wardId = wards.save(w).getId();
        PropertyTypeEntity t = new PropertyTypeEntity(); t.setCode("T"+suffix); t.setName("Nhà thử"); typeId = types.save(t).getId();
        PropertyCategoryEntity c = new PropertyCategoryEntity(); c.setCode("C"+suffix); c.setName("Bán thử"); categoryId = categories.save(c).getId();
        reset(parser,mailer);
    }
    @AfterEach void clear() { SecurityContextHolder.clearContext(); }
    RoleEntity role(String code, String suffix) {
        // Canonical roles are shared across fixtures, matching real account authority codes.
        return roles.findAll().stream().filter(r -> r.getCode().equals("ROLE_"+code)).findFirst().orElseGet(() -> {
            RoleEntity r = new RoleEntity(); r.setCode("ROLE_"+code); r.setName(code); return roles.save(r);
        });
    }
    UserEntity account(String name,RoleEntity role) {
        UserEntity u = new UserEntity(); u.setUsername(name); u.setPassword("test-only"); u.setRole(role);
        u.setEmail(name+"@example.invalid"); u.setFullname("Chủ <b>thử</b>"); return users.save(u);
    }
    void auth(UserEntity actor) {
        SecurityContextHolder.getContext().setAuthentication(new UsernamePasswordAuthenticationToken(actor.getUsername(),null,
            List.of(new SimpleGrantedAuthority(actor.getRole().getCode()))));
    }
    String bearer(UserEntity actor) throws Exception {
        UserDTO dto = new UserDTO(); dto.setId(actor.getId()); dto.setUsername(actor.getUsername()); dto.setRoleCode(actor.getRole().getCode());
        return "Bearer "+jwt.generateToken(dto);
    }
    PropertyDTO form() {
        PropertyDTO dto = new PropertyDTO(); dto.setTitle("Nhà <script>thử</script>"); dto.setAddress("123 đường thử");
        dto.setLegal("Sổ hồng"); dto.setPrice(new BigDecimal("1000000")); dto.setArea(new BigDecimal("60"));
        dto.setTypeId(typeId); dto.setCategoryId(categoryId); dto.setWardId(wardId); dto.setCity("Hồ Chí Minh"); return dto;
    }
    PropertyDTO create() { auth(owner); return service.saveOwnedProperty(form()); }
    void assign(Integer id) {
        tx.executeWithoutResult(s -> { AssignmentPropertyEntity a = new AssignmentPropertyEntity();
            a.setStaff(users.findById(staff.getId()).orElseThrow()); a.setProperty(properties.findById(id).orElseThrow()); assignments.save(a); });
    }
    PropertyDTO decision(PropertyDTO property, String status, String reason) {
        property.setStatus(status); property.setRejectionReason(reason); return property;
    }
    MockMultipartHttpServletRequestBuilder createRequest() {
        return multipart("/api/secure/properties").param("title","Nhà thử").param("address","123 đường thử")
            .param("legal","Sổ hồng").param("price","1000000").param("area","60")
            .param("typeId",typeId.toString()).param("categoryId",categoryId.toString()).param("wardId",wardId.toString());
    }
    PropertyMailEvent event(Integer id,String type) {
        return events.findAll().stream().filter(e -> e.getPropertyId().equals(id) && e.getEventType().equals(type)).findFirst().orElseThrow();
    }

    @Test void createReturnsPersistedDtoIgnoresClientAuthorityAndQueuesTrustedMail() throws Exception {
        var result = mvc.perform(createRequest().header("Authorization",bearer(owner))
            .param("userId",other.getId().toString()).param("userEmail","attacker@example.invalid")
            .param("status",StatusProperty.PUBLISHED.getStatus()).param("reviewedBy",staff.getId().toString()).param("rejectionReason","forged"))
            .andExpect(status().isOk()).andExpect(jsonPath("$.data.id").isNumber())
            .andExpect(jsonPath("$.data.createdDate").exists()).andExpect(jsonPath("$.data.status").value(StatusProperty.PENDING.getStatus()))
            .andExpect(jsonPath("$.data.rejectionReason").doesNotExist()).andReturn();
        int id = json.readTree(result.getResponse().getContentAsString()).path("data").path("id").asInt();
        assertEquals(owner.getId(), tx.execute(s -> properties.findById(id).orElseThrow().getUser().getId()));
        var event = event(id,"RECEIVED"); assertEquals(owner.getEmail(),event.getRecipient());
        assertEquals("[RealEstateMobile] Đã tiếp nhận bài đăng bất động sản",event.getSubject());
        assertTrue(event.getTextBody().contains("chưa được công khai")); assertEquals(1,events.countByPropertyId(id));
        verifyNoInteractions(parser, mailer);
        mvc.perform(get("/api/properties").param("title","Nhà thử")).andExpect(status().isOk())
            .andExpect(jsonPath("$.data.content[?(@.id == "+id+")]").isEmpty());
    }

    @Test void invalidCreateFkAndParserFailureReturn422WithoutWritingOrSending() throws Exception {
        long count = properties.count(), mailCount = events.count();
        mvc.perform(createRequest().with(request -> { request.setParameter("typeId","999999"); return request; }).header("Authorization",bearer(owner)))
            .andExpect(status().isUnprocessableEntity()).andExpect(jsonPath("$.detail").value("VALIDATION_ERROR"))
            .andExpect(jsonPath("$.data.typeId").exists());
        var missingWard = createRequest().with(request -> { request.removeParameter("wardId"); return request; });
        when(parser.parseAddress(anyString())).thenThrow(new RuntimeException("provider unavailable"));
        mvc.perform(missingWard.header("Authorization",bearer(owner))).andExpect(status().isUnprocessableEntity())
            .andExpect(jsonPath("$.data.wardId").exists());
        mvc.perform(createRequest().with(request -> { request.setParameter("title", " "); return request; })
            .header("Authorization",bearer(owner))).andExpect(status().isBadRequest());
        assertEquals(count,properties.count()); assertEquals(mailCount,events.count()); verifyNoInteractions(mailer);
    }

    @Test void parserCanResolveWardOnlyWhenNoExplicitSelection() throws Exception {
        when(parser.parseAddress(anyString())).thenReturn(new AddressParseResult("123 đường thử", wards.findById(wardId).orElseThrow().getName(), "Quận thử", "Hồ Chí Minh"));
        PropertyDTO request=form(); request.setWardId(null); auth(owner);
        PropertyDTO saved = service.saveOwnedProperty(request); assertNotNull(saved.getWardId());
        verify(parser).parseAddress(anyString());
    }

    @Test void optionsRequireJwtAndReturnOnlyOptionFields() throws Exception {
        mvc.perform(get("/api/secure/property-options")).andExpect(status().isUnauthorized());
        mvc.perform(get("/api/secure/property-options").header("Authorization",bearer(owner)))
            .andExpect(status().isOk()).andExpect(jsonPath("$.data.types[0].id").isNumber())
            .andExpect(jsonPath("$.data.types[0].name").exists()).andExpect(jsonPath("$.data.types[0].code").doesNotExist())
            .andExpect(jsonPath("$.data.wards[0].districtName").exists()).andExpect(jsonPath("$.data.wards[0].createdBy").doesNotExist());
    }

    @Test void unicodeWhitespaceOnlyReasonIsRejectedWithoutMutationOrEvent() throws Exception {
        PropertyDTO property=create(); assign(property.getId());
        Date modified=properties.findById(property.getId()).orElseThrow().getModifiedDate();
        for (String blank : List.of("\u00A0", "\u202F", "\uFEFF", " \t\n\u00A0\u202F\u2003\uFEFF ")) {
            decision(property,StatusProperty.REJECTED.getStatus(),blank);
            mvc.perform(post("/admin/api/properties").with(user(staff.getUsername()).roles("STAFF")).with(csrf())
                .contentType("application/json").content(json.writeValueAsString(property)))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.detail").value("VALIDATION_ERROR"))
                .andExpect(jsonPath("$.data.rejectionReason").exists());
            PropertyEntity stored=properties.findById(property.getId()).orElseThrow();
            assertEquals(StatusProperty.PENDING.getStatus(),stored.getStatus());
            assertNull(stored.getRejectionReason()); assertNull(stored.getReviewedBy()); assertNull(stored.getReviewedAt());
            assertEquals(modified,stored.getModifiedDate()); assertEquals(1,events.countByPropertyId(property.getId()));
        }
        verifyNoInteractions(mailer);
    }

    @Test void paddedUnicodeReasonIsNormalizedBeforeLengthCheckAndMailSnapshot() throws Exception {
        PropertyDTO property=create(); assign(property.getId());
        // Preserve interior spacing while removing edge padding, including no-break spaces and BOM.
        String normalized="Thiếu\u00A0giấy\u202Ftờ <b> & xác nhận";
        String padding="\u00A0\u202F\uFEFF \t\u2003";
        decision(property,StatusProperty.REJECTED.getStatus(),padding.repeat(200)+normalized+padding.repeat(200));
        mvc.perform(post("/admin/api/properties").with(user(staff.getUsername()).roles("STAFF")).with(csrf())
            .contentType("application/json").content(json.writeValueAsString(property)))
            .andExpect(status().isOk()).andExpect(jsonPath("$.data.rejectionReason").value(normalized));
        PropertyEntity stored=properties.findById(property.getId()).orElseThrow();
        assertEquals(normalized,stored.getRejectionReason()); assertEquals(staff.getId(),stored.getReviewedBy());
        assertNotNull(stored.getReviewedAt()); assertEquals(StatusProperty.REJECTED.getStatus(),stored.getStatus());
        PropertyMailEvent mail=event(property.getId(),"REJECTED");
        assertTrue(mail.getTextBody().contains("Lý do: "+stored.getRejectionReason()+"."));
        assertTrue(mail.getHtmlBody().contains("Lý do: "+org.springframework.web.util.HtmlUtils.htmlEscape(normalized,"UTF-8")+"."));
        assertFalse(mail.getTextBody().contains("\uFEFF")); assertEquals(2,events.countByPropertyId(property.getId()));
        verifyNoInteractions(mailer);
    }

    @Test void rejectRequiresReasonAndAssignmentAndPreservesOwnerAuditOnEdit() throws Exception {
        PropertyDTO property = create(); assign(property.getId());
        decision(property,StatusProperty.REJECTED.getStatus(),"   ");
        mvc.perform(post("/admin/api/properties").with(user(staff.getUsername()).roles("STAFF")).with(csrf())
            .contentType("application/json").content(json.writeValueAsString(property)))
            .andExpect(status().isUnprocessableEntity()).andExpect(jsonPath("$.data.rejectionReason").exists());
        assertEquals(1,events.countByPropertyId(property.getId()));
        property.setRejectionReason(null);
        mvc.perform(post("/admin/api/properties").with(user(staff.getUsername()).roles("STAFF")).with(csrf())
            .contentType("application/json").content(json.writeValueAsString(property)))
            .andExpect(status().isUnprocessableEntity()).andExpect(jsonPath("$.data.rejectionReason").exists());
        property.setRejectionReason("  Thiếu giấy tờ <script> & xác nhận  ");
        mvc.perform(post("/admin/api/properties").with(user(unassigned.getUsername()).roles("STAFF")).with(csrf())
            .contentType("application/json").content(json.writeValueAsString(property))).andExpect(status().isForbidden());
        mvc.perform(post("/admin/api/properties").with(user(staff.getUsername()).roles("STAFF"))
            .contentType("application/json").content(json.writeValueAsString(property))).andExpect(status().isForbidden());
        mvc.perform(post("/admin/api/properties").with(user(owner.getUsername()).roles("USER")).with(csrf())
            .contentType("application/json").content(json.writeValueAsString(property))).andExpect(status().isForbidden());
        mvc.perform(post("/admin/api/properties").with(user(staff.getUsername()).roles("STAFF")).with(csrf())
            .contentType("application/json").content(json.writeValueAsString(property))).andExpect(status().isOk())
            .andExpect(jsonPath("$.data.rejectionReason").value("Thiếu giấy tờ <script> & xác nhận"))
            .andExpect(jsonPath("$.data.reviewedBy").value(staff.getId()));
        var event=event(property.getId(),"REJECTED");
        assertEquals("[RealEstateMobile] Bài đăng của bạn chưa được phê duyệt",event.getSubject());
        assertTrue(event.getTextBody().contains("Thiếu giấy tờ <script> & xác nhận"));
        assertTrue(event.getHtmlBody().contains("&lt;script&gt; &amp; xác nhận"));
        assertFalse(event.getHtmlBody().contains("<script>")); assertTrue(event.getHtmlBody().contains("&lt;b&gt;"));
        Date reviewedAt=tx.execute(s -> properties.findById(property.getId()).orElseThrow().getReviewedAt());
        auth(owner); PropertyDTO edit=service.findById(property.getId()); edit.setTitle("Đã điều chỉnh");
        edit.setStatus(StatusProperty.PENDING.getStatus()); edit.setRejectionReason("forged"); edit.setReviewedBy(other.getId()); edit.setUserId(other.getId());
        PropertyDTO saved=service.saveOwnedProperty(edit);
        assertEquals(StatusProperty.REJECTED.getStatus(),saved.getStatus()); assertEquals(staff.getId(),saved.getReviewedBy());
        assertEquals(reviewedAt,saved.getReviewedAt()); assertEquals(owner.getId(),saved.getUserId());
        assertEquals("Thiếu giấy tờ <script> & xác nhận",saved.getRejectionReason()); assertEquals(2,events.countByPropertyId(property.getId()));
    }

    @Test void approveRepeatedDecisionKeepsAuditAndSameStatusContentEditWorks() throws Exception {
        PropertyDTO property=create(); assign(property.getId()); auth(staff);
        assertEquals(1,service.findById(property.getId()).getAssignmentIds().size());
        service.createOrUpdateProperty(decision(property,StatusProperty.PUBLISHED.getStatus(),null));
        Date reviewedAt=property.getReviewedAt(); Date modified=property.getModifiedDate();
        service.createOrUpdateProperty(property);
        assertEquals(reviewedAt,property.getReviewedAt()); assertEquals(modified,property.getModifiedDate());
        property.setTitle("Staff sửa nội dung"); service.createOrUpdateProperty(property);
        assertEquals("Staff sửa nội dung",property.getTitle()); assertEquals(reviewedAt,property.getReviewedAt());
        assertEquals(2,events.countByPropertyId(property.getId()));
        var event=event(property.getId(),"APPROVED"); assertEquals("[RealEstateMobile] Bài đăng của bạn đã được phê duyệt",event.getSubject());
        assertTrue(event.getTextBody().contains("đã công khai"));
        auth(other);
        assertNull(service.findById(property.getId()).getReviewedBy());
        mvc.perform(get("/api/properties").param("title","Staff sửa nội dung"))
            .andExpect(status().isOk()).andExpect(jsonPath("$.data.content[0].reviewedBy").doesNotExist());
        property.setStatus(StatusProperty.REJECTED.getStatus()); property.setRejectionReason("Conflict"); auth(staff);
        assertEquals(409,assertThrows(PropertyProblem.class,()->service.createOrUpdateProperty(property)).getStatus());
    }

    @Test void missingPrivateDetailOwnershipAndFavoriteVisibility() throws Exception {
        PropertyDTO property=create();
        mvc.perform(get("/api/secure/properties/999999").header("Authorization",bearer(owner))).andExpect(status().isNotFound());
        mvc.perform(get("/api/secure/properties/"+property.getId()).header("Authorization",bearer(other))).andExpect(status().isNotFound());
        mvc.perform(delete("/api/secure/properties/"+property.getId()).header("Authorization",bearer(other))).andExpect(status().isForbidden());
        auth(other); property.setTitle("Hijack");
        assertEquals(403,assertThrows(PropertyProblem.class,()->service.saveOwnedProperty(property)).getStatus());
        FavoritePropertyDTO favorite=new FavoritePropertyDTO(); favorite.setUserId(other.getId()); favorite.setPropertyIds(List.of(property.getId()));
        favorites.createOrUpdateFavoriteProperty(favorite);
        assertTrue(service.getFavoritePropertiesByUser(other.getId()).isEmpty());
        mvc.perform(post("/api/secure/favorite-properties").header("Authorization",bearer(other))
            .contentType("application/json").content(json.writeValueAsString(favorite))).andExpect(status().isNotFound());
        auth(admin); service.deleteProperty(property.getId());
        auth(other); assertEquals(404,assertThrows(PropertyProblem.class,()->service.findById(property.getId())).getStatus());
    }

    @Test void adminRetainsReviewPermissionAndRejectLengthBoundary() {
        PropertyDTO property=create(); auth(admin);
        property.setStatus(StatusProperty.REJECTED.getStatus()); property.setRejectionReason("x".repeat(1001));
        assertEquals(422,assertThrows(PropertyProblem.class,()->service.createOrUpdateProperty(property)).getStatus());
        property.setRejectionReason("x".repeat(1000)); service.createOrUpdateProperty(property);
        assertEquals(admin.getId(),property.getReviewedBy()); assertEquals(1000,property.getRejectionReason().length());
    }

    @Test void rollbackDoesNotPublishMailAndDeliveryRetriesSameEventWithoutRollingBackProperty() throws Exception {
        auth(owner); Integer id=tx.execute(status -> { PropertyDTO property=service.saveOwnedProperty(form()); status.setRollbackOnly(); return property.getId(); });
        assertFalse(properties.existsById(id)); assertEquals(0,events.countByPropertyId(id)); verifyNoInteractions(mailer);
        PropertyDTO property=create(); PropertyMailEvent event=event(property.getId(),"RECEIVED");
        doThrow(new IllegalStateException("secret provider payload")).when(mailer).send(any());
        delivery.deliver(event.getId()); var failed=events.findById(event.getId()).orElseThrow();
        assertEquals("PENDING",failed.getState()); assertEquals(1,failed.getAttempts()); assertTrue(failed.getNextAttemptAt().isAfter(Instant.now()));
        assertEquals("DELIVERY_FAILED",failed.getLastError()); assertEquals(StatusProperty.PENDING.getStatus(),properties.findById(property.getId()).orElseThrow().getStatus());
        delivery.deliver(event.getId()); verify(mailer,times(1)).send(any());
        tx.executeWithoutResult(s -> events.findById(event.getId()).orElseThrow().setNextAttemptAt(Instant.now().minusSeconds(1)));
        delivery.deliver(event.getId()); failed=events.findById(event.getId()).orElseThrow(); assertEquals("FAILED",failed.getState());
        assertEquals(2,failed.getAttempts()); assertEquals(1,events.countByPropertyId(property.getId()));
        PropertyDTO second=create(); var success=event(second.getId(),"RECEIVED"); reset(mailer);
        delivery.deliver(success.getId()); delivery.deliver(success.getId()); verify(mailer,times(1)).send(any());
        assertEquals("SENT",events.findById(success.getId()).orElseThrow().getState());
    }

    @Test void adminTemplatesRenderUnderRealSecurity() throws Exception {
        PropertyDTO property=create(); assign(property.getId());
        String createHtml=mvc.perform(get("/admin/properties-edit").with(user(admin.getUsername()).roles("ADMIN")))
            .andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
        var createOwner=java.util.regex.Pattern.compile("<select\\b(?=[^>]*\\bid=\"userId\")[^>]*>").matcher(createHtml);
        assertTrue(createOwner.find()); assertFalse(createOwner.group().contains("disabled"));
        String editHtml=mvc.perform(get("/admin/properties-edit-"+property.getId()).with(user(staff.getUsername()).roles("STAFF")))
            .andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
        var editOwner=java.util.regex.Pattern.compile("<select\\b(?=[^>]*\\bid=\"userId\")[^>]*>").matcher(editHtml);
        assertTrue(editOwner.find()); assertTrue(editOwner.group().contains("disabled"));
        assertTrue(editHtml.contains("id=\"approve-property\""));
        assertTrue(editHtml.contains("id=\"reject-dialog\""));
        assertTrue(editHtml.contains("src=\"/js/property-approval.js\""));
        mvc.perform(get("/js/property-approval.js").with(user(staff.getUsername()).roles("STAFF")))
            .andExpect(status().isOk()).andExpect(content().string(org.hamcrest.Matchers.containsString("PropertyApproval")));
        auth(staff); service.createOrUpdateProperty(decision(property,StatusProperty.REJECTED.getStatus(),"Lý do kiểm thử tích hợp"));
        String rejectedHtml=mvc.perform(get("/admin/properties-edit-"+property.getId()).with(user(staff.getUsername()).roles("STAFF")))
            .andExpect(status().isOk()).andReturn().getResponse().getContentAsString(java.nio.charset.StandardCharsets.UTF_8);
        assertTrue(rejectedHtml.contains("Lý do từ chối: Lý do kiểm thử tích hợp"));
        assertFalse(rejectedHtml.contains("id=\"approve-property\""));
    }

    @Test void concurrentDeliveriesSendOneApplicationEvent() throws Exception {
        PropertyDTO property=create(); var event=event(property.getId(),"RECEIVED");
        ExecutorService pool=Executors.newFixedThreadPool(2); CountDownLatch start=new CountDownLatch(1);
        CountDownLatch entered=new CountDownLatch(1), release=new CountDownLatch(1);
        doAnswer(invocation -> { entered.countDown(); assertTrue(release.await(5,TimeUnit.SECONDS)); return null; }).when(mailer).send(any());
        try {
            Callable<Void> task=() -> { start.await(); delivery.deliver(event.getId()); return null; };
            var a=pool.submit(task); var b=pool.submit(task); start.countDown();
            assertTrue(entered.await(5,TimeUnit.SECONDS)); release.countDown();
            a.get(20,TimeUnit.SECONDS); b.get(20,TimeUnit.SECONDS); verify(mailer,times(1)).send(any());
            assertEquals(1,events.findById(event.getId()).orElseThrow().getAttempts());
        } finally { release.countDown(); pool.shutdownNow(); }
    }

    @Test void concurrentSameAndConflictingDecisionsHaveOneReviewEvent() throws Exception {
        PropertyDTO property=create(); assign(property.getId());
        ExecutorService pool=Executors.newFixedThreadPool(2); CountDownLatch start=new CountDownLatch(1);
        try {
            Callable<Integer> approve=() -> { start.await(); auth(staff); try {
                PropertyDTO request=form(); request.setId(property.getId()); request.setStatus(StatusProperty.PUBLISHED.getStatus());
                service.createOrUpdateProperty(request); return 200;
            } catch(PropertyProblem ex) { return ex.getStatus(); } finally { SecurityContextHolder.clearContext(); } };
            Future<Integer> a=pool.submit(approve), b=pool.submit(approve); start.countDown();
            assertEquals(200,a.get(20,TimeUnit.SECONDS)); assertEquals(200,b.get(20,TimeUnit.SECONDS));
            assertEquals(2,events.countByPropertyId(property.getId()));
            PropertyDTO next=create(); assign(next.getId()); CountDownLatch race=new CountDownLatch(1);
            List<Future<Integer>> results=new ArrayList<>();
            for(String status:List.of(StatusProperty.PUBLISHED.getStatus(),StatusProperty.REJECTED.getStatus())) {
                results.add(pool.submit(() -> { race.await(); auth(staff); try {
                    PropertyDTO request=form(); request.setId(next.getId()); request.setStatus(status); request.setRejectionReason("Thiếu hồ sơ");
                    service.createOrUpdateProperty(request); return 200;
                } catch(PropertyProblem ex) { return ex.getStatus(); } finally { SecurityContextHolder.clearContext(); } }));
            }
            race.countDown(); List<Integer> codes=new ArrayList<>(); for(var future:results) codes.add(future.get(20,TimeUnit.SECONDS));
            assertTrue(codes.contains(200)); assertTrue(codes.contains(409)); assertEquals(2,events.countByPropertyId(next.getId()));
        } finally { pool.shutdownNow(); }
    }
}
