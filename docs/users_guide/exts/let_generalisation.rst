.. _mono-local-binds:

Let-generalisation
------------------

.. extension:: MonoLocalBinds
    :shortdesc: Enable do not generalise local bindings.
        Implied by :extension:`TypeFamilies` and :extension:`GADTs`.

    :implied by: :extension:`TypeFamilies`, :extension:`GADTs`
    :since: 6.12.1
    :status: Included in :extension:`GHC2024`

    Infer less polymorphic types for local bindings by default.

An ML-style language usually generalises the type of any let-bound or where-bound variable, so that it is as polymorphic as possible. With the extension :extension:`MonoLocalBinds` GHC implements a slightly more conservative policy, for reasons descibed in Section 4.2 of `OutsideIn(X): Modular type inference with local assumptions <https://www.microsoft.com/en-us/research/publication/outsideinx-modular-type-inference-with-local-assumptions/>`__,
and a `related blog post
<https://www.haskell.org/ghc/blog/20100930-LetGeneralisationInGhc7.html>`__.

The extension :extension:`MonoLocalBinds` is implied by :extension:`TypeFamilies`
and :extension:`GADTs`. You can switch it off again with
:extension:`NoMonoLocalBinds <MonoLocalBinds>` but type inference becomes
less predictable if you do so. (Read the paper!)

To a first approximation, with :extension:`MonoLocalBinds` *top-level bindings are
generalised, but local (i.e. nested) bindings are not*. The idea is
that, at top level, the type environment has no free type variables,
and so the difficulties described in these papers do not arise. But
GHC implements a slightly more complicated rule because,
for stylistic reasons, programmers sometimes write local bindings that make no use of local variables, so the binding could equally well be top-level.  It seems reasonable to generalise these.

So here are the exact rules used by MonoLocalBinds.
With MonoLocalBinds, a binding group will be *generalised* if and only if

*   It is a top-level binding group, or
*   Each of its free variables (excluding the variables bound by the group itself) is *closed* (see next bullet), or
*   Any of its binders has a partial type signature (see Partial Type Signatures). Adding a partial type signature ``f :: _``, (or, more generally, ``f :: _ => _``) provides a per-binding way to ask GHC to perform let-generalisation, even though MonoLocalBinds is on.


Even if the binding is generalised, it may not be generalised over all its free type variables, either because it mentions locally-bound variables, or because of the Monomorphism Restriction (Haskell Report, Section 4.5.5)

*Closed variables*.  The key idea is that: *if a variable is closed, then its type definitely has no free type variables*.  A variable ``f`` is called *closed* if and only if

* The variable ``f`` is imported from another module, or

* The variable ``f`` is let-bound, and one of the following holds:

  * ``f`` has an explicit, complete (i.e. not partial) type signature that has no free type variables, or
  * its binding group is generalised over all its free type variables, so that ``f``'s type has no free type variables.

Note that a signature like f :: a -> a is equivalent to ``f :: forall a. a -> a``, assuming ``a`` is not in scope.  Hence ``f`` is closed, since it has a complete type signature with no free variables.

Example 1 ::

    g v = ...
        where
          f1 x = x+1
          f2 y = f1 (y*2)

``f1`` has free variable ``(+)``, but it is imported and hence closed.  So ``f1``'s binding is generalised. As a result, its type ``f1 :: forall a. Num a => a -> a`` has no free type variables, so ``f1`` is closed.  Hence ``f2``'s binding is generalised (since its free variables, ``f1`` and ``(*)`` are both closed).

Example 2 ::

    f3 x = let g y = x+y in ....

The binding for ``g`` has a free variable ``x`` that is lambda-bound, and hence not closed.  So ``g``\'s binding is not generalised.

*Top-level bindings*.  The Monomorphism Restriction can cause even
top-level bindings not to be generalised, and hence even the top-level
type environment can have free type variables.  However, top-level bindings
are nevertheless always generalised. To see why, consider ::

   module M( f ) where
     x = 5
     f v = (v,x)

The binding ``x=5`` falls under the Monomorphism Restriction, so that binding is not generalised, and hence ``f``'s binding is not closed.  If, as a result, we did not generalise ``f``, we would end up exporting ``f :: Any -> (Any, Integer)``, defaulting ``x``'s type to `Integer` and ``v``'s type to ``Any``.  This is counter-intuitive and undesirable, so we always generalise top-level bindings.
