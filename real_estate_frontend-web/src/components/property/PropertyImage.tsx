import type { ImgHTMLAttributes } from "react";
import { fallbackPropertyImage } from "../../config/assets";

// Shared fallback guard prevents an endless error loop if the fallback also fails.
export function PropertyImage(props: ImgHTMLAttributes<HTMLImageElement>) {
  return <img decoding="async" {...props} onError={(event) => {
    const image = event.currentTarget;
    if (image.dataset.fallbackFor === props.src) return;
    image.dataset.fallbackFor = props.src;
    image.src = fallbackPropertyImage;
  }} />;
}
