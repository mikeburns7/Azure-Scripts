#retrieves all users who have a presence in Azure Subscriptions. Best if ran from account that is assigned to root management group
#az login   
$subscriptions = az account list --all | ConvertFrom-Json

foreach ($subscription in $subscriptions) {
    az account set -s $subscription.Id

    #get users
    #$users = az role assignment list --query "[?principalType=='User'].{principalName:principalName,principalType:principalType,roleDefinitionName:roleDefinitionName,scope:scope}" | ConvertFrom-Json
    $users = az role assignment list --query "[?principalType=='User'].{principalName:principalName,roleDefinitionName:roleDefinitionName}"| ConvertFrom-Json | ForEach-Object {
        new-object psobject -Property @{                      
                                         memberof = ""
                                         roleDefinitionName = $_.roleDefinitionName
                                         userprincipalname = $_.principalName
                                         subscription = $subscription.name
                                         }
                } | export-csv usersnew.csv -Append
    
    #get groups
    #$groups = az role assignment list --query "[?principalType=='Group'].{principalName:principalName,principalType:principalType,roleDefinitionName:roleDefinitionName,scope:scope}" | ConvertFrom-Json
    $groups = az role assignment list --query "[?principalType=='Group'].{principalName:principalName,roleDefinitionName:roleDefinitionName}" | ConvertFrom-Json
    
    #enumerate group
    foreach ($group in $groups){
        
    #write-host $_.principalName
    $groupmembers = az ad group member list -g $group.principalName | ConvertFrom-Json | ForEach-Object {
        new-object psobject -Property @{
                                        memberof = $group.principalName
                                         roleDefinitionName = $group.roleDefinitionName
                                         userprincipalname = $_.userprincipalname
                                         subscription = $subscription.displayName
                                         }
                } | export-csv usersnew.csv -Append
    }
}

$dedup = Import-Csv usersnew.csv | Sort-Object userprincipalname -Unique

$dedup | export-csv users-dedup.csv
