Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$Form                            = New-Object system.Windows.Forms.Form
$Form.ClientSize                 = '520,261'
$Form.text                       = "Form"
$Form.TopMost                    = $false

$Button1                         = New-Object system.Windows.Forms.Button
$Button1.text                    = "Envoyer"
$Button1.width                   = 88
$Button1.height                  = 51
$Button1.location                = New-Object System.Drawing.Point(419,196)
$Button1.Font                    = 'Microsoft Sans Serif,10'

$ListBox1                        = New-Object system.Windows.Forms.ListBox
$ListBox1.text                   = "listBox"
$ListBox1.width                  = 496
$ListBox1.height                 = 166
$ListBox1.location               = New-Object System.Drawing.Point(13,16)

$TextBoxNom                      = New-Object system.Windows.Forms.TextBox
$TextBoxNom.multiline            = $false
$TextBoxNom.width                = 90
$TextBoxNom.height               = 20
$TextBoxNom.location             = New-Object System.Drawing.Point(84,196)
$TextBoxNom.Font                 = 'Microsoft Sans Serif,10'

$Label1                          = New-Object system.Windows.Forms.Label
$Label1.text                     = "Message"
$Label1.AutoSize                 = $true
$Label1.width                    = 25
$Label1.height                   = 10
$Label1.location                 = New-Object System.Drawing.Point(16,231)
$Label1.Font                     = 'Microsoft Sans Serif,10'

$TextBoxMessage                  = New-Object system.Windows.Forms.TextBox
$TextBoxMessage.multiline        = $false
$TextBoxMessage.width            = 318
$TextBoxMessage.height           = 20
$TextBoxMessage.location         = New-Object System.Drawing.Point(84,226)
$TextBoxMessage.Font             = 'Microsoft Sans Serif,10'

$Label2                          = New-Object system.Windows.Forms.Label
$Label2.text                     = "Nom"
$Label2.AutoSize                 = $true
$Label2.width                    = 25
$Label2.height                   = 10
$Label2.location                 = New-Object System.Drawing.Point(16,202)
$Label2.Font                     = 'Microsoft Sans Serif,10'

$lbl_info                        = New-Object system.Windows.Forms.Label
$lbl_info.text                   = ""
$lbl_info.AutoSize               = $true
$lbl_info.width                  = 25
$lbl_info.height                 = 10
$lbl_info.location               = New-Object System.Drawing.Point(89,253)
$lbl_info.Font                   = 'Microsoft Sans Serif,10'

$Form.controls.AddRange(@($Button1,$ListBox1,$TextBoxNom,$Label1,$TextBoxMessage,$Label2,$lbl_info))

$Form.AutoSize = $true

$Script:bool = $true

Function Receive-TCPMessage {
    Param ( 
        [Parameter(Mandatory=$true, Position=0)]
        [ValidateNotNullOrEmpty()] 
        [int] $Port
    ) 
    Process {
        Try { 
            # Set up endpoint and start listening
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
                    #Write-Host $data 
                }
               
                $data               
                
                # Close TCP connection and stop listening
                $stream.close()
                $listener.stop()                
        }
        Catch {
            "Receive Message failed with: `n" + $Error[0]
        }
    }
}

Function Send-TCPMessage { 
    Param ( 
            [Parameter(Mandatory=$true, Position=0)]
            [ValidateNotNullOrEmpty()] 
            [string] 
            $EndPoint
        , 
            [Parameter(Mandatory=$true, Position=1)]
            [int]
            $Port
        , 
            [Parameter(Mandatory=$true, Position=2)]
            [string]
            $Message
    ) 
    Process {
        # Setup connection 
        $IP = [System.Net.Dns]::GetHostAddresses($EndPoint) 
        $Address = [System.Net.IPAddress]::Parse($IP) 
        $Socket = New-Object System.Net.Sockets.TCPClient($Address,$Port) 
    
        # Setup stream wrtier 
        $Stream = $Socket.GetStream() 
        $Writer = New-Object System.IO.StreamWriter($Stream)

        # Write message to stream
        $Message | % {
            $Writer.WriteLine($_)
            $Writer.Flush()
        }
    
        # Close connection and stream
        $Stream.Close()
        $Socket.Close()
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
		Start-Sleep -Milliseconds 100
	} while (!$BackgroundJob.IsCompleted)
    
    $Result = $Powershell.EndInvoke($BackgroundJob)
	
	#Clean up
	$Powershell.Dispose() | Out-Null
	$Runspace.Close() | Out-Null
    #Return our results to the GUI
	$Result
    
}

Function serveur {
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
        }
        $Form.ResumeLayout()
}

$Form.Add_FormClosing({ 
    $Script:bool = $false
    Send-TCPMessage -Port 29800 -Endpoint 127.0.0.1 -message "Arret du serveur.." 
})

$Button1.Add_Click({
    if(($TextBoxNom.Text -ne "") -and ($TextBoxMessage.Text -ne "")) { 
        Send-TCPMessage -Port 29800 -Endpoint 192.168.0.22 -message ("$($TextBoxNom.Text): $($TextBoxMessage.Text)")
        $ListBox1.Items.Add("$($TextBoxNom.Text): $($TextBoxMessage.Text)")
        $TextBoxMessage.Clear()
        $lbl_info.Text = "Message envoyer !"
    } else {
        $lbl_info.Text = "Vous devez entrez votre nom ET un message"
    }
})

$Form.Add_Shown({
    while($bool){
        Start-Sleep -Milliseconds 10
        serveur
    }
})

$Form.ShowDialog()


