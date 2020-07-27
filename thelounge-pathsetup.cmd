@ECHO OFF
(
    CALL "%~dp0.\thelounge-path-append.cmd" "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" 2> NUL
) || (
    CALL "%~dp0.\thelounge-path-append.cmd" "HKCU\Environment"
)
