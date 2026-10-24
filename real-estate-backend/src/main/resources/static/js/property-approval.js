(function (global) {
  "use strict";
  function validReason(value) {
    const reason = value.trim();
    return reason.length > 0 && reason.length <= 1000;
  }
  function mount(form, dependencies = {}) {
    const fetchRequest = dependencies.fetch || global.fetch.bind(global);
    const confirmRequest = dependencies.confirm || global.confirm.bind(global);
    const refresh = dependencies.refresh || (() => global.location.reload());
    const notify = dependencies.notify || ((message) => global.alert(message));
    const doc = form.ownerDocument;
    const dialog = doc.getElementById("reject-dialog");
    const reason = doc.getElementById("rejection-reason");
    const rejectConfirm = doc.getElementById("confirm-reject");
    const errorBox = doc.getElementById("form-error");
    const reasonError = doc.getElementById("error-rejectionReason");
    let busy = false;
    const originalStatus =
      form.elements.namedItem("status").value || "Chờ duyệt";
    function validate() {
      rejectConfirm.disabled = busy || !validReason(reason.value);
    }
    function showError(message) {
      errorBox.textContent = message;
      errorBox.style.display = "block";
    }
    function setBusy(value) {
      busy = value;
      form.querySelectorAll("button").forEach((button) => {
        button.disabled = value;
      });
      doc.getElementById("cancel-reject").disabled = value;
      reason.disabled = value;
      doc.getElementById("approval-loading").hidden = !value;
      validate();
    }
    async function save(status, rejectionReason) {
      if (busy) return;
      if (!form.reportValidity()) return;
      if (
        status === "Từ chối" &&
        status !== originalStatus &&
        !validReason(rejectionReason || "")
      )
        return;
      const data = Object.fromEntries(new global.FormData(form).entries());
      const csrf =
        data._csrf || doc.querySelector('meta[name="_csrf"]')?.content || "";
      delete data._csrf;
      data.status = status;

      delete data.reviewedBy;
      delete data.reviewedAt;
      delete data.createdDate;
      if (status === "Từ chối" && rejectionReason !== undefined)
        data.rejectionReason = rejectionReason.trim();
      errorBox.style.display = "none";
      reasonError.textContent = "";
      form.querySelectorAll(".error-message").forEach((element) => {
        element.textContent = "";
        element.style.display = "none";
      });
      setBusy(true);
      try {
        const response = await fetchRequest(form.action, {
          method: "POST",
          credentials: "same-origin",
          headers: { "Content-Type": "application/json", "X-CSRF-TOKEN": csrf },
          body: JSON.stringify(data),
        });
        const text = await response.text();
        let result;
        try {
          result = text ? JSON.parse(text) : {};
        } catch {
          result = { message: text };
        }
        if (!response.ok || response.redirected) {
          const hints = {
            401: "Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.",
            403: "Bạn không có quyền xét duyệt tin này.",
            404: "Không tìm thấy tin đăng.",
            409: "Tin đã được xử lý hoặc đã thay đổi. Hãy tải lại để xem trạng thái mới.",
          };
          const fields =
            result.data && typeof result.data === "object"
              ? result.data
              : result;
          let message = response.redirected
            ? hints[401]
            : hints[response.status] ||
              result.message ||
              (Array.isArray(result)
                ? result.join("\n")
                : "Không thể lưu tin đăng.");
          for (const [field, detail] of Object.entries(fields)) {
            if (typeof detail !== "string") continue;
            const element = doc.getElementById("error-" + field);
            if (element) {
              element.textContent = detail;
              element.style.display = "block";
            }
          }
          if (typeof fields.rejectionReason === "string")
            message += "\n" + fields.rejectionReason;
          showError(message);
          if (response.status === 409)
            doc.getElementById("reload-property").hidden = false;
          return;
        }
        if (dialog.open) dialog.close();
        notify(
          status !== originalStatus
            ? status === "Đang mở bán"
              ? "Bài đăng đã được duyệt và công khai. Hệ thống sẽ xử lý email thông báo."
              : "Bài đăng đã bị từ chối. Hệ thống sẽ thông báo lý do cho người đăng."
            : "Đã lưu thông tin tin đăng.",
        );
        refresh();
      } catch {
        showError(
          "Lỗi kết nối. Dữ liệu được giữ lại; hãy tải lại kiểm tra trạng thái trước khi thử lại thao tác.",
        );
      } finally {
        setBusy(false);
      }
    }
    form.addEventListener("submit", (event) => {
      event.preventDefault();
      save(originalStatus);
    });
    doc.getElementById("approve-property")?.addEventListener("click", () => {
      if (
        !busy &&
        confirmRequest(
          "Phê duyệt và công khai bài đăng này? Hệ thống sẽ xử lý email thông báo.",
        )
      )
        save("Đang mở bán");
    });
    doc.getElementById("reject-property")?.addEventListener("click", () => {
      if (!busy) {
        reason.value = "";
        reasonError.textContent = "";
        validate();
        dialog.showModal();
        reason.focus();
      }
    });
    reason.addEventListener("input", validate);
    rejectConfirm.addEventListener("click", () =>
      save("Từ chối", reason.value),
    );
    doc.getElementById("cancel-reject").addEventListener("click", () => {
      if (!busy) dialog.close();
    });
    dialog.addEventListener("cancel", (event) => {
      if (busy) event.preventDefault();
    });
    doc.getElementById("reload-property").addEventListener("click", refresh);
    validate();
    return { save };
  }
  global.PropertyApproval = { mount, validReason };
})(window);
