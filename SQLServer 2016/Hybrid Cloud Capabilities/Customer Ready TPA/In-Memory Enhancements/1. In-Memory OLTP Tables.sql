/* This Sample Code is provided for the purpose of illustration only and is not intended 
to be used in a production environment.  THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE 
PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR 
PURPOSE.  We grant You a nonexclusive, royalty-free right to use and modify the Sample Code
and to reproduce and distribute the object code form of the Sample Code, provided that You 
agree: (i) to not use Our name, logo, or trademarks to market Your software product in which
the Sample Code is embedded; (ii) to include a valid copyright notice on Your software product
in which the Sample Code is embedded; and (iii) to indemnify, hold harmless, and defend Us and
Our suppliers from and against any claims or lawsuits, including attorneys’ fees, that arise or 
result from the use or distribution of the Sample Code.
*/


-- ===================================
-- Step 1) TicketReservation Demo
-- ===================================

-- 1. Run Ticket Reservations program get baseline
-- 2. Stop and get a count
Use TicketReservations
GO

Select count(*) from TicketReservationDetail

-- 3. Make the following changes:
-- - Change TicketReservations.sql to a memory-optimized table (instructions commented in the file itself)
-- - Change InsertTicketReservations.sql to natively compiled (instructions in the same file)
-- - Publish the DB and rerun program

-- 4. Stop and get a count
Use TicketReservations
GO

Select count(*) from TicketReservationDetail
