files = %w[06ae0a72f481c57e8b1f698c9cda813344bf1367.zip 47fa09adab93e048451e97cee5798189c5d247d6.zip 8e344e6b2a1f16ae4a16d480d8139c82a7f291c4.zip d32e4e7d317d4f8a211c1708cb6a8adffed73fd0.zip 090e570bec8418bf04878cc7d16a54b1cfe59012.zip 48c05da98c24647acf6e897de5f8fda082e4eb02.zip 93ce1f706dedd516ac06eec344cd0ae4644aa39c.zip d4452cbfb5983a90d4ac64a681e9bf0386ef300e.zip 12f4edb1795f64f7b9e4abf6525528636c3783f7.zip 53e21423a05825173de0bec9c73e9d956587991b.zip 954fa9714023cb22090e724814ce9d6d1df1af4d.zip d826468254617b8155861cd925e1b108534d2542.zip 1a825fc70e3eb76b03183338a38a9fa3e15ac566.zip 57d4af16cdd1adc0d18af45c538a318c41d97d74.zip a20fba5f5ee4698f05cff66e04c4061bf34a8f03.zip d9b7628c0bc296c7433b85a46e33b1525dd14729.zip 1c5069344c9178b92d6baef97f560b6986b2b35c.zip 589494b37b6f391ccf23529f431644f4ad0cf02c.zip a849e9bfcc4f3d004df0b5d9ad1952d17ad67797.zip da996a5ebf26136d31c31c675601f96a68f8f5f8.zip 1c636ad589e2ae44700126c5330ce7f5796e6b43.zip 6ad10d644c5155b586123ff0fe549c17506b80ad.zip aabe67014fa6c40c76f5f5f1e4c04cd2e4bf4dce.zip e3dd2d58868a45b682adfa0b53b122532e958397.zip 22e2e768370931e2963d09ff770fbe7c502617c8.zip 6faf53d99b53428784ad3d88b0ae54eca7fd31af.zip af0fbef7fd4ab399f24b51e32a09d27d6704952d.zip e577449386639b4f394641854bdb6fb4b614cd4e.zip 23ae94497147ce2d4ea508f9b0e120328ca50273.zip 72da8b7da212bf480309262b3d1e22f5bb41bebb.zip b22c327775ff85a42a6a9c1fcb53fb4d56e5eedf.zip ecd7b6626b25a040c07a842e41b66882ecf2f224.zip 24fb7d648ef3d1ed1a2b820fe24c37f25afbe356.zip 7918a92ad61461e916a73d5120d5ba74873aafce.zip b62c33d9b02eaccc0490f381903b78884343a7d1.zip f022129265f9d0c7d19ff054f4c3571b09dc4d0f.zip 2849e32aa3c854d0f6f6693fea96f1eda6334f05.zip 7b45f3b802f80ebd534a470644b2fddb2ee781e2.zip bfebe5e135d74091a377d8898ed6c39173110a73.zip f1e5c9885846d6929033ac17b6c1379d53222f9f.zip 298d5d055e8104d3fefea71b4b82772afa0415e7.zip 817bd0ef86b8117ff5bfa3b7400d6032929a47a6.zip c3de4da8e3752ac6d4c6773de86d4d62fc217251.zip f370fe393417f8f7d5d7d0e8c4c37a48a0126193.zip 2ae243c8c0e7d12cb848be9f53317abe621e797e.zip 830527b19250e7bd5880f327e7d542b973dcf62f.zip c4d612efb457e888246ec249cc6943b01d8ebc04.zip f4c392cb1b40b3381d9f87ade2d9cdb42f90722e.zip 41d824f458fa51930a7480d031b038fabdd6fc40.zip 8793709605ca45a08994b3de688e4bff0ae511ad.zip ce070e2003b113537fc0bf634affc9688ee5e860.zip fc2865a1be9c01ea22ef4b9d2808470e47863d2e.zip 42119695bf284b907e79e0df1fc9c8beafe678ba.zip 8808cef52e52d4e360384aab422e94124497a337.zip d1d4277b971d134a36b334d1b851f993153ae61d.zip]

i = 0
files.each do |file_name|
  i += 1
  pp `cf run-task dluhc-core-production --command "bundle exec rake core:sales_data_import_field['owning_organisation_id','#{file_name}']" --name sales_owning_org_field_import_2.#{i}`
end
