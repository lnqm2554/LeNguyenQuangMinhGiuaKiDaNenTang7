# BÁO CÁO BÀI THI GIỮA KỲ

## Lập trình đa nền tảng — Ứng dụng quản lý sản phẩm

**Sinh viên:** ........................................................  
**Mã sinh viên:** ....................................................  
**Lớp:** ..............................................................  
**Giảng viên:** .......................................................  
**Ngày nộp:** .........................................................

> Hoàn thiện các dòng chấm và thay các vị trí `[Chèn ảnh ...]` bằng ảnh chụp từ dự án Firebase và ứng dụng đã chạy trước khi nộp. Không dùng ảnh minh họa thay cho ảnh chụp kết quả thật.

## 1. Mục tiêu

Xây dựng ứng dụng quản trị sản phẩm đa nền tảng bằng Flutter. Người quản trị đăng nhập, thêm/xem/sửa/xóa sản phẩm, chọn ảnh từ thiết bị; dữ liệu lưu trên Firebase để giao diện web và di động cùng sử dụng.

## 2. Công nghệ và thư viện

- Flutter, Dart, Material 3: giao diện responsive cho web và Android.
- Firebase Authentication: đăng nhập email/mật khẩu.
- Cloud Firestore: lưu và đồng bộ danh sách sản phẩm theo thời gian thực.
- Cloudinary: lưu ảnh; URL HTTPS được lưu ở trường `image`.
- `image_picker`: chọn ảnh; `mime`: xác định loại ảnh.
- `intl`: định dạng giá tiền; `http`: tải ảnh lên Cloudinary.

Các lệnh cài đặt và cấu hình:

```powershell
flutter doctor -v
flutter create --project-name product_admin --platforms=web,android <thu_muc_khung_rieng>
dart pub global activate flutterfire_cli
flutterfire configure
flutter pub get
```

Không tạo khung Flutter ngay trên thư mục source hiện có vì có thể ghi đè `lib/main.dart`. Hướng dẫn Windows từng bước để tạo thư mục khung riêng, chép `web`/`android` và cấu hình PATH nằm trong [`README.md`](./README.md), mục 1 và 3.

Firebase CLI và triển khai rules:

```powershell
npm install -g firebase-tools
firebase --version
firebase login
firebase use --add
firebase use
firebase deploy --only firestore:rules
```

Trong `firebase use --add`, chọn đúng Firebase project ID và đặt alias `default`; xác nhận lại bằng `firebase use` trước khi deploy.

App tải ảnh bằng unsigned upload preset của Cloudinary. Gói Free hiện được quảng cáo là không cần thẻ tín dụng; xác nhận quota/điều khoản hiện hành khi tạo tài khoản. Trong Cloudinary Console, ghi **Cloud name**, vào **Settings → Upload → Upload presets → Add upload preset**, tạo preset có **Signing Mode: Unsigned**, và giới hạn ảnh JPEG/PNG/WebP, 5 MB nếu giao diện cho phép. Không dùng hoặc đưa API Secret vào mã nguồn.

Chạy ứng dụng bằng hai cấu hình public sau (thay giá trị ví dụ bằng Cloud name và preset của bạn):

```powershell
flutter run -d chrome --dart-define=CLOUDINARY_CLOUD_NAME=your_cloud_name --dart-define=CLOUDINARY_UPLOAD_PRESET=product_admin_unsigned
```

Mở emulator/thiết bị, lấy ID bằng `flutter devices`, sau đó chạy riêng:

```powershell
flutter run -d <device-id> --dart-define=CLOUDINARY_CLOUD_NAME=your_cloud_name --dart-define=CLOUDINARY_UPLOAD_PRESET=product_admin_unsigned
```

Unsigned preset được nhúng vào client nên có thể bị người khác sử dụng; giới hạn preset và theo dõi quota. Thay/xóa sản phẩm không xóa ảnh cũ trên Cloudinary; có thể dọn ảnh thủ công trong Media Library. Xóa ảnh tự động cần backend an toàn giữ API Secret, không được đặt secret trong app.

## 3. Thiết kế dữ liệu

Collection Firestore: `products`. Mỗi sản phẩm chỉ có các trường:

| Tên trường | Kiểu dữ liệu | Ý nghĩa |
|---|---|---|
| `name` | String | Tên sản phẩm |
| `price` | Number | Giá sản phẩm, không âm |
| `soluong` | Integer | Số lượng, không âm |
| `image` | String | URL HTTPS ảnh trên Cloudinary |

ID tài liệu do Firestore quản lý; không lưu thêm trường nào vào tài liệu sản phẩm. Email và thông tin xác thực được Firebase Authentication quản lý riêng. File JSON dữ liệu mẫu nằm tại `database/products.json`; thay bằng dữ liệu thật đã nhập/xuất trước khi nộp.

**Ảnh Firebase Console → Firestore → collection `products`:**  
[Chèn ảnh chụp dữ liệu Firestore tại đây]

## 4. Các bước cấu hình và chạy

1. Tạo Firebase project tại Firebase Console, ghi lại project ID.
2. Bật **Authentication → Email/Password**; tạo tài khoản demo ở **Authentication → Users → Add user**.
3. Tạo Firestore Database ở chế độ production. Không cần bật Firebase Storage.
4. Cài Flutter SDK, Android Studio/Android SDK và Node.js LTS; xử lý các mục cần thiết của `flutter doctor -v`. Hướng dẫn cài Windows chi tiết trong [`README.md`](./README.md), mục 1.
5. Tạo thư mục nền tảng `web` và `android` bằng Flutter khung trong một thư mục riêng, rồi sao chép chúng vào source. **Không chạy `flutter create ... .` trong thư mục source hiện có.** Xem [`README.md`](./README.md), mục 3.1.
6. Cài Firebase CLI, đăng nhập, chọn đúng project và deploy `firebase/firestore.rules`; xác minh `firebase use` trước khi deploy.
7. Chạy `flutterfire configure`, chọn Firebase project và nền tảng Web/Android. Kiểm tra lệnh đã tạo `lib/firebase_options.dart`; sau đó chạy `flutter pub get`.
8. Tạo Cloudinary unsigned upload preset như hướng dẫn mục 2; ghi lại Cloud name và preset name.
9. Chạy ứng dụng với các tham số Cloudinary:

   ```powershell
   flutter run -d chrome --dart-define=CLOUDINARY_CLOUD_NAME=your_cloud_name --dart-define=CLOUDINARY_UPLOAD_PRESET=product_admin_unsigned
   ```

   Mở Chrome cho lệnh web. Để chạy Android, khởi động emulator/thiết bị, chạy `flutter devices` trong lệnh riêng, sau đó chạy `flutter run -d <device-id-hiển-thị> --dart-define=CLOUDINARY_CLOUD_NAME=your_cloud_name --dart-define=CLOUDINARY_UPLOAD_PRESET=product_admin_unsigned`.
10. Đăng nhập bằng tài khoản demo; thêm sản phẩm, chọn ảnh, sau đó thử sửa và xóa. Build web:

   ```powershell
   flutter build web --dart-define=CLOUDINARY_CLOUD_NAME=your_cloud_name --dart-define=CLOUDINARY_UPLOAD_PRESET=product_admin_unsigned
   ```

**Ảnh trang Authentication và tài khoản demo:**
[Chèn ảnh chụp Firebase Authentication tại đây]

**Ảnh Firestore Rules và Cloudinary Upload Preset:**
[Chèn ảnh Firestore Rules và cấu hình preset (che thông tin riêng nếu có) tại đây]

## 5. Chức năng

- Đăng nhập và đăng xuất bằng Firebase Authentication.
- Hiển thị danh sách sản phẩm realtime; giao diện tự điều chỉnh theo độ rộng màn hình.
- Thêm sản phẩm với kiểm tra tên, giá, số lượng và ảnh bắt buộc.
- Tải ảnh JPEG/PNG/WebP (tối đa 5 MB) lên Cloudinary và hiển thị URL ảnh trong trường `image`.
- Sửa/xóa sản phẩm có xác nhận. Vì app client không chứa Cloudinary API Secret, ảnh cũ không tự xóa khỏi Cloudinary và cần dọn thủ công nếu không dùng nữa.
- Firebase Rules yêu cầu đăng nhập và chỉ chấp nhận đúng bốn trường sản phẩm.

**Ảnh màn hình đăng nhập:**  
[Chèn ảnh chụp ứng dụng tại đây]

**Ảnh danh sách sản phẩm trên web:**  
[Chèn ảnh chụp ứng dụng tại đây]

**Ảnh biểu mẫu thêm/sửa sản phẩm:**  
[Chèn ảnh chụp ứng dụng tại đây]

**Ảnh danh sách và chi tiết sản phẩm trên Android:**  
[Chèn ảnh chụp thiết bị/emulator tại đây]

## 6. Kiểm thử

Thực hiện các kiểm thử sau sau khi cấu hình Firebase và chạy ứng dụng. Đánh dấu kết quả thực tế, ghi thiết bị/trình duyệt và chèn ảnh nếu phù hợp.

| STT | Trường hợp kiểm thử | Kết quả thực tế |
|---:|---|---|
| 1 | Đăng nhập bằng tài khoản hợp lệ | Chưa thực hiện |
| 2 | Nhập sai thông tin đăng nhập, kiểm tra thông báo lỗi | Chưa thực hiện |
| 3 | Thêm sản phẩm có đủ bốn trường và ảnh | Chưa thực hiện |
| 4 | Nhập tên rỗng, giá/số lượng không hợp lệ | Chưa thực hiện |
| 5 | Sửa tên, giá, số lượng và ảnh; tải lại để kiểm tra dữ liệu | Chưa thực hiện |
| 6 | Hủy và xác nhận xóa; kiểm tra Firestore và lưu ý ảnh vẫn còn trên Cloudinary | Chưa thực hiện |
| 7 | Mở đồng thời web và Android để kiểm tra đồng bộ | Chưa thực hiện |
| 8 | Kiểm tra tài liệu chỉ có `name`, `price`, `soluong`, `image` | Chưa thực hiện |

## 7. Kết luận

Ứng dụng và bộ rules được chuẩn bị để đáp ứng luồng quản lý sản phẩm trên web và thiết bị di động. Hoàn thiện đánh giá cuối cùng sau khi cấu hình Firebase, chạy đủ các ca kiểm thử và bổ sung ảnh minh họa thực tế.

## 8. Link nộp bài

- **GitHub source code:** https://github.com/lnqm2554/LeNguyenQuangMinhGiuaKiDaNenTang7
- **Video demo:** [Điền link video sau khi quay và tải lên]
- **File dữ liệu:** `database/products.json` (cập nhật thành dữ liệu thực tế trước khi nộp)
