#requires -Version 5.1

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'CatNapShutdownTimer.Core.psm1') -Force
[System.Windows.Forms.Application]::EnableVisualStyles()

$script:isBusy = $false
$script:pendingAction = $null
$script:pendingProcess = $null
$script:operationStopwatch = $null
$script:pendingReplacement = $false
$script:ownedFonts = New-Object System.Collections.Generic.List[System.Drawing.Font]

function New-AppFont {
    param(
        [Parameter(Mandatory = $true)] [string] $Family,
        [Parameter(Mandatory = $true)] [float] $Size,
        [Parameter(Mandatory = $true)] [System.Drawing.FontStyle] $Style
    )

    $font = New-Object System.Drawing.Font($Family, $Size, $Style)
    [void]$script:ownedFonts.Add($font)
    return $font
}

$cBackground = [System.Drawing.Color]::FromArgb(255, 255, 248, 250)
$cCard = [System.Drawing.Color]::White
$cBorder = [System.Drawing.Color]::FromArgb(255, 242, 190, 205)
$cText = [System.Drawing.Color]::FromArgb(255, 75, 51, 58)
$cMuted = [System.Drawing.Color]::FromArgb(255, 125, 105, 111)
$cPink = [System.Drawing.Color]::FromArgb(255, 224, 92, 130)
$cPinkHover = [System.Drawing.Color]::FromArgb(255, 203, 68, 106)
$cQuick = [System.Drawing.Color]::FromArgb(255, 255, 240, 218)
$cQuickHover = [System.Drawing.Color]::FromArgb(255, 255, 227, 196)
$cCancel = [System.Drawing.Color]::FromArgb(255, 253, 235, 240)
$cCancelHover = [System.Drawing.Color]::FromArgb(255, 248, 213, 224)
$cSuccess = [System.Drawing.Color]::FromArgb(255, 30, 117, 73)
$cError = [System.Drawing.Color]::FromArgb(255, 185, 55, 74)

$fontRegular = New-AppFont 'Segoe UI' 9.5 ([System.Drawing.FontStyle]::Regular)
$fontSmall = New-AppFont 'Segoe UI' 8.5 ([System.Drawing.FontStyle]::Regular)
$fontSemibold = New-AppFont 'Segoe UI Semibold' 10 ([System.Drawing.FontStyle]::Regular)
$fontTitle = New-AppFont 'Segoe UI Semibold' 16 ([System.Drawing.FontStyle]::Regular)
$fontCat = New-AppFont 'Segoe UI Emoji' 16 ([System.Drawing.FontStyle]::Regular)

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Hẹn Giờ Tắt Máy - Cat Sleep Timer'
$form.StartPosition = 'CenterScreen'
$form.ClientSize = New-Object System.Drawing.Size(480, 475)
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false
$form.MinimizeBox = $true
$form.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Dpi
$form.BackColor = $cBackground
$form.Font = $fontRegular
$form.AccessibleName = 'Ứng dụng hẹn giờ tắt máy'

$card = New-Object System.Windows.Forms.Panel
$card.Location = New-Object System.Drawing.Point(20, 20)
$card.Size = New-Object System.Drawing.Size(440, 435)
$card.BackColor = $cCard
$card.BorderStyle = 'FixedSingle'
$form.Controls.Add($card)

$catIcon = New-Object System.Windows.Forms.Label
$catIcon.Text = '🐾'
$catIcon.Font = $fontCat
$catIcon.ForeColor = $cPink
$catIcon.TextAlign = 'MiddleCenter'
$catIcon.Location = New-Object System.Drawing.Point(20, 12)
$catIcon.Size = New-Object System.Drawing.Size(400, 28)
$card.Controls.Add($catIcon)

$title = New-Object System.Windows.Forms.Label
$title.Text = 'HẸN GIỜ TẮT MÁY'
$title.Font = $fontTitle
$title.ForeColor = $cText
$title.TextAlign = 'MiddleCenter'
$title.Location = New-Object System.Drawing.Point(20, 40)
$title.Size = New-Object System.Drawing.Size(400, 30)
$card.Controls.Add($title)

$subtitle = New-Object System.Windows.Forms.Label
$subtitle.Text = 'Mèo con canh giờ, bạn cứ yên tâm treo game nhé.'
$subtitle.Font = $fontRegular
$subtitle.ForeColor = $cMuted
$subtitle.TextAlign = 'MiddleCenter'
$subtitle.Location = New-Object System.Drawing.Point(20, 72)
$subtitle.Size = New-Object System.Drawing.Size(400, 22)
$card.Controls.Add($subtitle)

$timeGroup = New-Object System.Windows.Forms.GroupBox
$timeGroup.Text = ' Thời gian tắt máy '
$timeGroup.Font = $fontSemibold
$timeGroup.ForeColor = $cPink
$timeGroup.BackColor = $cCard
$timeGroup.Location = New-Object System.Drawing.Point(28, 105)
$timeGroup.Size = New-Object System.Drawing.Size(382, 82)
$card.Controls.Add($timeGroup)

$number = New-Object System.Windows.Forms.NumericUpDown
$number.Minimum = 1
$number.Maximum = 10080
$number.Value = 60
$number.DecimalPlaces = 0
$number.Increment = 1
$number.Font = $fontSemibold
$number.ForeColor = $cText
$number.TextAlign = 'Center'
$number.Location = New-Object System.Drawing.Point(26, 31)
$number.Size = New-Object System.Drawing.Size(190, 29)
$number.AccessibleName = 'Số lượng thời gian'
$number.TabIndex = 0
$timeGroup.Controls.Add($number)

$unit = New-Object System.Windows.Forms.ComboBox
$unit.DropDownStyle = 'DropDownList'
$unit.Font = $fontSemibold
$unit.ForeColor = $cText
[void]$unit.Items.Add('phút')
[void]$unit.Items.Add('giờ')
$unit.SelectedIndex = 0
$unit.Location = New-Object System.Drawing.Point(232, 31)
$unit.Size = New-Object System.Drawing.Size(122, 29)
$unit.AccessibleName = 'Đơn vị thời gian'
$unit.TabIndex = 1
$timeGroup.Controls.Add($unit)

$quickLabel = New-Object System.Windows.Forms.Label
$quickLabel.Text = 'Chọn nhanh:'
$quickLabel.Font = $fontSmall
$quickLabel.ForeColor = $cMuted
$quickLabel.Location = New-Object System.Drawing.Point(28, 202)
$quickLabel.Size = New-Object System.Drawing.Size(72, 22)
$card.Controls.Add($quickLabel)

function New-QuickButton {
    param(
        [Parameter(Mandatory = $true)] [string] $Text,
        [Parameter(Mandatory = $true)] [int] $Left
    )

    $button = New-Object System.Windows.Forms.Button
    $button.Text = $Text
    $button.Font = $fontSmall
    $button.BackColor = $cQuick
    $button.ForeColor = $cText
    $button.FlatStyle = 'Flat'
    $button.FlatAppearance.BorderColor = $cBorder
    $button.FlatAppearance.BorderSize = 1
    $button.Location = New-Object System.Drawing.Point($Left, 197)
    $button.Size = New-Object System.Drawing.Size(68, 29)
    $button.AccessibleName = "Chọn nhanh $Text"
    $button.Add_MouseEnter({ param($sender, $eventArgs); if (-not $script:isBusy) { $sender.BackColor = $cQuickHover } })
    $button.Add_MouseLeave({ param($sender, $eventArgs); $sender.BackColor = $cQuick })
    $card.Controls.Add($button)
    return $button
}

$quick15 = New-QuickButton -Text '15 phút' -Left 104
$quick30 = New-QuickButton -Text '30 phút' -Left 180
$quick60 = New-QuickButton -Text '1 giờ' -Left 256
$quick120 = New-QuickButton -Text '2 giờ' -Left 332
$quickButtons = @($quick15, $quick30, $quick60, $quick120)
for ($index = 0; $index -lt $quickButtons.Count; $index++) {
    $quickButtons[$index].TabIndex = $index + 2
}

$quick15.Add_Click({ if (-not $script:isBusy) { $number.Value = 15; $unit.SelectedIndex = 0 } })
$quick30.Add_Click({ if (-not $script:isBusy) { $number.Value = 30; $unit.SelectedIndex = 0 } })
$quick60.Add_Click({ if (-not $script:isBusy) { $number.Value = 1; $unit.SelectedIndex = 1 } })
$quick120.Add_Click({ if (-not $script:isBusy) { $number.Value = 2; $unit.SelectedIndex = 1 } })

$startButton = New-Object System.Windows.Forms.Button
$startButton.Text = 'BẮT ĐẦU HẸN GIỜ'
$startButton.Font = $fontSemibold
$startButton.BackColor = $cPink
$startButton.ForeColor = [System.Drawing.Color]::White
$startButton.FlatStyle = 'Flat'
$startButton.FlatAppearance.BorderSize = 0
$startButton.Cursor = [System.Windows.Forms.Cursors]::Hand
$startButton.Location = New-Object System.Drawing.Point(28, 242)
$startButton.Size = New-Object System.Drawing.Size(252, 44)
$startButton.AccessibleName = 'Bắt đầu hẹn giờ tắt máy'
$startButton.TabIndex = 6
$card.Controls.Add($startButton)

$cancelButton = New-Object System.Windows.Forms.Button
$cancelButton.Text = 'HỦY LỊCH'
$cancelButton.Font = $fontSemibold
$cancelButton.BackColor = $cCancel
$cancelButton.ForeColor = $cError
$cancelButton.FlatStyle = 'Flat'
$cancelButton.FlatAppearance.BorderColor = $cBorder
$cancelButton.FlatAppearance.BorderSize = 1
$cancelButton.Cursor = [System.Windows.Forms.Cursors]::Hand
$cancelButton.Location = New-Object System.Drawing.Point(290, 242)
$cancelButton.Size = New-Object System.Drawing.Size(120, 44)
$cancelButton.AccessibleName = 'Hủy lịch tắt máy đang chờ'
$cancelButton.TabIndex = 7
$card.Controls.Add($cancelButton)

$startButton.Add_MouseEnter({ param($sender, $eventArgs); if (-not $script:isBusy) { $sender.BackColor = $cPinkHover } })
$startButton.Add_MouseLeave({ param($sender, $eventArgs); $sender.BackColor = $cPink })
$cancelButton.Add_MouseEnter({ param($sender, $eventArgs); if (-not $script:isBusy) { $sender.BackColor = $cCancelHover } })
$cancelButton.Add_MouseLeave({ param($sender, $eventArgs); $sender.BackColor = $cCancel })

$statusBox = New-Object System.Windows.Forms.Panel
$statusBox.Location = New-Object System.Drawing.Point(28, 305)
$statusBox.Size = New-Object System.Drawing.Size(382, 83)
$statusBox.BackColor = [System.Drawing.Color]::FromArgb(255, 255, 250, 244)
$statusBox.BorderStyle = 'FixedSingle'
$card.Controls.Add($statusBox)

$statusIcon = New-Object System.Windows.Forms.Label
$statusIcon.Text = '🐱'
$statusIcon.Font = $fontCat
$statusIcon.ForeColor = $cPink
$statusIcon.TextAlign = 'MiddleCenter'
$statusIcon.Location = New-Object System.Drawing.Point(10, 15)
$statusIcon.Size = New-Object System.Drawing.Size(45, 45)
$statusBox.Controls.Add($statusIcon)

$status = New-Object System.Windows.Forms.Label
$status.Text = 'Chưa có lịch tắt máy. Mèo con đang chờ lệnh.'
$status.Font = $fontRegular
$status.ForeColor = $cMuted
$status.TextAlign = 'MiddleLeft'
$status.Location = New-Object System.Drawing.Point(62, 12)
$status.Size = New-Object System.Drawing.Size(305, 56)
$status.AccessibleName = 'Trạng thái hẹn giờ'
$statusBox.Controls.Add($status)

$footer = New-Object System.Windows.Forms.Label
$footer.Text = 'Lịch vẫn hoạt động sau khi bạn đóng cửa sổ.'
$footer.Font = $fontSmall
$footer.ForeColor = $cMuted
$footer.TextAlign = 'MiddleCenter'
$footer.Location = New-Object System.Drawing.Point(28, 398)
$footer.Size = New-Object System.Drawing.Size(382, 20)
$card.Controls.Add($footer)

function Set-Status {
    param(
        [Parameter(Mandatory = $true)] [string] $Icon,
        [Parameter(Mandatory = $true)] [string] $Message,
        [Parameter(Mandatory = $true)] [System.Drawing.Color] $Color
    )

    $statusIcon.Text = $Icon
    $statusIcon.ForeColor = $Color
    $status.Text = $Message
    $status.ForeColor = $Color
}

function Set-BusyUi {
    param([Parameter(Mandatory = $true)] [bool] $Busy)

    $script:isBusy = $Busy
    $form.UseWaitCursor = $Busy
    $number.Enabled = -not $Busy
    $unit.Enabled = -not $Busy
    $startButton.Enabled = -not $Busy
    $cancelButton.Enabled = -not $Busy
    foreach ($button in $quickButtons) {
        $button.Enabled = -not $Busy
    }
}

$operationTimer = New-Object System.Windows.Forms.Timer
$operationTimer.Interval = 100

function Clear-PendingOperation {
    $operationTimer.Stop()

    $process = $script:pendingProcess
    $script:pendingProcess = $null
    $script:pendingAction = $null
    $script:pendingReplacement = $false

    if ($script:operationStopwatch) {
        $script:operationStopwatch.Stop()
        $script:operationStopwatch = $null
    }

    if ($process) {
        $process.Dispose()
    }
}

function Complete-ShutdownFlowTerminal {
    param(
        [Parameter(Mandatory = $true)] [ValidateSet('Schedule', 'Abort')] [string] $Action,
        [Parameter(Mandatory = $true)] [int] $ExitCode,
        [Parameter(Mandatory = $true)] [bool] $WasReplacing,
        [Parameter(Mandatory = $true)] [ValidateSet('Succeeded', 'Finished', 'Failed')] [string] $Outcome
    )

    if ($Outcome -eq 'Failed') {
        if ($Action -eq 'Schedule') {
            Set-Status '😿' "Windows không tạo lịch mới (mã $ExitCode)." $cError
            [void][System.Windows.Forms.MessageBox]::Show(
                $form,
                "Windows không tạo được lịch tắt máy (mã $ExitCode).`nLịch cũ đã được hủy và lịch mới chưa được tạo. Hãy thử lại.",
                'Không thể hẹn giờ',
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            )
        }
        elseif ($WasReplacing) {
            Set-Status '😿' "Windows không hủy được lịch cũ (mã $ExitCode). Lịch mới chưa được tạo." $cError
            [void][System.Windows.Forms.MessageBox]::Show(
                $form,
                "Windows không hủy được lịch tắt máy cũ (mã $ExitCode).`nLịch tắt máy đang chờ vẫn còn hiệu lực và lịch mới chưa được tạo.",
                'Không thể đặt lại lịch',
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            )
        }
        else {
            Set-Status '😿' "Windows không hủy được lịch (mã $ExitCode)." $cError
            [void][System.Windows.Forms.MessageBox]::Show(
                $form,
                "Windows không hủy được lịch tắt máy (mã $ExitCode).",
                'Không thể hủy lịch',
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            )
        }
        return
    }

    if ($Action -eq 'Schedule') {
        $target = (Get-Date).AddSeconds($script:requestedSeconds)
        $targetText = $target.ToString('HH:mm - dd/MM/yyyy')
        Set-Status '😺' "Đã hẹn tắt máy lúc $targetText.`nBạn có thể đóng cửa sổ này." $cSuccess
        [void][System.Windows.Forms.MessageBox]::Show(
            $form,
            "Đã hẹn tắt máy lúc $targetText.`n`nĐến giờ, Windows sẽ đóng game và các ứng dụng đang chạy.",
            'Đã hẹn giờ',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
        return
    }

    if ($Outcome -eq 'Succeeded') {
        Set-Status '😸' 'Đã hủy lịch tắt máy đang chờ.' $cSuccess
        [void][System.Windows.Forms.MessageBox]::Show(
            $form,
            'Đã hủy lịch tắt máy đang chờ.',
            'Đã hủy lịch',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
    }
    else {
        Set-Status '🐱' 'Hiện không có lịch tắt máy nào để hủy.' $cMuted
        [void][System.Windows.Forms.MessageBox]::Show(
            $form,
            'Hiện không có lịch tắt máy nào để hủy.',
            'Không có lịch chờ',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
    }
}

function Complete-Operation {
    param([Parameter(Mandatory = $true)] [int] $ExitCode)

    $action = $script:pendingAction
    $wasReplacing = $script:pendingReplacement
    Clear-PendingOperation

    $setBusy = { param([bool] $Busy); Set-BusyUi $Busy }.GetNewClosure()
    $startSchedule = {
        param([Int64] $Seconds)
        Start-Operation -Action Schedule -Seconds $Seconds -StatusMessage 'Đang tạo lịch tắt máy mới…'
    }.GetNewClosure()
    $complete = {
        param($Transition)
        Complete-ShutdownFlowTerminal -Action $action -ExitCode $ExitCode -WasReplacing $wasReplacing -Outcome $Transition.Outcome
    }.GetNewClosure()

    [void](Invoke-ShutdownFlowTransition `
        -CompletedAction $action `
        -ExitCode $ExitCode `
        -IsReplacement $wasReplacing `
        -RequestedSeconds $script:requestedSeconds `
        -SetBusy $setBusy `
        -StartSchedule $startSchedule `
        -Complete $complete)
}

function Fail-PendingOperation {
    param([Parameter(Mandatory = $true)] [string] $Message)

    Clear-PendingOperation
    Set-BusyUi $false
    Set-Status '😿' $Message $cError
    [void][System.Windows.Forms.MessageBox]::Show(
        $form,
        $Message,
        'Lỗi chương trình',
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    )
}

$operationTimer.Add_Tick({
    try {
        if (-not $script:pendingProcess) {
            $operationTimer.Stop()
            return
        }

        if ($script:pendingProcess.HasExited) {
            $exitCode = $script:pendingProcess.ExitCode
            Complete-Operation -ExitCode $exitCode
            return
        }

        if ($script:operationStopwatch.ElapsedMilliseconds -ge 3000) {
            Fail-PendingOperation 'Không nhận được kết quả từ Windows trong 3 giây. Ứng dụng không hủy lệnh đang gửi; nếu cần, hãy mở lại và bấm HỦY LỊCH.'
        }
    }
    catch {
        Fail-PendingOperation "Không thể theo dõi lệnh hệ thống: $($_.Exception.Message)"
    }
})

function Start-Operation {
    param(
        [Parameter(Mandatory = $true)] [ValidateSet('Schedule', 'Abort')] [string] $Action,
        [Int64] $Seconds = 0,
        [string] $StatusMessage = 'Đang gửi lệnh tới Windows…'
    )

    Set-BusyUi $true
    Set-Status '🐾' $StatusMessage $cMuted
    $script:pendingAction = $Action

    try {
        $script:pendingProcess = Start-ShutdownCommand -Action $Action -Seconds $Seconds
        $script:operationStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $operationTimer.Start()
    }
    catch {
        Fail-PendingOperation "Không thể gửi lệnh tới Windows: $($_.Exception.Message)"
    }
}

function Start-ScheduleReplacement {
    param([Parameter(Mandatory = $true)] [Int64] $Seconds)

    $script:requestedSeconds = $Seconds
    $script:pendingReplacement = $true
    Start-Operation -Action Abort -StatusMessage 'Đang hủy lịch cũ để tạo lịch mới…'
}

$startButton.Add_Click({
    if ($script:isBusy) {
        return
    }

    try {
        $unitCode = if ($unit.SelectedIndex -eq 1) { 'Hours' } else { 'Minutes' }
        $seconds = ConvertTo-ShutdownSeconds -Amount $number.Value -Unit $unitCode
        $description = if ($unitCode -eq 'Hours') { "$($number.Value) giờ" } else { "$($number.Value) phút" }

        $confirmation = [System.Windows.Forms.MessageBox]::Show(
            $form,
            "Hẹn tắt máy sau $description?`n`nLịch tắt máy đang chờ hiện có (kể cả lịch do ứng dụng khác tạo) sẽ được thay thế bằng lịch mới.`nKhi đến giờ, Windows sẽ đóng game và ứng dụng đang chạy. Hãy chắc rằng bạn không có dữ liệu chưa lưu.",
            'Xác nhận hẹn giờ',
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Warning,
            [System.Windows.Forms.MessageBoxDefaultButton]::Button2
        )

        if ($confirmation -eq [System.Windows.Forms.DialogResult]::Yes) {
            Start-ScheduleReplacement -Seconds $seconds
        }
    }
    catch {
        $message = "Thời gian không hợp lệ: $($_.Exception.Message)"
        Set-Status '😿' $message $cError
        [void][System.Windows.Forms.MessageBox]::Show(
            $form,
            $message,
            'Thời gian không hợp lệ',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )
    }
})

$cancelButton.Add_Click({
    if (-not $script:isBusy) {
        $confirmation = [System.Windows.Forms.MessageBox]::Show(
            $form,
            'Hủy lịch tắt máy Windows đang chờ? Nếu lịch được tạo bởi ứng dụng khác, lịch đó cũng sẽ bị hủy.',
            'Xác nhận hủy lịch',
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Warning,
            [System.Windows.Forms.MessageBoxDefaultButton]::Button2
        )
        if ($confirmation -eq [System.Windows.Forms.DialogResult]::Yes) {
            Start-Operation -Action Abort
        }
    }
})

$form.Add_FormClosing({
    param($sender, $eventArgs)
    if ($script:isBusy) {
        $eventArgs.Cancel = $true
        [void][System.Windows.Forms.MessageBox]::Show(
            $form,
            'Đang chờ Windows xác nhận lệnh. Vui lòng thử đóng lại sau giây lát.',
            'Đang xử lý',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
    }
})

$form.Add_Shown({
    $number.Focus()
})

try {
    [System.Windows.Forms.Application]::Run($form)
}
finally {
    $operationTimer.Stop()
    $operationTimer.Dispose()
    if ($script:pendingProcess) {
        $script:pendingProcess.Dispose()
    }
    $form.Dispose()
    foreach ($font in $script:ownedFonts) {
        $font.Dispose()
    }
}
