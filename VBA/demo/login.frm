VERSION 5.00
Begin {C62A69F0-16DC-11CE-9E98-00AA00574A4F} ϵͳ��¼ 
   Caption         =   "Login"
   ClientHeight    =   5892
   ClientLeft      =   100
   ClientTop       =   460
   ClientWidth     =   8960.001
   OleObjectBlob   =   "login.frx":0000
   StartUpPosition =   1  'CenterOwner
End
Attribute VB_Name = "ϵͳ��¼"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
'�����½��ť===========================================================
Private Sub LoginBtn_Click()
If UserNameBox.Text = "" Or PassWordBox.Text = "" Then
     MsgBox "����д��ȫ��", 1 + 64, "ϵͳ��¼"
     UserNameBox.SetFocus
Else
     If gotPassWordFromUserName(UserNameBox.Text) = PassWordBox.Text Then
     Unload Me
     MsgBox UserNameBox.Text & "��ã���ӭ����뱾ϵͳ��", 1 + 64, "��ӭ����"
     Application.Visible = True
     ActiveWorkbook.Author = "Super"
     ActiveWorkbook.Unprotect Password:="521sfiq"
     Sheets("LOVE").Visible = True
     Sheets("LOVE").Activate
     ActiveWorkbook.Protect Password:="521sfiq"
Else
     MsgBox "�Բ����¼����������������룡"
     
 End If
 End If
End Sub
'����˳���ť===========================================================
Private Sub LogoutBtn_Click()
     Unload Me
     Application.Visible = True
     ActiveWorkbook.Close savechanges:=False
     ThisWorkbook.Close False
End Sub
'������ð�ť===========================================================
Private Sub ResetBtn_Click()
UserNameBox = ""
PassWordBox = ""
VerificationBox = ""
End Sub
'�����ʼ��============================================================
Private Sub UserForm_Initialize()
     Dim x As Integer, Y As Integer
     x = Sheets("LOVE").Range("A65536").End(xlUp).Row
     UserNameBox.AddItem "Luna"
     UserNameBox.AddItem "Super"
     UserNameBox.AddItem "123456"
     gotVerificationCode
End Sub
Private Sub UserForm_QueryClose(Cancel As Integer, CloseMode As Integer)
     If CloseMode = 0 Then Cancel = 1
End Sub
'������֤��==============================================================
Sub gotVerificationCode()
Code = Int(Rnd() * 9000 + 1000)
VerificationLabel.Caption = Code
End Sub

Private Sub UserNameBox_Change()

End Sub

'�����֤�������»�ȡ��֤��===============================================
Private Sub VerificationLabel_Click()
gotVerificationCode
End Sub
