Import-Module ActiveDirectory
$DomainDN = "DC=laplateforme,DC=io"
$Password = ConvertTo-SecureString "Azerty_2025!" -AsPlainText -Force
New-ADOrganizationalUnit -Name "LaPlateforme" -Path $DomainDN
New-ADOrganizationalUnit -Name "Utilisateurs" -Path "OU=LaPlateforme,$DomainDN"
New-ADOrganizationalUnit -Name "Groupes" -Path "OU=LaPlateforme,$DomainDN"
$csvData = @"
nom,prénom,groupe1,groupe2,groupe3,groupe4,groupe5,groupe6
ALEXANDRE,MARCELLINE,Animation,,,,,
ARAGON,ISABELLE,Animation,,,,,
AVARO,MARINA,As,Médical,,,,
BERNARD,ISABELLE,As,Médical,,,,
BOUFFIER,STEPHANE,ASH,Hébergement,,,,
BOUZIANE,FATIHA,cadre de santé,Cadres,Médical,,,
CARLIER,CHANTAL,Comptable,Administratif,,,,
THILLOT,MARC,Directeur,Cadres,Hébergement,Technique,Administratif,Animation
GALLIEN,CAROLE,Maîtresse de Maison,Cadres,Hébergement,,,
GRIVEAUX,PATRICIA,Médecin,Cadres,Médical,,,
LARGUIER,SILVANIA,Psychologue,Cadres,Médical,,,
MALAURE,OPHYLANADRA,ASH,Hébergement,,,,
PRATABUY,MYRIAM,Secrétaire,Administratif,,,,
SAHTIT,OIFAA,IDE,Médical,,,,
SALVADOR,GLADYS,IDE,Médical,,,,
SCHNEIDER,EMILE,Technique,Cadres,,,,
VIGNOLO,VERONIQUE,Animation,Cadres,Hébergement,Administratif,,
"@
$users = $csvData | ConvertFrom-Csv -Delimiter ","
$allGroups = @()
foreach ($user in $users) {
    for ($i = 1; $i -le 6; $i++) {
        $grp = $user."groupe$i"
        if ($grp -and $grp.Trim() -ne "" -and $allGroups -notcontains $grp.Trim()) {
            $allGroups += $grp.Trim()
        }
    }
}
foreach ($grp in $allGroups) {
    New-ADGroup -Name $grp.Trim() -GroupScope Global -GroupCategory Security -Path "OU=Groupes,OU=LaPlateforme,$DomainDN"
    Write-Host "[GROUPE] Créé : $grp" -ForegroundColor Yellow
}
foreach ($user in $users) {
    $nom = $user.nom.Trim().ToUpper()
    $prenom = $user."prénom".Trim()
    $samBase = ($prenom.Substring(0,1) + $nom).ToLower()
    $samBase = $samBase -replace '[^a-z0-9]', ''
    $sam = $samBase.Substring(0, [Math]::Min($samBase.Length, 20))
    $counter = 1
    $finalSam = $sam
    while (Get-ADUser -Filter "SamAccountName -eq '$finalSam'" -ErrorAction SilentlyContinue) {
        $finalSam = $sam + $counter
        $counter++
    }
    New-ADUser -SamAccountName $finalSam -UserPrincipalName "$finalSam@laplateforme.io" -Name "$prenom $nom" -GivenName $prenom -Surname $nom -DisplayName "$prenom $nom" -AccountPassword $Password -ChangePasswordAtLogon $true -Enabled $true -Path "OU=Utilisateurs,OU=LaPlateforme,$DomainDN"
    Write-Host "[USER] Créé : $prenom $nom ($finalSam)" -ForegroundColor Green
    for ($i = 1; $i -le 6; $i++) {
        $grp = $user."groupe$i"
        if ($grp -and $grp.Trim() -ne "") {
            Add-ADGroupMember -Identity $grp.Trim() -Members $finalSam
            Write-Host "  -> Groupe : $($grp.Trim())" -ForegroundColor Cyan
        }
    }
}
Write-Host "Terminé ! Utilisateurs et groupes créés avec succès." -ForegroundColor Magenta
