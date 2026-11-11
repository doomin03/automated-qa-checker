# Windows redirected-parent fix

Upstream: flutter_pty2 3.0.0, MIT (LICENSE preserved).
Archive: https://pub.dev/api/archives/flutter_pty2-3.0.0.tar.gz
SHA256: 9802f793109fe7241cc172780571d501e50db6b247624a6b7c4df889bb9cbfe6

Only upstream code change: src/windows/pty_windows_spawn.c adds
`startup_info.StartupInfo.dwFlags |= STARTF_USESTDHANDLES;` after setting cb.
The zero-initialized hStdInput/hStdOutput/hStdError remain NULL. This prevents
redirected parent handles from replacing ConPTY handles. Parent handle state
and pub cache are not modified.

Reproduced before fix in Flutter tester and native Windows integration:
Node stdin.isTTY=false, no setRawMode, output outside PTY.
Regression: test/pty_native_test.dart and integration_test/pty_native_test.dart.

References:
- https://github.com/microsoft/terminal/discussions/15814
- https://github.com/microsoft/node-pty/blob/main/src/win/conpty.cc
- https://learn.microsoft.com/en-us/windows/console/getstdhandle

Manager approved this one-line patch on 2026-11-10. Replace the vendor only
after an upstream release passes the same Windows tests. Do not silently use
unpatched hosted 3.0.0. QA-PATCH.md is additional provenance, not upstream code.
