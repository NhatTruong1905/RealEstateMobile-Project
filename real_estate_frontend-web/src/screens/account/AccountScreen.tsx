import { useEffect, useRef, useState } from "react";
import { CircleUserRound, LoaderCircle, LogOut } from "lucide-react";
import { accountApi } from "../../services/api/account/accountApi";
import { session } from "../../services/api/core/session";
import type { UserProfile } from "../../types";

export function AccountPage() {
  const [profile, setProfile] = useState<UserProfile>();
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");
  const [file, setFile] = useState<File>();
  const [preview, setPreview] = useState("");
  const [failedImage, setFailedImage] = useState("");
  const [saving, setSaving] = useState(false);
  const previewRef = useRef("");
  const fileInput = useRef<HTMLInputElement>(null);
  const mounted = useRef(false);
  useEffect(() => {
    mounted.current = true;
    let active = true;
    accountApi.getProfile().then((data) => {
      if (active) setProfile(data);
    }).catch((error) => {
      if (active) setError(error instanceof Error ? error.message : "Không tải được hồ sơ.");
    });
    return () => {
      mounted.current = false;
      active = false;
      if (previewRef.current) URL.revokeObjectURL(previewRef.current);
    };
  }, []);
  useEffect(() => {
    const reset = () => {
      if (previewRef.current) URL.revokeObjectURL(previewRef.current);
      previewRef.current = "";
      setProfile(undefined); setFile(undefined); setPreview("");
      setSuccess(""); setError(""); setSaving(false);
    };
    window.addEventListener("session-cleared", reset);
    return () => window.removeEventListener("session-cleared", reset);
  }, []);

  function resetSelection() {
    if (previewRef.current) URL.revokeObjectURL(previewRef.current);
    previewRef.current = "";
    setPreview("");
    setFile(undefined);
    if (fileInput.current) fileInput.current.value = "";
  }

  async function saveAvatar(event: React.SubmitEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!file || !profile || saving) return;
    const generation = session.generation;
    setSaving(true);
    setError("");
    setSuccess("");
    try {
      const updated = await accountApi.updateAvatar(file, profile);
      if (!mounted.current || generation !== session.generation) return;
      setProfile(updated);
      setFailedImage("");
      resetSelection();
      setSuccess("Đã cập nhật ảnh đại diện.");
    } catch (error) {
      if (!mounted.current || generation !== session.generation) return;
      setError(error instanceof Error ? error.message : "Không thể cập nhật ảnh đại diện.");
    } finally {
      if (mounted.current && generation === session.generation) setSaving(false);
    }
  }
  const avatar = preview || profile?.avatar;
  return (
    <div className="page-shell">
      <div className="container narrow">
        <div className="page-intro compact-intro">
          <span className="eyebrow">Tài khoản</span>
          <h1>Hồ sơ của bạn</h1>
        </div>
        <div className="profile-card">
          <div className="avatar">
            {avatar && avatar !== failedImage ? (
              <img src={avatar} alt="Ảnh đại diện" decoding="async" onError={() => setFailedImage(avatar)} />
            ) : (
              <CircleUserRound />
            )}
          </div>
          <div>
            <h2>{profile?.fullname || "Đang tải..."}</h2>
            <p>@{profile?.username}</p>
          </div>
          <form className="avatar-form" onSubmit={saveAvatar}>
            <label htmlFor="avatar-file">Thay đổi ảnh đại diện</label>
            <input
              ref={fileInput}
              id="avatar-file"
              type="file"
              accept="image/jpeg,image/png,image/webp"
              disabled={!profile || saving}
              aria-describedby="avatar-file-hint"
              onChange={(event) => {
                const selected = event.currentTarget.files?.[0];
                resetSelection();
                setError("");
                setSuccess("");
                if (!selected) return;
                if (!["image/jpeg", "image/png", "image/webp"].includes(selected.type)) {
                  setError("Vui lòng chọn ảnh JPG, PNG hoặc WebP.");
                  return;
                }
                if (!selected.size || selected.size > 5 * 1024 * 1024) {
                  setError("Ảnh phải có dung lượng lớn hơn 0 và tối đa 5 MB.");
                  return;
                }
                previewRef.current = URL.createObjectURL(selected);
                setPreview(previewRef.current);
                setFile(selected);
              }}
            />
            <small id="avatar-file-hint">JPG, PNG hoặc WebP · Tối đa 5 MB</small>
            {error && <div className="form-error" role="alert">{error}</div>}
            {success && <p role="status">{success}</p>}
            <div className="avatar-actions">
              <button className="button button-primary" disabled={!file || saving}>
                {saving && <LoaderCircle className="spin" />}
                {saving ? "Đang lưu..." : "Lưu ảnh đại diện"}
              </button>
              {file && <button type="button" className="button button-secondary" disabled={saving} onClick={resetSelection}>Hủy</button>}
            </div>
          </form>
          <dl>
            <div>
              <dt>Email</dt>
              <dd>{profile?.email || "Chưa cập nhật"}</dd>
            </div>
            <div>
              <dt>Số điện thoại</dt>
              <dd>{profile?.phone || "Chưa cập nhật"}</dd>
            </div>
          </dl>
          <button
            className="button button-secondary"
            onClick={() => {
              session.clear();
              location.href = "/";
            }}
          >
            <LogOut /> Đăng xuất
          </button>
        </div>
      </div>
    </div>
  );
}

