################
# Scripts name : check-service.ps1
# Usage        : ./check-service.ps1
#                同一ディレクトリにcheck-service.confを配置し、タスクスケジューラーで定期実行する。
#                事前にAdmin権限で以下コマンドをを実行すること。
#                New-EventLog -LogName Application -Source "Service Check Script"
# Description  : Windowsサービスチェックスクリプト
# Create       : 2022/05/02 tech-mmmm (https://tech-mmmm.blogspot.com/)
# Modify       : 
################

$currentdir = Split-Path -Parent $MyInvocation.MyCommand.Path
$conffile = $currentdir + "\check-service.conf"    # 設定ファイル
$tmpfile = $currentdir + "\check-service.tmp"      # サービス情報保存用一時ファイル
$event_source = "Service Check Script"             # スクリプトソース名

# すでにDownしているサービス情報を取得
if ( Test-Path -Path $tmpfile ){
    $down_service = Get-Content $tmpfile
}
Write-Output $null | Out-File $tmpfile

# 設定ファイル読み込み
foreach ($line in (Get-Content $conffile)) {   
    # コメント行と空行を処理しない
    if ( $line -notmatch "^ *#|^$" ){
        # 現在のサービス数を取得
        $count = (Get-Service -Name $line | Where-Object { $_.Status -eq "Running" }).count
        
        # サービス数チェック
        if ( $count -lt 1 ){
            # Down時の処理
            # Downしているサービスか確認
            if ( $down_service -eq $line ){
                # すでにDown
                $message = "Service """ + $line + """ still down"
                $event_type = "Information"
            }else{
                # 初回Down
                $message = "Service """ + $line + """ down"
                $event_type = "Error"
            }
            
            # イベントログに出力
            Write-Output $message
            Write-EventLog -LogName Application -EntryType $event_type -Source $event_source -EventId 100 -Message $message

            # Donwしているサービス情報を出力
            Write-Output $line | Out-File -Append $tmpfile
        }else{
            # Up時の処理
            # Downしていたサービスか確認
            if ( $down_service -eq $line ){
                # Downだった
                $message = "Service """ + $line + """ up"
                $event_type = "Information"                
            }else{
                # すでにUp
                $message = "Service """ + $line + """ still up"
                $event_type = "Information"
            }

            # イベントログに出力
            Write-Output $message
            Write-EventLog -LogName Application -EntryType $event_type -Source $event_source -EventId 100 -Message $message
        }
    }
}

exit 0
