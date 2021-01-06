; -------------------------------
; Start
 
  Name "Graylog Sidecar"
  !define MUI_FILE "savefile"
  !define MUI_BRANDINGTEXT "Graylog Sidecar v${VERSION}${VERSION_SUFFIX}"
  CRCCheck On
  SetCompressor "bzip2"
 
  !include "${NSISDIR}\Contrib\Modern UI\System.nsh"
  !include nsDialogs.nsh
  !include LogicLib.nsh
  !include StrRep.nsh
  !include ReplaceInFile.nsh
  !include Common.nsh
  !include FileFunc.nsh
  !include WordFunc.nsh
  !include x64.nsh
  !include IfKeyExists.nsh

  VIProductVersion "${VERSION}.${REVISION}" ;Required format is X.X.X.X
  VIAddVersionKey "FileVersion" "${VERSION}"
  VIAddVersionKey "FileDescription" "Graylog Sidecar Installer"
  VIAddVersionKey "ProductName" "Graylog Sidecar"
  VIAddVersionKey "ProductVersion" "${VERSION}${VERSION_SUFFIX}"
  VIAddVersionKey "LegalCopyright" "Graylog, Inc."
 
;---------------------------------
;General

  !searchreplace SUFFIX '${VERSION_SUFFIX}' "-" "."
  OutFile "pkg/graylog_sidecar_installer_${VERSION}-${REVISION}${SUFFIX}.exe"
  RequestExecutionLevel admin ;Require admin rights
  ShowInstDetails "nevershow"
  ShowUninstDetails "nevershow"

  ; Variables
  Var Params
  Var ParamServerUrl
  Var InputServerUrl
  Var ServerUrl
  Var ParamNodeName
  Var InputNodeName
  Var InputApiToken
  Var NodeName
  Var ApiToken
  Var ParamUpdateInterval
  Var UpdateInterval
  Var ParamTlsSkipVerify
  Var TlsSkipVerify
  Var ParamSendStatus
  Var ParamApiToken
  Var SendStatus
  Var Dialog
  Var Label
  Var GraylogDir


;--------------------------------
;Modern UI Configuration  
  
  !define MUI_ICON "graylog.ico"  
  !insertmacro MUI_PAGE_WELCOME
  !insertmacro MUI_PAGE_LICENSE  "../LICENSE"
  !insertmacro MUI_UNPAGE_WELCOME
  !insertmacro MUI_UNPAGE_CONFIRM
  !insertmacro MUI_UNPAGE_INSTFILES

  
  ; Custom Pages
  Page custom nsDialogsPage nsDialogsPageLeave
  Page instfiles

  !insertmacro MUI_PAGE_FINISH
  !insertmacro MUI_UNPAGE_FINISH
  !define MUI_DIRECTORYPAGE
  !define MUI_ABORTWARNING
 
;--------------------------------
;Macros
 
  !insertmacro MUI_LANGUAGE "English"
  !insertmacro WordFind
  !insertmacro WordFind2X

  !macro Check_X64
    ${If} ${RunningX64}
      SetRegView 64
      Strcpy $GraylogDir "$PROGRAMFILES64\Graylog"
    ${Else}
      SetRegView 32
      Strcpy $GraylogDir "$PROGRAMFILES32\Graylog"
    ${EndIf}
    Strcpy $INSTDIR "$GraylogDir\sidecar"
  !macroend

;--------------------------------
;Data
 
  LicenseData "../LICENSE"

;-------------------------------- 
;Installer Sections     
Section "Install"

  ;These folders are needed at runtime
  CreateDirectory "$INSTDIR\generated"
  CreateDirectory "$INSTDIR\logs"
  SetOutPath "$INSTDIR"
 
  ${If} ${RunningX64}
    File "collectors/winlogbeat/windows/x86_64/winlogbeat.exe"
    File "collectors/filebeat/windows/x86_64/filebeat.exe"
  ${Else}
    File "collectors/winlogbeat/windows/x86/winlogbeat.exe"
    File "collectors/filebeat/windows/x86/filebeat.exe"
  ${EndIf}

  SetOverwrite off
  File /oname=sidecar.yml "../sidecar-windows-example.yml"
  SetOverwrite on
  File /oname=sidecar.yml.dist "../sidecar-windows-example.yml"
  File "../LICENSE"
  File "graylog.ico"  

  ;Stop service to allow binary upgrade
  !insertmacro _IfKeyExists HKLM "SYSTEM\CurrentControlSet\Services" "graylog-sidecar"
  Pop $R0
  ${If} $R0 = 1
    ExecWait '"$INSTDIR\graylog-sidecar.exe" -service stop'
  ${EndIf}

  ${If} ${RunningX64}
    File /oname=graylog-sidecar.exe "../build/${VERSION}/windows/amd64/graylog-sidecar.exe"
  ${Else}
    File /oname=graylog-sidecar.exe "../build/${VERSION}/windows/386/graylog-sidecar.exe"
  ${EndIf}

  ;When we stop the Sidecar service we also turn it on again
  ${If} $R0 = 1
    ExecWait '"$INSTDIR\graylog-sidecar.exe" -service start'
  ${EndIf}

  WriteUninstaller "$INSTDIR\uninstall.exe"

  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\GraylogSidecar" \
                 "DisplayName" "Graylog Sidecar"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\GraylogSidecar" \
                 "UninstallString" "$\"$INSTDIR\uninstall.exe$\""
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\GraylogSidecar" \
                 "DisplayIcon" "$\"$INSTDIR\graylog.ico$\""				 
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\GraylogSidecar" \
                 "QuietUninstallString" "$\"$INSTDIR\uninstall.exe$\" /S"				 
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\GraylogSidecar" \
                 "DisplayVersion" "${VERSION}${VERSION_SUFFIX}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\GraylogSidecar" \
                 "InstallLocation" "$INSTDIR"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\GraylogSidecar" \
                 "RegCompany" "Graylog, Inc."
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\GraylogSidecar" \
                 "Publisher" "Graylog, Inc."
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\GraylogSidecar" \
                 "HelpLink" "https://www.graylog.org"
				 
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\GraylogSidecar" \
                 "NoModify" "1"
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\GraylogSidecar" \
                 "NoRepair" "1"				 
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\GraylogSidecar" \
                 "EstimatedSize" "25000"


SectionEnd
 
Section "Post"

  ; Parse command line options
  ; The first character in the option string is treated as a parameter delimiter, so we prepend a white-space
  ; to allow options like -NODENAME=my-collector (second dash would interrupt option parsing otherwise)
  ${GetParameters} $Params
  ${GetOptions} $Params " -SERVERURL=" $ParamServerUrl
  ${GetOptions} $Params " -NODENAME=" $ParamNodeName
  ${GetOptions} $Params " -UPDATE_INTERVAL=" $ParamUpdateInterval
  ${GetOptions} $Params " -TLS_SKIP_VERIFY=" $ParamTlsSkipVerify
  ${GetOptions} $Params " -SEND_STATUS=" $ParamSendStatus
  ${GetOptions} $Params " -APITOKEN=" $ParamApiToken

  ${If} $ParamServerUrl != ""
    StrCpy $ServerUrl $ParamServerUrl
  ${EndIf}
  ${If} $ParamNodeName != ""
    StrCpy $NodeName $ParamNodeName
  ${EndIf}
  ${If} $ParamUpdateInterval != ""
    StrCpy $UpdateInterval $ParamUpdateInterval
  ${EndIf}
  ${If} $ParamTlsSkipVerify != ""
    StrCpy $TlsSkipVerify $ParamTlsSkipVerify
  ${EndIf}
  ${If} $ParamSendStatus != ""
    StrCpy $SendStatus $ParamSendStatus
  ${EndIf}
  ${If} $ParamApiToken != ""
    StrCpy $ApiToken $ParamApiToken
  ${EndIf}

  ; set defaults
  ${If} $ServerUrl == ""
    StrCpy $ServerUrl "http://127.0.0.1:9000/api"
  ${EndIf}
  ${If} $UpdateInterval == ""
    StrCpy $UpdateInterval "10"
  ${EndIf}
  ${If} $TlsSkipVerify == ""
    StrCpy $TlsSkipVerify "false"
  ${EndIf}
  ${If} $SendStatus == ""
    StrCpy $SendStatus "true"
  ${EndIf}

  !insertmacro _ReplaceInFile "$INSTDIR\sidecar.yml" "<SERVERURL>" $ServerUrl
  !insertmacro _ReplaceInFile "$INSTDIR\sidecar.yml" "<NODENAME>" $NodeName
  !insertmacro _ReplaceInFile "$INSTDIR\sidecar.yml" "<UPDATEINTERVAL>" $UpdateInterval
  !insertmacro _ReplaceInFile "$INSTDIR\sidecar.yml" "<TLSSKIPVERIFY>" $TlsSkipVerify
  !insertmacro _ReplaceInFile "$INSTDIR\sidecar.yml" "<SENDSTATUS>" $SendStatus
  !insertmacro _ReplaceInFile "$INSTDIR\sidecar.yml" "<APITOKEN>" $ApiToken

SectionEnd
 
;--------------------------------    
;Uninstaller Section  
Section "Uninstall"

  ;Uninstall system service
  ExecWait '"$INSTDIR\graylog-sidecar.exe" -service stop'
  ExecWait '"$INSTDIR\graylog-sidecar.exe" -service uninstall'
 
  ;Delete Files
  RMDir /r "$INSTDIR\*.*"    
 
  ;Remove the installation directory
  SetOutPath $TEMP
  RMDir "$INSTDIR"
  RMDir $GraylogDir
 
  ;Remove uninstall entries in the registry 
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\GraylogSidecar"

SectionEnd
 
 
;--------------------------------    
;Functions

Function .onInit
  ; check admin rights
  Call CheckAdmin
  
  ; check concurrent un/installations
  Call CheckConcurrent
    
  !insertmacro Check_X64
FunctionEnd

Function un.oninit
  ; check admin rights
  Call un.CheckAdmin
  
  ; check concurrent un/installations
  Call un.CheckConcurrent

  !insertmacro Check_X64
FunctionEnd

 

Function nsDialogsPage
  nsDialogs::Create 1018

  
  !insertmacro MUI_HEADER_TEXT "${MUI_BRANDINGTEXT} Configuration" "Here you can check and modify the configuration of this agent"
  
  
  Pop $Dialog

  ${If} $Dialog == error
     Abort
  ${EndIf}

  ${NSD_CreateLabel} 0 0 100% 12u "Enter the URL to your Graylog API:"
  Pop $Label
  ${NSD_CreateText} 50 20 75% 12u "http://127.0.0.1:9000/api"
  Pop $InputServerUrl

  ${NSD_CreateLabel} 0 60 100% 12u "The name of this instance:"
  Pop $Label
  ${NSD_CreateText} 50 80 75% 12u ""
  Pop $InputNodeName
  ${NSD_CreateLabel} 50 100 100% 12u "If empty, the hostname will be used."
  Pop $Label

  ${NSD_CreateLabel} 0 140 100% 12u "Enter the server API token:"
  Pop $Label
  ${NSD_CreateText} 50 160 75% 12u ""
  Pop $InputApiToken

  nsDialogs::Show
FunctionEnd

Function nsDialogsPageLeave
  ${NSD_GetText} $InputServerUrl $ServerUrl
  ${NSD_GetText} $InputNodeName $NodeName
  ${NSD_GetText} $InputApiToken $ApiToken

  ${If} $ServerUrl == ""
      MessageBox MB_OK "Please enter a valid address to your Graylog server!"
      Abort
  ${EndIf}
  ${If} $ApiToken == ""
      MessageBox MB_OK "Please enter an API token!"
      Abort
  ${EndIf}
FunctionEnd
