Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$Form                            = New-Object system.Windows.Forms.Form
$Form.ClientSize                 = '341,218'
$Form.text                       = "Form"
$Form.TopMost                    = $false

$Button1                         = New-Object system.Windows.Forms.Button
$Button1.text                    = "button"
$Button1.width                   = 60
$Button1.height                  = 30
$Button1.location                = New-Object System.Drawing.Point(259,143)
$Button1.Font                    = 'Microsoft Sans Serif,10'

$Label1                          = New-Object system.Windows.Forms.Label
$Label1.text                     = "label"
$Label1.AutoSize                 = $true
$Label1.width                    = 25
$Label1.height                   = 10
$Label1.location                 = New-Object System.Drawing.Point(274,186)
$Label1.Font                     = 'Microsoft Sans Serif,10'

$ListBox1                        = New-Object system.Windows.Forms.ListBox
$ListBox1.text                   = "listBox"
$ListBox1.width                  = 239
$ListBox1.height                 = 123
$ListBox1.location               = New-Object System.Drawing.Point(13,16)

$Form.controls.AddRange(@($Button1,$Label1,$ListBox1))

$Form.AutoSize = $true

Function Receive-TCPMessage {
    Param ( 
        [Parameter(Mandatory=$true, Position=0)]
        [ValidateNotNullOrEmpty()] 
        [int] $Port
    ) 
    Process {
        Try { 
            # Set up endpoint and start listening
                        
            #while($true){
                $endpoint = new-object System.Net.IPEndPoint([ipaddress]::any,$port) 
                $listener = new-object System.Net.Sockets.TcpListener $EndPoint
                $listener.start() 
 
                # Wait for an incoming connection 
                $data = $listener.AcceptTcpClient() 
        
                # Stream setup
                $stream = $data.GetStream() 
                $bytes = New-Object System.Byte[] 1024

                # Read data from stream and write it to host
                while (($i = $stream.Read($bytes,0,$bytes.Length)) -ne 0){
                    $EncodedText = New-Object System.Text.ASCIIEncoding
                    $data = $EncodedText.GetString($bytes,0, $i)
                    Write-Host $data 
                }
               
                $data               
                
                # Close TCP connection and stop listening
                $stream.close()
                $listener.stop()
                #Get-EventLog -Message $Message -LogName Application
                
            #}
        }
        Catch {
            "Receive Message failed with: `n" + $Error[0]
        }
    }
}

Function Start-BackgroundJob {
	param(
		[ScriptBlock]
			$Job = {},
		$JobVariables = [HashTable]::Synchronized(@{})
	)
    
    #Create our runspace & a powershell object to run in
	$Runspace = [runspacefactory]::CreateRunspace()
	$Runspace.Open()
	
	$Powershell = [powershell]::Create()
	$Powershell.Runspace = $Runspace
    
    #Add code for the function to be run
	$Powershell.AddScript($Job) | Out-Null
    
    #Send variables across pipeline 1 by 1 and make them available for our imported function
	foreach ($Variable in $JobVariables.GetEnumerator()) {
		$Powershell.AddParameter($Variable.Name, $Variable.Value) | Out-Null
	}
	
	#Start job
	$BackgroundJob = $Powershell.BeginInvoke()
    
	#Wait for code to complete and keep UI responsive
	do {
		[System.Windows.Forms.Application]::DoEvents()
		Start-Sleep -Milliseconds 1
	} while (!$BackgroundJob.IsCompleted)
    
    $Result = $Powershell.EndInvoke($BackgroundJob)
	
	#Clean up
	$Powershell.Dispose() | Out-Null
	$Runspace.Close() | Out-Null
    $Label1.Text = "Encore.."
    #Return our results to the GUI
	$Result
    
}

Function serveur {
    $Label1.Text = "En attente.."
    
    $Params = @{}
    $Params["Port"] = 29800
    $Script:Results = Start-BackgroundJob -Job ${Function:Receive-TCPMessage} -JobVariables $Params
    $Form.SuspendLayout()
    if($Results) { 
        $msg = ""
        foreach($i in $Results)
        {
            $msg = $msg + $i
        }
        $ListBox1.Items.Add($msg)
        $Label1.Text = "oui"
    } else {
        $Label1.Text = "non"
    }
    $Form.ResumeLayout()
}


$Button1.Add_Click({
    
})

$Form.Add_Shown({
    while($true) {
        serveur
    }
})

$Form.ShowDialog()


