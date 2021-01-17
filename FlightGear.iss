﻿; Script generated by the Inno Setup Script Wizard.
; SEE THE DOCUMENTATION FOR DETAILS ON CREATING INNO SETUP SCRIPT FILES!
;
; This script creates an installable FlightGear package for Win32 using the
; "Inno Setup" package builder.  Inno Setup is free (but probably not open
; source?.)  The official web site for this package building software is:
;
;     http://www.jrsoftware.org/isinfo.php
;
; Note: Files root path is defined in the FgHarnessPath (in InstallConfig.iss)
;
; For example if You want to use X: drive as a root path 
; You can do this with the command below:
;
;     subst X: path_to_files
;
; For example:
;
;     C:\> subst X: F:\Path\to\FlightGear\root
;     C:\> subst X: F:\
;
;
; InstallConfig.iss example content:
;
;  #define FGHarnessPath "x:"
;  #define FGVersion "2020.4.1"
;  #define FGVersionGroup "2020.4"
;  #define OSGVersion "3.0.0"
;  #define OSGSoNumber "2"
;  #define OTSoNumber "3"
;  #define FGDetails "-nightly"
;  #define IncludeData "FALSE"
;
; Uninstall procedure with --uninstall flag:
;  executed by fgfs.exe (fg_init.cxx):
;  - removes all under the FG_HOME directory
;  - removes all from Download dir/Terrasync
;  - removes all from Download dir/Aircraft

#include "InstallConfig.iss"
#include "FlightGear-i18n.iss"
                               
#define FGSourcePath FgHarnessPath + "\flightgear"

#define InstallDir32 FgHarnessPath + "\install\msvc140"
#define InstallCompositor32 FgHarnessPath + "\install\msvc140\compositor"
#define OSGInstallDir InstallDir32 + "\OpenSceneGraph"
#define OSGPluginsDir OSGInstallDir + "\bin\osgPlugins-" + OSGVersion

#define InstallDir64 FgHarnessPath + "\install\msvc140-64"
#define InstallCompositor64 FgHarnessPath + "\install\msvc140-64\compositor"
#define OSG64InstallDir InstallDir64 + "\OpenSceneGraph"
#define OSG64PluginsDir OSG64InstallDir + "\bin\osgPlugins-" + OSGVersion

#define ThirdPartyDir FgHarnessPath + "\windows-3rd-party\msvc140"

; we copy everything in install/<arch>/bin except these, which aren't
; useful to the end-user to ship
#define ExcludedBinaries "*smooth.exe,metar.exe"

#include "FlightGear-files.iss"

[Setup]
AppId=FlightGear_{#FGVersionGroup}
AppName=FlightGear
AppPublisher=The FlightGear Team
OutputBaseFilename=FlightGear-{#FGVersion}{#FGDetails}
AppVerName=FlightGear v{#FGVersion}
AppVersion={#FGVersion}
AppPublisherURL=http://www.flightgear.org
AppSupportURL=http://www.flightgear.org
AppUpdatesURL=http://www.flightgear.org
DefaultDirName={pf}\FlightGear {#FGVersionGroup}
UsePreviousAppDir=no
DefaultGroupName=FlightGear {#FGVersionGroup}
UsePreviousGroup=no
LicenseFile={#FGSourcePath}\COPYING
Uninstallable=yes
SetupIconFile={#FgHarnessPath}\windows\flightgear.ico
VersionInfoVersion={#FGVersion}.0
WizardImageFile={#FgHarnessPath}\windows\setupimg.bmp
WizardImageStretch=No
WizardSmallImageFile={#FgHarnessPath}\windows\setupsmall.bmp
VersionInfoCompany=The FlightGear Team
UninstallDisplayIcon={app}\bin\fgfs.exe
ArchitecturesInstallIn64BitMode=x64
ArchitecturesAllowed=x86 x64

; Sign tool must be defined in the Inno Setup GUI, to avoid
; exposing the certificate password
; SignTool=fg_code_sign1

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "Additional icons:"

[Languages]
Name: "en"; MessagesFile: "compiler:Default.isl"; 
Name: "pl"; MessagesFile: "compiler:Languages\Polish.isl"; 
Name: "es"; MessagesFile: "compiler:Languages\Spanish.isl"; 
Name: "nl"; MessagesFile: "compiler:Languages\Dutch.isl"; 
Name: "de"; MessagesFile: "compiler:Languages\German.isl"; 

[Dirs]
[Dirs]
; Make the user installable scenery directory
Name: "{%USERPROFILE}\FlightGear\Downloads"; Permissions: creatorowner-modify; Check: not DirExists(ExpandConstant('{%USERPROFILE}\FlightGear\Downloads'))
Name: "{%USERPROFILE}\FlightGear\Custom Aircraft"; Permissions: creatorowner-modify; Check: not DirExists(ExpandConstant('{%USERPROFILE}\FlightGear\Custom Aircraft'))
Name: "{%USERPROFILE}\FlightGear\Custom Scenery"; Permissions: creatorowner-modify; Check: not DirExists(ExpandConstant('{%USERPROFILE}\FlightGear\Custom Scenery'))

[Icons]
Name: "{userdesktop}\FlightGear {#FGVersionGroup}"; Filename: "{app}\bin\fgfs.exe"; Parameters: "--launcher"; WorkingDir: "{app}\bin"; Tasks: desktopicon;
Name: "{group}\FlightGear {#FGVersionGroup}"; Filename: "{app}\bin\fgfs.exe"; Parameters: "--launcher"; WorkingDir: "{app}\bin";
Name: "{group}\FlightGear {#FGVersionGroup} - Compositor"; Filename: "{app}\bin\fgfs-compositor.exe"; Parameters: "--launcher"; WorkingDir: "{app}\bin";
Name: "{group}\FlightGear Manual"; Filename: "{app}\data\Docs\getstart.pdf"
Name: "{group}\FlightGear Documentation"; Filename: "{app}\data\Docs\index.html"
Name: "{group}\Flightgear Wiki"; Filename: "http://wiki.flightgear.org"
Name: "{group}\Tools\Uninstall FlightGear"; Filename: "{uninstallexe}"
Name: "{group}\Tools\fgjs"; Filename: "cmd"; Parameters: "/k fgjs.exe ""--fg-root={app}\data"""; WorkingDir: "{app}\bin"
Name: "{group}\Tools\yasim"; Filename: "cmd"; Parameters: "/k ""{app}\bin\yasim.exe"" -h"; WorkingDir: "{app}\bin"
Name: "{group}\Tools\fgpanel"; Filename: "cmd"; Parameters: "/k ""{app}\bin\fgpanel.exe"" -h"; WorkingDir: "{app}\bin"
Name: "{group}\Tools\FGCom"; Filename: "{app}\bin\fgcom.exe"; WorkingDir: "{app}\bin"
Name: "{group}\Tools\FGCom-testing"; Filename: "{app}\bin\fgcom.exe"; Parameters: "--frequency=910"; WorkingDir: "{app}\bin"
Name: "{group}\Tools\Explore Documentation Folder"; Filename: "{app}\data\Docs"

[Code]
const
  NET_FW_SCOPE_ALL = 0;
  NET_FW_IP_VERSION_ANY = 2;
  NET_FW_ACTION_ALLOW = 1;
  NET_FW_RULE_DIR_ALL = 0;
  NET_FW_RULE_DIR_IN = 1;
  NET_FW_RULE_DIR_OUT = 2;
  NET_FW_IP_PROTOCOL_ALL = 0;
  NET_FW_IP_PROTOCOL_TCP = 6;
  NET_FW_IP_PROTOCOL_UDP = 17;
  NET_FW_PROFILE2_DOMAIN = 1;
  NET_FW_PROFILE2_PRIVATE = 2;
  NET_FW_PROFILE2_PUBLIC = 4;

procedure URLLabelOnClick(Sender: TObject);
var
  ErrorCode: Integer;
begin
  ShellExec('open', 'http://www.flightgear.org', '', '', SW_SHOWNORMAL, ewNoWait, ErrorCode);
end;

procedure CreateURLLabel(ParentForm: TSetupForm; CancelButton: TNewButton);
var
  URLLabel: TNewStaticText;
begin
  URLLabel := TNewStaticText.Create(ParentForm);
  URLLabel.Caption := 'www.flightgear.org';
  URLLabel.Cursor := crHand;
  URLLabel.OnClick := @URLLabelOnClick;
  URLLabel.Parent := ParentForm;
  { Alter Font *after* setting Parent so the correct defaults are inherited first }
  URLLabel.Font.Style := URLLabel.Font.Style + [fsUnderline];
  URLLabel.Font.Color := clBlue;
  URLLabel.Top := CancelButton.Top + CancelButton.Height - URLLabel.Height - 2;
  URLLabel.Left := ScaleX(20);
end;

function UpdateReadyMemo(Space, NewLine, MemoUserInfoInfo, MemoDirInfo, MemoTypeInfo, MemoComponentsInfo, MemoGroupInfo, MemoTasksInfo: String): String;
var
  S: String;
begin
  S := '';
  S := S + MemoDirInfo + NewLine + NewLine;
  S := S + MemoGroupInfo + NewLine + NewLine;
  S := S + MemoTasksInfo + NewLine + NewLine;

  Result := S;
end;

procedure AddBasicFirewallException(AppName, FileName: String);
var
  FirewallObject: variant;
  RuleObject: variant;
begin
  try
    FirewallObject := CreateOleObject('HNetCfg.FwMgr');
    RuleObject := CreateOleObject('HNetCfg.FwAuthorizedApplication');
    RuleObject.ProcessImageFileName := FileName;
    RuleObject.Name := AppName;
    RuleObject.Scope := NET_FW_SCOPE_ALL;
    RuleObject.IpVersion := NET_FW_IP_VERSION_ANY;
    RuleObject.Enabled := true;
    FirewallObject.LocalPolicy.CurrentProfile.AuthorizedApplications.Add(RuleObject);
  except
  end;
end;

procedure AddAdvancedFirewallException(AppName, AppDescription, FileName: String; Protocol: Integer; LocalPorts, RemotePorts: String; Direction: Integer);
var
  FirewallObject: variant;
  RuleObject: variant;
begin
  try
    FirewallObject := CreateOleObject('HNetCfg.FwPolicy2');
    RuleObject := CreateOleObject('HNetCfg.FWRule');
    RuleObject.Name := AppName;
    RuleObject.Description := AppDescription;
    RuleObject.ApplicationName := FileName;
    if (Protocol <> NET_FW_IP_PROTOCOL_ALL) then
      RuleObject.Protocol := Protocol;
    if (LocalPorts <> '') then
      RuleObject.LocalPorts := LocalPorts;
    if (RemotePorts <> '') then
      RuleObject.RemotePorts := RemotePorts;
    if (Direction <> NET_FW_RULE_DIR_ALL) then
      RuleObject.Direction := Direction;
    RuleObject.Enabled := true;
    RuleObject.Grouping := 'FlightGear';
    RuleObject.Profiles := NET_FW_PROFILE2_DOMAIN + NET_FW_PROFILE2_PRIVATE + NET_FW_PROFILE2_PUBLIC;
    RuleObject.Action := NET_FW_ACTION_ALLOW;
    RuleObject.RemoteAddresses := '*';
    FirewallObject.Rules.Add(RuleObject);
  except
  end;
end;

procedure RemoveFirewallException(AppName, FileName: String);
var
  FirewallObject: variant;
  Version: TWindowsVersion;
begin
  GetWindowsVersionEx(Version);
  try
    if (Version.Major >= 6) then
      begin
        FirewallObject := CreateOleObject('HNetCfg.FwPolicy2');
        FirewallObject.Rules.Remove(AppName);
      end
    else if (Version.Major = 5) and (((Version.Minor = 1) and (Version.ServicePackMajor >= 2)) or ((Version.Minor = 2) and (Version.ServicePackMajor >= 1))) then
      begin
        FirewallObject := CreateOleObject('HNetCfg.FwMgr');
        FirewallObject.LocalPolicy.CurrentProfile.AuthorizedApplications.Remove(FileName);
      end;
  except
  end;
end;

var
  UninstallCheckCleanPage: TNewNotebookPage;
  UninstallBackButton: TNewButton;
  UninstallNextButton: TNewButton;
  DoCleanCheckbox : TNewCheckBox;
  CleanHelp : TNewStaticText;

procedure InitializeUninstallProgressForm();
begin
  UninstallCheckCleanPage := TNewNotebookPage.Create(UninstallProgressForm);
  UninstallCheckCleanPage.Notebook := UninstallProgressForm.InnerNotebook;
  UninstallCheckCleanPage.Parent := UninstallProgressForm.InnerNotebook;
  UninstallCheckCleanPage.Align := alClient

  DoCleanCheckbox := TNewCheckBox.Create(UninstallProgressForm);
  DoCleanCheckbox.Parent := UninstallCheckCleanPage;
  DoCleanCheckbox.Caption := ExpandConstant('{cm:RemoveAllSettings}');
  DoCleanCheckbox.Left := ScaleX(10);
  DoCleanCheckbox.Top := ScaleY(10);

  DoCleanCheckbox.Width := UninstallProgressForm.InnerNotebook.Width - ScaleX(20)
  DoCleanCheckbox.Height := ScaleY(30)

  CleanHelp := TNewStaticText.Create(UninstallProgressForm);
  CleanHelp.Parent := UninstallCheckCleanPage;
  CleanHelp.Top := DoCleanCheckbox.Top + DoCleanCheckbox.Height + ScaleY(10);
  CleanHelp.Left := DoCleanCheckbox.Left;
  CleanHelp.Width := DoCleanCheckbox.Width;
  CleanHelp.Height := CleanHelp.AdjustHeight();

  CleanHelp.WordWrap := True;
  CleanHelp.Caption := ExpandConstant('{cm:RemoveAllSettingsDescription}');

  UninstallProgressForm.InnerNotebook.ActivePage := UninstallCheckCleanPage;

   UninstallNextButton := TNewButton.Create(UninstallProgressForm);
   UninstallNextButton.Caption := 'Next';
    UninstallNextButton.Parent := UninstallProgressForm;
    UninstallNextButton.Left :=
      UninstallProgressForm.CancelButton.Left -
      UninstallProgressForm.CancelButton.Width -
      ScaleX(10);
    UninstallNextButton.Top := UninstallProgressForm.CancelButton.Top;
    UninstallNextButton.Width := UninstallProgressForm.CancelButton.Width;
    UninstallNextButton.Height := UninstallProgressForm.CancelButton.Height;
     UninstallNextButton.ModalResult := mrOk;

    UninstallProgressForm.CancelButton.Enabled := True;
    UninstallProgressForm.CancelButton.ModalResult := mrCancel;

    if UninstallProgressForm.ShowModal = mrCancel then Abort;

    UninstallProgressForm.InnerNotebook.ActivePage := UninstallProgressForm.InstallingPage;
end;


procedure CurStepChanged(CurStep: TSetupStep);
var
  Version: TWindowsVersion;
begin
  if CurStep = ssPostInstall then
    begin
      GetWindowsVersionEx(Version);
      if (Version.Major >= 6) then
        begin
          { IN and OUT rules must be specified separately, otherwise the firewall will create only the IN rule }
          AddAdvancedFirewallException('FlightGear', ExpandConstant('{cm:FirewallFgException}'), ExpandConstant('{app}') + '\bin\fgfs.exe', NET_FW_IP_PROTOCOL_ALL, '', '', NET_FW_RULE_DIR_IN);
          AddAdvancedFirewallException('FlightGear', ExpandConstant('{cm:FirewallFgException}'), ExpandConstant('{app}') + '\bin\fgfs.exe', NET_FW_IP_PROTOCOL_ALL, '', '', NET_FW_RULE_DIR_OUT);
          AddAdvancedFirewallException('FlightGear FGCom', ExpandConstant('{cm:FirewallFgcomException}'), ExpandConstant('{app}') + '\bin\fgcom.exe', NET_FW_IP_PROTOCOL_ALL, '', '', NET_FW_RULE_DIR_IN);
          AddAdvancedFirewallException('FlightGear FGCom', ExpandConstant('{cm:FirewallFgcomException}'), ExpandConstant('{app}') + '\bin\fgcom.exe', NET_FW_IP_PROTOCOL_ALL, '', '', NET_FW_RULE_DIR_OUT);
        end
      else if (Version.Major = 5) and (((Version.Minor = 1) and (Version.ServicePackMajor >= 2)) or ((Version.Minor = 2) and (Version.ServicePackMajor >= 1))) then
        begin
          { The Windows XP/Server 2003 firewall does not block outgoing connections at all, so only listening processes should be added }
          AddBasicFirewallException('FlightGear', ExpandConstant('{app}') + '\bin\fgfs.exe');
          AddBasicFirewallException('FlightGear FGCom', ExpandConstant('{app}') + '\bin\fgcom.exe');
        end;
    end;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
     var ResultCode: Integer;
begin
  if CurUninstallStep = usUninstall then
  begin
     if DoCleanCheckbox.Checked = True then
     begin
         Log('Running clean uninstall');
         Exec(ExpandConstant('{app}\bin\fgfs.exe'), '--uninstall', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
         Log('clean uninstall completed');
     end;
  end;

  if CurUninstallStep = usPostUninstall then
    begin
      RemoveFirewallException('FlightGear', ExpandConstant('{app}') + '\bin\fgfs.exe');
      RemoveFirewallException('FlightGear FGCom', ExpandConstant('{app}') + '\bin\fgcom.exe');
    end;
end;
