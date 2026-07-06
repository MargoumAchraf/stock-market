import requests
import time

BASE_URL = "http://localhost:5001"
SYMBOL = "AAME"
INTERVAL = 1  # seconds between each fetch


def get_rate(symbol):
    res = requests.get(f"{BASE_URL}/exchange_rate/{symbol}")
    res.raise_for_status()
    return res.json()


def main():
    previous_rate = None

    print(f"Checking '{SYMBOL}' every {INTERVAL}s... (Ctrl+C bach twaqef)\n")

    while True:
        try:
            data = get_rate(SYMBOL)
            rate = data["rate"]

            if previous_rate is None:
                pct_str = "→ (first fetch, no %)"
            else:
                pct = ((rate - previous_rate) / previous_rate) * 100
                if pct > 0:
                    pct_str = f"⬆️  +{pct:.4f}%"
                elif pct < 0:
                    pct_str = f"⬇️  {pct:.4f}%"
                else:
                    pct_str = "➡️  0.0000%"

            print(f"rate = {rate:.6f}   {pct_str}")

            previous_rate = rate
            time.sleep(INTERVAL)

        except KeyboardInterrupt:
            print("\nWaqaft.")
            break
        except requests.RequestException as e:
            print(f"Erreur f fetch: {e}")
            time.sleep(INTERVAL)


if __name__ == "__main__":
    main()