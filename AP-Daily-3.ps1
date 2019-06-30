# Step 0 Set up with utility scripts
function Get-ScriptDirectory{
    # like https://blogs.msdn.microsoft.com/powershell/2007/06/19/get-scriptdirectory-to-the-rescue/
    # this script wants to find files in the same folder
    $Invocation = (Get-Variable MyInvocation -Scope 1).Value
    try {
        Split-Path $Invocation.MyCommand.Path -ea 0
    }
    catch {
        Write-Warning 'You need to call this function from within a saved script.'
    }
}
# change directory to this folder
$sd = Get-ScriptDirectory
Set-Location $sd

#==============================================================================================
# example from: http://blogs.technet.microsoft.com/platformspfe/2014/01/20/integrating-xaml-into-powershell/
# XAML file created in Visual Studio WPF Application, and saved in script folder.
# See blog for namespaces used by Visual Studio that need to be removed!
#==============================================================================================
# also https://stackoverflow.com/questions/27791783/powershell-unable-to-find-type-system-windows-forms-keyeventhandler

[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void] [System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")

# Step 1 load XAML and create variables for Named elements
[xml]$xaml3 = [IO.File]::ReadAllText("$sd\AP-CM-Form-4.xaml")
$reader=(New-Object System.Xml.XmlNodeReader $xaml3) 
try{$Form=[Windows.Markup.XamlReader]::Load( $reader )}
catch{Write-Host "Unable to load Windows.Markup.XamlReader. Invalid XAML."; Exit}
# Store Form Objects In PowerShell, any named elements in the XAML are created as variables like $name_value
$xaml3.SelectNodes("//*[@Name]") | ForEach-Object{Set-Variable -Scope global -Name  ($_.Name) -Value $Form.FindName($_.Name)}

$miAddToPackage.Add_Click({Add-ToPackage})
$miRemoveFromPackage.Add_Click({Remove-FromPackage})
$miExportSelected.Add_Click({Export-Items})
$miExportTool.Add_Click({Start-ArasExportTool})
$miGitK.Add_Click({Start-GitK})
$miBeyondCompare.Add_Click({Start-BeyondCompare})
$miNUnit.Add_Click({Start-NUnit})
$miRefresh.Add_Click({refresh-grid})
$miAuditPackage.Add_Click({Audit-Package})
$miExit.Add_Click({Exit-App})

function Add-ToPackage
{
    Update-Package "add"
    refresh-grid
}

function Remove-FromPackage
{
    Update-Package "delete"
    refresh-grid
}

function Start-ArasExportTool
{
   Start-Process $aras_export_tool
}
function Start-GitK
{
   Start-Process -FilePath $gitk
}
function Start-BeyondCompare
{
   Start-Process -FilePath $beyond_compare
}
function Start-NUnit
{
   Start-Process -FilePath $nunit
}
function Update-Package($action)
{
    $pd =  $tbPackage.Text
    if ($pd -eq "")
    { [System.Windows.MessageBox]::Show("Please enter Packge Name")}
    else
    {

        $selectrows = $dataGrid1.SelectedItems
        foreach ($item in $selectrows) {
            $pg       = $item["Group"]
            $pe_name  = $item["keyed_name"]
            $pe_id    = $item["ElementId"]
            $set_id=""
            if ( $action -eq "delete" ) {$set_id="id='"+$item["id"]+"'"}
            $qry_addtopackage =
@"
<AML>
    <Item type="PackageDefinition" action="merge" where="[PackageDefinition].[name]='$pd'">
    <name>$pd</name>
    <Relationships>
    <Item type="PackageGroup" action="merge"  where="[PackageGroup].[name]='$pg'">
        <name>$pg</name>
        <Relationships>
        <Item type="PackageElement" $set_id action= "$action">
            <name>$pe_name</name>
            <element_id>$pe_id</element_id>
            <element_type>$pg</element_type>
        </Item>
        </Relationships>
    </Item>
    </Relationships>
    </Item>
</AML>
"@

            $res_addtopackage = $innov.applyAML($qry_addtopackage)
            if ($res_addtopackage.isError())
            {  
                 [System.Windows.MessageBox]::Show( $res_addtopackage.ToString())
            }
            $res_addtopackage.ToString()
        }
    }
}

function gitbranchname {
    $currentBranch = ''
    git branch | ForEach-Object {
        if ($_ -match "^\* (.*)") {
            $currentBranch += $matches[1]
        }
    }
    return $currentBranch
}
function get-project_prefix
{
    [xml] $defaults = get-content (resolve-path -path "../AutomatedProcedures/Default.Settings.include")
    return $defaults.SelectSingleNode("/project/property[@name='Project.Prefix']/@value").Value
}

$gitBranch = gitbranchname
$project_prefix= get-project_prefix
$iom_folder= (resolve-path "../Innovator/Server/bin/")
$libs_folder=  (resolve-path "../AutomatedProcedures/tools/PackageImportExportUtilities/Export/")
$export_folder= (resolve-path "../AP-Posh-Tools/ExportFolder")
$innovator_url="http://localhost/"+$project_prefix+"-"+$gitBranch+"/"
$aras_export_tool= (resolve-path "../AutomatedProcedures/tools/PackageImportExportUtilities/Export/export.exe")
$gitk = "C:/Program Files/Git/cmd/gitk.exe"
$beyond_compare = "C:\Program Files\Beyond Compare 4\Bcompare.exe"
$nunit = (resolve-path "../Tests/packages/NUnit.Runners.2.6.4/tools/nunit.exe")
$database=$env:computername+"-"+$project_prefix+"-"+$gitBranch
$last_commit= (git show --format=%cI)[0].Substring(0,19)



# create a reference to .net assembly, dll file can be copied from Innovator tree
Add-Type -path  ($iom_folder.Path+"IOM.dll")
#create connection to Innovator
$url  = $innovator_url+'Server/InnovatorServer.aspx'
$db   = $database
$user = "admin"
$pw   = "innovator"
# create a connection
$conn =[Aras.IOM.IomFactory]::CreateHttpServerConnection($url,$db,$user,$pw)
$res = $conn.Login
$res.ToString()
$Global:innov= [Aras.IOM.IomFactory]::CreateInnovator($conn)

#create a reference to libs.dll for import/export functionality
Add-Type -path  ($libs_folder.Path+"libs.dll")

# get list of changes since last commit and populate DataGrid

# get params from CI config
$machine_specific_includes = "C:\_machine_specific_includes\"+$project_prefix+"-"+$gitBranch+".Settings.include"
[xml] $settings = get-content $machine_specific_includes

$s_inst =$settings.SelectSingleNode("/project/property[@name='MSSQL.Server']/@value").Value
$s_db = $settings.SelectSingleNode("/project/property[@name='MSSQL.Database.Name']/@value").Value
$s_user =$settings.SelectSingleNode("/project/property[@name='MSSQL.Innovator.User']/@value").Value
$s_pw =$settings.SelectSingleNode("/project/property[@name='MSSQL.Innovator.Password']/@value").Value
$qry_fname=resolve-path -path "./ConfiguationReportDateTime.sql"
$s_qry_template = [IO.File]::ReadAllText($qry_fname)
$time_zone = "Eastern Standard Time"
function Get-CompareDate
{
  $compare_datetime= $tbCompareDateTime.Text
  if ([string]::IsNullOrEmpty($compare_datetime))   {$compare_datetime = $last_commit }
  else { $compare_datetime = get-date -date $compare_datetime -Format s }
  return $compare_datetime
}
$compare_datetime = Get-CompareDate
$s_qry = [string]::Format($s_qry_template, $compare_datetime  ,$time_zone)
$Global:changes = Invoke-Sqlcmd -ServerInstance $s_inst -Database $s_db -Username $s_user -Password $s_pw -Query $s_qry 



$repo_folder= (resolve-path "../")
$lRepo.Content += (" "+$repo_folder.Path +" in branch : "+$gitBranch+" on "+$last_commit)
$dataGrid1.ItemsSource = $Global:changes

function Audit-Package
{
    $pa =  $tbPackage.Text
    if ($pd -eq "")
    { [System.Windows.MessageBox]::Show("Please enter Packge Name(s) as comma separated string")}
    else
    {
      # remove the stored procedure, and temp tables if they exist
      $s_qry =
@"
      if exists (
        SELECT id FROM sysobjects
        WHERE  sysobjects.name = 'SelectPackageElementForItemType'
        and sysobjects.type='P'
      )
      DROP PROCEDURE SelectPackageElementForItemType
"@
      Invoke-Sqlcmd -ServerInstance $s_inst -Database $s_db -Username $s_user -Password $s_pw -Query $s_qry     
      
      # create a stored procedure for one time use by this script
        $qry_fname=resolve-path -path "./SelectPackagElementForItemType.sql"
        $s_qry = [IO.File]::ReadAllText($qry_fname)
        Invoke-Sqlcmd -ServerInstance $s_inst -Database $s_db -Username $s_user -Password $s_pw -Query $s_qry

        # get the audit results
        $qry_fname=resolve-path -path "./SelectPackageAudit.sql"
        $s_qry = [IO.File]::ReadAllText($qry_fname)
        $s_qry = [string]::Format($s_qry,$pa)
        $pa_result = Invoke-Sqlcmd -ServerInstance $s_inst -Database $s_db -Username $s_user -Password $s_pw -Query $s_qry

        # display result
        $pa_result | Out-Gridview

    }
}

function refresh-grid
{
  $compare_datetime = Get-CompareDate
  $s_qry = [string]::Format($s_qry_template, $compare_datetime  ,$time_zone)
  $Global:changes = Invoke-Sqlcmd -ServerInstance $s_inst -Database $s_db -Username $s_user -Password $s_pw -Query $s_qry
  $dataGrid1.ItemsSource = $Global:changes
  $lRepo.Content = "Grid shows changes in local Database since Compare Date " + $compare_datetime
  $lRepo.Content += ". Last commit in current branch " +$gitBranch+" on "+$last_commit
  $dataGrid1.ItemsSource = $Global:changes
}

function Export-Items
{
    #create a reference to libs.dll for import/export functionality
    Add-Type -path  ($libs_folder.Path+"Libs.dll")
    <#* **************************************************
    * The following lines use Libs.dll, copied to Server/bin
    * and reference added to method_config.xml.
    * Build number of libs.dll probably needs to match IOM.dll
    * which it does v11SP9.
    * Research by inspecting source code in Visual Studio, aka "the documentation"
    * from libs source code: public CItemHelper(string Url, string Password, string DbName, string UserName, string Folder)
    * It is necessary to log in as well for ItemTypes and Relationship types to be exported!
    * This function adapted from C:\Repos\SelfDocumentingAras\ConfigurationManager\Import\Method\cm_export_selected_2.xml
    *************************************************** #>
    Get-ChildItem $export_folder -Force -Directory -Recurse | Remove-Item -Force

    $cih = New-Object Aras.Tools.SolutionUpgrade.CItemHelper($url,$pw,$db,$user,$export_folder);
    $cih.Login();
    $cei = New-Object Aras.Tools.SolutionUpgrade.CExportItems($cih);

    $selectrows = $dataGrid1.SelectedItems
    foreach ($item in $selectrows) 
    { 
        $this_pd=$item["Package"]
        $this_pg=$item["Group"]
        $this_name=$item["keyed_name"]
        $this_pe_id=$item["ElementId"]
        if ($this_pg -eq "RelationshipType (ItemType)") {$this_pg="RelationshipType"}
        $cih.Folder=$export_folder.Path+"`\"+$this_pd+"`\Import\"
        $h = @{}
        $ei = New-Object Aras.Tools.SolutionUpgrade.ExportItem($this_name,$this_pe_id,$this_pg);
        $cei.Export($ei,$this_pd,"1",$h)
    } 
    refresh-grid  
}

function Exit-App
{
  Set-Location $repo_folder
  $Form.Close()  | Out-Null
}
# Show the form
$Form.ShowDialog() | out-null

