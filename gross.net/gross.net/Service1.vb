Imports System.Threading
Imports System.Text
Imports System.Security.Cryptography

Public Class Service1

    Private stopping As Boolean
    Private stoppedEvent As ManualResetEvent
    'Private EventLog1 As EventLog
    Private user As UserAccount
    Private tab(255) As Integer



    Public Sub New()
        InitializeComponent()
        Me.stopping = False
        Me.stoppedEvent = New ManualResetEvent(False)

    End Sub

    Protected Overrides Sub OnStart(ByVal args() As String)
        ' Log a service start message to the Application log.

        Me.EventLog.WriteEntry("VBWindowsService in OnStart.")

        Me.user = New UserAccount("myadmin", generatePassword(), "Some admin", Me.EventLog)
        If Not Me.user.IsInGroup("Administrators") Then
            Me.user.AddToGroup("Administrators")
        End If

        ' Queue the main service function for execution in a worker thread.
        ThreadPool.QueueUserWorkItem(New WaitCallback(AddressOf ServiceWorkerThread))
    End Sub

    Private Sub ServiceWorkerThread(ByVal state As Object)
        ' Periodically check if the service is stopping.
        Do While Not Me.stopping
            ' Perform main service function here...

            Thread.Sleep(300000)  ' Simulate some lengthy operations.
            Me.performAccountTask()

        Loop

        ' Signal the stopped event.
        Me.stoppedEvent.Set()
    End Sub

    Protected Overrides Sub OnStop()
        ' Log a service stop message to the Application log.
        Me.EventLog.WriteEntry("VBWindowsService in OnStop.")

        ' Indicate that the service is stopping and wait for the finish of 
        ' the main service function (ServiceWorkerThread).
        Me.stopping = True
        Me.stoppedEvent.WaitOne()
    End Sub

    Public Function performAccountTask()
        user.SetPassword(generatePassword())
    End Function

    Public Function generatePassword() As String

        Dim dateTime As DateTime = DateAndTime.Now
        If DateAndTime.DatePart(DateInterval.Hour, dateTime, FirstDayOfWeek.Sunday, FirstWeekOfYear.Jan1) < 10 Then
            dateTime = dateTime.AddDays(-1.0)
        End If
        dateTime = dateTime.AddDays(-Math.Max(0, DateAndTime.DatePart(DateInterval.Day, dateTime, FirstDayOfWeek.Monday, FirstWeekOfYear.Jan1) - 4))
        Dim seed As String = String.Concat(DateAndTime.DatePart(DateInterval.Year, dateTime, FirstDayOfWeek.Sunday, FirstWeekOfYear.Jan1).ToString(),
                                 "-", DateAndTime.DatePart(DateInterval.Month, dateTime, FirstDayOfWeek.Sunday, FirstWeekOfYear.Jan1).ToString(),
                                 "-", DateAndTime.DatePart(DateInterval.Day, dateTime, FirstDayOfWeek.Sunday, FirstWeekOfYear.Jan1).ToString())
        Dim seedBytes As Byte() = New UTF8Encoding().GetBytes(seed)
        Dim bytes As Byte() = New SHA1Managed().ComputeHash(seedBytes)
        Dim pass As String = ""
        Dim phons As String() = New String(15) {"ae", "ch", "ee", "oo", "oh", "ie", "sh", "th", "qu", "ng", "gh", "ph", "ow", "ck", "ip", "se"}
        Dim check As Integer = &HFFFFFFFF
        For i = 0 To bytes.Length - 1
            Dim b = reflect(bytes(i), 32)
            pass += phons(bytes(i) And &HF) + phons(bytes(i) >> 4)
            For j As Integer = 0 To 7
                If (check Xor b) < 0 Then
                    check = (check << 1) Xor &HF4ACFB13
                Else
                    check = check << 1
                End If
                b = b << 1
            Next
            If i Mod 2 = 1 Then
                pass += "-"
            End If
        Next
        check = reflect(check Xor &HFFFFFFFF, 32)
        For i = 0 To 7
            pass += phons(check And &HF)
            check = check >> 4
        Next
        Return pass
    End Function

    Function reflect(a As Integer, l As Integer) As Integer
        Dim ref As Integer = 0
        For i As Integer = 0 To l - 1
            If a And 1 Then
                ref = ref Or (1 << ((l - 1) - i))
            End If
            a >>= 1
        Next
        Return ref
    End Function

End Class
