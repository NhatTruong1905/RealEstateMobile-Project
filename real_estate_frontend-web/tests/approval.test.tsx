// @vitest-environment jsdom
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import {
  cleanup,
  fireEvent,
  render,
  screen,
  waitFor,
} from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import { PostProperty } from "../src/screens/seller/PostPropertyScreen";
import { SellerProperties } from "../src/screens/seller/SellerPropertiesScreen";
import { SellerPropertyRow } from "../src/components/property/SellerPropertyRow";
import { sellerApi } from "../src/services/api/seller/sellerApi";
import { ApiError, request } from "../src/services/api/core/http";
import { session } from "../src/services/api/core/session";

vi.mock("../src/services/api/seller/sellerApi", () => ({
  sellerApi: { options: vi.fn(), create: vi.fn(), listMyProperties: vi.fn() },
}));
vi.mock("../src/utils/propertyImage", () => ({ resizePropertyImage: async (file: File) => file }));
const options = {
  types: [{ id: 17, name: "Bán" }],
  categories: [{ id: 35, name: "Căn hộ" }],
  wards: [{ id: 91, name: "Phường A", districtName: "Quận B" }],
};
beforeEach(() => {
  vi.clearAllMocks();
  vi.mocked(sellerApi.options).mockResolvedValue(options);
});
afterEach(() => {
  cleanup();
  vi.unstubAllGlobals();
  session.clear();
});
function form() {
  return render(
    <MemoryRouter>
      <PostProperty />
    </MemoryRouter>,
  );
}
async function fill() {
  await screen.findByRole("option", { name: "Bán" });
  fireEvent.change(screen.getByLabelText("Tiêu đề *"), {
    target: { value: "  Nhà mới  " },
  });
  fireEvent.change(screen.getByLabelText("Giá (VNĐ) *"), {
    target: { value: "5000000" },
  });
  fireEvent.change(screen.getByLabelText("Diện tích (m²) *"), {
    target: { value: "25.5" },
  });
  fireEvent.change(screen.getByLabelText("Địa chỉ đầy đủ *"), {
    target: { value: "  Địa chỉ A  " },
  });
  fireEvent.change(screen.getByLabelText("Thông tin pháp lý *"), {
    target: { value: "Sổ hồng" },
  });
  fireEvent.change(screen.getByLabelText("Loại hình giao dịch *"), {
    target: { value: "17" },
  });
  fireEvent.change(screen.getByLabelText("Phân khúc bất động sản *"), {
    target: { value: "35" },
  });
  fireEvent.change(screen.getByLabelText("Phường/xã"), {
    target: { value: "91" },
  });
}
describe("form đăng tin", () => {
  it("gửi multipart tên danh mục thật, chặn submit lặp và chỉ báo pending sau response", async () => {
    let resolve!: (value: {
      id: number;
      title: string;
      status: string;
    }) => void;
    vi.mocked(sellerApi.create).mockReturnValue(
      new Promise((done) => {
        resolve = done;
      }),
    );
    const view = form();
    await fill();
    fireEvent.change(screen.getByLabelText(/Ảnh \(tối đa/), {
      target: {
        files: [new File(["photo"], "house.png", { type: "image/png" })],
      },
    });
    const element = view.container.querySelector("form")!;
    fireEvent.submit(element);
    fireEvent.submit(element);
    await waitFor(() => expect(sellerApi.create).toHaveBeenCalledTimes(1));
    const payload = vi.mocked(sellerApi.create).mock.calls[0][0];
    expect(payload.get("title")).toBe("Nhà mới");
    expect(payload.get("wardId")).toBe("91");
    expect(payload.has("status")).toBe(false);
    expect(payload.has("userId")).toBe(false);
    expect((payload.get("files") as File).name).toBe("house.png");
    expect(screen.queryByText(/Hệ thống đã tiếp nhận/)).toBeNull();
    resolve({ id: 5, title: "Nhà mới", status: "Chờ duyệt" });
    expect(
      await screen.findByText(/Bài đăng đang chờ nhân viên xét duyệt/),
    ).toBeTruthy();
  });
  it("422 giữ draft và field error; không tự retry", async () => {
    vi.mocked(sellerApi.create).mockRejectedValue(
      new ApiError(422, "Địa chỉ chưa hợp lệ", {
        wardId: "Chọn phường hợp lệ",
      }),
    );
    const view = form();
    await fill();
    fireEvent.submit(view.container.querySelector("form")!);
    expect(await screen.findByText("Chọn phường hợp lệ")).toBeTruthy();
    expect((screen.getByLabelText("Tiêu đề *") as HTMLInputElement).value).toBe(
      "  Nhà mới  ",
    );
    expect(sellerApi.create).toHaveBeenCalledTimes(1);
  });
  it("lỗi mạng giữ draft và nhắc kiểm tra tin trước khi thử lại", async () => {
    vi.mocked(sellerApi.create).mockRejectedValue(
      new TypeError("Failed to fetch"),
    );
    const view = form();
    await fill();
    fireEvent.submit(view.container.querySelector("form")!);
    expect(
      await screen.findByText(/kiểm tra Tin đăng trước khi thử lại/),
    ).toBeTruthy();
    expect(sellerApi.create).toHaveBeenCalledTimes(1);
  });
  it("chặn whitespace, số âm/số lẻ phòng và hơn 5 ảnh", async () => {
    const view = form();
    await fill();
    fireEvent.change(screen.getByLabelText("Tiêu đề *"), {
      target: { value: "   " },
    });
    fireEvent.change(screen.getByLabelText("Phòng ngủ"), {
      target: { value: "1.5" },
    });
    const input = screen.getByLabelText(/Ảnh \(tối đa/) as HTMLInputElement;
    fireEvent.change(input, {
      target: {
        files: Array.from(
          { length: 6 },
          (_, i) => new File(["x"], `${i}.png`, { type: "image/png" }),
        ),
      },
    });
    fireEvent.submit(view.container.querySelector("form")!);
    expect(sellerApi.create).not.toHaveBeenCalled();
    expect(screen.getByText("Vui lòng nhập thông tin.")).toBeTruthy();
    expect(screen.getByText("Nhập số nguyên từ 0 trở lên.")).toBeTruthy();
    expect(screen.getByText("Chỉ chọn tối đa 5 ảnh.")).toBeTruthy();
  });
  it("options lỗi không đoán ID và cho tải lại", async () => {
    vi.mocked(sellerApi.options).mockRejectedValueOnce(
      new Error("Không tải danh mục"),
    );
    form();
    fireEvent.click(await screen.findByText("Tải lại danh mục"));
    expect(
      await screen.findByRole("option", { name: "Phường A - Quận B" }),
    ).toBeTruthy();
    expect(sellerApi.options).toHaveBeenCalledTimes(2);
  });
});
describe("tin của tôi", () => {
  it("tách từ chối/đã xóa, hiển thị lý do text và ngày; không có public link", () => {
    const view = render(
      <>
        <SellerPropertyRow
          property={{
            id: 1,
            title: "Tin A",
            status: "Từ chối",
            rejectionReason: "<script>bad</script>",
            createdDate: "2026-10-23T00:00:00Z",
          }}
        />
        <SellerPropertyRow
          property={{ id: 2, title: "Tin B", status: "Đã xóa" }}
        />
      </>,
    );
    expect(screen.getByText("Bị từ chối")).toBeTruthy();
    expect(screen.getByText("Đã xóa")).toBeTruthy();
    expect(
      screen.getByText("Lý do từ chối: <script>bad</script>"),
    ).toBeTruthy();
    expect(view.container.querySelector("script,a")).toBeNull();
  });
  it("lỗi fetch không hiện danh sách rỗng, tải lại fetch dữ liệu mới", async () => {
    vi.mocked(sellerApi.listMyProperties)
      .mockRejectedValueOnce(new Error("Phiên hết hạn"))
      .mockResolvedValueOnce([
        { id: 1, title: "Tin sau refresh", status: "Chờ duyệt" },
      ]);
    render(
      <MemoryRouter>
        <SellerProperties />
      </MemoryRouter>,
    );
    fireEvent.click(await screen.findByText("Tải lại"));
    expect(await screen.findByText("Tin sau refresh")).toBeTruthy();
    expect(sellerApi.listMyProperties).toHaveBeenCalledTimes(2);
  });
});
describe("API client", () => {
  it.each([401, 403, 404, 409, 422, 400])(
    "giữ HTTP %i và lỗi structured",
    async (status) => {
      vi.stubGlobal(
        "fetch",
        vi.fn().mockResolvedValue(
          new Response(
            JSON.stringify({
              message: "Validation",
              data: { rejectionReason: "Bắt buộc lý do" },
            }),
            { status },
          ),
        ),
      );
      await expect(request("/secure/properties")).rejects.toMatchObject({
        status,
        fields: { rejectionReason: "Bắt buộc lý do" },
      });
    },
  );
  it("gửi Bearer và để browser đặt multipart boundary", async () => {
    session.set("fake-token");
    const fetchMock = vi
      .fn()
      .mockResolvedValue(new Response("{}", { status: 200 }));
    vi.stubGlobal("fetch", fetchMock);
    await request("/secure/properties", {
      method: "POST",
      body: new FormData(),
    });
    const headers = fetchMock.mock.calls[0][1].headers as Headers;
    expect(headers.get("Authorization")).toBe("Bearer fake-token");
    expect(headers.has("Content-Type")).toBe(false);
    await waitFor(() => expect(fetchMock).toHaveBeenCalledTimes(1));
  });
});
