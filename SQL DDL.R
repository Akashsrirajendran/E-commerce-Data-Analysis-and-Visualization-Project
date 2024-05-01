# The SQL DDL

The proposed SQL DDL of each entity then determines the constraint and key to these new datasets. Creating a new database and setting up the tables with the highest normal form.

```{r eval=FALSE, echo=TRUE}
# Create new database
library(RSQLite)
connection <- RSQLite::dbConnect(RSQLite::SQLite(),"olist_import.db")
```

```{sql eval=FALSE, echo=TRUE}
--SQL DDL orders
CREATE TABLE 'orders' ( 
  'order_id' VARCHAR(50) PRIMARY KEY, 
  'customer_id' VARCHAR(50) NOT NULL,
  'order_status' TEXT NOT NULL,
  'order_purchase_timestamp' DATETIME NOT NULL,
  'order_approved_at' DATETIME,
  'order_delivered_carrier_date'DATETIME,
  'order_estimated_delivery_date' DATETIME NOT NULL,
  'order_delivered_customer_date' DATETIME,
  'shipping_limit_date' DATETIME NOT NULL,
  FOREIGN KEY('customer_id') 
  REFERENCES customers ('customer_id')
); 
```

```{sql eval=FALSE, echo=TRUE}
--SQL DDL items
CREATE TABLE 'items' ( 
  'order_item_id' INT NOT NULL,
  'order_id' VARCHAR(50) NOT NULL,
  'seller_id' VARCHAR(50) NOT NULL,
  'product_id' VARCHAR(50) NOT NULL,
  'price' REAL NOT NULL,
  'freight_value' REAL NOT NULL,
  PRIMARY KEY ('order_item_id','order_id'),
  FOREIGN KEY ('seller_id') 
  REFERENCES sellers ('seller_id'),
  FOREIGN KEY ('order_id') 
  REFERENCES orders ('order_id'),
  FOREIGN KEY ('product_id') 
  REFERENCES products ('product_id')
);  
```

```{sql eval=FALSE, echo=TRUE}
--SQL DDL product_seller
CREATE TABLE 'product_seller' ( 
  'seller_id' VARCHAR(50) NOT NULL,
  'product_id' VARCHAR(50) NOT NULL,
  PRIMARY KEY ('seller_id','product_id'),
  FOREIGN KEY ('seller_id') 
  REFERENCES sellers ('seller_id'),
  FOREIGN KEY ('product_id') 
  REFERENCES products ('product_id')
);  
```

```{sql eval=FALSE, echo=TRUE}
--SQL DDL products
CREATE TABLE 'products' ( 
  'product_id' VARCHAR(50) PRIMARY KEY, 
  'product_photos_qty' INT,
  'product_weight_g' INT,,
  'product_height_cm' INT,
  'product_width_cm'INT,
  'product_length_cm'INT,
  'product_description_lenght' INT,
  'product_name_lenght'INT,
  'product_category_name' VARCHAR(50),
  FOREIGN KEY ('product_category_name') 
  REFERENCES product_category_name ('product_category_name')
);  
```

```{sql eval=FALSE, echo=TRUE}
--SQL DDL sellers
CREATE TABLE 'sellers' (
  'seller_id' VARCHAR(50) PRIMARY KEY, 
  'seller_zip_code' INT NOT NULL,
  FOREIGN KEY ('seller_zip_code') 
  REFERENCES geolocation ('geolocation_zip_code')
);
```

```{sql eval=FALSE, echo=TRUE}
--SQL DDL product category name
CREATE TABLE 'product_category_name' (
  'product_category_name' VARCHAR(50) PRIMARY KEY,
  'product_category_name_english' VARCHAR(50) NOT NULL
);
```

```{sql eval=FALSE, echo=TRUE}
--SQL DDL customers
CREATE TABLE 'customers' (
  'customer_id' VARCHAR(50) PRIMARY KEY,
  'customer_unique_id' VARCHAR(50) NOT NULL, 
  'customer_zip_code' INT NOT NULL, 
  FOREIGN KEY ('customer_zip_code') 
  REFERENCES geolocation ('geolocation_zip_code')
);
```

```{sql eval=FALSE, echo=TRUE}
--SQL DDL geolocation
CREATE TABLE 'geolocation' (
  'geolocation_zip_code' INT PRIMARY KEY,
  'geolocation_state' VARCHAR(50) NOT NULL,
  'geolocation_city' VARCHAR(50) NOT NULL
);
```

```{sql eval=FALSE, echo=TRUE}
--SQL DDL geolocation_lat_lng
CREATE TABLE 'geolocation_lat_lng' (
  'zip_code' INT PRIMARY KEY,
  'geolocation_lng' REAL NOT NULL,
  'geolocation_lat' REAL NOT NULL,
  FOREIGN KEY ('zip_code') 
  REFERENCES geolocation ('geolocation_zip_code')
);
```

```{sql eval=FALSE, echo=TRUE}
--SQL DDL order_payments
CREATE TABLE 'order_payments' ( 
  'order_id' VARCHAR(50) NOT NULL,
  'payment_sequential' INT NOT NULL, 
  'payment_installments' INT NOT NULL,
  'payment_value' REAL NOT NULL,
  'payment_type' VARCHAR(50) NOT NULL,
  PRIMARY KEY ('order_id','payment_sequential'),
  FOREIGN KEY ('order_id') 
  REFERENCES orders ('order_id')
) ;  
```

```{sql eval=FALSE, echo=TRUE}
--SQL DDL reviews
CREATE TABLE 'reviews' ( 
  'review_id' VARCHAR(50) PRIMARY KEY, 
  'review_score' INT NOT NULL,
  'review_comment_title' VARCHAR(50),
  'review_comment_message' TEXT,
  'review_creation_date' DATETIME NOT NU,
  'review_answer_timestamp' DATETIME NOT NULL
) ;  
```

```{sql eval=FALSE, echo=TRUE}
--SQL DDL reviews_orders
CREATE TABLE 'reviews_orders' ( 
  'review_id' VARCHAR(50) NOT NULL, 
  'order_id' VARCHAR(50) NOT NULL,
  PRIMARY KEY ('review_id','order_id'),
  FOREIGN KEY ('order_id') 
  REFERENCES orders ('order_id'),
  FOREIGN KEY ('review_id') 
  REFERENCES reviews ('review_id')
) ;  
```

```{sql eval=FALSE, echo=TRUE}
--SQL DDL closed deals
CREATE TABLE 'closed_deals' (
  'mql_id' VARCHAR(50) PRIMARY KEY, 
  'seller_id' VARCHAR(50) NOT NULL,
  'sdr_id' VARCHAR(50) NOT NULL,
  'sr_id' VARCHAR(50) NOT NULL,
  'won_date' DATETIME NOT NULL,
  'business_segment' VARCHAR(50),
  'lead_type'VARCHAR(50),
  'lead_behaviour_profile_1' VARCHAR(25),
  'lead_behaviour_profile_2' VARCHAR(25),
  'has_company' VARCHAR(50),
  'has_gtin' VARCHAR(50),
  'average_stock' VARCHAR(50),
  'business_type' VARCHAR(50),
  'declared_product_catalog_size' INT,
  'declared_monthly_revenue' INT DEFAULT 0,
  FOREIGN KEY('seller_id') 
  REFERENCES sellers('seller_id')
);
```

```{sql eval=FALSE, echo=TRUE}
--SQL DDL marketing qualified leads
CREATE TABLE 'marketing_qualified_leads' (
  'mql_id' VARCHAR(50) PRIMARY KEY,
  'first_contact_date' DATE NOT NULL,
  'landing_page_id' VARCHAR(50) NOT NULL,
  'origin' VARCHAR(50) DEFAULT 'unknown',
  FOREIGN KEY('mql_id') 
  REFERENCES closed_deals('mql_id')
);
```