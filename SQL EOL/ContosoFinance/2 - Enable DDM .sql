-- Run Data Classification and Show Masking from Portal

select * from customers

Update Customers
Set CreditCardNumber = '8613-7945-1563-0122'
Where CustomerID = 1


Update Customers 
Set CreditCardNumber = (
SELECT
LEFT(CreditCardNumber,4)+'-'+SUBSTRING(CreditCardNumber,5,4)+'-'+SUBSTRING(CreditCardNumber,9,4)+'-'+SUBSTRING(CreditCardNumber,13,4)
from Customers B
where Customers.CreditCardNumber=B.CreditCardNumber)

where CustomerID = 2

Go


