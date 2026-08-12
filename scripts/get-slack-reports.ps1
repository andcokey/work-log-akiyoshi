#Requires -Version 5.1
<#
.SYNOPSIS
    Slack の日報チャンネルから出退勤時刻を抽出し JSON 化

.DESCRIPTION
    毎晩実行（Task Scheduler または Cron）
    日報テキストから出勤～退勤時刻を自動抽出して JSON に保存

.EXAMPLE
    .\get-slack-reports.ps1 -Token $env:SLACK_TOKEN -ChannelId C08PR2CPL8J -OutPath ./worklog.json
#>

param(
    [string]$Token = $env:SLACK_TOKEN,
    [string]$ChannelId = "C08PR2CPL8J",
    [string]$OutPath = "$PSScriptRoot\worklog.json",
    [int]$DaysBack = 30  # 過去 30 日分を取得
)

function ConvertFrom-SlackTimestamp {
    param([string]$Timestamp)
    [DateTimeOffset]::FromUnixTimeSeconds([long]$Timestamp.Split(".")[0]).DateTime
}

function ExtractTimeFromText {
    param([string]$Text)

    # 【日報YYYYMMDD】形式で日付を抽出
    if ($Text -match "【日報(\d{8})") {
        $dateStr = $matches[1]
        $date = [datetime]::ParseExact($dateStr, "yyyyMMdd", $null)
    } else {
        return $null
    }

    # タスク時刻パターン: "タスク名 -HHMM"
    $times = @()
    [regex]::Matches($Text, '-(\d{4})(?:\s|$)') | ForEach-Object {
        $times += $_.Groups[1].Value
    }

    if ($times.Count -lt 2) {
        return $null
    }

    # 最初のタスク時刻 = 出勤時刻
    # 最後のタスク時刻 = 退勤時刻
    $startTimeStr = $times[0]
    $endTimeStr = $times[-1]

    # HHMM → HH:MM 変換
    $startTime = "{0:d2}:{1:d2}" -f ([int]$startTimeStr.Substring(0,2)), ([int]$startTimeStr.Substring(2,2))
    $endTime = "{0:d2}:{1:d2}" -f ([int]$endTimeStr.Substring(0,2)), ([int]$endTimeStr.Substring(2,2))

    return @{
        date = $date.ToString("yyyy-MM-dd")
        startTime = $startTime
        endTime = $endTime
    }
}

# Slack API 呼び出し
try {
    $headers = @{
        "Authorization" = "Bearer $Token"
        "Content-Type" = "application/x-www-form-urlencoded"
    }

    Write-Host "Slack API: チャンネルメッセージ取得中..." -ForegroundColor Cyan

    # 過去 30 日分を取得
    $oldest = ([datetime]::Now.AddDays(-$DaysBack) - [datetime]"1970-01-01").TotalSeconds

    $response = Invoke-RestMethod -Uri "https://slack.com/api/conversations.history" `
        -Headers $headers `
        -Body "channel=$ChannelId&limit=100&oldest=$oldest" `
        -Method Post

    if (-not $response.ok) {
        throw "Slack API エラー: $($response.error)"
    }

    Write-Host "取得: $($response.messages.Count) メッセージ" -ForegroundColor Green

    # 日報パターンにマッチするメッセージをフィルター
    $reports = @()

    $response.messages | Where-Object { $_.text -match "【日報\d{8}" } | ForEach-Object {
        $extracted = ExtractTimeFromText -Text $_.text

        if ($extracted) {
            $extracted.ts = ConvertFrom-SlackTimestamp -Timestamp $_.ts
            $reports += $extracted
        }
    }

    # 日付でソート
    $reports = $reports | Sort-Object date -Unique

    Write-Host "抽出: $($reports.Count) 件の日報" -ForegroundColor Green

    # JSON 化
    $json = @{
        lastUpdated = (Get-Date).ToString("o")
        dataCount = $reports.Count
        data = $reports
    } | ConvertTo-Json

    # 出力
    $json | Out-File -FilePath $OutPath -Encoding utf8 -Force
    Write-Host "保存: $OutPath" -ForegroundColor Green

    # サマリー表示
    if ($reports.Count -gt 0) {
        Write-Host "`n最新 5 件:" -ForegroundColor Cyan
        $reports | Select-Object -Last 5 | Format-Table date, startTime, endTime
    }

} catch {
    Write-Error "エラー: $_"
    exit 1
}
