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
// defun_prefix= decouples the function prefix from the feature name
// mod_in_name= controls whether Rust module paths appear in Lisp names (default: true)
// separator= between prefix and function name (default: "-")
#[emacs::module(name = "my-feature", defun_prefix = "mf", mod_in_name = false)]
fn init(env: &Env) -> Result<()> {
    // One-time setup: define errors, set variables, etc.
    Ok(())
}
```

`#[defun]` functions **auto-register** via `ctor` — no manual registration needed in `init`.
The `init` hook is for setting variables, calling functions...
The module is automatically provided. Do not call `env.provide`.

---

## Defining Functions

```rust
// Basic: no &Env needed if you don't call into Lisp
#[defun]
fn add(x: i64, y: i64) -> Result<i64> {
    Ok(x + y)
}

// With &Env: needed for calling Lisp, interning symbols, constructing values
#[defun]
fn greet(env: &Env, name: String) -> Result<Value<'_>> {
    env.message(&format!("Hello, {}!", name))
}

#[defun]
fn maybe_upper(s: Option<String>) -> Result<Option<String>> {
    Ok(s.map(|s| s.to_uppercase()))
}
```

**Naming**: `#[defun]` converts `snake_case` → `kebab-case` automatically.
Override with `#[defun(name = "custom-lisp-name")]`.

Per-function `mod_in_name` override: `#[defun(mod_in_name = true/false)]`.

---

## Type Conversions

**Lisp → Rust**: prefer `value.into_rust::<T>()?` (method form); use `T::from_lisp(value)?` only when it improves clarity.

**Rust → Lisp**: types implementing `IntoLisp` convert implicitly as return values or via `.into_lisp(env)?`.

Built-in `IntoLisp`/`FromLisp` types: `i64`, `f64`, `bool`, `String`, `&str`, `Option<T>`, `Value`, `Vector`.

For structured data, build Lisp values explicitly:
```rust
env.cons(key, val)?          // cons cell
env.list((a, b, c))?         // list from tuple
env.vector((a, b, c))?       // vector from tuple
env.call("plist-get", (plist, env.intern(":key")?))?
```

---

## Embedding Rust Data as user-ptr

The GC owns the data; module code gets immutable references back (or mutable via interior mutability).

### `#[defun(user_ptr)]` — wrap return value automatically

```rust
// Wraps return value in RefCell<T> (default), suitable for single-threaded mutation
#[defun(user_ptr)]
fn make_parser() -> Result<Parser> {
    Ok(Parser::new())
}

// Parameter: &mut T borrows the RefCell mutably
#[defun]
fn set_language(parser: &mut Parser, lang: Language) -> Result<()> { ... }

// Parameter: &T borrows immutably
#[defun]
fn get_language(parser: &Parser) -> Result<Option<Language>> { ... }

// Other wrappers: user_ptr(mutex), user_ptr(rwlock), user_ptr(direct)
// direct: immutable only, no interior mutability
```

### Shared ownership (`Rc<RefCell<T>>`)

When Rust-side objects need to share ownership (e.g., tree nodes referencing their tree):

```rust
pub type Shared<T> = Rc<RefCell<T>>;
// Rc<RefCell<T>> implements Transfer automatically
// Use as return type directly (implements IntoLisp) or via &Shared<T> parameter
type Borrowed<'e, T> = &'e Shared<T>;  // parameter alias to avoid #[defun(user_ptr)] confusion

#[defun]
fn root_node(tree: Borrowed<Tree>) -> Result<Node> { ... }
```

Use `Rc<RefCell<T>>` (not `Arc<Mutex<T>>`) when sharing is purely within the Lisp/Emacs thread. Use `Arc<Mutex<T>>` or `Arc<RwLock<T>>` only when background Rust threads also need access.

---

## Interning Symbols

**Don't** call `env.intern("symbol-name")` repeatedly at runtime. Cache with `use_symbols!`:

```rust
use_symbols!(nil, t, error, my_custom_symbol);
// Generates OnceGlobalRef statics initialized at module load.
// Use as: nil.bind(env), t.bind(env), or pass directly where IntoLisp is expected.
```

For symbols not following the Rust→lisp name conversion, or for Lisp function references:

```rust
global_refs! { my_registrator(init_to_symbol) =>
    my_sym => "my-lisp-symbol"
}
global_refs! { my_fn_registrator(init_to_function) =>
    list_fn => "list"   // caches the function object, not the symbol
}
```

---

## GlobalRef and Value Lifetimes

`Value<'e>` is scoped to the `&'e Env` it came from — cannot escape the function call.

`GlobalRef` escapes the call scope (useful for caching, cross-invocation state):

```rust
static CACHED: OnceGlobalRef = OnceGlobalRef::new();

// In init:
CACHED.init(env, |env| env.intern("my-symbol"))?;

// In defuns:
let val = CACHED.bind(env);   // Value<'_> scoped to current env
```

`GlobalRef` is `Send + Sync`, but `.bind(env)` requires holding the Emacs GIL (i.e., being on the Emacs thread with a live `&Env`, or in other words, within a `#[defun]`).

---

## Error Handling

**Define typed error signals** with `define_errors!` — prefer this over bare `"error"` strings:

```rust
define_errors! {
    my_error "My module error"
    my_parse_error "Parse error" (my_error)   // parent hierarchy
    my_io_error    "I/O error"   (my_error)
}
// Generates OnceGlobalRef statics for each symbol.
```

**Signal from Rust**:
```rust
// Using env.signal directly:
env.signal(my_parse_error, ("details",))?;

// Wrapping foreign errors:
some_result.or_signal(env, my_io_error)?;  // ResultExt trait
```

**Propagate Lisp errors**: `?` on `env.call(...)` propagates non-local exits as `ErrorKind::Signal` or `ErrorKind::Throw` — these are re-raised automatically when the `#[defun]` returns.

---

## Threading

- The Emacs GIL means objects shared only among `#[defun]` don't need to be `Sync`.
- **Don't block** in `#[defun]` — use queues and return immediately.
- Background Rust threads **cannot call into Emacs** (no `&Env` available).
- To communicate with Emacs from a background thread: write to a shared queue, then use a signalling mechanism (OS signal, channel, file descriptor) to notify Emacs's main thread, which called a pre-registered callback to poll the queue.

```rust
// Push from any thread:
static CMD_QUEUE: OnceLock<Mutex<VecDeque<Cmd>>> = OnceLock::new();

fn push_cmd(cmd: Cmd) {
    CMD_QUEUE.get_or_init(Default::default).lock().unwrap().push_back(cmd);
    // Wake Emacs: raise SIGUSR1, write to a pipe, etc.
}

// Poll from Emacs thread:
#[defun]
fn poll_events(env: &Env) -> Result<Value<'_>> {
    let cmd = CMD_QUEUE.get_or_init(Default::default).lock().unwrap().pop_front();
    // Convert cmd to Lisp value...
}
```

---

## Common Pitfalls

- **Forgetting `plugin_is_GPL_compatible!()`**: module will fail to load.
- **Calling `env.intern()` in hot paths**: use `use_symbols!` instead.
- **Using `env.is_not_nil(v)` or `env.eq(a, b)`**: deprecated since 0.10; use `v.is_not_nil()` and `v.eq(other)`.
- **Leaking `GlobalRef`**: `GlobalRef::free(env)` requires an `&Env`; for long-lived caches use `OnceGlobalRef` (no free needed). Manual `GlobalRef` should be freed explicitly.
- **`Box<T>` without `Transfer`**: `IntoLisp for Box<T>` requires `T: Transfer`. Implement `Transfer` or use `RefCell<T>`/`Rc<RefCell<T>>` which have blanket impls.
- **Blocking in `#[defun]`**: stalls the entire Emacs process.
