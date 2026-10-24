package com.ndnt.services.storage;

import com.drew.imaging.ImageMetadataReader;
import com.drew.metadata.exif.ExifIFD0Directory;
import org.springframework.stereotype.Component;
import org.springframework.web.multipart.MultipartFile;

import javax.imageio.ImageIO;
import java.awt.*;
import java.awt.image.BufferedImage;
import java.io.*;
import java.util.Locale;
import java.util.Set;

@Component
public class ImageProcessor {
    public static final long MAX_BYTES = 5L * 1024 * 1024;
    public record Image(byte[] bytes, String contentType, String extension) {}

    public Image process(MultipartFile file, boolean avatar) {
        if (file == null || file.isEmpty() || file.getSize() > MAX_BYTES) throw StorageProblem.invalid();
        try {
            byte[] bytes;
            try (var stream = file.getInputStream()) { bytes = stream.readNBytes((int) MAX_BYTES + 1); }
            if (bytes.length == 0 || bytes.length > MAX_BYTES) throw StorageProblem.invalid();
            BufferedImage source;
            try (var input = ImageIO.createImageInputStream(new ByteArrayInputStream(bytes))) {
                var readers = ImageIO.getImageReaders(input);
                if (!readers.hasNext()) throw StorageProblem.invalid();
                var reader = readers.next();
                try {
                    String format = reader.getFormatName().toLowerCase(Locale.ROOT);
                    if (!Set.of("jpeg", "jpg", "png", "webp").contains(format)) throw StorageProblem.invalid();
                    reader.setInput(input, true, true);
                    int width = reader.getWidth(0), height = reader.getHeight(0);
                    if (width <= 0 || height <= 0 || width > 10000 || height > 10000 || (long) width * height > 20_000_000)
                        throw StorageProblem.invalid();
                    source = reader.read(0);
                } finally { reader.dispose(); }
            }
            int orientation = 1;
            var metadata = ImageMetadataReader.readMetadata(new ByteArrayInputStream(bytes));
            var exif = metadata.getFirstDirectoryOfType(ExifIFD0Directory.class);
            if (exif != null && exif.containsTag(ExifIFD0Directory.TAG_ORIENTATION))
                orientation = exif.getInt(ExifIFD0Directory.TAG_ORIENTATION);
            source = orient(source, orientation);
            int limit = avatar ? 512 : 1920;
            double scale = Math.min(1d, (double) limit / Math.max(source.getWidth(), source.getHeight()));
            int width = Math.max(1, (int) Math.round(source.getWidth() * scale));
            int height = Math.max(1, (int) Math.round(source.getHeight() * scale));
            boolean alpha = source.getColorModel().hasAlpha();
            BufferedImage output = new BufferedImage(width, height, alpha ? BufferedImage.TYPE_INT_ARGB : BufferedImage.TYPE_INT_RGB);
            Graphics2D graphics = output.createGraphics();
            try {
                graphics.setRenderingHint(RenderingHints.KEY_INTERPOLATION, RenderingHints.VALUE_INTERPOLATION_BICUBIC);
                graphics.drawImage(source, 0, 0, width, height, null);
            } finally { graphics.dispose(); }
            String format = alpha ? "png" : "jpeg";
            ByteArrayOutputStream encoded = new ByteArrayOutputStream();
            var writer = ImageIO.getImageWritersByFormatName(format).next();
            try (var target = ImageIO.createImageOutputStream(encoded)) {
                writer.setOutput(target);
                var params = writer.getDefaultWriteParam();
                if (!alpha) { params.setCompressionMode(javax.imageio.ImageWriteParam.MODE_EXPLICIT); params.setCompressionQuality(0.85f); }
                writer.write(null, new javax.imageio.IIOImage(output, null, null), params);
            } finally { writer.dispose(); }
            return new Image(encoded.toByteArray(), alpha ? "image/png" : "image/jpeg", alpha ? "png" : "jpg");
        } catch (StorageProblem ex) { throw ex; }
        catch (Exception ex) { throw StorageProblem.invalid(); }
    }

    private BufferedImage orient(BufferedImage image, int orientation) {
        if (orientation < 2 || orientation > 8) return image;
        int width = image.getWidth(), height = image.getHeight();
        boolean swap = orientation >= 5;
        BufferedImage output = new BufferedImage(swap ? height : width, swap ? width : height,
                image.getColorModel().hasAlpha() ? BufferedImage.TYPE_INT_ARGB : BufferedImage.TYPE_INT_RGB);
        for (int y = 0; y < height; y++) for (int x = 0; x < width; x++) {
            int dx = x, dy = y;
            switch (orientation) {
                case 2 -> dx = width - 1 - x;
                case 3 -> { dx = width - 1 - x; dy = height - 1 - y; }
                case 4 -> dy = height - 1 - y;
                case 5 -> { dx = y; dy = x; }
                case 6 -> { dx = height - 1 - y; dy = x; }
                case 7 -> { dx = height - 1 - y; dy = width - 1 - x; }
                case 8 -> { dx = y; dy = width - 1 - x; }
                default -> { }
            }
            output.setRGB(dx, dy, image.getRGB(x, y));
        }
        return output;
    }
}
