# Báo cáo kiểm tra và chỉnh sửa Cat Sleep Timer

Ngày kiểm tra: 05/08/2026

## Tóm tắt

Ứng dụng đã được giữ đúng phạm vi: hẹn tắt máy cục bộ sau một khoảng thời gian và hủy lịch đang chờ. Lịch được Windows quản lý nên vẫn hoạt động sau khi đóng giao diện. Không thêm thư viện, hình ảnh hay tính năng hẹn giờ ngoài phạm vi.

## Lỗi và rủi ro đã phát hiện

1. `CatNapShutdownTimer.ps1` là UTF-8 không BOM. Windows PowerShell 5.1 có thể đọc sai tiếng Việt, dẫn đến lỗi cú pháp và không mở được ứng dụng.
2. Click nút hẹn/hủy chờ `shutdown.exe` trên luồng giao diện đến 5 giây. Cách cũ còn redirect cả stdout/stderr nhưng không đọc chúng, có nguy cơ kẹt tiến trình nếu bộ đệm đầy.
3. Mã cũ hiển thị cảnh báo Administrator gây hiểu nhầm. Quyền tắt máy thường có sẵn cho tài khoản Windows tương tác; lỗi thực tế cần hiển thị mã trả về.
4. Mọi lỗi hủy lịch đều bị diễn giải là “không có lịch”. Mã 1116 mới đúng là không có shutdown đang chờ; các lỗi khác phải được báo là lỗi hệ thống.
5. Mã cũ cho rằng lệnh shutdown mới luôn thay thế lịch cũ. Việc tự gọi `/a` để thay thế có thể hủy nhầm lịch được tạo bởi ứng dụng khác.
6. Giao diện cũ có vẽ tùy biến, cache tài nguyên GDI và dispose control thủ công không cần thiết. Điều này làm vòng đời tài nguyên khó đọc và khó kiểm tra hơn.
7. Mức ép đóng ứng dụng cần được nói rõ: theo tài liệu Microsoft, khi `/t` lớn hơn 0 thì Windows đã ngầm dùng `/f`; dữ liệu chưa lưu có thể mất.

## Thay đổi đã thực hiện

- Tách `CatNapShutdownTimer.Core.psm1` để validation, tạo đối số cố định và mở `shutdown.exe` độc lập với UI.
- Chỉ cho phép số nguyên dương, phút/giờ hợp lệ và tối đa 7 ngày. Đối số lệnh cố định là `/s /f /t <giây đã kiểm tra> /d p:0:0 /c "Hen gio tat may"`; không có dữ liệu văn bản người dùng đi vào lệnh.
- Dùng đường dẫn thư mục hệ thống Windows thay vì biến môi trường tự ghép, không gọi qua `cmd.exe`, không redirect output/error và không dùng `Invoke-Expression`.
- Thay xử lý chặn bằng `System.Windows.Forms.Timer` kiểm tra tiến trình mỗi 100 ms. UI bị khóa trong lúc gửi lệnh; quá 3 giây chỉ báo trạng thái không xác định, không kill tiến trình để tránh làm sai lệnh hệ thống.
- Không tự hủy lịch cũ khi đặt lịch mới. Nút hủy có hộp xác nhận và chỉ báo “không có lịch” khi mã trả về là 1116.
- Lưu hai script PowerShell thực thi ở UTF-8 có BOM, tương thích Windows PowerShell 5.1. Launcher và hướng dẫn đã được cập nhật theo cấu trúc ba tệp cần thiết.
- Đơn giản hóa giao diện WinForms: pastel mèo nhẹ, chữ rõ, tooltip/nhãn truy cập, nút nhanh, tab order, trạng thái văn bản và không vẽ GDI tùy biến.
- Giải phóng timer, process handle và font do ứng dụng sở hữu khi đóng; khi lịch đã được Windows xác nhận, đóng cửa sổ không hủy lịch.

## Kiểm tra đã chạy

- `tests\Test-CatNapShutdownTimer.ps1`: 8/8 kiểm tra đạt (quy đổi, biên, validation và mẫu đối số).
- `tests\Test-CatNap-UiSmoke.ps1`: cửa sổ, tiêu đề, input, các nút chính và đóng ứng dụng rảnh đều đạt; test không bấm hẹn hay hủy shutdown thật.
- Parser của Windows PowerShell 5.1: đạt cho script giao diện, module lõi và hai script kiểm thử.
- Launcher `Start-CatNapShutdownTimer.bat`: mở được UI, đóng khi rảnh và trả mã 0.
- Đo khởi động UI 5 lần: 1249, 1294, 1308, 1349, 1492 ms; trung bình 1338 ms.

Không chạy `shutdown.exe /s` thật trong kiểm thử để không ảnh hưởng máy đang sử dụng.

## Cách chạy

1. Giải nén toàn bộ gói ZIP vào một thư mục.
2. Giữ `Start-CatNapShutdownTimer.bat`, `CatNapShutdownTimer.ps1` và `CatNapShutdownTimer.Core.psm1` cùng thư mục.
3. Nhấp đúp `Start-CatNapShutdownTimer.bat`.
4. Chọn thời gian, đọc cảnh báo, rồi xác nhận hẹn giờ.

Khi đến giờ, game và các ứng dụng đang chạy có thể bị ép đóng. Để hủy lịch, mở lại ứng dụng và bấm `HỦY LỊCH`; thao tác này cũng có thể hủy lịch Windows do ứng dụng khác tạo.

Tham khảo hành vi `shutdown.exe`: [Microsoft Learn](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/shutdown).
