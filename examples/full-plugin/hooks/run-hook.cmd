: ; # polyglot wrapper -- CMD runs the top half, bash runs the bottom half
: ; # Usage: run-hook.cmd <script-name> [args...]
: ; exec bash "${CLAUDE_PLUGIN_ROOT}/hooks/$1.sh" "${@:2}" <&0 ; exit $?
@echo off
setlocal
set "SCRIPT=%CLAUDE_PLUGIN_ROOT%\hooks\%1.sh"
bash "%SCRIPT%" %2 %3 %4 %5 %6 %7 %8 %9
exit /b %ERRORLEVEL%
