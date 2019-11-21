#Define external parameters
Param(

   [Parameter(Position=1)]
   [string]$arg1,
   [Parameter(Position=2)]
   [string]$arg2

)
#Get diskpart output
$dp = "list volume" | diskpart | ? { $_ -match "^ [^-]" }

#Define counters
$checksum = 0
$idx = 0
$counter = 0

# Count raid volumes
foreach ($row in $dp){
 # skip first line
 if (!$row.Contains("Том    ###|Volume     ###")) {
 # best match RegExp from http://www.eventlogblog.com/blog/2012/02/how-to-make-the-windows-softwa.html
 if ($row -match "\s\s((Том|Volume)\s\d)\s+([A-Za-z]|\s)\s+(.*)\s\s(NTFS|FAT|RAW)\s+(Mirror|Зеркальный|RAID-5|Чередование|Stripe|Spiegel|Spiegelung|Ubergreifend|Spanned|Составной)\s+(\d+)\s+(..)\s\s([A-Za-zА-Яа-я]*\s?[A-Za-zА-Яа-я]*)(\s\s)*.*") {
 $disk = $matches[3]
 # 0 = OK, 1 = WARNING, 2 = CRITICAL
 $statusCode = 1
 $status = "WARNING"
 $text = "Could not parse line: $row"
 $line = $row
 $counter++
 }
 }
 }


if (!$arg1) {
write-host "{"
write-host " `"data`":[`n"
}

#Generate data
foreach ($row in $dp){
 # skip first line
 if (!$row.Contains("Том    ###|Volume     ###")) {
 # best match RegExp from http://www.eventlogblog.com/blog/2012/02/how-to-make-the-windows-softwa.html
 if ($row -match "\s\s((Том|Volume)\s\d)\s+([A-Za-z]|\s)\s+(.*)\s\s(NTFS|FAT|RAW)\s+(Mirror|Зеркальный|RAID-5|Чередование|Stripe|Spiegel|Spiegelung|Ubergreifend|Spanned|Составной)\s+(\d+)\s+(..)\s\s([A-Za-zА-Яа-я]*\s?[A-Za-zА-Яа-я]*)(\s\s)*.*") {
 $disk = $matches[3]
 # 0 = OK, 1 = WARNING, 2 = CRITICAL
 $statusCode = 1
 $status = "WARNING"
 $text = "Could not parse line: $row"
 $line = $row
 #Get Volume numbers
 $number=$matches[1]
 $number -match "\d" | Out-Null
 $number=$matches[0]

 if ($line -match "Fehlerfre |OK|Healthy|Исправен") {
 $statusText = "is healthy"
 $statusCode = 0
 $status = "OK"
 }
 elseif ($line -match "Rebuild|Перестроение") {
 $statusText = "is rebuilding"
 $statusCode = 1
 $checksum++
 }
 elseif ($line -match "Failed|At Risk|Fehlerhaf|Ошибка чт") {
 $statusText = "failed"
 $statusCode = 2
 $status = "CRITICAL"
 $checksum++
 }
 #Checking external parameters
 if (($arg1) -and (!$arg2)) {
 if (($line -match " $arg1 ") -and ($arg1 -match "\d")){
  echo $status
  }
 }
 #Define types
 if ($line -match "Mirror|Зеркальный") {
 $type= "Mirror"
 }

 if ($line -match "RAID-5") {
 $type= "RAID-5"
 }
 if ($line -match "Чередование|Stripe|Spiegel|Spiegelung") {
 $type= "Stripe"
 }

 if ($line -match "Ubergreifend|Spanned|Составной") {
 $type= "Spanned"
 }
 #Checking external parameters
 if (($arg2 -eq "type") -and ($line -match " $arg1 ") -and ($arg1 -match "\d")) {
 echo $type
 }

 if ($disk -eq " ") {
 $disk="Unnamed"
 }

 if (($arg2 -eq "name") -and ($line -match " $arg1 ") -and ($arg1 -match "\d")) {
 echo $disk
 }

 if (!$arg1) {
 $jsonline= "`t{`n " +
            "`t`t`"{#VOLUMENAME}`":`""+$disk+"`""+ ",`n" +
	    "`t`t`"{#VOLUMENUMBER}`":`""+$number+"`""+ ",`n" +
            "`t`t`"{#STATUS}`":`""+$status+"`""+ ",`n" +  
            "`t`t`"{#TYPE}`":`""+$type+"`""+ "`n" +       
            "}"

 if ($idx -lt $counter - 1)
    {
       $jsonline += ",`n"
    }
    elseif ($idx -ge  $counter - 1)
    {
    
    }

  write-host $jsonline
  $idx++
 # Testing
 # echo "$statusCode microsoft_software_raid - $status - Software RAID on disk ${disk}:\ $statusText"

}

 }


}

}

if (!$arg1) {

write-host
write-host " ]"
write-host "}"
}
