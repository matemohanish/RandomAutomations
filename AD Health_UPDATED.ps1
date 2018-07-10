#file path
Write-Verbose "Setting File path"
$reportpath = "D:\AD_Health.txt"

if((test-path $reportpath) -like $false)
{
Write-Verbose "Creating New File"

new-item $reportpath -type file

}
else
{
Write-Verbose "File Exist, Deleting file"

Remove-Item $reportpath 

new-item $reportpath -type file

}
 
#import Module 

Write-Verbose -Message "Importing active directory module"
if (! (Get-Module ActiveDirectory) ) 
 {
    Import-Module ActiveDirectory -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
    Write-Host ("[SUCCESS]") ("ActiveDirectory Powershell Module Loaded")
    Write-Verbose -Message "Active directory Module import successfully"  
 }
else 
 { 
      Write-Host ("[INFO]") ("ActiveDirectory Powershell Module Already Loaded")
      Write-Verbose -Message "ActiveDirectory Powershell Module Already Loaded"
  }

#get-domain controller 
      Write-Verbose "selecting Domain controllers"

      $DC = Get-ADDomainController -Filter * -Computername $server

#foreach domain controller 
foreach ($Dcserver in $dc.hostname){
if (Test-Connection -ComputerName $Dcserver -Count 4 -Quiet)
 {
  try
     {

 # Netlogon Service Status  
   
      Write-Verbose "checking status of netlogon"

      $DcNetlogon = Get-Service -ComputerName $Dcserver -Name "Netlogon" -ErrorAction SilentlyContinue
   
          if ($DcNetlogon.Status -eq "Running")
           {
             $setnetlogon = "ok"
           }
   
          else  
           {
             $setnetlogon = "$DcNetlogon.status"
           }

 #NTDS Service Status

     Write-Verbose "checking status of NTDS"

     $dcntds = Get-Service -ComputerName $Dcserver -Name "NTDS" -ErrorAction SilentlyContinue 

         if ($dcntds.Status -eq "running")
          {
            $setntds = "ok"
           }

         else 
          {
            $setntds = "$dcntds.status"
          }

   #DNS Service Status 
   
      Write-Verbose "checking status of DNS"

      $dcdns = Get-Service -ComputerName $Dcserver -Name "DNS" -ea SilentlyContinue 
   
         if ($dcdns.Status -eq "running")
          {
              $setdcdns = "ok"                    
          }

         else
          {
             $setdcdns = "$dcdns.Status"
          }
    
   #Dcdiag netlogons "Checking now"
     
     Write-Verbose "Checking Status of netlogns"

     $dcdiagnetlogon = dcdiag /test:netlogons /s:$dcserver
         if ($dcdiagnetlogon -match "passed test NetLogons")
          {
            $setdcdiagnetlogon = "ok"
          }
         else
           {
            $setdcdiagnetlogon = $dcdiagnetlogon 
           }

   #Dcdiag services check

   Write-Verbose "Checking status of DCdiag Services"

   $dcdiagservices = dcdiag /test:services /s:$dcserver

         if ($dcdiagservices -match "passed test services")
          {
            $setdcdiagservices = "ok"
          }
         else
          {
            $setdcdiagservices = $dcdiagservices 
          }

   
   #Dcdiag Replication Check

   Write-Verbose "Checking status of DCdiag Replication"

   $dcdiagreplications = dcdiag /test:Replications /s:$dcserver

         if ($dcdiagreplications -match "passed test Replications")
          {
            $setdcdiagreplications = "ok"
          }
         else
          {
            $setdcdiagreplications = $dcdiagreplications 
          }

   #Dcdiag FSMOCheck Check

   Write-Verbose "Checking status of DCdiag FSMOCheck"

   $dcdiagFsmoCheck = dcdiag /test:FSMOCheck /s:$dcserver

         if ($dcdiagFsmoCheck -match "passed test FsmoCheck")
          {
            $setdcdiagFsmoCheck = "ok"
          }
         else
          {
            $setdcdiagFsmoCheck = $dcdiagFsmoCheck 
          }

   #Dcdiag Advertising Check

   Write-Verbose "Checking status of DCdiag Advertising"

   $dcdiagAdvertising = dcdiag /test:Advertising /s:$dcserver

         if ($dcdiagAdvertising -match "passed test Advertising")
          {
            $setdcdiagAdvertising = "ok"
          }
         else
          {
            $setdcdiagAdvertising = $dcdiagAdvertising 
          }
  
    $tryok = "ok"

  }
 catch 
    {
    
    $ErrorMessage = $_.Exception.Message

    }
 if ($tryok -eq "ok"){
    #new-object Created

$csvObject = New-Object PSObject

Add-Member -inputObject $csvObject -memberType NoteProperty -name "DCName" -value $dcserver
Add-Member -inputObject $csvObject -memberType NoteProperty -name "Netlogon" -value $setnetlogon
Add-Member -inputObject $csvObject -memberType NoteProperty -name "NTDS" -value $setntds
Add-Member -inputObject $csvObject -memberType NoteProperty -name "DNS" -value $setdcdns
Add-Member -inputObject $csvObject -memberType NoteProperty -name "Dcdiag_netlogons" -value $setdcdiagnetlogon
Add-Member -inputObject $csvObject -memberType NoteProperty -name "Dcdiag_Services" -value $setdcdiagservices
Add-Member -inputObject $csvObject -memberType NoteProperty -name "Dcdiag_replications" -value $setdcdiagreplications
Add-Member -inputObject $csvObject -memberType NoteProperty -name "Dcdiag_FSMOCheck" -value $setdcdiagFsmoCheck
Add-Member -inputObject $csvObject -memberType NoteProperty -name "DCdiag_Advertising" -value $setdcdiagAdvertising

#set DC status 

$setdcstatus = "ok"

 }
 }
else
 {
#if Server Down
Write-Verbose "Server Down"

$setdcstatus = "$dcserver is down"

Add-Member -inputObject $csvObject -memberType NoteProperty -name "Server_down" -value $setdcstatus
   
 }
#Output of Property
}
$csvobject  | ft -AutoSize | Out-file "$reportpath"