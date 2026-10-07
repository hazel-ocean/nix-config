## Local rules

These rules extend the upstream skill. Where they conflict, these rules win.

### Spans on custom errors

- Give an error a span only when the span points at the caller's input: a parameter, a flag value, or piped data.
- Otherwise, use `error make --unspanned`. A span inside the command's own body shows the module's source, and the caller cannot act on it.
- Typical unspanned errors: an external command failed, a remote service returned an error, or an environment precondition is not met.
- This rule replaces the review checklist item "No bare `error make {msg: '...'}` without span when metadata is available".

```nu
# Spanned: the label points at the argument the caller passed.
def validate-age [age: int] {
    if $age < 0 {
        error make {
            msg: 'Invalid age value'
            label: {text: 'must not be negative', span: (metadata $age).span}
        }
    }
    $age
}

# Unspanned: the failure is in bd, not in anything the caller typed.
let result = ^bd list --json | complete
if $result.exit_code != 0 {
    error make --unspanned {msg: ($result.stderr | str trim)}
}
```
