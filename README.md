# CatNap Shutdown Timer 🐾

> A tiny, dependency-free Windows PowerShell timer for shutting down a PC after a gaming or idle session.

CatNap Shutdown Timer gives Windows a pending shutdown schedule through the native `shutdown.exe` command. Once the schedule is accepted, you can close the small cat-themed window and Windows keeps the schedule running.

> **Important:** Windows forces applications to close when a shutdown timeout is used. Save anything important before confirming. This project is best suited to an idle gaming machine, such as a Steam game left running.

## Features

- Native Windows shutdown scheduling; no service, tray process, or background daemon.
- Compact pastel cat-themed WinForms UI.
- Minutes and hours, with quick presets for 15 minutes, 30 minutes, 1 hour, and 2 hours.
- Input validation with a seven-day maximum.
- Explicit confirmation before scheduling or cancelling a Windows shutdown.
- UI-safe process polling so the window does not block while `shutdown.exe` responds.
- No external PowerShell modules or third-party dependencies.
- PowerShell 5.1-compatible UTF-8 source files.

## Requirements

- Windows 10 or Windows 11.
- Windows PowerShell 5.1 (`powershell.exe`).
- A normal interactive Windows account with permission to shut down the local computer.

## Quick start

1. Keep these three files in the same folder:

   - `Start-CatNapShutdownTimer.bat`
   - `CatNapShutdownTimer.ps1`
   - `CatNapShutdownTimer.Core.psm1`

2. Double-click `Start-CatNapShutdownTimer.bat`.
3. Enter a duration or choose a quick preset.
4. Review the warning and select **Yes**.
5. Close the window if desired; Windows retains the pending shutdown.

To cancel a pending shutdown, open the app again, select **HỦY LỊCH**, and confirm. The cancel command affects the pending Windows shutdown on that machine, even if another program created it.

## Run from PowerShell

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File .\CatNapShutdownTimer.ps1
```

The BAT launcher is recommended because it keeps the required files together and starts PowerShell in STA mode for WinForms.

## How it works

1. The UI validates a positive whole-number duration and converts it to seconds.
2. The core module builds a fixed command containing only that validated number:

   ```text
   shutdown.exe /s /f /t <seconds> /d p:0:0 /c "Hen gio tat may"
   ```

3. A short WinForms timer observes the native process without blocking the interface.
4. Windows owns the actual countdown, so closing CatNap does not cancel a successful schedule.

The `/f` behavior is intentional for unattended game sessions. It can discard unsaved application data. See the [Microsoft shutdown command documentation](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/shutdown) for the platform behavior.

## Tests

Run the contract tests:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\Test-CatNapShutdownTimer.ps1
```

Run the idle UI smoke test:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File .\tests\Test-CatNap-UiSmoke.ps1
```

The tests never execute a real shutdown command. They cover duration conversion, boundaries, command construction, parser compatibility, UI startup, visible controls, and clean idle close.

## Project layout

```text
.
├── CatNapShutdownTimer.ps1          # WinForms UI and interaction flow
├── CatNapShutdownTimer.Core.psm1    # Validation and native command boundary
├── Start-CatNapShutdownTimer.bat    # Double-click launcher
├── tests/
│   ├── Test-CatNapShutdownTimer.ps1
│   └── Test-CatNap-UiSmoke.ps1
├── AUDIT_REPORT.md                  # Vietnamese audit and verification report
└── README.md
```

## Troubleshooting

- **The app does not open:** confirm all three runtime files are in the same folder and try the BAT launcher again.
- **Windows rejects the schedule:** read the displayed exit code. A pending schedule or a local policy may require cancelling the existing schedule first.
- **The cancel button says there is no schedule:** Windows currently has no pending shutdown to cancel.
- **Do I need Administrator rights?** Usually no. The relevant requirement is the Windows “Shut down the system” user right.

## Audit

See [AUDIT_REPORT.md](AUDIT_REPORT.md) for the Vietnamese review of safety, validation, resource lifetime, UI responsiveness, Windows compatibility, and verification results.

## License

No license has been specified yet. Add a license before redistributing the project as open-source software.

---

# CatNap Shutdown Timer 🐾 — Tiếng Việt

> Ứng dụng PowerShell nhỏ gọn giúp hẹn Windows tắt máy sau khi treo game hoặc để máy nhàn rỗi.

CatNap Shutdown Timer giao lịch tắt máy cho `shutdown.exe` có sẵn trong Windows. Khi lịch đã được Windows chấp nhận, bạn có thể đóng cửa sổ nhỏ chủ đề mèo; Windows vẫn tiếp tục đếm thời gian.

> **Lưu ý quan trọng:** Khi tắt máy theo thời gian chờ, Windows sẽ ép đóng các ứng dụng đang chạy. Hãy lưu dữ liệu quan trọng trước khi xác nhận. Ứng dụng phù hợp với máy chủ yếu để treo game Steam hoặc tác vụ không cần lưu.

## Tính năng

- Dùng cơ chế tắt máy gốc của Windows, không chạy service hay daemon nền.
- Giao diện WinForms pastel chủ đề mèo, gọn và nhẹ.
- Chọn phút/giờ, có nút nhanh 15 phút, 30 phút, 1 giờ và 2 giờ.
- Kiểm tra đầu vào, giới hạn tối đa 7 ngày.
- Xác nhận rõ ràng trước khi hẹn hoặc hủy lịch.
- Theo dõi tiến trình không chặn giao diện.
- Không cần module PowerShell ngoài hay thư viện bên thứ ba.
- Tương thích mã nguồn UTF-8 với Windows PowerShell 5.1.

## Cách chạy nhanh

1. Để ba file sau cùng một thư mục: `Start-CatNapShutdownTimer.bat`, `CatNapShutdownTimer.ps1`, `CatNapShutdownTimer.Core.psm1`.
2. Nhấp đúp `Start-CatNapShutdownTimer.bat`.
3. Nhập thời gian hoặc chọn nút nhanh.
4. Đọc cảnh báo và chọn **Yes**.
5. Có thể đóng cửa sổ sau khi hẹn thành công.

Muốn hủy lịch, mở lại ứng dụng, chọn **HỦY LỊCH** rồi xác nhận. Lệnh hủy tác động tới lịch tắt máy Windows đang chờ trên máy đó, kể cả khi chương trình khác tạo lịch.

## Kiểm thử

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\Test-CatNapShutdownTimer.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File .\tests\Test-CatNap-UiSmoke.ps1
```

Kiểm thử không gọi lệnh shutdown thật; chỉ kiểm tra validation, biên thời gian, đối số lệnh, parser, khởi động UI và đóng cửa sổ khi rảnh.

## Báo cáo

Xem [AUDIT_REPORT.md](AUDIT_REPORT.md) để đọc báo cáo tiếng Việt về lỗi đã tìm thấy, thay đổi an toàn, tương thích Windows và kết quả xác minh.

## Giấy phép

Dự án hiện chưa chỉ định giấy phép. Hãy thêm license phù hợp trước khi phát hành như phần mềm mã nguồn mở.
