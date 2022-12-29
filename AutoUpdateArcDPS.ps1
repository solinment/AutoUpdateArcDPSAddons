$Path = [System.IO.Path]::GetDirectoryName($myInvocation.MyCommand.Definition) # Installation path of Guild Wars 2, where Gw2-64.exe is hiding.
$Web = New-Object Net.WebClient # Get ley line thingy.
$GuildWarsRunning = Get-Process "Gw2-64" -ErrorAction SilentlyContinue

Function Install {
	Param ($DownloadLink, $LocalSaveFile, $LogFile, $LogContent)
	
	$Web.DownloadFile($DownloadLink, $LocalSaveFile) # Download and save
	$LogContent | Out-File -FilePath ($LogFile) # Save log content
}

Function Get-Update {
	Param ($DownloadLink, $DirectoryName, $DownloadFile, $LogContent)
	
	$LocalSaveFile = $Path+"\"+$DirectoryName+"\"+$DownloadFile
	$LogFile = $Path+"\Last "+$DownloadFile+".txt"
	
	if (!(Test-Path ($LogFile)) -and !(Test-Path ($LocalSaveFile))) {
		"Init for "+$DownloadFile
		Install $DownloadLink $LocalSaveFile $LogFile $LogContent
	}elseif (!(Test-Path ($LogFile))){
		"Log file missing. Init for "+$DownloadFile
		Install $DownloadLink $LocalSaveFile $LogFile $LogContent
	}elseif (!(Test-Path ($LocalSaveFile))){
		"Local save file missing. Init for "+$DownloadFile
		Install $DownloadLink $LocalSaveFile $LogFile $LogContent
	}else{
		$LogContentOld = ""
		if ((Test-Path ($LogFile))){
			$File = new-object System.IO.StreamReader($LogFile) # Read "Last XXXX.txt" to get the last compare tag
			$LogContentOld = $File.ReadLine()
			$File.close()
		}
		
		if ($LogContent -notlike $LogContentOld) {
			"There is a new version of "+$DownloadFile+"."
			Install $DownloadLink $LocalSaveFile $LogFile $LogContent
		}else{
			"Nothing changed for "+$DownloadFile+"."
		}
	}
	" --- "
}

Function Get-LogContentFromWeb {
	Param ($WebPage, $SearchStr)
	
	$Text = $web.DownloadString($WebPage)
	
	$Pos1 = $Text.IndexOf($SearchStr)
	$Pos2 = $Pos1
	while ($Pos1 -notlike -1) {
		if (($Text.Substring($Pos1+8,1) -notlike ".")) {$Pos2 = $Pos1}
		$Pos1 = $Text.IndexOf($SearchStr,$Pos1+1)
	}
	$SpacePos1 = $Text.IndexOf('indexcollastmod">',$Pos2+8)+17 # Find start of date & time.
	while ($Text.Substring($SpacePos1,1) -like " ") {$SpacePos1 = $SpacePos1+1} # Skip all the spaces to get our first year number. *This was needed in older web page.
	$DashPos1 = $Text.IndexOf("-",$SpacePos1)+1 # Dash between year and month.
	$DashPos2 = $Text.IndexOf("-",$DashPos1)+1 # Dash between month and day.
	$SpacePos2 = $Text.IndexOf(" ",$DashPos2)+1 # Space between day and hour.
	$ColonPos = $Text.IndexOf(":",$SpacePos2)+1 # Colon between hour and minutes.
	#Take the numbers out and make it nice again:
	$DateTime = $Text.Substring($SpacePos1,($DashPos1-1)-$SpacePos1)+"-"+$Text.Substring($DashPos1,($DashPos2-1)-$DashPos1)+"-"+$Text.Substring($DashPos2,($SpacePos2-1)-$DashPos2)+" "+$Text.Substring($SpacePos2,($ColonPos-1)-$SpacePos2)+":"+$Text.Substring($ColonPos,$Text.IndexOf(" ",$ColonPos)-$ColonPos)
	
	return $DateTime
}

Function Get-LogContentFromGithub {
	Param ($Owner, $RepoName, $File)
	
	$link="https://api.github.com/repos/"+$Owner+"/"+$RepoName+"/releases"
	$Json=Invoke-RestMethod -URI $link
	return $Json[0].tag_name
}

Function Get-DownloadLinkWithNewestVersion{
	Param ($TagName, $File)

	return "https://github.com/"+$Owner+"/"+$RepoName+"/releases/download/"+$TagName+"/"+$File
}

if(!$GuildWarsRunning){

	# Download ArcDPS
	$File="d3d11.dll"
	$Url = "https://www.deltaconnected.com/arcdps/x64/"
	$LogContent = Get-LogContentFromWeb $Url $File
	$DownloadLink = $Url + $File
	$Directory = ""
	Get-Update $DownloadLink $Directory $File $LogContent

	# Download Unofficial Extras
	$File="arcdps_unofficial_extras.dll"
	$Owner = "Krappa322"
	$RepoName = "arcdps_unofficial_extras_releases"
	$Directory="bin64"
	$LogContent = Get-LogContentFromGithub $Owner $RepoName
	$DownloadLink=Get-DownloadLinkWithNewestVersion $LogContent $File
	Get-Update $DownloadLink $Directory $File $LogContent

	# Download Boon Table
	$File="d3d9_arcdps_table.dll"
	$Owner = "knoxfighter"
	$RepoName = "GW2-ArcDPS-Boon-Table"
	$Directory="bin64"
	$LogContent = Get-LogContentFromGithub $Owner $RepoName
	$DownloadLink=Get-DownloadLinkWithNewestVersion $LogContent $File
	Get-Update $DownloadLink $Directory $File $LogContent

	# Download Mechanics Log
	$File="d3d9_arcdps_mechanics.dll"
	$Owner = "knoxfighter"
	$RepoName = "GW2-ArcDPS-Mechanics-Log"
	$Directory="bin64"
	$LogContent = Get-LogContentFromGithub $Owner $RepoName
	$DownloadLink=Get-DownloadLinkWithNewestVersion $LogContent $File
	Get-Update $DownloadLink $Directory $File $LogContent

	# Download KP add on
	$File="d3d9_arcdps_killproof_me.dll"
	$Owner = "knoxfighter"
	$RepoName = "arcdps-killproof.me-plugin"
	$Directory="bin64"
	$LogContent = Get-LogContentFromGithub $Owner $RepoName
	$DownloadLink=Get-DownloadLinkWithNewestVersion $LogContent $File
	Get-Update $DownloadLink $Directory $File $LogContent

	"Starting GW2..."
	& ($Path+"\Gw2-64.exe") # Run Guild Wars 2.

}else{
	"Gw2 already running."
}

"This window closes automatically after 3 seconds."
Sleep 3
