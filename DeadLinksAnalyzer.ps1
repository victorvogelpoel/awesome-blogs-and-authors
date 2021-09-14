function Test-MarkdownLinks([String]$Path)
{
    $unreachableLinks = @()

    # Get markdown files recursively
    $files = Get-ChildItem -Path $Path -Recurse -Include "*.md"

    foreach ($file in $files)
    {
        $fileName = $file.Name
        Write-Host "Analyzing `"$fileName`""

        $urls = Select-String -Path $file -Pattern "\[.+\]\((http.*?)\)(<!--.+-->)?" | where { $_.matches.Groups[1].Success -and $_.matches.Groups[2].Value -ne '<!-- omit in link analyzer -->'} | foreach { $_.matches.Groups[1].Value }

        foreach ($url in $urls)
        {
            Write-Host "Requesting url $url"

            try
            {
                $request = Invoke-WebRequest -Uri $url -DisableKeepAlive -UseBasicParsing
            }
            catch
            {
                Write-Warning -Message "Found dead url $url in $fileName"

                $unreachableLinks += $url
            }
        }
    }

    # Output urls
    return $unreachableLinks
}


$deadLinks = Test-MarkdownLinks -Path "."

if ($deadLinks)
{
    Write-Host -Object '--- DEAD LINKS FOUND ---' -ForegroundColor Red

    foreach ($deadLink in $deadLinks)
    {
        Write-Host $deadLink -ForegroundColor Red
    }

    exit 1
}
