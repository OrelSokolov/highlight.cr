' Сервис пользователей
Imports System
Imports System.Collections.Generic
Imports System.Linq

Namespace App.Services

    Public Class UserService
        Implements IDisposable

        Private ReadOnly _users As New List(Of String)()
        Public Const MAX_AGE As Integer = 100
        Public Shared InstanceCount As Integer = 0

        Public Sub New(Optional ByVal capacity As Integer = 10)
            If capacity < 0 Then Throw New ArgumentOutOfRangeException(NameOf(capacity))
            InstanceCount += 1
        End Sub

        Public Function FindUsers(ByVal minAge As Integer) As List(Of String)
            Dim query = From u In _users
                        Where u.Length > 2 AndAlso Not u.StartsWith("x")
                        Select u.ToUpper()
            Return query.ToList()
        End Function

        Public Property Name As String = "default"

        Public Sub Dispose() Implements IDisposable.Dispose
            Console.WriteLine("disposed")
        End Sub

    End Class

    Public Structure Point
        Public X, Y As Double
    End Structure

End Namespace
