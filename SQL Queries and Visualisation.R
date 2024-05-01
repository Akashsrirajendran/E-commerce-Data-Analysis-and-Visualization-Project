# Data queries and visualization

```{r library, include=FALSE}
library(readr)
library(tidyverse)
library(dplyr)
library(RSQLite)
library(lubridate)
```

Based on the data given, we design **five complex SQL queries** and also translate these to the equivalents using R and dplyr pipes. The results of these queries are visualized by using ggplot.

```{r, eval=FALSE, include=FALSE}
# get a list of files
olist_files <- list.files("Olist/")
prefix <- "olist_"
suffix <- "dataset.csv"
olist_files <- gsub("olist_","",olist_files)
olist_files <- gsub("_dataset.csv","",olist_files)
olist_files <- gsub(".csv","",olist_files)
olist_files


# import data
closed_deals <- read.csv("Olist/olist_closed_deals_dataset.csv")
customers <- read.csv("Olist/olist_customers_dataset.csv")
geolocation <- read.csv("Olist/olist_geolocation_dataset.csv")
marketing_qualified_leads <- read.csv("Olist/olist_marketing_qualified_leads_dataset.csv")
order_items <- read.csv("Olist/olist_order_items_dataset.csv")
order_payments <- read.csv("Olist/olist_order_payments_dataset.csv")
order_reviews <- read.csv("Olist/olist_order_reviews_dataset.csv")
orders <- read.csv("Olist/olist_orders_dataset.csv")
products <- read.csv("Olist/olist_products_dataset.csv")
sellers <- read.csv("Olist/olist_sellers_dataset.csv")
product_category_name_translation <- read.csv("Olist/product_category_name_translation.csv")

# look through
all_files <- list.files("Olist/")
for (variable in all_files) {
  this_filepath <- paste0("Olist/",variable) 
  this_file_contents <- readr::read_csv(this_filepath)
  
  number_of_rows <- nrow(this_file_contents)
  number_of_columns <- ncol(this_file_contents)
  
  print(paste0("The file: ",variable,
               " has: ",
               format(number_of_rows,big.mark = ","),
               " rows and ",
               number_of_columns," columns"))
}

# Check if the first column of each file is a primary
for (variable in all_files) {
  this_filepath <- paste0("Olist/",variable) 
  this_file_contents <- readr::read_csv(this_filepath) 
  number_of_rows <- nrow(this_file_contents)
  
  print(paste0("Checking for: ",variable))
  
  print(paste0(" is ",nrow(unique(this_file_contents[,1]))==number_of_rows))
}

# load files in an sqlite database
connection <- RSQLite::dbConnect(RSQLite::SQLite(),"olist_import.db")

for (variable in all_files) {
  this_filepath <- paste0("Olist/",variable) 
  this_file_contents <- readr::read_csv(this_filepath)
  table_name <- gsub(".csv","",variable)
  table_name <- gsub("olist_","",table_name) 
  table_name <- gsub("_dataset","",table_name) # table_name <- variable
  RSQLite::dbWriteTable(connection,table_name,this_file_contents,overwrite=TRUE)
}

RSQLite::dbListTables(connection)
#RSQLite::dbDisconnect(connection)
```

```{r, eval=FALSE, include=FALSE}
for (variable in all_files) {
  this_filepath <- paste0("Olist/",variable) 
  this_file_contents <- readr::read_csv(this_filepath) 
  number_of_rows <- nrow(this_file_contents)
  
  print(paste0("Checking for: ",variable))
  print(paste0(" is ",nrow(unique(this_file_contents[,1]))==number_of_rows))
}
```

## Q1-Summarize of sales data in different categories and find the top seller of each category

The first query is to analyze the sales data of sellers in different categories. We calculated each seller's total value by adding up the price of their order items and the cost of freight, grouped sellers in the same category, and then ranked the sellers in order of total revenue, with the highest revenue seller being considered the top seller.

```{r, eval=FALSE}
# Q1 SQL
Top_seller <- RSQLite::dbGetQuery(connection, 
"SELECT    
  pt.product_category_name_english, 
  oi.seller_id,                    
  SUM(oi.price) AS total_price,                    
  SUM(oi.freight_value) AS total_freight,
  SUM(oi.price)+SUM(oi.freight_value) AS total_value
FROM order_items AS oi 
LEFT JOIN products AS p 
  ON oi.product_id = p.product_id 
LEFT JOIN product_category_name_translation AS pt
  ON p.product_category_name = pt.product_category_name
WHERE  p.product_category_name NOTNULL 
GROUP BY p.product_category_name, oi.seller_id
ORDER BY p.product_category_name, total_value DESC")
```

```{r, eval=FALSE}
# Q1 R
R_Top_seller <- order_items %>%
  left_join(products, by = "product_id") %>%
  left_join(product_category_name_translation, 
            by = "product_category_name") %>%
  filter(!is.null(product_category_name)) %>%
  group_by(product_category_name_english, seller_id) %>%
  summarize(total_price = sum(price),
            total_freight = sum(freight_value),
            total_value = sum(price) + sum(freight_value)) %>%
  arrange(product_category_name_english, desc(total_value))
```

## Q2-What categories have average review score more than 4 and what is the lowest and highest review score of them?

Then, we proceeded to investigate the product categories that review scores exceeding a threshold of 4, with the intention of gaining a deeper understanding of the categories. The result shows that there are 47 categories which hold the relatively high customer satisfaction and the cds_dvds_musicals has the highest review score with 4.64.

```{r, eval=FALSE}
# Q2 SQL
reviewed_product <- RSQLite::dbGetQuery(connection, 
"SELECT  
  product_category_name_english,
  ROUND(AVG(review_score),2) AS avg_review_score,
  MIN(review_score) AS lowest_review_score,
  MAX(review_score) AS highest_review_score
FROM  products p
LEFT JOIN product_category_name_translation pcnt
  ON p.product_category_name = pcnt.product_category_name
LEFT JOIN order_items oi
  ON oi.product_id = p.product_id 
LEFT JOIN order_reviews or2
  ON oi.order_id = or2.order_id 
GROUP BY product_category_name_english
HAVING avg_review_score > 4
ORDER BY avg_review_score DESC")

```

```{r, eval=FALSE}
# Q2 R
R_reviewed_product <- products %>%
  inner_join(product_category_name_translation) %>%
  inner_join(order_items, by = "product_id") %>%
  inner_join(order_reviews, by = "order_id") %>%
  group_by(product_category_name_english) %>%
  summarise(
    avg_review_score = round(mean(review_score),2),
    lowest_review_score = round(min(review_score),2),
    highest_review_score = round(max(review_score),2)
  ) %>%
  filter(avg_review_score > 4) %>%
  arrange(desc(avg_review_score))

```

## Q3-Collect the top 10 popular product categories in state SP (measured by the total number of items been delivered)

For the third query, we collect the top 10 most popular product categories in the state of São Paulo, Brazil, as measured by the total number of items delivered. By doing so, we hope to gain insights into the purchasing behaviors of consumers in this state, which can be useful for businesses to develop effective marketing strategies and tailored to the specific needs of the local market.

```{r, eval=FALSE}
# Q3 SQL
Total_purchases <- RSQLite::dbGetQuery(connection, 
"SELECT 
  customer_state, 
  pcnt.product_category_name_english, 
  SUM(order_items.order_item_id) AS purchasing_times
FROM   order_items
INNER JOIN products 
  ON order_items.product_id = products.product_id
INNER JOIN orders 
  ON order_items.order_id = orders.order_id
INNER JOIN customers 
  ON orders.customer_id = customers.customer_id
INNER JOIN product_category_name_translation AS pcnt
  ON products.product_category_name = pcnt.product_category_name
WHERE customers.customer_state = 'SP' 
AND orders.order_status in ('delivered')
GROUP BY customers.customer_state, 
  pcnt.product_category_name_english
ORDER BY purchasing_times DESC LIMIT 10 ")
```

```{r, eval=FALSE}
# Q3 R
R_Total_purchases <- purchasing_times <- order_items %>%
  inner_join(products, by = "product_id") %>%
  inner_join(orders, by = "order_id") %>%
  inner_join(customers, by = "customer_id") %>%
  inner_join(product_category_name_translation, 
             by = c("product_category_name" = "product_category_name")) %>%
  filter(customer_state == "SP", order_status %in% c("delivered")) %>%
  group_by(customer_state, 
           product_category_name_english) %>%
  summarize(purchasing_times = sum(order_item_id)) %>%
  arrange(desc(purchasing_times)) %>%
  slice(1:10)

```

## Q4-How much revenue of all sellers that came from paid search in marketing leads can generate?

Additionally, the fourth query aims to assess the revenue generated by sellers from paid search in marketing leads, which can evaluate the effectiveness of marketing strategy.

```{r, eval=FALSE}
# Q4 SQL
revenue_paid_search <-   RSQLite::dbGetQuery(connection, 
"SELECT    
  oi.seller_id,
  cd.business_type,
  cd.business_segment,
  s.seller_state,    
  ROUND(SUM(oi.price)+SUM(oi.freight_value),2) AS total_revenue
FROM order_items AS oi 
LEFT JOIN closed_deals AS cd 
    ON oi.seller_id = cd.seller_id 
LEFT JOIN sellers AS s
    ON oi.seller_id = s.seller_id 
LEFT JOIN marketing_qualified_leads AS mq
    ON cd.mql_id = mq.mql_id
WHERE mq.origin = 'paid_search'
GROUP BY oi.seller_id, cd.business_type,
  cd.business_segment,s.seller_state
ORDER BY total_revenue DESC ")
```

```{r, eval=FALSE}
# Q4 R
R_revenue_paid_search <- order_items %>%
  left_join(closed_deals, by = "seller_id") %>%
  left_join(sellers, by = "seller_id") %>%
  left_join(marketing_qualified_leads, by = "mql_id") %>%
  filter(origin == "paid_search") %>%
  group_by(seller_id, business_type, business_segment, seller_state) %>%
  summarize(total_revenue = round(sum(price) + sum(freight_value), 2)) %>%
  arrange(desc(total_revenue))
```

## Q5-What is the proportion of each payment types per year?

Last but not least, we evaluate the total payment value associated with various payment methods over a given period of observation. Based on the result, a stable trend was observed in the years 2016 to 2018, indicating that the majority of customers preferred to use credit cards for their transactions, while a relatively small proportion of individuals were found to utilize debit cards during this time period.

```{r, eval=FALSE}
# Q5 SQL
highest_value_by_card <-   RSQLite::dbGetQuery(connection, 
"SELECT    
  strftime('%Y', DATE(o.order_purchase_timestamp , 'unixepoch')) AS purchase_year,
  op.payment_type,    
  ROUND(SUM(payment_value),2) AS total_value
FROM order_payments AS op 
LEFT JOIN orders o 
    ON o.order_id = op.order_id 
WHERE op.payment_type NOT IN ('not_defined')
GROUP BY purchase_year, op.payment_type
ORDER BY purchase_year DESC, total_value DESC
")
```

```{r, eval=FALSE}
# Q5 R
R_highest_value_by_card <- 
 order_payments %>%
  left_join(orders, by = "order_id") %>%
  filter(!payment_type %in% c("not_defined")) %>%
  group_by(purchase_year = year(ymd_hms(order_purchase_timestamp)), payment_type) %>%
  summarize(total_value = round(sum(payment_value), 2)) %>%
  arrange(desc(purchase_year), desc(total_value))
```
------------------------------------------------------------------------
