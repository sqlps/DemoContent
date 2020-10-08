bcp [tpc-H_500GB].dbo.lineitem format nul -f E:\Demos\TPC-H\FORMATFILES\LINEITEM.fmt -S w2k16-s17-01 -T
bcp [tpc-H_500GB].dbo.lineitem in "H:\TPC-H Toolkit\2.17.3\dbgen\lineitem.tbl" -f E:\Demos\TPC-H\FORMATFILES\lineitem.fmt -S w2k16-s17-01 -T -b100000
2,147,482,867 rows copied.
Network packet size (bytes): 4096
Clock Time (ms.) Total     : 20356500 Average : (105493.72 rows per sec.)


bcp [tpc-H_500GB].dbo.orders format nul -f E:\Demos\TPC-H\FORMATFILES\ORDERS.fmt -S w2k16-s17-01 -T
bcp [tpc-H_500GB].dbo.orders in "H:\TPC-H Toolkit\2.17.3\dbgen\orders.tbl" -f E:\Demos\TPC-H\FORMATFILES\orders.fmt -S w2k16-s17-01 -T -b100000

bcp [tpc-H_500GB].dbo.partsupp format nul -f E:\Demos\TPC-H\FORMATFILES\PARTSUPP.fmt -S w2k16-s17-01 -T
bcp [tpc-H_500GB].dbo.partsupp in "H:\TPC-H Toolkit\2.17.3\dbgen\partsupp.tbl" -f E:\Demos\TPC-H\FORMATFILES\partsupp.fmt -S w2k16-s17-01 -T -b100000

bcp [tpc-H_500GB].dbo.customer format nul -f E:\Demos\TPC-H\FORMATFILES\CUSTOMER.fmt -S w2k16-s17-01 -T
bcp [tpc-H_500GB].dbo.customer in "H:\TPC-H Toolkit\2.17.3\dbgen\customer.tbl" -f E:\Demos\TPC-H\FORMATFILES\customer.fmt -S w2k16-s17-01 -T -b100000

bcp [tpc-H_500GB].dbo.part format nul -f E:\Demos\TPC-H\FORMATFILES\PART.fmt -S w2k16-s17-01 -T
bcp [tpc-H_500GB].dbo.part in "H:\TPC-H Toolkit\2.17.3\dbgen\part.tbl" -f E:\Demos\TPC-H\FORMATFILES\part.fmt -S w2k16-s17-01 -T -b100000

bcp [tpc-H_500GB].dbo.supplier format nul -f E:\Demos\TPC-H\FORMATFILES\SUPPLIER.fmt -S w2k16-s17-01 -T
bcp [tpc-H_500GB].dbo.Supplier in "H:\TPC-H Toolkit\2.17.3\dbgen\supplier.tbl" -f E:\Demos\TPC-H\FORMATFILES\SUPPLIER.fmt -S w2k16-s17-01 -T -b100000


bcp [tpc-H_500GB].dbo.nation format nul -f E:\Demos\TPC-H\FORMATFILES\NATION.fmt -S w2k16-s17-01 -T -b100000
bcp [tpc-H_500GB].dbo.nation in "H:\TPC-H Toolkit\2.17.3\dbgen\nation.tbl" -f E:\Demos\TPC-H\FORMATFILES\NATION.fmt -S w2k16-s17-01 -T -b100000

bcp [tpc-H_500GB].dbo.region format nul -f E:\Demos\TPC-H\FORMATFILES\REGION.fmt -S w2k16-s17-01 -T -b100000
bcp [tpc-H_500GB].dbo.region in "H:\TPC-H Toolkit\2.17.3\dbgen\region.tbl" -f E:\Demos\TPC-H\FORMATFILES\REGION.fmt -S w2k16-s17-01 -T -b100000