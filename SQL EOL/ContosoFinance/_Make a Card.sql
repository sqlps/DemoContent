Update Customers 
Set CreditCardNumber = (
SELECT
LEFT(CreditCardNumber,4)+'-'+SUBSTRING(CreditCardNumber,5,4)+'-'+SUBSTRING(CreditCardNumber,9,4)+'-'+SUBSTRING(CreditCardNumber,13,4)
from Customers B
where Customers.CreditCardNumber=B.CreditCardNumber)



-- Add Column
ALTER TABLE person.person ADD CreditCard char(20)

--Change the values
declare @id int, @maxid int, @Upper INT = 9999, @Lower INT = 1000
Select @id = min(BusinessEntityID), @maxid = max(BusinessEntityId) from PERSON.Person

while (@id <=@maxid)
BEGIN
	Update Person.Person
	Set CreditCard = cast(ROUND(((@Upper - @Lower -1) * RAND() + @Lower), 0) as char(4))+'-'+cast(ROUND(((@Upper - @Lower -1) * RAND() + @Lower), 0) as char(4))+'-'+cast(ROUND(((@Upper - @Lower -1) * RAND() + @Lower), 0) as char(4))+'-'+cast(ROUND(((@Upper - @Lower -1) * RAND() + @Lower), 0) as char(4))
	where BusinessEntityID = @id
	Set @id+=1
END