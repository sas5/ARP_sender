@ECHO OFF
SETLOCAL EnableExtensions DisableDelayedExpansion
for /F %%a in ('echo prompt $E ^| cmd') do (
  set "ESC=%%a"
)
SETLOCAL EnableDelayedExpansion
if exist arp.list ( del /Q /F arp.list )
if exist Done.tmp ( del /Q /F Done.tmp )
if not "%1" == "" goto :%1 

(set \n=^
%
)
set /A "i=0"
set "alignspace=                                            "


for /F "tokens=1,2 delims=:" %%a IN ('ipconfig') do ( 
   set "_tmp=%%~a"
   if "!_tmp:adapter=!"=="!_tmp!" (
        if not "!_tmp:IPv4 Address=!"=="!_tmp!" (   
            set /A "i=!i!+1"
            set "_ip=%%~b!alignspace!"
            set "align=!adapter!!alignspace!"
            set "count=!i!!alignspace!"
            echo.[ %ESC%[33m!count:~,2!%ESC%[0m ] %ESC%[94m!align:~,20!%ESC%[0m -^> [ %ESC%[96m!_ip:~1,16!%ESC%[0m^] [ %ESC%[92mConnected%ESC%[0m ]
        ) 
    ) else (
        set "_ip="
        set "adapter=!_tmp:*adapter =!" 
    )
)
set "_choice="
echo !\n!Choose on of these adabpters [1-!i!]:
set /p "_choice=-> "
call :INFO
mkdir "%temp%/arp" > nul 2>&1
timeout /t 1 > nul
call :CreateCR
set /A "i=0"
start /b %~nx0 scan

:check
    if exist Done.tmp (
        echo.
        timeout /t 4 > nul
        FOR /R "%temp%/arp" %%a IN (*.arp) DO type %%a >> arp.list
        del /Q /F "%temp%/arp"
        del /Q /F Done.tmp
        set /A "i=0"
        echo.!\n!%ESC%[36m___________^(Current Devices in this Network^)__________________%ESC%[0m!\n!!\n!
        FOR /F "tokens=1,2* delims=-" %%a in (arp.list) do (
            set /A "i+=1"
            echo [ %ESC%[33m!i!!alignspace:~,3!%ESC%[0m]  %ESC%[93m%%a!alignspace:~,4! %ESC%[0m- [%ESC%[32m%%b%ESC%[0m ]
        )

        echo.!\n!______________________________________________________________!\n!!\n!
        echo %ESC%[36mAll This Data Will Be Saved To [arp.list] In Same Path%ESC%[0m
        echo %ESC%[31mClick Enter 2 Times To Exit%ESC%[0m
        endlocal
        pause > nul
        exit /b
    )
    goto :check


:scan
    set /A i=i+1
    START /B CMD /C CALL "arpS.exe" %Myip% %range%%i% > "%temp%/arp/%i%.arp"
    set /p="%ESC%[93m SCANNING: %ESC%[91m%range%%ESC%[92m%i%  %ESC%[0m!alignspace:~,6!Time: [%ESC%[95m!TIME!%ESC%[0m ]!CR!" < nul
    if %i%==254 type nul>Done.tmp & pause > nul & exit  
    ping localhost -n 1 -w 500 > nul
    goto :scan

:Help 
    echo %0 IP of Router or your Device
    echo Exit
    exit /b

:INFO
    if NOT "!_choice!"=="" (
        if !_choice! LEQ !i! (
            call :adapter_info !_choice!
            echo.!Myip! | findstr /r "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*" > nul 2>&1 || echo Can't resolve !Myip! && exit /b
            FOR /F "tokens=1,2,3,4 delims=." %%a IN ('echo !Myip!') DO ( set "range=%%a.%%b.%%c." )
            exit /b
        ) 
    )
    set "_choice="
    echo %ESC%[91mError.%ESC%[0m
    set /p "_choice=-> "
    goto :INFO

:adapter_info
    set /A "G=0"
    set /A "i=0"
    for /F "tokens=1,2 delims=:" %%a IN ('ipconfig') do ( 
            set "_tmp=%%~a"
            if "!_tmp:adapter=!"=="!_tmp!" (
                if not "!_tmp:IPv4 Address=!"=="!_tmp!" (   
                    set /A "i=!i!+1"
                    if "!i!"=="%~1" (
                        set "_ip=%%~b"
                        set "Niface=!G!"
                        echo.______________________________________________________________
                        call :GET_INFO
                        echo.______________________________________________________________
                        echo.
                        exit /b
                    )
                ) 
            ) else (
                set "_ip="
                set "adapter=!_tmp:*adapter =!"
                set /A "G=!G!+1"
            )   

    )

:CreateCR
    set "X=."
    for /L %%c in (1,1,13) DO set X=!X:~0,4094!!X:~0,4094!
    echo !X!  > %temp%\cr.tmp
    echo\>> %temp%\cr.tmp
    for /f "tokens=2 usebackq" %%a in ("%temp%\cr.tmp") do (
        endlocal
        set cr=%%a
        exit /b
    )
    exit /b


:GET_INFO
    @REM set "Myip=%~1"
    set /A "G=0"
    echo.!\n!%ESC%[93mCurrent adapter: %ESC%[96m!adapter!%ESC%[0m !\n!
    for /F "tokens=1,2 delims=:" %%a IN ('ipconfig /all') do ( 
        set "_tmp=%%~a"
        if "!_tmp:adapter=!"=="!_tmp!" (
            if "!G!"=="!Niface!" (
                if NOT "%%~b"==" " (
                    set "_result=%%~b"
                    set "_result=!_result:~1!"
                    echo !_tmp! | findstr /C:"Physical Address" > nul 2>&1 && set "MacAddress=!_result!"
                    echo !_tmp! | findstr /C:"Default Gateway" > nul 2>&1 && set "Gateway=!_result!"
                    echo !_result! | findstr /C:"!_ip:~1!"> nul 2>&1 && set "Myip=!_ip:~1!"
                    echo !_tmp! | findstr /C:"DNS Servers" > nul 2>&1 && exit /b || echo %ESC%[33m!_tmp:.= ! %ESC%[94m!_result:^(Preferred^)=^ ^%ESC%[93m^<-- ^( My ip ^)!%ESC%[0m
                )
            )
        ) else (
            set "adapter=!_tmp:*adapter =!"
            set /A "G=!G!+1"
            if !G! GTR Niface exit /b
        )
    )
