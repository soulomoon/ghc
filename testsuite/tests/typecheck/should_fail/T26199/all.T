test('T26199', [extra_files(['A.hs', 'B.hs', 'B.hs-boot', 'C.hs', 'C.hs-boot', 'Other.hs', 'T26199.hs'])], multimod_compile_fail, ['T26199', '-v0'])
