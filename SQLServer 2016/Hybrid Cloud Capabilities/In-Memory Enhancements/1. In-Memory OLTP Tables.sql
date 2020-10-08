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
