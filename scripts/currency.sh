#pass the currency and convert values
CURRENCY=$1
CONVERT=$2
while true; do
	curl -s "https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/$CURRENCY.json" >/tmp/currency$CURRENCY.txt
	curl -s "https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/$CONVERT.json" >/tmp/currency$CONVERT.txt
	PRICE=$(cat /tmp/currency$CURRENCY.txt | jq .$CURRENCY.$CONVERT | cut -c 1-5)
	REVERSEPRICE=$(cat /tmp/currency$CONVERT.txt | jq .$CONVERT.$CURRENCY | cut -c 1-5)
	echo "{ \"text\": \"$PRICE\", \"tooltip\":\"$CURRENCY to $CONVERT = $PRICE\n$CONVERT to $CURRENCY = $REVERSEPRICE\"}"
	# Sleep for 1 hour (3600 seconds)
	sleep 3600
done
