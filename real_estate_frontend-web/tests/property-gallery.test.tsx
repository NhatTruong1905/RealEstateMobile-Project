// @vitest-environment jsdom
import { cleanup, fireEvent, render, screen } from "@testing-library/react";
import { afterEach, expect, it, vi } from "vitest";
import { MemoryRouter } from "react-router-dom";
import { PropertyDetailPage } from "../src/screens/properties/PropertyDetailScreen";

vi.mock("../src/services/api/property/propertyApi", () => ({
  propertyApi: { getById: async () => ({ id: 1, title: "Gallery test", price: 1000, images: ["/first.jpg", "/second.jpg", "/third.jpg", "/fourth.jpg"] }) },
}));
afterEach(cleanup);

it("toggles compact mode while preserving selection of every property image", async () => {
  render(<MemoryRouter><PropertyDetailPage /></MemoryRouter>);
  const toggle = await screen.findByRole("button", { name: "Thu nhỏ ảnh" });
  const gallery = document.getElementById("property-gallery")!;
  const thumbnails = document.querySelectorAll<HTMLButtonElement>(".gallery-thumbnails button");
  expect(thumbnails).toHaveLength(4);
  fireEvent.click(thumbnails[3]);
  expect(gallery.querySelector(".gallery-main")?.getAttribute("src")).toBe("/fourth.jpg");
  fireEvent.click(toggle);
  expect(gallery.classList.contains("gallery-compact")).toBe(true);
  expect(toggle.getAttribute("aria-pressed")).toBe("true");
  fireEvent.click(screen.getByRole("button", { name: "Mở rộng ảnh" }));
  expect(gallery.classList.contains("gallery-compact")).toBe(false);
  expect(gallery.querySelector(".gallery-main")?.getAttribute("src")).toBe("/fourth.jpg");
});
