
-- First a simple look into the data:

Select *
From HousingData..NashvilleHousing$

-- Change the SaleDate:
-- Time is very long and it is not that important for now. I want to omit it.
Select SaleDate, CONVERT(Date,SaleDate)
From HousingData..NashvilleHousing$
-- New one looks better. Let's update.

Update NashvilleHousing$
SET SaleDate = CONVERT(Date,SaleDate)

-- Check if it is updated.
Select SaleDate
From HousingData..NashvilleHousing$
-- Sometimes this doesn't update.

-- Another way:
ALTER TABLE NashvilleHousing$
Add SaleDateConverted Date;

Update NashvilleHousing$
SET SaleDateConverted = CONVERT(Date,SaleDate)

Select SaleDateConverted
From HousingData..NashvilleHousing$

-- Now it is updated.


-- Property Adress column values seems to have some problems. We have nulls.
Select PropertyAddress
From HousingData..NashvilleHousing$
--Where PropertyAddress is null

-- Thinking from logical point of view, a property address should be almost always fixed.
-- So, if we can find a reference value for the null values, we can populate them.


-- What can be a reference ? Maybe the ParcelID and the relationship between that and property address can help me. 
Select *
From HousingData..NashvilleHousing$
order by ParcelID

-- Same ParcelD gives Same Property Address. (As expected)
-- Also, first 6 digits of parcel id, gives information about property address:
-- [Except this number part 1808]  FOX CHASE DR, GOODLETTSVILLE -> this part is same for other parcel id's starting with 007 00 0


-- I am going to do a self join:
Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
From HousingData..NashvilleHousing$ a
JOIN HousingData..NashvilleHousing$ b
on a.ParcelID = b.ParcelID
AND a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is null

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
From HousingData..NashvilleHousing$ a
JOIN HousingData..NashvilleHousing$ b
on a.ParcelID = b.ParcelID
AND a.[UniqueID ] <> b.[UniqueID ]

-- Successfully populated all null values in the property address.


-- Break a column into more than one column:
Select SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress) -1) as Address,
SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress) +1, LEN(PropertyAddress)) as City
From HousingData..NashvilleHousing$
-- When we do not include -1, we get address and comma at the end. I do not want the comma.

-- Now let me add these two columns to our main table:
ALTER TABLE NashvilleHousing$
Add City nvarchar(255)

Update NashvilleHousing$
SET City = SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress) +1, LEN(PropertyAddress))
From HousingData..NashvilleHousing$

ALTER TABLE NashvilleHousing$
Add Address nvarchar(255)

Update NashvilleHousing$
SET Address = SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress) -1)

-- Check if these actually worked or not.
Select *
From HousingData..NashvilleHousing$

-- Worked. But Change the name to PropAddress and PropCity so that there is no confusion:

-- Step 1: Add a new column
ALTER TABLE NashvilleHousing$
ADD PropAddress nvarchar(255);

-- Step 2: Update the new column with the data from the old column
UPDATE NashvilleHousing$
SET PropAddress = Address;

-- Step 3: Drop the old column
ALTER TABLE NashvilleHousing$
DROP COLUMN Address;


-- Step 1: Add a new column
ALTER TABLE NashvilleHousing$
ADD PropCity nvarchar(255);

-- Step 2: Update the new column with the data from the old column
UPDATE NashvilleHousing$
SET PropCity = City;

-- Step 3: Drop the old column
ALTER TABLE NashvilleHousing$
DROP COLUMN City;
-- Done.

-- Look into the owner address:
Select OwnerAddress
From HousingData..NashvilleHousing$

-- Let me use parsename:
Select
PARSENAME(REPLACE(OwnerAddress,',','.'),3) as OwnerAddressSplit,
PARSENAME(REPLACE(OwnerAddress,',','.'),2) as OwnerAddressCity,
PARSENAME(REPLACE(OwnerAddress,',','.'),1) as OwnerAddressState
From HousingData..NashvilleHousing$

-- Now let me add these to our main table:
ALTER TABLE NashvilleHousing$
Add OwnerAddressSplit nvarchar(255)

Update NashvilleHousing$
SET OwnerAddressSplit = PARSENAME(REPLACE(OwnerAddress,',','.'),3)

ALTER TABLE NashvilleHousing$
Add OwnerAddressCity nvarchar(255)

Update NashvilleHousing$
SET OwnerAddressCity = PARSENAME(REPLACE(OwnerAddress,',','.'),2)

ALTER TABLE NashvilleHousing$
Add OwnerAddressState nvarchar(255)

Update NashvilleHousing$
SET OwnerAddressState = PARSENAME(REPLACE(OwnerAddress,',','.'),1)

-- Check if it worked or not.
--Select *
--From HousingData..NashvilleHousing$
-- Done.

-- For consistency purposes, I want to change N to No, Y to Yes at the SoldAsVacant column.
Select Distinct(SoldAsVacant), COUNT(SoldAsVacant)
From HousingData..NashvilleHousing$
Group by SoldAsVacant
order by 2

-- I will use case statement:
Select SoldAsVacant,
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END
From HousingData..NashvilleHousing$

Update NashvilleHousing$
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END
-- Worked.


-- There are some duplicates, I want to remove them.
-- And there are some unused columns, I want to remove them too.
-- Normally, at an industrial application, I would NOT delete any data.


-- Identify duplicate rows (Assume there is no unique id column):
WITH RowNUMCTE as(
Select *,
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID,
				PropertyAddress,
				SaleDate,
				SalePrice,
				LegalReference
				ORDER BY UniqueID) row_num
From HousingData..NashvilleHousing$
)
DELETE
From RowNUMCTE
--Order by ParcelID
where row_num >1
-- Deleted duplicate rows.


-- Delete OwnerAddress and PropertyAddress columns because we have the better versions of them:

ALTER TABLE HousingData..NashvilleHousing$
DROP COLUMN OwnerAddress, PropertyAddress

Select *
From HousingData..NashvilleHousing$

-- It worked.

-- SaleDate should fly away too :)
ALTER TABLE HousingData..NashvilleHousing$
DROP COLUMN SaleDate

-- Now the dataset is easier to use and cleaner.