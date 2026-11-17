import { useEffect, useState } from "react";
import { House } from "lucide-react";
import type { Property } from "../../types";
import { getPropertyImages } from "../../services/images/propertyImages";
import { prefetchImage } from "../../services/images/imagePrefetch";
import { PropertyImage } from "./PropertyImage";

export function PropertyGallery({ property }: { property: Property }) {
  const [activeImage, setActiveImage] = useState(0);
  const [compact, setCompact] = useState(false);
  const [loadedImage, setLoadedImage] = useState("");
  const images = getPropertyImages(property);
  const current = images[activeImage] || images[0];
  const nextImages = images.slice(activeImage + 1, activeImage + 3).join("\n");

  useEffect(() => {
    // Wait for the visible main image before spending bandwidth on neighbours.
    if (loadedImage !== current) return;
    nextImages.split("\n").filter(Boolean).forEach(prefetchImage);
  }, [current, loadedImage, nextImages]);

  return <>
    <div className="gallery-toolbar">
      <button type="button" className="button button-secondary" aria-controls="property-gallery"
        aria-pressed={compact} onClick={() => setCompact((value) => !value)}>
        {compact ? "Mở rộng ảnh" : "Thu nhỏ ảnh"}
      </button>
    </div>
    <div id="property-gallery" className={`gallery${images.length === 1 ? " gallery-single" : ""}${compact ? " gallery-compact" : ""}`}>
      <PropertyImage className="gallery-main" src={current} alt={property.title}
        loading="eager" fetchPriority="high" onLoad={() => setLoadedImage(current)} />
      <div className={`gallery-stack${images.length === 2 ? " gallery-stack-single" : ""}`}>
        {images.slice(1, 3).map((src, index) => <PropertyImage key={`${index}-${src}`}
          src={src} alt={`${property.title} - ảnh ${index + 2}`} loading="lazy" />)}
        {images.length < 2 && <div className="gallery-placeholder"><House /></div>}
      </div>
    </div>
    {images.length > 1 && <div className="gallery-thumbnails" role="group" aria-label="Chọn ảnh bất động sản">
      {images.map((src, index) => <button key={`${index}-${src}`} type="button"
        aria-label={`Xem ảnh ${index + 1}`} aria-pressed={activeImage === index}
        onClick={() => setActiveImage(index)} onFocus={() => prefetchImage(src)}
        onPointerEnter={() => prefetchImage(src)}>
        <PropertyImage src={src} alt="" loading="lazy" width={72} height={54} />
      </button>)}
    </div>}
  </>;
}
