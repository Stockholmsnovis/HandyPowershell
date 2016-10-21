$regex = [regex] 'AssemblyFileVersion\("(?<Major>\d+)\.(?<Minor>\d+)\.(?<Build>\d+)\.(?<Patch>\d+)"\)'
$childItems = Get-ChildItem -Path .\ -Filter *.NuSpec -Recurse
$childItems | ForEach-Object -process {
        $projectName = [io.path]::GetFileNameWithoutExtension($_.FullName);
        $directoryName = ($_.DirectoryName);
        $csProjPath = "$directoryName\$projectName.csproj";
        $assemblyInfoFile = (Get-ChildItem -Path $directoryName -Filter AssemblyInfo.cs -Recurse);

        if((Test-Path $csProjPath) -And ($assemblyInfoFile.Length -gt 0)) {

            Write-Host "Behandlar projekt: $projectName";

            $content = gc $assemblyInfoFile[0].FullName;

            $match = $regex.Match($content);
            $major = $match.Groups["Major"].Value
            $minor = $match.Groups["Minor"].Value
            $patch = $match.Groups["Patch"].Value
            $build = $match.Groups["Build"].Value

            $xmlDoc = [xml](Get-Content $csProjPath);
            $ns = new-object Xml.XmlNamespaceManager $xmlDoc.NameTable
            $ns.AddNamespace("my", $xmlDoc.DocumentElement.NamespaceURI);
            $octoPackPackageVersionElement = $xmlDoc.DocumentElement.SelectSingleNode("my:PropertyGroup/my:OctoPackPackageVersion", $ns);

            if($octoPackPackageVersionElement -eq $null) {

              Write-Host "<OctoPackPackageVersion> does not exist, inserting a new one...";
              $propGroupElement = $xmlDoc.CreateElement("PropertyGroup", $xmlDoc.DocumentElement.NamespaceURI);
              $octoPackPackageVersionElement = $xmlDoc.CreateElement("OctoPackPackageVersion", $xmlDoc.DocumentElement.NamespaceURI);
              $propGroupElement.AppendChild($octoPackPackageVersionElement);
              $xmlDoc.DocumentElement.PrependChild($propGroupElement);


            } else {
              Write-Host "<OctoPackPackageVersion> exists, updating version number...";
            }

            $octoPackPackageVersionElement.InnerText = "$major.$minor.$patch.$build";
            $xmlDoc.Save($csProjPath);

        }
    }
