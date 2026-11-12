# Quản lý sản phẩm — Flutter + Firebase

Ứng dụng quản trị responsive chạy trên web và thiết bị di động, gồm đăng nhập, thêm, xem, sửa, xóa sản phẩm, chọn ảnh từ thư viện và đồng bộ dữ liệu bằng Cloud Firestore. Ảnh được tải lên Cloudinary; trường `image` lưu URL ảnh HTTPS.

## Giới hạn schema

Mỗi tài liệu trong collection `products` chỉ có đúng bốn trường:

| Trường | Kiểu | Ràng buộc |
|---|---|---|
| `name` | String | Không rỗng, tối đa 120 ký tự |
| `price` | Number | Từ 0 trở lên |
| `soluong` | Integer | Từ 0 trở lên |
| `image` | String | URL ảnh |

ID tài liệu do Firestore quản lý, không phải trường dữ liệu. Email/mật khẩu thuộc Firebase Authentication, không được thêm vào sản phẩm. Firebase Rules kiểm tra chặt chẽ tập trường này.

## 1. Chuẩn bị máy Windows

Thực hiện lần lượt. Nếu đã cài Flutter/Android Studio, mở PowerShell và chạy `flutter doctor -v`; chuyển sang bước 2 nếu không có lỗi cần xử lý.

### 1.1. Cài Flutter SDK

1. Cài Git for Windows và VS Code nếu máy chưa có.
2. Tải Flutter SDK cho Windows từ [flutter.dev/install](https://docs.flutter.dev/get-started/install/windows/mobile), giải nén vào thư mục ngắn, không có dấu cách, ví dụ `C:\src\flutter`. Không giải nén vào `Program Files`.
3. Mở Start → tìm **Edit the system environment variables** → **Environment Variables** → chọn `Path` trong **User variables** → **Edit** → **New** → thêm `C:\src\flutter\bin` → bấm OK để đóng mọi cửa sổ.
4. Đóng và mở lại VS Code/PowerShell. Chạy:

   ```powershell
   flutter --version
   flutter doctor -v
   ```

### 1.2. Cài Android Studio (để chạy bản di động)

1. Cài Android Studio từ [developer.android.com/studio](https://developer.android.com/studio).
2. Mở Android Studio → **More Actions → SDK Manager**. Trong **SDK Platforms**, cài một Android SDK Platform được hỗ trợ. Trong **SDK Tools**, chọn **Android SDK Command-line Tools (latest)**, **Android SDK Platform-Tools**, **Android SDK Build-Tools** và **Android Emulator** → **Apply**.
3. Trong PowerShell chạy:

   ```powershell
   flutter doctor --android-licenses
   ```

   Gõ `y` rồi Enter cho các giấy phép được hỏi. Chạy lại `flutter doctor -v`.
4. Tạo máy ảo: Android Studio → **More Actions → Virtual Device Manager → Create device** → chọn một điện thoại → chọn/tải system image → **Finish** → bấm nút Play. Hoặc bật Developer options + USB debugging trên điện thoại Android, cắm cáp USB và chấp nhận hộp thoại cấp quyền.
5. Kiểm tra thiết bị được nhận:

   ```powershell
   flutter devices
   ```

### 1.3. Cài Node.js (để dùng Firebase CLI)

1. Cài bản LTS từ [nodejs.org](https://nodejs.org/), giữ tùy chọn cài npm.
2. Mở PowerShell mới và kiểm tra:

   ```powershell
   node --version
   npm --version
   ```

## 2. Tạo và cấu hình Firebase (thực hiện trên trang web)

### 2.1. Tạo project

1. Mở [Firebase Console](https://console.firebase.google.com/) và đăng nhập Google.
2. Bấm **Add project** (hoặc **Create a project**), nhập tên, ví dụ `product-admin-demo`, bấm **Continue**.
3. Analytics không cần cho bài này; có thể tắt để thiết lập nhanh. Bấm **Create project**, chờ hoàn tất rồi **Continue**.
4. Ghi lại **Project ID**: mở biểu tượng bánh răng cạnh **Project Overview → Project settings → General**. Dùng đúng project ID này ở các bước tiếp theo.

### 2.2. Bật đăng nhập email/mật khẩu

1. Menu trái → **Build → Authentication → Get started**.
2. Mở tab **Sign-in method** (ở giao diện mới có thể tên **Sign-in providers**).
3. Chọn **Email/Password** → bật tùy chọn Email/Password đầu tiên → **Save**. Không cần bật Email link.
4. Chưa cần tạo tài khoản ở bước này; tạo ở mục 2.5 sau khi biết thông tin đăng nhập muốn dùng.

### 2.3. Tạo Firestore

1. Menu trái → **Build → Firestore Database → Create database**.
2. Chọn **Production mode**. Không chọn test mode.
3. Chọn vị trí (location) phù hợp, gần người dùng; xác nhận **Create/Enable**. Hãy chọn kỹ vì vị trí database thường không đổi được sau khi tạo.
4. Không cần tạo collection `products` bằng tay. Ứng dụng sẽ tạo collection khi thêm sản phẩm đầu tiên.

### 2.4. Cấu hình Cloudinary cho ảnh (không dùng Firebase Storage)

1. Tạo tài khoản Cloudinary tại [cloudinary.com](https://cloudinary.com/). Gói Free hiện được quảng cáo là miễn phí và không cần thẻ tín dụng; kiểm tra hạn mức/điều khoản hiện hành trước khi dùng.
2. Trong **Cloudinary Console → Dashboard**, ghi lại **Cloud name**.
3. Vào **Settings → Upload → Upload presets → Add upload preset** (tên/vị trí mục có thể khác đôi chút).
4. Đặt tên preset, ví dụ `product_admin_unsigned`, chọn **Signing Mode: Unsigned**, giới hạn định dạng thành `jpg`, `jpeg`, `png`, `webp` và dung lượng tối đa 5 MB nếu giao diện cho phép, sau đó lưu preset.
5. App chỉ cần Cloud name và tên unsigned preset. Không đưa API Secret hoặc khóa bí mật vào Flutter, `--dart-define`, GitHub hay Firestore. Unsigned preset sẽ công khai trong ứng dụng; giới hạn định dạng/dung lượng, theo dõi quota và không dùng cho ảnh riêng tư.
6. Firebase Storage không còn cần thiết. Không tạo bucket hoặc deploy Storage rules; Firebase chỉ cung cấp Authentication và Firestore cho ứng dụng.

### 2.5. Tạo tài khoản đăng nhập

1. Trong **Authentication → Users**, bấm **Add user**.
2. Nhập email và mật khẩu (ít nhất 6 ký tự), bấm **Add user**.
3. Ghi lại email/mật khẩu để đăng nhập khi chạy demo; không ghi mật khẩu vào GitHub hoặc file source.
4. Ứng dụng chỉ có màn hình đăng nhập, không có đăng ký. Tạo tài khoản tại Console như bước này.

## 3. Tạo cấu hình nền tảng cho source có sẵn

> **Quan trọng:** source hiện tại đã có `lib/main.dart` và `pubspec.yaml`. Không chạy `flutter create ... .` trực tiếp trong thư mục dự án: Flutter có thể thay thế file giao diện đang có.

### 3.1. Sinh thư mục Android/Web an toàn

1. Mở thư mục dự án trong File Explorer hoặc VS Code. Mở Terminal → **New Terminal**; terminal phải ở đúng thư mục chứa `pubspec.yaml`, `lib`, `firebase.json`.
2. Kiểm tra vị trí:

   ```powershell
   Get-Location
   Get-ChildItem
   ```

3. Tạo project Flutter khung **ở thư mục khác** để không ghi đè source:

   ```powershell
   $scaffold = Join-Path $env:TEMP 'product_admin_scaffold'
   flutter create --project-name product_admin --platforms=web,android $scaffold
   ```

   Nếu báo thư mục đích đã tồn tại và không rỗng, đổi tên `product_admin_scaffold` trong lệnh thành `product_admin_scaffold2`.
4. Sao chép chỉ thư mục nền tảng và metadata sang thư mục dự án (đảm bảo terminal vẫn đang ở thư mục dự án):

   ```powershell
   Copy-Item "$scaffold\web" . -Recurse
   Copy-Item "$scaffold\android" . -Recurse
   Copy-Item "$scaffold\.metadata" . -Force
   ```

   Nếu PowerShell hỏi có ghi đè file, không ghi đè `lib\main.dart` hoặc `pubspec.yaml`; chỉ chép các thư mục/file nêu trên. Không cần chép `lib`, `test`, `pubspec.yaml` từ scaffold.
5. Xác nhận source gốc vẫn còn:

   ```powershell
   Test-Path .\lib\main.dart
   Test-Path .\pubspec.yaml
   ```

   Cả hai phải trả về `True`.

### 3.2. Cài Firebase CLI và triển khai rules

Trong terminal đang ở thư mục dự án, chạy lần lượt:

```powershell
npm install -g firebase-tools
firebase --version
firebase login
firebase use --add
```

1. `firebase login` mở trình duyệt; đăng nhập đúng Google account đang sở hữu Firebase project, rồi quay về terminal.
2. `firebase use --add` hiển thị danh sách project; chọn project đã tạo. Khi hỏi alias, nhập `default`.
3. Kiểm tra project được chọn:

   ```powershell
   firebase use
   ```

   Phải hiện tên/ID project của bạn. Nếu sai, chạy lại `firebase use --add` và chọn đúng.
4. Triển khai rules trong source:

   ```powershell
   firebase deploy --only firestore:rules
   ```

   Chỉ tiếp tục nếu lệnh báo deploy thành công. Không đổi rules thành `allow read, write: if true`.

### 3.3. Liên kết Flutter với Firebase

Trong cùng terminal/thư mục dự án:

```powershell
dart pub global activate flutterfire_cli
flutterfire configure
```

1. Nếu `flutterfire` không được nhận diện, đóng/mở terminal mới. Nếu vẫn không được, thêm `%LOCALAPPDATA%\Pub\Cache\bin` vào User `Path`, rồi mở terminal mới và chạy lại `flutterfire configure`.
2. Khi CLI hỏi Firebase project, chọn project đã tạo.
3. Khi hỏi platform, chọn **web** và **android** (di chuyển bằng phím mũi tên, chọn/bỏ chọn bằng Space, xác nhận bằng Enter; cách hiển thị có thể khác theo phiên bản).
4. Nếu CLI hỏi Android package name/application ID, nhập đúng `com.example.product_admin` (khung tạo ở mục 3.1 dùng tên này), hoặc dùng đúng ID được in trong phần Android app settings nếu đã thay đổi.
5. Chờ lệnh hoàn tất. Phải xuất hiện file `lib/firebase_options.dart`. Đây là cấu hình Firebase client cần để chạy app; giữ file này trong source nộp. **Không** tạo hay tải service-account JSON vào ứng dụng.
6. Cài các thư viện:

   ```powershell
   flutter pub get
   ```

   Chờ đến khi lệnh kết thúc thành công trước khi chạy app.

## 4. Chạy thử từng nền tảng

### 4.1. Chạy web

1. Cài Google Chrome nếu máy chưa có; đóng và mở terminal lại để Flutter nhận Chrome.
2. Trong terminal tại thư mục dự án:

   ```powershell
   flutter devices
   flutter run -d chrome --dart-define=CLOUDINARY_CLOUD_NAME=your_cloud_name --dart-define=CLOUDINARY_UPLOAD_PRESET=product_admin_unsigned
   ```

3. Thay `your_cloud_name` và `product_admin_unsigned` bằng giá trị thật ở mục 2.4. Chrome mở ứng dụng; đăng nhập bằng tài khoản tại mục 2.5.
4. Nhấn **Thêm sản phẩm** → nhập tên, giá, số lượng → **Chọn hình ảnh** → chọn file ảnh từ máy → **Thêm**. Trên web, hộp thoại chọn ảnh là file picker của trình duyệt.
5. Mở **Firebase Console → Firestore Database → Data** để kiểm tra collection `products`; mở **Cloudinary Console → Media Library** để kiểm tra ảnh.

### 4.2. Chạy Android

1. Khởi động emulator hoặc kết nối điện thoại và chấp nhận thông báo cho phép USB debugging.
2. Chạy `flutter devices`, chép device ID hiển thị (ví dụ `emulator-5554`).
3. Chạy lệnh với đúng ID:

   ```powershell
   flutter run -d emulator-5554 --dart-define=CLOUDINARY_CLOUD_NAME=your_cloud_name --dart-define=CLOUDINARY_UPLOAD_PRESET=product_admin_unsigned
   ```

   Thay `emulator-5554` bằng ID thực tế của thiết bị và thay hai giá trị Cloudinary như mục 2.4.
4. Đăng nhập, thêm sản phẩm và chọn ảnh từ thư viện. Nếu điện thoại không hiện trong `flutter devices`, kiểm tra USB debugging/cáp hoặc khởi động lại emulator, rồi chạy `flutter doctor -v`.

### 4.3. Build web

```powershell
flutter build web --dart-define=CLOUDINARY_CLOUD_NAME=your_cloud_name --dart-define=CLOUDINARY_UPLOAD_PRESET=product_admin_unsigned
```

Nếu build thành công, thư mục `build/web` có thể dùng để triển khai. Để demo trực tiếp, dùng lệnh đã cấu hình ở mục 4.1 để app nhận đủ hai giá trị Cloudinary.

## 5. Kiểm tra chức năng và chuẩn bị bài nộp

1. Đăng nhập hợp lệ; thử mật khẩu sai để chụp thông báo lỗi.
2. Thêm 2–3 sản phẩm thật với ảnh; kiểm tra thẻ hiển thị tên, giá, số lượng và ảnh.
3. Sửa một sản phẩm, tải lại trang và kiểm tra dữ liệu đã lưu.
4. Xóa sản phẩm thử nghiệm; kiểm tra tài liệu Firestore đã bị xóa. Ảnh trên Cloudinary được giữ lại; nếu không cần, xóa thủ công trong Media Library.
5. Mở Firebase Console → Firestore → `products`; từng tài liệu phải có đúng bốn trường `name`, `price`, `soluong`, `image`. Chụp ảnh màn hình rõ tên trường và giá trị.
6. Chụp ảnh màn hình đăng nhập, danh sách web, form thêm/sửa, giao diện Android, Authentication Users, Firestore Data và Cloudinary Media Library. Thay chỗ trống trong [`BAO_CAO.md`](./BAO_CAO.md) bằng ảnh và kết quả **thực tế**.
7. `database/products.json` ban đầu là dữ liệu mẫu, chưa phải bản xuất Firestore. Trước khi nộp, cập nhật file bằng sản phẩm thật; mỗi object phải chỉ có bốn thuộc tính đã nêu. Có thể sao chép giá trị từ Firestore Data và sửa file bằng VS Code; kiểm tra JSON bằng PowerShell:

   ```powershell
   Get-Content .\database\products.json -Raw | ConvertFrom-Json
   ```

   Không chép document ID vào từng object. Trong báo cáo ghi rõ JSON này là file dữ liệu nộp; không tuyên bố nó được tự động xuất bởi Firebase Console.
8. Đẩy source lên GitHub và quay video demo; điền hai liên kết đó vào báo cáo. Không đẩy mật khẩu, service-account key hoặc thông tin bí mật lên repository.

## 6. Lỗi thường gặp

- **`flutter`/`dart` is not recognized:** kiểm tra `C:\src\flutter\bin` đã ở User `Path`; mở lại terminal và chạy `flutter doctor -v`.
- **Android toolchain chưa sẵn sàng:** cài các SDK Tools ở mục 1.2, sau đó chạy `flutter doctor --android-licenses` và trả lời `y`.
- **`firebase` không được nhận diện:** cài Node.js LTS, mở terminal mới, chạy `npm install -g firebase-tools`.
- **`flutterfire` không được nhận diện:** thêm `%LOCALAPPDATA%\Pub\Cache\bin` vào User `Path`; mở terminal mới.
- **Không tìm thấy `firebase_options.dart`:** chạy `flutterfire configure` ở đúng thư mục dự án và kiểm tra `lib\firebase_options.dart`.
- **`permission-denied` khi tải dữ liệu:** đảm bảo đã đăng nhập, chọn đúng project bằng `firebase use`, và deploy rules thành công.
- **Đăng nhập không được:** kiểm tra đã bật Email/Password và tài khoản tồn tại trong Authentication → Users.
- **Không tải được ảnh:** kiểm tra Cloud name, tên unsigned preset, định dạng JPEG/PNG/WebP, ảnh dưới 5 MB và kết nối mạng. Xem thông báo lỗi Cloudinary trong app/Console và quota của tài khoản.
- **App báo chưa cấu hình Cloudinary:** chạy lại app với cả hai tham số `--dart-define=CLOUDINARY_CLOUD_NAME=...` và `--dart-define=CLOUDINARY_UPLOAD_PRESET=...`.
- **Lưu Firestore lỗi sau khi upload:** ảnh có thể đã tải lên Cloudinary nhưng chưa liên kết với sản phẩm; tìm và dọn ảnh thừa trong Media Library.
- **Xóa/sửa sản phẩm nhưng ảnh cũ còn trên Cloudinary:** đây là chủ đích. Xóa media bằng API cần API Secret và backend đáng tin cậy; không nhúng secret vào app. Dọn ảnh cũ thủ công trong Media Library.
- **Sai Firebase project:** chạy `firebase use`; chạy lại `flutterfire configure` và chọn project đúng nếu cần.

## 3. File dữ liệu nộp

`database/products.json` là file JSON mẫu để nộp/đối chiếu; mỗi phần tử chỉ chứa bốn trường cho phép. Thay ảnh mẫu bằng ảnh thực tế nếu cần. Trước khi nộp, xuất các sản phẩm thật từ collection `products` ra JSON theo cùng cấu trúc (không đưa document ID hay trường Firebase khác vào mỗi sản phẩm). Có thể xem/chụp ảnh dữ liệu trong Firebase Console → Firestore Database → `products`.

Báo cáo bài thi có sẵn tại [`BAO_CAO.md`](./BAO_CAO.md); cần thay chỗ trống bằng thông tin cá nhân, ảnh chụp thật, kết quả kiểm thử và liên kết GitHub/video trước khi nộp.

## 4. Kiểm tra và minh họa báo cáo

- Đăng nhập thành công và thử thông báo khi nhập sai mật khẩu.
- Thêm sản phẩm có ảnh; chụp màn hình biểu mẫu, danh sách, tài liệu trên Firestore và ảnh trên Cloudinary.
- Sửa giá/số lượng/ảnh, tải lại trang và kiểm tra dữ liệu vẫn đồng bộ.
- Xóa sản phẩm; kiểm tra tài liệu đã bị xóa và lưu ý ảnh vẫn còn trên Cloudinary.
- Chạy trên Chrome và Android; chụp ảnh giao diện mobile, trong đó ảnh và thông tin sản phẩm hiển thị đúng.
- Ghi các lệnh cài thư viện (`flutter pub get`) và cấu hình Firebase/FlutterFire ở trên vào báo cáo.

## Ghi chú bảo mật

Rules yêu cầu người dùng đăng nhập mới đọc/ghi được sản phẩm và chỉ cho phép đúng bốn trường đã nêu. Ứng dụng không có màn hình tự đăng ký; tài khoản demo được tạo thủ công trong Firebase Console. Nếu triển khai thực tế cần bổ sung phân quyền admin riêng (custom claims) và quy trình quản lý tài khoản.
