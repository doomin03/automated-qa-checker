$ErrorActionPreference='Stop'
$repository=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$release=Join-Path $repository 'artifacts/releases/desktop-ai-alpha8/Release'
$executable=Join-Path $release 'automated_qa_desktop.exe'
$pin=Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $repository 'apps/app/engine-runtime-pin.json') | ConvertFrom-Json
$manifest=Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $repository 'artifacts/releases/desktop-ai-alpha8/manifest.json') | ConvertFrom-Json
Add-Type @'
using System;
using System.Text;
using System.Collections.Generic;
using System.Runtime.InteropServices;
public static class QaWindows {
 private delegate bool EnumWindowsCallback(IntPtr handle,IntPtr data);
 [DllImport("user32.dll")] static extern bool EnumWindows(EnumWindowsCallback callback,IntPtr data);
 [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr handle,out uint process);
 [DllImport("user32.dll",CharSet=CharSet.Unicode)] static extern int GetClassName(IntPtr handle,StringBuilder value,int length);
 public static string[] Classes(int process){var names=new List<string>();EnumWindows((handle,data)=>{uint owner;GetWindowThreadProcessId(handle,out owner);if(owner==process){var value=new StringBuilder(256);GetClassName(handle,value,256);names.Add(value.ToString());}return true;},IntPtr.Zero);return names.ToArray();}
}
'@
$child=Start-Process -FilePath $executable -WorkingDirectory $release -WindowStyle Hidden -PassThru
try {
 $classes=@()
 for($attempt=0;$attempt -lt 30;$attempt++) {
  Start-Sleep -Milliseconds 200
  $child.Refresh()
  if($child.HasExited){throw 'Release application exited during startup'}
  $classes=@([QaWindows]::Classes($child.Id))
  if($classes -contains 'FLUTTER_RUNNER_WIN32_WINDOW'){break}
 }
 if(!($classes -contains 'FLUTTER_RUNNER_WIN32_WINDOW')){throw 'Flutter native window was not initialized'}
 $record=@{engineVersion=$pin.engineVersion;executable=$executable;processAlive=$true;windowClasses=$classes;scope='Native Release process/window initialization; product interactions are covered by separate Windows integration_test and Provider tests';releaseManifest='artifacts/releases/desktop-ai-alpha8/manifest.json';releaseManifestSha256=$manifest.manifestSha256;timestamp=[DateTime]::UtcNow.ToString('o')}
 $record | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $repository 'artifacts/releases/desktop-ai-alpha8/launch.json') -Encoding UTF8
 Write-Output "Release native startup passed; complete Release manifest $($manifest.manifestSha256)"
} finally { $child.Refresh();if(!$child.HasExited){Stop-Process -Id $child.Id} }
