package com.ndnt.services.impl;

import org.junit.jupiter.api.Test;
import org.springframework.core.io.FileSystemResource;
import org.springframework.jdbc.datasource.init.ScriptUtils;
import java.sql.DriverManager;
import static org.junit.jupiter.api.Assertions.*;

class PropertyApprovalMigrationTest {
    @Test void additiveForwardUniqueKeyAndRollbackPreserveLegacyRows() throws Exception {
        verify("MySQL", "001_property_approval_forward.sql");
    }
    @Test void postgresqlVariantPreservesLegacyRows() throws Exception {
        verify("PostgreSQL", "001_property_approval_postgresql_forward.sql");
    }
    void verify(String mode, String migration) throws Exception {
        try(var connection=DriverManager.getConnection("jdbc:h2:mem:migration"+java.util.UUID.randomUUID()+";MODE="+mode+";DB_CLOSE_DELAY=-1")) {
            var statement=connection.createStatement();
            statement.execute("CREATE TABLE property(id INT PRIMARY KEY, status VARCHAR(255))");
            statement.execute("INSERT INTO property VALUES(1,'legacy')");
            ScriptUtils.executeSqlScript(connection,new FileSystemResource("db/migrations/"+migration));
            var rows=statement.executeQuery("SELECT rejection_reason,reviewed_by,reviewed_at FROM property WHERE id=1");
            assertTrue(rows.next()); assertNull(rows.getString(1)); assertNull(rows.getObject(2)); assertNull(rows.getObject(3));
            String insert="INSERT INTO property_mail_outbox(property_id,event_key,event_type,recipient,subject,text_body,html_body,state,attempts,next_attempt_at,created_at) VALUES(1,'1:RECEIVED','RECEIVED','a@example.invalid','subject','text','html','PENDING',0,CURRENT_TIMESTAMP,CURRENT_TIMESTAMP)";
            statement.execute(insert); assertThrows(java.sql.SQLException.class,()->statement.execute(insert));
            ScriptUtils.executeSqlScript(connection,new FileSystemResource("db/migrations/001_property_approval_rollback.sql"));
            rows=statement.executeQuery("SELECT status FROM property WHERE id=1"); assertTrue(rows.next()); assertEquals("legacy",rows.getString(1));
            assertThrows(java.sql.SQLException.class,()->statement.executeQuery("SELECT rejection_reason FROM property"));
            assertThrows(java.sql.SQLException.class,()->statement.executeQuery("SELECT * FROM property_mail_outbox"));
        }
    }
}
