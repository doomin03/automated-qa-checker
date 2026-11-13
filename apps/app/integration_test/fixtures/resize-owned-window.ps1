param([int]$TargetProcessId, [string]$ExpectedExecutable, [int]$ClientWidth, [int]$ClientHeight)
$ErrorActionPreference = 'Stop'
$target = Get-Process -Id $TargetProcessId
if ($target.Path -ne $ExpectedExecutable -or $target.MainWindowHandle -eq 0) {
  throw 'The integration test window identity does not match.'
}
Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class TestWindow {
  [StructLayout(LayoutKind.Sequential)] public struct Rect { public int Left, Top, Right, Bottom; }
  [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out Rect r);
  [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr h, out Rect r);
  [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr h, IntPtr after, int x, int y, int w, int hgt, uint flags);
}
'@
[void][TestWindow]::SetProcessDPIAware()
$outer = New-Object TestWindow+Rect
$inner = New-Object TestWindow+Rect
if (![TestWindow]::GetWindowRect($target.MainWindowHandle, [ref]$outer) -or ![TestWindow]::GetClientRect($target.MainWindowHandle, [ref]$inner)) { throw 'Cannot read owned window geometry.' }
$borderWidth = ($outer.Right - $outer.Left) - ($inner.Right - $inner.Left)
$borderHeight = ($outer.Bottom - $outer.Top) - ($inner.Bottom - $inner.Top)
if (![TestWindow]::SetWindowPos($target.MainWindowHandle, [IntPtr]::Zero, 0, 0, $ClientWidth + $borderWidth, $ClientHeight + $borderHeight, 22)) { throw 'Cannot resize owned window.' }
[void][TestWindow]::GetClientRect($target.MainWindowHandle, [ref]$inner)
@{pid=$TargetProcessId; hwnd=$target.MainWindowHandle.ToInt64(); clientWidth=$inner.Right; clientHeight=$inner.Bottom; executable=$target.Path} | ConvertTo-Json -Compress
