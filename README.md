# L4G4_DataDestroyers
DATA201/422 Group Project Group L4G4

## Description:
This is a group project based on the data set listings.csv.
!!!Cont desc!!!

## Installation:

## AirBnB Data Set:

| Column Name | Data Type | Description |
|---|---|---|
| `id` | Integer | Primary key / Unique identifier for the listing |
| `name` | Text | Name or title of the Airbnb listing |
| `host_id` | Integer | Unique identifier for the property host |
| `host_name` | Text | First name of the host |
| `neighbourhood_group` | Text | Region (e.g., Auckland, Wellington, Canterbury) |
| `neighbourhood` | Text | Local area, suburb, or ward |
| `latitude` | Numeric | Latitude coordinates (WGS84 format) |
| `longitude` | Numeric | Longitude coordinates (WGS84 format) |
| `room_type` | Text | Property classification: `Entire place`, `Private room`, or `Shared room` |
| `price` | Currency | Nightly rate listed in New Zealand Dollars (NZD) |
| `minimum_nights` | Integer | Minimum required length of stay in nights |
| `number_of_reviews` | Integer | Total reviews received by the listing |
| `last_review` | Date | Date of the most recent review (`YYYY-MM-DD`) |
| `reviews_per_month` | Numeric | Average number of reviews per month over the lifetime of the listing |
| `calculated_host_listings_count` | Integer | Total number of listings owned by the host at the time of the scrape |
| `availability_365` | Integer | Number of available days in the upcoming 365 days |
| `number_of_reviews_ltm` | Integer | Number of reviews received in the last 12 months |
| `license` | Text | License, permit, or registration number (if applicable under local council regulations) |



### Source:
Sourced from Inside AirBnB
https://insideairbnb.com/get-the-data/ - New Zealand


### Note:
#### Room Type Categories

The room_type column may contain the following values:

- Entire home/apt: Guests have access to the entire property.
- Private room: Guests have a private bedroom but may share other spaces.
- Shared room: Guests share the sleeping area with other people.

#### Availability_365

The availability_365 value should not be interpreted directly as the number of vacant days.

A listing may be unavailable because:

- it has already been booked;
- the host has blocked the date;
- the listing is temporarily inactive; or
- booking restrictions have been applied.

#### Reviews per Month

If the number of days between the scrape date and the first review is 30 or fewer:

    reviews_per_month = number_of_reviews

Otherwise:

    reviews_per_month =
        number_of_reviews /
        ((scrape_date - first_review + 1) / (365 / 12))



### Christchurch Data Cleaning Log

__1.  Dropped columns with no analytical value__   
license: 100% missing in this data set: zero information, drop entirely  
neighbourhood_group: constant "Christchurch City", no analytical value  
name, host_name: personal-identifier columns not needed for numeric analysis, also privacy considerations.  

  
__2.  Handled missing prices__  
price is important to rent comparison with the bond dataset,so rows with no price are not usable for that purpose. We drop them rather than impute, since imputing a price would fabricate rent data.  

__Result:__   
Number of rows lost: 10667  
Remaining rows:  18128  

___

## Bond Data Set:

| Column Name | Data Type | Description |
|---|---|---|
| `TimeFrame` | Date | Quarter the rental data relates to |
| `Location Id` | Integer | Unique identifier for the location |
| `Dwelling Type` | Text | Type of dwelling |
| `Number Of Beds` | Integer | Number of bedrooms in the dwelling |
| `Total Bonds` | Integer | Total number of rental bonds |
| `Active Bonds` | Integer | Number of active rental bonds |
| `Closed Bonds` | Integer | Number of closed rental bonds |
| `Median Rent` | Currency | Median weekly rent in New Zealand Dollars (NZD) |
| `Geometric Mean Rent` | Currency | Average weekly rent calculated using the geometric mean |
| `Upper Quartile Rent` | Currency | Weekly rent at the upper quartile |
| `Lower Quartile Rent` | Currency | Weekly rent at the lower quartile |
| `Log Std Dev Weekly Rent` | Numeric | Measure of variation in weekly rent |

### Bond Data Source:

Sourced from Tenancy Services – Rental Bond Data

Dataset: Detailed Quarterly Report, Q1 2020 – Q3 2026

[Tenancy Services – Rental Bond Data](https://www.tenancy.govt.nz/about-tenancy-services/data-and-statistics/rental-bond-data/)
('The Ministry of Business, Innovation and Employment') 


### Bond Data Description:

The dataset contains quarterly rental bond information for different locations, dwelling types and numbers of bedrooms across New Zealand. The data includes rental bond counts and weekly rental prices.


### Bond Data Cleaning Log
__1. Filter on date range__  
 01 Oct 2025 to 30 June 2026, to match Christchurch data



__2.  Dropped columns with no analytical value__   



__