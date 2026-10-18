import { Upload } from "lucide-react";

export function PostProperty() {
  return (
    <div>
      <div className="seller-header">
        <div>
          <span className="eyebrow">Thông tin bất động sản</span>
          <h1>Đăng tin mới</h1>
        </div>
      </div>
      <form className="property-form" onSubmit={(e) => e.preventDefault()}>
        <div className="form-section">
          <span>01</span>
          <div>
            <h2>Thông tin chính</h2>
            <p>Cho người xem biết bạn đang cung cấp điều gì.</p>
          </div>
          <div className="form-fields">
            <label>
              Tiêu đề
              <input
                required
                placeholder="Ví dụ: Căn hộ 2 phòng ngủ nhiều ánh sáng"
              />
            </label>
            <div className="filter-row">
              <label>
                Hình thức
                <select>
                  <option>Mua bán</option>
                  <option>Cho thuê</option>
                </select>
              </label>
              <label>
                Loại bất động sản
                <select>
                  <option>Căn hộ</option>
                  <option>Nhà phố</option>
                  <option>Đất</option>
                </select>
              </label>
            </div>
            <label>
              Mô tả
              <textarea
                rows={6}
                placeholder="Mô tả không gian, tiện ích và điểm nổi bật..."
              />
            </label>
          </div>
        </div>
        <div className="form-section">
          <span>02</span>
          <div>
            <h2>Giá và thông số</h2>
            <p>Các trường bắt buộc theo API hiện tại.</p>
          </div>
          <div className="form-fields">
            <div className="filter-row">
              <label>
                Giá (VNĐ)
                <input type="number" min="1" required />
              </label>
              <label>
                Diện tích (m²)
                <input type="number" min="1" required />
              </label>
            </div>
            <div className="triple-row">
              <label>
                Phòng ngủ
                <input type="number" min="0" />
              </label>
              <label>
                Phòng tắm
                <input type="number" min="0" />
              </label>
              <label>
                Số tầng
                <input type="number" min="0" />
              </label>
            </div>
          </div>
        </div>
        <div className="form-section">
          <span>03</span>
          <div>
            <h2>Vị trí và hình ảnh</h2>
            <p>Ảnh rõ nét giúp người xem đánh giá tốt hơn.</p>
          </div>
          <div className="form-fields">
            <label>
              Địa chỉ
              <input required />
            </label>
            <label>
              Thông tin pháp lý
              <input required placeholder="Nhập đúng thông tin được xác nhận" />
            </label>
            <label className="upload-box">
              <Upload />
              <strong>Chọn ảnh bất động sản</strong>
              <small>JPG, PNG theo giới hạn backend</small>
              <input type="file" multiple accept="image/png,image/jpeg" />
            </label>
          </div>
        </div>
        <div className="form-actions">
          <button className="button button-primary" type="submit">
            Lưu tin đăng
          </button>
          <p>
            Form đã sẵn sàng về giao diện; danh mục động và xác nhận upload cần
            dữ liệu API tương ứng.
          </p>
        </div>
      </form>
    </div>
  );
}

