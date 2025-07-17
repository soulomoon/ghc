test('T26154', [extra_files(['A.hs', 'B.hs', 'B.hs-boot', 'Other.hs'])], multimod_compile, ['T26154', '-v0'])
