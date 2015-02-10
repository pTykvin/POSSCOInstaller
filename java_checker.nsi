;Библиотеки
  !include LogicLib.nsh
;--------------------------------

;ДЕКЛАРИРОВАНИЕ
  ;Константы
    !define ShortName "SCO"
    !define AppVersion "1.0"
    !define JRE_VERSION "1.7"
    !define Vendor "CrystalService"
    !define AppName "SetRetail10_SCO"    
  ;--------------------------------

  ;Служебные константы и переменные
    !define N "$\r$\n"
    !define MakePGInstall `!insertmacro MakePGInstall`
  ;--------------------------------
;================================


;МАКРОСЫ И ФУНКЦИИ
  ;Макрос, генерирующий командный файл для тихой установки постгреса
  !macro MakePGInstall
    FileOpen $4 "$TEMP\pgsql\install.cmd" w  
    FileWrite $4 "@echo off${N}"
    FileWrite $4 "echo Silence install PostgreSQL in progress...${N}"
    FileWrite $4 'postgresql.exe --unattendedmodeui minimal --mode unattended --superpassword "postgres" --servicename "postgreSQL" --servicepassword "postgres --serverport 5432${N}'
    FileWrite $4 "echo Silence install PostgreSQL ready."  
  !macroend
  ;--------------------------------
;================================


;КОНФИГУРАЦИИ
  ;Конфигурация инсталлятора
    Name "${AppName}"
    InstallDir "$PROGRAMFILES/"
    OutFile "${ShortName}_v${AppVersion}_setup.exe"
    InstallDirRegKey HKLM "SOFTWARE\${Vendor}\${ShortName}" ""
    ShowInstDetails show
  ;--------------------------------

  ;Конфигурация списка этапов инсталляции/деинсталляции
    Page components
    Page instfiles
    UninstPage uninstConfirm
    UninstPage instfiles
  ;--------------------------------
;================================


;СЕКЦИИ
  ;Секция установки POS SCO
    Section "!SCO"
      DetailPrint "Extract POS SCO v${AppVersion}"
      ;TODO: раскомментарить перед продакшеном
      ;SectionIn RO
      SetOutPath "$INSTDIR\${Vendor}\${AppName}"
      DetailPrint "Extract coplete"
    SectionEnd
  ;--------------------------------

  ;Секция установки JRE 1.7
    Section "Java 1.7"    
      ;TODO: раскомментарить перед продакшеном
      ;SectionIn RO
      DetailPrint "Extract jre1.7 for POS SCO"
      SetOutPath "$INSTDIR\${Vendor}\${AppName}"
      File /r jre
      DetailPrint "Extract coplete"
    SectionEnd
  ;--------------------------------

  ;Секция установки PostgreSQL
    Section "PostgreSQL"
      DetailPrint "Install postgresql"
      SetOutPath "$TEMP\pgsql"
      File postgresql.exe
      !insertmacro MakePGInstall
      ExecDos::exec /DETAILED "$TEMP\pgsql\install.cmd" "" ""
      DetailPrint "PostgreSQL installation finished."
    SectionEnd
  ;--------------------------------
;================================
