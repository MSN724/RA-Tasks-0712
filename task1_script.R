library(data.table)

# Load data
EuropeEAs <- fread("/Users/masonzhang/Downloads/EuropeEAs.csv")
Europefirmquarters <- fread("/Users/masonzhang/Downloads/Europefirmquarters.csv")
tradingdates <- fread("/Users/masonzhang/Downloads/tradingdates.csv", header = FALSE, col.names = "trading_date")

# Convert date columns to appropriate formats
tradingdates[, trading_date := as.IDate(trading_date, format="%m/%d/%y")]
EuropeEAs[, `:=`(PENDS = as.IDate(PENDS, format="%d-%b-%y"),
                 ANNDATS = as.IDate(ANNDATS, format="%d-%b-%y"),
                 ANNTIMS = as.ITime(ANNTIMS, format="%H:%M:%S"))]
Europefirmquarters[, fqenddt := as.IDate(fqenddt, format="%d-%b-%y")]

# Ensure CUSIP is 9 digits and generate SEDOL
EuropeEAs[, CUSIP := sprintf("%09s", CUSIP)]
EuropeEAs[, sedol := substr(CUSIP, 4, 9)]

# Merge datasets
merged_data <- merge(Europefirmquarters, EuropeEAs, by.x = c("sedol", "fqenddt"), by.y = c("sedol", "PENDS"), all.x = TRUE)
merged_data <- merged_data[CUSIP != "" & !is.na(CUSIP) & CUSIP != " "]

# Adjust announcement date if the announcement time is after trading hours (16:00:00)
merged_data[, trade_response_date := as.IDate(ifelse(ANNTIMS > as.ITime("16:00:00"), ANNDATS + 1, ANNDATS))]

# Ensure tradingdates is sorted
setkey(tradingdates, trading_date)

# Find the next trading date
merged_data[, next_trading_date := tradingdates[trading_date > trade_response_date][1, trading_date], by = trade_response_date]

# Ensure next_trading_date is treated as a date
output_dataset <- unique(merged_data[, .(sedol, fqenddt, next_trading_date)])

print(output_dataset)

fwrite(output_dataset, "/Users/masonzhang/Downloads/task1_result.csv")