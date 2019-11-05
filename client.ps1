Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()


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
$Form.BackColor                  = "#EFEBEB"
$Form.text                       = "Form"
$Form.TopMost                    = $false

$TextBoxMessage                  = New-Object system.Windows.Forms.TextBox
$TextBoxMessage.multiline        = $false
$TextBoxMessage.width            = 248
$TextBoxMessage.height           = 20
$TextBoxMessage.location         = New-Object System.Drawing.Point(8,359)
$TextBoxMessage.Font             = 'Microsoft Sans Serif,10'

$btnEnvoi                        = New-Object system.Windows.Forms.Button
$btnEnvoi.text                   = "Envoyer"
$btnEnvoi.width                  = 106
$btnEnvoi.height                 = 30
$btnEnvoi.location               = New-Object System.Drawing.Point(269,353)
$btnEnvoi.Font                   = 'Microsoft Sans Serif,10'

$Nom                             = New-Object system.Windows.Forms.Label
$Nom.text                        = "Nom:"
$Nom.AutoSize                    = $true
$Nom.width                       = 25
$Nom.height                      = 10
$Nom.location                    = New-Object System.Drawing.Point(20,323)
$Nom.Font                        = 'Microsoft Sans Serif,10'

$TextBoxNom                      = New-Object system.Windows.Forms.TextBox
$TextBoxNom.multiline            = $false
$TextBoxNom.width                = 100
$TextBoxNom.height               = 20
$TextBoxNom.location             = New-Object System.Drawing.Point(83,320)
$TextBoxNom.Font                 = 'Microsoft Sans Serif,10'

$ListBoxMsg                        = New-Object system.Windows.Forms.ListBox
$ListBoxMsg.text                   = "listBox"
$ListBoxMsg.width                  = 350
$ListBoxMsg.height                 = 262
$ListBoxMsg.location               = New-Object System.Drawing.Point(19,22)


$btnEnvoi.add_Click({
$ListBoxMsg.Items.Add("$($TextBoxNom.Text): $($TextBoxMessage.Text)")
Send-TCPMessage -Port 29800 -Endpoint 192.168.0.22 -message ("$($TextBoxNom.Text): $($TextBoxMessage.Text)")
$TextBoxMessage.Clear()
})



$Form.controls.AddRange(@($TextBoxMessage,$btnEnvoi,$Label2,$Nom,$TextBoxNom,$ListBoxMsg))

$Form.AutoSize = $true
$Form.ShowDialog()