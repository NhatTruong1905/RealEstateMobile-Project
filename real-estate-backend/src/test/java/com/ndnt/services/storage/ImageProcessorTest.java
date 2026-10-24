package com.ndnt.services.storage;

import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockMultipartFile;
import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.*;
import static org.junit.jupiter.api.Assertions.*;

class ImageProcessorTest {
    private final ImageProcessor processor = new ImageProcessor();
    static byte[] png(int width, int height) throws Exception {
        var output = new ByteArrayOutputStream();
        ImageIO.write(new BufferedImage(width, height, BufferedImage.TYPE_INT_RGB), "png", output);
        return output.toByteArray();
    }
    static MockMultipartFile image() throws Exception { return new MockMultipartFile("file", "house.png", "image/png", png(30, 20)); }
    @Test void decodesBytesRatherThanTrustingMimeOrNameAndResizes() throws Exception {
        var result = processor.process(new MockMultipartFile("file", "wrong.svg", "text/html", png(1200, 600)), true);
        assertEquals("image/jpeg", result.contentType()); assertEquals("jpg", result.extension());
        var decoded = ImageIO.read(new ByteArrayInputStream(result.bytes()));
        assertEquals(512, decoded.getWidth()); assertEquals(256, decoded.getHeight());
    }
    @Test void rejectsFakeEmptyOversizeAndExcessivePixels() throws Exception {
        assertThrows(StorageProblem.class, () -> processor.process(new MockMultipartFile("file", "x.png", "image/png", "<svg/>".getBytes()), true));
        assertThrows(StorageProblem.class, () -> processor.process(new MockMultipartFile("file", "x.jpg", "image/jpeg", new byte[0]), true));
        assertThrows(StorageProblem.class, () -> processor.process(new MockMultipartFile("file", "x.jpg", "image/jpeg", new byte[5*1024*1024+1]), true));
        byte[] bytes = png(1, 1);
        java.nio.ByteBuffer.wrap(bytes, 16, 8).putInt(10000).putInt(10000);
        var crc = new java.util.zip.CRC32(); crc.update(bytes, 12, 17);
        java.nio.ByteBuffer.wrap(bytes, 29, 4).putInt((int) crc.getValue());
        assertThrows(StorageProblem.class, () -> processor.process(new MockMultipartFile("file", "x.png", "image/png", bytes), true));
    }
    @Test void appliesExifOrientationThenStripsMetadata() throws Exception {
        var jpeg = new ByteArrayOutputStream();
        ImageIO.write(new BufferedImage(40, 20, BufferedImage.TYPE_INT_RGB), "jpeg", jpeg);
        byte[] source = jpeg.toByteArray();
        byte[] exif = { 'E','x','i','f',0,0, 'I','I',42,0,8,0,0,0, 1,0, 0x12,1,3,0,1,0,0,0,6,0,0,0, 0,0,0,0 };
        var oriented = new ByteArrayOutputStream(); oriented.write(source, 0, 2);
        oriented.write(0xff); oriented.write(0xe1); oriented.write(0); oriented.write(exif.length+2);
        oriented.write(exif); oriented.write(source, 2, source.length-2);
        var result = processor.process(new MockMultipartFile("file", "rotated.jpg", "image/jpeg", oriented.toByteArray()), true);
        var decoded = ImageIO.read(new ByteArrayInputStream(result.bytes()));
        assertEquals(20, decoded.getWidth()); assertEquals(40, decoded.getHeight());
        assertNull(com.drew.imaging.ImageMetadataReader.readMetadata(new ByteArrayInputStream(result.bytes()))
                .getFirstDirectoryOfType(com.drew.metadata.exif.ExifIFD0Directory.class));
    }
    @Test void decodesRealWebpAndReencodesWithAnHonestExtension() throws Exception {
        byte[] bytes = java.util.Base64.getDecoder().decode("UklGRjQAAABXRUJQVlA4ICgAAACQAQCdASoIAAQAAUAmJZgCdLoAA5gA/vCbQ/4DdfFtMv0fmXJznAAA");
        var output=processor.process(new MockMultipartFile("file","test.webp","image/webp",bytes),true);
        assertEquals("image/jpeg",output.contentType()); assertEquals("jpg",output.extension());
        var image=ImageIO.read(new ByteArrayInputStream(output.bytes()));
        assertEquals(8,image.getWidth()); assertEquals(4,image.getHeight());
    }
}
