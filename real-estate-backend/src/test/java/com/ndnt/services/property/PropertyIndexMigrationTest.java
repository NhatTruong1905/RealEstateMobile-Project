package com.ndnt.services.property;

import org.junit.jupiter.api.Test;
import org.springframework.core.io.FileSystemResource;
import org.springframework.jdbc.datasource.init.ScriptUtils;
import java.sql.DriverManager;
import java.util.UUID;
import static org.junit.jupiter.api.Assertions.*;

class PropertyIndexMigrationTest {
    @Test void mysqlMigrationPreservesLegacyAndEnforcesVersionUniqueness() throws Exception { verify("MySQL","mysql"); }
    @Test void postgresqlMigrationPreservesLegacyAndEnforcesVersionUniqueness() throws Exception { verify("PostgreSQL","postgresql"); }
    void verify(String mode,String variant) throws Exception {
        try(var db=DriverManager.getConnection("jdbc:h2:mem:index"+UUID.randomUUID()+";MODE="+mode)) {
            var sql=db.createStatement();
            sql.execute("CREATE TABLE property(id INTEGER PRIMARY KEY)");sql.execute("INSERT INTO property VALUES(1)");
            ScriptUtils.executeSqlScript(db,new FileSystemResource("db/migrations/004_property_index_"+variant+"_forward.sql"));
            var rows=sql.executeQuery("SELECT index_version FROM property WHERE id=1");assertTrue(rows.next());assertEquals(1,rows.getLong(1));
            String insert="INSERT INTO property_index_outbox(id,property_id,aggregate_version,operation,routing_key,state,attempts,created_at,next_attempt_at) VALUES('%s',1,2,'upsert','property.approved','PENDING',0,CURRENT_TIMESTAMP,CURRENT_TIMESTAMP)";
            sql.execute(insert.formatted(UUID.randomUUID()));
            assertThrows(java.sql.SQLException.class,()->sql.execute(insert.formatted(UUID.randomUUID())));
        }
    }
}
