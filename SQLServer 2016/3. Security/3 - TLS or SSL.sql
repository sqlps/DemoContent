-- ==========================================
-- Step 1) Check if connections are encrypted
-- ===========================================
Select * from sys.dm_exec_connections
where encrypt_option = 'TRUE'

-- =================================================
-- Step 2) Enable TLS Encryption from Config Manager
-- =================================================

-- ====================================
-- Step 3) ReCheck connections
-- ====================================
Select * from sys.dm_exec_connections
where encrypt_option = 'TRUE'

exec xp_readerrorlog 0, 1, cert

-- =====================================================
-- Step 4) View traffic from Message Analyzer (Optional)
-- =====================================================