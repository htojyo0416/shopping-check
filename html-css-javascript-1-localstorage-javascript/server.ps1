$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$Port = 4173
$IndexFile = Join-Path $Root "index.html"

if (-not (Test-Path -LiteralPath $IndexFile)) {
  Write-Host "index.html was not found." -ForegroundColor Red
  Read-Host "Press Enter to close"
  exit 1
}

$Listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Any, $Port)
$Listener.Start()

Write-Host ""
Write-Host "Shopping app server is running." -ForegroundColor Green
Write-Host "PC:    http://127.0.0.1:$Port"

$Addresses = [System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces() |
  Where-Object { $_.OperationalStatus -eq "Up" } |
  ForEach-Object { $_.GetIPProperties().UnicastAddresses } |
  Where-Object { $_.Address.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork -and -not [System.Net.IPAddress]::IsLoopback($_.Address) } |
  ForEach-Object { $_.Address.ToString() } |
  Sort-Object -Unique

foreach ($Address in $Addresses) {
  Write-Host "Phone: http://$Address`:$Port" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "Keep this window open while using the app on your phone."
Write-Host "Close this window to stop the server."
Write-Host ""

try {
  while ($true) {
    $Client = $Listener.AcceptTcpClient()
    try {
      $Stream = $Client.GetStream()
      $Reader = [System.IO.StreamReader]::new($Stream)
      $RequestLine = $Reader.ReadLine()

      while ($Reader.Peek() -ge 0) {
        $Line = $Reader.ReadLine()
        if ([string]::IsNullOrEmpty($Line)) { break }
      }

      $Path = "/"
      if ($RequestLine -match "^\w+\s+([^\s]+)") {
        $Path = $Matches[1].Split("?")[0]
      }

      if ($Path -eq "/" -or $Path -eq "/index.html") {
        $Body = [System.IO.File]::ReadAllBytes($IndexFile)
        $Header = "HTTP/1.1 200 OK`r`nContent-Type: text/html; charset=utf-8`r`nContent-Length: $($Body.Length)`r`nCache-Control: no-store`r`nConnection: close`r`n`r`n"
      } else {
        $Text = [System.Text.Encoding]::UTF8.GetBytes("Not found")
        $Body = $Text
        $Header = "HTTP/1.1 404 Not Found`r`nContent-Type: text/plain; charset=utf-8`r`nContent-Length: $($Body.Length)`r`nConnection: close`r`n`r`n"
      }

      $HeaderBytes = [System.Text.Encoding]::ASCII.GetBytes($Header)
      $Stream.Write($HeaderBytes, 0, $HeaderBytes.Length)
      $Stream.Write($Body, 0, $Body.Length)
      $Stream.Flush()
    } finally {
      $Client.Close()
    }
  }
} finally {
  $Listener.Stop()
}
