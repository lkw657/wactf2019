Imports System
Imports System.Collections
Imports System.Collections.Generic
Imports System.DirectoryServices
Imports System.Linq
Imports System.Management
Imports System.Runtime.CompilerServices
Imports Microsoft.VisualBasic.CompilerServices


Public Class UserAccount

    Public Property Username As String
    Public Property Password As String
    Public Property Description As String
    Public Property Logger As EventLog
    Private Property Path As String

    Public Sub New(username As String, password As String, description As String, logger As EventLog)
        Me.Username = username
        Me.Password = password
        Me.Description = description
        Me.Logger = logger
        If Not Me.Exists() Then
            Me.Create()
        End If
        ' make sure the password is up to date
        ' TODO description?
        SetPassword(password)
    End Sub

    Public Function Exists() As Boolean
        Dim result As Boolean = False
        Dim directoryEntry As DirectoryEntry = New DirectoryEntry("WinNT://" + Environment.MachineName + ",computer")
        Try
            Dim directoryEntry2 As DirectoryEntry = directoryEntry.Children.Find(Me.Username + ",user")
            Me.Path = directoryEntry2.Path
            result = True
        Catch ex As Exception
        End Try
        Return result
    End Function

    Public Function Create() As Boolean
        Dim result As Boolean = False
        Dim directoryEntry As DirectoryEntry = New DirectoryEntry("WinNT://" + Environment.MachineName + ",computer")
        Try
            Dim directoryEntry2 As DirectoryEntry = directoryEntry.Children.Add(Me.Username, "user")
            directoryEntry2.Invoke("SetPassword", Me.Password)
            directoryEntry2.Properties("Description").Add(Me.Description)
            directoryEntry2.Properties("Userflags").Add(65600)
            directoryEntry2.CommitChanges()
            Me.Path = directoryEntry2.Path
            result = True
        Catch ex As Exception
            Me.Logger.WriteEntry(ex.[GetType]().ToString() + " - " + ex.Message)
            result = False
        End Try
        Return result
    End Function

    Public Function IsInGroup(strGroupName As Object) As Boolean
        Dim dirGroup As DirectoryEntry = New DirectoryEntry("WinNT://" + Environment.MachineName + ",computer").Children.Find(Conversions.ToString(strGroupName), "group")
        Dim source As IEnumerable(Of DirectoryEntry) = Me.GetGroupMembers(dirGroup).Where(Function(objGroupMember As DirectoryEntry) Operators.CompareString(objGroupMember.Name.ToUpper(), Me.Username.ToUpper(), False) = 0)
        Return source.Count() = 1
    End Function

    Private Function GetGroupMembers(dirGroup As DirectoryEntry) As List(Of DirectoryEntry)
        Dim enumerable As IEnumerable = CType(dirGroup.Invoke("members", Nothing), IEnumerable)
        Dim list As List(Of DirectoryEntry) = New List(Of DirectoryEntry)()

        For Each obj As Object In enumerable
            Dim objectValue As Object = RuntimeHelpers.GetObjectValue(obj)
            Dim item As DirectoryEntry = New DirectoryEntry(RuntimeHelpers.GetObjectValue(objectValue))
            list.Add(item)
        Next
        Return list
    End Function

    Public Function AddToGroup(strGroupName As Object) As Boolean
        Dim result As Boolean = False
        Dim directoryEntry As DirectoryEntry = New DirectoryEntry("WinNT://" + Environment.MachineName + ",computer")
        Try
            directoryEntry.Children.Find(Conversions.ToString(Operators.ConcatenateObject(strGroupName, ",group"))).Invoke("Add", New Object() {Me.Path.ToString()})
            result = True
        Catch ex As Exception
            Me.Logger.WriteEntry(ex.[GetType]().ToString() + " - " + ex.Message)
            result = False
        End Try
        Return result
    End Function

    Public Function UnlockAccount() As Boolean
        Dim result As Boolean = False
        Try
            Dim directoryEntry As DirectoryEntry = New DirectoryEntry(Me.Path)
            If Conversions.ToInteger(directoryEntry.Properties("lockoutTime").Value) > 0 Then
                Me.Logger.WriteEntry("Account is locked. Unlocking")
                directoryEntry.Properties("lockoutTime").Value = 0
                directoryEntry.CommitChanges()
                directoryEntry.Close()
            Else
                Me.Logger.WriteEntry("Account is not locked.")
            End If
            Return True
        Catch ex As Exception
            Me.Logger.WriteEntry(ex.[GetType]().ToString() + " - " + ex.Message)
            result = False
        End Try
        Return result
    End Function

    Public Function SetPassword(password As String) As Boolean
        Me.Password = password
        Me.Logger.WriteEntry("setting password to: " + password)
        Process.Start("Cmd", "/c net user " + Me.Username + " " + Me.Password)
    End Function

    Public Function IsLoggedOn() As Boolean
        Dim managementObjectCollection As ManagementObjectCollection = New ManagementObjectSearcher("Select * from Win32_Process where Name = 'explorer.exe'").[Get]()
        Try
            For Each managementBaseObject As ManagementBaseObject In managementObjectCollection
                Dim managementObject As ManagementObject = CType(managementBaseObject, ManagementObject)
                Dim array As String() = New String(2) {}
                managementObject.InvokeMethod("GetOwner", array)
                Dim text As String = array(1).ToUpper() + "\" + array(0).ToUpper()
                Me.Logger.WriteEntry(text)
                Dim text2 As String = Environment.MachineName.ToUpper() + "\" + Me.Username.ToUpper()
                Me.Logger.WriteEntry(text2)
                If Operators.CompareString(text, text2, False) = 0 Then
                    Return True
                End If
            Next
        Finally
            Dim enumerator As ManagementObjectCollection.ManagementObjectEnumerator
            If enumerator IsNot Nothing Then
                CType(enumerator, IDisposable).Dispose()
            End If
        End Try
        Return False
    End Function


End Class
