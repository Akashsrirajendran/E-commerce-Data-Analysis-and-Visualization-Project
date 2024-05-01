# Data cleaning and normalization

In the step of checking and cleaning data records, there are 8 tables that have missing, empty, or duplicate values. The normalization step is required. These issues are identified below.

```{r setup, include=FALSE}
knitr::opts_chunk$set(echo = TRUE)
library(readr)
library(dplyr)
library(hunspell)
```

```{r name, message=FALSE, warning=FALSE, include=FALSE}

setwd("./data")

# Get file name and clean to have proper name
olist_files <- list.files()
olist_names <- list.files()

prefix <- "olist_"
suffix <- "_dataset.csv"

olist_names <- gsub("olist_","",olist_files)
olist_names <- gsub("_dataset.csv","",olist_names)
olist_names <- gsub("_qualified","",olist_names)
olist_names <- gsub(".csv","",olist_names)
olist_names

```

```{r loop,message=FALSE,warning=FALSE, include=FALSE}
# Create object in based on files and names
for (n in 1:length(olist_files)) {
  assign(olist_names[n], read.csv(olist_files[n]))
}

```

```{r eval=FALSE, echo=TRUE}
#Import all data files and read CSV, then make a list of datafiles' name in 'datasets'
datasets <- list(customers, geolocation, order_items, order_payments,
                 order_reviews, orders , products, sellers,
                 product_category_name_translation, closed_deals, marketing_leads)

#Check initial missing data
for (i in 1:length(datasets)) {
  cat("Dataset", i, "has", sum(is.na(datasets[[i]])), "missing values. \n")
}

#Check attributes in each table and data type
for (i in 1:length(datasets)) {
  cat("Dataset", i, "has the following columns:\n")
  colnames <- names(datasets[[i]])
  for (col in colnames) {
    cat("* Column", col, "is of type", class(datasets[[i]][[col]]), "\n")
    if (any(is.na(datasets[[i]][[col]]))) {
      cat("  - Missing values found in column", col, "\n")
    }
    if (class(datasets[[i]][[col]]) == "factor") {
      cat("  - Factor levels for column", col, ": ", levels(datasets[[i]][[col]]), "\n")
    }
  }
  cat("\n")
}

```

```{r eval=FALSE, echo=TRUE}
#Check initial presence of duplicates
duplicates <- anyDuplicated(datasets)

if(duplicates != 0) {
  datasets[duplicates]
} else {
  message("No duplicates found!")
}
```

## Orders table

-   There is no missing value, assuming that blank data is intentionally left blank for future input.
-   This dataset could fails 1NF because of blank values, but these values are deterministic based on order_status (e.g. a shipped order may have a delivered_carrier_date but not a delivered_customer_date, whereas an invoiced order will have neither). We recommend fill in these blank values with 'NA' values as all other values are atomic. There is only 1 primary key (order_id) which meets 2NF by default. All functional dependencies are between this primary key and non-key attributes so 3NF is met.

```{r , message=FALSE, warning=FALSE}
# Count distinct data and NA value
orders %>%
  sapply(function(x) c(count = length(x), 
                       count_distinct = n_distinct(x), 
                       count_na = sum(is.na(x))))%>%
  t()%>%
  kableExtra::kable()%>%
  kableExtra::kable_styling(latex_options = "HOLD_position", 
                            position ="center", font_size = 7)
```

## Items table

-   The dataset is in 1NF, as each entry is an atomic value. There is a composite primary key(order_id & order_item_id).
-   This partial FD fails 2NF as we assume that order_id alone determines shipping_limit_date and 336 rows (less than 1%) that have different shipping_limit_date are recorded incorrectly. Furthermore, we have the transitive FD from the key attribute order_id & order_item_id -\> order_product_id -\> order_seller_id. order_product_id is not a candidate key hence this would fail 3NF.
-   To meet 2NF, we suggest removing shipping_limit_date to the orders dataset where order_id is a primary key. In order to further normalise this into 3NF, we recommend creating another table with product_id and seller_id as composite primary key.

```{r , message=FALSE, warning=FALSE}
# Count distinct data and NA value
order_items %>%
  sapply(function(x) c(count = length(x), 
                       count_distinct = n_distinct(x), 
                       count_na = sum(is.na(x))))%>%
  t()%>%
  kableExtra::kable()%>%
  kableExtra::kable_styling(latex_options = "HOLD_position", 
                            position ="center", font_size = 7)
```

## Products table

-   There are approximately 2% of all products that have missing value in some of the columns; however, these products do exist because they have been sold and delivered to customers.
-   1NF is satisfied as each entry is an atomic value. There is only 1 primary key (product_id) so we meet 2NF by default. There is no transitive FD of a non-key attribute on a key attribute (i.e. non-key attributes; the product dimension variables and product_category_name all depend directly on product_id and not on each other). Therefore this dataset is in 3NF.

```{r , message=FALSE, warning=FALSE}
# Count distinct data and NA value
products %>%
  sapply(function(x) c(count = length(x), 
                       count_distinct = n_distinct(x), 
                       count_na = sum(is.na(x))))%>%
  t()%>%
  kableExtra::kable()%>%
  kableExtra::kable_styling(latex_options = "HOLD_position", 
                            position ="center", font_size = 7)
```

```{r}

products %>%
  mutate_all(na_if,"")%>%
  left_join(order_items, by = "product_id") %>%
  filter(	is.na(product_category_name), !is.na(order_id))%>%
  head(3)%>%
  t()%>%
  kableExtra::kable()%>%
  kableExtra::kable_styling(latex_options = "HOLD_position",
                            position ='center', font_size = 7)

```

## Sellers table

-   'seller_city' and 'seller_state' attributes are considered redundant as they already exist in the geolocation table. City names are written in different formats and spellings.
-   1NF is satisfied as each entry is an atomic value. There is only 1 primary key (seller_id) so we meet 2NF by default. However, we have the transitive FD from the key attribute seller_id -\> seller_zip_code_prefix -\> seller_state with seller_zip_code_prefix not a key attribute. This fails 3NF.
-   We suggest to delete the seller_city and seller_state attributes, as their relationship with zip code already exists in the geolocation dataset.

```{r , message=FALSE, warning=FALSE}
# Count distinct data and NA value
sellers %>%
  sapply(function(x) c(count = length(x), 
                       count_distinct = n_distinct(x), 
                       count_na = sum(is.na(x))))%>%
  t()%>%
  kableExtra::kable()%>%
  kableExtra::kable_styling(latex_options = "HOLD_position", 
                            position ="center", font_size = 7)
```

```{r}
#Example of incorrect name for Sao Paulo
sellers %>%
  filter(grepl('sao p', seller_city, ignore.case = TRUE))%>%
  distinct(seller_city)%>%
  arrange(seller_city)%>%
  head(10)%>%
  kableExtra::kable()%>%
  kableExtra::kable_styling(latex_options = "HOLD_position", 
                            position ="center", font_size = 7)
```

## Category name translation table

-   1NF is satisfied as each entry is an atomic value. Both the attributes are candidate keys so 2NF and 3NF are both satisfied by default as there are no non-key attributes the dataset is in 3NF.

```{r , message=FALSE, warning=FALSE}
# Count distinct data and NA value
product_category_name_translation %>%
  sapply(function(x) c(count = length(x), 
                       count_distinct = n_distinct(x), 
                       count_na = sum(is.na(x))))%>%
  t()%>%
  kableExtra::kable()%>%
  kableExtra::kable_styling(latex_options = "HOLD_position", 
                            position ="center", font_size = 7)
```

## Customer table

-   'customer_city' and 'customer_state' attributes are considered redundant as they already exist in the geolocation table.
-   First normal form is satisfied as each entry is an atomic value. Second normal form is satisfied by default as there is only 1 primary key (customer_id). However, there is the transitive FD from the key attribute customer_id -\> customer_zip_code_prefix -\> customer_state and customer_zip_code_prefix is not a key attribute. This fails 3NF.
-   We suggest to delete the customer_city and customer_state attributes, as their relationship with zip code already exists in the geolocation dataset.

```{r , message=FALSE, warning=FALSE}
# Count distinct data and NA value
customers %>%
  sapply(function(x) c(count = length(x), 
                       count_distinct = n_distinct(x), 
                       count_na = sum(is.na(x))))%>%
  t()%>%
  kableExtra::kable()%>%
  kableExtra::kable_styling(latex_options = "HOLD_position", 
                            position ="center", font_size = 7)
```

## Geolocation table

-   Assuming that the original data used latitude and longitude as primary keys because it is the smallest unit, it leads to many duplicates in zip code, city, and state data. These coordinates can also not be related to other entities.
-   First normal form is satisfied as each entry is an atomic value (latitude and longitude are separate columns). There is a composite key formed of geolocation_lat and geolocation_lng. There is no partial FD for any non-key attribute on either of composite key, therefore the dataset is 2NF. However, we have the transitive FD from the key attribute geolocation_lat & geolocation_lng -\> geolocation_zip_code_prefix -\> geolocation_state. geolocation_zip_code_prefix is not a candidate key hence this fails 3NF.
-   To normalise this into 3NF, we suggest deleting latitude and longitude variables from the geolocation dataset, giving zip_code_prefix, city, and state, and making the zip code as the primary key. The new table includes zip code, latitude, and longitude.
-   City names should be written in the same format and spelling, and check that they are in the right state.

```{r , message=FALSE, warning=FALSE}
# Count distinct data and NA value
geolocation %>%
  sapply(function(x) c(count = length(x), 
                       count_distinct = n_distinct(x), 
                       count_na = sum(is.na(x))))%>%
  t()%>%
  kableExtra::kable()%>%
  kableExtra::kable_styling(latex_options = "HOLD_position", 
                            position ="center", font_size = 7)
```

```{r}
#Example of incorrect name for Sao Paulo

geolocation %>%
  filter(grepl('paulo', geolocation_city, ignore.case = TRUE))%>%
  distinct(geolocation_city)%>%
  arrange(desc(geolocation_city))%>%
  head(10)%>%
  kableExtra::kable()%>%
  kableExtra::kable_styling(latex_options = "HOLD_position", 
                            position = 'center', font_size = 7)

```

## Payments table

-   This dataset satisfied is in 1NF, 2NF, and 3NF. Each entry is an atomic value. There is a composite key of order_id & payment_sequential. There is no partial FD for any non-key attribute on either of composite keys. Furthermore, no non-key attribute functionally depends on another non-key attribute (i.e payment_value, payment_installments and payment_type cannot be obtained without the whole composite key).

```{r , message=FALSE, warning=FALSE}
# Count distinct data and NA value
order_payments %>%
  sapply(function(x) c(count = length(x), 
                       count_distinct = n_distinct(x), 
                       count_na = sum(is.na(x))))%>%
  t()%>%
  kableExtra::kable()%>%
  kableExtra::kable_styling(latex_options = "HOLD_position", 
                            position ="center", font_size = 7)
```

## Reviews table

-   There is no missing value, assuming that blank data is intentionally left blank because the comment is not required from customer input.
-   The dataset is in 1NF, as each entry is an atomic value. There is a composite primary key (review_id&order_id).This partial FD fails 2NF as we assume that review_id alone determines review_score. We suggest removing order_id and creating another table with review_id and order_id as a composite primary key. This also should make this dataset 3NF.

```{r , message=FALSE, warning=FALSE}
# Count distinct data and NA value
order_reviews %>%
  sapply(function(x) c(count = length(x), 
                       count_distinct = n_distinct(x), 
                       count_na = sum(is.na(x))))%>%
  t()%>%
  kableExtra::kable()%>%
  kableExtra::kable_styling(latex_options = "HOLD_position", 
                            position ="center", font_size = 7)
```

## Closed deals table

-   There are many attributes that have missing value, which are the details of the seller. This could be due to insufficient data collection or the company failing to provide them to Olist. Original data input are not in the same format, for example, average_stock includes both number and date, which we assume the date data is wrong and should be number.
-   This dataset fails 1NF as the lead_behaviour_profile is multivalued attribute which contain up to 2 values such as 'cat, wolf'. We suggest to split into 2 attributes to separately store them and fill in blank data with NA. There is only 1 primary key (mql_id) and 1 candidate key (seller_id), so 2NF will be satisfied by not having partial FD. All attribute depend on this primary key and all closed deal become seller_id, so this data is satisfied 3NF.

```{r , message=FALSE, warning=FALSE}
# Count distinct data and NA value
closed_deals %>%
  sapply(function(x) c(count = length(x), 
                       count_distinct = n_distinct(x), 
                       count_na = sum(is.na(x))))%>%
  t()%>%
  kableExtra::kable()%>%
  kableExtra::kable_styling(latex_options = "HOLD_position", 
                            position ="center", font_size = 7)
```

```{r}
#Example of lead behaviour

closed_deals %>%
  distinct(lead_behaviour_profile)%>%
  kableExtra::kable()%>%
  kableExtra::kable_styling(latex_options = "HOLD_position", 
                            position = 'center', font_size = 7)
```

## Marketing qualified leads table

-   There is less than 1% of data that has a missing value from origin attribute. We propose to convert the missing value to 'unknown' instead.
-   1NF is satisfied as each entry is an atomic value. We have one candidate key (mql_id). Hence 2NF is satisfied by default. There are no functional dependencies between any non-key attributes which satisfies 3NF. This dataset is in 3NF.

```{r , message=FALSE, warning=FALSE}
# Count distinct data and NA value
marketing_leads %>%
  sapply(function(x) c(count = length(x), 
                       count_distinct = n_distinct(x), 
                       count_na = sum(is.na(x))))%>%
  t()%>%
  kableExtra::kable()%>%
  kableExtra::kable_styling(latex_options = "HOLD_position",
                            position ="center", font_size = 7)
```
