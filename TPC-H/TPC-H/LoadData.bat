bcp [tpc-H_500].dbo.orders in "H:\TPC-H Toolkit\2.17.3\dbgen\orders.tbl" -f E:\Demos\TPC-H\FORMATFILES\orders.fmt -S w2k16-s17-01 -T -b100000
bcp [tpc-H_500].dbo.partsupp in "H:\TPC-H Toolkit\2.17.3\dbgen\partsupp.tbl" -f E:\Demos\TPC-H\FORMATFILES\partsupp.fmt -S w2k16-s17-01 -T -b100000
bcp [tpc-H_500].dbo.customer in "H:\TPC-H Toolkit\2.17.3\dbgen\customer.tbl" -f E:\Demos\TPC-H\FORMATFILES\customer.fmt -S w2k16-s17-01 -T -b100000
bcp [tpc-H_500].dbo.part in "H:\TPC-H Toolkit\2.17.3\dbgen\part.tbl" -f E:\Demos\TPC-H\FORMATFILES\part.fmt -S w2k16-s17-01 -T -b100000
bcp [tpc-H_500].dbo.Supplier in "H:\TPC-H Toolkit\2.17.3\dbgen\supplier.tbl" -f E:\Demos\TPC-H\FORMATFILES\SUPPLIER.fmt -S w2k16-s17-01 -T -b100000
bcp [tpc-H_500].dbo.nation in "H:\TPC-H Toolkit\2.17.3\dbgen\nation.tbl" -f E:\Demos\TPC-H\FORMATFILES\NATION.fmt -S w2k16-s17-01 -T -b100000
bcp [tpc-H_500].dbo.region in "H:\TPC-H Toolkit\2.17.3\dbgen\region.tbl" -f E:\Demos\TPC-H\FORMATFILES\REGION.fmt -S w2k16-s17-01 -T -b100000