// Model.js — parsing and formatting helpers for the Bitcoin price plugin.
//
// CoinGecko free endpoint:
//   https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd&include_24hr_change=true&include_last_updated_at=true
//
// Response shape:
//   { "bitcoin": { "usd": 63098, "usd_24h_change": 0.17, "last_updated_at": 1786905590 } }

// Parse the CoinGecko /simple/price JSON into a flat object.
// Returns null on any parse failure so callers can retry.
function parsePriceResponse(raw) {
  try {
    var data = JSON.parse(String(raw || ""))
    if (!data || !data.bitcoin) return null

    var btc = data.bitcoin
    var usd = parseFloat(String(btc.usd))
    var change = parseFloat(String(btc.usd_24h_change))
    var updated = parseInt(String(btc.last_updated_at), 10)

    if (isNaN(usd)) return null

    return {
      usd: usd,
      change24h: isNaN(change) ? 0 : change,
      lastUpdated: isNaN(updated) ? 0 : updated
    }
  } catch (e) {
    return null
  }
}

// Format a USD number with comma thousands separators, no decimals.
//   63098  → "$63,098"
//   100000 → "$100,000"
function formatPrice(usd) {
  var n = parseFloat(String(usd))
  if (isNaN(n)) return ""
  var rounded = Math.round(n)
  var str = String(rounded)
  var formatted = ""
  var count = 0
  for (var i = str.length - 1; i >= 0; i--) {
    if (count > 0 && count % 3 === 0) formatted = "," + formatted
    formatted = str[i] + formatted
    count++
  }
  return "$" + formatted
}

// Compact bar label: Bitcoin symbol + formatted price.
//   "₿$63,098"
function barLabel(usd) {
  var price = formatPrice(usd)
  if (price === "") return ""
  return "\u20BF" + price
}

// Format the 24-hour change as a signed percentage.
//   0.17     → "+0.17%"
//   -1.23    → "-1.23%"
function formatChange(change) {
  var n = parseFloat(String(change))
  if (isNaN(n)) return ""
  var sign = n >= 0 ? "+" : ""
  return sign + n.toFixed(2) + "%"
}

// Determine text color based on 24h change direction.
// Returns a hex color string suitable for QML color properties.
function changeColor(change) {
  var n = parseFloat(String(change))
  if (isNaN(n)) return "#888888"
  return n >= 0 ? "#4ade80" : "#f87171"
}

// Format a Unix timestamp (seconds) as "HH:mm" local time.
function formatUpdatedTime(timestamp) {
  var ts = parseInt(String(timestamp), 10)
  if (!ts) return ""
  var d = new Date(ts * 1000)
  var h = String(d.getHours()).padStart(2, "0")
  var m = String(d.getMinutes()).padStart(2, "0")
  return h + ":" + m
}

// ---- Color toggle ----

// Two options only: bitcoin orange or the bar's default foreground.
// Parse the btc-price.json state file: { "useOrange": true }
// Returns null if no preference is stored.
function parseColorFile(raw) {
  try {
    var data = JSON.parse(String(raw || ""))
    if (!data || data.useOrange === undefined || data.useOrange === null) return null
    return data.useOrange === true
  } catch (e) {
    return null
  }
}
