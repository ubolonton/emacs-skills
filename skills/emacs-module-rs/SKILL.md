---
name: emacs-module-rs
description: >
  Best practices for writing Emacs dynamic modules in Rust using the emacs-module-rs crate.
  Use this skill whenever working with #[defun], #[module], Transfer/user-ptr, GlobalRef,
  use_symbols!, error handling, or any code in a crate that depends on the `emacs` crate.
  Apply proactively when reviewing or writing module.rs files that define Emacs-callable Rust
  functions, even if the user hasn't explicitly asked about emacs-module-rs patterns.
---

# emacs-module-rs Best Practices

Target audience: expert Rust programmers. Canonical doc: https://ubolonton.github.io/emacs-module-rs

Reference implementation: https://github.com/emacs-tree-sitter/elisp-tree-sitter/
Library source: https://github.com/ubolonton/emacs-module-rs/

---

## Module Initialization

```rust
emacs::plugin_is_GPL_compatible!();

// name= sets the Lisp feature name (default: crate name, kebab-cased)
// name(fn) uses the init function's name instead
// defun_prefix= decouples the function prefix from the feature name
// mod_in_name= controls whether Rust module paths appear in Lisp names (default: true)
// separator= between prefix and function name (default: "-")
#[emacs::module(name = "my-feature", defun_prefix = "mf", mod_in_name = false)]
fn init(env: &Env) -> Result<()> {
    // Runs after all #[defun]s are exported, but before (provide 'feature-name).
    // Use for one-time setup: set variables, define errors, etc.
    Ok(())
}
```

`#[defun]` functions **auto-register** via `ctor` — no manual registration needed in `init`.
`(provide 'feature-name)` is called automatically. Do not call `env.provide` manually.

---

## Defining Functions

```rust
// Declare input types directly — prefer this over calling .into_rust() inside the body
#[defun]
fn add(x: i64, y: i64) -> Result<i64> {
    Ok(x + y)
}

// &Env: needed to call into Lisp, intern symbols, construct values.
// Unnecessary if you already have a Value parameter (use value.env instead).
#[defun]
fn greet(env: &Env, name: String) -> Result<Value<'_>> {
    env.message(&format!("Hello, {}!", name))
}

// Option<T> maps to nil / T
#[defun]
fn maybe_upper(s: Option<String>) -> Result<Option<String>> {
    Ok(s.map(|s| s.to_uppercase()))
}

// Value parameter: use when conversion can be deferred, or type has no Rust equivalent
#[defun]
fn maybe_call(lambda: Value) -> Result<()> {
    if some_condition() { lambda.call([])?; }
    Ok(())
}
```

**Naming**: `snake_case` → `kebab-case` automatically. Full name: `<feature-prefix>[mod-prefix]<base-name>`.
Override base name: `#[defun(name = "custom-lisp-name")]`.
Per-function mod path: `#[defun(mod_in_name = true/false)]`.

Docstrings are forwarded to Lisp. The function signature `(fn ARG1 ARG2)` is appended automatically.

---

## Type Conversions

**Declare types in `#[defun]` signatures** rather than calling `.into_rust()` / `.into_lisp()` manually — cleaner and less error-prone. Use `.into_rust()` only when conversion needs to be delayed or conditional.

Built-in `IntoLisp`/`FromLisp`: `i64`, `f64`, `bool`, `String`, `&str`, `Option<T>`, `()` (nil), `Value`, `Vector`.

Constructing structured Lisp values:
```rust
env.cons(key, val)?
env.list((a, b, c))?          // list from tuple
env.vector([1, 2, 3])?        // homogeneous array
env.vector((1, "x", true))?   // heterogeneous tuple
env.make_vector(5, ())?        // fixed-size, filled with nil
env.call("plist-get", (plist, env.intern(":key")?))?
```

Integer conversion is lossless by default (signals `rust-error` on overflow). Feature `lossy-integer-conversion` disables this.

---

## Embedding Rust Data as user-ptr

The GC owns the boxed value; Rust gets references back. Interior mutability is required for mutation.

### `#[defun(user_ptr)]` — RefCell wrapping (default)

```rust
// Return value is wrapped in Box<RefCell<T>>
#[defun(user_ptr)]
fn make_parser() -> Result<Parser> { Ok(Parser::new()) }

// &mut T borrows the RefCell mutably
#[defun]
fn set_language(parser: &mut Parser, lang: Language) -> Result<()> { ... }

// &T borrows immutably
#[defun]
fn get_language(parser: &Parser) -> Result<Option<Language>> { ... }
```

`&T` / `&mut T` parameters only work for RefCell-embedded values. For `Mutex`/`RwLock` embeddings, take `Value<'_>` and lock manually — locking strategy (deadlock avoidance, etc.) is module-specific:

```rust
#[defun(user_ptr(rwlock))]
fn make_map() -> Result<HashMap<String, String>> { Ok(HashMap::new()) }

#[defun]
fn get_map(v: Value<'_>, key: String) -> Result<Option<String>> {
    let lock: &RwLock<HashMap<String, String>> = v.into_rust()?;
    let map = lock.try_read().map_err(|_| Error::msg("map is busy"))?;
    Ok(map.get(&key).cloned())
}
```

Other wrappers: `user_ptr(mutex)`, `user_ptr(direct)` (immutable, no interior mutability).

### Shared ownership (`Rc<RefCell<T>>`)

When multiple Rust objects share ownership of the same data (e.g., tree nodes holding a reference to their tree):

```rust
pub type Shared<T> = Rc<RefCell<T>>;
// Rc<RefCell<T>> has a blanket Transfer impl and implements IntoLisp directly

// Alias avoids confusion: &Shared<T> is recognized as a Transfer ref, not a user_ptr param
type Borrowed<'e, T> = &'e Shared<T>;

#[defun]
fn root_node(tree: Borrowed<Tree>) -> Result<Shared<Node>> { ... }
```

Use `Rc<RefCell<T>>` for Emacs-thread-only sharing. Use `Arc<Mutex<T>>` or `Arc<RwLock<T>>` only when background Rust threads also need access.

### Lifetime-constrained types

When a type has a non-`'static` lifetime (e.g., `Node<'tree>`), it cannot be embedded directly. The canonical solution is to use a self-referential struct (e.g., via the `ouroboros` or `self_cell` crate) that bundles the owned parent and the derived reference together.

---

## Interning Symbols

Don't call `env.intern("symbol-name")` on every invocation — it allocates and traverses the symbol table. Cache with `use_symbols!`:

```rust
use_symbols!(nil, t, error, my_custom_symbol);
// Declares OnceGlobalRef statics initialized at module load.
// Use: nil.bind(env), or pass directly where IntoLisp<'_> is expected.
```

To cache function objects (subrs), use `use_functions!`:

```rust
use_functions! {
    list_fn => "list"   // caches the subr, not the symbol; snake_case→kebab-case auto-applied
    plist_get => "plist-get"
    length
    aref
}
// Statics are OnceGlobalRef; call via: list_fn.bind(env).call((a, b, c))?
```

## Comparing Values Against Cached Refs

You can compare a `Value` directly against any `OnceGlobalRef` static (from `use_symbols!`, `use_functions!`, or `define_errors!`) without calling `.bind(env)`:

```rust
if key == *kw_device { ... }
let focused = val.is_not_nil() && val != *kw_false;
```

The `*` dereference coerces `OnceGlobalRef` to `GlobalRef`. The comparison delegates to Emacs `eq` internally — no allocation, no intermediate binding needed.

---

## GlobalRef and Value Lifetimes

`Value<'e>` is scoped to its `&'e Env` — cannot escape the function call.

`GlobalRef` escapes the call scope (useful for caching values across invocations):

```rust
static CACHED: OnceGlobalRef = OnceGlobalRef::new();

// In init:
CACHED.init(env, |env| env.intern("my-symbol"))?;

// In any defun:
let val = CACHED.bind(env);   // Value<'_> scoped to current env
```

`GlobalRef` is `Send + Sync`, but `.bind(env)` requires the Emacs GIL (i.e., must be called from within a `#[defun]` or `init`).

---

## Error Handling

**Define typed error signals** with `define_errors!` — prefer over bare `"error"`:

```rust
define_errors! {
    my_error "My module error"
    my_parse_error "Parse error" (my_error)   // inherits from my_error
    my_io_error    "I/O error"   (my_error)
}
// Generates OnceGlobalRef statics for each symbol.
```

**Signaling**:
```rust
env.signal(my_parse_error, ("details",))?;

// Convert a foreign error type into a Lisp signal (ResultExt trait):
some_result.or_signal(env, my_io_error)?;
```

**Propagating Lisp errors**: `?` on `env.call(...)` converts non-local exits to `ErrorKind::Signal`/`Throw`, which are re-raised at the `#[defun]` boundary automatically.

**Catching Lisp errors in Rust**:
```rust
match env.call("insert", [some_text]) {
    Err(e) => {
        if let Some(ErrorKind::Signal { symbol, .. }) = e.downcast_ref() {
            let sym = unsafe { symbol.value(env) };  // unsafe: must use the same env
            if sym.eq(env.intern("buffer-read-only")?) {
                // handle specifically
                return Ok(());
            }
        }
        Err(e)  // propagate others
    }
    v => v,
}
```

**Panics**: `catch_unwind` at the Rust-C boundary converts panics to `rust-panic` (not a subtype of `rust-error`). If the panic value is an `ErrorKind`, it propagates as the corresponding signal/throw — useful in FFI callbacks where `Result` can't be returned.

---

## Threading

- The Emacs GIL means objects shared only among `#[defun]`s don't need to be `Sync`.
- **Don't block** in `#[defun]` — stalls the entire Emacs process.
- Background Rust threads **cannot call into Emacs** (no `&Env` available).
- To communicate from a background thread to Emacs: write to a shared queue, then signal the main thread (SIGUSR1, pipe write, etc.) to call a polling `#[defun]`.

```rust
static EVENT_QUEUE: OnceLock<Mutex<VecDeque<Event>>> = OnceLock::new();

fn push_event(e: Event) {
    EVENT_QUEUE.get_or_init(Default::default).lock().unwrap().push_back(e);
    // notify Emacs main thread here
}

#[defun]
fn poll_event(env: &Env) -> Result<Value<'_>> {
    match EVENT_QUEUE.get_or_init(Default::default).lock().unwrap().pop_front() {
        Some(e) => e.into_lisp(env),
        None => Ok(().into_lisp(env)?),
    }
}
```

---

## Common Pitfalls

- **Forgetting `plugin_is_GPL_compatible!()`**: module will fail to load.
- **Calling `env.intern()` on every invocation**: use `use_symbols!` instead.
- **`env.is_not_nil(v)` / `env.eq(a, b)`**: deprecated since 0.10 — use `v.is_not_nil()` and `v.eq(other)`.
- **`v.eq(kw.bind(env))`**: unnecessary — use `v == *kw` when comparing against an `OnceGlobalRef` from `use_symbols!` / `use_functions!` / `define_errors!`.
- **`&T` / `&mut T` params for non-RefCell embeddings**: only works with `user_ptr` (RefCell). For Mutex/RwLock, take `Value<'_>` and lock manually.
- **Leaking `GlobalRef`**: `GlobalRef::free(env)` requires an `&Env` and cannot be called from `Drop`. For long-lived values use `OnceGlobalRef` (leaked intentionally, no free needed). For short-lived ones, free explicitly.
- **`Box<T>` without `Transfer`**: `IntoLisp for Box<T>` requires `T: Transfer`. Blanket impls exist for `RefCell<T>`, `Mutex<T>`, `RwLock<T>`, `Rc<T>`, `Arc<T>` where `T: 'static`.
- **Calling `env.provide()`**: unnecessary — `#[module]` calls it automatically.
