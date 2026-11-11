$ErrorActionPreference='Stop'
$repository=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$output=Join-Path $repository 'artifacts/releases/desktop-xml-block-studio-alpha8'
$release=Join-Path $output 'Release'
$executable=Join-Path $release 'automated_qa_desktop.exe'
$manifest=Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $output 'manifest.json') | ConvertFrom-Json
$appData=Join-Path $repository 'artifacts/xml-block-studio/release-smoke-appdata'
New-Item -ItemType Directory -Force -Path $appData | Out-Null
Add-Type @'
using System;
using System.Text;
using System.Collections.Generic;
using System.Runtime.InteropServices;
public static class QaStudioWindows {
 private delegate bool Callback(IntPtr h,IntPtr d);
 [DllImport("user32.dll")] static extern bool EnumWindows(Callback c,IntPtr d);
 [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr h,out uint p);
 [DllImport("user32.dll",CharSet=CharSet.Unicode)] static extern int GetClassName(IntPtr h,StringBuilder v,int n);
 public static string[] Classes(int p){var a=new List<string>();EnumWindows((h,d)=>{uint owner;GetWindowThreadProcessId(h,out owner);if(owner==p){var v=new StringBuilder(256);GetClassName(h,v,256);a.Add(v.ToString());}return true;},IntPtr.Zero);return a.ToArray();}
}
'@
$start=[Diagnostics.ProcessStartInfo]::new($executable)
$start.WorkingDirectory=$release
$start.UseShellExecute=$false
$start.WindowStyle=[Diagnostics.ProcessWindowStyle]::Hidden
$start.EnvironmentVariables['APPDATA']=$appData
$child=[Diagnostics.Process]::Start($start)
try {
 $classes=@()
 for($attempt=0;$attempt -lt 50;$attempt++) {
  Start-Sleep -Milliseconds 200
  $child.Refresh()
  if($child.HasExited){throw 'New Release exited during startup'}
  $classes=@([QaStudioWindows]::Classes($child.Id))
  if($classes -contains 'FLUTTER_RUNNER_WIN32_WINDOW'){break}
 }
 if(!($classes -contains 'FLUTTER_RUNNER_WIN32_WINDOW')){throw 'Flutter native window was not initialized'}
 @{engineVersion=$manifest.engineVersion;executable=$executable;processAlive=$true;windowClasses=$classes;isolatedAppData=$appData;scope='New Release native startup only; actual Engine runs and picker interactions are separate evidence';releaseManifest='artifacts/releases/desktop-xml-block-studio-alpha8/manifest.json';releaseManifestSha256=$manifest.manifestSha256;timestamp=[DateTime]::UtcNow.ToString('o')} | ConvertTo-Json -Depth 8 | Set-Content -Encoding UTF8 -LiteralPath (Join-Path $output 'launch.json')
 Write-Output "New studio Release startup passed: $($manifest.manifestSha256)"
} finally { $child.Refresh();if(!$child.HasExited){Stop-Process -Id $child.Id} }
