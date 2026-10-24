export async function resizePropertyImage(file: File): Promise<File> {
  const url = URL.createObjectURL(file);
  try {
    const image = new Image();
    image.src = url;
    await image.decode();
    const scale = Math.min(1, 1920 / Math.max(image.naturalWidth, image.naturalHeight));
    if (scale === 1) return file;
    const canvas = document.createElement("canvas");
    canvas.width = Math.max(1, Math.round(image.naturalWidth * scale));
    canvas.height = Math.max(1, Math.round(image.naturalHeight * scale));
    const context = canvas.getContext("2d");
    if (!context) throw new Error("Không thể xử lý ảnh. Vui lòng chọn lại ảnh.");
    context.drawImage(image, 0, 0, canvas.width, canvas.height);
    const blob = await new Promise<Blob | null>((resolve) => canvas.toBlob(resolve, file.type, 0.85));
    if (!blob) throw new Error("Không thể thu nhỏ ảnh. Vui lòng chọn lại ảnh.");
    return new File([blob], file.name, { type: blob.type, lastModified: file.lastModified });
  } catch {
    throw new Error(`Không thể xử lý ảnh ${file.name}. Vui lòng chọn ảnh JPG/PNG hợp lệ.`);
  } finally {
    URL.revokeObjectURL(url);
  }
}
