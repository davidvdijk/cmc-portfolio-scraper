Import-Module ".\WebDriver.dll"
Import-Module ".\WebDriver.Support.dll"

$username = $args[0]
$password = $args[1]
$refresh_every_seconds = $args[2]

if($refresh_every_seconds -eq $null) {
    $refresh_every_seconds = 5
}

if($username -eq $null -or $password -eq $null) {
    Write-Error "No username/password has been given"
    exit
}

echo ("Refreshing every: " + $refresh_every_seconds + " seconds")

$ChromeOptions = New-Object OpenQA.Selenium.Chrome.ChromeOptions
$ChromeOptions.AddArgument('start-maximized')
$ChromeOptions.AcceptInsecureCertificates = $True

$ChromeDriver = New-Object OpenQA.Selenium.Chrome.ChromeDriver($ChromeOptions)
$ChromeDriver.Url = 'https://coinmarketcap.com/';

$ChromeDriver.FindElementByXPath('//*[@id="__next"]/div/div[1]/div[1]/div[1]/div/div[2]/button[1]').Click()
$ChromeDriver.FindElementByXPath('/html/body/div[2]/div/div[2]/div[3]/input').SendKeys($username)
$ChromeDriver.FindElementByXPath('/html/body/div[2]/div/div[2]/div[4]/div[2]/input').SendKeys($password)
$ChromeDriver.FindElementByXPath('/html/body/div[2]/div/div[2]/div[5]/button').Click()
Start-Sleep -s 5
$ChromeDriver.Navigate().GoToUrl('https://coinmarketcap.com/portfolio-tracker')

while(1 -eq 1) {
$list = $ChromeDriver.FindElementByClassName('cmc-table');
$date = Get-Date
$elements = $list.FindElementsByTagName('tr');

$coins = New-Object System.Collections.Generic.List[System.Object]
$elements | ForEach-Object {
	try{
  		if($_.Text -inotmatch "Price") {
            $__anchor = $_.FindElementByTagName('a')
			$href = $__anchor.getAttribute('href')
			$name = $__anchor.FindElementByTagName('p').Text
			$tag = $__anchor.FindElementByClassName('coin-item-symbol').Text
			$img = $__anchor.FindElementByCssSelector('img.coin-logo').getAttribute('src')
            $price_dollar = $_.FindElementsByTagName('td')[1].FindElementByTagName('p').Text.replace("$", "")
            $24h_change_percentage = $_.FindElementsByTagName('td')[2].Text.replace("%", "")

            $holding_price_dollar = $_.FindElementsByTagName('td')[3].FindElementByTagName('div').Text.replace("`n","- ").replace("`r","- ").Split("- ")[0].replace("$", "")
            $holding_amount = $_.FindElementsByTagName('td')[3].FindElementByTagName('p').getAttribute('innerHTML').replace("`n",", ").replace("`r",", ").Split(", ")[0] # -replace ".* " -replace " "
            $__holding_profit_total = $_.FindElementsByTagName('td')[4].FindElementByTagName('p').Text.Split(" ")
            $__holding_profit_direction = $__holding_profit_total[0]
            $holding_profit_amount_dollar = $__holding_profit_total[1].replace("$", "")
            $holding_profit_amount_percentage = $_.FindElementsByTagName('td')[4].FindElementByTagName('span').Text.replace("%", "")

            if($__holding_profit_direction -eq "+") {
                $holding_profit_positive = $true
            } else {
                $holding_profit_positive = $false
            }

            $coinProperties = @{
                name = $name;
                tag = $tag;
                price_usd = $price_dollar;
                change_24h_per = $24h_change_percentage;
                holdings = $holding_amount;
                holdings_price_usd = $holding_price_dollar;
                has_profit = $holding_profit_positive;
                profit_usd = $holding_profit_amount_dollar;
                profit_per = $holding_profit_amount_percentage;
                icon_href = $img;
                href = $href;
            }
            $coin = New-Object psobject -Property $coinProperties
            #$coin | Format-Table
            $coins.Add($coin)
		}
	} catch {
		echo $_.Exception
        #echo $_.ErrorDetails
        #echo $_.ScriptStackTrace
        exit
	}
}
$coins | Format-Table -AutoSize name, tag, price_usd,holdings,holdings_price_usd,change_24h_per,has_profit,profit_per,profit_usd,href,icon_href
Start-Sleep -s $refresh_every_seconds
$ChromeDriver.Navigate().Refresh();
}

#Read-Host -Prompt "Press Enter to exit"