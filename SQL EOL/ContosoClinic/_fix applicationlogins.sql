-- ============================================
-- Step 1) Create new logins
-- ============================================

-- Launch website and create 3 new logins, nurse1, nurse2 and admin
-- We need to do this since the password is not valid from original github repo

-- ============================================
-- Step 2) Update ApplicationUserPatients
-- ============================================

select * from AspNetUsers


update ApplicationUserPatients
set ApplicationUser_Id = '56ed68b1-f0f8-4509-87b6-764947af53b0'
where ApplicationUser_Id = '2ba087ec-d8c3-4955-9a9d-c6719dc29ec2' --alice


update ApplicationUserPatients
set ApplicationUser_Id = 'a7b56e65-e4b7-45f3-93f5-056cc180cb77'
where ApplicationUser_Id = '9606e906-6d94-4fa7-a881-a6efceeaa232' --rachael
