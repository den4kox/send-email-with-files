$id = "B2" # уникальный идентификатор перевозчика,  в соответствии с регламентом 
$fileTimeStampFormat = "_yyyy_MM_dd_HH_mm_ss_fff" # дата и время, указанные в имени файла, должны соответствовать дате и времени его формирования.
$fileExtension = ".edf" # расширение файла в соответствии с его содержимым, edf - для UN/EDIFACT 
$fromDir = "E:\scripts\sendSMTP\test\" # $fromDir = "c:\MSQLTB2\"    папка куда поступают файлы UN/EDIFACT в данном случае из модуля - SJPM
$mask = "*.txt" # фильтр файлов UN/EDIFACT. Если расширение исходного файла неизвестно, необходимо использовать *.*
$saveDir = "E:\scripts\sendSMTP\test\OUT\" # $saveDir = "c:\MSQLTB2\OUT\"    папка куда сохранять копии загруженных файлов
$smtp = "10.10.10.10" # SMTP server 
#my const
$body = "Please see attachment."
$temp = "$env:temp\"


$fpath = ".\log.txt" 
$onlyErrorLog = ".\onlyErrorLog.txt" 
$tos = @("email", "email", "email")
$countTo = $tos.Count
$failFolder = "UNSENT_FILES\" 

function getOrCreateFile($path){
    Write-Host $path
    if(-Not (Test-Path $fpath)) {
       Write-host "Файл $path не существует."
       Write-host "Создание файла..."
       New-Item $path -type file  | Out-Null
       Write-host "Файл $path создан!"
    }
    return $path | Out-Null
}

getOrCreateFile($fpath) | Out-Null
getOrCreateFile($onlyErrorLog) | Out-Null

function getOrCreateFolder{
    param( [string]$path, [string]$folder )
        if(-Not (Test-Path $path$folder)) {
       Write-host "Папка $folder в $path не существует."
       Write-host "Создание папки $folder ..."
       New-Item $path$folder -type directory  | Out-Null
       Write-host "Файл $path$folder создан!"
    }
    return $path+$folder
}

function resendFile{
    param( [string]$path )
    $listFolder = dir $path
    write-host $listFolder
}

function sendListFiles($listFiles){  
    $countFiles = 0
    $countFilesTrue = 0
    
    foreach ($file in $listFiles){
        $countFiles++
        $defName =  $file.ToString()
        $newFileName = $id+$file.CreationTime.ToString($fileTimeStampFormat)+$fileExtension
        $subject = "Belavia APIS - "+$newFileName 
        if(-Not (Test-Path $temp$newFileName)) {
            Copy-Item $file.fullName -Destination $temp$newFileName
        }
        $counterToTrue = 0 
        $countFlag=0
        $counterTo=0  
        foreach($to in $tos){
            $counterTo++
            $status = ""
            $errorDescription = ""
            $time = Get-Date -Format G
            try{
                Send-MailMessage -from "from@from.com" -to $to -subject $subject -body $body -Attachments $temp$newFileName -smtpServer $smtp -EA Stop
                
                $countFilesTrue++
                $counterToTrue++
                $countFlag = 1
                $status = "OKEY!"
                $errorDescription = "$to $defName => 'OUT/$newFileName'"
                $outMessage = "$status $time $errorDescription"
                Add-Content $fpath $outMessage    
            }Catch [System.Net.Mail.SmtpFailedRecipientException]{
                $status = "FAIL!"
                $errorDescription = "$to $defName Message: $_.Exception.Message"
                $outMessage = "$status $time $errorDescription"
                getOrCreateFolder $fromDir $failFolder | Out-Null
                getOrCreateFolder $fromDir$failFolder $to | Out-Null
                Copy-Item $file.fullName -Destination $fromDir$failFolder$to | Out-Null
                
                Add-Content $fpath $outMessage | Out-Null
                Add-Content $onlyErrorLog $outMessage | Out-Null
            }Catch [System.Net.Mail.SmtpException]{
                $status = "FAIL!"
                $errorDescription = "$to $defName Message: $_.Exception.Message"
                $outMessage = "$status $time $errorDescription"
               
                Add-Content $fpath $outMessage | Out-Null
                Add-Content $onlyErrorLog $outMessage | Out-Null            
            }Finally{
                Write-host $outMessage                
                if($counterTo -eq $countTo -and $countFlag -eq 1){
                    Move-Item $file.fullName $saveDir$newFileName
                }                       
            }
        }
                            
    }
    return $countFilesTrue       
}

sendListFiles(dir $fromDir $mask)



