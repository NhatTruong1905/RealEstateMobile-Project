import { useEffect, useState } from "react";
import { CircleUserRound, LogOut } from "lucide-react";
import { accountApi } from "../../services/api/account/accountApi";
import { session } from "../../services/api/core/session";
import type { UserProfile } from "../../types";

export function AccountPage() {
  const [profile, setProfile] = useState<UserProfile>();
  useEffect(() => {
    accountApi.getProfile().then(setProfile);
  }, []);
  return (
    <div className="page-shell">
      <div className="container narrow">
        <div className="page-intro compact-intro">
          <span className="eyebrow">Tài khoản</span>
          <h1>Hồ sơ của bạn</h1>
        </div>
        <div className="profile-card">
          <div className="avatar">
            {profile?.avatar ? (
              <img src={profile.avatar} alt="" />
            ) : (
              <CircleUserRound />
            )}
          </div>
          <div>
            <h2>{profile?.fullname || "Đang tải..."}</h2>
            <p>@{profile?.username}</p>
          </div>
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

