<#

.NAME
AcronisAPILibrairy

.SYNOPSIS
PowerShell Librairy to access Acronis Cloud Backup API Service v1

.DESCRIPTION
PowerShell Librairy with CLI that allows flexible access to the Acronis Cloud Backup API Service v1
All function based in order to simplify compliance with the Acronis API. API Reference can be found at
http://dl.acronis.com/u/raml-console/1.0/?raml=https://us-cloud.acronis.com/api/1/raml/api.raml&withCredentials=true

.EXAMPLE
./AcronisAPILibrairy.ps1

.NOTES
You have the option to change your credentials and datacenter at any moments.
Licenced under the MIT Licence (https://choosealicense.com/licenses/mit/)

Copyright 2018 Olivier Toutant-Paradis

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

.LINK
https://github.com/holytoutant/AcronisAPIPowerShellLibrairy

#>

#Initialize system variables
#Clean-up all previously initialized variables
$AcronisURL = 'https://us-cloud.acronis.com/'
$APIVersion = '1'
[Microsoft.PowerShell.Commands.WebRequestSession]$nwebSession
$LastHttpRequestReply
[PSCredential] $AcronisCredentials
Clear-Variable -Name AcronisCredentials
Clear-Variable -Name nwebSession
Clear-Variable -Name LastHttpRequestReply
$firstRun = $true

Function Get-UserChoice
{
    param( [string]$initialMessage )

    clear

#Change and the reset color after displaying     
$t = $host.ui.RawUI.ForegroundColor
$host.ui.RawUI.ForegroundColor = "DarkGreen"
if($initialMessage -ne "" ){write-output $initialMessage}
$host.ui.RawUI.ForegroundColor = $t

if($Global:FirstRun){write-output "Welcome to this powershell tool to access Acronis Cloud Backup API"; $Global:FirstRun = $false}
write-output "Current datacenter: $Global:AcronisURL
Current API Version: $Global:APIVersion"
if($Global:AcronisCredentials.Username){write-output "Current username is "$Global:AcronisCredentials.UserName}
"---------------------------------------"

    

    #Start the script that provides a Graphical User Interface
    write-output "Options available
    1 - Enter credentials
    2 - Login to Acronis Cloud
    3 - Get current user information
    C - Change Acronis Datacenter
    N - Display Web Session information
    Exit - Exit the current program"
    #Wait for user input
    $UserInput = Read-Host -Prompt 'Please choose an option...'

    PerformUserChoice -UserChoice $UserInput
}

Function PerformUserChoice
{
    param ( [string]$UserChoice )

    clear

    if($UserChoice){$UserChoice = $UserChoice.ToLower()}

    switch ($UserChoice) {
        #User choosed "Enter Credentials"
        "1" {
                "Please enter your Acronis Credentials"
                Get-AcronisCredentials
                
                if($Global:AcronisCredentials){
                    $ReturnString = "The credentials for " + $Global:AcronisCredentials.UserName + " was successfully saved"
                } else {
                    $ReturnString = "There was an error saving your credentials, please try again."
                }

                Get-UserChoice -initialMessage $ReturnString
                break
        }

        #Login to Acronis Cloud using the credentials
        "2" {
                if(Got-AcronitCredentials){
                    write-output "Logging in to $AcronisURL using "$Global:AcronisCredentials.UserName
                    Login -AcronisUsername $Global:AcronisCredentials.UserName -AcronisPassword $Global:AcronisCredentials.GetNetworkCredential().Password
                    Get-UserChoice -initialMessage "Successfully Logged in to Acronis"
                } else {
                    Get-UserChoice -initialMessage "Please enter your credentials first"
                }
        }


        #User choosed "Get current user information"
        "3" {
                if(Got-AcronitCredentials){
                    "Getting user information..."
                    $ReturnString = Get-Profile
                    Get-UserChoice -initialMessage $ReturnString
                } else {
                    Get-UserChoice -initialMessage "Please enter your credentials first"
                }
        }

        #Get nWebSession Information
        "n" {
                $ReturnString = Get-WebSessionInformation
                Get-UserChoice -initialMessage $ReturnString
        }

        #User choosed "Change Datacenter"
        "c" {
                clear
                Change-Datacenter
                Get-UserChoice -initialMessage "Your new datacenter is"$Global:AcronisURL
        }
        
        "exit"{
                if(Got-AcronitCredentials){Logout}
                exit
        }

        #User choice was not part of this list
        default {
                $ReturnString = "Your choice was invalid. Your choice was: $UserChoice"
                Get-UserChoice -initialMessage $ReturnString
        }
    }
}

Function Got-AcronitCredentials
{
    if($Global:AcronisCredentials){
        return $true
    } else {
        return $false
    }
}

Function Get-AcronisCredentials
{

    $Global:AcronisCredentials = Get-Credential

}

Function Change-Datacenter{

    "Resetting Web Session..."
    Clear-Variable -Name nwebSession
    Clear-Variable -Name LastHttpRequestReply
    "Resetting the current credentials..."
    Clear-Variable -Name AcronisCredentials
    "Getting new credentials"
    $Global:AcronisCredentials = Get-Credential
    "Please select your datacenter:
    1 - us-cloud.acronis.com
    2 - eu-cloud.acronis.com
    3 - Manually enter Acronis Cloud Datacenter
    Exit - Do not change the datacenter"
                
    $UserChoiceValid = $false
    $UserDatacenterInput = Read-Host -Prompt 'Please choose an option...'
    $UserDatacenterInput = $UserDatacenterInput.ToLower()

    while($UserChoiceValid -eq $false){
        Switch ($UserDatacenterInput){
            "1"{
                $Global:AcronisURL = "us-cloud.acronis.com"
                $UserChoiceValid = $true
            }

            "2"{
                $Global:AcronisURL = "eu-cloud.acronis.com"
                $UserChoiceValid = $true
            }

            "3"{
                $manualDatacenter = Read-Host -Prompt 'Please enter your datacenter URL (Ex: us-cloud.acronis.com)'
                $Global:AcronisURL = $manualDatacenter.ToLower()
                $UserChoiceValid = $true
            }

            "exit"{
                $UserChoiceValid = $true
                break
            }

            default{
                "Your choice was invalid, please try again"
            }

        }
    }

}

Function Login
{
    param( [string]$AcronisUsername, [string]$AcronisPassword )
    $CompleteAcronisURL = $AcronisURL + "api/" + $APIVersion + "/login"
    $postParams = @{
       username=$AcronisUsername
       password=$AcronisPassword
    }
    $json = $postParams | ConvertTo-Json
    $Global:LastHttpRequestReply = Invoke-RestMethod $CompleteAcronisURL -Method Post -Body $json -ContentType 'application/json' -SessionVariable webSession
    $global:nwebSession = $webSession
}

Function Logout
{
    $CompleteAcronisURL = $AcronisURL + "api/" + $APIVersion + "/logout"
    $response = Invoke-RestMethod $CompleteAcronisURL -Method Post -ContentType 'application/json' -WebSession $global:nwebSession

    $response
}

Function Get-Profile
{

    $CompleteAcronisURL = $AcronisURL + "api/" + $APIVersion + "/profile"
    $Global:LastHttpRequestReply = Invoke-RestMethod $CompleteAcronisURL -Method Get -ContentType 'application/json' -WebSession $global:nwebSession
    Return $Global:LastHttpResponseReply
}

Function Get-WebSessionInformation
{
    #Return a string containing the web session information
    if($Global:nWebSession){
        $ReturnString = $Global:LastHttpRequestReply
        return $ReturnString
    } else {
        return "The web session has not been initialized yet. Please login first"
    }
   
}

#Start initialization
Get-UserChoice
