// @vitest-environment jsdom
import { readFileSync } from "node:fs";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { fireEvent, waitFor } from "@testing-library/dom";

const template = readFileSync(
  "../real-estate-backend/src/main/resources/templates/property/edit.html",
  "utf8",
);
const script = readFileSync(
  "../real-estate-backend/src/main/resources/static/js/property-approval.js",
  "utf8",
);
let fetchMock: ReturnType<typeof vi.fn>,
  refresh: ReturnType<typeof vi.fn>,
  notify: ReturnType<typeof vi.fn>,
  confirm: ReturnType<typeof vi.fn>;
function el<T extends HTMLElement = HTMLElement>(id: string) {
  return document.getElementById(id)! as T;
}
function mount(status = "Chờ duyệt") {
  document.body.innerHTML = template;
  const form = el<HTMLFormElement>("formProperty");
  form.action = "/admin/api/properties";
  el<HTMLInputElement>("status").value = status;
  form.insertAdjacentHTML(
    "beforeend",
    '<input name="_csrf" value="csrf-test"><input name="id" value="45"><input name="title" value="Tin thật"><input name="status" value="ignored">',
  );
  // Thymeleaf emits the field name at render time; emulate that binding.
  el<HTMLInputElement>("status").name = "status";
  form.querySelector('input[name="status"][value="ignored"]')?.remove();
  vi.spyOn(form, "reportValidity").mockReturnValue(true);
  const dialog = el<HTMLDialogElement>("reject-dialog");
  dialog.showModal = () => {
    dialog.setAttribute("open", "");
  };
  dialog.close = () => {
    dialog.removeAttribute("open");
  };
  window.eval(script);
  const api = (
    window as unknown as {
      PropertyApproval: {
        mount: (form: HTMLFormElement, deps: object) => unknown;
      };
    }
  ).PropertyApproval;
  api.mount(form, { fetch: fetchMock, refresh, notify, confirm });
  return form;
}
function reject(value: string) {
  fireEvent.click(el("reject-property"));
  fireEvent.input(el("rejection-reason"), { target: { value } });
  fireEvent.click(el("confirm-reject"));
}
beforeEach(() => {
  fetchMock = vi.fn();
  refresh = vi.fn();
  notify = vi.fn();
  confirm = vi.fn().mockReturnValue(true);
});
describe("Staff UI thực thi trên template hiện có", () => {
  it("dialog yêu cầu trim reason, giới hạn 1000 và chặn submit trùng", async () => {
    let finish!: (value: Response) => void;
    fetchMock.mockReturnValue(
      new Promise((resolve) => {
        finish = resolve;
      }),
    );
    mount();
    fireEvent.click(el("reject-property"));
    const textarea = el<HTMLTextAreaElement>("rejection-reason");
    fireEvent.input(textarea, { target: { value: "   " } });
    expect(el<HTMLButtonElement>("confirm-reject").disabled).toBe(true);
    fireEvent.input(textarea, { target: { value: "x".repeat(1001) } });
    expect(el<HTMLButtonElement>("confirm-reject").disabled).toBe(true);
    fireEvent.input(textarea, { target: { value: "  Thiếu giấy tờ  " } });
    fireEvent.click(el("confirm-reject"));
    fireEvent.click(el("confirm-reject"));
    expect(fetchMock).toHaveBeenCalledTimes(1);
    expect(refresh).not.toHaveBeenCalled();
    const request = fetchMock.mock.calls[0][1];
    expect(JSON.parse(request.body)).toMatchObject({
      id: "45",
      status: "Từ chối",
      rejectionReason: "Thiếu giấy tờ",
    });
    expect(request.headers["X-CSRF-TOKEN"]).toBe("csrf-test");
    expect(request.credentials).toBe("same-origin");
    finish(
      new Response('{"message":"Success","data":{"status":"Từ chối"}}', {
        status: 200,
      }),
    );
    await waitFor(() => expect(refresh).toHaveBeenCalledTimes(1));
    expect(notify.mock.calls[0][0]).toContain("Hệ thống sẽ thông báo lý do");
  });
  it("approve cần confirm, không optimistic đổi status và refresh sau success", async () => {
    fetchMock.mockResolvedValue(new Response("{}", { status: 200 }));
    mount();
    confirm.mockReturnValueOnce(false);
    fireEvent.click(el("approve-property"));
    expect(fetchMock).not.toHaveBeenCalled();
    fireEvent.click(el("approve-property"));
    expect(el<HTMLInputElement>("status").value).toBe("Chờ duyệt");
    expect(JSON.parse(fetchMock.mock.calls[0][1].body).status).toBe(
      "Đang mở bán",
    );
    await waitFor(() => expect(refresh).toHaveBeenCalledTimes(1));
  });
  it.each([401, 403, 404, 409, 422, 400])(
    "HTTP %i không báo success, giữ reason và xử lý validation",
    async (status) => {
      fetchMock.mockResolvedValue(
        new Response(
          JSON.stringify({
            message: "Lỗi máy chủ",
            data: { rejectionReason: "Lý do không hợp lệ" },
          }),
          { status },
        ),
      );
      mount();
      reject("Bổ sung tài liệu");
      await waitFor(() => expect(el("form-error").style.display).toBe("block"));
      expect(notify).not.toHaveBeenCalled();
      expect(refresh).not.toHaveBeenCalled();
      expect(el<HTMLTextAreaElement>("rejection-reason").value).toBe(
        "Bổ sung tài liệu",
      );
      expect(el("error-rejectionReason").textContent).toBe(
        "Lý do không hợp lệ",
      );
      if (status === 409) {
        fireEvent.click(el("reload-property"));
        expect(refresh).toHaveBeenCalledTimes(1);
      }
    },
  );
  it("network không tự retry, form giữ dữ liệu", async () => {
    fetchMock.mockRejectedValue(new TypeError("offline"));
    mount();
    reject("Sai nội dung");
    await waitFor(() =>
      expect(el("form-error").textContent).toContain("Lỗi kết nối"),
    );
    expect(fetchMock).toHaveBeenCalledTimes(1);
    expect(refresh).not.toHaveBeenCalled();
  });
  it("edit rejected không reset reason/audit/status", async () => {
    fetchMock.mockResolvedValue(new Response("{}", { status: 200 }));
    const form = mount("Từ chối");
    fireEvent.submit(form);
    await waitFor(() => expect(refresh).toHaveBeenCalledTimes(1));
    const data = JSON.parse(fetchMock.mock.calls[0][1].body);
    expect(data.status).toBe("Từ chối");
    expect(data).not.toHaveProperty("rejectionReason");
    expect(data).not.toHaveProperty("reviewedBy");
  });
  it.each([false, true])(
    "owner selector create/edit (edit=%s) giữ đúng owner trong payload",
    (editing) => {
      document.body.innerHTML = template;
      // Materialize only the owner Thymeleaf bindings for the two server model cases.
      const form = el<HTMLFormElement>("formProperty");
      const owner = el<HTMLSelectElement>("userId");
      expect(owner.getAttribute("th:field")).toBe("*{userId}");
      expect(owner.getAttribute("th:disabled")).toBe("${property.id != null}");
      owner.name = "userId";
      owner.disabled = editing;
      owner.innerHTML =
        '<option value="9" selected>Người đăng hiện tại</option><option value="12">Người đăng khác</option>';
      const hidden = form.querySelector<HTMLInputElement>(
        'input[name="userId"]',
      )!;
      if (editing) hidden.value = "9";
      else hidden.remove();
      if (!editing) fireEvent.change(owner, { target: { value: "12" } });
      const values = new FormData(form).getAll("userId");
      expect(values).toEqual([editing ? "9" : "12"]);
      expect(owner.selectedOptions[0].textContent).toBe(
        editing ? "Người đăng hiện tại" : "Người đăng khác",
      );
    },
  );
  it("legacy400 list lỗi không báo thành công", async () => {
    fetchMock.mockResolvedValue(
      new Response(JSON.stringify(["Tiêu đề không hợp lệ"]), { status: 400 }),
    );
    const form = mount();
    fireEvent.submit(form);
    await waitFor(() =>
      expect(el("form-error").textContent).toContain("Tiêu đề không hợp lệ"),
    );
    expect(refresh).not.toHaveBeenCalled();
  });
});
