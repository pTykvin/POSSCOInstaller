; Credit given to so many people of the NSIS forum.
 
!define JRE_VERSION "1.4.1"
 
!include "MUI.nsh"
!include "Sections.nsh"
 
!define TEMP $R0
!define TEMP2 $R1
!define VAL1 $R2
!define VAL2 $R3
 
!define DOWNLOAD_JRE_FLAG $8
 
; define your own download path
!define JRE_URL "<path to a jre install>/jre.exe"
 
;--------------------------------
;Configuration
 
  ;General
  Name "JRE Test"
  OutFile "jretest.exe"
 
  ;Folder selection page
  InstallDir "$PROGRAMFILES\JRE Test"
 
  ;Get install folder from registry if available
  InstallDirRegKey HKLM "SOFTWARE\JRE Test" ""
 
;--------------------------------
;Pages
 
  Page custom CheckInstalledJRE
  !insertmacro MUI_PAGE_INSTFILES
  !define MUI_PAGE_CUSTOMFUNCTION_PRE myPreInstfiles
  !define MUI_PAGE_CUSTOMFUNCTION_LEAVE RestoreSections
  !insertmacro MUI_PAGE_DIRECTORY
  !insertmacro MUI_PAGE_INSTFILES
 
  !insertmacro MUI_UNPAGE_CONFIRM
  !insertmacro MUI_UNPAGE_INSTFILES
 
;--------------------------------
;Modern UI Configuration
 
  !define MUI_ABORTWARNING
 
;--------------------------------
;Languages
 
  !insertmacro MUI_LANGUAGE "English"
 
;--------------------------------
;Language Strings
 
  ;Description
  LangString DESC_SecJRETest ${LANG_ENGLISH} "Application files copy"
 
  ;Header
  LangString TEXT_JRE_TITLE ${LANG_ENGLISH} "Java Runtime Environment"
  LangString TEXT_JRE_SUBTITLE ${LANG_ENGLISH} "Installation"
  LangString TEXT_PRODVER_TITLE ${LANG_ENGLISH} \
"Installed version of JRE Test"
  LangString TEXT_PRODVER_SUBTITLE ${LANG_ENGLISH} "Installation cancelled"
 
;--------------------------------
;Reserve Files
 
  ;Only useful for BZIP2 compression
 
  ;ReserveFile "jre.ini"
  ;!insertmacro MUI_RESERVEFILE_INSTALLOPTIONS
 
;--------------------------------
;Installer Sections
 
Section -installjre jre
  DetailPrint "Starting the JRE installation"
  !ifdef WEB_INSTALL
    DetailPrint "Downloading the JRE setup"
    NSISdl::download /TIMEOUT=30000 ${JRE_URL} "$TEMP\jre_setup.exe"
    Pop $0 ;Get the return value
    StrCmp $0 "success" InstallJRE 0
    StrCmp $0 "cancel" 0 +3
    Push "Download cancelled."
    Goto ExitInstallJRE
    Push "Unkown error during download."
    Goto ExitInstallJRE
  !else
    File /oname=$TEMP\jre_setup.exe j2re-setup.exe
  !endif
InstallJRE:
  DetailPrint "Launching JRE setup"
  ExecWait "$TEMP\jre_setup.exe" $0
  DetailPrint "Setup finished"
  Delete "$TEMP\jre_setup.exe"
  StrCmp $0 "0" InstallVerif 0
  Push "The JRE setup has been abnormally interrupted."
  Goto ExitInstallJRE
 
InstallVerif:
  DetailPrint "Checking the JRE Setup's outcome"
  Call DetectJRE
  Pop $0
  StrCmp $0 "OK" JavaExeVerif 0
  Push "The JRE setup failed"
  Goto ExitInstallJRE
 
JavaExeVerif:
  Pop $1
  IfFileExists $1 JREPathStorage 0
  Push "The following file : $1, cannot be found."
  Goto ExitInstallJRE
 
JREPathStorage:
  !insertmacro MUI_INSTALLOPTIONS_WRITE "jre.ini" \
"UserDefinedSection" "JREPath" $1
  Goto End
 
ExitInstallJRE:
  Pop $2
  MessageBox MB_OK "The setup is about to be interrupted for the following reason : $2"
  Quit
End:
 
SectionEnd
 
Section /o "Installation of JRE Test" SecJRETest
 
  SetOutPath $INSTDIR
  File /r "installDir\*"
 
  !insertmacro MUI_INSTALLOPTIONS_READ $0 "jre.ini" "UserDefinedSection" "JREPath"
  ;Store install folder
  WriteRegStr HKLM "SOFTWARE\JRE Test" "" $INSTDIR
 
  WriteRegStr HKLM \
"Software\Microsoft\Windows\CurrentVersion\Uninstall\JRE Test" \
"DisplayName" "JRE Test"
  WriteRegStr HKLM \
"Software\Microsoft\Windows\CurrentVersion\Uninstall\JRE Test" \
"UninstallString" '"$INSTDIR\uninstall.exe"'
  WriteRegDWORD HKLM \
"Software\Microsoft\Windows\CurrentVersion\Uninstall\JRE Test" \
"NoModify" "1"
  WriteRegDWORD HKLM \
"Software\Microsoft\Windows\CurrentVersion\Uninstall\JRE Test" \
"NoRepair" "1"
 
  ;Create uninstaller
  WriteUninstaller "$INSTDIR\Uninstall.exe"
 
SectionEnd
 
Section /o "Start menu shortcuts" SecCreateShortcut
 
  CreateDirectory "$SMPROGRAMS\JRE Test"
  CreateShortCut "$SMPROGRAMS\JRE Test\Uninstall.lnk" \
"$INSTDIR\uninstall.exe" "" "$INSTDIR\uninstall.exe" 0
  CreateShortCut "$SMPROGRAMS\JRE Test\JRE Test.lnk" \
"$INSTDIR\jretext.exe" "" "$INSTDIR\jretest.exe" 0
 
SectionEnd
 
;--------------------------------
;Descriptions
 
!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
  !insertmacro MUI_DESCRIPTION_TEXT ${SecJRETest} $(DESC_SecJRETest)
!insertmacro MUI_FUNCTION_DESCRIPTION_END
 
;--------------------------------
;Installer Functions
 
Function .onInit
 
  ;Extract InstallOptions INI Files
  !insertmacro MUI_INSTALLOPTIONS_EXTRACT "jre.ini"
  Call SetupSections
 
FunctionEnd
 
Function myPreInstfiles
 
  Call RestoreSections
  SetAutoClose true
 
FunctionEnd
 
FunctionEnd
 
Function CheckInstalledJRE
  Call DetectJRE
  Pop ${TEMP}
  StrCmp ${TEMP} "OK" NoDownloadJRE
  Pop ${TEMP2}
  StrCmp ${TEMP2} "None" NoFound FoundOld
 
FoundOld:
  !insertmacro MUI_INSTALLOPTIONS_WRITE "jre.ini" "Field 1" "Text" "JRE Test requires a more recent version of the Java Runtime Environment \
than the one found on your computer. \
The installation of JRE \
${JRE_VERSION} will start."
  !insertmacro MUI_HEADER_TEXT "$(TEXT_JRE_TITLE)" "$(TEXT_JRE_SUBTITLE)"
  !insertmacro MUI_INSTALLOPTIONS_DISPLAY_RETURN "jre.ini"
  Goto DownloadJRE
 
NoFound:
  !insertmacro MUI_INSTALLOPTIONS_WRITE "jre.ini" "Field 1" "Text" "No Java Runtime Environment could be found on your computer \
The installation of JRE v${JRE_VERSION} will start."
  !insertmacro MUI_HEADER_TEXT "$(TEXT_JRE_TITLE)" "$(TEXT_JRE_SUBTITLE)"
  !insertmacro MUI_INSTALLOPTIONS_DISPLAY "jre.ini"
  Goto DownloadJRE
 
DownloadJRE:
  StrCpy ${DOWNLOAD_JRE_FLAG} "Download"
  Return
 
NoDownloadJRE:
  Pop ${TEMP2}
  StrCpy ${DOWNLOAD_JRE_FLAG} "NoDownload"
  !insertmacro MUI_INSTALLOPTIONS_WRITE "jre.ini" \
"UserDefinedSection" "JREPath" \
${TEMP2}
  Return
 
ExitInstall:
  Quit
 
FunctionEnd
 
 
Function DetectJRE
  ReadRegStr ${TEMP2} HKLM "SOFTWARE\JavaSoft\Java Runtime Environment" \
"CurrentVersion"
  StrCmp ${TEMP2} "" DetectTry2
  ReadRegStr ${TEMP3} HKLM \
"SOFTWARE\JavaSoft\Java Runtime Environment\${TEMP2}" "JavaHome"
  StrCmp ${TEMP3} "" DetectTry2
  Goto GetJRE
 
DetectTry2:
  ReadRegStr ${TEMP2} HKLM "SOFTWARE\JavaSoft\Java Development Kit" \
"CurrentVersion"
  StrCmp ${TEMP2} "" NoFound
  ReadRegStr ${TEMP3} HKLM \
"SOFTWARE\JavaSoft\Java Development Kit\${TEMP2}" "JavaHome"
  StrCmp ${TEMP3} "" NoFound
 
GetJRE:
  IfFileExists "${TEMP3}\bin\java.exe" 0 NoFound
  StrCpy ${VAL1} ${TEMP2} 1
  StrCpy ${VAL2} ${JRE_VERSION} 1
  IntCmp ${VAL1} ${VAL2} 0 FoundOld FoundNew
  StrCpy ${VAL1} ${TEMP2} 1 2
  StrCpy ${VAL2} ${JRE_VERSION} 1 2
  IntCmp ${VAL1} ${VAL2} FoundNew FoundOld FoundNew
 
NoFound:
  Push "None"
  Push "NOK"
  Return
 
FoundOld:
  Push ${TEMP2}
  Push "NOK"
  Return
 
FoundNew:
  Push "${TEMP3}\bin\java.exe"
  Push "OK"
  Return
 
FunctionEnd
 
Function RestoreSections
  !insertmacro UnselectSection ${jre}
  !insertmacro SelectSection ${SecJRETest}
  !insertmacro SelectSection ${SecCreateShortcut}
 
FunctionEnd
 
Function SetupSections
  !insertmacro SelectSection ${jre}
  !insertmacro UnselectSection ${SecJRETest}
  !insertmacro UnselectSection ${SecCreateShortcut}
FunctionEnd
 
;--------------------------------
;Uninstaller Section
 
Section "Uninstall"
 
  ; remove registry keys
  DeleteRegKey HKLM \
"Software\Microsoft\Windows\CurrentVersion\Uninstall\JRE Test"
  DeleteRegKey HKLM  "SOFTWARE\JRE Test"
  ; remove shortcuts, if any.
  Delete "$SMPROGRAMS\JRE Test\*.*"
  ; remove files
  RMDir /r "$INSTDIR"
 
SectionEnd