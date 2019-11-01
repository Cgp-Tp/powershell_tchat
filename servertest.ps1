Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

Function Receive-TCPMessage {
    Param ( 
        [Parameter(Mandatory=$true, Position=0)]
        [ValidateNotNullOrEmpty()] 
        [int] $Port
    ) 
    Process {
        Try { 
            # Set up endpoint and start listening
            while($true){
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
                    Write-Output $data
                }
         
                # Close TCP connection and stop listening
                $stream.close()
                $listener.stop()
            }
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



$Form                            = New-Object system.Windows.Forms.Form
$Form.ClientSize                 = '403,400'
$Form.text                       = "Form"
$Form.TopMost                    = $false

$btnEnvoi                        = New-Object system.Windows.Forms.Button
$btnEnvoi.text                   = "Envoyer"
$btnEnvoi.width                  = 106
$btnEnvoi.height                 = 30
$btnEnvoi.location               = New-Object System.Drawing.Point(269,353)
$btnEnvoi.Font                   = 'Microsoft Sans Serif,10'

$Label2                          = New-Object system.Windows.Forms.Label
$Label2.text                     = "Bonjour je suis le label 2"
$Label2.AutoSize                 = $true
$Label2.width                    = 363
$Label2.height                   = 293
$Label2.location                 = New-Object System.Drawing.Point(106,64)
$Label2.Font                     = 'Microsoft Sans Serif,10'

$btnEnvoi.Add_Click({

Send-TCPMessage -Port 29800 -Endpoint 192.168.10.5 -message 'coucou'
$Label2.Text = "Coucou"

})


$Form.controls.AddRange(@($btnEnvoi, $Label2))

$Form.AutoSize = $true
$Form.ShowDialog()

Receive-TCPMessage -Port 29800
