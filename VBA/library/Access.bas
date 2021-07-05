Attribute VB_Name = "Access"
Option Compare Database

'Delete Table
Public Sub DelTable(TableName As String)
    If TableExist(TableName) = True Then
        DoCmd.DeleteObject acTable, TableName
    End If
End Sub

'Delete Table by sub string
Public Sub DelTables_BySubStr(sub_str As String)
    Dim tdf As TableDef
    With CurrentDb
        For Each tdf In .TableDefs
            If InStr(tdf.Name, sub_str) > 0 Then
                DoCmd.SetWarnings False
                DoCmd.DeleteObject acTable, tdf.Name
                DoCmd.SetWarnings True
            End If
        Next tdf
    End With
End Sub

'Check whether table exists or not
Public Function TableExist(TableName As String) As Boolean
    TableExist = False
    Dim tdf As TableDef
    With CurrentDb
        For Each tdf In .TableDefs
            If TableName = tdf.Name Then
                    TableExist = True
                    Exit For
            End If
        Next tdf
    End With
End Function

'Delete Query
Public Sub DelQuery(QueryName As String)
    Dim QryExist As Boolean
    QryExist = QueryExist(QueryName)
    If QryExist = True Then
        DoCmd.SetWarnings False
        DoCmd.DeleteObject acQuery, QueryName
        DoCmd.SetWarnings True
    End If
End Sub

'Check whether query exist or not
Public Function QueryExist(QueryName As String) As Boolean
    QueryExist = False
    Dim QDf As QueryDef
    With CurrentDb
        For Each QDf In .QueryDefs
            If QueryName = QDf.Name Then
                    QueryExist = True
                    Exit For
            End If
        Next QDf
    End With
End Function

'Obtain record counts of a table
Public Function Table_RecordCount(Tbl_name As String) As Long
    Table_RecordCount = -1
    If TableExist(Tbl_name) = False Then
        GoTo Exit_Table_RecordCount
    End If
    Table_RecordCount = SQL_Obj_RecordCount(Tbl_name)
Exit_Table_RecordCount:
End Function

'Obtain record counts of a query
Public Function Query_RecordCount(Qry_name As String) As Long
    Query_RecordCount = -1
    If QueryExist(Qry_name) = False Then
        GoTo Exit_Query_RecordCount
    End If
    Query_RecordCount = SQL_Obj_RecordCount(Qry_name)
Exit_Query_RecordCount:
End Function

'Obtain record counts of a SQL object
Public Function SQL_Obj_RecordCount(SQL_Obj_name As String) As Long
    SQL_Obj_RecordCount = -1
    Dim RS As DAO.Recordset
    Set RS = CurrentDb.OpenRecordset(SQL_Obj_name)
    With RS
        If .EOF = True Then
            SQL_Obj_RecordCount = 0
        Else
            .MoveFirst
            .MoveLast
            SQL_Obj_RecordCount = .RecordCount
        End If
        .Close
    End With
End Function

'Check whether a table is valid or not
Public Function TableValid(TableName As String) As Boolean
    TableValid = False
    If TableExist(TableName) = False Then
        Exit Function
    End If
    If Table_RecordCount(TableName) <= 0 Then
        Exit Function
    End If
    TableValid = True
End Function

'Check whether a query is valid or not
Public Function QueryValid(Qryname As String) As Boolean
    QueryValid = False
    If QueryExist(Qryname) = False Then
        Exit Function
    End If
    If Query_RecordCount(Qryname) <= 0 Then
        Exit Function
    End If
    QueryValid = True
End Function

'Transfer multiple objects in a database
Public Function TransferObjSetInDb(TransferType As Variant, DatabaseType As String, DatabaseName As String, ObjectType As Variant, SrcList As Variant, DesList As Variant, Optional StructureOnly As Boolean = False, Optional StoreLogin As Boolean = False) As String
    On Error GoTo Err_TransferObjSetInDb
    Dim FailedReason As String
    If Len(Dir(DatabaseName)) = 0 Then
        FailedReason = DatabaseName
        GoTo Exit_TransferObjSetInDb
    End If
    If VarType(DesList) <> vbArray + vbVariant Then
        DesList = SrcList
    End If
    If UBound(SrcList) <> UBound(DesList) Then
        FailedReason = "No. of elements in SrcList and DesList are not equal"
        GoTo Exit_TransferObjSetInDb
    End If
    Dim TblNameIdx As Integer
    For TblNameIdx = 0 To UBound(SrcList)
        If ObjectType = acTable Then
            DelTable (DesList(TblNameIdx))
        ElseIf ObjectType = acQuery Then
            DelQuery (DesList(TblNameIdx))
        End If
        On Error Resume Next
        DoCmd.TransferDatabase TransferType, DatabaseType, DatabaseName, ObjectType, SrcList(TblNameIdx), DesList(TblNameIdx), StructureOnly, StoreLogin
        On Error GoTo Next_TblNameIdx
Next_TblNameIdx:
    Next TblNameIdx
    On Error GoTo Err_TransferObjSetInDb
Exit_TransferObjSetInDb:
    TransferObjSetInDb = FailedReason
    Exit Function
Err_TransferObjSetInDb:
    FailedReason = Err.Description
    Resume Exit_TransferObjSetInDb
End Function

'Link multiple table in a daily file of specified format
Public Function LinkTblSetInDailyFileInDir(DataDate As Date, DateFmt As String, DailyFileDir_path As String, DailyFile_prefix As String, FileFmt As String, SrcList As Variant, DesList As Variant, Optional ReferToLocal As Boolean = False) As String
    On Error GoTo Err_LinkTblSetInDailyFileInDir
    Dim FailedReason As String
    Dim DailyFile_path As String
    DailyFile_path = DailyFile_prefix & "_" & Format(DataDate, DateFmt) & "." & FileFmt
    If ReferToLocal = False Then
        DailyFile_path = DailyFileDir_path & DailyFile_path
        Dim DailyFile_l_path As String
        DailyFile_l_path = CurrentProject.Path & LocalDailyData_path & DailyFile_prefix & "_local." & FileFmt
        Call CopyFileBypassErr(DailyFile_path, DailyFile_l_path)
        DailyFile_path = DailyFile_l_path
    Else
        DailyFile_path = CurrentProject.Path & LocalDailyData_path & DailyFile_path
    End If
    If FileFmt = "xls" Then
        FailedReason = LinkToWorksheetInWorkbook(DailyFile_path, SrcList, DesList)
    ElseIf FileFmt = "mdb" Then
        FailedReason = TransferObjSetInDb(acLink, "Microsoft Access", DailyFile_path, acTable, SrcList, DesList, True)
    End If
Exit_LinkTblSetInDailyFileInDir:
    LinkTblSetInDailyFileInDir = FailedReason
    Exit Function
Err_LinkTblSetInDailyFileInDir:
    FailedReason = Err.Description
    Resume Exit_LinkTblSetInDailyFileInDir
End Function

'Link Table Through Table Definition
Public Function LinkTblByTdf(Tbl_src_name As String, Tbl_des_name As String, str_conn As String) As String
    On Error GoTo Err_LinkTblByTdf
    Dim FailedReason As String
    DelTable (Tbl_des_name)
    With CurrentDb
        Dim tdf As TableDef
        Set tdf = .CreateTableDef(Tbl_des_name)
        tdf.Connect = str_conn
        tdf.SourceTableName = Tbl_src_name
        .TableDefs.Append tdf
        .TableDefs(Tbl_des_name).RefreshLink
    End With
    RefreshDatabaseWindow
Exit_LinkTblByTdf:
    LinkTblByTdf = FailedReason
    Exit Function
Err_LinkTblByTdf:
    FailedReason = Err.Description
    Resume Exit_LinkTblByTdf
End Function

'Remove all link tables
Public Function RemoveLink() As String
    On Error GoTo Err_RemoveLink
    Dim FailedReason As String
    Dim tdf As TableDef
    For Each tdf In CurrentDb.TableDefs
        If tdf.Attributes = dbAttachedTable Or tdf.Attributes = dbAttachedODBC Then
            DoCmd.DeleteObject acTable, tdf.Name
        End If
    Next tdf
Exit_RemoveLink:
    RemoveLink = FailedReason
    Exit Function
Err_RemoveLink:
    FailedReason = Err.Description
    Resume Exit_RemoveLink
End Function

'Get the current path of a link table
Public Function GetLinkTblPath(Tbl_name As String) As String
    On Error GoTo Exit_GetLinkTblPath
    Dim LinkTblPath As String
    LinkTblPath = CurrentDb.TableDefs(Tbl_name).Connect
    LinkTblPath = Right(LinkTblPath, Len(LinkTblPath) - (InStr(1, LinkTblPath, "DATABASE=") + 8)) & "\" & CurrentDb.TableDefs(Tbl_name).SourceTableName
    GetLinkTblPath = LinkTblPath
Exit_GetLinkTblPath:
    Exit Function
Err_GetLinkTblPath:
    ShowMsgBox (Err.Description)
    GetLinkTblPath = ""
    Resume Exit_GetLinkTblPath
End Function

'Get Link Table connection Info
Public Function GetLinkTblConnInfo(Tbl_name As String, param As String) As String
    On Error GoTo Exit_GetLinkTblConnInfo
    Dim LinkTblConnInfo As Variant
    LinkTblConnInfo = SplitStrIntoArray(CurrentDb.TableDefs(Tbl_name).Connect, ";")
    Dim param_idx As Integer
    Dim LinkTblConnParam As String
    param = param & "="
    For param_idx = 0 To UBound(LinkTblConnInfo)
        LinkTblConnParam = LinkTblConnInfo(param_idx)
        If Left(LinkTblConnParam, Len(param)) = param Then
            GetLinkTblConnInfo = Right(LinkTblConnParam, Len(LinkTblConnParam) - Len(param))
            Exit For
        End If
    Next param_idx
Exit_GetLinkTblConnInfo:
    Exit Function
Err_GetLinkTblConnInfo:
    ShowMsgBox (Err.Description)
    GetLinkTblConnInfo = ""
    Resume Exit_GetLinkTblConnInfo
End Function

'Obtain a string with all columns names of a table
Public Function ObtainTblFldNameStr(Tbl_name As String)
    If TableExist(Tbl_name) = False Then
            GoTo Exit_ObtainTblFldNameStr
    End If
    With CurrentDb
        Dim td As TableDef
        Dim fld As Field
        Set td = .TableDefs(Tbl_name)
        If td.Fields.count <= 0 Then
            GoTo Exit_ObtainTblFldNameStr
        End If
        For Each fld In td.Fields
            ObtainTblFldNameStr = ObtainTblFldNameStr + ", " + "[" + fld.Name + "]"
        Next
        ObtainTblFldNameStr = Right(ObtainTblFldNameStr, Len(ObtainTblFldNameStr) - 1)
    End With
Exit_ObtainTblFldNameStr:
    Exit Function
End Function

'Find a column in a table
Public Function FindColInTbl(Tbl_name As String, Col_name As String) As Integer
    FindColInTbl = -1
    If TableExist(Tbl_name) = False Then
            GoTo Exit_FindColInTbl
    End If
    With CurrentDb
        Dim td As TableDef
        Dim fld As Field
        Set td = .TableDefs(Tbl_name)
        If td.Fields.count <= 0 Then
            GoTo Exit_FindColInTbl
        End If
        Dim Col_Idx As Integer
        Col_Idx = 0
        For Each fld In td.Fields
            If Col_name = fld.Name Then
                FindColInTbl = Col_Idx
                Exit For
            End If
            Col_Idx = Col_Idx + 1
        Next
    End With
Exit_FindColInTbl:
    Exit Function
End Function

'Export Access Table to Text file
Public Function ExportTableToTxt(Tbl_name As String, des As String, Optional Delim As String = " ", Optional Quotation As String = "", Optional HasFldName As Boolean = True, Optional NullStr As String = "", Optional DateFmt As String = "MM/DD/YY", Optional TimeFmt As String = "h:mm") As String
    On Error GoTo Err_ExportTableToTxt
    Dim FailedReason As String
    If des = "" Or Tbl_name = "" Then
        FailedReason = "Input is invalid"
        GoTo Exit_ExportTableToTxt
    End If
    If TableExist(Tbl_name) = False Then
        FailedReason = Tbl_name & " does not exist"
        GoTo Exit_ExportTableToTxt
    End If
    If Delim = "" Then
        Delim = " "
    End If
    Dim des_PortNum As Integer
    des_PortNum = FreeFile
    Open des For Output As #des_PortNum
    With CurrentDb
        Dim line As String
        line = ""
        If HasFldName = True Then
            Dim TD_Tbl As TableDef
            Set TD_Tbl = .TableDefs(Tbl_name)
            Dim fld As Field
            For Each fld In TD_Tbl.Fields
                line = line & fld.Name & Delim
            Next
            line = Left(line, Len(line) - Len(Delim))
            Print #des_PortNum, line
        End If
        Dim RS_Tbl As Recordset
        Set RS_Tbl = .OpenRecordset(Tbl_name)
        With RS_Tbl
            .MoveFirst
            Dim FldIdx As Integer
            Dim fld_str As String
            Do Until .EOF
                FldIdx = 0
                line = ""
                For FldIdx = 0 To .Fields.count - 1
                    If IsNull(.Fields(FldIdx)) = True Then
                        fld_str = NullStr
                    ElseIf .Fields(FldIdx).Type = dbDate Then
                        If .Fields(FldIdx).Value > 1 Then
                            fld_str = Format(str(.Fields(FldIdx).Value), DateFmt)
                        Else
                            fld_str = Format(str(.Fields(FldIdx).Value), TimeFmt)
                        End If
                    Else
                        fld_str = .Fields(FldIdx).Value
                    End If
                    line = line & Quotation & fld_str & Quotation & Delim
                Next
                line = Left(line, Len(line) - Len(Delim))
                Print #des_PortNum, line
                .MoveNext
            Loop
        End With
        .Close
    End With
    Close #des_PortNum
Exit_ExportTableToTxt:
    ExportTableToTxt = FailedReason
    Exit Function
Err_ExportTableToTxt:
    FailedReason = Err.Description
    Resume Exit_ExportTableToTxt
End Function

'Convert Access Table into HTML Format
Public Function ConvertTblToHtml(Tbl_name As String, Html As String) As String
    On Error GoTo Err_ConvertTblToHtml
    Dim FailedReason As String
    If TableValid(Tbl_name) = False Then
        FailedReason = Tbl_name & "is not valid"
        GoTo Exit_ConvertTblToHtml
    End If
    Html = Html & "<table border = ""1"", style = ""font-size:9pt;"">" & vbCrLf
    Dim RS_Tbl As DAO.Recordset
    Set RS_Tbl = CurrentDb.OpenRecordset(Tbl_name)
    'Create table
    With RS_Tbl
        Dim fld_idx As Integer
        'Create header
        Html = Html & "<tr>" & vbCrLf
        For fld_idx = 0 To .Fields.count - 1
            Html = Html & "<th bgcolor = #c0c0c0>" & .Fields(fld_idx).Name & "</th>" & vbCrLf
        Next fld_idx 'For fld_idx = 0 To .Fields.count - 1
        Html = Html & "</tr>"
        .MoveFirst
        Do Until .EOF
            Html = Html & "<tr>" & vbCrLf
            For fld_idx = 0 To .Fields.count - 1
                Html = Html & "<td>" & .Fields(fld_idx).Value & "</td>" & vbCrLf
            Next fld_idx 'For fld_idx = 0 To .Fields.count - 1
            Html = Html & "</tr>" & vbCrLf
            .MoveNext
        Loop
        .Close
    End With 'RS_TblD
    Html = Html & "</table>"
Exit_ConvertTblToHtml:
    ConvertTblToHtml = FailedReason
    Exit Function
Err_ConvertTblToHtml:
    FailedReason = Err.Description
    Resume Exit_ConvertTblToHtml
End Function

'Generate a concatenated string of related records (SQL Query Use)
Public Function ConcatRelated(strField As String, strTable As String, Optional strWhere As String, Optional strOrderBy As String, Optional strSeparator = ", ") As Variant
On Error GoTo Err_ConcatRelated
    Dim rs As DAO.Recordset         'Related records
    Dim rsMV As DAO.Recordset       'Multi-valued field recordset
    Dim strSql As String            'SQL statement
    Dim strOut As String            'Output string to concatenate to.
    Dim lngLen As Long              'Length of string.
    Dim bIsMultiValue As Boolean    'Flag if strField is a multi-valued field.
    ConcatRelated = Null
    strSql = "SELECT " & strField & " FROM " & strTable
    If strWhere <> vbNullString Then
        strSql = strSql & " WHERE " & strWhere
    End If
    If strOrderBy <> vbNullString Then
        strSql = strSql & " ORDER BY " & strOrderBy
    End If
    Set rs = DBEngine(0)(0).OpenRecordset(strSql, dbOpenDynaset)
    'Determine if the requested field is multi-valued (Type is above 100.)
    bIsMultiValue = (rs(0).Type > 100)
    Do While Not rs.EOF
        If bIsMultiValue Then
            Set rsMV = rs(0).Value
            Do While Not rsMV.EOF
                If Not IsNull(rsMV(0)) Then
                    strOut = strOut & rsMV(0) & strSeparator
                End If
                rsMV.MoveNext
            Loop
            Set rsMV = Nothing
        ElseIf Not IsNull(rs(0)) Then
            strOut = strOut & rs(0) & strSeparator
        End If
        rs.MoveNext
    Loop
    rs.Close
    lngLen = Len(strOut) - Len(strSeparator)
    If lngLen > 0 Then
        ConcatRelated = Left(strOut, lngLen)
    End If
Exit_ConcatRelated:
    Set rsMV = Nothing
    Set rs = Nothing
    Exit Function
Err_ConcatRelated:
    Call ShowMsgBox("Error " & Err.Number & ": " & Err.Description, vbExclamation, "ConcatRelated()")
    Resume Exit_ConcatRelated
End Function

'Comapact and renew Database
Public Function CompactAndRenewDb(Db_path As String) As String
    On Error GoTo Err_CompactAndRenewDb
    Dim FailedReason As String
    If FileExists(Db_path) = False Then
        FailedReason = Db_path
        GoTo Exit_CompactAndRenewDb
    End If
    Dim WShell As Object
    Dim FSO As Object
    Set WShell = CreateObject("WScript.Shell")
    Set FSO = CreateObject("Scripting.FileSystemObject")
    Dim Db_CP_path As String
    Db_CP_path = WShell.ExpandEnvironmentStrings("%TEMP%") & "\" & FSO.GetBaseName(Db_path) & "_Compacted" & "." & FSO.GetExtensionName(Db_path)
    If Len(Dir(Db_CP_path)) > 0 Then
        Kill Db_CP_path
    End If
    Call CompactDatabase(Db_path, Db_CP_path)
    If Len(Dir(Db_CP_path)) = 0 Then
        GoTo Exit_CompactAndRenewDb
    End If
    Kill Db_path
    Call CopyFileBypassErr(Db_CP_path, Db_path)
    Kill Db_CP_path
Exit_CompactAndRenewDb:
    CompactAndRenewDb = FailedReason
    Exit Function
Err_CompactAndRenewDb:
    FailedReason = Err.Description
    Resume Exit_CompactAndRenewDb
End Function
