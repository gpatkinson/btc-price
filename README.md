# BTC Price

A live Bitcoin price widget for the Omarchy Quattro bar. Shows the current BTC/USD price and polls CoinGecko's free API every 15 minutes. Click the bar widget for a details panel with 24-hour change and last-updated time.

## API

Uses the free CoinGecko endpoint — no API key required:

```
https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd&include_24hr_change=true&include_last_updated_at=true
```

The 15-minute poll interval stays well within CoinGecko's free-tier rate limit.

## Install

```sh
omarchy plugin add https://github.com/gpatkinson/btc-price.git --enable
```

## Usage

- The bar shows `₿$63,098` (Bitcoin symbol + formatted USD price).
- Click the bar widget to open the details panel.
- The panel shows the current price, 24-hour change (green/red), last-updated time, and a manual refresh button.
- Press Escape to close the panel.

## Configure

Move the widget to a different bar section:

```sh
omarchy bar move gpatkinson.btc-price --section right
```

## Remove

```sh
omarchy plugin remove gpatkinson.btc-price
```

## Files

| File             | Purpose                                        |
|------------------|------------------------------------------------|
| `manifest.json`  | Plugin metadata and bar-widget entry point     |
| `BarWidget.qml`  | Bar entry point — displays price label         |
| `Panel.qml`      | Details panel + HTTP fetch logic (curl/Timer)  |
| `Model.js`       | API response parsing and price formatting      |

## License

MIT
