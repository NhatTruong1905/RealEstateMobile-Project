package com.ndnt.services.storage;

import org.junit.jupiter.api.Test;
import org.springframework.core.io.FileSystemResource;
import org.springframework.jdbc.datasource.init.ScriptUtils;
import java.sql.DriverManager;
import static org.junit.jupiter.api.Assertions.*;

class StorageMigrationTest {
    @Test void mysqlForwardAndRollback() throws Exception { verify("MySQL", "mysql"); }
    @Test void postgresForwardAndRollback() throws Exception { verify("PostgreSQL", "postgresql"); }
    void verify(String mode, String dialect) throws Exception {
        try (var connection = DriverManager.getConnection("jdbc:h2:mem:storage"+java.util.UUID.randomUUID()+";MODE="+mode)) {
            var statement = connection.createStatement();
            statement.execute("CREATE TABLE legacy_image(id INT PRIMARY KEY, url VARCHAR(255))");
            statement.execute("INSERT INTO legacy_image VALUES(1,'https://legacy.example.invalid/a.jpg')");
            ScriptUtils.executeSqlScript(connection, new FileSystemResource("db/migrations/002_storage_cleanup_"+dialect+"_forward.sql"));
            statement.execute("INSERT INTO storage_cleanup_task(provider,object_key,url,next_attempt_at,created_at) VALUES('r2','key','https://example.invalid/key',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP)");
            var rows = statement.executeQuery("SELECT state, attempts FROM storage_cleanup_task");
            assertTrue(rows.next()); assertEquals("PENDING", rows.getString(1)); assertEquals(0, rows.getInt(2));
            ScriptUtils.executeSqlScript(connection, new FileSystemResource("db/migrations/002_storage_cleanup_rollback.sql"));
            rows = statement.executeQuery("SELECT url FROM legacy_image"); assertTrue(rows.next());
            assertEquals("https://legacy.example.invalid/a.jpg", rows.getString(1));
        }
    }
}
