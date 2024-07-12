library(data.table)
library(dplyr)

# Load the data
allnews <- fread("/Users/masonzhang/Downloads/allnews.csv")
ESGnews <- fread("/Users/masonzhang/Downloads/ESGnews.csv")

head(allnews,20)
head(ESGnews,20)

allnews[, article_date := as.Date(article_date, format = "%d%b%Y")]
ESGnews[, eventdate := as.Date(eventdate, format = "%m/%d/%y")]

unique_combinations <- unique(allnews[, .(TOPIC, GROUP, TYPE)])
# Sort values
unique_combinations <- unique_combinations[order(TOPIC, GROUP, TYPE)]
# Print the entire table without truncation
print(unique_combinations, n = Inf)
# print only group and type
print(unique_combinations[, .(GROUP, TYPE)], n = Inf)

ESG_topics <- c("environment", "society", "politics")

ESG_groups <- c(
  "pollution", "industrial-accidents", "labor-issues", "civil-unrest", "corporate-responsibility", "health", 
  "insider-trading", "legal", "security"
)

ESG_types <- c(
  "air-pollution",
  "aircraft-accident", "automobile-accident", "facility-accident", "factory-accident",
  "force-majeure", "freight-transport-accident", "mine-accident", "pipeline-accident",
  "power-outage", "public-transport-accident", "refinery-accident", "spill",
  "board-member-appointment", "board-member-death", "board-member-firing", "board-member-health",
  "board-member-resignation", "board-member-retirement", "executive-appointment", 
  "executive-compensation", "executive-death", "executive-firing", "executive-health",
  "executive-incentives", "executive-resignation", "executive-retirement", "executive-salary", 
  "executive-scandal", "executive-search", "hirings", "layoffs", "union-pact", "workers-strike",
  "workforce-salary", "evacuation", "protest", "donation", "sponsorship", "suicide",
  "insider-buy", "insider-gift", "insider-sell", "insider-surrender", "insider-trading-lawsuit", 
  "sell-registration", "antitrust-investigation", "antitrust-settlement", "antitrust-suit",
  "appeal", "blackmail", "confidentiality-pact", "copyright-infringement", "corruption", 
  "defamation", "discrimination", "embezzlement", "fraud", "legal-issues", "patent-infringement",
  "sanctions", "sanctions-guidance", "settlement", "tax-evasion", "verdict", "corporate-espionage",
  "cyber-attacks", "explosion", "weapons-testing"
)

# Identify firms with ESG news events
firms_with_ESG_news <- unique(ESGnews$gvkey)

# Extract all news events for these firms
news_for_ESG_firms <- allnews[gvkey %in% firms_with_ESG_news]

# Mark ESG-related news
news_for_ESG_firms[, is_ESG := FALSE]
news_for_ESG_firms[TOPIC %in% ESG_topics, is_ESG := TRUE]
news_for_ESG_firms[TOPIC %in% c("business", "economy") & (GROUP %in% ESG_groups | TYPE %in% ESG_types), is_ESG := TRUE]

# Identify non-ESG news events
non_ESG_news <- news_for_ESG_firms[is_ESG == FALSE]

# Get gvkey and eventdate from ESGnews
ESG_event_dates <- unique(ESGnews[, .(gvkey, eventdate)])
setnames(ESG_event_dates, "eventdate", "article_date")

# Remove non-ESG news events on the same date as ESG news events for the same firm
non_ESG_news_filtered <- anti_join(as.data.frame(non_ESG_news), as.data.frame(ESG_event_dates), by = c("gvkey", "article_date"))

# Create the output dataset of unique firm-dates with non-ESG news events
output_dataset <- unique(as.data.table(non_ESG_news_filtered)[, .(gvkey, article_date)])

print(output_dataset)

fwrite(output_dataset, "/Users/masonzhang/Downloads/task2_result.csv")