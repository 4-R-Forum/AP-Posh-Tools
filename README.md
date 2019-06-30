# AP-Posh-Tools
Powershell scripts with a Xaml Gui to help Aras Practitioners with post-processing changes in a development database for use with continuous integration. The contents of this repo are intended for use inside a customer project repository and use the Aras customer repository Settings.iclude file in the _machine_specific_includes folder

New Configuration Report, Add-To-Package, Audit-Package and Export functionality replaces obsolete ActiveX in the Self-Documenting repo.  The Gui has menu items to: Add selected rows to PackageDefinitions, Export selected rows, Audit PackageDefinitions to avoid import errors, and  Launch Beyond Compare and the Export/Import tool.

Known issues
1) ConfigurationManager.bat needs to be moved to the customer repository folder.
2) When the ConfigurationManager is closed it is necessary to navigate up using "cd .."
3) AP-CM-Form-4.xaml needs to be edited with an absolute uri, relative addressing doesn't work in Powershell



