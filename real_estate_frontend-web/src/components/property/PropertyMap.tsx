import { useEffect, useRef } from "react";
import L from "leaflet";
import "leaflet/dist/leaflet.css";
import type { Property } from "../../types";
import { formatMoney } from "../../utils/format";

type PropertyMapProps = {
  properties: Property[];
  selectedId?: number;
  onSelect: (id: number) => void;
};

export function PropertyMap({ properties, selectedId, onSelect }: PropertyMapProps) {
  const containerRef = useRef<HTMLDivElement>(null);
  const mapRef = useRef<L.Map | null>(null);
  const markersRef = useRef<L.LayerGroup | null>(null);
  const onSelectRef = useRef(onSelect);

  useEffect(() => {
    onSelectRef.current = onSelect;
  }, [onSelect]);

  useEffect(() => {
    if (!containerRef.current || mapRef.current) return;

    const map = L.map(containerRef.current, {
      center: [10.7769, 106.7009],
      zoom: 12,
      zoomControl: true,
    });
    L.tileLayer("https://tile.openstreetmap.de/{z}/{x}/{y}.png", {
      maxZoom: 19,
      attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>',
    }).addTo(map);
    mapRef.current = map;
    markersRef.current = L.layerGroup().addTo(map);

    return () => {
      map.remove();
      mapRef.current = null;
      markersRef.current = null;
    };
  }, []);

  useEffect(() => {
    const map = mapRef.current;
    const layer = markersRef.current;
    if (!map || !layer) return;
    layer.clearLayers();

    const points: L.LatLngExpression[] = [];
    properties.forEach((property) => {
      if (property.latitude == null || property.longitude == null) return;
      const point: L.LatLngExpression = [property.latitude, property.longitude];
      points.push(point);
      const selected = property.id === selectedId;
      const icon = L.divIcon({
        className: "property-price-marker-wrap",
        html: `<span class="property-price-marker${selected ? " selected" : ""}">${formatMoney(property.price)}</span>`,
        iconSize: [92, 34],
        iconAnchor: [46, 17],
      });
      const marker = L.marker(point, { icon, title: property.title }).addTo(layer);
      const tooltip = document.createElement("div");
      tooltip.className = "map-property-tooltip";
      const title = document.createElement("strong");
      title.textContent = property.title;
      const address = document.createElement("span");
      address.textContent = property.address || "Địa chỉ đang cập nhật";
      tooltip.append(title, address);
      marker.bindTooltip(tooltip, { direction: "top", offset: [0, -14] });
      marker.on("click", () => onSelectRef.current(property.id));
    });

    if (points.length > 1) map.fitBounds(L.latLngBounds(points), { padding: [45, 45] });
    else if (points.length === 1) map.setView(points[0], 15);
    window.setTimeout(() => map.invalidateSize(), 0);
  }, [properties, selectedId]);

  return (
    <div className="property-map-shell">
      <div className="property-map" ref={containerRef} aria-label="Bản đồ bất động sản" />
      <div className="map-count">
        <strong>{properties.length}</strong> vị trí đang hiển thị
      </div>
    </div>
  );
}
